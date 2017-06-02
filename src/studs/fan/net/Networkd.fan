//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Sep 2016  Andy Frank  Creation
//

using concurrent

**
** Networkd
**
const class Networkd : Daemon
{
  @NoDoc new make() : super(5sec) {}

  ** Get the Networkd instance for this vm.  If an instance is
  ** not found, throw Err if 'checked' otherwise reutrn null.
  static Networkd? cur(Bool checked := true)
  {
    d := Actor.locals["d.networkd"]
    if (d == null && checked) throw Err("Networkd instance not found")
    return d
  }

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
    send(DaemonMsg { it.op="setup"; it.a=opts.toImmutable })
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

  @NoDoc override Void onPoll() {}

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
    Pack.write(proc.out, ["op":"status"])
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

    // TODO: for now just call into busybox
    up   := ["/sbin/ip", "link", "set", name, "up"]
    set  := ["/sbin/ip", "addr", "add", "${ip}/${mask}", "dev", name]
    Proc { it.cmd=up  }.run.waitFor.okOrThrow
    Proc { it.cmd=set }.run.waitFor.okOrThrow

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
    }
  }

  ** Setup dhcp IP assignment.
  private Void setupDhcp(Str:Obj opts)
  {
    // TODO
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