# Changelog

#### Version 1.4 (working)
- New `inspect` on-device unit testing app: [BitBucket](https://bitbucket.org/studs/inspect)
- Add `/etc/sys.props` available on device at runtime
- Add `studs::Sys` for `/etc/sys.props` access and reboot support
- Working Uart.read/write support; fix to correctly configure `UartConfig` on open
- Prototype `studs::Gpio`
- Prototype `studs::I2C`
- Prototype `studs::Spi`
- Indicate release file size in AsmCmd
- Remove `DaemonMgr` and simply use `Daemon.start`

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