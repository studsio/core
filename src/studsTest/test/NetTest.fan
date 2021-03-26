//
// Copyright (c) 2021, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   26 Mar 2021  Andy Frank  Creation
//

using inet
using studs

class NetTest : Test
{
  override Void setup() { n := Networkd() }

  Void testSubnetToMask()
  {
    verifyPrefix("0.0.0.0",         0)
    verifyPrefix("255.0.0.0",       8)
    verifyPrefix("255.255.0.0",     16)
    verifyPrefix("255.255.255.0",   24)
    verifyPrefix("255.255.255.255", 32)

    verifyPrefix("128.0.0.0",       1)
    verifyPrefix("192.0.0.0",       2)
    verifyPrefix("255.128.0.0",     9)
    verifyPrefix("255.255.128.0",   17)

    verifyPrefix("255.255.255.128", 25)
    verifyPrefix("255.255.255.192", 26)
    verifyPrefix("255.255.255.252", 30)
  }

  private Void verifyPrefix(Str subnet, Int prefix)
  {
    p := Networkd.cur->subnetToPrefix(subnet)
    verifyEq(p, prefix)
  }
}