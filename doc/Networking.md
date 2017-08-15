# Networking

[networkd]: ../api/studs/Networkd.html

Networking support in Studs is provided by the [Networkd][networkd] daemon.

## Basics

[cur]:    ../api/studs/Networkd.html#cur
[list]:   ../api/studs/Networkd.html#list
[status]: ../api/studs/Networkd.html#status

All methods operate on the `Networkd` singleton, accessed via [cur][cur]. First
step is start the daemon:

    Networkd().start

To list the available interfaces, use [list][list]:

    Networkd.cur.list => ["eth0":0]

To view status and statistics for a given interface, use [status][status]:

    Networkd.cur.status("eth0") =>
      ["name":"eth0", "up":true, "broadcast", ...]

## Static IP

[setup]: ../api/studs/Networkd.html#setup

To configure a static IP address for an interface, pass the configuration data
to [setup][setup], using `"mode":"static"`:

    Networkd.cur.setup([
      "name":   "eth0",
      "mode":   "static",
      "ip":     "192.168.1.150",
      "mask":   "24",
      "router": "192.168.1.1,
      "dns":    "8.8.8.8 8.8.4.4"
    ])

## DHCP

To configure an interface for automatic IP address assigment using DHCP,
use [setup][setup] with `"mode":"dhcp"`:

    Networkd.cur.setup(["name":"eth0", "mode":"dhcp"])
