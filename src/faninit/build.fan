#! /usr/bin/env fan
//
// Copyright (c) 2016, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   26 Aug 2016  Andy Frank  Creation
//

using build

**
** Build: faninit
**
class Build : BuildScript
{
  ** Compile with toolchains to target systems
  @Target { help = "Compile faninit binary" }
  Void compile()
  {
    ver  := config("buildVersion")   // TODO: just inject this automatically?
    opts := ["-Wall", "-Wextra", "-O2", "-s", "-D_GNU_SOURCE", "-DPROGRAM_VERSION=$ver"]
    Method m := Method.find("studsTools::Toolchain.compile")
    m.callOn(null, ["faninit", scriptDir + `src/`, [,], opts])
  }
}