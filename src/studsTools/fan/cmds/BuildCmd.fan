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
    baseDir := Env.cur.workDir + `studs/systems/`
    baseDir.create
    sysDir := baseDir + `$sys.name/`

    // check if up-to-date
    tag := sysDir + `nerves-system.tag`
    if (tag.exists)
    {
      line := tag.readAllLines.first
      ver  := Version(line[1..-1], false)

      // up-to-date bail
      if (sys.version == ver) return

      // prompt to upgrade
      // TODO: do we abort if out-of-date???
      if (!promptYesNo("Upgrade $sys.name $ver -> $sys.version? [Yn] ")) return
      Proc.run("rm -rf $sysDir.osPath")
    }

    // download
    tar := baseDir + `$sys.uri.name`
    Proc.download("Downloading $sys.name system", sys.uri, tar)

    // untar
    out.printLine("Install $sys.name system...")
    Proc.run("tar xvf $tar.osPath -C $baseDir.osPath")

    // rename nerves_system_xxx -> xxx
    (baseDir + `nerves_system_${sys.name}/`).rename(sys.name)

    // cleanup
    tar.delete
  }
}