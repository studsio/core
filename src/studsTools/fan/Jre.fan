//
// Copyright (c) 2020, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   4 Mar 2020  Andy Frank  Creation
//

using concurrent

**
** Jre models a target JRE image.
**
const class Jre
{
  ** It-block ctor.
  new make(|This| f) { f(this) }

  ** Find a JRE instance for given arch.
  static Jre? find(Str arch, Bool checked := true)
  {
    jre := defs.find |d| { d.arch == arch }
    if (jre == null && checked) throw ArgErr("JRE not found for ${arch}")
    return jre
  }

  ** Private ctor.
  private new makeDef(Str arch, Str ver, Str prof)
  {
    this.arch    = arch
    this.version = ver
    this.profile = prof
    // TODO
    this.uri = `https://github.com/studsio/jre/releases/download/11.0.6/studs-jre-arm32hf-11.0.6-min.tar.gz`
  }

  ** CPU architecture for this JRE.
  const Str arch

  ** Vesion of system.
// TODO: until we have a semver Version class
// const Version version
  const Str version

  ** JRE profile.
  const Str profile

  ** URI to fetch JRE image.
  const Uri uri

  ** toStr is {name}-{version}
  override Str toStr() { "jre-${arch}-${version}-${profile}" }

  ** Default JREs instances.
  private static const Jre[] defs := [
    makeDef("arm32hf", "11.0.6", "min"),
  ]
}