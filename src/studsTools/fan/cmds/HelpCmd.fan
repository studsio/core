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
  override const Str sig  := "[cmd]"
  override const Str helpShort := "Show command help or comand list overview"
  override const Str? helpFull :=
    "cmd  Show detailed help for 'cmd'"

  override Int run()
  {
    args.size > 0 ? showDetails(args.first) : showOverview
  }

  ** Display command details.
  internal Int showDetails(Str name)
  {
    c := Cmd.get(name)

    if (c == null)
    {
      err.printLine("unknown command: $name")
      showOverview
      return 1
    }

    out.printLine(
      "studs $c.name $c.sig

       $c.helpShort")

    full := c.helpFull
    if (full != null)
    {
      out.printLine("")
      full.splitLines.each |s| { out.printLine("  $s") }
    }

    return 0
  }

  ** Display help overview.
  internal Int showOverview()
  {
    out.printLine("Usage: studs <cmd> [options]")
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
    out.printLine("")
    return 0
  }
}