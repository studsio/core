//
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    4 Apr 2017  Andy Frank  Creation
//

using concurrent

**
** Sys provides system level information and utilites for a target device.
**
class Sys
{

//////////////////////////////////////////////////////////////////////////
// Props
//////////////////////////////////////////////////////////////////////////

  **
  ** Get 'etc/sys.props' system properites, which includes:
  **  - 'proj.name'
  **  - 'proj.version'
  **  - 'studs.version'
  **  - 'system.name'
  **  - 'system.version'
  **
  static Str:Str props()
  {
    if (propsRef.val == null)
      propsRef.val = File(`/etc/sys.props`).readProps.toImmutable

    return propsRef.val
  }

  ** Get firmware properties for the active firmware slot.
  @NoDoc static Str:Str fwActiveProps()
  {
    if (fwActiveRef.val == null)
    {
      map    := Str:Str[:]
      active := fwProps["nerves_fw_active"]
      fwProps.each |v,n|
      {
        if (n.startsWith("${active}."))
        {
          an := n["${active}.".size..-1]
          map[an] = v
        }
      }
      fwActiveRef.val = map.toImmutable
    }

    return fwActiveRef.val
  }

  ** Get all firmware properties regardless of active firmware slot.
  @NoDoc static Str:Str fwProps()
  {
    if (fwPropsRef.val == null)
    {
      m := Str:Str[:]
      p := Proc { it.cmd=["/usr/sbin/fw_printenv"] }
      p.run.waitFor.okOrThrow.in.readAllStr.splitLines.each |line|
      {
        i := line.index("=")
        if (i == null) return
        n := line[0..<i]
        v := line[i+1..-1]
        m[n] = v
      }
      fwPropsRef.val = m.toImmutable
    }

    return fwPropsRef.val
  }

  private static const AtomicRef propsRef    := AtomicRef(null)
  private static const AtomicRef fwActiveRef := AtomicRef(null)
  private static const AtomicRef fwPropsRef  := AtomicRef(null)

//////////////////////////////////////////////////////////////////////////
// Reboot/shutdown
//////////////////////////////////////////////////////////////////////////

  ** Reboot this device.
  static Void reboot()
  {
    Proc { it.cmd=["/sbin/reboot"] }.run.waitFor.okOrThrow
  }

  ** Shutdown this device.
  static Void shutdown()
  {
    Proc { it.cmd=["/sbin/poweroff"] }.run.waitFor.okOrThrow
  }
}
