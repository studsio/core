#! /usr/bin/env fan
//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
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
    version = Version("1.0.0")
    meta    = [
      "proj.name":    "Studs",
      "proj.uri":     "http://studs.io/",
      "license.name": "Academic Free License 3.0",
      "vcs.uri":      "https://bitbucket.org/afrankvt/studs/"]
    depends = [
      "sys @{fan.depend}",
      "util @{fan.depend}",
      "concurrent @{fan.depend}",
      "web @{fan.depend}",
      "studs @{fan.depend}"]
    srcDirs = [`fan/`, `fan/cmds/`]
    resDirs = [`res/`,
               `bins/bbb/`,
               `bins/rpi3/`]
    docSrc = true
  }
}