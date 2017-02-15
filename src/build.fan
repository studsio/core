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
      `studsTest/build.fan`,
      `faninit/build.fan`,
      `fanuart/build.fan`,

      // We need to rebuild studsTools after natives have been
      // compiled since this is where we package them.  This is
      // a litte hacky - but saves us from having to keep track
      // of another resource
      `studsTools/build.fan`,
    ]
  }
}
