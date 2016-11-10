# **Building Firmware**

TODO: `fan studs asm` detailed docs

## Targets

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
