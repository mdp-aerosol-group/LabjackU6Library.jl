LabjackU6Library.jl is a Julia package to communicate with Labjack series U6 multifunction DAQ device. The package is partial wrapper to the low-level [Labjack Linux driver](https://github.com/labjack/exodriver). 

The driver provides a series of C functions to communicate with the DAQ device. A shared static library is obtained by compiling the files in the U6 directory. 

The wrapper is incomplete, but quite functional. 

The setup of the device is performed through the the send buffer. The three functions

```labjackSend(HANDLE,sendIt)```

```labjackRead!(HANDLE,recordIt)```

```labjackStream!(HANDLE,recordIt)```

perform the necessary communication with the device. If you miss a function it can easily be included by updating the libU6.so file and the u6calls.jl file. Examples for 
"feedback" operation and "stream" mode are provided in the examples directory.

The code can be adapated to communicate with the U3 or U9 device.