//
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    2 Mar 2017  Andy Frank  Creation
//

using concurrent

**************************************************************************
** UartConfig
**************************************************************************

** UartConfig models configuration for a `UartPort`
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
  const Int speed := 115200

  ** Number of data bits to use (5..8)
  const Int data := 8

  ** Number of stop bits to use (1.2)
  const Int stop := 1

  ** Parity mode: 'none', 'even', 'odd'
  const Str parity := "none"

  ** Flow control mode: 'none', 'hw', or 'sw'
  const Str flow := "none"

  private static const Str[] paritys := ["none", "even", "odd"]
  private static const Str[] flows   := ["none", "hw", "sw"]
}

**************************************************************************
** UartPort
**************************************************************************

** UartPort models a UART port instance.
class UartPort
{
  ** Internal constructor.
  internal new make(Proc proc) { this.proc = proc }

  Void test()
  {
    Pack.write(proc.out, ["op":"foo"])
  }

  internal Proc proc
}



