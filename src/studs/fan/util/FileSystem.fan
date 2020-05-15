//
// Copyright (c) 2020, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//    13 May 2020  Andy Frank  Creation
//

**
** FileSystem provides file system support and utilities.
**
const class FileSystem
{
  **
  ** Return 'true' if given 'device' is currently mounted. If 'dir'
  ** is specified, validate device is mounted at given directory.
  ** Throws 'IOErr' if an error occurred checking mounts.
  **
  ** Example:
  **   FileSystem.isMounted("/dev/mmcblk3p1")
  **   FileSystem.isMounted("/dev/mmcblk3p1", "/mnt/sdcard")
  **
  static Bool isMounted(Str device, Str? dir := null)
  {
    if (dir == null) dir = "/"
    out := Proc { it.cmd=["mount"] }.run.waitFor.okOrThrow.in.readAllStr
    return out.splitLines.any |s| { s.startsWith("${device} on ${dir}") }
  }

  **
  ** Mount given 'device' under 'dir', where 'fs' specifies the
  ** filesystem type, and 'access' is '"ro"' for read-only, or '"rw"'
  ** is read-write.  If device is already mounted, this method does
  ** nothing.  Throws 'IOErr' if device cound not be mounted.
  **
  ** Example:
  **   FileSystem.mount("/dev/mmcblk3p1", "/mnt/sdcard", "ext4", "rw")
  **
  static Void mount(Str device, Str dir, Str fs, Str access)
  {
    // fail fast if fs not supported
    if (!fslist.contains(fs)) throw IOErr("Filesystem '${fs}' not supported")

    try
    {
      // fallback to read-only if not explicitly 'rw'
      if (access != "rw") access = "ro"

      // TODO: how do we validate 'access' matches?
      // bail if already mounted
      if (isMounted(device, dir)) return

      // unmount dir as sanity check
      unmount(dir)

      // mount disk
      cmd  := ["/bin/mount"]
      if (access == "ro") cmd.add("-r")
      cmd.addAll(["-t", fs, device, dir])
      Proc { it.cmd=cmd }.run.waitFor

      // sanity check we mounted
      if (isMounted(device, dir)) return
      throw Err("Could not validate mount point")
    }
    catch (Err err)
    {
      throw IOErr("Failed to mount ${device} under ${dir}", err)
    }
  }

  **
  ** Unmount given 'dir', or do nothing if not mounted
  **
  ** Example:
  **   FileSystem.unmount("/mnt/sdcard")
  **
  static Void unmount(Str dir)
  {
    cmd := ["/bin/umount", dir]
    Proc { it.cmd=cmd }.run.waitFor
  }

  **
  ** Format given 'device' using 'fs' filesystem type.
  **
  ** Example:
  **   FileSystem.format("/dev/mmcblk3p1", "ext4")
  **
  static Void format(Str device, Str fs, Uuid? uuid := null)
  {
    // fail fast if fs not supported
    if (!fslist.contains(fs)) throw IOErr("Filesystem '${fs}' not supported")

    try
    {
      // generate a new unique UUID if not specified
      if (uuid == null) uuid = Uuid.make

      // format device
      cmd := ["/sbin/mkfs.${fs}", "-U", uuid, "-F", device]
      Proc { it.cmd=cmd }.run.waitFor
    }
    catch (Err err)
    {
      throw IOErr("Failed to format ${device}", err)
    }
  }

  // supported filesystem types
  private static const Str[] fslist := ["ext4","ext3","ext2"]
}