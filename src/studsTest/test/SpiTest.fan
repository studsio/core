//
// Copyright (c) 2017, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//    5 Apr 2017  Andy Frank  Creation
//

using inet
using studs

class SpiTest : Test
{
  Void testConfig()
  {
    c := SpiConfig {}
    verifyConfig(c, 0, 8, 1_000_000, 10)

    c = SpiConfig {
      it.mode   = 3
      it.bits   = 16
      it.speed  = 500_000
      it.delay  = 20
    }
    verifyConfig(c, 3, 16, 500_000, 20)
  }

  private Void verifyConfig(SpiConfig c, Int mode, Int bits, Int speed, Int delay)
  {
    verifyEq(c.mode,  mode)
    verifyEq(c.bits,  bits)
    verifyEq(c.speed, speed)
    verifyEq(c.delay, delay)
  }
}