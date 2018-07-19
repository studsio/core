# HTTP Server

[httpd]: ../api/studs/Httpd.html

HTTP server support in Studs is provided by the [Httpd][httpd] daemon.

## Basics

[HttpConfig]: ../api/studs/HttpConfig.html
[webmod]:     https://fantom.org/doc/web/WebMod
[ota]:        #ota-firmware-updates

To start a server with the default configuration of port `80` and [OTA][ota]
updates enabled, start the daemon with no arguments:

    Httpd().start

To customize HTTP settings pass a [HttpConfig][HttpConfig] instance:

    config := HttpConfig
    {
      it.port = 8001
      it.root = MyWebMod()
    }

    Httpd(config).start

## OTA Firmware Updates

Applying firmware updates over-the-air is performed with a standard HTTP `PUT`
request where the `Content-Type` header is `application/x-firmware`, and the
request body is the firmware file.

### Pushing Updates

The simplest way to push updates to a device is using the `studs push` CLI.
This will update a device using the default `HttpConfig` settings:

    fan studs push 192.168.1.100

If your device is using non-standard settings:

    # alternate port
    fan studs push 192.168.1.100:8001

    # custom otaUpdateUri
    fan studs push 192.168.1.100 /custom/update/uri

Example using `curl`:

    curl -T my-firmware.fw -H "Content-Type: application/x-firmware" \
         http://192.168.1.100/update-fw

Devices are implicitly rebooted after an OTA firmware update has been received
to apply. See [Disabling Updates](#disabling-updates) for how to customize this
behavior.

### Disabling Updates

[otaUri]:   ../api/studs/HttpConfig.html#otaUpdateUri
[updateFw]: ../api/studs/Sys.html#updateFirmware

To completely disable OTA firmware updates, configure [otaUpdateUri][otaUri]
to `null`:

    config := HttpConfig { it.otaUpdateUri = null }
    Httpd(config).start

This will disable `Httpd` support for OTA updates. You may, however, still
manually implement this functionality in your own WebMod using
[Sys.updateFirmware][updateFw].
