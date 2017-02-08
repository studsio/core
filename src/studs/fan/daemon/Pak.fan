//
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jan 2017  Andy Frank  Creation
//

**
** Pak is a binary encoding for name-value pairs.
**
class Pak
{
  static Buf encode(Str:Obj map)
  {
    if (map.isEmpty) throw ArgErr("Cannot encode empty map")

    buf := Buf()
    buf.writeI2(magic)  // magic number 'pk'
    buf.writeI2(0)      // placeholder for len

    // encode each name-value pair
    map.each |v,n|
    {
      // validate name
      nlen := n.size
      if (nlen > 255) throw ArgErr("Name length > 255: $n")
      if (n.any |c| { c < 0x20 || c > 0x7e }) throw ArgErr("Invalid name: $n")

      // encode name
      buf.write(nlen)
      buf.print(n)

      // encode value
      switch (v.typeof)
      {
        case Bool#:
          buf.write(tcBool).write(v == false ? 0x00 : 0x01)

        case Int#:
          buf.write(tcInt).writeI8(v)

        case Float#:
          buf.write(tcFloat).writeF8(v)

        case Str#:
          // charset checking?
          s := (Str)v
          if (s.size > 0xffff) throw ArgErr("Value string length > 65536")
          buf.write(tcStr).writeI2(s.size).print(s)

        default: throw ArgErr("Unsupported value type: $v [$v.typeof]")
      }
    }

    // backpatch len
    buf.seek(2)
    buf.writeI2(buf.size-4)
    return buf.seek(0)
  }

  static Str:Obj decode(Buf buf)
  {
    m := buf.readU2
    if (m != magic) throw IOErr("Invalid magic number $m.toHex")

    len   := buf.readU2
    start := buf.pos
    map   := Str:Obj[:]

    while (buf.pos-start < len)
    {
      nlen := buf.read
      name := buf.readChars(nlen)
      code := buf.read
      switch (code)
      {
        case tcBool:
          map[name] = buf.read != 0

        case tcInt:
          map[name] = buf.readS8

        case tcFloat:
          map[name] = buf.readF8

        case tcStr:
          slen := buf.readU2
          map[name] = buf.readChars(slen)

        default: throw IOErr("Unknown type code: 0x$code.toHex")
      }
    }

    return map
  }

  // magic number 'pk'
  static const Int magic := 0x706b

  // type codes
  static const Int tcBool  := 0x10
  static const Int tcInt   := 0x20
  static const Int tcFloat := 0x30
  static const Int tcStr   := 0x40
}
