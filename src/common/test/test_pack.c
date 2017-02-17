/*
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Jan 2017  Andy Frank  Creation
*/

#include "test.h"
#include "../src/pack.h"

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

int main()
{
  test_basics();
  // TODO: test_bool
  // TODO: test_int
  // TODO: test_str
  // TODO: test_names
  printf("TEST PASSED\n");
  return 0;
}