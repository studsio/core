//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Aug 2016  Andy Frank  Creation
//

**
** Cmd models a build tool command.
**
abstract const class Cmd
{
  ** Unique name of this command.
  abstract Str name()

  ** One-line short help text for this command.
  abstract Str helpShort()

  ** Full help text for this command, or 'null' for none.
  abstract Str? helpFull()

  ** Run this command and return exit code.
  abstract Int run()

  ** Convenience for 'Env.cur.out'.
  OutStream out() { Env.cur.out }

  ** Convenience for 'Env.cur.err'.
  OutStream err() { Env.cur.out }

  ** List all commands.
  static Cmd[] list()
  {
    // find all commands and verify names
    types := Cmd#.pod.types.findAll |t| { t != Cmd# && t.fits(Cmd#) }
    Cmd[] cmds := types.map |c| { c.make }
    map := Str:Cmd[:].addList(cmds) |c| { c.name }
    return cmds.sort |a,b| { a.name <=> b.name }
  }
}