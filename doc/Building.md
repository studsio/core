# **Building**

TODO: `fan studs asm` detailed docs

## **Targets**

By default asm will assemble all targets defined in `studs.props`.  To
assemble only a specific target(s) you can pass them on the command line:

    fan studs asm rpi3

## **Rootfs Additions**

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

## **Profile Configuration**

If you build lots of projects, some configuration may become repetitive --
particularly finding and copying the source JRE tarball into your project.

To help streamline this process, you can create a `.studs` profile file in your
home directory (`~/.studs`) to store project-wide configuration:

    # By default, studs will look for the source JRE tarball under the
    # local studs/jres/ directory. If one is not found, you may specify
    # another directory to search here. Must end in a trailing slash.
    jres.dir=/some/dir/
