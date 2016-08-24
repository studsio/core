# **Studs**

TODO: catchy tag line here :)

Easily build and deploy embedded software in [Fantom](http://fantom.org).

Inspired by and in cooperation with [Nerves](http://nerves-project.org).

## **Installation**

**NOTE: still under heavy development -- not ready for use yet!**

First make sure you have Java 7 or later installed on your machine.  This is
required for Fantom and for creating our embedded JRE images.

Next we need to install Fantom, Studs and several utilities we'll need to build
our firmware.  The easiest method is to use [Homebrew](http://brew.sh) and
[fanr](http://fantom.org/doc/docFanr/Tool):

    # Not yet functional:
    #  TODO: need to update homebrew fantom forumla to 1.0.69
    #  TODO: need to actually post studs to eggbox

    $ brew update
    $ brew install fantom
    $ brew install fwup squashfs coreutils
    $ fanr install -r http://eggbox.fantomfactory.org/fanr/ studs

## **Create a Project**

To get started, first we need to create a new project:

    $ fan studs init myproj

This will create a stand-alone [PathEnv](http://fantom.org/doc/docLang/Env#PathEnv)
to keep our application pods separate from our master Fantom lib:

    myproj/
     ├─ fan.props            # fan config for PathEnv
     ├─ src/
     |   ├─ fan/
     |   |   └─ Main.fan     # application entry point
     |   └─ build.fan        # project build file
     ├─ studs.props          # firmware configuration file
     └─ studs/
         ├─ jres/            # target JREs installed here
         └─ systems/         # target systems installed here

Review `build.fan` and add/change any fields that make sense.

`studs.props` contains the configuration for your firmware, including the
targets you wish to build for. The default target is `rpi3`, but you may change
or add additional targets by commenting/uncommenting them:

    # studs.props

    # Uncomment to add target platform to build
    #target.bbb=true
    target.rpi3=true

## **Install Embedded JRE**

Oracle requires you to jump through several hoops in order to get a JRE for
embedded platforms, so unfortunately this part of the process must be manually
completed.

Download the appropriate embedded JDK for your target platform:

Target           | eJDK
-----------------|-------------------------------------------------------------
Raspberry Pi 3   | [ejdk-8u###-linux-armv6-vfp-hflt.tar.gz](http://www.oracle.com/technetwork/java/embedded/embedded-se/downloads/javase-embedded-downloads-2209751.html)
BeagleBone Black | [ejdk-8u###-linux-armv6-vfp-hflt.tar.gz](http://www.oracle.com/technetwork/java/embedded/embedded-se/downloads/javase-embedded-downloads-2209751.html)

Next copy the tar into your project directory:

    myproj/
     └─ studs/
         └─ jres/
             └─ ejdk-8u###-linux-armv6-vfp-hflt.tar.gz

From here the build tools will manage creating the correct image for your device.

## **Build your Project**

Now we're ready to build!

TODO
