//
// Copyright (c) 2017, Andy Frank
// Licensed under the Apache License version 2.0
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
// Filesystem
//////////////////////////////////////////////////////////////////////////

  ** Return true it the writable data parition is mounted.
  ** See `mountData`.
  static Bool isDataMounted()
  {
    dev := fwActiveProps["nerves_fw_application_part0_devpath"]
    out := Proc { it.cmd=["mount"] }.run.waitFor.okOrThrow.in.readAllStr
    return out.splitLines.any |s| { s.startsWith("${dev} on /data") }
  }

  ** Mount the writable data partition for this device under the '/data'
  ** directory.  If the partition fails to mount and 'reformat=true', then
  ** the partition is automatically reformatted, and mount attempted again.
  ** Throws 'IOErr' if data partition could not be mounted.  If partition
  ** is already mounted, this method does nothing.
  static Void mountData(Bool reformat := true)
  {
    // read fwprops to find partition info
    fs  := fwActiveProps["nerves_fw_application_part0_fstype"]
    dev := fwActiveProps["nerves_fw_application_part0_devpath"]

    // bail if already mounted
    if (isDataMounted) return

    umountCmd := ["/bin/umount", "/data"]
    mountCmd  := ["/bin/mount", "-t", fs, dev, "/data"]
    mkfsCmd   := ["/sbin/mkfs.${fs}", "-F", dev]
    mountMsg  := "/data partition mounted as rw"

    // first attempt
    Proc { it.cmd=umountCmd }.run.waitFor
    Proc { it.cmd=mountCmd }.run.waitFor
    if (isDataMounted) { log.debug(mountMsg); return }

    if (reformat)
    {
      // format
      log.debug("Formatting /data partition...")
      Proc { it.cmd=umountCmd }.run.waitFor
      Proc { it.cmd=mkfsCmd }.run.waitFor

      // second attempt
      Proc { it.cmd=mountCmd }.run.waitFor
      if (isDataMounted) { log.debug(mountMsg); return }
    }

    throw IOErr("/data partition could not be mounted")
  }

//////////////////////////////////////////////////////////////////////////
// Firmware
//////////////////////////////////////////////////////////////////////////

  **
  ** Update the firmware running on this device with the image
  ** contained in the given 'fw' file.  This  method implicity
  ** reboots device if update is successful.
  **
  ** See [Updating Firmware]`../../doc/UpdatingFirmware.html`
  ** chapter for details on how firwmare is updated.
  **
  static Void updateFirmware(File fw)
  {
    // TODO
    echo("TODO: Sys.updateFirmware: $fw")
  }

//////////////////////////////////////////////////////////////////////////
// Reboot/shutdown
//////////////////////////////////////////////////////////////////////////

  ** Reboot this device.
  static Void reboot()
  {
    // TODO: fix this to signal to faninit?
    Proc { it.cmd=["/sbin/reboot"] }.run.waitFor.okOrThrow
  }

  ** Shutdown this device.
  static Void shutdown()
  {
    // TODO: fix this to signal to faninit?
    Proc { it.cmd=["/sbin/poweroff"] }.run.waitFor.okOrThrow
  }

//////////////////////////////////////////////////////////////////////////
// Log
//////////////////////////////////////////////////////////////////////////

  ** Internal sys log instance.
  private static const Log log := Log("sys", false) { it.level=LogLevel.debug }
}
