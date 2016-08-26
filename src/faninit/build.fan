#! /usr/bin/env fan
//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Aug 2016  Andy Frank  Creation
//

using build
using web

**
** Build: faninit
**
class Build : BuildScript
{
  ** Map of toolchains to system targets
  const Str:Toolchain toolchains := [
    "bbb":  Toolchain("arm-unknown-linux-gnueabihf-darwin-x86_64", "0.6.1"),
    "rpi3": Toolchain("arm-unknown-linux-gnueabihf-darwin-x86_64", "0.6.1"),
  ]

  ** Compile with toolchains to target systems
  @Target { help = "Compile faninit binary" }
  Void compile()
  {
    log.info("compile [faninit]")

    toolchains.each |tc, target|
    {
      // check if we need to install toolchain
      if (!tc.dir.exists)
      {
        // download
        log.info("  InstallToolchain [$tc.name]")
        uri := ("https://github.com/nerves-project/nerves-toolchain/releases/download/" +
                "v${tc.version}/nerves-${tc.name}-v${tc.version}.tar.xz").toUri
        tar := Env.cur.workDir + `$uri.name`
        download("    Downloading", uri, tar)

        // untar
        log.info("    Untar")
        dir := Env.cur.workDir + `toolchains/`
        dir.create
        proc := Process(["tar", "xf", tar.osPath, "-C", dir.osPath])
        proc.out = null
        if (proc.run.join != 0) throw fatal("tar failed")

        // cleanup
        tar.delete
      }

      // make sure studTools target dir exists
      binDir := Env.cur.workDir + `src/studsTools/bins/$target/`
      binDir.create
      dest := binDir + `faninit`

      // TODO FIXIT: auto-check if repo out-of-date?
      //   https://developer.github.com/v3/repos/commits/
      //   https://github.com/nerves-project/erlinit
      //   synced @ [Jun-23-2016] Fix Coverity errors -- 3c7a1134d20fc9823e52ac2ec94d7c5b9816576f

      // compile
      log.info("  Compile [faninit-$target]")
      opts := ["-Wall", "-Wextra", "-O2","-o", "$dest.osPath" ]
      src  := (scriptDir + `src/`).listFiles.map |f| { "src/$f.name" }
      proc := Process([tc.gcc.osPath].addAll(opts).addAll(src))
      proc.dir = scriptDir
      if (proc.run.join != 0) throw fatal("gcc failed")

      // indicate dest dir
      log.info("  Write [$dest.osPath]")
    }
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
}

**
** Toolchain spec
**
const class Toolchain
{
  new make(Str n, Str v)
  {
    this.name = n
    this.version = Version(v)
    // TODO: bbb/rpi3 version is not consisent with URI...
    this.dir = Env.cur.workDir + `toolchains/nerves-${name}-v0.6.0/` //${version}/`
    this.gcc = dir + `bin/` + (name.split('-')[0..3].join("-") + "-gcc").toUri
  }
  const Str name
  const Version version
  const File dir
  const File gcc
}