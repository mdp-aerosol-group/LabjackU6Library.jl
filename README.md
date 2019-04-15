# LabjackU6Library.jl
A Julia library to communicate with Labjack series U6 multifunction DAQ device

## Installation

Julia Package

```julia
pkg> add https://github.com/mdpetters/LabjackU6Library.jl.git
```

Debian dependencies:
```shell
sudo apt install libusb-1.0-0-dev
```

Labjack Exodriver:
```shell
cd ~/.julia/packages/LabjackU6library/XXXXX/dependencies/exodriver
```

where XXXXX is directory assigned by the Julia package manager

```shell
sudo ./install.sh
sudo reboot
```

