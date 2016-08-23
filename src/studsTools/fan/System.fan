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
    this.uri =
      ("https://github.com/nerves-project/nerves_system_${name}/releases/download" +
      "/v${version}/nerves_system_${name}-v${version}.tar.gz").toUri
  }

  ** Unique name for this system
  const Str name

  ** Vesion of system.
  const Version version

  ** URI to fetch system image.
  const Uri uri

  ** List available systems.
  static System[] list() { Actor.locals["sys.list"] }

  ** Find System with given name. If system not found throw
  ** Err if 'checked' is true, otherwise return 'null'.
  static System? find(Str name, Bool checked := true)
  {
    sys := list.find |s| { s.name == name }
    if (sys == null && checked) throw Err("System not found '$name'")
    return sys
  }
}