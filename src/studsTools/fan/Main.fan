//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Aug 2016  Andy Frank  Creation
//

using concurrent

class Main
{
  ** Entry point for studs build tools.
  static Int main()
  {
    setup
    name := Env.cur.args.first
    cmd  := Cmd.list.find |c| { c.name == name }
    if (cmd == null) abort("unknown command: $name")
    return cmd.run
  }

  ** Setup const data structures.
  private static Void setup()
  {
    // setup Cmd.profile
    profile := Str:Str[:]
    try
    {
      home := Env.cur.vars["user.home"] ?: ""
      file := "$home/.studs".toUri.toFile
      if (file.exists) profile = file.readProps
    }
    finally {}
    Actor.locals["cmd.profile"] = profile.toImmutable

    // setup Cmd.props
    Actor.locals["cmd.props"] = Props()

    // setup Cmd.list
    types := Cmd#.pod.types.findAll |t| { t != Cmd# && t.fits(Cmd#) }
    Cmd[] cmds := types.map |c| { c.make }
    map := Str:Cmd[:].addList(cmds) |c| { c.name }
    Actor.locals["cmd.list"] = cmds.sort |a,b| { a.name <=> b.name }.toImmutable

    // setup Cmd.args/opts
    args := Str[,]
    opts := Str[,]
    Env.cur.args.each |s,i|
    {
      if (i == 0) return
      if (s == "-") abort("Invalid option")
      if (s.startsWith("--")) opts.add(s[2..-1])
      else if (s.startsWith("-")) { s[1..-1].each |ch| { opts.add(ch.toChar) }}
      else args.add(s)
    }

    Actor.locals["cmd.args"] = args.toImmutable
    Actor.locals["cmd.opts"] = opts.toImmutable
  }

  ** Print message and exit with err code.
  static Void abort(Str msg)
  {
    Env.cur.err.printLine(msg)
    Cmd.get("help")->showOverview
    Env.cur.exit(1)
  }
}