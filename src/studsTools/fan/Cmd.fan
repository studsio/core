//
// Copyright (c) 2016, Andy Frank
// Licensed under the Apache License version 2.0
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

  ** Convenience for 'prompt' with an integer range choice, returns
  ** the selected choise, or aborts if invalid input or out of range.
  Int promptChoice(Str msg, Range range)
  {
    s := prompt("$msg [$range] ")
    i := s.toInt(10, false)
    if (i == null || !range.contains(i)) abort("invalid selection '$s'")
    return i
  }

  ** Profile configuration.
  static Str:Str profile() { Actor.locals["cmd.profile"] }

  ** Props configuration.
  static Props props()
  {
    p := Actor.locals["cmd.props"] as Props
    if (p == null) Actor.locals["cmd.props"] = p = Props()
    return p
  }

  ** List all commands.
  static Cmd[] list() { Actor.locals["cmd.list"] }

  ** Get the given command, or 'null' if not found.
  static Cmd? get(Str name) { list.find |c| { c.name == name } }

  ** Get the current working directory.
  File workDir()
  {
    path := Env.cur.vars["user.dir"]
    return path==null ? Env.cur.workDir : File.os(path)
  }

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
// TODO?
//    showHelp
    Env.cur.exit(1)
  }

  ** Convenience to display help for this command.
  Void showHelp()
  {
    Cmd.get("help")->showDetails(name)
  }

  ** Prompt to select a current release. Returns selected release fw file.
  @NoDoc File? promptRelease(Str action)
  {
    relDir := Env.cur.workDir + `studs/releases/`
    rels   := relDir.listFiles.findAll |f| { f.ext == "fw" }

    // sort by filename
    rels.sort |a,b| { a.name <=> b.name }

    // bail if no releases found
    if (rels.isEmpty) abort("no releases found")

    // prompt for release selection
    File? rel
    if (rels.size == 1) rel = rels.first
    else
    {
      echo("Available releases:")
      w := rels.map |f| { f.name.size }.max
      rels.each |f,i|
      {
        size := f.size.toLocale("B")
        date := f.modified.date == Date.today
          ? "Today     " + f.modified.toLocale("k::mmaa")
          : f.modified.toLocale("DD-MMM-YY k::mmaa")
        echo(" [${i+1}] " + f.name.padr(w) + "   $size  $date")
      }
      sel := promptChoice("Which release do you want to ${action}?", 1..rels.size)
      rel = rels[sel-1]
    }

    return rel
  }
}