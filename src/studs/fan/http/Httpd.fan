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

**
** Http server support in Studs is provided by the Httpd daemon.
**
** See [Http Server]`../../doc/HttpServer.html` chapter for details.
**
const class Httpd : Daemon
{
  @NoDoc new make() : super(null)
  {
    // allow only one instance per VM
    if (!curRef.compareAndSet(null, this)) throw Err("Httpd already exists")
  }

  ** Get the Httpd instance for this VM.  If an instance is
  ** not found, throw Err if 'checked' otherwise return null.
  static Httpd? cur(Bool checked := true)
  {
    if (curRef.val == null && checked) throw Err("Httpd instance not found")
    return curRef.val
  }

  private static const AtomicRef curRef := AtomicRef(null)

  ** HTTP port to listen for requests.
  // TODO: force to only allow TLS
  const Int port := 80

  ** URI to publish for updating firmware over-the-air, or
  ** 'null' to disable OTA firmware updates.
  const Uri? otaUpdateUri := `/update-fw`

  ** Directory to temporarily stage firmware before applying.
  ** The downloaded image will automatically be deleted after
  ** the update completes (or fails).
  const File otaUpdateStageDir := File(`/data/update-fw-stage/`)

  ** Root WebMod used to servce requests.
  const WebMod? root

  ** Max number of threads to use for concurrent web request processing.
  @NoDoc const Int maxThreads := 25

//////////////////////////////////////////////////////////////////////////
// Actor local
//////////////////////////////////////////////////////////////////////////

  @NoDoc override Void onStart()
  {
    wisp := WispService
    {
      it.httpPort = this.port  // TODO: https only
      it.maxThreads = this.maxThreads
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