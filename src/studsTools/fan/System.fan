//
// Copyright (c) 2016, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   23 Aug 2016  Andy Frank  Creation
//

using concurrent

**
** System models a target system image.
**
const class System
{
  ** Find a default system by name.
  static System? find(Str name, Bool checked := true)
  {
    sys := defs.find |sys| { sys.name == name }
    if (sys == null && checked) throw ArgErr("Default system not found: ${name}")
    return sys
  }

  ** It-block ctor.
  new make(|This| f) { f(this) }

  ** Private ctor for default systems.
  private new makeDef(Str name, Str arch, Str ver)
  {
    this.name = name
    this.arch = arch
    this.version = Version(ver)
    this.uri = `https://github.com/studsio/system-${name}/releases/download/${version}/studs-system-${name}-${version}.tar.gz`
  }

  ** Unique name for this system.
  const Str name

  ** CPU architecture for this system.
  const Str arch

  ** Vesion of system.
  const Version version

  ** Toolchain name for system.
// TODO: goes away with 'arch'
  Str toolchain()
  {
    arch == "arm32sf"
      ? "armv6_rpi_linux_gnueabi"
      : "arm_unknown_linux_gnueabihf"
  }

  ** URI to fetch system image.
  const Uri uri

  ** toStr is {name}-{version}
  override Str toStr() { "system-${name}-${version}" }

  ** Default systems.
  private static const System[] defs := [
    makeDef("bb",   "arm32hf", "1.4"),
    makeDef("rpi3", "arm32hf", "1.4"),
    makeDef("rpi0", "arm32sf", "1.4"),
  ]
}