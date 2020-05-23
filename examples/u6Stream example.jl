using LabjackU6Library, DataStructures, Gadfly

const NumChannels = UInt8(1);      #  SamplesPerPacket needs to be a multiple of NumChannels.
const SamplesPerPacket = UInt8(25) # Needs to be 25 to read multiple StreamData responses
                             # in one large packet, otherwise can be any value between
                             # 1-25 for 1 StreamData response per packet.


# This function configures the stream and turn off timers/counter 
function configureLabjack(HANDLE)
    # Adapted from the u6Stream.c example
    # Maintain C style zero indexing for bytes by using +1

    sl,rl = 16,16   # Length of send buffer,receive buffer in bytes
    sendBuff, rec = zeros(UInt8,sl), zeros(UInt8,rl)

    sendBuff[1+1] = UInt8(0xF8)  # Command byte
    sendBuff[2+1] = UInt8(0x03)  # Number of data words
    sendBuff[3+1] = UInt8(0x0B)  # Extended command number

    sendBuff[6+1] = 1;  # Writemask : Setting writemask for TimerCounterConfig (bit 0)
    
    sendBuff[7+1] = 0;  # NumberTimersEnabled : Setting to zero to disable all timers.
    sendBuff[8+1] = 0;  # CounterEnable: Setting bit 0 and bit 1 to zero to disable both counters
    sendBuff[9+1] = 0;  # TimerCounterPinOffset
                             
    # Create labjack buffer data types to pass to C-functions
    send =  labjackBuffer{sl}(NTuple{sl,UInt8}(sendBuff[i] for i in 1:sl))
    rec =  labjackBuffer{rl}(NTuple{rl,UInt8}(rec[i] for i in 1:rl))

    extendedChecksum!(send)

    labjackSend(HANDLE,send)
    labjackRead!(HANDLE,rec)
end

# This function configures the stream and turn off timers/counter 
function configureStream(HANDLE)
    # Adapted from the u6Stream.c example
    # Maintain C style zero indexing for bytes by using +1

    sl,rl =  14+NumChannels*2,8  # Length of send buffer,receive buffer in bytes
    sendBuff, rec = zeros(UInt8,sl), zeros(UInt8,rl)

    sendBuff[1+1] = UInt8(0xF8)      # Command byte
    sendBuff[2+1] = 4 + NumChannels  # Number of data words = NumChannels + 4
    sendBuff[3+1] = UInt8(0x11)      # Extended command number
    sendBuff[6+1] = NumChannels      # NumChannels
    sendBuff[7+1] = 3                # ResolutionIndex
    sendBuff[8+1] = SamplesPerPacket # SamplesPerPacket
    sendBuff[9+1] = 0                # Reserved
    sendBuff[10+1] = 0               # SettlingFactor: 0
    sendBuff[11+1] = 0               # ScanConfig:
                                    # Bit 3: Internal stream clock frequency = b0: 4 MHz
                                    # Bit 1: Divide Clock by 256 = b0

    scanInterval = 400
    sendBuff[12+1] = UInt8(scanInterval&(0x00FF))  # scan interval (low byte)
    sendBuff[13+1] = UInt8(scanInterval >> 8)      # scan interval (high byte)

    for i = UInt8(1):NumChannels-1
        sendBuff[14 + i*2+1] = i;     # ChannelNumber (Positive) = i
        sendBuff[15 + i*2+1] = 0;     # ChannelOptions: Bit 7: Differential = 0 Bit 5-4: GainIndex = 0 (+-10V)
    end
                      
    # Create labjack buffer data types to pass to C-functions
    send =  labjackBuffer{sl}(NTuple{sl,UInt8}(sendBuff[i] for i in 1:sl))
    rec =  labjackBuffer{rl}(NTuple{rl,UInt8}(rec[i] for i in 1:rl))

    extendedChecksum!(send)

    labjackSend(HANDLE,send)
    labjackRead!(HANDLE,rec)
end

function startStream(HANDLE)
    # Adapted from the u6Stream.c example
    # Maintain C style zero indexing for bytes by using +1
    sl,rl =  2,4     # Length of send buffer,receive buffer in bytes
    sendBuff, rec = zeros(UInt8,sl), zeros(UInt8,rl)

    sendBuff[0+1] = UInt8(0xA8)  # Checksum8
    sendBuff[1+1] = UInt8(0xA8)  # Command byte

    # Create labjack buffer data types to pass to C-functions
    send =  labjackBuffer{sl}(NTuple{sl,UInt8}(sendBuff[i] for i in 1:sl))
    rec =  labjackBuffer{rl}(NTuple{rl,UInt8}(rec[i] for i in 1:rl))  

    labjackSend(HANDLE,send)
    labjackRead!(HANDLE,rec)
end

function stopStream(HANDLE)
    # Adapted from the u6Stream.c example
    # Maintain C style zero indexing for bytes by using +1
    sl,rl =  2,4     # Length of send buffer,receive buffer in bytes
    sendBuff, rec = zeros(UInt8,sl), zeros(UInt8,rl)

    sendBuff[0+1] = UInt8(0xB0)  # Checksum8
    sendBuff[1+1] = UInt8(0xB0)  # Command byte

    # Create labjack buffer data types to pass to C-functions
    send =  labjackBuffer{sl}(NTuple{sl,UInt8}(sendBuff[i] for i in 1:sl))
    rec =  labjackBuffer{rl}(NTuple{rl,UInt8}(rec[i] for i in 1:rl))  

    labjackSend(HANDLE,send)
    labjackRead!(HANDLE,rec)
end

function labjackStream(HANDLE, caliInfo)
    readSizeMultiplier = 10
    channel = CircularBuffer{Int}(Int(NumChannels))
    
    rl = (14 + SamplesPerPacket*2)
    rlx = (14 + SamplesPerPacket*2)*readSizeMultiplier
    recZ = zeros(UInt8, rlx)
    rec =  labjackBuffer{rlx}(NTuple{rlx,UInt8}(recZ[i] for i in 1:rlx))  

    voltages = [Float64[] for i=1:NumChannels]
    labjackStream!(HANDLE,rec)
    count = 1
    for m = 0:readSizeMultiplier-1
        backLog = Int(rec.buff[m*48 + 12 + SamplesPerPacket*2+1])

        #println(rec.buff[m*rl + 11 +1]) - buffer overflow error
        for k = 12:2:12 + SamplesPerPacket*2-1
            bytesV = UInt16(rec.buff[m*rl + k+1]) + UInt16(rec.buff[m*rl + k+1+1]*256)

            foo = Cdouble(0)
            calV = ccall((:getAinVoltCalibrated_julia, LabjackU6Library.lib), Cdouble,
                (Ref{u6CalibrationInfo}, Cint, Cint, Cint, Cuint, Ref{Cdouble}),
                caliInfo, 1, 0, 0, bytesV, foo)
            push!(voltages[(count % NumChannels) + 1], calV)
            count = count + 1       
        end
    end
    voltages[1]
end

HANDLE = openUSBConnection(-1)
caliInfo = getCalibrationInformation(HANDLE)
stopStream(HANDLE)
configureStream(HANDLE)

startStream(HANDLE)

for i = 1:200
    x = map(_->labjackStream(HANDLE, caliInfo),1:4);
    V = vcat(x...)
    p = plot(y = V, Geom.line)
    display(p)
end

closeUSBConnection(HANDLE)
