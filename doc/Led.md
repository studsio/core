# LED

[linux]: https://www.kernel.org/doc/Documentation/leds/leds-class.txt

The [Led](../api/studs/Led.html) API manages LED state using `/sys/class/leds`.

See the [Linux documentation][linux] for details on how this `sysfs` works.

## On/Off

[on]:  ../api/studs/Led.html#on
[off]: ../api/studs/Led.html#off
[set]: ../api/studs/Led.html#set


Toggle LEDs on and off with the [on][on], [off][off], and [set][set] methods:

    Led.on("beaglebone:green:usr0")
    Led.off("beaglebone:green:usr0")
    Led.set("beaglebone:green:usr0", true)

## Blinking

[blink]: ../api/studs/Led.html#blink

Configure a LED to blink using the [blink][blink] methods, where the arguments
specify how long to leave the LED `on` and `off`:

    // on for 1sec; off for 500ms
    Led.blink("beaglebone:green:usr1", 1sec, 500ms)

## Triggers

[trigger]: ../api/studs/Led.html#trigger

A trigger is a kernel based source of LED events. Examples for the `bb` are
`heartbeat`, `mmc0`, `cpu0`.  Consult your platform for available triggers and
see the [Linux documentation][linux] for low level details.

    Led.trigger("beaglebone:green:usr2", "heartbeat")