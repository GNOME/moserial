# moserial

moserial is a clean, friendly gtk-based serial terminal for the gnome desktop. It is written in [Vala](https://wiki.gnome.org/Vala).

## Features

- ASCII and HEX views of incoming and outgoing data
- Logging to file of incoming and/or outgoing data
- Support for x, y, and z-modem file send and receive
- Support for profile files, to load/save common configurations
- Easier to use than the alternatives
- Supports i18n
- It even has docs! 

For more information see [GNOME wiki](https://wiki.gnome.org/Apps/Moserial).

## Build

### Dependencies

Install the following build dependencies:

`sudo apt-get install libglib2.0-dev yelp-tools graphviz-dev libgtk-3-dev`

At least libgtk v3.20 is required.

Get the Vala compiler from [here](https://download.gnome.org/sources/vala/)
Required version v0.48.5 or later.

Extract files to folder then run inside that folder:
```
./configure
make
sudo make install
```

### Manually build

```
git clone https://github.com/Mictronics/moserial
cd moserial/
```
On 32 bit systems:
```
./autogen.sh --prefix=/usr 
make
```
On 64 bit systems:
```
./autogen.sh --prefix=/usr --libdir '/usr/lib64' --build x86_64 
make
```
Optional:
`sudo make install`

### Build issues

A. If you see this error:
   src/SerialConnection.c:31:21: fatal error: stropts.h: No such file or directory

   then either:

   1. sudo touch /usr/include/stropts.h

   or

   2. patch your posix.vapi file as described at
   http://bugzilla.gnome.org/show_bug.cgi?id=656690#c3

B. moserial does not implement the xmodem, ymodem, or zmodem protocols
   directly. It relies on the standard rz and sz utilities to send and
   receive data. These utilities, part of the lrzsz package, must be
   installed on your system.
