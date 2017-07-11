# Changelog

#### Version 1.6 (working)
- Add `studs burn --upgrade` option to perform a `--task upgrade` during burn
- Fix `faninit` to start java under `/app/fan` working directory
- Networkd: rename fields `ipaddr,netmask -> ip,mask`
- Networkd: add `router` field for default route
- Fix `Ntpd.servers` to be mutable
- Add `Ntpd.sync` to block until time is acquired
- Add `libfan` for Fantom-JNI library support
- Networkd: fix to invoke `res_init` after updating `/etc/resolve.conf`
- Fix `Daemon.cur` design to properly work across actors
- Blacklist unnecessary pods during `AsmCmd` (shaves `2.88MB` off release fw size)
- Add support for `pod.blacklist` and `pod.whitelist` in `studs.props`
- Fix `Gpio.listen` to pass `mode` to fangpio
- Add `Gpio.listen` `timeout` argument
- Add `Sys.shutdown` method
- Add support for configuring JVM heap size with `jvm.xmx` in `faninit.props`

#### Version 1.5 (4-May-2017)
- Add `repo.public` pod.meta for `studs,studsTools` for Eggbox
- Add `--clean` option for `AsmCmd` to delete `studs/systems/` and `studs/jres/` intermediate files
- Add `studs.props` support for configuring which JRE compact profile to use
- Make JRE profile default to `compact1` (shaves `6MB` off release fw size)
- Update `GettingStarted` to include Linux installation instructions
- Fix `AsmCmd` JRE setup to work on Linux
- Beef up `Building.md` docs

#### Version 1.4 (12-Apr-2017)
- New `inspect` on-device unit testing app: [BitBucket](https://bitbucket.org/studs/inspect)
- Add `/etc/sys.props` available on device at runtime
- Add `studs::Sys` for `/etc/sys.props` access and reboot support
- Working Uart.read/write support; fix to correctly configure `UartConfig` on open
- Prototype `studs::Gpio`
- Prototype `studs::I2C`
- Prototype `studs::Spi`
- Indicate release file size in `AsmCmd`
- Remove `DaemonMgr` and simply use `Daemon.start`
- Show duration time for `AsmCmd`

#### Version 1.3 (29-Mar-2017)
- Change versioning to use simpler `<major>.<minor>.<patch>` convention
- Rework build scripts to move Toolchain into studsTools
- Cleanup dependencies so fanr install will work
- Pack encoder/decoder
- BurnCmd: prompt when multiple disk devices found
- Proc.sinkErr
- Prototype DevTree
- Prototype Uart API
- Rename DaemonSupervisor -> DaemonMgr

#### Version 1.0.2 (18-Jan-2017)
- Move repo to https://bitbucket.org/studs/core
- Rename BuildCmd -> AsmCmd
- Add some real-world functionality into `init` skeleton Main
- Add support for `~/.studs` profile
- Add support for looking up jre.tar.gz via `jre.dirs` profile prop
- Rework Cmd to model studs.props with Props
- Add support for using custom systems via `target.xxx.uri` system.prop

#### Version 1.0.1 (2-Oct-2016)
- faninit: add support for fs.mount option
- faninit: add support for tty.console option
- Add Daemon and DaemonSupervisor API
- Add Proc API
- Add Ntpd
- Add Networkd
- Update tools to use our own system packages hosted on BitBucket

#### Version 1.0.0 (14-Sep-2016)
Initial bare-bones working version with minimal support
for faninit, booting JVM, and basic LED support