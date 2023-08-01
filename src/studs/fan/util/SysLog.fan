//
// Copyright (c) 2018, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//    5 Oct 2018  Andy Frank  Creation
//

using concurrent

**
** SysLog is a system wide in-memory ring buffer where all Daemon
** log messages are collected and made available to read.
**
const class SysLog
{
  ** Create new instance with given log history capacity.
  new make(Int capacity := 500)
  {
    this.capacity = capacity
    Log.addHandler |rec| { append(rec) }
  }

  ** Capacity if ring buffer before oldest entries are
  ** overwritten by newer entries.
  const Int capacity

  ** Generate an 'info' level log entry in root sys log.
  This debug(Str msg, Err? err := null)
  {
    append(LogRec(DateTime.now(null), LogLevel.debug, "sys", msg, err))
    return this
  }

  ** Generate an 'info' level log entry in root sys log.
  This info(Str msg, Err? err := null)
  {
    append(LogRec(DateTime.now(null), LogLevel.info, "sys", msg, err))
    return this
  }

  ** Generate an 'err' level log entry in root sys log.
  This err(Str msg, Err? err := null)
  {
    append(LogRec(DateTime.now(null), LogLevel.err, "sys", msg, err))
    return this
  }

  ** Append given 'rec' to ring buffer.
  This append(LogRec rec)
  {
    actor.send(DaemonMsg { it.op="append"; it.a=rec })
    return this
  }

  ** Read back current log entires.
  LogRec[] read()
  {
    actor.send(DaemonMsg { it.op="read" }).get(10sec)
  }

  ** Read entries in ring buffer. This method uses a non-thread safe
  ** copy of backing ring buffer, and as such may not represent the
  ** exact log state.
  @NoDoc Void each(|LogRec| func)
  {
    Unsafe u  := actor.send(DaemonMsg { it.op="buf" }).get
    RingBuf b := u.val
    b.each(func)
  }

  ** Read entries in ring buffer in reverse. This method uses a
  ** non-thread safe copy of backing ring buffer, and as such may
  ** not represent the exact log state.
  @NoDoc Void eachr(|LogRec| func)
  {
    Unsafe u  := actor.send(DaemonMsg { it.op="buf" }).get
    RingBuf b := u.val
    b.eachr(func)
  }

  ** Clear all log entries.
  @NoDoc Void clear()
  {
    actor.send(DaemonMsg { it.op="clear" })
  }

  private Obj? receive(DaemonMsg? msg)
  {
    RingBuf? buf := Actor.locals["r"]
    if (buf == null) Actor.locals["r"] = buf = RingBuf(capacity)

    switch (msg.op)
    {
      case "read":
        acc := LogRec[,]
        buf.each |r| { acc.add(r) }
        return acc.toImmutable

      case "append":
        buf.add(msg.a)
        return null

      case "buf":
        return Unsafe(buf)

      case "clear":
        buf.clear
        return null

      default: return null
    }
  }

  private const ActorPool pool := ActorPool { it.name = "SysLog" }
  private const Actor actor := Actor(pool) |msg| { receive(msg) }
}