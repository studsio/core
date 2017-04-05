# Spi

The [Spi](../api/studs/Spi.html) API allows you to communicate over serial
SPI interfaces.

## Basics

[config]:   ../api/studs/Spi.html
[open]:     ../api/studs/Spi.html#open
[transfer]: ../api/studs/Spi.html#transfer
[close]:    ../api/studs/Spi.html#close

Invoke [Spi.open][open] to open a SPI interface with a given
[SpiConfig][config]. Transfer and receive data using the [transfer][transfer]
method:

    spi  := Spi.open("spidev1.0", SpiConfig {})
    data := Buf().writeI4(0x1234_abcd)
    resp := spi.transfer(data)
    spi.close

Once you are finished with a pin, call [close][close] to free the backing
native process.
