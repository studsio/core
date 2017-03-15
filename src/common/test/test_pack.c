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
  pack_setb(map, "b", true);
  verify(pack_has(map, "b"));
  verify_int(map->size, 1);
  verify(pack_getb(map, "b"));

  // test seti/geti
  pack_seti(map, "i", 5);
  verify(pack_has(map, "i"));
  verify_int(map->size, 2);
  verify_int(pack_geti(map, "i"), 5);

  // test seti/geti
  pack_sets(map, "s", "foo");
  verify(pack_has(map, "s"));
  verify_int(map->size, 3);
  verify_str(pack_gets(map, "s"), "foo");

  // test encode/decode
  uint8_t enc[] = { 0x70, 0x6b, 0x00, 0x17,
                    0x01, 0x62, 0x10, 0x01,
                    0x01, 0x69, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x05,
                    0x01, 0x73, 0x40, 0x00, 0x03, 0x66, 0x6f, 0x6f };

  buf = pack_encode(map);
  verify_buf(buf, enc);

  map = pack_decode(enc);
  verify(pack_has(map, "b"));
  verify(pack_has(map, "i"));
  verify(pack_has(map, "s"));
  verify(pack_getb(map, "b"));
  verify_int(pack_geti(map, "i"), 5);
  verify_str(pack_gets(map, "s"), "foo");

  // free
  pack_map_free(map);
}

//////////////////////////////////////////////////////////////////////////
// test_maps
//////////////////////////////////////////////////////////////////////////

void test_maps()
{
  struct pack_map *map = pack_map_new();

  struct pack_map *a = pack_map_new();
  pack_setb(a, "x", true);
  pack_seti(a, "y", 12);
  pack_sets(a, "z", "foo");
  pack_setm(map, "a", a);

  verify_int(map->size, 1);
  verify(    pack_getb(pack_getm(map, "a"), "x") == true);
  verify_int(pack_geti(pack_getm(map, "a"), "y"), 12);
  verify_str(pack_gets(pack_getm(map, "a"), "z"), "foo");

  uint8_t enc[] = { 0x70, 0x6b, 0x00, 0x1c,
                    0x01, 0x61, 0x60, 0x00, 0x03,
                    0x01, 0x78, 0x10, 0x01,
                    0x01, 0x79, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0c,
                    0x01, 0x7a, 0x40, 0x00, 0x03, 0x66, 0x6f, 0x6f };

  uint8_t *buf = pack_encode(map);
  verify_buf(buf, enc);

  pack_map_free(map);
}

//////////////////////////////////////////////////////////////////////////
// test_err
//////////////////////////////////////////////////////////////////////////

void test_err()
{
  struct pack_map *map = pack_err("oops");
  verify_int(map->size, 1);
  verify_str(pack_gets(map, "err"), "oops");
}

//////////////////////////////////////////////////////////////////////////
// test_io
//////////////////////////////////////////////////////////////////////////

void test_io()
{
  struct pack_map *m = pack_map_new();
  pack_setb(m, "b", true);
  pack_seti(m, "i", 5);
  pack_sets(m, "s", "foo");

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
  verify(pack_getb(test, "b"));
  verify_int(pack_geti(test, "i"), 5);
  verify_str(pack_gets(test, "s"), "foo");

  // read_fully
  pack_buf_clear(b);
  f = fopen("test/test.tmp", "r");
  if (pack_read_fully(f, b) != 0) fail("pack_read failed");
  fclose(f);
  test = pack_decode(b->bytes);
  verify(pack_getb(test, "b"));
  verify_int(pack_geti(test, "i"), 5);
  verify_str(pack_gets(test, "s"), "foo");
}

//////////////////////////////////////////////////////////////////////////
// main
//////////////////////////////////////////////////////////////////////////

int main()
{
  test_basics();
  test_maps();
  // TODO: test_bool
  // TODO: test_int
  // TODO: test_str
  // TODO: test_names
  test_err();
  test_io();
  printf("TEST PASSED\n");
  return 0;
}