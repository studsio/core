# Studs

TODO: catchy tag line here :)

Easily build and deploy embedded software in [Fantom](http://fantom.org).

Inspired by and in cooperation with [Nerves](http://nerves-project.org).

## Installation

**NOTE: still under heavy development -- not ready for use yet!**

TODO: Linux (Windows?)

TODO: need to update homebrew fantom forumla to 1.0.69

    $ brew update
    $ brew install fantom
    $ brew install fwup squashfs coreutils

## Create a Project

To get started, first we need to create and configure our project source
directory:

    $ mkdir myproj
    $ cd myproj
    $ touch fan.props
    $ fanr install -r http://eggbox.fantomfactory.org/fanr/ studs
    $ fanr install -r http://eggbox.fantomfactory.org/fanr/ studsTools
    $ fan studs init myproj

This will create a stand-alone [PathEnv](http://fantom.org/doc/docLang/Env#PathEnv)
to keep our application pods separate from our master Fantom lib:

    myproj/
      fan.props
      studs.props
      src/
        fan/
          Main.fan
        build.fan

Review `build.fan` and add/change any fields that make sense.
