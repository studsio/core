//
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    4 Apr 2017  Andy Frank  Creation
//

**
** Sys provides system level information and utilites for a target device.
**
class Sys
{
  ** Return the Studs system name for this device (ex: bbb, rpi3).
  static Str system()
  {
    "TODO"
  }

  ** Reboot this device.
  static Void reboot()
  {
    Proc { it.cmd=["/sbin/reboot"] }.run.waitFor.okOrThrow
  }
}
