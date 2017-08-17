/*
// Copyright (c) 2017, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   14 Feb 2017  Andy Frank  Creation
*/

#include <stdarg.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

void fail(const char *fmt, ...)
{
  fprintf(stdout, "TEST FAILED: ");
  va_list ap;
  va_start(ap, fmt);
  vfprintf(stdout, fmt, ap);
  va_end(ap);
  fprintf(stdout, "\n*** TEST FAILED ***\n");
  exit(1);
}

void verify(int v)
{
  if (!v) fail("verify failed");
}

void verify_int(int64_t test, int64_t expected)
{
  if (test != expected) fail("%lld != %lld", test, expected);
}

void verify_float(double test, double expected)
{
  if (test != expected) fail("%f != %f", test, expected);
}

void verify_str(char *test, char *expected)
{
  if (test == NULL)
  {
    if (expected == NULL) return;
    fail("NULL != %s", expected);
  }

  if (expected == NULL)
  {
    if (test == NULL) return;
    fail("%s != NULL", test);
  }

  if (strcmp(test, expected) != 0) fail("%s != %s", test, expected);
}

void verify_buf(uint8_t *test, uint8_t *expected, int len)
{
  // int tlen = sizeof(test) / sizeof(test[0]);
  // int xlen = sizeof(expected) / sizeof(expected[0]);
  // if (tlen != xlen) fail("buf length %d != %d", tlen, xlen);
  // for (int i=0; i<tlen; i++)
  for (int i=0; i<len; i++)
    if (test[i] != expected[i])
      fail("buf[%d] %d != %d", i, test[i], expected[i]);
}
