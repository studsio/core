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

  ** Get the Ntpd instance for this vm.  If an instance is
  ** not found, throw Err if 'checked' otherwise return null.
  static Ntpd? cur(Bool checked := true)
  {
    d := Actor.locals["d.ntpd"]
    if (d == null && checked) throw Err("Ntpd instance not found")
    return d
  }

  ** The current NTP server pool.
  Str[] servers
  {
    get { serversRef.val }
    set { serversRef.val = it.toImmutable }
  }

  ** Block until ntpd acquires a valid time.  If 'timeout' is
  ** 'null' this method blocks indefinietly.  Returns 'true'
  ** time was acquired, or 'false' if timed out.
  Bool sync(Duration? timeout := null)
  {
    // TODO: temp hack -- need to actually check ntpd output

    s := Duration.nowTicks
    t := timeout?.ticks ?: Int.maxVal
    while (DateTime.now(null).year == 2000)
    {
      if (Duration.nowTicks - s >= t) return false
      Actor.sleep(100ms)
    }
    return true
  }

  private const AtomicRef serversRef := AtomicRef(defServers)
  private static const Str[] defServers := [
    "0.pool.ntp.org",
    "1.pool.ntp.org",
    "2.pool.ntp.org",
    "3.pool.ntp.org"
  ]

//////////////////////////////////////////////////////////////////////////
// Actor local
//////////////////////////////////////////////////////////////////////////

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

      p = Proc { it.cmd=cmd; it.redirectErr=true }
      p.run
      Actor.locals["p"] = p
      log.debug("ntpd process started")
    }
  }
}