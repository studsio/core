# Changelog

#### Version 1.11 (working)
* New design for JRE using pre-built OSS JRE images managed by Studs
* New `SysLog` ring buffer for system wide syslog available via `Sys.log`
* New `Sys.loadKernelMod` API
* New `FileSystem` API
* New `fan studs rel` release info command
* Update AsmCmd to display `jre` in use
* Update AsmCmd behavior to use common `rootfs_overlay` and `rootfs_overlay_{sys.name}`
* Update AsmCmd to remove support for multiple targets
    - This was never really supported properly due to configuration in
      `faninit.props`. Its simpler to keep these local to the target system
      and introduce a new concept for targeting multiple hardware. TBD.
* Update Toolchains to compile/store by arch instead of sys.name
    - This removes duplicated binaries in `studsTools` when arch is the
      same (ie. `bb` and `rpi3` both use `arm_unknown_linux_gnueabihf`)
    - This makes it easier to support custom systems since in most cases
      it uses an existing toolchain architecture with preexisting binaries
* Update `Networkd.status` to return `ipaddr` value for interface
* Update `Networkd.status` to return `netmask` value for interface
* Update `Networkd.status` to return `mac` as hex string instead of `Buf`
* Update `Networkd.setup` to rename `mask` -> `netmask`
    - Support for taking either subnet `255.255.255.0` or `24` prefix
* Fix for `udhcpc.script` to correctly set interface `netmask` subnet
* Fix for `Sys.updateFirmware` to ignore EOF errors
* Deprecate `KeyUtil` in favor of new Fantom `Crypto` API

#### Version 1.10 (19-Jul-2018)
* New end-to-end firmware signing support
   - All firmware is now required to be signed
* New new Httpd daemon for web server support
* New OTA firmware update support in Httpd
* New `Sys.updateFirmware` method
* New `PushCmd` to simplify pushing firmware from CLI
* Update `Sys` to log events (mount partition, updateFirmware, reboot, etc)
* Update AsmCmd to display system version in output
* Update AsmCmd to download system images from GitHub
* Update default pod blacklist to be stricter:
   - Saves 1.37MB bytes off release fw size
   - Added to blacklist: `build`, `compiler`, `compilerDoc`, `compilerJava`,
     `compilerJs`, `email`, `fandoc`, `fanr`, `fansh`, `obix`, `sql`
* Update systems to 1.4
* Fix BurnCmd to sort release filenames
* Fix Networkd.list argument bug

#### Version 1.9 (26-Jun-2018)
* Rename `rootfs-additions` -> `rootfs_overlay`
* Update toolchains to `1.0.0`
* Convert `system-bbb` -> `system-bb` to reflect broader board support
* Update systems to `1.3`

#### Version 1.8 (29-Nov-2017)
* Change licence to Apache License 2.0
* Official support for `rpi0`
* Update systems to `1.2`
   - Remove Erlang and dependencies from base system; we already did not
     distribute OTP releases, but this stills saves ~1MB off release fw size
     and cuts Buildroot make times from ~25min down to ~15min
* Update toolchains to `0.11.0`
* Add `Cmd` warnings for retired `studs.props` and `faninit.props` properties

#### Version 1.7 (15-Aug-2017)
[bbb-1.1]:  https://bitbucket.org/studs/system-bbb/src/068f8e086a82a41975d3392b5a361df8747aa84d/changelog.md
[rpi3-1.1]: https://bitbucket.org/studs/system-rpi3/src/9db864004a9a0431f56016b39725abdb55095c0b/changelog.md

* Update systems to `1.1` - see BitBucket for details:
    - [bbb changelog][bbb-1.1]
    - [rpi3 changelog][rpi3-1.1]
    - Initial support for `rpi0`
* Fix AsmCmd to not delete local system source tarballs
* Fix BurnCmd to prompt when multiple releases found
* Fix Networkd to flush addr before assigning a static IP address
* Add basic DHCP support
* Add support for reading fwup firmware props with `Sys.fwActiveProps` and `Sys.fwProps`
* Rework `/data` mount to use `Sys.mountData` and support auto-reformatting if partition
  could not be mounted.  The `fs.mount` option in `faninit.props` is no longer used.
* Update serial console tutorial to include rpi3

#### Version 1.6 (21-Jul-2017)
* Add `studs burn --upgrade` option to perform a `--task upgrade` during burn
* Fix `faninit` to start java under `/app/fan` working directory
* Networkd: rename fields `ipaddr,netmask -> ip,mask`
* Networkd: add `router` field for default route
* Fix `Ntpd.servers` to be mutable
* Add `Ntpd.sync` to block until time is acquired
* Add `libfan` for Fantom-JNI library support
* Networkd: fix to invoke `res_init` after updating `/etc/resolve.conf`
* Fix `Daemon.cur` design to properly work across actors
* Blacklist unnecessary pods during `AsmCmd` (saves `2.88MB` off release fw size)
* Add support for `pod.blacklist` and `pod.whitelist` in `studs.props`
* Fix `Gpio.listen` to pass `mode` to fangpio
* Add `Gpio.listen` `timeout` argument
* Add `Sys.shutdown` method
* Add support for configuring JVM heap size with `jvm.xmx` in `faninit.props`

#### Version 1.5 (4-May-2017)
* Add `repo.public` pod.meta for `studs,studsTools` for Eggbox
* Add `--clean` option for `AsmCmd` to delete `studs/systems/` and `studs/jres/` intermediate files
* Add `studs.props` support for configuring which JRE compact profile to use
* Make JRE profile default to `compact1` (saves `6MB` off release fw size)
* Update `GettingStarted` to include Linux installation instructions
* Fix `AsmCmd` JRE setup to work on Linux
* Beef up `Building.md` docs

#### Version 1.4 (12-Apr-2017)
* New `inspect` on-device unit testing app: [BitBucket](https://bitbucket.org/studs/inspect)
* Add `/etc/sys.props` available on device at runtime
* Add `studs::Sys` for `/etc/sys.props` access and reboot support
* Working Uart.read/write support; fix to correctly configure `UartConfig` on open
* Prototype `studs::Gpio`
* Prototype `studs::I2C`
* Prototype `studs::Spi`
* Indicate release file size in `AsmCmd`
* Remove `DaemonMgr` and simply use `Daemon.start`
* Show duration time for `AsmCmd`

#### Version 1.3 (29-Mar-2017)
* Change versioning to use simpler `<major>.<minor>.<patch>` convention
* Rework build scripts to move Toolchain into studsTools
* Cleanup dependencies so fanr install will work
* Pack encoder/decoder
* BurnCmd: prompt when multiple disk devices found
* Proc.sinkErr
* Prototype DevTree
* Prototype Uart API
* Rename DaemonSupervisor -> DaemonMgr

#### Version 1.0.2 (18-Jan-2017)
* Move repo to https://bitbucket.org/studs/core
* Rename BuildCmd -> AsmCmd
* Add some real-world functionality into `init` skeleton Main
* Add support for `~/.studs` profile
* Add support for looking up jre.tar.gz via `jre.dirs` profile prop
* Rework Cmd to model studs.props with Props
* Add support for using custom systems via `target.xxx.uri` system.prop

#### Version 1.0.1 (2-Oct-2016)
* faninit: add support for fs.mount option
* faninit: add support for tty.console option
* Add Daemon and DaemonSupervisor API
* Add Proc API
* Add Ntpd
* Add Networkd
* Update tools to use our own system packages hosted on BitBucket

#### Version 1.0.0 (14-Sep-2016)
Initial bare-bones working version with minimal support
for faninit, booting JVM, and basic LED support