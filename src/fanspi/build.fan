#! /usr/bin/env fan
//
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Mar 2017  Andy Frank  Creation
//

using build

**
** Build: fanspi
**
class Build : BuildScript
{
  ** Compile with toolchains to target systems
  @Target { help = "Compile fanspi binary" }
  Void compile()
  {
    opts := ["-O2", "-Wall", "-Wextra", "-Wno-unused-parameter"]

    xsrc := [
      scriptDir + `../common/src/log.c`,
      scriptDir + `../common/src/pack.c`
    ]

    Method m := Method.find("studsTools::Toolchain.compile")
    m.callOn(null, ["fanspi", scriptDir + `src/`, xsrc, opts])
  }
}