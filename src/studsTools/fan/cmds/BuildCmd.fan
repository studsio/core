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
    // find system uri
// TODO: pull out version info somewhere?
    Uri? uri
    switch (target)
    {
      case "rpi3": uri = `https://github.com/nerves-project/nerves_system_rpi3/releases/download/v0.6.1/nerves_system_rpi3-v0.6.1.tar.gz`
      default: abort("unknown target: $target")
    }

    // short-circuit if already installed
    dir := Env.cur.workDir + `studs/`
    dir.create
// TODO FIXIT: actually verify - maybe check nerves-system.tag?
    if ((dir + `rpi3/`).exists) return

    // download
    temp := dir + `$uri.name`
    fout := temp.out
    c := WebClient(uri)
    try
    {
      c.writeReq.readRes
      len := c.resHeaders["Content-Length"].toInt
      in  := c.resIn
      blk := 4096
      cur := 0
      buf := Buf { it.capacity=blk }
      Int? last

      while ((last = in.readBuf(buf.clear, blk)) != null)
      {
        // pipe to temp file
        fout.writeBuf(buf.flip)

        // update progress
        cur += last
        per := (cur.toFloat / len.toFloat * 100f).toInt.toStr.padl(2)
        out.print("\rDownloading rpi3 system... ${per}%\r")
      }

      out.printLine("")
    }
    finally { c.close; fout.close }

    // untar
    out.printLine("Install rpi3 system...")
    proc := Process(["tar", "xvf", temp.osPath, "-C", dir.osPath])
    proc.out = null
    proc.run.join

    // rename nerves_system_rpi3 -> rpi3
    (dir + `nerves_system_rpi3/`).rename("rpi3")

    // cleanup
    temp.delete
  }
}