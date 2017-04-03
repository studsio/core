# Gpio

The [Gpio](../api/studs/Gpio.html) API provides high level access to GPIO pins
through the Linux sysclass interface.

# Basics

    g := Gpio.open(18, "out")
    g.write(1)
    g.read
    g.close

# Listening for Changes

[listen]: ../api/studs/Gpio.html#listen

To monitor changes to a GPIO pin output, you can use [Gpio.listen][listen].
This method will register an interrupt handler and efficiently poll for pin
state changes:

    g := Gpio.open(18, "out")
    i := 0

    g.listen |val|
    {
      echo("Pin is now $val")
      if (++i == 5) g.close
    }

    echo("Pin was read 5 times")
