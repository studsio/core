# Gpio

The [Gpio](../api/studs/Gpio.html) API provides high level access to GPIO pins
through the Linux `/sys/class/gpio` interface.

## Basics

[open]:  ../api/studs/Gpio.html#open
[read]:  ../api/studs/Gpio.html#read
[write]: ../api/studs/Gpio.html#write
[close]: ../api/studs/Gpio.html#close

Invoke [Gpio.open][open] to open a given GPIO pin number and direction. Use
[read][read] and [write][write] to read and toggle the pin value:

    g := Gpio.open(18, "out")
    g.write(1)
    g.read
    g.close

Once you are finished with a pin, call [close][close] to free the backing
native process.

## Listening for Changes

[listen]: ../api/studs/Gpio.html#listen

To monitor changes to a GPIO pin output, you can use [Gpio.listen][listen].
This method will register an interrupt handler that triggers on the rising,
falling, or both edges and efficiently poll for pin state changes:

    g := Gpio.open(18, "out")
    i := 0

    g.listen("falling") |val|
    {
      echo("Pin is now $val")
      if (++i == 5) g.close
    }

    echo("Pin was read 5 times")
