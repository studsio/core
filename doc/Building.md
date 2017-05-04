# Building

Most build and assembly configuration is specified in `studs.props`:

    # Project meta-data
    proj.name=myApp
    proj.ver=1.0.0

    # JRE compact profile for target: 1, 2 or 3
    jre.profile=1

    # Uncomment to add target platform to build
    target.bbb=true
    #target.rpi3=true

## Using `fan asm`

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

## Rootfs Additions

To add additional files into the root filesystem, create a folder named
`rootfs-additions` under the `src` directory, with a subdirectory for each
system target:

    myproj/
     └─ src/
         └─ rootfs-additions/
             ├─ bbb/
             └─ rpi3/

Any files under the `rootfs-additions/xxx/` will be directly added to the
default root filesystem for the respective system. If a file in
`rootfs-additions` already exists in the base image, it will replace the base
copy.

## Profile Configuration

If you build lots of projects, some configuration may become repetitive --
particularly finding and copying the source JRE tarball into your project.

To help streamline this process, you can create a `.studs` profile file in your
home directory (`~/.studs`) to store project-wide configuration:

    # By default, studs will look for the source JRE tarball under the
    # local studs/jres/ directory. If one is not found, you may specify
    # another directory to search here. Must end in a trailing slash.
    jres.dir=/some/dir/
