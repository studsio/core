//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Aug 2016  Andy Frank  Creation
//

**
** Build project.
**
const class BuildCmd : Cmd
{
  override const Str name := "build"
  override const Str helpShort := "Build project"
  override const Str? helpFull := null

  override Int run()
  {
    f := Env.cur.workDir + `studs.props`
    if (!f.exists) abort("project not found: $Env.cur.workDir.osPath")

    // find targets
    targets := Str[,]
    f.readProps.each |val,key|
    {
      if (key.startsWith("target.") && val == "true")
        targets.add(key["target.".size..-1])
    }

    // TODO: verify target list
    out.printLine("TODO")
    out.printLine("targets: $targets")
    return 0
  }
}