//
// Copyright (c) 2020, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   2 Jun 2020  Andy Frank  Creation
//

using web

**
** Release image information.
**
const class RelCmd : Cmd
{
  override const Str name := "rel"
  override const Str sig  := "[options]*"
  override const Str helpShort := "Show release image informationm"
  override const Str? helpFull :=
    "Display information about built releasess.

     --md5  Display md5 hash of firmware files"

  override Int run()
  {
    relDir := Env.cur.workDir + `studs/releases/`
    rels   := relDir.listFiles.findAll |f| { f.ext == "fw" }

    // sort files
    sortFwFiles(rels)

    // bail if no releases found
    if (rels.isEmpty) abort("no releases found")

    // list release infos
    echo("Releases:")
    if (opts.contains("md5")) listMd5(rels)
    else listNormal(rels)

    return 0
  }

  private Void listNormal(File[] rels)
  {
    w := rels.map |f| { f.name.size }.max
    rels.each |f,i|
    {
      size := f.size.toLocale("B")
      date := f.modified.date == Date.today
        ? "Today     " + f.modified.toLocale("k::mmaa")
        : f.modified.toLocale("DD-MMM-YY k::mmaa")
      echo("  " + f.name.padr(w) + "   $size  $date")
    }
  }

  private Void listMd5(File[] rels)
  {
    w := rels.map |f| { f.name.size }.max
    rels.each |f,i|
    {
      md5 := f.readAllBuf.toDigest("MD5").toHex
      echo("  " + f.name.padr(w) + "   $md5")
    }
  }
}