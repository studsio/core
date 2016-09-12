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
** Build: studs
**
class Build : BuildPod
{
  new make()
  {
    podName = "studs"
    summary = "Studs"
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
      "inet @{fan.depend}",
      "web @{fan.depend}",
      "webmod @{fan.depend}",
      "wisp @{fan.depend}"]
    srcDirs = [
      `fan/`,
      `fan/ntp/`,
      `test/`]
    docSrc = true
  }
}