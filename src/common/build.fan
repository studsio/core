#! /usr/bin/env fan
//
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Jan 2017  Andy Frank  Creation
//

using build

**
** Build: common
**
class Build : BuildScript
{
  ** No-op compile
  @Target { help = "No-op" }
  Void compile() {}

  ** Test common lib
  @Target { help = "Test common lib" }
  Void test()
  {
    gcc(["src/pack.c", "test/test_pack.c"], "test")
    run("test")
  }

  Void gcc(Str[] src, Str out)
  {
    opts := ["-Wall", "-o", "${(scriptDir + `test/$out`).osPath}"]
    srcf := src.map |s| { (scriptDir + s.toUri).osPath }
    proc := Process(["gcc"].addAll(opts).addAll(srcf))
    proc.dir = scriptDir
    if (proc.run.join != 0) throw Err("gcc failed")
  }

  Void run(Str bin)
  {
    cmd  := scriptDir + `test/$bin`
    proc := Process([cmd.osPath])
    proc.dir = scriptDir
    if (proc.run.join != 0) Env.cur.exit(1)
  }
}