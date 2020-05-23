using LabjackU6Library, Gadfly

# This function sets the send and receive buffers
function setupLabjackBuffers()
    # See pg. 83 of U6 Datasheet for protocol
    # Maintain C style zero indexing for bytes by using +1

    # 2 AIN 24bit, 1 AIN14 (T)
    # IOType input bytes  = 2*4 + 1*4 = 12 bytes
    # IOType output bytes = 2*3 + 1*3 = 9 bytes

    # Send buffer in words = (1 + 12 + 1)/2 = 7
    # Receive buffer in words  = (8 + 9 + 1)/2 = 9
    sl,rl = (7*2+6),(9*2+8)   # Length of send buffer,receive buffer in bytes
    sendBuff, rec = zeros(UInt8,sl), zeros(UInt8,rl)

    # Block 1 Bytes 1-5 Configure Basic Setup
    # Bytes 0,4,5 are reserved for checksum
    sendBuff[1+1] = UInt8(0xF8)    # Command byte
    sendBuff[2+1] = 7              # Number of data words
    sendBuff[3+1] = Int8(0x00)    # Extended command number

    # Block 2 Echo + Bytes 7-XX
    # Bytes 7-XX Configure Channels
    # Must be even number of bytes
    sendBuff[6+1] = 0;           # Echo

    # AIN0
    sendBuff[7+1]  = 2;          # IOType is AIN24
    sendBuff[8+1]  = 0;          # Channel 0
    sendBuff[9+1]  = 9 + 0*16;   # Resolution & Gain
    sendBuff[10+1] = 0 + 0*128;  # Settling & Differential 

    # AIN1
    sendBuff[11+1] = 2;          # IOType is AIN24
    sendBuff[12+1] = 1;          # Channel 1
    sendBuff[13+1] = 9 + 0*16;   # Resolution & Gain
    sendBuff[14+1] = 0 + 0*128;  # Settling & Differential

    # AIN14
    sendBuff[15+1] = 2           # IOType is AIN24
    sendBuff[16+1] = 14          # Positive channel = 14 (temperature sensor)
    sendBuff[17+1] = 9 + 0*16    # Resolution & Gain 
    sendBuff[18+1] = 0 + 0*128   # SettlingFactor & Differential

    # Padding bye (size of a packet must be an even number of bytes)
    sendBuff[19+1] = 0;

    # Create labjack buffer data types to pass to C-functions
    send =  labjackBuffer{sl}(NTuple{sl,UInt8}(sendBuff[i] for i in 1:sl))
    rec =  labjackBuffer{rl}(NTuple{rl,UInt8}(rec[i] for i in 1:rl))

    # Fills bytes 0,4,5 with checksums
    extendedChecksum!(send)
    return send, rec
end

function labjackReadWrite(HANDLE, caliInfo)
    sendIt, recordIt = setupLabjackBuffers()

    labjackSend(HANDLE,sendIt)
    labjackRead!(HANDLE,recordIt)
    AIN0 = calibrateAIN(caliInfo,recordIt,9,0,1,10,11,12)  # Calibrate AIN0
    AIN1 = calibrateAIN(caliInfo,recordIt,9,0,1,13,14,15)  # Calibrate AIN1
	AIN14 = calibrateAIN(caliInfo,recordIt,9,0,1,16,17,18)  # Calibrate AIN14
    Tk = caliInfo.ccConstants[23]*AIN14 + caliInfo.ccConstants[24] # Temp in K
    
    AIN0# AIN1, Tk
end

HANDLE = openUSBConnection(-1)
caliInfo = getCalibrationInformation(HANDLE)
y = Float64[]
for i = 1:100
    a = labjackReadWrite(HANDLE, caliInfo)
    push!(y,a)
    sleep(0.02)
end
x = range(0,stop = 100*0.05, length=100)
plot(x=x,y=y, Geom.line)
closeUSBConnection(HANDLE)
