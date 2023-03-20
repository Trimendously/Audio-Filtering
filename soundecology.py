import sys
import subprocess




# implement pip as a subprocess:
#subprocess.check_call([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"])


import rpy2
import rpy2.robjects as robjects
import rpy2.robjects.packages as rpackages
from rpy2.robjects.vectors import StrVector

# Currently suppressing until permissions can be addressed for R package library
from rpy2.rinterface_lib.callbacks import logger as rpy2_logger
import logging
rpy2_logger.setLevel(logging.ERROR)   # will display errors, but not warnings






def main(fileName,indices):



    # List of r packages that need to be installed
    package_names = ('soundecology','tuneR','ineq','vegan','parallel','seewave','pracma','oce')

    # Check if packages are installed
    if all (rpackages.isinstalled(x) for x in package_names):
        package_installed = True
    else:
        package_installed = False

    if not package_installed:
        utils = rpackages.importr('utils')
        utils.chooseCRANmirror(ind = 75) # Ohio mirror (can change by setting graphics = False)

        package_to_install = [x for x in package_names if not rpackages.isinstalled(x)]

        if (len(package_to_install)  > 0):
            utils.install_packages(StrVector(package_to_install))

    sound = rpackages.importr('soundecology')
    tuneR = rpackages.importr('tuneR')
    file = tuneR.readWave(fileName)

    
    dict = ['ACI','NDSI','BI','ADI','AEI']

    #Computes the indices and returns a float from the R vector
    def ACI():
        file.aci = sound.acoustic_complexity(file)
        return file.aci[0][0]
        
    def NDSI():
        file.ndsi = sound.ndsi(file)
        return file.ndsi[0][0]

    def BI():
        file.bi = sound.bioacoustic_index(file)
        return file.bi[0][0]

    def ADI():
        file.adi = sound.acoustic_diversity(file)
        return file.adi[0][0]

    def AEI():
        file.aei = sound.acoustic_evenness(file)
        return file.aei[0][0]

    return locals()[indices]()
