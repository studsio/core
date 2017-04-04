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
    this.proc = Proc { it.cmd=["/usr/bin/fangpio", pin.toStr, dir] }
    this.proc.run.sinkErr
  }

  ** Close this port.
  Void close()
  {
    if (proc == null) return
    try
    {
      Pack.write(proc.out, ["op":"exit"])
      proc.waitFor
      proc = null
    }
    catch (Err err) { throw IOErr("Gpio.close failed", err) }
  }

  ** Read the current value of the pin.
  Int read()
  {
    if (proc == null) throw IOErr("Gpio port not open")
    Pack.write(proc.out, ["op":"read"])
    res := Pack.read(proc.in)
    checkErr(res)
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
    if (proc == null) throw IOErr("Gpio port not open")
    Pack.write(proc.out, ["op":"write", "val":val==0])
    checkErr(Pack.read(proc.in))
    return this
  }

  **
  ** Register an interrupt handler to listen for GPIO output
  ** changes. The 'mode' should be one of the strings "rising",
  ** "falling" or "both" to indicate which edge(s) the ISR is
  ** to be triggered on. Invoke the given callback function when
  ** a change occurs. This method will block listening until
  ** `close` is called.
  **
  Void listen(Str mode, |Int val| callback)
  {
    // check mode
    if (mode != "rising" && mode != "falling" && mode != "both")
      throw ArgErr("Invalid mode '$mode")

    // register interrupt
    Pack.write(proc.out, ["op":"listen"])
    checkErr(Pack.read(proc.in))

    // block until proc exists
    while (proc != null)
    {
      res := Pack.read(proc.in)
      checkErr(res)
      callback(res["val"])
    }
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