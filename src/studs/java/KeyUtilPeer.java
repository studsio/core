//
// Copyright (c) 2019, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   13 Nov 2017  Andy Frank  Creation
//

package fan.studs;

import fan.sys.File;
import java.io.*;
import java.nio.file.*;
import java.nio.charset.*;
import java.security.*;
import java.security.cert.*;
import java.security.spec.*;
import javax.xml.bind.*;

import static fan.studs.EncodingUtils.base64Decode;

public class KeyUtilPeer
{

//////////////////////////////////////////////////////////////////////////
// Peer Impl
//////////////////////////////////////////////////////////////////////////

  public static Object keyStore(File certFile, File keyFile)
    throws Exception
  {
    X509Certificate cert = loadCert(certFile);
    PrivateKey key = loadKey(keyFile.osPath());

    KeyStore ks = KeyStore.getInstance("JKS");
    ks.load(null, null);
    ks.setKeyEntry("key", key, new char[] {}, new X509Certificate[] { cert, });
    return ks;
  }

//////////////////////////////////////////////////////////////////////////
// X509 Utils
//////////////////////////////////////////////////////////////////////////

  private static X509Certificate loadCert(File file)
    throws CertificateException, IOException
  {
    byte[] pemBytes = Files.readAllBytes(Paths.get(file.osPath()));

    String data = new String(pemBytes);
    String[] tokens = data.split(X509_PEM_HEADER);
    tokens = tokens[1].split(X509_PEM_FOOTER);
    byte[] certBytes = DatatypeConverter.parseBase64Binary(tokens[0]);

    CertificateFactory factory = CertificateFactory.getInstance("X.509");
    return (X509Certificate)factory.generateCertificate(new ByteArrayInputStream(certBytes));
  }

  private static final String X509_PEM_HEADER = "-----BEGIN CERTIFICATE-----";
  private static final String X509_PEM_FOOTER = "-----END CERTIFICATE-----";

//////////////////////////////////////////////////////////////////////////
// PCKS Utils
//////////////////////////////////////////////////////////////////////////

  /*
   * Read an _unencrypted_ RSA key encoded in the following formats:
   *
   *   - PKCS#1 PEM (-----BEGIN RSA PRIVATE KEY-----)
   *   - PKCS#8 PEM (-----BEGIN PRIVATE KEY-----)
   *   - PKCS#8 DER (binary)
   */
  private static PrivateKey loadKey(String keyFilePath)
    throws GeneralSecurityException, IOException
  {
    byte[] keyDataBytes = Files.readAllBytes(Paths.get(keyFilePath));
    String keyDataString = new String(keyDataBytes, StandardCharsets.UTF_8);

    if (keyDataString.contains(PKCS_1_PEM_HEADER))
    {
      // OpenSSL / PKCS#1 Base64 PEM encoded file
      keyDataString = keyDataString.replace(PKCS_1_PEM_HEADER, "");
      keyDataString = keyDataString.replace(PKCS_1_PEM_FOOTER, "");
      return readPkcs1PrivateKey(base64Decode(keyDataString));
    }

    if (keyDataString.contains(PKCS_8_PEM_HEADER))
    {
      // PKCS#8 Base64 PEM encoded file
      keyDataString = keyDataString.replace(PKCS_8_PEM_HEADER, "");
      keyDataString = keyDataString.replace(PKCS_8_PEM_FOOTER, "");
      return readPkcs8PrivateKey(base64Decode(keyDataString));
    }

    // We assume it's a PKCS#8 DER encoded binary file
    return readPkcs8PrivateKey(Files.readAllBytes(Paths.get(keyFilePath)));
  }

  private static PrivateKey readPkcs8PrivateKey(byte[] pkcs8Bytes)
    throws GeneralSecurityException
  {
    KeyFactory keyFactory = KeyFactory.getInstance("RSA", "SunRsaSign");
    PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(pkcs8Bytes);
    try {
        return keyFactory.generatePrivate(keySpec);
    } catch (InvalidKeySpecException e) {
        throw new IllegalArgumentException("Unexpected key format!", e);
    }
  }

  private static PrivateKey readPkcs1PrivateKey(byte[] pkcs1Bytes)
    throws GeneralSecurityException
  {
    // We can't use Java internal APIs to parse ASN.1 structures, so we build a PKCS#8 key Java can understand
    int pkcs1Length = pkcs1Bytes.length;
    int totalLength = pkcs1Length + 22;
    byte[] pkcs8Header = new byte[] {
            0x30, (byte) 0x82, (byte) ((totalLength >> 8) & 0xff), (byte) (totalLength & 0xff), // Sequence + total length
            0x2, 0x1, 0x0, // Integer (0)
            0x30, 0xD, 0x6, 0x9, 0x2A, (byte) 0x86, 0x48, (byte) 0x86, (byte) 0xF7, 0xD, 0x1, 0x1, 0x1, 0x5, 0x0, // Sequence: 1.2.840.113549.1.1.1, NULL
            0x4, (byte) 0x82, (byte) ((pkcs1Length >> 8) & 0xff), (byte) (pkcs1Length & 0xff) // Octet string + length
    };
    byte[] pkcs8bytes = join(pkcs8Header, pkcs1Bytes);
    return readPkcs8PrivateKey(pkcs8bytes);
  }

  private static byte[] join(byte[] byteArray1, byte[] byteArray2)
  {
    byte[] bytes = new byte[byteArray1.length + byteArray2.length];
    System.arraycopy(byteArray1, 0, bytes, 0, byteArray1.length);
    System.arraycopy(byteArray2, 0, bytes, byteArray1.length, byteArray2.length);
    return bytes;
  }

  private static final String PKCS_1_PEM_HEADER = "-----BEGIN RSA PRIVATE KEY-----";
  private static final String PKCS_1_PEM_FOOTER = "-----END RSA PRIVATE KEY-----";
  private static final String PKCS_8_PEM_HEADER = "-----BEGIN PRIVATE KEY-----";
  private static final String PKCS_8_PEM_FOOTER = "-----END PRIVATE KEY-----";
}
