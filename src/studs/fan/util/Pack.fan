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

//////////////////////////////////////////////////////////////////////////
// Encode
//////////////////////////////////////////////////////////////////////////

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
      encodeName(n, buf)
      encodeVal(v, buf)
    }

    // sanity size check
    if (buf.size-4 > 0xffff) throw ArgErr("Packet size too big > 65536")

    // backpatch len
    buf.seek(2)
    buf.writeI2(buf.size-4)
    return buf.seek(0)
  }

  private static Void encodeName(Str n, Buf buf)
  {
    nlen := n.size
    if (nlen > 255) throw ArgErr("Name length > 255: $n")
    if (n.any |c| { c < 0x20 || c > 0x7e }) throw ArgErr("Invalid name: $n")
    buf.write(nlen).print(n)
  }

  private static Void encodeVal(Obj v, Buf buf)
  {
    // encode value
    t := v.typeof
    if (t.fits(Buf#)) t = Buf#
    switch (t)
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

      case Buf#:
        b := (Buf)v
        buf.write(tcBuf).writeI2(b.size).writeBuf(b.seek(0))

      case Obj[]#:
        list := (Obj[])v
        if (list.size > 0xffff) throw ArgErr("List size > 65536")
        buf.write(tcList).writeI2(list.size)
        list.each |i| { encodeVal(i, buf) }

      case [Str:Obj]#:
        map := (Str:Obj)v
        if (map.size > 0xffff) throw ArgErr("Map size > 65536")
        buf.write(tcMap).writeI2(map.size)
        map.each |mv, mk|
        {
          encodeName(mk, buf)
          encodeVal(mv, buf)
        }

      default: throw ArgErr("Unsupported value type: $v [$v.typeof]")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Decode
//////////////////////////////////////////////////////////////////////////

  ** Decode Pack byte buffer into map instance.
  static Str:Obj decode(Buf buf)
  {
    m := buf.readU2
    if (m != magic) throw IOErr("Invalid magic number 0x$m.toHex")

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

      case tcBuf:
        blen := buf.readU2
        return buf.readBufFully(null, blen)

      case tcList:
        list := Obj[,]
        llen := buf.readU2
        llen.times { list.add(decodeVal(buf)) }
        return list.toImmutable

      case tcMap:
        map  := Str:Obj[:]
        mlen := buf.readU2
        mlen.times
        {
          nlen := buf.read
          name := buf.readChars(nlen)
          map[name] = decodeVal(buf)
        }
        return map.toImmutable

      default: throw IOErr("Unknown type code: 0x$tc.toHex")
    }
  }

//////////////////////////////////////////////////////////////////////////
// I/O
//////////////////////////////////////////////////////////////////////////

  ** Read a Pack packet from the given 'InStream' and return
  ** the decoded name/value pair map.  Throws IOErr if stream
  ** or encoding error occurs.
  static Str:Obj read(InStream in)
  {
    m := in.readU2
    if (m != magic) throw IOErr("Invalid magic '0x$m.toHex'")
    len := in.readU2
    buf := Buf(len+4)
    buf.writeI2(magic)
    buf.writeI2(len)
    in.readBufFully(buf, len)
    return Pack.decode(buf.seek(0))
  }

  ** Write a Pack packet to given 'OutStream'. Throws 'IOErr'
  ** if write failed.  This method invokes 'out.flush' after
  ** writing packet content.
  static Void write(OutStream out, Str:Obj map)
  {
    buf := Pack.encode(map)
    out.writeBuf(buf).flush
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  // magic number 'pk'
  static const Int magic := 0x706b

  // type codes
  static const Int tcBool := 0x10
  static const Int tcInt  := 0x20
  static const Int tcStr  := 0x40
  static const Int tcBuf  := 0x50
  static const Int tcList := 0x60
  static const Int tcMap  := 0x70
}
