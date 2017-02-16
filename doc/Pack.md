# Pack

Pack is a binary encoding for name-value pair data structures, and is the
primary mechanism used for exchanging data between Fantom and C daemons in
Studs.

## Fantom Usage

[fan_map]: http://fantom.org/doc/sys/Map
[fan_buf]: http://fantom.org/doc/sys/Buf

Pack encodes/decodes between Fantom [Map][fan_map] and [Buf][fan_buf] types.
The supported primitive value types for Pack maps are:

  - Bool
  - Int
  - Str

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

TODO

## Spec

TODO