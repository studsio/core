//
// Copyright (c) 2016, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   26 Sep 2016  Andy Frank  Creation
//

using concurrent

**************************************************************************
** Daemon
**************************************************************************

**
** Daemon provides an API for long-running system services running
** on their own thread with life-cycle callbacks for start, stop,
** poll, and custom messages.
**
** See [Daemons]`../../doc/Daemons.html` chapter for details.
**
abstract const class Daemon
{
  **
  ** Subclass constructor where 'pollFreq' is the frequency
  ** to invoke `onPoll` callback, or 'null' to not schedule
  ** a poll callback.
  **
  protected new make(Duration? pollFreq)
  {
    name := this.name
    this.pool  = ActorPool { it.name=name }
    this.actor = Actor(pool) |m| { receive(m) }
    this.log   = Log(name, false)
    this.pollFreq = pollFreq

    // TODO: for now pin all services to debug
    this.log.level = LogLevel.debug
  }

  ** Programmtic name of this daemon, which by convention
  ** is simply the type name lowercased.
  Str name() { typeof.name.lower }

  ** Log for this daemon.
  const Log log

  ** Start this daemon instance. This method is guaranteed not to
  ** throw an exception (but will log errors to `log`). Any error
  ** handling required should be implemented inside the `onStart`
  ** override method.
  This start()
  {
    try
    {
      send(DaemonMsg { it.op="start" })
    }
    catch (Err err)
    {
      log.err("$name failed to start", err)
    }
    return this
  }

  ** Send this daemon a message.
  Future send(DaemonMsg m) { actor.send(m) }

  ** Callback when daemon is started.
  protected virtual Void onStart() {}

  ** Callback when daemon is stopped.
  protected virtual Void onStop() {}

  ** Callback when periodic poll is dispatched.
  protected virtual Void onPoll() {}

  ** Callback to process a daemon message.
  protected virtual Obj? onMsg(DaemonMsg m) { null }

  ** Route message to `onMsg` callback.
  private Obj? receive(Obj msg)
  {
    DaemonMsg m := msg
    if (m.op === "start")
    {
      onStart
      if (pollFreq != null) actor.sendLater(pollFreq, pollMsg)
      return null
    }

    if (m.op === "stop")
    {
      onStop
      return null
    }

    if (m.op === "poll" && pollFreq != null)
    {
      try { onPoll }
      catch (Err e) { e.trace }
      finally { actor.sendLater(pollFreq, m) }
      return null
    }

    return onMsg(msg)
  }

  private const ActorPool pool
  private const Actor actor
  private const Duration? pollFreq
  private const DaemonMsg pollMsg  := DaemonMsg { it.op="poll" }
}

**************************************************************************
** DaemonMsg
**************************************************************************

** DaemonMsg is used to send messages to `Daemon` actors.
const class DaemonMsg
{
  new make(|This| f) { f(this) }

  ** Name of this message op.
  const Str op

  const Obj? a := null
  const Obj? b := null
  const Obj? c := null
}