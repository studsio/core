//
// Copyright (c) 2017, Andy Frank
// Licensed under the Apache License version 2.0
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
    verifyConfig(c, 9600, 8, 1, "none", "none", "9600-8-1-none-none")

    c = UartConfig {
      it.speed  = 38400
      it.data   = 7
      it.stop   = 2
      it.parity = "odd"
      it.flow   = "hw"
    }
    verifyConfig(c, 38400, 7, 2, "odd", "hw", "38400-7-2-odd-hw")
  }

  private Void verifyConfig(UartConfig c, Int speed, Int data, Int stop, Str parity, Str flow, Str ser)
  {
    // test fields
    verifyEq(c.speed,  speed)
    verifyEq(c.data,   data)
    verifyEq(c.stop,   stop)
    verifyEq(c.parity, parity)
    verifyEq(c.flow,   flow)

    // test serialization
    verifyEq(c.toStr, ser)
    x := UartConfig.fromStr(ser)
    verifyEq(x.speed,  c.speed)
    verifyEq(x.data,   c.data)
    verifyEq(x.stop,   c.stop)
    verifyEq(x.parity, c.parity)
    verifyEq(x.flow,   c.flow)
  }

  Void testStreamRead()
  {
    // internal test for how UartInStream reads from Uart.read Buf blocks
    buf := Buf()
    5.times
    {
      if (buf.pos == buf.size) buf.clear.writeBuf(genBuf.seek(0)).seek(0)
      verifyEq(buf.read, 'a'); verifyNotEq(buf.pos, buf.size)
      verifyEq(buf.read, 'b'); verifyNotEq(buf.pos, buf.size)
      verifyEq(buf.read, 'c'); verifyNotEq(buf.pos, buf.size)
      verifyEq(buf.read, 'd'); verifyNotEq(buf.pos, buf.size)
      verifyEq(buf.read, 'e'); verifyEq(buf.pos, buf.size)
      verifyEq(buf.read, null)
    }
  }

  private Buf genBuf()
  {
    Buf().print("abcde")
  }
}