# Building

Most build and assembly configuration is specified in `studs.props`:

    # Project meta-data
    proj.name=myApp
    proj.ver=1.0.0

    # Target platform to build
    system.name=rpi3

## Using `fan studs asm`

The `asm` command is used to assemble firmware bundles from your application:

    fan studs asm [--clean] [--gen-keys]

The `--clean` option deletes intermediate and cached System and JRE files. The
next time `fan studs asm` is invoked, the system and JRE will be re-downloaded
and configured.

    $ fan studs asm --clean

Firmware is always signed. The first time `fan studs asm` is invoked, a pair
of public-private siging keys will be auto-generated (`fw-key.pub` and
`fw-key.priv`).  In order to update firwmare in existing devices, you **must**
use the same signing keys.  Take care to keep the `fw-key.priv` private key
safe.

If you ever need to regenerate keys, you can use the `--gen-keys` option. Be
aware this will remove your existing keys.  Have a backup if you need the old
keys!

    $ fan studs --gen-keys
    Key pair already exists. Regenerate and overwrite? [yN

## Using `fan studs burn`

The `burn` command writes your firmware bundle onto a SDCard:

    fan studs burn [options]*

By default, this command detects attached SDCards and then invokes `fwup` to
overwrite the contents of the selected SDCard with the new image. Data on the
SDCard will be lost, so be careful.

The `upgrade` option can be used to upgrade your application on an existing
SDCard. In this case only the root application partition is effected -- any
data partitions will not be touched.

    $ fan studs burn --upgrade

## Rootfs Overlay

To add additional files into the root filesystem, create a folder named
`rootfs_overlay` under the `src` directory, with a subdirectory for each system
target:

    myproj/
     └─ src/
         └─ rootfs_overlay/

Any files under the `rootfs_overlay/` will be directly added to the default
root filesystem for the respective system. If a file in `rootfs_overlay`
already exists in the base image, it will replace the base copy.

To customize the root filesystem on a per system basis add a system name suffix
to the rootfs directory:

    myproj/
     └─ src/
         ├─ rootfs_overlay/       # all systems get this overlay
         └─ rootfs_overlay_bb/    # only `bb` targets get this overlay

The common `rootfs_overlay` is always copied first. If a matching system
specific overlay is found, it will be copied overtop of both base copies.

## Pod Whitelist/Blacklist

The `AsmCmd` will attempt to exclude certain pods that generally do not make
sense to install in an embedded environment, in order to reduce the release
firmware size.  The default blacklist is:

    studsTest, studsTools, build, compiler, compilerDoc, compilerJava,
    compilerJs, docDomkit, docFanr, docIntro, docLang, docTools, icons,
    gfx, fwt, webfwt, flux, fluxTest, syntax, email, fandoc, fanr, fansh,
    obix, sql, testCompiler, testDomkit, testJava, testNative, testSys

To add additional pods to the exclusion list, configure the `pod.blacklist` in
your `studs.props`:

    # Comma-separated list of pods to exclude from release fw image.
    # This list is in addition to the default blacklist.
    pod.blacklist=myPodA,myPodB

To force a pod to always be included (such as a pod from the default
blacklist), configure `pod.whitelist` in your `studs.props` file:

    # Comma-separated list of pods to always include in release fw
    # image. This list takes precedence over both the default and
    # above blacklists.
    pod.whitelist=gfx,fwt,myPod
