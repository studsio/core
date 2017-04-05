# I2C

The [I2C](../api/studs/I2C.html) API allows you to communicate over serial
I2C interfaces.

## Basics

[open]:  ../api/studs/I2C.html#open
[read]:  ../api/studs/I2C.html#read
[write]: ../api/studs/I2C.html#read
[close]: ../api/studs/I2C.html#close

Invoke [I2C.open][open] to open a I2C interface with a given I2C bus name.
Read and write data to devices using [read][read] and [write][write], where
`addr` is the 7-bit address on the I2C bus:

    i2c  := I2C.open("i2c-1")
    i2c.write(5, Buf().writeI4(0x1234_abcd))
    bytes := i2c.read(5, 4)
    i2c.close

Once you are finished, call [close][close] to free the backing native process.
