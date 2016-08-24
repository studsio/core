//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Aug 2016  Andy Frank  Creation
//

using web

**
** Build project.
**
const class BuildCmd : Cmd
{
  override const Str name := "build"
  override const Str helpShort := "Build project"
  override const Str? helpFull := null

  override Int run()
  {
    f := Env.cur.workDir + `studs.props`
    if (!f.exists) abort("project not found: $Env.cur.workDir.osPath")

    // find targets
    targets := Str[,]
    f.readProps.each |val,key|
    {
      if (key.startsWith("target.") && val == "true")
        targets.add(key["target.".size..-1])
    }

    // install required systems
    targets.each |t| { installSystem(t) }

    // TODO: verify target list
    out.printLine("TODO")
    out.printLine("targets: $targets")
    return 0
  }

  ** Download and install the system configuration for target.
  Void installSystem(Str target)
  {
    sys := System.find(target, false)
    if (sys == null) abort("unknown target: $target")

    // short-circuit if already installed
    dir := Env.cur.workDir + `studs/systems/`
    dir.create
// TODO FIXIT: actually verify - maybe check nerves-system.tag?
    if ((dir + `$sys.name/`).exists) return

    // download
    temp := dir + `$sys.uri.name`
    Proc.download(out, "Downloading $sys.name system", sys.uri, temp)

    // untar
    out.printLine("Install $sys.name system...")
    Proc.run("tar xvf $temp.osPath -C $dir.osPath")

    // rename nerves_system_xxx -> xxx
    (dir + `nerves_system_${sys.name}/`).rename(sys.name)

    // cleanup
    temp.delete
  }
}