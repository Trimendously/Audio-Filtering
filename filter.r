
library("tuneR")
library("soundecology")
library("stats")

frequency_filter <-function(dir_path, min_freq, max_freq) {
    if (file.access(dir_path) == -1) {
		stop(paste("The directory specified does not exist or this user is not autorized to read it:\n    ", directory))
		}

    file_Names <- list.files(path = dir_path, pattern = "\\.wav$", full.names = TRUE)

    for (file_name in file_Names) {
        audio_data <- tuneR::readWave(file_name)
        tuneR::normalize(audio_data, unit = c("1"), center =FALSE, rescale = FALSE) # the interval chosen is [-1,1]
        sample_rate <- audio_data@samp.rate
        bit <- audio_data@bit

        fourier <- fft(audio_data@left, inverse= TRUE) # fourier transformation

        # Frequencies
        freq <- (0:(length(audio_data@left)-1)) * (sample_rate / length(audio_data@left))

        # Filtering the sample
        fourier[freq < min_freq] <- 0 #High Pass filter
        fourier[freq > max_freq] <- 0 # Low pass filter
 
        
        filtered_sig <- Re(signal::ifft(fourier)) # Inverse fourier transformation

        filtered_wav <- tuneR::Wave(filtered_sig, samp.rate = sample_rate, bit = bit)
        tuneR::writeWave(filtered_wav, filename = file_name, sample_rate)
    }
}

acoustic_helper <- function(data, indices) {

    ACI <- function() {
    data.aci <- acoustic_complexity(data)
    return(data.aci$AciTotAll_left)
    }

    NDSI <- function() {
    data.ndsi <- ndsi(data)
    return(data.ndsi$ndsi_left)
    }

    BI <- function() {
    data.bi <- bioacoustic_index(data)
    return(data.bi$left_area)
    }

    ADI <- function() {
    data.adi <- acoustic_diversity(data)
    return(data.ndsi$adi_left)
    }

    AEI <- function() {
    data.aei <- acoustic_evenness(data)
    return(data.ndsi$aei_left)
    }

    return(get(indices)())
}

acoustic_filter <- function(dir_path, acoustic_index, max_val, timeStep) {
    if (file.access(dir_path) == -1) {
		stop(paste("The directory specified does not exist or this user is not autorized to read it:\n    ", directory))
	}

    file_Names <- list.files(path = dir_path, pattern = "\\.wav$", full.names = TRUE)

    for (file_name in file_Names) {

        audio_data <- readWave(paste0(file_name, '.wav'))
        sample_rate <- audio_data@samp.rate
        bit <- audio_data@bit

        file_length <- floor(length(audio_data)/timeStep)
        subarrays <- split(audio_data, rep(1:timeStep, each=file_length,length.out = length(audio_data@left)))


        # Calculates the <insert acoustic index here> for each subarray
        count <- 0
        concatenated_wav <- Wave(rep(0, 0), samp.rate = sample_rate, bit = bit)
        for (i in seq_along(subarrays)) {
            # Assigns the indices to a temp variable
            indices <- acoustic_helper(subarrays[[i]], acoustic_index)

            cat(acoustic_index, " for [", count,",",count+file_length , "]:    ", toString(indices), "\n")
            if (indices > max_val) {
                subarrays[[i]] <- Wave(rep(0, length(subarrays[[i]])), samp.rate = sample_rate, bit = bit) # nolint: line_length_linter.
            }

            concatenated_waveform <- c(as.vector(concatenated_wav@left), as.vector(subarrays[[i]]@left))
            concatenated_wav <- Wave(concatenated_waveform, samp.rate = sample_rate, bit = bit)
            count <- count + file_length
        }

        tuneR::writeWave(concatenated_wav, filename = file_name, sample_rate)
    }
    

}

# Sets the defaults values for testing purposes
fileName = 'PinkPanther30.wav'
acoustic_index <- 'BI'
max_val <-10
timeStep <-3
max_freq = 10
min_freq = 0


# Create the directory (if it doesn't already exist)
dir_name = paste0('Filtered_',fileName)
if (file.exists(dir_name)) {
    unlink(dir_name,recursive=TRUE)
}

dir.create(dir_name)

file.copy(from = fileName, to = dir_name,overwrite = TRUE) # Copies the original file to the new directory




frequency_filter(dir_name, min_freq, max_freq)
#acoustic_filter(dir_name, acoustic_index, max_val, timeStep)