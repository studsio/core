//
// Copyright (c) 2019, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   11 Nov 2019  Andy Frank  Creation
//

using web
using studs

class KeyTest : Test
{
  File? cacert
  File? cakey
  File? cert
  File? key

  Void testKeyStore()
  {
    genKeys
    ks := KeyUtil.keyStore(cert.readAllBuf, key.readAllBuf)
    verifyNotNull(ks)
  }

  Void testClientTls()
  {
    // verify no cert fails
    verifyErr(IOErr#) { WebClient(`https://client.badssl.com`).getStr }

// TODO: awaiting upstream fantom patch :)
/*
    // now check with cert
    bc := typeof.pod.file(`/res/badssl.com-client.pem`).readAllBuf
    bk := typeof.pod.file(`/res/badssl.com-client.key`).readAllBuf
    ks := KeyUtil.keyStore(bc, bk)
    wc := WebClient(`https://client.badssl.com`)
    wc.tlsContext = KeyUtil.tlsContext(ks)
    wc.getStr
*/
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  ** Generate a CA cert and singed device cert.
  private Void genKeys()
  {
    // create ca
    createCA("ca", tempDir, ["subj":"/CN=Test CA"])
    this.cacert = tempDir + `ca.pem`
    this.cakey  = tempDir + `ca.key`

    // create cert signed by ca
    createCert("cert", tempDir, cacert, cakey, ["subj":"/CN=Test Cert"])
    this.cert = tempDir + `cert.pem`
    this.key  = tempDir + `cert.key`
  }

  ** Create a new CA keypair
  private Void createCA(Str name, File outDir, Str:Str opts := [:])
  {
    subj := opts["subj"] ?: throw ArgErr("Missing 'subj' opt")
    days := opts["days"] ?: "500"
    key  := (outDir + `${name}.key`).osPath
    pem  := (outDir + `${name}.pem`).osPath

    run(["openssl","genrsa","-out","${key}","2048"])
    run(["openssl","req","-x509","-new","-nodes","-key","${key}",
         "-sha256","-subj","${subj}","-days","${days}","-out","${pem}"])
  }

  ** Create a new Cert signed by given CA keypair.
  private Void createCert(Str name, File outDir, File cacert, File cakey, Str:Str opts)
  {
    subj := opts["subj"] ?: throw ArgErr("Missing 'subj' opt")
    ser  := opts["ser"]  ?: "0x" + Uuid.make.toStr.split('-').join
    days := opts["days"] ?: "500"
    key  := (outDir + `${name}.key`).osPath
    csr  := (outDir + `${name}.csr`).osPath
    pem  := (outDir + `${name}.pem`).osPath

    run(["openssl","genrsa","-out","${key}","2048"])
    run(["openssl","req","-new","-key","${key}","-out","${csr}",
         "-subj","${subj}"])
    run(["openssl","x509","-req","-in","${csr}","-CA","${cacert.osPath}",
         "-CAkey","${cakey.osPath}","-set_serial","${ser}","-out","${pem}",
         "-days","${days}","-sha256"])
  }

  ** Return 'true' if given Cert is signed by given CA keypair.
  private Bool isSignedBy(File cert, File cacert)
  {
    try
    {
      run(["openssl","verify","-CAfile","${cacert.osPath}","${cert.osPath}"])
      return true
    }
    catch return false
  }

  private static Void run(Str[] cmd)
  {
    Proc { it.cmd=cmd }.run.waitFor.okOrThrow
  }
}