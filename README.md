# VGA interface for Commodore CBM-II computers

This project adds a VGA interface to Commodore CBM-II machines. The board can be installed in both low-profile and high-profile machines and adds a VGA connector which mirrors the main display.

## Project aims

This is a VGA **interface**, not a VGA **graphics card**. It does not add any graphical capabilities to your computer besides those it already possesses. What it does is to allow you to connect your computer to a modern VGA display (or a VGA-to-HDMI converter), giving you a better quality picture than a composite video output.

Due to the nature of its operation (explained below), it will also allow you to check the operation of your computer if you don't get any display from it. Since it does not depend on the inbuilt video circuitry, you can check if the CPU is booting even if the primary display is not working.

## Project status

The hardware part is ready. You can find the PCB files from the `eagle` directory. There are two PCBs: main board (to be installed in an expansion socket on the mainboard) and connector board (to be installed, for example, on the metal backplate). The boards are connected via a 2x5 pin header cable (for example, a JTAG cable).

The firmware is not yet completed but it is usable enough. It displays the picture, allows for cursor positioning and switching between text and graphics mode. These features are enough to use your computer. Advanced CRTC functions (such as changing the cursor shape) are not yet supported. You can find the current firmware binary in the `firmware` directory. You need to program the onboard 24C256 EEPROM chip with the firmware.

## How it works?

The board is centered around a Propeller v1 chip which generates a 640x480 VGA video signal. The chip is programmed to silently sniff signals on the 6509 CPU bus and react to writes to the I/O area. Through this it maintains its own copy of the video memory as well as the CRTC and TPI registers, which allows it to re-create the screen contents and display it on the VGA connector.

This way the board does not need any changes in the KERNAL video routines. Also, since it doesn't use the original video signal in ay way, you can use the board even if the primary video circuitry of the computer is not working.

## Advanced stuff

The board is also meant to be used with the 8088 board. To that end it provides a second display mode which is compatible with IBM MDA display. This mode uses an IBM 8x16 font and recognizes all MDA attributes (bright, invert, underline, blink). This mode is not yet fully supported - stay tuned for future releases.

There is a second connector on the board labeled `INPUT`. It is meant for daisy-chaining a secondary video board which is in a planning stage.
