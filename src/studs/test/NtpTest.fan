//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Sep 2016  Andy Frank  Creation
//

using inet

class NtpTest : Test
{
  Void testSntp()
  {
    offset := SntpClient.offset(IpAddr("time1.google.com"))

    // assume test host is relatively accurate :)
    verify(offset > -100ms && offset < 100ms)
  }

  Void testNtpTimestamps()
  {
    // TODO: be nice to find test cases in other impl to validate against

    t1 := DateTime("2016-09-12T19:50:00Z UTC")
    t2 := DateTime("2016-09-12T19:50:00.25Z UTC")
    t3 := DateTime("2016-09-12T19:50:00.5Z UTC")
    t4 := DateTime("2016-09-12T19:50:00.75Z UTC")

    verifyEq(SntpClient.toNtp(t1), 0xdb818568_00000000)
    verifyEq(SntpClient.toNtp(t2), 0xdb818568_40000000)
    verifyEq(SntpClient.toNtp(t3), 0xdb818568_80000000)
    verifyEq(SntpClient.toNtp(t4), 0xdb818568_c0000000)

    verifyEq(SntpClient.fromNtp(0xdb818568_00000000), t1)
    verifyEq(SntpClient.fromNtp(0xdb818568_40000000), t2)
    verifyEq(SntpClient.fromNtp(0xdb818568_80000000), t3)
    verifyEq(SntpClient.fromNtp(0xdb818568_c0000000), t4)
  }
}