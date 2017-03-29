//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Sep 2016  Andy Frank  Creation
//

using concurrent

**
** Ntpd
**
@NoDoc const class Ntpd : Daemon
{
  new make() : super(5sec) {}

  ** NTP server pool.
  const Str[] servers := [
    "0.pool.ntp.org",
    "1.pool.ntp.org",
    "2.pool.ntp.org",
    "3.pool.ntp.org"
  ]

  override Void onStart() { onPoll }

  override Void onStop()
  {
    Proc? p := Actor.locals["p"]
    if (p == null || !p.isRunning) return

    p.kill.waitFor
    Actor.locals["p"] = null
    log.debug("ntpd process stopped")
  }

  override Void onPoll()
  {
    Proc? p := Actor.locals["p"]

    // drain process stdout and check if running
    if (p != null)
    {
      Str? out
      while ((out = p.in.readLine) != null) log.debug(out)
      if (!p.isRunning)
      {
        log.debug("ntpd process terminated with exit code $p.exitCode")
        p = null
      }
    }

    // restart process if not running
    if (p == null)
    {
      cmd := ["/usr/sbin/ntpd", "-n", "-d"]
      cmd.addAll(servers.map |s| { "-p$s" })
      log.debug(cmd.join(" "))

      p = Proc { it.cmd=cmd }
      p.run
      Actor.locals["p"] = p
      log.debug("ntpd process started")
    }
  }
}