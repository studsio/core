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
  override const Str helpShort := "Show command help or command list overview"
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
      err("unknown command: $name")
      showOverview
      return 1
    }

    info(
      "Usage:
         fan studs $c.name $c.sig

       $c.helpShort")

    full := c.helpFull
    if (full != null)
    {
      info("")
      full.splitLines.each |s| { info("  $s") }
    }

    return 0
  }

  ** Display help overview.
  internal Int showOverview()
  {
    info("Usage: studs <cmd> [options]")
    info("")

    // find max command name length
    clen := 0
    cmds := Cmd.list
    cmds.each |c| { clen = clen.max(c.name.size) }

    Cmd.list.each |c|
    {
      info("  ${c.name.padr(clen)}  $c.helpShort")
    }

    info("")
    info("Use \"studs help <cmd>\" for additional information on each command")
    info("")
    return 0
  }
}