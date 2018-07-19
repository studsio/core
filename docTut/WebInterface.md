# Creating a Web Interface

[httpd]: ../api/studs/Httpd.html

In this tutorial we'll cover how to implement a Web Interface for your device
using the [Httpd][httpd] daemon, complete with support for OTA firmware updates.

## Requirements

[setup]:       ../doc/GettingStarted.html
[http-server]: ../doc/HttpServer.html

 - [Setup Studs][setup]
 - [Review Http Server documentation][http-server]
 - Any supported device; this tutorial will use a BeagleBone Black

## Coding

First create a new project:

    $ fan studs init webui

Next edit your `src/fan/Main.fan` to look like:

    using studs
    using concurrent
    using web

    const class Main
    {
      static Int main()
      {
        // setup Networking for DHCP
        Networkd().start
        Networkd.cur.setup(["name":"eth0", "mode":"dhcp"])

        // setup Http server
        config := HttpConfig { it.root=MyWebMod() }
        Httpd(config).start

        // Sleep forever to keep Fantom running
        Actor.sleep(Duration.maxVal)
        return 0
      }
    }

    const class MyWebMod : WebMod
    {
      override Void onService()
      {
        res.statusCode = 200
        res.headers["Content-Type"] = "text/html; charset=UTF-8"

        out := res.out
        out.docType
        out.html
        out.head
          .title.esc("Hello, World!").titleEnd
          .headEnd
        out.body
          .h1.esc("Hello, World!").h1End
          .bodyEnd
        out.htmlEnd
      }
    }

## Running

[console]: Console.html

To build and run your project:

    $ src/build.fan
    $ fan studs asm
    $ fan studs burn

Insert your SD card and power up your device.  If using DHCP the assigned IP
address will be printed in the console output.

## Updating firmware OTA

[ota]: ../doc/HttpServer.html#ota-firmware-updates

After your initial `fan studs burn` to load your firmware onto disk, you can
push updates [over-the-air][ota] using:

    fan studs push 192.168.1.100
