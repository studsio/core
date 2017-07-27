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
    meta    = [
      "proj.name":    "Studs",
      "proj.uri":     "http://studs.io/",
      "license.name": "Academic Free License 3.0",
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
               `bins/bbb/`,
               `bins/rpi0/`,
               `bins/rpi3/`]
    docSrc = true
  }
}