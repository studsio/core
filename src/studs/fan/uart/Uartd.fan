//
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Jan 2017  Andy Frank  Creation
//

using concurrent

**
** Uartd
**
const class Uartd : Daemon
{
  new make() : super(null) {}

  ** Get the Uartd instance for this vm.  If an instance is
  ** not found, throw Err if 'checked' otherwise reutrn null.
  static Uartd? cur(Bool checked := true)
  {
    d := Actor.locals["d.uartd"]
    if (d == null && checked) throw Err("Uartd instance not found")
    return d
  }

  ** List the available uart ports on this device.
  Str:Obj ports()
  {
    p := Proc { it.cmd=["/usr/bin/fanuart", "enum"] }
    p.run.sinkErr.waitFor.okOrThrow
    return Pack.read(p.in)
  }

  ** Open the serial port 'name' with given config. Throws
  ** IOErr if port cannot be opened.
  UartPort open(Str name, UartConfig config)
  {
    msg := DaemonMsg { it.op="open"; it.a=name; it.b=config }
    Unsafe unsafe := send(msg).get(5sec)
    return unsafe.val
  }

  ** Close the serial port 'name'.  If port was not open, this
  ** method does nothing.
  Void close(Str name)
  {
    send(DaemonMsg { it.op="close"; it.a=name }).get(5sec)
  }

  ** Internal actor.
  protected override Obj? onMsg(DaemonMsg m)
  {
    lock := Actor.locals["lock"] as Str:UartPort
    if (lock == null) Actor.locals["lock"] = lock = Str:UartPort[:]

    if (m.op == "open")
    {
      if (lock[m.a] != null) throw IOErr("Port already open $m.a")
      proc := Proc { it.cmd=["/usr/bin/fanuart"] }.run.sinkErr
      port := UartPort(proc)
      lock[m.a] = port
      return Unsafe(port)
    }

    if (m.op == "close")
    {
      // TODO: this has some fishy concurrent semantics
      // we really should be processing all this on the
      // same thread as UartPort instance
      p := lock[m.a] as UartPort
      if (p == null) return null
      Pack.write(p.proc.out, ["op":"exit"])
      p.proc.waitFor
      lock.remove(m.a)
    }

    return null
  }
}