//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
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
    out.printLine(
     "Studs $typeof.pod.version
      Copyright (c) 2016 Andy Frank")
    return 0
  }
}