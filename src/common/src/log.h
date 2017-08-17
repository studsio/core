/*
// Copyright (c) 2017, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//    2 Mar 2017  Andy Frank  Creation
*/

#ifndef LOG_H
#define LOG_H

void log_debug(const char *fmt, ...);
void log_warn(const char *fmt, ...);
void log_err(const char *fmt, ...);
void log_fatal(const char *fmt, ...);

#endif