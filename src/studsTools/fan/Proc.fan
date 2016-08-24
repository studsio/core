//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
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
  ** Invoke the command string and return 0 if child process exited
  ** normally. If child process returns a non-zero exit code and
  ** 'checked' is true, then abort this process with an error message.
  ** If 'checked' is 'false' then return the child process error code.
  static Int run(Obj cmd, Bool checked := true)
  {
    c := cmd as Str[] ?: cmd.toStr.split
    p := Process(c)
    p.out = null
    r := p.run.join
    if (r != 0 && checked) Proc.abort("$p.command.first failed: $cmd")
    return r
  }

  ** Convenience for `run` to evaluate a bash script.
  static Int bash(Str bash, Bool checked := true)
  {
    run(["bash", "-c", bash])
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
    tout   := target.out
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
        // pipe to temp file
        tout.writeBuf(buf.flip)

        // update progress
        cur += read
        per := (cur.toFloat / len.toFloat * 100f).toInt.toStr.padl(2)
        Env.cur.out.print("\r${msg}... ${per}%\r")
      }

      Env.cur.out.printLine("")
    }
    finally { client.close; tout.close }
  }
}