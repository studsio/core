# LEDs

TODO

    // toggle LEDs on/off
    Led.on("beaglebone:green:usr0")
    Led.off("beaglebone:green:usr0")
    Led.set("beaglebone:green:usr0", true)

    // blink LEDS
    Led.blink("beaglebone:green:usr1", 1sec, 500ms)

    // assign trigger
    Led.trigger("beaglebone:green:usr2", "heartbeat")