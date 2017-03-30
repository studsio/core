# Uart

The [Uart](../api/studs/Uart.html) API allows you to communicate over serial
UART interfaces.

## Enumerating Ports

[Uart.list](../api/studs/Uart.html#list) will enumerate the current serial
ports as a `Str:Obj` map, where the keys are the port names and the values are
the available meta-data about each port:

    [ "ttyS0": [:],
      "ttyUSB1": [
       "desc":"USB Serial Port", "man":"FTDI", "pid":24577, "vid":1027
      ]
    ]

## Working with a Uart

[open]:  ../api/studs/Uart.html#open
[close]: ../api/studs/Uart.html#close
[in]:    ../api/studs/Uart.html#in
[out]:   ../api/studs/Uart.html#out

Open and close a serial port using [open][open] and [close][close]:

    uart := Uart().open("ttyS0", UartConfig {})
    uart.close

Read and write data using the standard Fantom I/O streams with [in][in] and
[out][out]:

    uart.in.readLine
    uart.out.printLine("foobar")