//
// Copyright (c) 2016, Andy Frank
// Licensed under the Apache License version 2.0
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
  override const Str sig  := "[--clean] [--gen-keys]"
  override const Str helpShort := "Assemble firmware"
  override const Str? helpFull :=
    "Assemble firmware image for system specified in studs.props.

     --clean     Delete intermediate system and JRE files
     --gen-keys  Generate firmware signing keys (fw-key.pub and fw-key.priv)"

  ** Temp working directory.
  const File tempDir := Env.cur.workDir + `studs/temp/`
  private Void tempClean() { tempDelete; tempDir.create }
  private Void tempDelete() { Proc.run("rm -rf $tempDir.osPath") }

  ** Firmware signing key files.
  private File pubKey()  { Env.cur.workDir + `fw-key.pub` }
  private File privKey() { Env.cur.workDir + `fw-key.priv` }

  override Int run()
  {
    start := Duration.now

    // sanity check
    if (Env.cur isnot PathEnv) abort("Not a PathEnv")

    // check for --gen-keys
    if (opts.contains("gen-keys"))
    {
      // challenge
      if (pubKey.exists || privKey.exists)
      {
        if (!promptYesNo("Key pair already exists. Regenerate and overwrite? [yN] ", "n"))
          abort("cancelled")
      }

      // regenerate
      genKeys
      return 0
    }

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
      // generate keys if not found
      if (!pubKey.exists || !privKey.exists) genKeys

      sys := props.system
      jre := props.jre

      info("Assemble [$sys, $jre]")
      installSystem(sys)
      installJre(jre)
      assemble(sys, jre)

      // clean up after ourselves
      //tempDelete
    }

    dur := Duration.now - start
    loc := (dur.toMillis.toFloat / 1000f).toLocale("0.00")
    info("ASM SUCCESS [${loc}sec]!")
    return 0
  }

  ** Generate firmware signing keys.
  Void genKeys()
  {
    baseDir := Env.cur.workDir

    // start fresh
    pubKey.delete
    privKey.delete

    // gen keys
    info("Generate firmware signing keys...")
    Proc.bash("cd $baseDir.osPath; fwup --gen-keys")
    Proc.run("mv $baseDir.osPath/fwup-key.pub $pubKey.osPath")
    Proc.run("mv $baseDir.osPath/fwup-key.priv $privKey.osPath")
    info("Keep your private key in a safe location!")
  }

  ** Download and install the system configuration for target.
  Void installSystem(System sys)
  {
    baseDir := Env.cur.workDir + `studs/systems/`
    baseDir.create
    sysDir := baseDir + `$sys/`

    // short-circuit if already installed
    if (sysDir.exists) return

    tar := baseDir + `$sys.uri.name`
    if (sys.uri.scheme == "http" || sys.uri.scheme == "https")
    {
      // download tar
      Proc.download("  Downloading ${sys}", sys.uri, tar)
    }
    else
    {
      // assume uri is a local file
      tar = sys.uri.toFile
      if (!tar.exists) abort("file not found: $tar.osPath")
    }

    // untar
    info("  Install ${sys}...")
    Proc.run("tar xvf $tar.osPath -C $baseDir.osPath")

    // TODO: until we update system tar file format; manually
    //       move from xxx -> system-xxx-y.y structure
    dir := baseDir + `${sys.name}/`
    if (dir.exists) dir.moveTo(sysDir)

    // cleanup (only if downloaded)
    if (sys.uri.scheme == "http" || sys.uri.scheme == "https") tar.delete
  }

  ** Download and install the JRE for target.
  Void installJre(Jre jre)
  {
    baseDir := Env.cur.workDir + `studs/jres/`
    baseDir.create
    sysDir := baseDir + `$jre/`

    // short-circuit if already installed
    if (sysDir.exists) return

    tar := baseDir + `$jre.uri.name`
    if (jre.uri.scheme == "http" || jre.uri.scheme == "https")
    {
      // download tar
      Proc.download("  Downloading ${jre}", jre.uri, tar)
    }
    else
    {
      // assume uri is a local file
      tar = jre.uri.toFile
      if (!tar.exists) abort("file not found: $tar.osPath")
    }

    // untar
    info("  Install ${jre}...")
    Proc.run("tar xvf $tar.osPath -C $baseDir.osPath")

    // cleanup (only if downloaded)
    if (jre.uri.scheme == "http" || jre.uri.scheme == "https") tar.delete
  }

  ** Assemble firmware image for target.
  Void assemble(System sys, Jre jre)
  {
    // dir setup
    sysDir := Env.cur.workDir + `studs/systems/${sys}/`
    jreDir := Env.cur.workDir + `studs/jres/${jre}/`
    relDir := Env.cur.workDir + `studs/releases/`
    relDir.create
    tempClean
    rootfs := tempDir + `rootfs_overlay/`
    rootfs.create

    // release image name
    proj := props["proj.name"]; if (proj==null) abort("missing 'proj.meta' in studs.props")
    ver  := props["proj.ver"];  if (ver==null)  abort("missing 'proj.ver' in studs.props")
    urel := relDir + `${proj}-${ver}-${sys.name}._fw`
    srel := relDir + `${proj}-${ver}-${sys.name}.fw`

    // defaults
    fwupConf := sysDir + `images/fwup.conf`

    // stage jre
    info("  Stage rootfs...")
    (rootfs + `app/`).create
    Proc.run("cp -R $jreDir.osPath $rootfs.osPath/app")
    Proc.run("mv $rootfs.osPath/app/${jre} $rootfs.osPath/app/jre")

    // stage faninit
    init := Pod.find("studsTools").file(`/bins/${sys.toolchain}/faninit`)
    init.copyTo(rootfs + `sbin/init`)
    Proc.run("chmod +x $rootfs.osPath/sbin/init")

    // faninit.props
    initProps := Env.cur.workDir + `faninit.props`
    initProps.copyTo(rootfs + `etc/faninit.props`)
    initProps.readProps.keys.each |n|
    {
      if (faninitRetired.containsKey(n))
        info("  # [faninit.props] '$n' prop not longer used")
    }

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

    // fw-key.pub
    pubKey.copyTo(rootfs + `etc/fw-key.pub`)

    // stage scripts
    ["udhcpc.script"].each |name|
    {
      script := Pod.find("studsTools").file(`/scripts/$name`)
      script.copyTo(rootfs + `usr/bin/$name`)
      Proc.run("chmod +x $rootfs.osPath/usr/bin/$name")
    }

    // stage natives
    ["fangpio", "fani2c", "fannet", "fanspi", "fanuart", "fankmsg"].each |name|
    {
      bin := Pod.find("studsTools").file(`/bins/${sys.toolchain}/$name`)
      bin.copyTo(rootfs + `usr/bin/$name`)
      Proc.run("chmod +x $rootfs.osPath/usr/bin/$name")
    }

    // stage libfan
    libfan := Pod.find("studsTools").file(`/bins/${sys.toolchain}/libfan.so`)
    libfan.copyTo(rootfs + `usr/lib/libfan.so`)

    // stage app
    podWhitelist := props["pod.whitelist"]?.split(',') ?: Str#.emptyList
    podBlacklist := props["pod.blacklist"]?.split(',') ?: Str#.emptyList
    (rootfs + `app/fan/lib/fan/`).create
    (rootfs + `app/fan/lib/java/`).create
    (Env.cur.homeDir + `lib/java/sys.jar`).copyTo(rootfs + `app/fan/lib/java/sys.jar`)
    (Env.cur as PathEnv).path.each |path|
    {
      pods := (path + `lib/fan/`).listFiles.findAll |f|
      {
        if (f.ext != "pod") return false
        if (podWhitelist.contains(f.basename)) return true
        if (podBlacklist.contains(f.basename)) return false
        if (podDefBlacklist.contains(f.basename)) return false
        return true
      }
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

    // copy user rootfs_overlay
    userRootfsBase := Env.cur.workDir + `src/rootfs_overlay/`
    userRootfsSys  := Env.cur.workDir + `src/rootfs_overlay_${sys.name}/`
    if (userRootfsBase.exists) Proc.run("cp -Rf $userRootfsBase.osPath/ $rootfs.osPath")
    if (userRootfsSys.exists)  Proc.run("cp -Rf $userRootfsSys.osPath/ $rootfs.osPath")

    // stage data
    (rootfs + `data/`).create

    // merge rootfs
    info("  Merge rootfs...")
    Proc.run(
      "$sysDir.osPath/scripts/merge-squashfs " +
      "$sysDir.osPath/images/rootfs.squashfs " +
      "$tempDir.osPath/combined.squashfs " +
      "$tempDir.osPath/rootfs_overlay")

    // assemble image
    info("  Assemble firmware image...")
    Proc.bash(
      "export NERVES_SYSTEM=$sysDir.osPath
       export ROOTFS=$tempDir.osPath/combined.squashfs
       fwup -c -f $fwupConf.osPath -o $urel.osPath")

    // sign release image
    info("  Signing firmware image...")
    Proc.run("fwup -S -s $privKey.osPath -i $urel.osPath -o $srel.osPath")
    Proc.run("rm $urel.osPath")

    // indicate image filepath
    path := srel.osPath[Env.cur.workDir.osPath.size+1..-1]
    size := srel.size.toLocale("B")
    info("  Release:")
    info("    ${path} [${size}]")
  }

  ** List of retired faninit prop names
  static const Str:Str faninitRetired := [:].setList([
    "fs.mount",
  ])

  ** Blacklist of pods to remove from app staging.
  static const Str[] podDefBlacklist := [
    "studsTest",
    "studsTools",
    "build",          // build tools
    "compiler",
    "compilerDoc",
    "compilerJava",
    "compilerJs",
    "docDomkit",      // docs
    "docFanr",
    "docIntro",
    "docLang",
    "docTools",
    "examples",
    "icons",          // fwt and flux
    "gfx",
    "fwt",
    "webfwt",
    "flux",
    "fluxText",
    "syntax",
    "email",          // misc
    "fandoc",
    "fanr",
    "fansh",
    "obix",
    "sql",
    "yaml",
    "testCompiler",   // unit tests
    "testDomkit",
    "testGraphics",
    "testJava",
    "testNative",
    "testSys",
  ]
}