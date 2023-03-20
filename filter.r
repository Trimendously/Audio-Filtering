
library("tuneR")
library("soundecology")
library("stats")


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

acoustic_filter <- function(fileName, acoustimestep) {
    max_val <-30
	fileName <- 'PinkPanther30'
    acoustic_index <- 'BI'
    timeStep <-3

    audio_data <- readWave(paste0(fileName, '.wav'))
    sample_rate <- audio_data@samp.rate
    bit <- audio_data@bit

    num_files <- 3
    file_length <- floor(length(audio_data)/num_files)
    subarrays <- split(audio_data, rep(1:num_files, each=file_length,length.out = length(audio_data@left)))
    #subarrays <- split(audio_data, ceiling(seq_along(audio_data)/ts))

    # Create the directory (if it doesn't already exist)
    dir_name = paste0('Filtered_',fileName)
    if (file.exists(dir_name)) {
        unlink(dir_name,recursive=TRUE)
    }

    dir.create(dir_name)
    
    # Calculates the <insert acoustic index here> for each subarray
    count <- 0
    indices <- vector("list",timeStep)
    concatenated_wav <- Wave(rep(0, 0), samp.rate = sample_rate, bit = bit)
    for (i in seq_along(subarrays)) {
        #temp_filePath <- file.path(dir_name,paste0(fileName,'_',(i-1)*file_length,'_',(i)*file_length, '.wav'))
        #tuneR::writeWave(subarrays[[i]], filename = temp_filePath, sample_rate)

        indices[i] <- acoustic_helper(subarrays[[i]], acoustic_index)

        cat(acoustic_index, " for [", count,",",count+file_length , "]:    ", toString(indices[i]), "\n")
        if (indices[i] > max_val)
		{
		#subarrays[[i]] <-tuneR::silence(subarrays[[i]],sample_rate,num_channels)# Makes the audio silent
        subarrays[[i]] <- Wave(rep(0, length(subarrays[[i]])), samp.rate = sample_rate, bit = bit)
        }
        #concatenated_wav <- c(concatenated_wav,subarrays[[i]])
        concatenated_waveform <- c(as.vector(concatenated_wav@left), as.vector(subarrays[[i]]@left))
        concatenated_wav <- Wave(concatenated_waveform, samp.rate = sample_rate, bit = bit)
        count <- count + file_length
    }
    
    temp_filePath <- file.path(dir_name,fileName, '.wav')
    tuneR::writeWave(concatenated_wav, filename = 'yo.wav', sample_rate)
    

}
acoustic_filter()