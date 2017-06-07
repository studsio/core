//
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   6 Jun 2017  Andy Frank  Creation
//

package fan.studs;

public class LibFanPeer
{
  static
  {
    System.load("/usr/lib/libfan.so");
  }

  public static native long doReloadResolvConf();
}