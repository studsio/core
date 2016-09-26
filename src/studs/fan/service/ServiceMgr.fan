//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Sep 2016  Andy Frank  Creation
//

using concurrent

**
** ServiceMgr manages starting, stopping, and monitoring `Service` instances.
**
const class ServiceMgr
{
  ** It-block constructor.
  new make(|This| f) { f(this) }

  ** Services this manager is managing.
  const StudsService[] services

  ** Start this manager and `services`.
  Void start()
  {
    // add shutdown hook
    Env.cur.addShutdownHook |->|
    {
      stopMsg := ServiceMsg { it.op="stop" }
      services.each |s|
      {
        try { s.send(stopMsg) }
        catch (Err e) { e.trace }
      }
    }

    // start all services
    startMsg := ServiceMsg { it.op="start" }
    services.each |s|
    {
      try { s.send(startMsg) }
      catch (Err e) { e.trace }
    }
  }
}
