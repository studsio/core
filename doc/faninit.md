# faninit

This is a replacement for `/sbin/init` that launches directly into the Fantom
runtime on start-up. It is intentionally minimalist as it expects Fantom to be
in charge of application initialization and supervision.

Based on **erlinit** by Frank Hunleth:

[https://github.com/nerves-project/erlinit](https://github.com/nerves-project/erlinit)

## Configuration

`faninit` reads configuration from `/etc/faninit.props`. The available options
are:

    # Fantom entry point which is invoked when faninit boots
    # The acceptable options are the same as 'fan':
    #   http://fantom.org/doc/docTools/Fan#pods
    main=<pod>[::<type>[.<method>]]

    # Configure the maximum heap size for JVM using -Xmx option
    jvm.xmx=384m

    # Enable debug logging
    debug=true

    # Override the controlling terminal (ttyAMA0, tty1, etc.)
    #tty.console=ttyO0

    # Action to take when JVM exits:
    #   'hang'      hang the board rather than rebooting
    #   'reboot'    reboot board
    #   'poweroff'  power off board; This is similar to 'hang' except it's for
    #               platforms without a reset button or an easy way to restart
    exit.action=hang

    # Optionally run a program after JVM exits
    exit.run=/bin/sh

    # Action to take when a fatal error is detected in faninint
    # See 'exit.action' for options
    fatal.action=hang