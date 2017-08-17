/*
// Copyright (c) 2017, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   28 Jan 2017  Andy Frank  Creation
*/

#ifndef PACK_H
#define PACK_H

#include <stdbool.h>
#include <stdint.h>

#define PACK_TYPE_BOOL   0x10
#define PACK_TYPE_INT    0x20
#define PACK_TYPE_STR    0x40
#define PACK_TYPE_BUF    0x50
#define PACK_TYPE_LIST   0x60
#define PACK_TYPE_MAP    0x70

#define PACK_BUF_SIZE    65536

union pack_val {
  bool b;
  int64_t i;
  char *s;
  uint8_t *d;
  struct pack_map *m;
};

struct pack_entry {
  char *name;
  uint8_t type;
  union pack_val val;
  uint16_t vlen;
  struct pack_entry *next;
};

struct pack_map {
  struct pack_entry *head;
  struct pack_entry *tail;
  uint16_t size;
};

struct pack_buf {
  uint8_t bytes[PACK_BUF_SIZE];
  ssize_t pos;
  bool ready;
};

struct pack_map* pack_map_new();
void pack_map_free(struct pack_map *map);

char* pack_debug(struct pack_map *map);

bool pack_has(struct pack_map *map, char *name);
bool pack_get_bool(struct pack_map *map, char *name);
int64_t pack_get_int(struct pack_map *map, char *name);
char* pack_get_str(struct pack_map *map, char *name);
uint8_t* pack_get_buf(struct pack_map *map, char *name);
struct pack_map* pack_get_map(struct pack_map *map, char *name);

void pack_set_bool(struct pack_map *map, char *name, bool val);
void pack_set_int(struct pack_map *map, char *name, int64_t val);
void pack_set_str(struct pack_map *map, char *name, char *val);
void pack_set_buf(struct pack_map *map, char *name, uint8_t *val, uint16_t len);
void pack_set_map(struct pack_map *map, char *name, struct pack_map *val);

uint8_t* pack_encode(struct pack_map *map);
struct pack_map* pack_decode(uint8_t *buf);

struct pack_buf* pack_buf_new();
void pack_buf_free(struct pack_buf* buf);
void pack_buf_clear(struct pack_buf* buf);

int pack_read_fully(FILE *f, struct pack_buf *buf);
int pack_read(FILE *f, struct pack_buf *buf);
int pack_write(FILE *f, struct pack_map *map);

#endif