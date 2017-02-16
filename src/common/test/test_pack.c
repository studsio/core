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
  struct pack_entry *p;
  uint8_t *buf;

  // bad magic
  uint8_t bad_magic[] = { 0, 5, 8 };
  p = pack_decode(bad_magic);
  verify(p == NULL);

  // a:true
  uint8_t a[] = { 0x70, 0x6b, 0x00, 0x04,
                  0x01, 0x61, 0x10, 0x01 };

  p = pack_decode(a);
  verify(pack_has(p, "a"));
  verify(pack_getb(p, "a"));

  verify_int(pack_geti(p, "a"), 0);

  buf = pack_encode(p);
  verify_buf(buf, a);

  // b:5
  uint8_t b[] = { 0x70, 0x6b, 0x00, 0x0b,
                  0x01, 0x62, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x05 };

  p = pack_decode(b);
  verify(pack_has(p, "b"));
  verify_int(pack_geti(p, "b"), 5);

  verify(!pack_has(p, "bc"));
  verify(!pack_has(p, "c"));
  verify(!pack_has(p, "x"));
  verify_int(pack_geti(p, "x"), 0);
  verify(!pack_getb(p, "b"));

  buf = pack_encode(p);
  verify_buf(buf, b);

  // d:"foo"
  uint8_t d[] = { 0x70, 0x6b, 0x00, 0x08,
                  0x01, 0x64, 0x40, 0x00, 0x03, 0x66, 0x6f, 0x6f };

  p = pack_decode(d);
  verify(pack_has(p, "d"));
  verify_str(pack_gets(p, "d"), "foo");
  verify_str(pack_gets(p, "x"), NULL);

  buf = pack_encode(p);
  verify_buf(buf, d);

  // b:true, i:1000, s:"cool"
  uint8_t m[] = { 0x70, 0x6b, 0x00, 0x18,
                  0x01, 0x62, 0x10, 0x01,
                  0x01, 0x69, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xe8,
                  0x01, 0x73, 0x40, 0x00, 0x04, 0x63, 0x6f, 0x6f, 0x6c };

  p = pack_decode(m);
  verify(pack_has(p, "b"));
  verify(pack_has(p, "i"));
  verify(pack_has(p, "s"));
  verify(pack_getb(p, "b"));
  verify_int(pack_geti(p, "i"), 1000);
  verify_str(pack_gets(p, "s"), "cool");

  buf = pack_encode(p);
  verify_buf(buf, m);
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