//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Sep 2016  Andy Frank  Creation
//

using [java] java.lang
using [java] java.lang::Process as JProcess
using [java] fanx.interop::Interop

**
** Proc manages spawning an external OS process.  This class differs
** from sys::Process by optimizing the API for interaction with the
** child process over stdio.
**
class Proc
{
  ** It-block constructor.
  new make(|This| f) { f(this) }

  ** Command argument list used to launch process. The first
  ** item is the executable itself, then rest are the parameters.
  const Str[] cmd

  ** Working directory for child process.
  const File? dir := null

  ** Environment variables to pass to child process. This map
  ** is initialized with the current process environment.
  const Str:Str env := [:]

  ** If 'true', then stderr is redirected to stdout.
  const Bool redirectErr := true

  ** Spawn the child process. See `waitFor` to block until the
  ** process has terminated, and `exitCode` to retreive process
  ** exit code.
  This run()
  {
    if (p != null) throw Err("Proc already running")

    b := ProcessBuilder(cmd)
    if (dir != null) b.directory(Interop.toJava(dir))
    if (redirectErr) b.redirectErrorStream(true)
    env.each |k,v| { b.environment.put(k,v) }
    this.p = b.start
    return this
  }

  ** Return OutStream used to write to process stdin.
  OutStream out()
  {
    if (p == null) throw Err("Proc not running")
    return Interop.toFan(p.getOutputStream)
  }

  ** Return InStream used to read process stdout.
  InStream in()
  {
    if (p == null) throw Err("Proc not running")
    return Interop.toFan(p.getInputStream)
  }

  ** Return InStream used to read process stderr.
  InStream err()
  {
    if (p == null) throw Err("Proc not running")
    return Interop.toFan(p.getErrorStream)
  }

  ** Return 'true' if child process is currently running
  ** or 'false' if not started or terminated.
  Bool isRunning()
  {
    if (p == null) return false
    try { x := p.exitValue; return true }
    catch { return false }
  }

  ** Block the current thread until the child process has
  ** terminated. Use `exitCode` to retreive exit code.
  This waitFor()
  {
    if (p == null) return this
    p.waitFor
    return this
  }

  ** Kill the child process. Use `waitFor` to block until the
  ** process has terminated.
  This kill()
  {
    if (p == null) return this
    p.destroy
    return this
  }

  ** Return the exit code for child process, 'null' if process
  ** has not started, or throws Err if process has not yet
  ** terminated.
  Int? exitCode()
  {
    if (p == null) return null
    return p.exitValue
  }

  private JProcess? p
}
