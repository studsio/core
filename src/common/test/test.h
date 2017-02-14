/*
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
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
