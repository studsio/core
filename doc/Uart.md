# Uart

TODO

## Enumerating Available Ports


## Working with a Uart

    port := Uartd.open("ttyS0")
    port.write("Hello")
    port.read
    port.close