//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Sep 2016  Andy Frank  Creation
//

using concurrent

**
** DaemonMgr manages starting, stopping, and monitoring `Daemon`
** instances.
**
const class DaemonMgr
{
  ** It-block constructor.
  new make(|This| f) { f(this) }

  ** Daemons this supervisor is managing.
  const Daemon[] daemons

  ** Start this supervisor and `daemons`.
  Void start()
  {
    // add shutdown hook
    Env.cur.addShutdownHook |->|
    {
      daemons.each |s|
      {
        try { s.send(stopMsg) }
        catch (Err e) { e.trace }
      }
    }

    // start all daemons
    daemons.each |s|
    {
      try { s.send(startMsg) }
      catch (Err e) { e.trace }
    }
  }

  private static const DaemonMsg startMsg := DaemonMsg { it.op="start" }
  private static const DaemonMsg stopMsg  := DaemonMsg { it.op="stop"  }
}
