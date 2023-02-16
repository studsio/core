//
// Copyright (c) 2023, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   15 Feb 2023  Andy Frank  Creation
//

using concurrent

**
** Collects operating system-level messages from `/proc/kmsg`,
** and forwards them to `SysLog` with an appropriate level to
** match the syslog priority parsed out of the message.
**
// TODO FIXIT: this probably gets folding to `Logd` daemon along with `Syslog`
@NoDoc /*internal*/ const class Kmsg
{
  ** Private ctor.
  /*private*/ new make()
  {
    this.actor.send("start")
  }

  // TODO
  // ** Close this port.
  // Void close()
  // {
  //   if (proc == null) return
  //   try
  //   {
  //     // any input will force exit
  //     proc.out.print("close").flush
  //     proc.waitFor
  //     proc = null
  //   }
  //   catch (Err err) { throw IOErr("Kmsg.close failed", err) }
  // }

  // private Proc? proc := null

  private const Log log := Log("kmsg", false) { it.level=LogLevel.debug }
  private const ActorPool pool := ActorPool { it.name = "Kmsg" }
  private const Actor actor := Actor(pool) |msg|
  {
    try
    {
      // spawn fankmsg process
      proc := Proc { it.cmd=["/usr/bin/fankmsg"] }
      proc.run.sinkErr
      log.debug("kmsg actor started")

      // block indefinitely
      while (true) //proc != null)
      {
        line := proc.in.readLine
        rec  := parseKmsg(line)
        if (rec != null) log.log(rec)
      }
    }
    catch (Err err) { log.err("kmsg unexpected err", err) }
    return null
  }

  **
  ** Parse a kmsg log line according to:
  ** https://elixir.bootlin.com/linux/latest/source/Documentation/ABI/testing/dev-kmsg
  **
  ** Most messages are of the form:
  **
  **   priority,sequence,timestamp,flag;message
  **
  **   - 'priority' is an integer that when broken apart gives you a facility and severity
  **   - 'sequence' is a monotonically increasing counter
  **   - 'timestamp' is the time in microseconds
  **   - 'flag' is almost always '-'
  **   - 'message' is everything else
  **
  ** Example:
  **
  **     7,160,424069,-;pci_root PNP0A03:00: host bridge window [io  0x0000-0x0cf7] (ignored)
  **      SUBSYSTEM=acpi
  **      DEVICE=+acpi:PNP0A03:00
  **     6,339,5140900,-;NET: Registered protocol family 10
  **     30,340,5690716,-;udevd[80]: starting version 181
  **
  private static LogRec? parseKmsg(Str line)
  {
    try
    {
      // short circuit if no data
      if (line.size == 0) return null

      // TODO: for now we do not support multi-line SUBSYSTEM,DEVICE output
      if (line[0] == ' ') return null

      // parse line
      a   := line.split(';')
      b   := a[0].split(',')
      msg := a[1]
      // ts appears to be ticks since boot which is not helpful when
      // trying to compare log timing; so fudge and use our time
      // ts  := DateTime.makeTicks(b[2].toInt * 1ms.ticks)
      ts  := DateTime.now(null)
      return LogRec(ts, LogLevel.debug, "kmsg", msg)
    }
    catch (Err err)
    {
      // ignore if message could not be parsed
      return null
    }
  }
}