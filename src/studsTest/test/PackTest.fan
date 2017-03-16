//
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jan 2017  Andy Frank  Creation
//

using studs

class PackTest : Test
{
  Void testBasics()
  {
    // bool
    verifyBuf(["b":false], "706b 0004 0162 1000")
    verifyBuf(["b":true],  "706b 0004 0162 1001")

    // int
    verifyBuf(["i":0],   "706b 000b 0169 20 0000 0000 0000 0000")
    verifyBuf(["i":255], "706b 000b 0169 20 0000 0000 0000 00ff")

    // str
    verifyBuf(["s":"foo"],  "706b 0008 0173 40 0003 666f6f")

    // buf
    verifyBuf(["x":Buf().writeI4(0xdeadbeef)], "706b 0009 0178 50 0004 deadbeef")

    // mixed
    map := Str:Obj[:] { it.ordered=true }
    map["b"] = true
    map["i"] = 1000
    map["s"] = "cool"         // b      // i                        //s
    verifyBuf(map, "706b 0018 0162 1001 0169 20 0000 0000 0000 03e8 0173 40 0004 636f6f6c")
  }

  Void testNames()
  {
    verifyBuf(["foo":false], "706b 0006 03 666f6f 1000")

    // name too big
    x := ""; 256.times { x+="x" }
    verifyErr(ArgErr#) { Pack.encode([x:false]) }

    // non-ascii
    verifyErr(ArgErr#) { Pack.encode(["\u0019":false]) }
    verifyErr(ArgErr#) { Pack.encode(["\u007f":false]) }
    verifyErr(ArgErr#) { Pack.encode(["\u00ff":false]) }
  }

  Void testLists()
  {
    verifyBuf(["a":[true, 12, "foo"]],
      "706b 0016 0161 60 0003
       1001
       20 0000 0000 0000 000c
       40 0003 666f6f")
  }

  Void testMaps()
  {
    map := Str:Obj[:] {
      ordered = true
      it.set("x", true)
      it.set("y", 12)
      it.set("z", "foo")
    }
    verifyBuf(["a":map],
      "706b 001c 0161 70 0003
       0178 1001
       0179 20 0000 0000 0000 000c
       017a 40 0003 666f6f")
  }

  Void testIO()
  {
    map := Str:Obj[:] {
      ordered = true
      it.set("x", true)
      it.set("y", 12)
      it.set("z", "foo")
    }

    enc := "706b 0017
            0178 1001
            0179 20 0000 0000 0000 000c
            017a 40 0003 666f6f"

    verifyBuf(map, enc)

    f := tempDir + `test.pack`
    out := f.out
    Pack.write(out, map)
    out.flush.sync.close

    test := Pack.read(f.in)
    verifyBuf(test, enc)
  }

  private Void verifyBuf(Str:Obj map, Str hex)
  {
    buf := Pack.encode(map)
    verifyEq(buf.toHex, hex.split.join)

    test := Pack.decode(buf)
    verifyEq(map.size, test.size)

    mk := map.keys.sort
    tk := test.keys.sort
    verifyEq(mk.size, tk.size)
    mk.each |k,i|
    {
      t := tk[i]
      verifyEq(k, t)
      if (map[k] is Buf)
        verifyEq(map[k]->toHex, test[t]->toHex)
      else
        verifyEq(map[k], test[t])
    }
  }
}