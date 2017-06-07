/*
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    6 Jun 2017  Andy Frank  Creation
*/

#include "jni.h"
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/nameser.h>
#include <resolv.h>

/*
 * Flag resolver to reload /etc/resolv.conf
 */
JNIEXPORT jlong JNICALL Java_fan_studs_LibFanPeer_doReloadResolvConf(JNIEnv *env, jclass cls)
{
  return res_init();
}