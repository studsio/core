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
** Build: studsTest
**
class Build : BuildPod
{
  new make()
  {
    podName = "studsTest"
    summary = "Studs Test Harness"
    meta    = [
      "proj.name":    "Studs",
      "proj.uri":     "http://studs.io/",
      "license.name": "Apache License 2.0",
      "vcs.uri":      "https://github.com/studsio/core/"]
    depends = [
      "sys @{fan.depend}",
      "util @{fan.depend}",
      "concurrent @{fan.depend}",
      "inet @{fan.depend}",
      "web @{fan.depend}",
      "webmod @{fan.depend}",
      "wisp @{fan.depend}",
      "studs @{buildVersion}"]
    srcDirs = [`test/`]
    resDirs = [`res/`]
    docSrc = false
  }
}