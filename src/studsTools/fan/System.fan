//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
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
  ** It-block ctor.
  new make(|This| f)
  {
    f(this)
    // TODO?
    this.jre = "linux-armv6-vfp-hflt"
  }

  ** Make default System.
  new makeDef(Str name)
  {
    this.name = name
    this.version = defVer[name]
    this.uri = `https://bitbucket.org/studs/core/downloads/studs-system-${name}-${version}.tar.gz`
    // TODO?
    this.jre = "linux-armv6-vfp-hflt"
  }

  ** Unique name for this system
  const Str name

  ** Vesion of system.
  const Version version

  ** URI to fetch system image.
  const Uri uri

  ** JRE platform for this system.
  const Str jre

  ** toStr is {name}-{version}
  override Str toStr() { "${name}-${version}" }

  ** Default system versions.
  private static const Str:Version defVer := [
    "bbb":  Version("1.0.0"),
// TODO
"rpi0": Version("1.0.0"),
    "rpi3": Version("1.0.0"),
  ]
}