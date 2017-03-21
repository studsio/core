/*
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Jan 2017  Andy Frank  Creation
*/

#include <stdio.h>
#include "test.h"
#include "../src/pack.h"

//////////////////////////////////////////////////////////////////////////
// test_basics
//////////////////////////////////////////////////////////////////////////

void test_basics()
{
  struct pack_map *map;
  uint8_t *buf;

  // test new
  map = pack_map_new();
  verify(map != NULL);
  verify(map->head == NULL);
  verify(map->tail == NULL);
  verify_int(map->size, 0);

  verify(!pack_has(map, "b"));
  verify(!pack_has(map, "i"));
  verify(!pack_has(map, "s"));

  // test setb/getb
  pack_set_bool(map, "b", true);
  verify(pack_has(map, "b"));
  verify_int(map->size, 1);
  verify(pack_get_bool(map, "b"));

  // test seti/geti
  pack_set_int(map, "i", 5);
  verify(pack_has(map, "i"));
  verify_int(map->size, 2);
  verify_int(pack_get_int(map, "i"), 5);

  // test sets/gets
  pack_set_str(map, "s", "foo");
  verify(pack_has(map, "s"));
  verify_int(map->size, 3);
  verify_str(pack_get_str(map, "s"), "foo");

  // test setd/getd
  uint8_t d[] = { 0xde, 0xad, 0xbe, 0xef };
  pack_set_buf(map, "d", d, 4);
  verify(pack_has(map, "d"));
  verify_int(map->size, 4);
  verify_buf(pack_get_buf(map, "d"), d, 4);

  // test encode/decode
  uint8_t enc[] = { 0x70, 0x6b, 0x00, 0x20,
                    0x01, 0x62, 0x10, 0x01,
                    0x01, 0x69, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x05,
                    0x01, 0x73, 0x40, 0x00, 0x03, 0x66, 0x6f, 0x6f,
                    0x01, 0x64, 0x50, 0x00, 0x04, 0xde, 0xad, 0xbe, 0xef };

  buf = pack_encode(map);
  verify_buf(buf, enc, sizeof(enc));

  map = pack_decode(enc);
  verify(pack_has(map, "b"));
  verify(pack_has(map, "i"));
  verify(pack_has(map, "s"));
  verify(pack_has(map, "d"));
  verify(pack_get_bool(map, "b"));
  verify_int(pack_get_int(map, "i"), 5);
  verify_str(pack_get_str(map, "s"), "foo");
  verify_buf(pack_get_buf(map, "d"), d, 4);

  // free
  pack_map_free(map);
  free(buf);
}

//////////////////////////////////////////////////////////////////////////
// test_bufs
//////////////////////////////////////////////////////////////////////////

void test_bufs_empty()
{
  struct pack_map *map;
  uint8_t *buf;
  uint8_t empty_buf[0] = {};

  // test new
  map = pack_map_new();
  pack_set_buf(map, "empty", empty_buf, 0);
  verify(pack_has(map, "empty"));
  verify_int(map->size, 1);
  verify_buf(pack_get_buf(map, "empty"), empty_buf, 0);

  // test encode/decode
  uint8_t enc[] = { 0x70, 0x6b, 0x00, 0x09,
                    0x05, 0x65, 0x6d, 0x70, 0x74, 0x79,
                    0x50, 0x00, 0x00 };
  buf = pack_encode(map);
  verify_buf(buf, enc, sizeof(enc));

  // free
  pack_map_free(map);
  free(buf);
}

void test_bufs_big()
{
  struct pack_map *map;
  uint8_t *buf;
  uint8_t big[] = {
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,

    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,

    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,

    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,

    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
  };

  // test new
  map = pack_map_new();
  pack_set_buf(map, "big", big, 320);
  verify(pack_has(map, "big"));
  verify_int(map->size, 1);
  verify_buf(pack_get_buf(map, "big"), big, 320);

  // test encode/decode
  uint8_t enc_prefix[] = { 0x70, 0x6b, 0x01, 0x47,
                           0x03, 0x62, 0x69, 0x67,
                           0x50, 0x01, 0x40 };
  uint8_t *enc = (uint8_t *)malloc(11+320);
  memcpy(enc,    enc_prefix, 11);
  memcpy(enc+11, big,        320);
  buf = pack_encode(map);
  verify_buf(buf, enc, sizeof(enc));
  free(buf);

  // write
  FILE *f = fopen("test/test.tmp", "w");
  pack_write(f, map);
  fclose(f);

  // read_fully
  struct pack_buf *b = pack_buf_new();
  f = fopen("test/test.tmp", "r");
  if (pack_read_fully(f, b) != 0) fail("pack_read failed");
  fclose(f);
  struct pack_map *test = pack_decode(b->bytes);
  verify(pack_has(test, "big"));
  buf = pack_get_buf(test, "big");
  verify_buf(buf, big, sizeof(big));

  // free
  pack_map_free(map);
  pack_map_free(test);
  pack_buf_free(b);
  free(enc);
  free(buf);
}

//////////////////////////////////////////////////////////////////////////
// test_maps
//////////////////////////////////////////////////////////////////////////

void test_maps()
{
  struct pack_map *map = pack_map_new();

  struct pack_map *a = pack_map_new();
  pack_set_bool(a, "x", true);
  pack_set_int(a, "y", 12);
  pack_set_str(a, "z", "foo");
  pack_set_map(map, "a", a);

  verify_int(map->size, 1);
  verify(    pack_get_bool(pack_get_map(map, "a"), "x") == true);
  verify_int(pack_get_int(pack_get_map(map, "a"), "y"), 12);
  verify_str(pack_get_str(pack_get_map(map, "a"), "z"), "foo");

  uint8_t enc[] = { 0x70, 0x6b, 0x00, 0x1c,
                    0x01, 0x61, 0x70, 0x00, 0x03,
                    0x01, 0x78, 0x10, 0x01,
                    0x01, 0x79, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0c,
                    0x01, 0x7a, 0x40, 0x00, 0x03, 0x66, 0x6f, 0x6f };

  uint8_t *buf = pack_encode(map);
  verify_buf(buf, enc, sizeof(enc));

  pack_map_free(map);
  free(buf);
}

//////////////////////////////////////////////////////////////////////////
// test_debug
//////////////////////////////////////////////////////////////////////////

void test_debug()
{
  struct pack_map *a = pack_map_new();
  pack_set_bool(a, "x", true);
  pack_set_int(a, "y", 12);
  pack_set_str(a, "z", "foo");
  verify_str(pack_debug(a), "[x:1, y:12, z:foo]");

  struct pack_map *b = pack_map_new();
  pack_set_map(b, "m", a);
  verify_str(pack_debug(b), "[m:[x:1, y:12, z:foo]]");

  pack_map_free(b); // will free a
}

//////////////////////////////////////////////////////////////////////////
// test_io
//////////////////////////////////////////////////////////////////////////

void test_io()
{
  struct pack_map *m = pack_map_new();
  pack_set_bool(m, "b", true);
  pack_set_int(m, "i", 5);
  pack_set_str(m, "s", "foo");

  // write
  FILE *f = fopen("test/test.tmp", "w");
  pack_write(f, m);
  fclose(f);

  // read
  struct pack_buf *b = pack_buf_new();
  f = fopen("test/test.tmp", "r");
  while (!b->ready)
    if (pack_read(f, b) != 0) fail("pack_read failed");
  fclose(f);
  struct pack_map *test = pack_decode(b->bytes);
  verify(pack_get_bool(test, "b"));
  verify_int(pack_get_int(test, "i"), 5);
  verify_str(pack_get_str(test, "s"), "foo");

  // read_fully
  pack_buf_clear(b);
  f = fopen("test/test.tmp", "r");
  if (pack_read_fully(f, b) != 0) fail("pack_read failed");
  fclose(f);
  test = pack_decode(b->bytes);
  verify(pack_get_bool(test, "b"));
  verify_int(pack_get_int(test, "i"), 5);
  verify_str(pack_get_str(test, "s"), "foo");
}

//////////////////////////////////////////////////////////////////////////
// main
//////////////////////////////////////////////////////////////////////////

int main()
{
  test_basics();
  test_bufs_empty();
  test_bufs_big();
  test_maps();
  // TODO: test_bool
  // TODO: test_int
  // TODO: test_str
  // TODO: test_names
  test_debug();
  test_io();
  printf("TEST PASSED\n");
  return 0;
}