//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Sep 2016  Andy Frank  Creation
//

using inet

**
** SntpClient retrieves network time using SNTP protocol.
**
class SntpClient
{
  **
  ** Request the time offset between the current system clock and
  ** the given NTP host.  Note that NTP requires the requesting
  ** host be within 34 years of the server time.  Therefore if a
  ** system has not had time configured, it should be set a date
  ** close to the present.
  **
  static Duration offset(IpAddr host, Int port := 123, Duration timeout := 10sec)
  {
    UdpSocket? socket := null
    try
    {
      socket = UdpSocket()
      socket.options.receiveTimeout = timeout

      // send request
      req   := Buf(48)
      reqTs := toNtp(DateTime.nowUtc(null))
      req.write(3.shiftl(3).or(3))  // ver=3 | mode=3
      req.write(0)         // stratum
      req.write(0)         // poll
      req.write(0)         // precision
      req.writeI4(0)       // root delay
      req.writeI4(0)       // root dispersion
      req.writeI4(0)       // reference id
      req.writeI8(0)       // reference ts
      req.writeI8(0)       // orig ts
      req.writeI8(0)       // recv ts
      req.writeI8(reqTs)   // transmit time
      packet := UdpPacket(host, port, req.flip)
      socket.send(packet)

      // read response
      res    := socket.receive.data
      destTs := toNtp(DateTime.now(null))
      first     := res.seek(0).read
      leapInd   := first.shiftl(6).and(0x03)
      mode      := first.and(0x07)
      stratum   := res.read
      poll      := res.read
      prec      := res.read
      rootDelay := res.readU4
      rootDisp  := res.readU4
      refId     := res.readU4
      refTs     := res.readS8
      origTs    := res.readS8
      rxTs      := res.readS8
      txTs      := res.readS8

      // sanity checks per RFC 4330 - Section 5/6

      // verify response mode server=4 or broadcast=5
      if (mode != 4 && mode != 5) throw Err("Unsupported mode response: $mode")

      // server not synchronized
      if (stratum == 0) throw Err("Server not synchronized: ${toRefCode(refId)}")
      if (leapInd == 3) throw Err("Server not synchronized")
      if (refTs == 0 || origTs == 0 || rxTs == 0) throw Err("Server not synchronized")

      // verify bounds
      if (stratum > 15) throw Err("Unsupported stratum: $stratum")
      if (reqTs != origTs) throw Err("Request timestamp ($reqTs) != Originate timestamp ($origTs)")

      delay  := (destTs - origTs) - (txTs - rxTs)
      offset := ((rxTs - origTs) + (txTs - destTs)) / 2
      return Duration(offset)
    }
    finally { socket?.close }
  }

  ** Get reference code from reference id.
  private static Str toRefCode(Int refId)
  {
    a := refId.shiftr(24).and(0x0ff)
    b := refId.shiftr(16).and(0x0ff)
    c := refId.shiftr(8).and(0x0ff)
    d := refId.and(0x0ff)

    buf := StrBuf()
    if (a != 0) buf.addChar(a)
    if (b != 0) buf.addChar(b)
    if (c != 0) buf.addChar(c)
    if (d != 0) buf.addChar(d)
    return buf.toStr
  }

  **
  ** Convert a DateTime instance to NTP timestamp, where time is
  ** represented with a 64-bit field as seconds since midnight
  ** Jan 1, 1900:
  **
  **   Bits 00-31: seconds
  **   Bits 32-63: seconds fraction (in picoseconds)
  **
  internal static Int toNtp(DateTime ts)
  {
    ns   := ts.ticks
    sec  := ns / nsInSec
    frac := (ns % nsInSec) * 0x100_000_000 / nsInSec
    return (sec + ntpEpoch).shiftl(32).or(frac)
  }

  **
  ** Convert NTP timestamp back to a DateTime instance.
  ** See `toNtp` for conversion notes.
  **
  internal static DateTime fromNtp(Int ntp, TimeZone tz := TimeZone.cur)
  {
    sec  := ntp.shiftr(32).and(0xffff_ffff) - ntpEpoch
    frac := ntp.and(0xffff_ffff) * nsInSec / 0x100_000_000
    ns   := (sec * nsInSec) + frac
    return DateTime.makeTicks(ns, tz)
  }

  // secs between NTP/Fan epochs 1/1/1900..1/1/20000
  private static const Int ntpEpoch := 36524 * 1day.toSec

  // ns in 1sec
  private static const Int nsInSec := 1_000_000_000
}