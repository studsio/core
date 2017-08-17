//
// Copyright (c) 2016, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   24 Aug 2016  Andy Frank  Creation
//

using web

**
** Utilities for running and working with native processes.
**
const class Proc
{
  **
  ** Invoke the command string and return 0 if child process exited
  ** normally. If child process returns a non-zero exit code and
  ** 'checked' is true, then abort this process with an error message.
  ** If 'checked' is 'false' then return the child process error code.
  **
  ** By default, stdout will be redirected to /dev/null.  If 'stdout'
  ** is specified and is an 'OutStream' redirect to stream.  If a
  ** 'Buf' is passed, capture output in Buf.  Bufs will be flipped
  ** and ready to read when this method returns.
  **
  ** Stderr is always sent to 'Env.cur.err'.
  **
  static Int run(Obj cmd, Obj? stdout := null, Bool checked := true)
  {
    c := cmd as Str[] ?: cmd.toStr.split
    p := Process(c)
    p.out = (stdout as Buf)?.out ?: stdout
    r := p.run.join
    if (r != 0 && checked) Proc.abort("$p.command.first failed: $cmd")
    if (stdout is Buf) ((Buf)stdout).seek(0)
    return r
  }

  ** Convenience for `run` to evaluate a bash script.
  static Int bash(Str bash, Buf? out := null, Bool checked := true)
  {
    run(["bash", "-c", bash], out, checked)
  }

  ** Print the 'msg' and exit with error code.
  static Void abort(Str msg)
  {
    Env.cur.err.printLine(msg)
    Env.cur.exit(1)
  }

  ** Download content from URI and pipe to given file. Progress
  ** will be written to 'out' prefixed with 'msg'.
  static Void download(Str msg, Uri uri, File target)
  {
    out := target.out
    client := WebClient(uri)
    try
    {
      client.writeReq.readRes
      len := client.resHeaders["Content-Length"].toInt
      in  := client.resIn
      bsz := 4096                      // buf size to read at a time
      cur := 0                         // how many bytes have been read
      Int? read                        // bytes read on last attempt
      buf := Buf { it.capacity=bsz }   // read buffer

      while ((read = in.readBuf(buf.clear, bsz)) != null)
      {
        // pipe to target file
        out.writeBuf(buf.flip)

        // update progress
        cur += read
        per := (cur.toFloat / len.toFloat * 100f).toInt.toStr.padl(2)
        Env.cur.out.print("\r${msg}... ${per}%\r")
      }

      Env.cur.out.printLine("")
    }
    finally { client.close; out.close }
  }
}