//
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    3 Apr 2017  Andy Frank  Creation
//

**
** Spi
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
      it.cmd=["/usr/bin/fanspi", name,
              "$config.mode", "$config.bits", "$config.speed", "$config.delay"]
    }
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
    catch (Err err) { throw IOErr("Spi.close failed", err) }
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