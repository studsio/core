//
// Copyright (c) 2017, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   27 Jan 2017  Andy Frank  Creation
//

**
** LibFan provides access to the native libfan library.
**
@NoDoc class LibFan
{
  ** Reload /etc/resolv.conf for this process.
  static Void reloadResolvConf()
  {
    if (doReloadResolvConf != 0)
      throw IOErr("reloadResolvConf failed")
  }

  private static native Int doReloadResolvConf()
}