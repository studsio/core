//
// Copyright (c) 2018, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   27 Jun 2018  Andy Frank  Creation
//

using concurrent
using web
using wisp

**************************************************************************
** HttpdConfig
**************************************************************************

**
** Configuration settings for `Httpd` daemon.
**
const class HttpConfig
{
  ** It-block constructor.
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

  ** HTTP port to listen for requests.
  // TODO: force to only allow TLS
  const Int port := 80

  **
  ** URI to publish for updating firmware over-the-air, or
  ** 'null' to disable OTA firmware updates.
  **
  ** See [Updating Firmware]`../../doc/UpdatingFirmware.html`
  ** chapter for details on how firwmare is updated.
  **
  const Uri? otaUpdateUri := `/update-fw`

  ** Root WebMod used to service requests.
  // TODO: what is behvior when this is not specified?
  //       ie: just want OTA but nothing else?
  const WebMod? root

  ** Max number of threads to use for concurrent web request processing.
  @NoDoc const Int maxThreads := 25
}

**************************************************************************
** Httpd
**************************************************************************

**
** Http server support in Studs is provided by the Httpd daemon.
**
** See [Http Server]`../../doc/HttpServer.html` chapter for details.
**
const class Httpd : Daemon
{
  @NoDoc new make(HttpConfig config := HttpConfig()) : super(null)
  {
    this.config = config
  }

  ** Get the Httpd instance for this VM.  If an instance is
  ** not found, throw Err if 'checked' otherwise return null.
  static Httpd? cur(Bool checked := true)
  {
    if (curRef.val == null && checked) throw Err("Httpd instance not found")
    return curRef.val
  }

  private static const AtomicRef curRef := AtomicRef(null)

  ** HTTP server configuration.
  const HttpConfig config

//////////////////////////////////////////////////////////////////////////
// Actor local
//////////////////////////////////////////////////////////////////////////

  @NoDoc override Void onStart()
  {
    wisp := WispService
    {
      it.httpPort = this.config.port  // TODO: https only
      it.maxThreads = this.config.maxThreads
      it.root = HttpMod(this)
    }

    Actor.locals["w"] = wisp
    wisp.start
  }

  @NoDoc override Void onStop()
  {
    wisp := Actor.locals["w"] as WispService
    wisp?.stop
  }
}