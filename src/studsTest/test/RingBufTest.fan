//
// Copyright (c) 2021, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   16 Apr 2021  Andy Frank  Creation
//

using studs

class RingBufTest : Test
{
  Void testBasics()
  {
    r := RingBuf(3)
    verifyRingBuf(r, Str[,])
    r.add("a"); verifyRingBuf(r, ["a"])
    r.add("b"); verifyRingBuf(r, ["b", "a"])
    r.add("c"); verifyRingBuf(r, ["c", "b", "a"])
    r.add("d"); verifyRingBuf(r, ["d", "c", "b"])
    r.add("e"); verifyRingBuf(r, ["e", "d", "c"])
    r.add("f"); verifyRingBuf(r, ["f", "e", "d"])
    r.add("g"); verifyRingBuf(r, ["g", "f", "e"])

    // clear
    r.clear
    verifyRingBuf(r, Str[,])
  }

  private Void verifyRingBuf(RingBuf r, Obj?[] expected)
  {
    // each
    actual := Str[,]
    verifyEq(r.size, expected.size)
    r.each |val| { actual.add(val) }
    verifyEq(actual, expected)

    // eachr
    revActual := Str[,]
    revExpect := expected.dup.reverse
    r.eachr |val| { revActual.add(val) }
    verifyEq(revActual, revExpect)
  }
}