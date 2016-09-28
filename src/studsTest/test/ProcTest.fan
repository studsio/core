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

    p = Proc { it.cmd=["echo", "alpha\nbeta\ngamma"] }
    verifyEq(p.run.waitFor.exitCode, 0)
    verifyEq(p.in.readLine, "alpha")
    verifyEq(p.in.readLine, "beta")
    verifyEq(p.in.readLine, "gamma")
    verifyEq(p.in.readLine, null)

    p = Proc { it.cmd=["bash", bash(s1).osPath] }
    p.run
    verifyEq(p.in.readLine, "alpha")
    verifyEq(p.in.readLine, "beta")
    verifyEq(p.in.readLine, "gamma")
    verifyEq(p.in.readLine, null)
    p.waitFor
    verifyEq(p.exitCode, 0)
    verifyEq(p.in.readLine, null)
  }

  private File bash(Str bash)
  {
    f := File.createTemp.deleteOnExit
    f.out.printLine(bash).flush.sync.close
    return f
  }

  private static const Str s1 :=
    """echo "alpha"; sleep 1
       echo "beta";  sleep 1
       echo "gamma"; sleep 1"""
}
