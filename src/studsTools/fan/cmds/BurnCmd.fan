//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
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
  override const Str helpShort := "Burn firmware card images"
  override const Str? helpFull := "TODO"

  override Int run()
  {
    relDir := Env.cur.workDir + `studs/releases/`
    rels   := relDir.listFiles.findAll |f| { f.ext == "fw" }

    // bail if no releases found
    if (rels.isEmpty) abort("burn: no releases found")

    // TODO FIXIT: prompt to select?
    rel := rels.first
    // TODO: prompt to select which image...

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

    info("Burning $rel.name to ${dev}...")

    // burn it
    task := "complete"
    Proc.run("fwup -a -i $rel.osPath -t $task -d $dev", Env.cur.out)
    return 0
  }
}