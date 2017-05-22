# NTP

The [Ntpd](../api/studs/Ntpd.html) daemon provides support for synchronizing
wall clock time using the NTP protocol.

## Ntpd

[start]: ../api/studs/Ntpd.html#start
[sync]:  ../api/studs/Ntpd.html#sync

To use NTP simply start the daemon using [start][start], synchronization will
begin in the background:

    Ntpd().start

To block your application until a valid time has been acquired, first setup
your network interface, then call [sync][sync] to wait:

    // start our networking and NTP daemons
    Netword().start
    Ntpd().start

    // setup network interface, and block until NTP acquires time
    Networkd.cur.setup(["name":"eth0", "mode":"dhcp"])
    Ntpd.cur.sync

    echo("Time is $DateTime.now")

An optional timeout may be passed to [sync][sync], where the method returns
`true` if time was successfully acquired, or `false` if it timed out:

    if (Ntpd.cur.sync(30sec)) echo("Time is $DateTime.now")
    else echo("Sync timed out")
