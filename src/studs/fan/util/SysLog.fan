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
  new make(Int capacity := 5000)
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

  ** Read back current log entires, with an optional 'limit'
  ** to restrict number of entries.  By default all entires
  ** in ring buffer are returned.
  LogRec[] read(Int limit := capacity)
  {
    actor.send(DaemonMsg { it.op="read"; it.a=limit }).get(10sec)
  }

  private Obj? receive(DaemonMsg? msg)
  {
    LogRec[]? ring := Actor.locals["r"]
    if (ring == null)
      Actor.locals["r"] = ring = LogRec[,] { it.capacity = this.capacity }

    switch (msg.op)
    {
      case "read":
        // TODO: yikes!
        Int limit := msg.a
        min := (ring.size-limit).max(0)
        max := ring.size.min(limit)
        return ring[min..<max].reverse.toImmutable

      case "append":
        ring.add(msg.a)
        // TODO: yikes!
        if (ring.size > capacity) ring = ring[1..-1]
        return null

      default: return null
    }
  }

  private const ActorPool pool := ActorPool { it.name = "SysLog" }
  private const Actor actor := Actor(pool) |msg| { receive(msg) }
}