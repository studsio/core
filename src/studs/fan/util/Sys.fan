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

  ** Reboot this device.
  static Void reboot()
  {
    Proc { it.cmd=["/sbin/reboot"] }.run.waitFor.okOrThrow
  }

  private static const AtomicRef propsRef := AtomicRef(null)
}
