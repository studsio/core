//
// Copyright (c) 2019, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   11 Nov 2019  Andy Frank  Creation
//

using crypto
using inet
using studs
using web

class KeyTest : Test
{
  File? cacert
  File? cakey
  File? cert
  File? key

  Void testKeyStore()
  {
    genKeys

    // Deprecated - use Crypto API
    // ks := KeyUtil.keyStore(cert.readAllBuf, key.readAllBuf)
    // verifyNotNull(ks)

    cert := Crypto.cur.loadPem(cert.in)
    key  := Crypto.cur.loadPem(key.in)
    ks   := Crypto.cur.loadKeyStore.setPrivKey("", key, [cert])
    verifyNotNull(ks)
  }

  Void testClientTls()
  {
    //
    // NOTE: Test certs expire 11/26/2021
    // To update key/pem for tests:
    //  - Download client certs from badssl.com in PEM format
    //  - Split into key/cert (password is 'badssl.com'):
    //     openssl rsa -in badssl.com-client.pem -out x.key -outform PEM
    //     copy-paste cert portion into x.pem certfile
    //

    WebClient? wc

    // verify no cert fails
    verifyErr(IOErr#) { WebClient(`https://client.badssl.com`).getStr }

    // sanity check 'cert-missing'
    wc = WebClient(`https://client-cert-missing.badssl.com`)
    wc.writeReq
    wc.readRes
    verifyEq(wc.resCode, 400)
    verifyTrue(wc.resIn.readAllStr.contains("No required SSL certificate was sent"))

    // verify no cert sent 400
    wc = WebClient(`https://client.badssl.com`)
    wc.writeReq
    wc.readRes
    verifyEq(wc.resCode, 400)

    // verify success with cert
    bc := Crypto.cur.loadPem(typeof.pod.file(`/res/badssl.com-client.pem`).in)
    bk := Crypto.cur.loadPem(typeof.pod.file(`/res/badssl.com-client.key`).in)
    // Deprecated - use Crypto API
    //   ks := KeyUtil.keyStore(bc, bk)
    sc := SocketConfig {
      it.keystore = Crypto.cur.loadKeyStore.setPrivKey("client", bk, [bc])
    }
    wc = WebClient(`https://client.badssl.com`)
    // Deprecated - use Crypto API
    //   wc.tlsContext = KeyUtil.tlsContext(ks)
    wc.socketConfig = sc
    wc.writeReq
    wc.readRes
    verifyEq(wc.resCode, 200)
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