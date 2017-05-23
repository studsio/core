# Networking

TODO: coming in `1.5` or `1.6`

## Networkd

TODO

   Networkd().start

## Static IP Address

TODO

    Networkd.cur.setup([
      "name":   "eth0",
      "mode":   "static",
      "ip":     "192.168.1.150",
      "mask":   "24",
      "router": "192.168.1.1,
      "dns":    "8.8.8.8 8.8.4.4"
    ])
