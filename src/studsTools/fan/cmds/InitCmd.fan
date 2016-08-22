//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Aug 2016  Andy Frank  Creation
//

**
** Create a new project.
**
const class InitCmd : Cmd
{
  override const Str name := "init"

  override const Str helpShort := "Create a new project"

  override const Str? helpFull :=
   "TODO"

  override Int run()
  {
    name := args.getSafe(0)

    // missing name
    if (name == null)
    {
      err.printLine("missing arg: name")
      showHelp
      return 1
    }

    // invalid name
    if (!isName(name))
    {
      err.printLine("invalid arg: name")
      showHelp
      return 1
    }

    // prompt to continue
    dir := Env.cur.workDir + name.toUri
    res := prompt("Init project: $dir.osPath [Yn] ")
    if (res != "" && res.lower != "y") return 1

    // go
    out.printLine("TODO")
    return 0
  }

  ** Return 'true' if string is a valid project name.
  Bool isName(Str s)
  {
    if (!s[0].isAlpha) return false
    return s.all |ch| { ch.isAlphaNum || ch == '_' }
  }
}