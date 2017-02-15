/*
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Jan 2017  Andy Frank  Creation
*/

#ifndef PACK_H
#define PACK_H

#include <stdint.h>

#define PACK_TYPE_BOOL   0x10
#define PACK_TYPE_INT    0x20
#define PACK_TYPE_STR    0x40

union pack_uval {
  int64_t i;
  char *s;
};

struct pack_entry {
  char *name;
  uint8_t type;
  union pack_uval val;
  struct pack_entry *next;
};

struct pack_entry * pack_decode(char *buf);
char * pack_encode(struct pack_entry *p);

struct pack_entry * pack_find(struct pack_entry *p, char *name);
int pack_has(struct pack_entry *p, char *name);
int pack_getb(struct pack_entry *p, char *name);
int64_t pack_geti(struct pack_entry *p, char *name);
char * pack_gets(struct pack_entry *p, char *name);

#endif
