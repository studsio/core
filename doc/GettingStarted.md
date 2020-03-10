# Getting Started

## Installation

First make sure you have Java 8 or later installed on your machine.  This is
required for Fantom.

Next we need to install Fantom, Studs and several utilities we'll need to build
our firmware.

### macOS

The easiest method for macOS is to use [Homebrew](http://brew.sh) and
[fanr](http://fantom.org/doc/docFanr/Tool):

    $ brew update
    $ brew install fantom
    $ brew install fwup squashfs coreutils
    $ fanr install -r http://eggbox.fantomfactory.org/fanr/ "studs,studsTools"

### Linux

[fanorg]:     http://fantom.org
[linux-fan]:  http://fantom.org/doc/docTools/Setup#unix
[linux-fwup]: https://github.com/fhunleth/fwup#installing

Fantom is currently not available in most package managers, so you'll need to
download and unzip onto your system.  Follow [Setup][linux-fan] instructions
on [fantom.org][fanorg].  Note that Java is a pre-requisite for Fantom.

Next install `fwup` using the instructions on the [Installation
Page][linux-fwup].

The ssh-askpass package is also required on Linux so `burn` command will be
able to use sudo to gain the required permission to write directly to an SD
card:

    $ sudo apt-get install ssh-askpass

Finally, install squashfs-tools using your distribution’s package manager along
with the Studs fantom pods. For example:

    $ sudo apt-get install squashfs-tools
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
targets you wish to build for. The default target is `bb`, but you may change
or add additional targets by commenting/uncommenting them:

    # studs.props

    # Target platform to build
    system.name=bb
    #system.name=rpi3
    #system.name=rpi0

## Build your Project

Now we're ready to build!

    $ src/build.fan
    $ fan studs asm

This will compile your Fantom application and assemble the firmware images for
your target device(s). The first time `studs asm` is run the system
dependencies will be downloaded which can take a few minutes. After that
firmware builds will be fast.

After building the firmware, images are placed under the `releases` dir, where
the naming convention is `proj-version-system`:

    myproj/
    └── studs/
        └── releases/
            └── myproj-1.0.0-bb.fw

See [Building](Building.html) for detailed documentation on the build process.

## Running your Project

To run your freshly minted project we need to burn our firmware image onto a
SD card:

    $ fan studs burn

This command will automatically detect the SD card in your host machine.  If you
have more then one card, or if you have more than one firmware target, you will
be prompted to select the desired choices.

Once complete, insert card into the target device and power up.

