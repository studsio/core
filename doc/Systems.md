# Systems

[br]:     https://buildroot.org
[docker]: https://www.docker.com

Studs systems are simply minimal Linux images built using [Buildroot][br]. They
are designed to be small and lightweight, and push as much implementation detail
as possible up into the Studs Fantom layer. This keeps systems simple and
improves portability for applications.

## Supported Systems

[hg-bbb]:  https://https://bitbucket.org/studs/system-bbb
[hg-rpi3]: https://https://bitbucket.org/studs/system-rpi3
[vagrant]: https://www.vagrantup.com

Studs includes several pre-built systems as part of the open source project:

Name | Platform         | Repo
-----|------------------|----------------
bbb  | BeagleBone Black | [Repo][hg-bbb]
rpi3 | Raspberry Pi 3   | [Repo][hg-rpi3]

## Building a System

To build a Studs system you will need a Linux PC or VM. This project supports
building on macOS using [Vagrant][vagrant]. But most any Linux setup will work.
This section will cover how to build an existing system from source. The follow
section will cover how to create your own systems.

### Setup Build Directory

First step is to setup our build directory and pull the system sources we will
be using. This step should be done on the host system (not in your VM).

Grab `hg` if needed:

    # macOS
    $ brew install mercurial

    # Debian/Ubuntu
    $ sudo apt-get install mercurial

Next pull the `base` and `bbb` system sources under a root `studs` directory:

    $ mkdir studs
    $ cd studs
    $ hg clone ssh://hg@bitbucket.org/studs/system
    $ hg clone ssh://hg@bitbucket.org/studs/system-bbb

Afterwards your `studs` directory should look like this:

    studs
    ├── system
    └── system-bbb

### macOS Vagrant Setup

[vf]: https://bitbucket.org/studs/system/src/tip/vagrant/Vagrantfile
[hg]: https://www.mercurial-scm.org/downloads

The simplest way to build on macOS is to use the supplied [Vagrantfile][vf],
which will allow you to host and edit the source on your Mac, and build on a
Linux VM. To get started with Vagrant:

  1. Install [Vagrant](https://www.vagrantup.com)

  2. Install [VirtualBox]( https://www.virtualbox.org)

  3. Modify the defaults in `system/vagrant/Vagrantfile` for memory/cores to
     match your host:

        # Change here for more or less memory/cores
        VM_MEMORY=8192
        VM_CORES=4

   4. Provision your VM -- this will take a few minutes while it downloads and
      configures your new image:

        $ cd system/vagrant
        $ vagrant up

   5. When provisioning is complete, log into your VM:

        $ vagrant ssh

Your host `studs` source directory will automatically be shared when you boot
your Vagrant VM. It will be mounted under `~/studs` on Linux:

    vagrant@jessie:~$ ls ~/studs
    system  system-bbb

Quick-start to using Vagrant:

    $ vagrant up       # boot VM
    $ vargant ssh      # login to VM
    $ vagrant halt     # shutdown VM -- 'vagrant up' to reboot
    $ vagrant destory  # delete VM -- 'vagrant up' to recreate

Once Vagrant is setup and you have booted and logged into your VM, continue to
the Setup section below to complete setup.

### Building

On Linux, first install required dependencies:

    $ sudo apt-get update
    $ sudo apt-get install git g++ libssl-dev libncurses5-dev \
      bc m4 make unzip cmake

Once you have setup Linux and download system sources, setup your build
configuration for the intended target:

    $ system/setup.sh bbb

The `setup.sh` script will:

   - Download and install Buildroot
   - Configure Buildroot to compile our Studs project
   - Create an output working directory for Buildroot

Change to your output directory and run `make`:

    # macOS Vagrant -- we need to store our output directory outside of the
    # shared folder under Vagrant, since VirtualBox does not support creating
    # hardlinks in shared folders -- which Buildroot requires
    $ cd /home/vagrant/output-bbb/
    $ make

    # Under native Linux the output direcotry will be created as a peer to
    # the system source directories
    $ cd output-bbb
    $ make

After we have run `make` a new tarball will be created in the target directory:

    system-bbb/releases/studs-system-bbb-1.0.0.tar.gz



## Creating a New System

TODO