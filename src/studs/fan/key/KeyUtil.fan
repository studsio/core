/** Deprecated - Use Crypto API **/
/*
//
// Copyright (c) 2019, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   5 Nov 2019  Andy Frank  Creation
//

**
** KeyUtil
**
const class KeyUtil
{
  ** Return a 'java.security.KeyStore' instance for the given key pair.
  static native Obj keyStore(Buf cert, Buf key)

  ** Create a 'javax.net.ssl.SSLContext' instance using given keystore.
  static native Obj tlsContext(Obj keystore)
}
*/