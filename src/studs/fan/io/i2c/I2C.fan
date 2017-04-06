//
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    5 Apr 2017  Andy Frank  Creation
//

**
** I2C allows you to communicate over serial I2C interfaces.
**
** See [I2C]`../../doc/I2C.html` chapter for details.
**
class I2C
{
  ** Open a I2C port with given I2C bus name.
  ** Throws IOErr if port could not be opended.
  static I2C open(Str name)
  {
    try { return make(name) }
    catch (Err err) { throw IOErr("I2C.open failed", err) }
  }

  ** Private ctor.
  private new make(Str name)
  {
    this.name = name

    // spawn fani2c process
    this.proc = Proc { it.cmd=["/usr/bin/fani2c", "/dev/$name"] }
    this.proc.run.sinkErr

    // status check to verify running
    Pack.write(proc.out, ["op":"status"])
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
      proc = null
    }
    catch (Err err) { throw IOErr("I2C.close failed", err) }
  }

  ** Read 'len' bytes from the device at 'addr'.
  ** Throw IOErr if read failed.
  Buf read(Int addr, Int len)
  {
    if (proc == null) throw IOErr("Port not open")
    Pack.write(proc.out, ["op":"read", "addr":addr, "len":len])
    res := Pack.read(proc.in)
    checkErr(res)
    return res["data"]
  }

  ** Write the specified 'data' to the device at 'addr'.
  ** Throws IOErr if write failed. Return this.
  This write(Int addr, Buf data)
  {
    if (proc == null) throw IOErr("Port not open")
    Pack.write(proc.out, ["op":"write", "addr":addr, "len":data.size, "data":data])
    checkErr(Pack.read(proc.in))
    return this
  }

  ** Check pack message and throw Err if contains 'err' key.
  private Void checkErr(Str:Obj pack)
  {
    if (pack["status"] == "err")
      throw Err(pack["msg"] ?: "Unknown error")
  }

  private const Str name
  private Proc? proc := null
}