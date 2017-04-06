# Getting Started

## Installation

First make sure you have Java 7 or later installed on your machine.  This is
required for Fantom and for creating our embedded JRE images.

Next we need to install Fantom, Studs and several utilities we'll need to build
our firmware.  The easiest method is to use [Homebrew](http://brew.sh) and
[fanr](http://fantom.org/doc/docFanr/Tool):

    $ brew update
    $ brew install fantom
    $ brew install fwup squashfs coreutils
    $ fanr install -r http://eggbox.fantomfactory.org/fanr/ "studs,studsTools"

## Create a Project

To get started, first we need to create a new project:

    $ fan studs init myproj

This will create a stand-alone [PathEnv](http://fantom.org/doc/docLang/Env#PathEnv)
to keep our application pods separate from our master Fantom lib:

    myproj/
    ├── fan.props            # fan config for PathEnv
    ├── src/
    │   ├── fan/
    │   │   └── Main.fan     # application entry point
    │   └── build.fan        # project build file
    ├── studs.props          # firmware configuration file
    └── studs/
        ├── jres/            # target JREs installed here
        ├── systems/         # target systems installed here
        └── releases/        # compiled firmware images put here

`studs.props` contains the configuration for your firmware, including the
targets you wish to build for. The default target is `bbb`, but you may change
or add additional targets by commenting/uncommenting them:

    # studs.props

    # Uncomment to add target platform to build
    target.bbb=true
    #target.rpi3=true

## Install Embedded JRE

Oracle requires you to jump through several hoops in order to get a JRE for
embedded platforms, so unfortunately this part of the process must be manually
completed.

Download the appropriate embedded JDK for your target platform:

Target           | eJDK
-----------------|-------------------------------------------------------------
BeagleBone Black | [ejdk-8u###-linux-armv6-vfp-hflt.tar.gz](http://www.oracle.com/technetwork/java/embedded/embedded-se/downloads/javase-embedded-downloads-2209751.html)
Raspberry Pi 3   | [ejdk-8u###-linux-armv6-vfp-hflt.tar.gz](http://www.oracle.com/technetwork/java/embedded/embedded-se/downloads/javase-embedded-downloads-2209751.html)

Next copy the tar into your project directory:

    myproj/
    └── studs/
        └── jres/
            └── ejdk-8u###-linux-armv6-vfp-hflt.tar.gz

From here the build tools will manage creating the correct image for your device.

## Build your Project

Now we're ready to build!

    $ src/build.fan
    $ fan studs asm

This will compile your Fantom application and assemble the firmware images for
your target device(s). The first time `studs asm` is run the system
dependencies will be downloaded which can take a few minutes. After that
firmware builds will be fast.

After building the firmware, images are placed under the `releases` dir, where
the naming convention is `proj-version-target`:

    myproj/
    └── studs/
        └── releases/
            └── myproj-1.0.0-bbb.fw

## Running your Project

To run your freshly minted project we need to burn our firmware image onto a
SD card:

    $ fan studs burn

This command will automatically detect the SD card in your host machine.  If you
have more then one card, or if you have more than one firmware target, you will
be prompted to select the desired choices.

Once complete, insert card into the target device and power up.

