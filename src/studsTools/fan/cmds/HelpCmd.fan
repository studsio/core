//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Aug 2016  Andy Frank  Creation
//

**
** HelpCmd display command help.
**
const class HelpCmd : Cmd
{
  override const Str name := "help"

  override const Str helpShort := "Show command help or comand list overview"

  override const Str? helpFull := "TODO"

  override Int run()
  {
    out.printLine("Usage: studs <cmd> [cmd args]")
    out.printLine("")

    // find max command name length
    clen := 0
    cmds := Cmd.list
    cmds.each |c| { clen = clen.max(c.name.size) }

    Cmd.list.each |c|
    {
      out.printLine("  ${c.name.padr(clen)}  $c.helpShort")
    }

    out.printLine("")
    out.printLine("Use \"studs help <cmd>\" for additional information on each command")
    return 0
  }
}