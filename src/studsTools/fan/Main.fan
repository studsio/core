//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Aug 2016  Andy Frank  Creation
//

class Main
{
  ** Entry point for studs build tools.
  static Int main()
  {
    name := Env.cur.args.first
    cmd  := Cmd.list.find |c| { c.name == name }

    if (cmd == null)
    {
      Env.cur.err.printLine("unknown command: $name")
      HelpCmd().run
      return 1
    }

    return cmd.run
  }
}