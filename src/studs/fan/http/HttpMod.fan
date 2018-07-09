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
    // first check for OTA
    if (req.uri == httpd.config.otaUpdateUri) return onOta

    try
    {
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
    // TODO: improve how we handle errors during the request stream
    //       so we can return a meaningful response to client

    // stream update to alternate root partition
    try
    {
      // verify PUT method
      if (req.method != "PUT") throw IOErr("Invalid method '$req.method'. Use PUT")

      // verify content type
      ct := req.headers["Content-Type"]
      if (ct != "application/x-firmware") throw IOErr("Invalid Content-Type: '$ct'")

      // TODO: check certs/keys/something yadda yadda

      // install firmware
      Sys.updateFirmware(req.in)
    }
    catch (Err err)
    {
      // log error with stack trace locally
      httpd.log.debug("Firmware update failed", err)

      // send machine readable err response; never send stack
      res.statusCode = 500
      res.headers["Content-Type"] = "text/plain; charset=UTF-8"
      res.out.printLine(err.msg).flush.close

      return
    }

    // send 200 response and close to terminate request
    res.statusCode = 200
    res.headers["Content-Type"] = "text/plain; charset=UTF-8"
    res.out
      .printLine("Firmware upload successful. Now rebooting device to apply.")
      .flush.close

    // reboot device to apply
    Sys.reboot
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
    //       or maybe just be safe and _never_ send traces
    //       ^ need solid network log debugging to make this work

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