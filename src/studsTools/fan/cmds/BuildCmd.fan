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
      {
        name := key["target.".size..-1]
        if (System.find(name, false) == null) abort("unknown target: $name")
        targets.add(name)
      }
    }

    // build each target
    targets.each |t|
    {
      sys := System.find(t)
      installSystem(sys)
      buildJre(sys)
      buildFw(sys)
    }

    // clean up after ourselves
    tempDelete
    return 0
  }

  ** Download and install the system configuration for target.
  Void installSystem(System sys)
  {
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
    info("Install $sys.name system...")
    Proc.run("tar xvf $tar.osPath -C $baseDir.osPath")

    // rename nerves_system_xxx -> xxx
    (baseDir + `nerves_system_${sys.name}/`).rename(sys.name)

    // cleanup
    tar.delete
  }

  ** Build compact JRE for target.
  Void buildJre(System sys)
  {
    baseDir := Env.cur.workDir + `studs/jres/`
    baseDir.create
    jreDir := baseDir + `$sys.jre/`

    // bail if already exists
    if (jreDir.exists) return

    // find source tar image
    tar := baseDir.listFiles.find |f| { f.name.endsWith("${sys.jre}.tar.gz") }
    if (tar == null) Proc.abort("no jre found for $sys.name")

    // unpack
    tempClean
    info("Build ${jreDir.name} jre...")
    Proc.run("tar xf $tar.osPath -C $tempDir.osPath")

    // invoke jrecreate (requires Java 7+)
    jdkDir := tempDir.listDirs.find |d| { d.name.startsWith("ejdk") }
    Proc.bash(
      "export JAVA_HOME=\$(/usr/libexec/java_home)
       ${jdkDir.osPath}/bin/jrecreate.sh --dest $jreDir.osPath --profile compact3 -vm client")
  }

  ** Assemble firmware image for target.
  Void buildFw(System sys)
  {
    // dir setup
    jreDir := Env.cur.workDir + `studs/jres/$sys.jre/`
    sysDir := Env.cur.workDir + `studs/systems/$sys.name/`
    relDir := Env.cur.workDir + `studs/releases/`
    relDir.create
    tempClean
    rootfs := tempDir + `rootfs-additions/`
    rootfs.create

    // release image name
    proj := Env.cur.workDir.basename
    ver  := Pod.find(proj).version
    rel  := relDir + `${proj}-${ver}-${sys.name}.fw`

    // defaults
    fwupConf := sysDir + `images/fwup.conf`

    // copy jre
    (rootfs + `srv/`).create
    Proc.run("cp -R $jreDir.osPath $rootfs.osPath/srv")
    Proc.run("mv $rootfs.osPath/srv/${sys.jre} $rootfs.osPath/srv/jre")

    // copy app
    (rootfs + `app/`).create
    // TODO FIXIT

    // copy user rootfs-additions
    // TODO FIXIT

    // merge rootfs
    info("Merge rootfs...")
    Proc.run(
      "$sysDir.osPath/scripts/merge-squashfs " +
      "$sysDir.osPath/images/rootfs.squashfs " +
      "$tempDir.osPath/combined.squashfs " +
      "$tempDir.osPath/rootfs-additions")

    // build image
    info("Build firmware image...")
    Proc.bash(
      "export NERVES_SYSTEM=$sysDir.osPath
       export ROOTFS=$tempDir.osPath/combined.squashfs
       fwup -c -f $fwupConf.osPath -o $rel.osPath")
  }
}