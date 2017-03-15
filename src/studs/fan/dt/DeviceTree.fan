//
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Mar 2017  Andy Frank  Creation
//

**
** Runtime API for Device Tree overlays.
**
const class DeviceTree
{
  ** Enable given Device Tree Source fragment.
  static Void enable(Str frag)
  {
    // TODO: check system...
    p := Proc { it.cmd=["sh", "-c", "echo $frag > /sys/devices/platform/bone_capemgr/slots"] }
    p.run.waitFor.okOrThrow
  }
}