# **Studs**

TODO: catchy tag line here :)

Easily build and deploy embedded software in [Fantom](http://fantom.org).

Inspired by and in cooperation with [Nerves](http://nerves-project.org).

## **Installation**

**NOTE: still under heavy development -- not ready for use yet!**

TODO:

  - Linux (Windows?)
  - need to update homebrew fantom forumla to 1.0.69
  - java?

Studs requires a few dependencies we need to install first. The simplest way to
is to use [Homebrew](http://brew.sh) and [fanr](http://fantom.org/doc/docFanr/Tool):

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
      fan.props
      studs.props
      src/
        fan/
          Main.fan
        build.fan

Review `build.fan` and add/change any fields that make sense.
