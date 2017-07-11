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

#ifndef FANINIT_H
#define FANINIT_H

#define PROGRAM_NAME "faninit"
#ifndef PROGRAM_VERSION
#define PROGRAM_VERSION unknown
#endif

#define xstr(s) str(s)
#define str(s) #s
#define PROGRAM_VERSION_STR xstr(PROGRAM_VERSION)

#define FANINIT_PROPS "/etc/faninit.props"
#define FAN_HOME "/app/fan"
#define JAVA_HOME "/app/jre"

// This is the maximum number of mounted filesystems that
// is expected in a running system. It is used on shutdown
// when trying to unmount everything gracefully.
#define MAX_MOUNTS 32

#define MAX_ARGC 32

// PATH_MAX wasn't in the musl include files, so rather
// than pulling an arbitrary number in from linux/limits.h,
// just define to something that should be trivially safe
// for faninit use.
#define FANINIT_PATH_MAX 1024

struct prop {
  const char* name;
  const char* val;
  struct prop* next;
};

struct prop* props;

struct erlinit_options {
  int verbose;
  int print_timing;
  int unintentional_exit_cmd; // Invoked when jvm exits. See linux/reboot.h for options
  int fatal_reboot_cmd;       // Invoked on fatal() log message. See linux/reboot.h for options
  int warn_unused_tty;
  char *controlling_terminal;
  char *alternate_exec;
  char *uniqueid_exec;
  char *hostname_pattern;
  char *additional_env;
  char *release_search_path;
  char *extra_mounts;
  char *run_on_exit;
  char *pre_run_exec;
  int uid;
  int gid;
};

extern struct erlinit_options options;

// Logging functions
void debug(const char *fmt, ...);
void warn(const char *fmt, ...);
void fatal(const char *fmt, ...);

#define OK_OR_FATAL(WORK, MSG, ...) do { if ((WORK) < 0) fatal(MSG, ## __VA_ARGS__); } while (0)
#define OK_OR_WARN(WORK, MSG, ...) do { if ((WORK) < 0) warn(MSG, ## __VA_ARGS__); } while (0)

// Props
struct prop* read_props(const char* filename);
const char* get_prop(struct prop* props, const char* name, const char* def);

// Configuration loading
void merge_config(int argc, char *argv[], int *merged_argc, char **merged_argv);

// Argument parsing
void parse_args(int argc, char *argv[]);

// Networking
void setup_networking();

// Filesystems
void setup_pseudo_filesystems();
void setup_filesystems();
void unmount_all();

// Terminal
void set_ctty();
void warn_unused_tty();

#endif // FANINIT_H
