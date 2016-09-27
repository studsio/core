//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Sep 2016  Andy Frank  Creation
//

using studs

class ProcTest : Test
{
  Void test()
  {
    p := Proc { it.cmd=["echo", "hello"] }
    r := p.run.waitFor.exitCode
    x := p.in.readLine

    verifyEq(r, 0)
    verifyEq(x, "hello")

    x = p.in.readLine
    verifyEq(x, null)
  }
}
