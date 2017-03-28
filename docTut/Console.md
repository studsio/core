# Connecting PC to BBB serial console

How to connect your PC to the serial console on the BeagleBone Black. The serial
console will allow you to view stdout as well as access the Linux shell.

## USB-to-TTL serial cable

The console is configured to output to `ttyS0` by default. This is the UART
output accessible by the 6 pin header labeled J1. A 3.3V FTDI cable is needed
to access the output.

These cables are available from:

 - [Adafruit](https://www.adafruit.com/products/70)
 - [Sparkfun](https://www.sparkfun.com/products/9717)
 - [Digikey](http://www.digikey.com/product-detail/en/TTL-232R-3V3/768-1015-ND/1836393)

Pin 1 on the cable is the black wire and connects to pin 1 on the board, the
pin with the white dot next to it.

## Opening a serial session

On macOS and Linux you can use the `screen` command to open a serial session to
the BBB:

    $ screen /dev/tty.usbserial 115200

The actual device name `tty.usbserial` will vary. It will typically include
`usb` somewhere in the name. You can use tab completion to search for the
correct device. You can also `ls /dev` before and after inserting your USB
cable and see what new port shows up.

Power on your BBB and you should now be able to view the stdout as Linux boots
and your application is started.

To access the shell, make sure you configure `faninit.props` for `exit.action`
and `exit.run`:

    exit.action=hang
    exit.run=/bin/sh

With these settings, when your Fantom application exits, or you press `Ctrl+C`
from the console, you will exit to a Linux shell.