//
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Mar 2017  Andy Frank  Creation
//

using concurrent

**
** Runtime API for Device Tree overlays.
**
const class DeviceTree
{
  ** Enable given Device Tree Source fragment.  If this fragment
  ** has already been enabled, this method does nothing.
  static Void enable(Str frag)
  {
    //
    // TODO: this is not thread-safe -- fixup with proper actor!!!
    //

    // only supported on bbb
    sysname := Sys.props["system.name"]
    if (sysname != "bbb") throw Err("not yet supported on '$sysname'")

    // TEMP: check if already enabled
    Str:Bool map := (mapRef.val as Str:Bool ?: Str:Bool[:]).rw
    if (map[frag] == true) return

    // load dt
    p := Proc { it.cmd=["sh", "-c", "echo $frag > /sys/devices/platform/bone_capemgr/slots"] }
    p.run.waitFor.okOrThrow
    map[frag] = true
    mapRef.val = map.toImmutable
  }

  // TEMP: support for tracking enabled frags
  private static const AtomicRef mapRef := AtomicRef(null)
}