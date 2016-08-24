//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Aug 2016  Andy Frank  Creation
//

**
** Utilities for running and working with native processes.
**
const class Proc
{
  ** Invoke the command string and return 'true' if exited
  ** normally or 'false' if returned with error code.
  static Bool run(Str cmd)
  {
    p := Process(cmd.split)
    p.out = null
    return p.run.join == 0
  }
}