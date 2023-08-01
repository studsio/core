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
    r.add("b"); verifyRingBuf(r, ["a", "b"])
    r.add("c"); verifyRingBuf(r, ["a", "b", "c"])
    r.add("d"); verifyRingBuf(r, ["b", "c", "d"])
    r.add("e"); verifyRingBuf(r, ["c", "d", "e"])
    r.add("f"); verifyRingBuf(r, ["d", "e", "f"])
    r.add("g"); verifyRingBuf(r, ["e", "f", "g"])

    // clear
    r.clear
    verifyRingBuf(r, Str[,])
  }

  private Void verifyRingBuf(RingBuf r, Obj?[] expected)
  {
    expIndexes := Int[,]
    expected.each |v,i| { expIndexes.add(i) }

    // each
    actual  := Str[,]
    indexes := Int[,]
    verifyEq(r.size, expected.size)
    r.each |val,i|
    {
      actual.add(val)
      indexes.add(i)
    }
    verifyEq(actual, expected)
    verifyEq(indexes, expIndexes)

    // eachr
    revActual  := Str[,]
    revExpect  := expected.dup.reverse
    revIndexes := Int[,]
    r.eachr |val,i|
    {
      revActual.add(val)
      revIndexes.add(i)
    }
    verifyEq(revActual, revExpect)
    verifyEq(revIndexes, expIndexes.reverse)
  }
}