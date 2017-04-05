//
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    3 Apr 2017  Andy Frank  Creation
//

using concurrent

**
** SpiConfig models configuration for a `Spi` port.
**
const class SpiConfig
{
  ** It-block constructor.
  new make(|This| f)
  {
    f(this)
    if (mode < 0 || mode > 3)    throw ArgErr("Invalid mode '$mode'")
    if (bits != 8 && bits != 16) throw ArgErr("Invalid bits '$bits'")
    if (speed <= 0)              throw ArgErr("Invalid speed '$speed'")
    if (delay <= 0)              throw ArgErr("Invalid delay '$delay'")
  }

  ** Mode specifies the clock polarity and phase to use (0..3)
  const Int mode := 0

  ** Number of bits per word on the bus (8 or 16; defaults to 8)
  const Int bits := 8

  ** Bus speed in hertz (defaults to 1 MHz)
  const Int speed := 1_000_000

  ** The delay between transactions in microseconds (defaults to 10us)
  const Int delay := 10
}
