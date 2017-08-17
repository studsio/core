//
// Copyright (c) 2017, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//    3 Apr 2017  Andy Frank  Creation
//

**
** Spi allows you to communicate over serial SPI interfaces.
**
** See [Spi]`../../doc/Spi.html` chapter for details.
**
**
class Spi
{
  ** Open a SPI port with given device name and config.
  ** Throws IOErr if port could not be opended.
  static Spi open(Str name, SpiConfig config)
  {
    try { return make(name, config) }
    catch (Err err) { throw IOErr("Spi.open failed", err) }
  }

  ** Private ctor.
  private new make(Str name, SpiConfig config)
  {
    this.name   = name
    this.config = config

    // spawn fanspi process
    this.proc = Proc {
      it.cmd=["/usr/bin/fanspi", "/dev/$name",
              "$config.mode", "$config.bits", "$config.speed", "$config.delay"]
    }
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
    catch (Err err) { throw IOErr("Spi.close failed", err) }
  }

  **
  ** Perform a SPI transfer. The 'data' should be a binary
  ** containing the bytes to send. Since SPI transfers
  ** simultaneously send and receive, the return value will
  ** be a 'Buf' of the same length.
  **
  Buf transfer(Buf data)
  {
    if (proc == null) throw IOErr("Port not open")
    Pack.write(proc.out, ["op":"transfer", "len":data.size, "data":data])
    res := Pack.read(proc.in)
    checkErr(res)
    return res["data"]
  }

  ** Check pack message and throw Err if contains 'err' key.
  private Void checkErr(Str:Obj pack)
  {
    if (pack["status"] == "err")
      throw Err(pack["msg"] ?: "Unknown error")
  }

  private const Str name
  private const SpiConfig config
  private Proc? proc := null
}