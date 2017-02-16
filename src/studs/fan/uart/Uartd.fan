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
  Str[] ports()
  {
    p := Proc { it.cmd=["/usr/bin/fanuart"] }
    p.run.waitFor.okOrThrow
    return p.in.readAllLines
  }
}