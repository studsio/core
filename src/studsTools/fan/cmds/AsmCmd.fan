//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Aug 2016  Andy Frank  Creation
//

using util

**
** Assemble project.
**
const class AsmCmd : Cmd
{
  override const Str name := "asm"
  override const Str sig  := "[target]*"
  override const Str helpShort := "Assemble project"
  override const Str? helpFull :=
    "By default the asm command will assemble a firmware image for each
     target specifed in studs.props.  If target(s) are listed on the
     command line, only these targets will be assembled.

     [target]*  List of specific targets to assemble, or all if none specified"

  ** Temp working directory.
  const File tempDir := Env.cur.workDir + `studs/temp/`
  private Void tempClean() { tempDelete; tempDir.create }
  private Void tempDelete() { Proc.run("rm -rf $tempDir.osPath") }

  override Int run()
  {
    // sanity check
    if (Env.cur isnot PathEnv) abort("Not a PathEnv")

    f := Env.cur.workDir + `studs.props`
    if (!f.exists) abort("project not found: $Env.cur.workDir.osPath")

    // make sure temp is clean
    tempClean

    // find proj-meata
    projMeta := Str:Str[:]
    f.readProps.each |val,key|
    {
      if (key.startsWith("proj.")) projMeta[key] = val
    }

    // find targets - pick up from cmdline or fallback to studs.props
    targets := args.dup.rw
    if (targets.isEmpty)
    {
      f.readProps.each |val,key|
      {
        if (key.startsWith("target.") && val == "true")
        {
          name := key["target.".size..-1]
          targets.add(name)
        }
      }
    }

    // validate targets first
    targets.each |t| {
      if (System.find(t, false) == null) abort("unknown target: $t")
    }

    // build each target
    targets.each |t|
    {
      info("Assemble [$t]")
      sys := System.find(t)
      installSystem(sys)
      buildJre(sys)
      assemble(sys, projMeta)
    }

    // clean up after ourselves
    //tempDelete
    return 0
  }

  ** Download and install the system configuration for target.
  Void installSystem(System sys)
  {
    baseDir := Env.cur.workDir + `studs/systems/`
    baseDir.create
    sysDir := baseDir + `$sys.name/`

    // check if up-to-date
    sysProps := sysDir + `system.props`
    if (sysProps.exists)
    {
      // bail here if up-to-date
      ver := Version(sysProps.readProps["version"] ?: "", false)
      if (sys.version == ver) return

      // prompt to upgrade
      // TODO: do we abort if out-of-date???
      if (!promptYesNo("Upgrade $sys.name $ver -> $sys.version? [Yn] ")) return
      Proc.run("rm -rf $sysDir.osPath")
    }

    // download
    tar := baseDir + `$sys.uri.name`
    Proc.download("  Downloading $sys.name system", sys.uri, tar)

    // untar
    info("  Install $sys.name system...")
    Proc.run("tar xvf $tar.osPath -C $baseDir.osPath")

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
    info("  Build ${jreDir.name} jre...")
    Proc.run("tar xf $tar.osPath -C $tempDir.osPath")

    // invoke jrecreate (requires Java 7+)
    jdkDir := tempDir.listDirs.find |d| { d.name.startsWith("ejdk") }
    Proc.bash(
      "export JAVA_HOME=\$(/usr/libexec/java_home)
       ${jdkDir.osPath}/bin/jrecreate.sh --dest $jreDir.osPath --profile compact3 -vm client")
  }

  ** Assemble firmware image for target.
  Void assemble(System sys, Str:Str projMeta)
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
    proj := projMeta["proj.name"]; if (proj==null) abort("missing 'proj.meta' in studs.props")
    ver  := projMeta["proj.ver"];  if (ver==null)  abort("missing 'proj.ver' in studs.props")
    rel  := relDir + `${proj}-${ver}-${sys.name}.fw`

    // defaults
    fwupConf := sysDir + `images/fwup.conf`

    // stage jre
    info("  Stage rootfs...")
    (rootfs + `app/`).create
    Proc.run("cp -R $jreDir.osPath $rootfs.osPath/app")
    Proc.run("mv $rootfs.osPath/app/${sys.jre} $rootfs.osPath/app/jre")

    // stage faninit
    init := Pod.find("studsTools").file(`/bins/$sys.name/faninit`)
    init.copyTo(rootfs + `sbin/init`)
    Proc.run("chmod +x $rootfs.osPath/sbin/init")

    // faninit.props
    initProps := Env.cur.workDir + `faninit.props`
    initProps.copyTo(rootfs + `etc/faninit.props`)

    // stage app
    (rootfs + `app/fan/lib/fan/`).create
    (rootfs + `app/fan/lib/java/`).create
    (Env.cur.homeDir + `lib/java/sys.jar`).copyTo(rootfs + `app/fan/lib/java/sys.jar`)
    (Env.cur as PathEnv).path.each |path|
    {
      pods := (path + `lib/fan/`).listFiles.findAll |f| { f.name != "studsTools" && f.ext == "pod" }
      pods.each |p| { p.copyTo(rootfs + `app/fan/lib/fan/$p.name`) }
    }

    // unit database
    units := Env.cur.homeDir + `etc/sys/units.txt`
    units.copyTo(rootfs + `app/fan/etc/sys/$units.name`)

    // tz database
    tzData  := Env.cur.homeDir + `etc/sys/timezones.ftz`
    tzAlias := Env.cur.homeDir + `etc/sys/timezone-aliases.props`
    tzJs    := Env.cur.homeDir + `etc/sys/tz.js`
    tzData.copyTo(rootfs + `app/fan/etc/sys/$tzData.name`)
    tzAlias.copyTo(rootfs + `app/fan/etc/sys/$tzAlias.name`)
    tzJs.copyTo(rootfs + `app/fan/etc/sys/$tzJs.name`)

    // copy user rootfs-additions
    userRootfs := Env.cur.workDir + `src/rootfs-additions/${sys.name}/`
    if (userRootfs.exists) Proc.run("cp -Rf $userRootfs.osPath/ $rootfs.osPath")

    // stage data
    (rootfs + `data/`).create

    // merge rootfs
    info("  Merge rootfs...")
    Proc.run(
      "$sysDir.osPath/scripts/merge-squashfs " +
      "$sysDir.osPath/images/rootfs.squashfs " +
      "$tempDir.osPath/combined.squashfs " +
      "$tempDir.osPath/rootfs-additions")

    // assemble image
    info("  Assemble firmware image...")
    Proc.bash(
      "export NERVES_SYSTEM=$sysDir.osPath
       export ROOTFS=$tempDir.osPath/combined.squashfs
       fwup -c -f $fwupConf.osPath -o $rel.osPath")

    // indicate image filepath
    info("  Release: $rel.osPath")
  }
}