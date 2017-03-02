#! /usr/bin/env fan
//
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Jan 2017  Andy Frank  Creation
//

using build

**
** Build: fanuart
**
class Build : BuildScript
{
  ** Compile with toolchains to target systems
  @Target { help = "Compile fanuart binary" }
  Void compile()
  {
    opts := ["-O2", "-Wall", "-Wextra", "-Wno-unused-parameter",
             "-std=c99", "-D_GNU_SOURCE"]

    xsrc := [
      scriptDir + `../common/src/log.c`,
      scriptDir + `../common/src/pack.c`
    ]

    Method m := Method.find("studsTools::Toolchain.compile")
    m.callOn(null, ["fanuart", scriptDir + `src/`, xsrc, opts])
  }
}