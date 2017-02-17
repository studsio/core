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

Additionally Pack map values can be `Obj[]` lists and `Str:Obj` maps of the
above primitives.

    // encode
    map := ["a":true, "b":12, "c":"foo"]
    buf := Pack.encode(map)

    // decode
    map := Pack.decode(buf)

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

Note all integers are 64-bit signed longs for consistency with how integers are
modeled in Fantom.

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

     // maps
     struct pack_map *sub = pack_map_new();
     pack_setb(sub, "foo", true);
     pack_sets(sub, "bar", "cool beans");
     pack_setm(map, "sub", sub);

## Spec

TODO