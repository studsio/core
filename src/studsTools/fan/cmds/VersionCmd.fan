//
// Copyright (c) 2016, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   22 Aug 2016  Andy Frank  Creation
//

**
** VersionCmd displays version and copyright information.
**
const class VersionCmd : Cmd
{
  override const Str name := "version"

  override const Str helpShort := "Display version and copyright information"

  override const Str? helpFull := null

  override Int run()
  {
    info(
     "Studs $typeof.pod.version
      Copyright (c) 2016-$Date.today.year Andy Frank")
    return 0
  }
}