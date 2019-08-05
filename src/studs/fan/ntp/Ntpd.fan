//
// Copyright (c) 2016, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   26 Sep 2016  Andy Frank  Creation
//

using concurrent

**
** The Ntpd daemon provides support for synchronizing wall clock
** time using the NTP protocol.
**
** See [NTP]`../../doc/NTP.html` chapter for details.
**
const class Ntpd : Daemon
{
  new make() : super(5sec)
  {
    // allow only one instance per VM
    if (!curRef.compareAndSet(null, this)) throw Err("Ntpd already exists")

    // TODO: override pin to info
    this.log.level = LogLevel.info
  }

  ** Get the Ntpd instance for this VM.  If an instance is
  ** not found, throw Err if 'checked' otherwise return null.
  static Ntpd? cur(Bool checked := true)
  {
    if (curRef.val == null && checked) throw Err("Ntpd instance not found")
    return curRef.val
  }

  private static const AtomicRef curRef := AtomicRef(null)

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

  @NoDoc override Void onStart() { onPoll }

  @NoDoc override Void onStop()
  {
    Proc? p := Actor.locals["p"]
    if (p == null || !p.isRunning) return

    p.kill.waitFor
    Actor.locals["p"] = null
    log.debug("ntpd process stopped")
  }

  @NoDoc override Void onPoll()
  {
    Proc? p := Actor.locals["p"]

    if (p != null)
    {
      // drain process stdout
      Str? out
      while (p.in.avail > 0)
      {
        out = p.in.readLine
        // TODO: parse output
        log.debug(out)
      }

      // check if still running
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