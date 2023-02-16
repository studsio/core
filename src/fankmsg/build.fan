#! /usr/bin/env fan
//
// Copyright (c) 2023, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   15 Feb 2023  Andy Frank  Creation
//

using build

**
** Build: fankmsg
**
class Build : BuildScript
{
  ** Compile with toolchains to target systems
  @Target { help = "Compile fankmsg binary" }
  Void compile()
  {
    opts := ["-O2", "-Wall", "-Wextra", "-Wno-unused-parameter",
             "-std=c99", "-D_GNU_SOURCE"]
    xsrc := [,]

    Method m := Method.find("studsTools::Toolchain.compile")
    m.callOn(null, ["fankmsg", scriptDir + `src/`, xsrc, opts])
  }
}