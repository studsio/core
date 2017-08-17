//
// Copyright (c) 2016, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   21 Aug 2016  Andy Frank  Creation
//

@NoDoc class Main
{
  ** Convenience to invoke 'studsTools::Main'.
  static Int main()
  {
    Method m := Slot.find("studsTools::Main.main")
    return m.call
  }
}