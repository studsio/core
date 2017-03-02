//
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    2 Mar 2017  Andy Frank  Creation
//

using inet
using studs

class UartTest : Test
{
  Void testConfig()
  {
    c := UartConfig {}
    verifyConfig(c, 115200, 8, 1, "none", "none")

    c = UartConfig {
      it.speed  = 38400
      it.data   = 7
      it.stop   = 2
      it.parity = "odd"
      it.flow   = "hw"
    }
    verifyConfig(c, 38400, 7, 2, "odd", "hw")
  }

  private Void verifyConfig(UartConfig c, Int speed, Int data, Int stop, Str parity, Str flow)
  {
    verifyEq(c.speed,  speed)
    verifyEq(c.data,   data)
    verifyEq(c.stop,   stop)
    verifyEq(c.parity, parity)
    verifyEq(c.flow,   flow)
  }
}