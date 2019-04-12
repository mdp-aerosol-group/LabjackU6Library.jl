//Author: LabJack
//April 5, 2011
//Communicates with an LJTick-DAC using low level functions.  The LJTDAC should
//be plugged into FIO2/FIO3 for this example.

#include "u6.h"
#include <unistd.h>

int setLJTDAC(HANDLE hDevice, u6TdacCalibrationInfo *caliInfo, uint8 DIOAPinNum, double analogVDacA, double analogVDacB)
{
    int err;
    uint8 options, speedAdjust, sdaPinNum, sclPinNum, address, numBytesToSend, numBytesToReceive, errorcode;
    uint16 binaryVoltage;
    uint8 bytesCommand[5];
    uint8 bytesResponse[64];
    uint8 ackArray[4];

    err = 0;

    //Setting up parts I2C command that will remain the same throughout this example
    options = 0;      //I2COptions : 0
    speedAdjust = 0;  //SpeedAdjust : 0 (for max communication speed of about 130 kHz)
    sdaPinNum = DIOAPinNum+1;   
	sclPinNum = DIOAPinNum;   

    //Setting up I2C command
    //Make note that the I2C command can only update 1 DAC channel at a time.
    address = (uint8)(0x24);  //Address : h0x24 is the address for DAC
    numBytesToSend = 3;       //NumI2CByteToSend : 3 bytes to specify DACA and the value
    numBytesToReceive = 0;    //NumI2CBytesToReceive : 0 since we are only setting the value of the DAC
    bytesCommand[0] = (uint8)(0x30);  //LJTDAC command byte : h0x30 (DACA)

    getTdacBinVoltCalibrated(caliInfo, 0, analogVDacA, &binaryVoltage);
    bytesCommand[1] = (uint8)(binaryVoltage/256);         //value (high)
    bytesCommand[2] = (uint8)(binaryVoltage & (0x00FF));  //value (low)

    //Performing I2C low-level call
    err = I2C(hDevice, options, speedAdjust, sdaPinNum, sclPinNum, address, numBytesToSend, numBytesToReceive, bytesCommand, &errorcode, ackArray, bytesResponse);

    //Setting up I2C command
    address = (uint8)(0x24);  //Address : h0x24 is the address for DAC
    numBytesToSend = 3;       //NumI2CByteToSend : 3 bytes to specify DACB and the value
    numBytesToReceive = 0;    //NumI2CBytesToReceive : 0 since we are only setting the value of the DAC
    bytesCommand[0] = (uint8)(0x31);  //LJTDAC command byte : h0x31 (DACB)
    getTdacBinVoltCalibrated(caliInfo, 1, analogVDacB, &binaryVoltage);
    bytesCommand[1] = (uint8)(binaryVoltage/256);         //value (high)
    bytesCommand[2] = (uint8)(binaryVoltage & (0x00FF));  //value (low)

    //Performing I2C low-level call
    err = I2C(hDevice, options, speedAdjust, sdaPinNum, sclPinNum, address, numBytesToSend, numBytesToReceive, bytesCommand, &errorcode, ackArray, bytesResponse);

    return err;
}
