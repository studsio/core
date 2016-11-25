//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Aug 2016  Andy Frank  Creation
//

using concurrent

**
** Cmd models a build tool command.
**
abstract const class Cmd
{
  ** Unique name of this command.
  abstract Str name()

  ** Help signature.
  virtual Str sig() { "" }

  ** One-line short help text for this command.
  abstract Str helpShort()

  ** Full help text for this command, or 'null' for none.
  abstract Str? helpFull()

  ** Run this command and return exit code.
  abstract Int run()

  ** Convenience for 'Env.cur.out.printLine'.
  Void info(Str msg) { Env.cur.out.printLine(msg) }

  ** Convenience for 'Env.cur.err.printLine'.
  Void err(Str msg) { Env.cur.err.printLine(msg) }

  ** Conveniece for 'Env.cur.prompt'.
  Str? prompt(Str msg) { Env.cur.prompt(msg) }

  ** Convenience for 'prompt' with yes/no choice, return true for
  ** 'y' or false for 'n'.  If enter is pressed with no choice,
  ** then use 'def' for default.
  Bool promptYesNo(Str msg, Str def := "y")
  {
    r := prompt(msg)
    if (r == "") r = def
    return r == "y"
  }

  ** Profile configuration.
  static Str:Str profile() { Actor.locals["cmd.profile"] }

  ** List all commands.
  static Cmd[] list() { Actor.locals["cmd.list"] }

  ** Get the given command, or 'null' if not found.
  static Cmd? get(Str name) { list.find |c| { c.name == name } }

  ** List command arguments. Arguments are any terms that
  ** trail the command name not prefixied with '-'.
  Str[] args() { Actor.locals["cmd.args"] }

  ** List of command options.  Options are any terms that
  ** trail the command name and are prexifed with '-'.
  Str[] opts() { Actor.locals["cmd.opts"] }

  ** Print the given error message, show command help, then exit with error code.
  Void abort(Str msg)
  {
    err(msg)
    showHelp
    Env.cur.exit(1)
  }

  ** Convenience to display help for this command to `out`.
  Void showHelp()
  {
    Cmd.get("help")->showDetails(name)
  }
}