//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Aug 2016  Andy Frank  Creation
//

class Main
{
  ** Convenience to invoke 'studsTools::Main'.
  static Int main()
  {
    Method m := Slot.find("studsTools::Main.main")
    return m.call
  }
}