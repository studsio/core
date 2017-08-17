//
// Copyright (c) 2016, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   25 Aug 2016  Andy Frank  Creation
//

using web

**
** Burn firmware card images.
**
const class BurnCmd : Cmd
{
  override const Str name := "burn"
  override const Str sig  := "[options]*"
  override const Str helpShort := "Burn firmware image to an attached SDCard"
  override const Str? helpFull :=
    "By default, this command detects attached SDCards and then invokes
     fwup to overwrite the contents of the selected SDCard with the new
     image. Data on the SDCard will be lost, so be careful.

      -u --upgrade  Upgrade the application without erasing data partition"

  override Int run()
  {
    relDir := Env.cur.workDir + `studs/releases/`
    rels   := relDir.listFiles.findAll |f| { f.ext == "fw" }

    // bail if no releases found
    if (rels.isEmpty) abort("burn: no releases found")

    // prompt for release selection
    File? rel
    if (rels.size == 1) rel = rels.first
    else
    {
      echo("Available releases:")
      w := rels.map |f| { f.name.size }.max
      rels.each |f,i|
      {
        size := f.size.toLocale("B")
        echo(" [${i+1}] " + f.name.padr(w) + "  ($size)")
      }
      sel := promptChoice("Which release do you want to burn?", 1..rels.size)
      rel = rels[sel-1]
    }

    // attempt to find card devices
    out := Buf()
    Proc.run("fwup --detect", out)
    devs := out.readAllLines
    if (devs.isEmpty) abort("burn: could not auto detect your SD card")

    Str? dev
    if (devs.size == 1)
    {
      list := devs.first.split(',')
      name := list[0]
      size := list[1].toInt.toLocale("B")
      if (!promptYesNo("Use $size memory card found at $name? [Yn] ")) return 1
      dev = name
    }
    else
    {
      echo("Discovered devices:")
      devs.each |d,i|
      {
        list := d.split(',')
        name := list[0]
        size := list[1].toInt.toLocale("B")
        echo(" [${i+1}] $name ($size)")
      }
      sel := promptChoice("Which device do you want to burn to?", 1..devs.size)
      dev = devs[sel-1].split(',').first
    }

    // check for upgrade
    task := "complete"
    if (opts.contains("u") || opts.contains("upgrade")) task = "upgrade"

    // burn it
    info("Burning $rel.name to ${dev} [$task]...")
    Proc.run("fwup -a -i $rel.osPath -t $task -d $dev", Env.cur.out)
    return 0
  }
}