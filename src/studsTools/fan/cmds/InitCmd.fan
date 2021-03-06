//
// Copyright (c) 2016, Andy Frank
// Licensed under the Apache License version 2.0
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
  override const Str sig  := "<name>"
  override const Str helpShort := "Create a new project"
  override const Str? helpFull :=
   "<name>  Name for new project (must be a valid pod name)"

  override Int run()
  {
    // validate input
    name := args.getSafe(0)
    if (name == null)  abort("missing arg: name")
    if (!isName(name)) abort("invalid arg: name")

    // check if dir exists
    dir := workDir + `$name/`
    if (dir.exists) abort("dir already exists: $dir.osPath")

    // prompt to continue
    if (!promptYesNo("Init project: $dir.osPath [Yn] ")) return 1

    // do it!
    macros := ["proj.name":name]
    dir.create
    (dir + `src/fan/`).create
    (dir + `studs/jres/`).create
    (dir + `studs/systems/`).create
    (dir + `studs/releases/`).create
    apply(typeof.pod.file(`/res/fan.propsx`),     macros, dir + `fan.props`)
    apply(typeof.pod.file(`/res/faninit.propsx`), macros, dir + `faninit.props`)
    apply(typeof.pod.file(`/res/studs.propsx`),   macros, dir + `studs.props`)
    apply(typeof.pod.file(`/res/build.fanx`),     macros, dir + `src/build.fan`, true)
    apply(typeof.pod.file(`/res/Main.fanx`),      macros, dir + `src/fan/Main.fan`)
    return 0
  }

  ** Return 'true' if string is a valid project name.
  Bool isName(Str s)
  {
    if (!s[0].isAlpha) return false
    if (!s[0].isLower) return false
    return s.all |ch| { ch.isAlphaNum || ch == '_' }
  }

  ** Read given resource file, apply macros, and write results to given target
  Void apply(File src, Str:Str macros, File target, Bool exec := false)
  {
    in  := src.in
    out := target.out
    try
    {
      // apply macros
      in.readAllStr.splitLines.each |s|
      {
        macros.each |v,n| { s = s.replace("{{$n}}", v) }
        out.printLine(s)
      }

      // mark +x
      if (exec) Proc.run("chmod +x $target.osPath")
    }
    finally { in.close; out.close }
  }
}