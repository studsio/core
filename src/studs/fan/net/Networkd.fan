//
// Copyright (c) 2016, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   29 Sep 2016  Andy Frank  Creation
//

using concurrent

**
** Networking support in Studs is provided by the Networkd daemon.
**
** See [Networking]`../../doc/Networking.html` chapter for details.
**
const class Networkd : Daemon
{
  @NoDoc new make() : super(5sec)
  {
    // allow only one instance per VM
    if (!curRef.compareAndSet(null, this)) throw Err("Networkd already exists")
  }

  ** Get the Networkd instance for this VM.  If an instance is
  ** not found, throw Err if 'checked' otherwise return null.
  static Networkd? cur(Bool checked := true)
  {
    if (curRef.val == null && checked) throw Err("Networkd instance not found")
    return curRef.val
  }

  private static const AtomicRef curRef := AtomicRef(null)

  ** List available network interfaces for this device. Blocks
  ** until 'timeout' elapses waiting for results.  If 'timeout'
  ** is 'null' blocks forever.
  Str:Obj list(Str name, Duration? timeout := 10sec)
  {
    send(DaemonMsg { it.op="list" }).get(timeout)
  }

  ** Get the status for given network interface. Blocks until
  ** 'timeout' elapses waiting for results.  If 'timeout' is
  ** 'null' blocks forever.
  Str:Obj status(Str name, Duration? timeout := 10sec)
  {
    send(DaemonMsg { it.op="status"; it.a=name }).get(timeout)
  }

  ** Configure a network interface.
  This setup(Str:Str opts)
  {
    // get Future to collect any thrown Errs
    send(DaemonMsg { it.op="setup"; it.a=opts.toImmutable }).get(1min)
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Actor local
//////////////////////////////////////////////////////////////////////////

  @NoDoc override Void onStart()
  {
    // touch to start process
    getProc
  }

  @NoDoc override Void onStop()
  {
    // gracefully exit native if running
    proc := getProc(false)
    if (proc == null) return
    try
    {
      Pack.write(proc.out, ["op":"exit"])
      proc.waitFor
      Actor.locals["p"] = null
    }
    catch (Err err) { throw IOErr("Networkd.stop failed", err) }
  }

  @NoDoc override Void onPoll()
  {
    // check dhcp
    p := Actor.locals["dp"] as Proc
    if (p == null) return

    // drain stdout
    while (p.in.avail  > 0)
    {
      // TODO
      out := p.in.readLine
      if (out.contains("adding dns")) LibFan.reloadResolvConf
      log.debug(out)
    }
  }

  @NoDoc override Obj? onMsg(DaemonMsg m)
  {
    if (m.op === "status") return onStatus(m.a)
    if (m.op === "list")   return onList
    if (m.op === "setup")  return onSetup(m.a)
    throw ArgErr("Unsupported message op '$m.op'")
  }

  ** Service status msg.
  private Obj? onStatus(Str name)
  {
    proc := getProc
    Pack.write(proc.out, ["op":"status", "name":name])
    res := Pack.read(proc.in)
    checkErr(res)
    return res
  }

  ** Service list msg.
  private Obj? onList()
  {
    proc := getProc
    Pack.write(proc.out, ["op":"list"])
    res := Pack.read(proc.in)
    checkErr(res)
    return res
  }

  ** Service setup msg.
  private Obj? onSetup(Str:Str opts)
  {
    log.debug("setup: $opts")
    mode := opts["mode"]
    switch (mode)
    {
      case "static": setupStatic(opts)
      case "dhcp":   setupDhcp(opts)
      default:       throw Err("Unknown mode '$mode'")
    }
    return null
  }

  ** Setup static IP assignment.
  private Void setupStatic(Str:Obj opts)
  {
    // TODO: figure how which command(s) to invoke
    // and verify correct options were passed in
    name   := opts["name"]   ?: throw ArgErr("Missing 'name' opt")
    ip     := opts["ip"]     ?: throw ArgErr("Missing 'ip' opt")
    mask   := opts["mask"]   ?: throw ArgErr("Missing 'mask' opt")

    // make sure dhcp is not running
    killDhcp

    // TODO: for now just call into busybox
    up    := ["/sbin/ip", "link", "set", name, "up"]
    flush := ["/sbin/ip", "addr", "flush", "dev", name]
    set   := ["/sbin/ip", "addr", "add", "${ip}/${mask}", "dev", name]
    Proc { it.cmd=up    }.run.waitFor.okOrThrow
    Proc { it.cmd=flush }.run.waitFor.okOrThrow
    Proc { it.cmd=set   }.run.waitFor.okOrThrow

    // Update default route
    router := opts["router"]
    if (router != null)
    {
      def := ["/sbin/ip", "route", "add", "default", "via", router, "dev", name]
      Proc { it.cmd=def }.run.waitFor.okOrThrow
    }

    // Update DNS
    Str? dns := opts["dns"] as Str
    if (dns != null)
    {
      out := File(`/tmp/resolv.conf`).out
      try
      {
        dns.split.each |n| { out.printLine("nameserver $n") }
        out.flush.sync
      }
      finally { out.close }
      LibFan.reloadResolvConf
    }
  }

  ** Setup dhcp IP assignment.
  private Void setupDhcp(Str:Obj opts)
  {
    name := opts["name"] ?: throw ArgErr("Missing 'name' opt")

    // stop existing dhcp daemon if running
    killDhcp

    // assemble process args
    dhcp := ["udhcpc",
      "--interface", name,
      "--foreground",
      "--script", "/usr/bin/udhcpc.script"
    ]

    // start daemon
    p := Proc { it.cmd=dhcp; it.redirectErr=true }.run
    Actor.locals["dp"] = p
  }

  ** Kill udhcp process if running.
  private Void killDhcp()
  {
    p := Actor.locals["dp"] as Proc
    if (p == null) return
    if (!p.isRunning) return
    p.kill.waitFor
    Actor.locals.remove("dp")
  }

  ** Get our background native process. If 'start' is 'true' then
  ** start the process if it is not found or not currenlty running.
  private Proc? getProc(Bool start := true)
  {
    proc := Actor.locals["p"] as Proc
    if (proc == null || !proc.isRunning)
    {
      if (!start) return null
      proc = Proc { it.cmd=["/usr/bin/fannet"] }
      proc.run.sinkErr
      Actor.locals["p"] = proc
    }
    return proc
  }

  ** Check pack message and throw Err if contains 'err' key.
  private Void checkErr(Str:Obj pack)
  {
    if (pack["status"] == "err")
      throw Err(pack["msg"] ?: "Unknown error")
  }
}