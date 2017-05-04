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
  override const Str sig  := "[target]* [--clean]"
  override const Str helpShort := "Assemble project"
  override const Str? helpFull :=
    "By default the asm command will assemble a firmware image for each
     target specified in studs.props.  If target(s) are listed on the
     command line, only these targets will be assembled.

     [target]*  List of specific targets to assemble, or all if none specified

     --clean    Delete intermediate system and JRE files"

  ** Temp working directory.
  const File tempDir := Env.cur.workDir + `studs/temp/`
  private Void tempClean() { tempDelete; tempDir.create }
  private Void tempDelete() { Proc.run("rm -rf $tempDir.osPath") }

  override Int run()
  {
    start := Duration.now

    // sanity check
    if (Env.cur isnot PathEnv) abort("Not a PathEnv")

    // make sure temp is clean
    tempClean

    if (opts.contains("clean"))
    {
      // clean intermediate files
      info("Clean")
      dirs := File[,]
      dirs.addAll((Env.cur.workDir + `studs/systems/`).listDirs)
      dirs.addAll((Env.cur.workDir + `studs/jres/`).listDirs)
      dirs.each |d|
      {
        info("  Delete $d.osPath")
        d.delete
      }
    }
    else
    {
      // check for cmdline system filter
      System[] systems := args.isEmpty
        ? props.systems
        : args.map |n| { props.system(n) }

      // build each target
      systems.each |sys|
      {
        info("Assemble [$sys.name]")
        installSystem(sys)
        buildJre(sys)
        assemble(sys)
      }

      // clean up after ourselves
      //tempDelete
    }

    dur := Duration.now - start
    loc := (dur.toMillis.toFloat / 1000f).toLocale("0.00")
    info("ASM SUCCESS [${loc}sec]!")
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

    tar := baseDir + `$sys.uri.name`
    if (sys.uri.scheme == "http" || sys.uri.scheme == "https")
    {
      // download tar
      Proc.download("  Downloading $sys.name system", sys.uri, tar)
    }
    else
    {
      // assume uri is a local file
      tar = sys.uri.toFile
      if (!tar.exists) abort("file not found: $tar.osPath")
    }

    // untar
    info("  Install $sys.name system...")
    Proc.run("tar xvf $tar.osPath -C $baseDir.osPath")

    // cleanup
    tar.delete
  }

  ** Build compact JRE for target.
  Void buildJre(System sys)
  {
    profDir := profile["jres.dir"]?.toUri?.toFile
    baseDir := Env.cur.workDir + `studs/jres/`
    baseDir.create
    jreDir := baseDir + `$sys.jre/`

    // determine JRE compact profile to use
    jreProfStr := props["jre.profile"] ?: "1"
    jreProfile := jreProfStr.toInt(10, false)
    if (jreProfile == null || !(1..3).contains(jreProfile))
      Proc.abort("invalid jre.profile '$jreProfStr'")

    // TODO: check if profile has changed?

    // bail if already exists
    if (jreDir.exists) return

    // find source tar image - first check local dir, and if not
    // found try to find the profile dir if one is defined
    find := |File dir->File?| {
      dir.listFiles.find |f| { f.name.endsWith("${sys.jre}.tar.gz") }
    }
    tar := find(baseDir)
    if (tar == null && profDir != null) tar = find(profDir)
    if (tar == null) Proc.abort("no jre found for $sys.name")

    // unpack
    tempClean
    info("  Build ${jreDir.name} jre [compact${jreProfile}]...")
    Proc.run("tar xf $tar.osPath -C $tempDir.osPath")

    // invoke jrecreate (requires Java 7+)
    jdkDir := tempDir.listDirs.find |d| { d.name.startsWith("ejdk") }
    Proc.bash(
      "export JAVA_HOME=\$(/usr/libexec/java_home)
       ${jdkDir.osPath}/bin/jrecreate.sh --dest $jreDir.osPath --profile compact${jreProfile} -vm client")
  }

  ** Assemble firmware image for target.
  Void assemble(System sys)
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
    proj := props["proj.name"]; if (proj==null) abort("missing 'proj.meta' in studs.props")
    ver  := props["proj.ver"];  if (ver==null)  abort("missing 'proj.ver' in studs.props")
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

    // sys.props
    sysProps := Str:Str[:] {
      it.ordered = true
      it.set("proj.name",      proj)
      it.set("proj.version",   ver)
      it.set("studs.version",  AsmCmd#.pod.version.toStr)
      it.set("system.name",    sys.name)
      it.set("system.version", sys.version.toStr)
    }
    (rootfs + `etc/sys.props`).writeProps(sysProps)

    // stage natives
    ["fangpio", "fani2c", "fanspi", "fanuart"].each |name|
    {
      bin := Pod.find("studsTools").file(`/bins/$sys.name/$name`)
      bin.copyTo(rootfs + `usr/bin/$name`)
      Proc.run("chmod +x $rootfs.osPath/usr/bin/$name")
    }

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
    size := rel.size.toLocale("B")
    info("  Release:")
    info("    $rel.osPath [$size]")
  }
}