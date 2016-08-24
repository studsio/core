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

  ** Temp working directory.
  const File tempDir := Env.cur.workDir + `studs/temp/`
  private Void tempClean() { tempDelete; tempDir.create }
  private Void tempDelete() { Proc.run("rm -rf $tempDir.osPath") }

  override Int run()
  {
    f := Env.cur.workDir + `studs.props`
    if (!f.exists) abort("project not found: $Env.cur.workDir.osPath")

    // make sure temp is clean
    tempClean

    // find targets
    targets := Str[,]
    f.readProps.each |val,key|
    {
      if (key.startsWith("target.") && val == "true")
        targets.add(key["target.".size..-1])
    }

    // install required systems
    targets.each |t| { installSystem(t) }

    // build jres
    targets.each |t| { buildJre(t) }

    // TODO

    // clean up after ourselves
    tempDelete
    return 0
  }

  ** Download and install the system configuration for target.
  Void installSystem(Str target)
  {
    sys := System.find(target, false)
    if (sys == null) abort("unknown target: $target")

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

  ** Build compact JRE for target.
  Void buildJre(Str target)
  {
    sys := System.find(target, false)
    if (sys == null) abort("unknown target: $target")

    // bail if already exists
    baseDir := Env.cur.workDir + `studs/jres/`
    baseDir.create
    jreDir := baseDir + `$sys.jre/`
    if (jreDir.exists) return

    // find source tar image
    tar := baseDir.listFiles.find |f| { f.name.endsWith("${sys.jre}.tar.gz") }
    if (tar == null) Proc.abort("no jre found for $target")

    // unpack
    tempClean
    out.printLine("Build ${jreDir.name} jre...")
    Proc.run("tar xf $tar.osPath -C $tempDir.osPath")

    // invoke jrecreate (requires Java 7+)
    jdkDir := tempDir.listDirs.find |d| { d.name.startsWith("ejdk") }
    Proc.bash(
      "export JAVA_HOME=\$(/usr/libexec/java_home)
       ${jdkDir.osPath}/bin/jrecreate.sh --dest $jreDir.osPath --profile compact3 -vm client")
  }
}