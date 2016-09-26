//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Sep 2016  Andy Frank  Creation
//

using concurrent

**************************************************************************
** StudsService
**************************************************************************

**
** StudsService provides an API for long-running system services
** running on their own thread with life-cycle callbacks for start,
** stop, poll, and custom messages.
**
** Services are managed by a `ServiceMgr` instance.
**
abstract const class StudsService
{
  **
  ** Subclass constructor where 'name' is the name of this service,
  ** and 'pollFreq' is the frequency to invoke `onPoll` callback,
  ** or 'null' to not schedule a poll callback.
  **
  protected new make(Str name, Duration? pollFreq)
  {
    this.pool  = ActorPool { it.name=name }
    this.actor = Actor(pool) |m| { receive(m) }
    this.pollFreq = pollFreq
  }

  ** Send this service a message.
  Void send(ServiceMsg m) { actor.send(m) }

  ** Callback when service is started.
  protected virtual Void onStart() {}

  ** Callback when service is stopped.
  protected virtual Void onStop() {}

  ** Callback when periodic poll is dispatched.
  protected virtual Void onPoll() {}

  ** Callback to process a service message.
  protected virtual Obj? onMsg(ServiceMsg m) { null }

  ** Route message to `onMsg` callback.
  private Obj? receive(Obj msg)
  {
    ServiceMsg m := msg
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
  private const ServiceMsg pollMsg  := ServiceMsg { it.op="poll" }
}

**************************************************************************
** ServiceMsg
**************************************************************************

** ServiceMsg is used to send messages to Service actors.
const class ServiceMsg
{
  new make(|This| f) { f(this) }

  ** Name of this message op.
  const Str op

  const Obj? a := null
  const Obj? b := null
  const Obj? c := null
}