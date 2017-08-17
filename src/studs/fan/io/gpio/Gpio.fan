//
// Copyright (c) 2017, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   30 Mar 2017  Andy Frank  Creation
//

using concurrent

**
** Gpio provides high level access to GPIO pins through the Linux
** '/sys/class/gpio' interface.
**
** See [Gpio]`../../doc/Gpio.html` chapter for details.
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
    return res["val"] == false ? 0 : 1
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
    Pack.write(proc.out, ["op":"write", "val":val==0 ? false : true])
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
  ** If 'timeout' is non-null, then 'callback' will be invoked
  ** at every duration of 'timeout' regardless of whether a state
  ** change occurred.  If 'timeout' is null, this method blocks
  ** until a state change is detected.
  **
  ** Note that after calling 'listen', you will receive an initial
  ** callback with the state of the pin. This prevents the race
  ** condition between getting the initial state of the pin and
  ** turning on interrupts.
  **
  Void listen(Str mode, Duration? timeout, |Int val| callback)
  {
    // check mode
    if (mode != "rising" && mode != "falling" && mode != "both")
      throw ArgErr("Invalid mode '$mode")

    // register interrupt
    Pack.write(proc.out, ["op":"listen", "mode":mode])
    checkErr(Pack.read(proc.in))

    // block until proc exists
    while (proc != null)
    {
      if (timeout != null)
      {
        trigger := Duration.nowTicks + timeout.ticks
        while (proc.in.avail == 0)
        {
          if (Duration.nowTicks >= trigger)
          {
            Pack.write(proc.out, ["op":"read"])
            break
          }
          Actor.sleep(10ms)
        }
      }

      res := Pack.read(proc.in)
      checkErr(res)
      callback(res["val"] == false ? 0 : 1)
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