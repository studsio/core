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

  ** Configure a network interface.
  This setup(Str:Str opts)
  {
    send(DaemonMsg { it.op="setup"; it.a=opts.toImmutable })
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Actor local
//////////////////////////////////////////////////////////////////////////

  @NoDoc override Void onStart() {}

  @NoDoc override Void onStop() {}

  @NoDoc override Void onPoll() {}

  @NoDoc override Obj? onMsg(DaemonMsg m)
  {
    if (m.op === "setup") return onSetup(m.a)
    throw ArgErr("Unsupported message op '$m.op'")
  }

  private Obj? onSetup(Str:Str opts)
  {
    log.debug("setup: $opts")

    // TODO: figure how which command(s) to invoke
    // and verify correct options were passed in
    name    := opts["name"]    ?: throw ArgErr("Missing 'name' opt")
    ipaddr  := opts["ipaddr"]  ?: throw ArgErr("Missing 'ipaddr' opt")
    netmask := opts["netmask"] ?: throw ArgErr("Missing 'ipaddr' opt")

    // TODO: for now just call into busybox
    up   := ["/sbin/ip", "link", "set", name, "up"]
    set  := ["/sbin/ip", "addr", "add", "${ipaddr}/24", "dev", name]
    Proc { it.cmd=up  }.run.waitFor.okOrThrow
    Proc { it.cmd=set }.run.waitFor.okOrThrow

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

    return null
  }
}