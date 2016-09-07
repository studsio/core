/*
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Aug 2016  Andy Frank  Creation
//
// Based on erlinit by Frank Hunleth:
// https://github.com/nerves-project/erlinit
*/

#include "faninit.h"

#define _GNU_SOURCE // for asprintf

#include <dirent.h>
#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <linux/reboot.h>
#include <sys/reboot.h>
#include <sys/stat.h>
#include <sys/wait.h>

static int desired_reboot_cmd = 0; // 0 = no request to reboot

static void setup_environment()
{
  debug("setup_environment");

  // Set up the environment for running Fantom.
  putenv("HOME=/root");

  // PATH appears to only be needed for user convenience when running os:cmd/1
  // It may be possible to remove in the future.
  putenv("PATH=/usr/sbin:/usr/bin:/sbin:/bin");
  putenv("TERM=vt100");

  // Java/Fantom environment
  // TODO FIXIT
  putenv("FAN_HOME=/app/fan");
  putenv("JAVA_HOME=/app/jre");

  // Set any additional environment variables from the user
  if (options.additional_env) {
    char *envstr = strtok(options.additional_env, ";");
    while (envstr) {
      putenv(strdup(envstr));
      envstr = strtok(NULL, ";");
    }
  }
}

static int run_cmd(const char *cmd)
{
  debug("run_cmd '%s'", cmd);

  pid_t pid = fork();
  if (pid == 0) {
    // child
    char *cmd_copy = strdup(cmd);
    char *exec_path = strtok(cmd_copy, " ");
    char *exec_argv[16];
    int arg = 0;

    exec_argv[arg++] = exec_path;
    while ((exec_argv[arg] = strtok(NULL, " ")) != NULL)
        arg++;
    exec_argv[arg] = 0;
    if (exec_path)
        execvp(exec_path, exec_argv);

    // Not supposed to reach here.
    warn("execvp '%s' failed", cmd);
    exit(EXIT_FAILURE);
  } else {
    // parent
    int status;
    if (waitpid(pid, &status, 0) != pid) {
      warn("waitpid");
      return -1;
    }
    return status;
  }
}

static void drop_privileges()
{
  if (options.gid > 0) {
    debug("setting gid to %d", options.gid);

#ifndef UNITTEST
    OK_OR_FATAL(setgid(options.gid), "setgid failed");
#endif
  }
  if (options.uid > 0) {
    debug("setting uid to %d", options.uid);

#ifndef UNITTEST
    OK_OR_FATAL(setuid(options.uid), "setuid failed");
#endif
  }
}

static void child()
{
  setup_filesystems();

  // Locate everything needed to configure the environment
  // and pass to erlexec.
  // TODO

  // Set up the environment for running erlang.
  setup_environment();

  // Set up the minimum networking we need for Erlang.
  setup_networking();

  // Warn the user if they're on an inactive TTY
  if (options.warn_unused_tty)
    warn_unused_tty();

  // Optionally run a "pre-run" program
  if (options.pre_run_exec)
    run_cmd(options.pre_run_exec);

  // Optionally drop privileges
  drop_privileges();

  // Start Erlang up
  char erlexec_path[FANINIT_PATH_MAX];
  sprintf(erlexec_path, "/app/jre/bin/java");
  char *exec_path = erlexec_path;

  char *exec_argv[32];
  int arg = 0;
  exec_argv[arg++] = "java";

  // TODO
  exec_argv[arg++] = "-cp";
  exec_argv[arg++] = "/app/fan/lib/java/sys.jar";
  exec_argv[arg++] = "fanx.tools.Fan";
  exec_argv[arg++] = "fansh";
  exec_argv[arg] = NULL;

  if (options.verbose) {
    // Dump the environment and commandline
    extern char **environ;
    char** env = environ;
    while (*env != 0)
        debug("Env: '%s'", *env++);

    int i;
    for (i = 0; i < arg; i++)
      debug("Arg: '%s'", exec_argv[i]);
  }

  debug("Launching fantom...");
  if (options.print_timing)
    warn("stop");

  execvp(exec_path, exec_argv);

  // execvpe is not supposed to return
  fatal("execvp failed to run %s: %s", exec_path, strerror(errno));
}

static void signal_handler(int signum);

static void register_signal_handlers()
{
  struct sigaction act;

  act.sa_handler = signal_handler;
  sigemptyset(&act.sa_mask);
  act.sa_flags = 0;

  sigaction(SIGPWR, &act, NULL);
  sigaction(SIGUSR1, &act, NULL);
  sigaction(SIGTERM, &act, NULL);
  sigaction(SIGUSR2, &act, NULL);
}

static void unregister_signal_handlers()
{
  struct sigaction act;

  act.sa_handler = SIG_IGN;
  sigemptyset(&act.sa_mask);
  act.sa_flags = 0;

  sigaction(SIGPWR, &act, NULL);
  sigaction(SIGUSR1, &act, NULL);
  sigaction(SIGTERM, &act, NULL);
  sigaction(SIGUSR2, &act, NULL);
}

void signal_handler(int signum)
{
  switch (signum) {
  case SIGPWR:
  case SIGUSR1:
    desired_reboot_cmd = LINUX_REBOOT_CMD_HALT;
    break;
  case SIGTERM:
    desired_reboot_cmd = LINUX_REBOOT_CMD_RESTART;
    break;
  case SIGUSR2:
    desired_reboot_cmd = LINUX_REBOOT_CMD_POWER_OFF;
    break;
  default:
    warn("received unexpected signal %d", signum);
    desired_reboot_cmd = LINUX_REBOOT_CMD_RESTART;
    break;
  }

  // Handling the signal is a one-time action. Now we're done.
  unregister_signal_handlers();
}

static void kill_all()
{
  debug("kill_all");

#ifndef UNITTEST
  // Kill processes the nice way
  kill(-1, SIGTERM);
  warn("Sending SIGTERM to all processes");
  sync();

  sleep(1);

  // Brutal kill the stragglers
  kill(-1, SIGKILL);
  warn("Sending SIGKILL to all processes");
  sync();
#endif
}

int main(int argc, char *argv[])
{
#ifndef UNITTEST
  if (getpid() != 1)
    fatal("Refusing to run since not pid 1");
#else
  if (getpid() == 1)
    fatal("Trying to run unit test version of erlinit for real. This won't work.");
#endif

  // Merge the config file and the command line arguments
  static int merged_argc;
  static char *merged_argv[MAX_ARGC];
  merge_config(argc, argv, &merged_argc, merged_argv);

  parse_args(merged_argc, merged_argv);

  if (options.print_timing)
    warn("start");

  debug("Starting " PROGRAM_NAME " " PROGRAM_VERSION_STR "...");

  debug("cmdline argc=%d, merged argc=%d", argc, merged_argc);
  int i;
  for (i = 0; i < merged_argc; i++)
      debug("merged argv[%d]=%s", i, merged_argv[i]);

  // Mount /dev, /proc and /sys
  setup_pseudo_filesystems();

  // Fix the terminal settings so output goes to the right
  // terminal and the CTRL keys work in the shell..
  set_ctty();

  // Do most of the work in a child process so that if it
  // crashes, we can handle the crash.
  pid_t pid = fork();
  if (pid == 0) {
    child();
    exit(1);
  }

  // Register signal handlers to catch requests to exit
  register_signal_handlers();

  // Wait on Erlang until it exits or we receive a signal.
  int is_intentional_exit = 0;
  if (waitpid(pid, 0, 0) < 0) {
    debug("signal or error terminated waitpid. clean up");

    if (desired_reboot_cmd != 0) {
      // A signal is sent from commands like poweroff, reboot, and halt
      // This is usually intentional.
      is_intentional_exit = 1;
    } else {
      // If waitpid returns error and it wasn't from a handled signal, print a warning.
      warn("unexpected error from waitpid(): %s", strerror(errno));
      desired_reboot_cmd = options.unintentional_exit_cmd;
    }
  } else {
    debug("Java VM exited");

    desired_reboot_cmd = options.unintentional_exit_cmd;
  }

  // If the user specified a command to run on an unexpected exit, run it.
  if (options.run_on_exit && !is_intentional_exit)
    run_cmd(options.run_on_exit);

  // Exit everything that's still running.
  kill_all();

  // Unmount almost everything.
  unmount_all();

  // Sync just to be safe.
  sync();

  // See if the user wants us to halt or poweroff on an "unintentional" exit
  if (!is_intentional_exit &&
        options.unintentional_exit_cmd != LINUX_REBOOT_CMD_RESTART) {
    // Sometimes Erlang exits on initialization. Hanging on exit
    // makes it easier to debug these cases since messages don't
    // keep scrolling on the screen.
    warn("Not rebooting on exit as requested by the erlinit configuration...");

    // Make sure that the user sees the message.
    sleep(5);
  }

#ifndef UNITTEST
  // Reboot/poweroff/halt
  reboot(desired_reboot_cmd);
#endif

  // If we get here, oops the kernel.
  return 0;
}