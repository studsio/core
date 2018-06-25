# Building

Most build and assembly configuration is specified in `studs.props`:

    # Project meta-data
    proj.name=myApp
    proj.ver=1.0.0

    # JRE compact profile for target: 1, 2 or 3
    jre.profile=1

    # Uncomment to add target platform to build
    target.bb=true
    #target.rpi3=true

## Using `fan studs asm`

The `asm` command is used to assemble firmware bundles from your application:

    fan studs asm [target]* [--clean]

 - `[target*]` -- By default asm will assemble all targets defined in
   `studs.props`. To assemble only a specific target(s) you can pass them on
   the command line:

       $ fan studs asm        # build all enabled targets
       $ fan studs asm rpi3   # build only rpi3 target

  - `--clean` -- This option deletes intermediate and cached System and JRE
    files:

        $ fan studs asm --clean

    The next time `fan studs asm` is invoked, systems will be re-downloaded and
    configured, and the JRE will be rebuilt.

## Using `fan studs burn`

The `burn` command writes your firmware bundle onto a SDCard:

    fan studs burn [options]*

By default, this command detects attached SDCards and then invokes `fwup` to
overwrite the contents of the selected SDCard with the new image. Data on the
SDCard will be lost, so be careful.

The `upgrade` option can be used to upgrade your application on an existing
SDCard. In this case only the root application partition is effected -- any
data partitions will not be touched.

    fan studs burn --upgrade

## JRE Compact Profiles

[jre-profiles]: http://www.oracle.com/technetwork/java/embedded/resources/tech/compact-profiles-overview-2157132.html

The `asm` command will generate any of the 3 compact profiles for the target
embedded JRE. See [Compact Profiles Overview][jre-profiles] for details and
comparison of each profile.

Studs defaults to profile `1` to minimize the release file size. The profile
may be changed in `studs.props`:

    # JRE compact profile for target: 1, 2 or 3
    jre.profile=1

Remember to run `asm --clean` after making any changes to `jre.profile`.

## Rootfs Overlay

To add additional files into the root filesystem, create a folder named
`rootfs_overlay` under the `src` directory, with a subdirectory for each system
target:

    myproj/
     └─ src/
         └─ rootfs_overlay/
             ├─ bb/
             └─ rpi3/

Any files under the `rootfs_overlay/xxx/` will be directly added to the default
root filesystem for the respective system. If a file in `rootfs_overlay`
already exists in the base image, it will replace the base copy.

## Pod Whitelist/Blacklist

The `AsmCmd` will attempt to exclude certain pods that generally do not make
sense to install in an embedded environment, in order to reduce the release
firmware size.  The default blacklist is:

    studsTest, studsTools, docDomkit, docFanr, docIntro, docLang,
    docTools, icons, gfx, fwt, webfwt, flux, fluxTest, syntax, testCompiler,
    testDomkit, testJava, testNative, testSys

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

## Profile Configuration

If you build lots of projects, some configuration may become repetitive --
particularly finding and copying the source JRE tarball into your project.

To help streamline this process, you can create a `.studs` profile file in your
home directory (`~/.studs`) to store project-wide configuration:

    # By default, studs will look for the source JRE tarball under the
    # local studs/jres/ directory. If one is not found, you may specify
    # another directory to search here. Must end in a trailing slash.
    jres.dir=/some/dir/
