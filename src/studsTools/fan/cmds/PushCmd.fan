//
// Copyright (c) 2018, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   6 Jul 2018  Andy Frank  Creation
//

using web

**
** Upload firmware images over HTTP.
**
const class PushCmd : Cmd
{
  override const Str name := "push"
  override const Str sig  := "<ipaddr> [options]*"
  override const Str helpShort := "Upload firmware images over HTTP"
  override const Str? helpFull :=
    "<ipaddr>  IP address of target device (ex: 192.168.1.100)"

  // TODO [-u --url]    manually specify target URL
  // TODO [-i --image]  manually select image file

  override Int run()
  {
    // validate input
    ipaddr := args.getSafe(0)
    if (ipaddr == null) abort("missing arg: ipaddr")

    // prompt for release image
    rel := promptRelease

    try
    {
      // upload file
      info("Pushing $rel.name to ${ipaddr}...")
      c := WebClient(`http://${ipaddr}/update-fw`)
      c.reqMethod = "PUT"
      c.reqHeaders["Content-Type"] = "application/x-firmware"
      c.reqHeaders["Content-Length"] = rel.size.toStr
      c.writeReq
      rel.in.pipe(c.reqOut)
      c.reqOut.close

      // verify response
      c.readRes
      if (c.resCode != 200) throw Err("Device upload failed with $c.resCode")
      echo("$c.resStr")
      c.close
    }
    catch (Err err)
    {
      abort("push failed: $err.msg")
      return 1
    }

    return 0
  }
}