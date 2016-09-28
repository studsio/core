//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Sep 2016  Andy Frank  Creation
//

using concurrent
using studs

class ProcTest : Test
{
  Void testSimple()
  {
    p := Proc { it.cmd=["echo", "hello"] }
    r := p.run.waitFor.exitCode
    x := p.in.readLine
    verifyEq(r, 0)
    verifyEq(x, "hello")
    x = p.in.readLine
    verifyEq(x, null)
  }

  Void testIn()
  {
    p := Proc { it.cmd=["echo", "alpha\nbeta\ngamma"] }
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

  Void testIsRunning()
  {
    p := Proc { it.cmd=["bash", bash("sleep 2").osPath] }
    verifyEq(p.isRunning, false)
    p.run
    verifyEq(p.isRunning, true)
    Actor.sleep(1sec)
    verifyEq(p.isRunning, true)
    Actor.sleep(2sec)
    verifyEq(p.isRunning, false)
  }

  Void testExitCode()
  {
    p := Proc { it.cmd=["bash", bash("exit 0").osPath] }
    verifyEq(p.run.waitFor.exitCode, 0)

    p = Proc { it.cmd=["bash", bash("exit 1").osPath] }
    verifyEq(p.run.waitFor.exitCode, 1)

    p = Proc { it.cmd=["bash", bash("exit 2").osPath] }
    verifyEq(p.run.waitFor.exitCode, 2)
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
