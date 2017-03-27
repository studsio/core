# Using UART to read GPS module

In this tutorial we'll cover how to wire up your BeagleBone Black to Adafruit's
Ultimate GPS Breakout (MTK3339) and read GPS locations over the UART serial
interface.

## Requirements

[setup]: ../doc/GettingStarted.html
[gps]:   https://www.adafruit.com/product/746

 - [Setup Studs][setup]
 - BeagleBone Black
 - Adafruit Ultimate GPS Breakout -- $40 from [Adafruit][gps]

## Wiring

TODO

## Coding

First create a new project:

    $ fan studs init uartgps

Next edit your `src/fan/Main.fan` to look like:

    using studs
    using concurrent

    const class Main
    {
      static Int main()
      {
        // enable UART1
        DeviceTree.enable("BB-UART1")

        // open uart and read forever
        uart := Uart().open("ttyS1", UartConfig {})
        while (true)
        {
          try
          {
            line := uart.in.readLine
            echo("# $line")
          }
          catch (Err err) { err.trace }
        }

        // never get here; but close and return
        uart.close
        return 0
      }
    }

### Enable UART1

UART1 is disabled by default on the BBB, so the first thing we need todo is
enable it using a device tree overlay, which is done with the following code:

    // enable UART1
    DeviceTree.enable("BB-UART1")

The `ttyS1` serial port will now be available for use.

### Open port

Next we need to open the UART with the appropriate configuration options. The
GPS module happens to use the default config (`9600-8n1`) so we can pass in the
defaults:

    uart := Uart().open("ttyS1", UartConfig {})

### Read port

In our example code, we will loop forever dumping what we read from the GPS
module to stdout:

    line := uart.in.readLine
    echo("# $line")

The `uart.in.readLine` will block until data is available and read up to the
next `CRLF` terminator.

## Running

To build and run your project:

    $ src/build.fan
    $ fan studs asm
    $ fan studs burn

Insert your SD card and power up your BBB. If you have the serial console
connected to your PC you should start seeing the stdout from our application.
