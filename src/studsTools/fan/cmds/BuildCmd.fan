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
    dir := Env.cur.workDir + `studs/`
    dir.create
// TODO FIXIT: actually verify - maybe check nerves-system.tag?
    if ((dir + `$sys.name/`).exists) return

    // download
    temp := dir + `$sys.uri.name`
    fout := temp.out
    c := WebClient(sys.uri)
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
        out.print("\rDownloading $sys.name system... ${per}%\r")
      }

      out.printLine("")
    }
    finally { c.close; fout.close }

    // untar
    out.printLine("Install $sys.name system...")
    if (!Proc.run("tar xvf $temp.osPath -C $dir.osPath"))
      abort("tar failed: $temp.osPath")

    // rename nerves_system_xxx -> xxx
    (dir + `nerves_system_${sys.name}/`).rename(sys.name)

    // cleanup
    temp.delete
  }
}