//
// Copyright (c) 2017, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//    2 Mar 2017  Andy Frank  Creation
//

using concurrent

**
** UartConfig models configuration for a `Uart` port.
**
const class UartConfig
{
  ** It-block constructor.
  new make(|This| f)
  {
    f(this)
    if (speed <= 0)                throw ArgErr("Invalid speed '$speed'")
    if (data < 5 || data > 8)      throw ArgErr("Invalid data '$data'")
    if (stop < 1 || stop > 2)      throw ArgErr("Invalid stop 'stop'")
    if (!paritys.contains(parity)) throw ArgErr("Invalid parity '$parity'")
    if (!flows.contains(flow))     throw ArgErr("Invalid flow '$flow'")
  }

  ** Baud rate (ex: 9600, 38400, 115200)
  const Int speed := 9600

  ** Number of data bits to use (5..8)
  const Int data := 8

  ** Number of stop bits to use (1.2)
  const Int stop := 1

  ** Parity mode: 'none', 'even', 'odd'
  const Str parity := "none"

  ** Flow control mode: 'none', 'hw', or 'sw'
  const Str flow := "none"

  ** Get string serialization for config instance.
  override Str toStr()
  {
    "${speed}-${data}-${stop}-${parity}-${flow}"
  }

  ** Parse a UartConfig instance from Str. See `toStr`.
  static new fromStr(Str s, Bool checked := true)
  {
    try
    {
      p := s.split('-')
      return UartConfig {
        it.speed  = p[0].toInt
        it.data   = p[1].toInt
        it.stop   = p[2].toInt
        it.parity = p[3]
        it.flow   = p[4]
      }
    }
    catch (Err err)
    {
      if (!checked) return null
      throw ParseErr("Invalid uart config string '${s}'")
    }
  }

  private static const Str[] paritys := ["none", "even", "odd"]
  private static const Str[] flows   := ["none", "hw", "sw"]
}
