#! /usr/bin/env fan
//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Aug 2016  Andy Frank  Creation
//

using build
using fanr
using util

**
** Studs top level build script
**
class Build : BuildGroup
{
  new make()
  {
    childrenScripts =
    [
      `studs/build.fan`,
      `studsTools/build.fan`,
    ]
  }
}
