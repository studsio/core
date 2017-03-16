# Pack

Pack is a binary encoding for name-value pair data structures, and is the
primary mechanism used for exchanging data between Fantom and C daemons in
Studs.

## Fantom Usage

[fan_map]: http://fantom.org/doc/sys/Map
[fan_buf]: http://fantom.org/doc/sys/Buf

Pack encodes/decodes between Fantom [Map][fan_map] and [Buf][fan_buf] types.
The supported primitive value types for Pack maps are:

  - `Bool`
  - `Int`
  - `Str`
  - `Buf`

Additionally Pack map values can be `Obj[]` lists and `Str:Obj` maps of the
above primitives.

    // encode
    map := ["a":true, "b":12, "c":"foo"]
    buf := Pack.encode(map)

    // decode
    map := Pack.decode(buf)

    // byte array
    bytes := Buf().write(0x01).write(0x02).write(0x03)
    map := ["data":bytes]

    // list and maps
    map := [
      "a": [1,2,3],
      "b": ["foo":false, "bar":"cool beans"]
    ]

## C Usage

The Pack C library is defined in `pack.h` and models the name/value pairs using
`struct pack_map`.  The primitive value types are stored as:

  - `bool`
  - `int64_t`
  - `char *`
  - `uint8_t *`

Note that the integer val type is a 64-bit signed long for consistency with how
integers are modeled in Fantom.

     // allocate
     struct pack_map *map = pack_map_new();
     pack_map_free(map);

     // setters
     pack_setb(map, "a", true);
     pack_seti(map, "b", 12);
     pack_sets(map, "c", "foo");

     // getters
     bool b = pack_getb(map, "a");
     int64_t i = pack_geti(map, "b");
     char *s = pack_gets(map, "c");

     if (pack_has("foo")) { ... }

     // encode
     uint8_t *buf = pack_encode(map);

     // decode
     struct pack_map *map = pack_decode(buf);

     // byte array
     uint8_t bytes[] = { 0x01, 0x02, 0x03 };
     pack_setd(map, "data", bytes, 3);
     utin8_t *x = pack_getd(map, "data")

     // maps
     struct pack_map *a = pack_map_new();
     pack_setb(a, "foo", true);
     pack_sets(a, "bar", "cool beans");
     pack_setm(map, "a", a);
     struct pack_map *x = pack_getm(map, "a");

### C I/O

Encoded Pack messages can be exchanged using `pack_read` and `pack_write`.
The `pack_read_fully` method is provided as a convenience if you wish to block
until the entire message can be read.

    // write
    FILE *f = fopen("foo.pack", "w");
    pack_write(f, map);
    fclose(f);

    // read
    struct pack_buf *buf = pack_buf_new();
    FILE *f = fopen("foo.pack", "r");
    if (pack_read_fully(f, buf) != 0) { /* read failed */ }
    fclose(f);
    struct pack_map *map = pack_decode(buf->bytes);

Reads are read into a holding buffer using `struct pack_buf`. Once the complete
message has been read, the `ready` field will be set to `true`.  If you wish
to reuse a buffer instance for multiple reads, you must call `pack_buf_clear`
to reset its state after each completed read:

    struct pack_buf *buf = pack_buf_new();
    for (;;)
    {
      if (pack_read(f, buf) != 0) { /* read failed */ }
      if (buf->ready)
      {
        struct pack_map *map = pack_decode(buf->bytes);
        pack_buf_clear(buf);
      }
    }

## Spec

TODO