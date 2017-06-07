#! /usr/bin/env fan
//
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    6 Jun 2017  Andy Frank  Creation
//

using build

**
** Build: libfan
**
class Build : BuildScript
{
  ** Compile with toolchains to target systems
  @Target { help = "Compile libfan JNI binding library" }
  Void compile()
  {
    opts := ["-O2", "-Wall", "-shared"]
    xsrc := [,]

    Method m := Method.find("studsTools::Toolchain.compile")
    m.callOn(null, ["libfan.so", scriptDir + `src/`, xsrc, opts])
  }
}