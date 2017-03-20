//
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Mar 2017  Andy Frank  Creation
//

**
** Uart models a UART port instance.
**
class Uart
{
  ** List the available uart ports on this device.
  static Str:Obj list()
  {
    p := Proc { it.cmd=["/usr/bin/fanuart", "enum"] }
    p.run.sinkErr.waitFor.okOrThrow
    return Pack.read(p.in)
  }

  ** Open the serial port 'name' with given config. Throws
  ** IOErr if port cannot be opened.
  This open(Str name, UartConfig config)
  {
    if (proc != null) throw IOErr("Uart already open")
    try
    {
      // spawn fanuart process
      this.proc = Proc { it.cmd=["/usr/bin/fanuart"] }
      this.proc.run.sinkErr

      // initiate open
      Pack.write(proc.out, ["op":"open", "name":name])
      checkErr(Pack.read(proc.in))

      // setup streams
      _in  = UartInStream(this)
      _out = UartOutStream(this)
      return this
    }
    catch (Err err) { throw IOErr("Uart.open failed", err) }
  }

  ** Close this port.
  Void close()
  {
    if (proc == null) return
    try
    {
      // close port
      Pack.write(proc.out, ["op":"close"])
      checkErr(Pack.read(proc.in))
      _in  = null
      _out = null

      // exit proc
      Pack.write(proc.out, ["op":"exit"])
      proc.waitFor
    }
    catch (Err err) { throw IOErr("Uart.close failed", err) }
  }

  ** TODO
  Buf? read()
  {
    Pack.write(proc.out, ["op":"read"])
    res := Pack.read(proc.in)
    checkErr(res)
    return res["data"] as Buf
  }

  ** TODO
  Void write(Buf buf)
  {
  }

  ** Get an `InStream` to read this port.
  ** Throws IOErr if port not open.
  InStream in()
  {
    if (proc == null) throw IOErr("Port not open")
    return _in
  }

  ** Get an `OutStream` to write to this port.
  ** Throws IOErr if port not open.
  OutStream out()
  {
    if (proc == null) throw IOErr("Port not open")
    return _out
  }

  ** Check pack message and throw Err if contains 'err' key.
  private Void checkErr(Str:Obj pack)
  {
    msg := pack["err"]
    if (msg == null) return
    throw Err(msg)
  }

  private Proc? proc := null
  private InStream? _in   := null
  private OutStream? _out := null
}