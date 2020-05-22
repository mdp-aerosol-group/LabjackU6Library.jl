module LabjackU6Library
#+
# This module provides the Julia wrapper to the U6 C-library
#
# Author: Markus Petters (mdpetter@ncsu.edu)
#         Department of Marine Earth and Atmospheric Science
#         NC State University
#         Raleigh, NC 27695-8208
#
# October 2018
#-

export
   openUSBConnection,             # Opens a USB connection
   closeUSBConnection,            # Closes a USB connection
   getCalibrationInformation,     # Returns u6CalibrationInfo
   getTdacCalibrationInformation, # Returns u6CalibrationInfo LJTdac
   setLJTDAC,                     # low-level call to set LJTDAC V
   extendedChecksum!,             # Computes checksum
   labjackSend,                   # Send buffer to Labjack
   labjackRead!,                  # Read buffer from Labjack
   calibrateAIN                   # Calibrates AIN signal

export
   u6CalibrationInfo,
   labjackBuffer


"""
   u6CalibrationInfo

Data structure containing the calibration information
 - prodID: productID
 - hiRes: 
 - ccConstants: calibration constants

"""
mutable struct u6CalibrationInfo
   prodID::UInt8
   hiRes::UInt8
   ccConstants::NTuple{40,Float64}
end

"""
   u6TDACCalibrationInfo

Data Structure of LJTDAC calibration constants
 - prodID: productID
 - ccConstants: calibration constants

"""
mutable struct u6TDACCalibrationInfo
	prodID::UInt8
	ccConstants::NTuple{4,Float64}
end

"""
   u6TDACCalibrationInfo

Generic Buffer structure to send and receive data via Hardware calls
NTuple{N,UInt8}

"""
mutable struct labjackBuffer{N}
   buff::NTuple{N,UInt8}
end

#const lib = dirname(Base.find_package("LabjackU6Library"))*"/libU6.so"
const lib = pwd()*"/libU6.so"
include("u6ccalls.jl")

end
