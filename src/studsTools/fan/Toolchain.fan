//
// Copyright (c) 2017, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   24 Jan 2017  Andy Frank  Creation
//

using web

**
** Toolchain models a cross-compiler toolchain.
**
const class Toolchain
{
  ** Construct a new toolchain with name and version.
  new make(Str name, Str ver, Str githash)
  {
    this.name    = name
    this.version = Version(ver)
    this.githash = githash
    this.host    = Env.cur.os == "macosx" ? "darwin_x86_64" : "linux_x86_64"
    this.qname   = "nerves_toolchain_${name}-${host}-${version}-${githash}"
    this.dir = Env.cur.workDir + `toolchains/$qname/`
    this.gcc = dir + ("bin/" + name.replace("_", "-") + "-gcc").toUri
  }

  ** Compile with toolchains to target systems
  static Void compile(Str binName, File srcDir, File[] xsrc, Str[] ccOpts)
  {
    echo("compile [$binName]")
    ver := Toolchain#.pod.version
    Toolchain.toolchains.each |tc, target|
    {
      // check if we need to install toolchain
      if (!tc.dir.exists) tc.install

      // make sure studTools target dir exists
      binDir := Env.cur.workDir + `src/studsTools/bins/$target/`
      binDir.create
      dest := binDir + `$binName`

      // compile
      echo("  Compile [$binName-$target]")
      opts := ccOpts.addAll(["-o", "$dest.osPath"])
      src  := srcDir.listFiles.map |f| { "src/$f.name" }
      xsrc.each |f| { src.add(f.osPath) }
      proc := Process([tc.gcc.osPath].addAll(opts).addAll(src))
      proc.dir = srcDir.parent
      if (proc.run.join != 0) abort("gcc failed")

      // indicate dest dir
      echo("    Write [$dest.osPath]")
    }
  }

  ** Install toolchain to host.
  private Void install()
  {
    // download
    echo("  InstallToolchain [$name]")
    uri := `https://github.com/nerves-project/toolchains/releases/download/v${version}/${qname}.tar.xz`
    tar := Env.cur.workDir + `$uri.name`
    download("    Downloading", uri, tar)

    // untar
    echo("    Untar")
    dir := Env.cur.workDir + `toolchains/`
    dir.create
    proc := Process(["tar", "xf", tar.osPath, "-C", dir.osPath])
    proc.out = null
    if (proc.run.join != 0) abort("tar failed")

    // rename target dir
    (dir + `${qname}.tar.xz/`).rename(qname)

    // cleanup
    tar.delete
  }

  ** Download content from URI and pipe to given file. Progress
  ** will be written to 'out' prefixed with 'msg'.
  private Void download(Str msg, Uri uri, File target)
  {
    out := target.out
    client := WebClient(uri)
    try
    {
      client.writeReq.readRes
      len := client.resHeaders["Content-Length"].toInt
      in  := client.resIn
      bsz := 4096                      // buf size to read at a time
      cur := 0                         // how many bytes have been read
      Int? read                        // bytes read on last attempt
      buf := Buf { it.capacity=bsz }   // read buffer

      while ((read = in.readBuf(buf.clear, bsz)) != null)
      {
        // pipe to target file
        out.writeBuf(buf.flip)

        // update progress
        cur += read
        per := (cur.toFloat / len.toFloat * 100f).toInt.toStr.padl(2)
        Env.cur.out.print("\r${msg}... ${per}%\r")
      }

      Env.cur.out.printLine("")
    }
    finally { client.close; out.close }
  }

  ** Print the given error message then exit with error code.
  private static Void abort(Str msg)
  {
    Env.cur.err.printLine(msg)
    Env.cur.exit(1)
  }

  ** Map of toolchains to system targets.
  internal static const Str:Toolchain toolchains := [
    "bb":   Toolchain("arm_unknown_linux_gnueabihf", "1.0.0", "400FC9B"),
    "rpi3": Toolchain("arm_unknown_linux_gnueabihf", "1.0.0", "400FC9B"),
    "rpi0": Toolchain("armv6_rpi_linux_gnueabi",     "1.0.0", "D5EC22E"),
  ]

  const Str name
  const Version version
  const Str githash
  const Str host
  const Str qname
  const File dir
  const File gcc
}
