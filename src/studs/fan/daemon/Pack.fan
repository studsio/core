//
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jan 2017  Andy Frank  Creation
//

**
** Pack is a binary encoding for name-value pairs.
**
class Pack
{
  ** Enode map into a Pack byte buffer.
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
      encodeVal(v, buf)
    }

    // TODO: check len > 0xffff

    // backpatch len
    buf.seek(2)
    buf.writeI2(buf.size-4)
    return buf.seek(0)
  }

  ** Decode Pack byte buffer into map instance.
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
      map[name] = decodeVal(buf)
    }

    return map
  }

  private static Void encodeVal(Obj v, Buf buf)
  {
    // encode value
    switch (v.typeof)
    {
      case Bool#:
        buf.write(tcBool).write(v == false ? 0x00 : 0x01)

      case Int#:
        buf.write(tcInt).writeI8(v)

      case Str#:
        // charset checking?
        s := (Str)v
        if (s.size > 0xffff) throw ArgErr("Value string length > 65536")
        buf.write(tcStr).writeI2(s.size).print(s)

      case Obj[]#:
        list := (Obj[])v
        if (list.size > 0xffff) throw ArgErr("List size > 65536")
        buf.write(tcList).writeI2(list.size)
        list.each |i| { encodeVal(i, buf) }

      default: throw ArgErr("Unsupported value type: $v [$v.typeof]")
    }
  }

  private static Obj decodeVal(Buf buf)
  {
    tc := buf.read
    switch (tc)
    {
      case tcBool:
        return buf.read != 0

      case tcInt:
        return buf.readS8

      case tcStr:
        slen := buf.readU2
        return buf.readChars(slen)

      case tcList:
        list := Obj[,]
        llen := buf.readU2
        llen.times { list.add(decodeVal(buf)) }
        return list.toImmutable

      default: throw IOErr("Unknown type code: 0x$tc.toHex")
    }
  }

  // magic number 'pk'
  static const Int magic := 0x706b

  // type codes
  static const Int tcBool := 0x10
  static const Int tcInt  := 0x20
  static const Int tcStr  := 0x40
  static const Int tcList := 0x50
  static const Int tcMap  := 0x60
}
