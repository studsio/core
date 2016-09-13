//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Sep 2016  Andy Frank  Creation
//

**
** Led manages LED state using '/sys/class/leds'.
**
class Led
{
  ** Set the on/off state for given led.
  static Void set(Str name, Bool on)
  {
    write("$name/trigger", "none")
    write("$name/brightness", on ? "1" : "0")
  }

  ** Convenience for 'set(name, true)'.
  static Void on(Str name) { set(name, true) }

  ** Convenience for 'set(name, false)'.
  static Void off(Str name) { set(name, false) }

  ** Blink the given led using the given on/off pattern.
  static Void blink(Str name, Duration onDur, Duration offDur)
  {
    write("$name/trigger",   "timer")
    write("$name/delay_on",  "$onDur.toMillis")
    write("$name/delay_off", "$offDur.toMillis")
  }

  ** Set led trigger to given value.
  static Void trigger(Str name, Str val)
  {
    write("$name/trigger", val)
  }

  ** Write value to given file.
  private static Void write(Str path, Str val)
  {
    file := File(`/sys/class/leds/$path`)

    if (!file.exists)
      throw IOErr("LED not found: " + file.uri.path[3])

    out := file.out
    try out.print(val).flush
    finally out.close
  }
}