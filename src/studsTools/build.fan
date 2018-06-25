#! /usr/bin/env fan
//
// Copyright (c) 2016, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   21 Aug 2016  Andy Frank  Creation
//

using build

**
** Build: studsTools
**
class Build : BuildPod
{
  new make()
  {
    podName = "studsTools"
    summary = "Studs Build Tool Support"
    meta    = [
      "proj.name":    "Studs",
      "proj.uri":     "http://studs.io/",
      "license.name": "Apache License 2.0",
      "vcs.uri":      "https://bitbucket.org/studs/core/",
      "repo.public":  "true",
      "repo.tags":    "studs"]
    depends = [
      "sys @{fan.depend}",
      "util @{fan.depend}",
      "concurrent @{fan.depend}",
      "web @{fan.depend}",
      "studs @{buildVersion}"]
    srcDirs = [`fan/`, `fan/cmds/`]
    resDirs = [`res/`,
               `bins/bb/`,
               `bins/rpi0/`,
               `bins/rpi3/`,
               `scripts/`]
    docSrc = true
  }

  @Target { help = "Compile to pod file and associated natives" }
  override Void compile()
  {
    // stub out empty bins/ directory if needed
    stubDir(scriptDir + `bins/bb/`)
    stubDir(scriptDir + `bins/rpi0/`)
    stubDir(scriptDir + `bins/rpi3/`)

    super.compile
  }

  private Void stubDir(File f)
  {
    if (!f.exists) f.create
  }
}