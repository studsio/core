//
// Copyright (c) 2018, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   29 Jun 2018  Andy Frank  Creation
//

using concurrent
using web
using wisp

**
** HttpMod is the internal root WebMod for `Httpd`.
**
internal const class HttpMod : WebMod
{
  ** Ctor.
  new make(Httpd httpd)
  {
    this.httpd = httpd
  }

  ** Service request.
  override Void onService()
  {
    try
    {
      // first check for OTA
      if (req.uri == httpd.config.otaUpdateUri) return onOta

      // next check if root is configured
      if (httpd.config.root == null) return onNoRoot

      // delegate to root
      req.mod = httpd.config.root
      httpd.config.root.onService
    }
    catch (Err err) { onErr(err) }
  }

  ** Handle an OTA firmware upgrade request.
  private Void onOta()
  {
    // verify PUT method
    if (req.method != "PUT") return res.sendErr(405)

    // verify content type
    ct := req.headers["Content-Type"]
    if (ct != "application/x-firmware") throw IOErr("Invalid Content-Type: '$ct'")

    // TODO: check certs/keys/something yadda yadda

    // verify stageDir exists and that /data partition is mounted
    try { httpd.config.otaUpdateStageDir.create }
    catch (Err err) { throw IOErr("otaUpdateStageDir could not be created; See Sys.mountData", err) }

    // TODO: fix to stream WebReq directly to `fwup` Proc instance

    // pipe to stage file
    fw  := httpd.config.otaUpdateStageDir + `update-${DateTime.nowTicks}.fw`
    out := fw.out
    try { req.in.pipe(out) }
    finally { out.sync.close }

    // send 200 response and close to terminate request
    res.statusCode = 200
    res.headers["Content-Type"] = "text/html; charset=UTF-8"
    res.out
      .printLine("Firmware upload successful. Now installing and rebooting device to apply.")
      .flush.close

    // apply firmware
    Sys.updateFirmware(fw)
  }

  ** Handle an error condition during a request.
  private Void onNoRoot()
  {
    res.statusCode = 200
    res.headers["Content-Type"] = "text/html; charset=UTF-8"

    out := res.out
    out.docType
    out.html
    out.head
      .title.esc("No root mod configured").titleEnd
      .headEnd
    out.body
      .h1.esc("No root mod configured").h1End
      .bodyEnd
    out.htmlEnd
  }

  ** Handle an error condition during a request.
  private Void onErr(Err err)
  {
    // setup response if not already commited
    if (!res.isCommitted)
    {
      res.statusCode = 500
      res.headers["Content-Type"] = "text/html; charset=UTF-8"
    }

    // TODO: fix to toggle stack traces on/off upstream
    // send HTML response
    out := res.out
    out.docType
    out.html
    out.head
      .title.esc("500: Internal server error").titleEnd
      .style.w("pre { font-family:monospace; }").styleEnd
      .headEnd
    out.body
      .h1.esc("500: Internal server error").h1End
      .h2.esc(err.msg).h2End
      .pre.w(err.traceToStr).preEnd
      .bodyEnd
    out.htmlEnd
  }

  private const Httpd httpd
}