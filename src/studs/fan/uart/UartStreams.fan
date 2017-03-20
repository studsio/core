//
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Mar 2017  Andy Frank  Creation
//

**************************************************************************
** UartInStream
**************************************************************************

internal class UartInStream : InStream
{
  new make(Uart uart) : super(null)
  {
    this.uart = uart
  }

  override Int avail()
  {
    if (pushback != null && !pushback.isEmpty) return pushback.size
    if (inbuf.size > 0) return inbuf.size
    // TODO: poll proc
    return 0
  }

  override Int? read()
  {
    // first check pushback
    if (pushback != null && !pushback.isEmpty) return pushback.pop

    // read from proc if local buffer is empty
    if (inbuf.pos == inbuf.size)
      inbuf.clear.writeBuf(uart.read.seek(0)).seek(0)

    return inbuf.read
  }

  override This unread(Int b)
  {
    if (pushback == null) pushback = Int[,]
    pushback.push(b)
    return this
  }

  override Int? readBuf(Buf buf, Int n)
  {
    r := 0
    while (r < n)
    {
      buf.write(read)
      r++
    }
    return r
  }

  private Uart uart
  private Buf inbuf := Buf(4096)
  private Int[]? pushback
}

**************************************************************************
** UartOutStream
**************************************************************************

internal class UartOutStream : OutStream
{
  new make(Uart uart) : super(null)
  {
    this.uart = uart
  }

  override This write(Int b)
  {
    // TODO
    return this
  }

  override This writeBuf(Buf buf, Int n := buf.remaining)
  {
    // TODO
    // start := buf.pos
    // while (buf.pos < start+n) write(buf.read)
    return this
  }

  private Uart uart
}