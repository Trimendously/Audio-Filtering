import scipy
import scipy.fftpack
import scipy.io.wavfile
import numpy as np
from matplotlib import pyplot as plt
import soundfile as sf

import math
from PIL import Image
import sys,os
import subprocess

import soundecology

from threading import Thread
import time as tm

thread_running = True


# implement pip as a subprocess:
subprocess.check_call([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"], stdout = subprocess.DEVNULL)

fileName = ''


def infinite_while():
    global thread_running

    start_time = tm.time()

    # run this while there is no input
    while thread_running:
        tm.sleep(0.1)

        if tm.time() - start_time >= 5:
            start_time = tm.time()
            #print('Another 5 seconds has passed')

def input_reciever():
    global fileName
    fileName = str(input('Type user input: '))
    # doing something with the input
    print('The user input is: ', fileName)


# Disables printing
def blockPrint():
    sys.stdout = open(os.devnull, 'w')

# Restores printing
def enablePrint():
    sys.stdout = sys.__stdout__

if __name__ == '__main__':
    
    # Plots normal audio sample,fft, filtered fft, and ifft
    def four_plot(x):
        figs, axs = plt.subplots(4)
        axs = axs.flatten()
        plt.subplot(4,1,1)



        # Plots the original signal
        axs[0].plot(time[::x],data[::x], "b")
        axs[0].set(label = 'Original',xlabel = 'Time', ylabel = 'Amplitude', title = 'Original')


        # Plots the signal after a fast fourier transform is applied
        axs[1].plot(freq_pos[::x],fourier_pos[::x], "g")
        axs[1].set(xlabel = 'Frequency, HZ', ylabel = 'Intensity', title = 'FFT')


        # Plots the positive range of the signal after a fast fourier transform is applied
        axs[2].plot(freq_pos[::x],filtFour_pos[::x], "r")
        axs[2].set(xlabel = 'Frequency, HZ', ylabel = 'Intensity', title = 'Filtered Frequencies')

        # Plots the original signal after a certain frequency is filtered out
        axs[3].plot(time[::x],new[::x], "b")
        axs[3].set(xlabel = 'Time', ylabel = 'Amplitude', title = 'Filtered Signal')
        plt.tight_layout()
        plt.show()

    def filter():
            
        # High Pass filter
        def high_pass(threshold):
            filtFour[(freq < threshold)] = 0
            
        # Low Pass filter
        def low_pass(threshold):
            filtFour[(freq > threshold)] = 0


        fourier = (scipy.fft.fft(data)) # fourier transformation
        fourier_pos = fourier[range(samp//2)] # Positive only fft

        #print("\n\nFFT Size:",fourier_pos.size)

        #Frequencies
        freq = scipy.fftpack.fftfreq(data.size,d =0.1)
        freq_pos = freq[range(samp//2)]


        #Filtering the sample
        filtFour = fourier.copy()

        high_pass(2.2)
        filtFour_pos = filtFour[range(samp//2)]


        #orig = scipy.fft.ifft(fourier)
        new = scipy.fft.ifft(filtFour)

        n=samp
        step = samp // 1000
        four_plot(step)


    t1 = Thread(target=infinite_while)
    t2 = Thread(target=input_reciever)

    t1.start()
    t2.start()

    t2.join()  # Waits until input is recieved or process is terminated

    thread_running = False
    print('The end of waiting for input')
    print()

    #fileName = 'test_g'
    #fileName = 'PinkPanther30'

    data, sample_rate = sf.read(fileName + '.wav')

    if (data.shape == 2):
        data = data.sum(axis=1)/2

    samp = data.shape[0] # of samplings

    print("\n\nSamples: ",samp,"\n\n")

    samp = data.shape[0] # of samplings

    sec = samp / float(sample_rate) # Seconds. Have to type cast as wavefile.read(...) returns an int

    #TS = 1.0/ sample_rate # timestep

    time = np.arange(0,sec,(1.0/ sample_rate)) #time vector

    print("Total time elapsed:        ",time[-1] , 'seconds')

    # interval indicates the timestep to evaluate based off of
    # the larger the ts the longer the runtime
    time_elapsed = math.ceil(time[-1])
    
    ts = -1
    for i in range(3,time_elapsed):
        if time_elapsed % i == 0:
            ts = i
            break


    #Should consider prime numbers as well
    if ts == -1:
        print("No multiple of time elapsed")


    buckets = time_elapsed/ts
    # will initally implement hard codes as equal intervals but should make it so that integer isnt needed

    edges = np.arange(0,time_elapsed,ts,dtype=int)

    subarrays = np.split(data,ts)

    indices = np.zeros(len(subarrays))

    # Calculates the <insert acoustic index here> for each subarray
    acoustic_index = 'NDSI'
    count = 0
    for i in range(len(subarrays)):
        temp_fileName = fileName + str(i) + '.wav'
        sf.write(temp_fileName, subarrays[i] , sample_rate)

        blockPrint()
        indices[i] = soundecology.main(temp_fileName,acoustic_index)
        enablePrint()

        print(acoustic_index, " for [",count,",",count+buckets , "]:    ", indices[i])
        #os.remove(temp_fileName)
        count+=buckets






