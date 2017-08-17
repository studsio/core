/*
// Copyright (c) 2017, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//    2 Mar 2017  Andy Frank  Creation
*/

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "log.h"

#include <sys/reboot.h>

/*
 * Log message to stderr with 'debug' level.
 */
void log_debug(const char *fmt, ...)
{
  va_list ap;
  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  va_end(ap);
  fprintf(stderr, "\r\n");
}

/*
 * Log message to stderr with 'warn' level.
 */
void log_warn(const char *fmt, ...)
{
  va_list ap;
  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  va_end(ap);
  fprintf(stderr, "\r\n");
}

/*
 * Log message to stderr with 'err' level.
 */
void log_err(const char *fmt, ...)
{
  va_list ap;
  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  va_end(ap);
  fprintf(stderr, "\r\n");
}

/*
 * Log message to stderr with 'err' level then
 * exit with non-zero error coee.
 */
void log_fatal(const char *fmt, ...)
{
  fprintf(stderr, "\r\n\r\n*** FATAL ERROR ***\r\n");
  va_list ap;
  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  va_end(ap);
  fprintf(stderr, "\r\n");
  exit(1);
}
