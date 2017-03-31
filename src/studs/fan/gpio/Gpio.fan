//
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Mar 2017  Andy Frank  Creation
//

**
** Gpio
**
class Gpio
{
  ** Open a GPIO port with given pin and direction, where
  ** 'dir' is '"in"' or '"out"'.
  static Gpio open(Int pin, Str dir)
  {
    try { return make(pin, dir) }
    catch (Err err) { throw IOErr("Gpio.open failed", err) }
  }

  ** Private ctor.
  private new make(Int pin, Str dir)
  {
    // sanity checks
    if (pin < 0) throw ArgErr("Invalid pin '$pin'")
    if (dir != "in" && dir != "out") throw ArgErr("Invalid dir '$dir'")

    this.pin = pin
    this.dir = dir

    // spawn fangpio process
    this.proc = Proc { it.cmd=["/usr/bin/fangpio"] }
    this.proc.run.sinkErr

    // initiate open
    Pack.write(proc.out, ["op":"open", "pin":pin, "dir":dir])
    checkErr(Pack.read(proc.in))
  }

  ** Close this port.
  Void close()
  {
    if (proc == null) return
    try
    {
      Pack.write(proc.out, ["op":"exit"])
      proc.waitFor
    }
    catch (Err err) { throw IOErr("Gpio.close failed", err) }
  }

  ** Read the current value of the pin.
  Int read()
  {
    Pack.write(proc.out, ["op":"read"])
    res := Pack.read(proc.in)
    return res["val"]
  }

  **
  ** Write the given value to the GPIO. The GPIO should be
  ** configured as an output. Valid values are '0' for logic
  ** low, or '1' for logic high. Other non-zero values will
  ** result in logic high being output. Returns this.
  **
  This write(Int val)
  {
    Pack.write(proc.out, ["op":"write", "val":val==0])
    checkErr(Pack.read(proc.in))
    return this
  }

  ** Check pack message and throw Err if contains 'err' key.
  private Void checkErr(Str:Obj pack)
  {
    if (pack["status"] == "err")
      throw Err(pack["msg"] ?: "Unknown error")
  }

  private const Int pin
  private const Str dir
  private Proc? proc := null
}