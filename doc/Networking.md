# Networking

## Networkd

TODO

    DaemonMgr {
      it.daemons = [
        Networkd()
      ]
    }.start

## Static IP Address

TODO

    Networkd.cur.setup([
      "name":    "eth0",
      "mode":    "static",
      "ipaddr":  "192.168.1.150",
      "netmask": "255.255.255.0",
      "dns":     "8.8.8.8 8.8.4.4"
    ])
