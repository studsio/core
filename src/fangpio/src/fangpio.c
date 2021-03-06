/*
// Copyright (c) 2017, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   30 Mar 2017  Andy Frank  Creation
//
// Based on elixir_ale by Frank Hunleth:
// https://github.com/fhunleth/elixir_ale
*/

#include <errno.h>
#include <err.h>
#include <poll.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include "../../common/src/log.h"
#include "../../common/src/pack.h"

//////////////////////////////////////////////////////////////////////////
// Structs
//////////////////////////////////////////////////////////////////////////

enum gpio_state {
  GPIO_OUTPUT,
  GPIO_INPUT,
  GPIO_INPUT_WITH_INTERRUPTS
};

struct gpio {
  enum gpio_state state;
  int fd;
  int pin_number;
};

//////////////////////////////////////////////////////////////////////////
// Helpers
//////////////////////////////////////////////////////////////////////////

/**
 * @brief write a string to a sysfs file
 * @return returns 0 on failure, >0 on success
 */
static int sysfs_write_file(const char *pathname, const char *value)
{
  int fd = open(pathname, O_WRONLY);
  if (fd < 0) {
    log_debug("Error opening %s", pathname);
    return 0;
  }

  size_t count = strlen(value);
  ssize_t written = write(fd, value, count);
  close(fd);

  if (written < 0 || (size_t) written != count) {
    log_debug("Error writing '%s' to %s", value, pathname);
    return 0;
  }

  return written;
}

/*
 * Send an ok pack response to stdout.
 */
static void send_ok()
{
  struct pack_map *res = pack_map_new();
  pack_set_str(res, "status", "ok");
  if (pack_write(stdout, res) < 0) log_debug("fangpio: send_ok failed");
  pack_map_free(res);
}

/*
 * Send an error pack response to stdout.
 */
static void send_err(char *msg)
{
  struct pack_map *res = pack_map_new();
  pack_set_str(res, "status", "err");
  pack_set_str(res, "msg",    msg);
  if (pack_write(stdout, res) < 0) log_debug("fangpio: send_err failed");
  pack_map_free(res);
}

//////////////////////////////////////////////////////////////////////////
// GPIO functions
//////////////////////////////////////////////////////////////////////////

/**
 * @brief  Open and configure a GPIO
 *
 * @param  pin         The pin structure
 * @param  pin_number  The GPIO pin
 * @param  dir         Direction of pin (in or out)
 *
 * @return  1 for success, -1 for failure
 */
static int gpio_init(struct gpio *pin, unsigned int pin_number, enum gpio_state dir)
{
  // Initialize the pin structure
  pin->state = dir;
  pin->fd = -1;
  pin->pin_number = pin_number;

  // Construct the gpio control file paths
  char direction_path[64];
  sprintf(direction_path, "/sys/class/gpio/gpio%d/direction", pin_number);

  char value_path[64];
  sprintf(value_path, "/sys/class/gpio/gpio%d/value", pin_number);

  // Check if the gpio has been exported already
  if (access(value_path, F_OK) == -1) {
    // Nope. Export it.
    char pinstr[64];
    sprintf(pinstr, "%d", pin_number);
    if (!sysfs_write_file("/sys/class/gpio/export", pinstr))
      return -1;
  }

  // The direction file may not exist if the pin only works one way.
  // It is ok if the direction file doesn't exist, but if it does
  // exist, we must be able to write it.
  if (access(direction_path, F_OK) != -1)
  {
    const char *dir_string = (dir == GPIO_OUTPUT ? "out" : "in");

    // Writing the direction fails on a Raspberry Pi in what looks
    // like a race condition with exporting the GPIO. Poll until it
    // works as a workaround.
    int retries = 1000;  // Allow 1000 * 1 ms = 1 second max for retries

    while (!sysfs_write_file(direction_path, dir_string) && retries > 0)
    {
      usleep(1000);
      retries--;
    }

    if (retries == 0) return -1;
  }

  pin->pin_number = pin_number;

  // Open the value file for quick access later
  pin->fd = open(value_path, pin->state == GPIO_OUTPUT ? O_RDWR : O_RDONLY);
  if (pin->fd < 0)
    return -1;

  return 1;
}

/**
 * @brief  Set pin with the value "0" or "1"
 *
 * @param  pin    The pin structure
 * @param  value  Value to set (0 or 1)
 *
 * @return  1 for success, -1 for failure
 */
static int gpio_write(struct gpio *pin, unsigned int val)
{
  if (pin->state != GPIO_OUTPUT)
    return -1;

  char buf = val ? '1' : '0';
  ssize_t amount_written = pwrite(pin->fd, &buf, sizeof(buf), 0);
  if (amount_written < (ssize_t) sizeof(buf))
    log_fatal("pwrite");

  return 1;
}

/**
* @brief  Read the value of the pin
*
* @param  pin  The GPIO pin
*
* @return  The pin value if success, -1 for failure
*/
static int gpio_read(struct gpio *pin)
{
  char buf;
  ssize_t amount_read = pread(pin->fd, &buf, sizeof(buf), 0);
  if (amount_read < (ssize_t) sizeof(buf))
    log_fatal("pread");

  return buf == '1' ? 1 : 0;
}

/**
 * Set isr as the interrupt service routine (ISR) for the pin. Mode
 * should be one of the strings "rising", "falling" or "both" to
 * indicate which edge(s) the ISR is to be triggered on. The function
 * isr is called whenever the edge specified occurs, receiving as
 * argument the number of the pin which triggered the interrupt.
 *
 * @param   pin   Pin number to attach interrupt to
 * @param   mode  Interrupt mode
 *
 * @return  Returns 1 on success.
 */
static int gpio_set_int(struct gpio *pin, const char *mode)
{
  char path[64];
  sprintf(path, "/sys/class/gpio/gpio%d/edge", pin->pin_number);
  if (!sysfs_write_file(path, mode))
    return -1;

  if (strcmp(mode, "none") == 0)
    pin->state = GPIO_INPUT;
  else
    pin->state = GPIO_INPUT_WITH_INTERRUPTS;

  return 1;
}

//////////////////////////////////////////////////////////////////////////
// Pack
//////////////////////////////////////////////////////////////////////////

/*
 * Send current state of GPIO pin.
 */
static void on_gpio(struct gpio *pin)
{
  int val = gpio_read(pin);
  struct pack_map *res = pack_map_new();
  pack_set_str(res, "status", "ok");
  pack_set_bool(res, "val", val);
  if (pack_write(stdout, res) < 0) log_debug("fangpio: on_read failed");
  pack_map_free(res);
}

/*
 * Send current state of GPIO pin.
 */
static void on_read(struct pack_map *req, struct gpio *pin)
{
  // debug
  char *d = pack_debug(req);
  log_debug("fangpio: on_read %s", d);
  free(d);

  // read and return pin value
  on_gpio(pin);
}

/*
 * Write current state of GPIO pin.
 */
static void on_write(struct pack_map *req, struct gpio *pin)
{
  // debug
  char *d = pack_debug(req);
  log_debug("fangpio: on_write %s", d);
  free(d);

  // set pin value
  if (!pack_has(req, "val")) { send_err("missing 'val' field"); return; }
  bool val = pack_get_bool(req, "val");
  gpio_write(pin, val);
  send_ok();
}

/*
 * Register interrupt handler for GPIO pin changes.
 */
static void on_listen(struct pack_map *req, struct gpio *pin)
{
  // debug
  char *d = pack_debug(req);
  log_debug("fangpio: on_listen %s", d);
  free(d);

  char *mode = pack_get_str(req, "mode");
  if (mode == NULL) { send_err("missing or invalid 'mode' field"); return; }

  if (gpio_set_int(pin, mode)) send_ok();
  else send_err("listen failed");
}

/*
 * Callback to process an incoming Fantom request.
 * Returns -1 if process should exit, or 0 to continue.
 */
static int on_proc_req(struct pack_map *req, struct gpio *pin)
{
  char *op = pack_get_str(req, "op");

  if (strcmp(op, "read")   == 0) { on_read(req, pin);   return 0; }
  if (strcmp(op, "write")  == 0) { on_write(req, pin);  return 0; }
  if (strcmp(op, "listen") == 0) { on_listen(req, pin); return 0; }
  if (strcmp(op, "exit")   == 0) { return -1; }

  log_debug("fangpio: unknown op '%s'", op);
  return 0;
}

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

int main(int argc, char *argv[])
{
  // sanity checks
  if (argc != 3) log_fatal("%s <pin#> <in|out>", argv[0]);

  int pin_number = strtol(argv[1], NULL, 0);
  enum gpio_state initial_state = GPIO_INPUT;
  if (strcmp(argv[2], "in") == 0)
    initial_state = GPIO_INPUT;
  else if (strcmp(argv[2], "out") == 0)
    initial_state = GPIO_OUTPUT;
  else
    log_fatal("Specify 'in' or 'out'");

  struct gpio pin;
  if (gpio_init(&pin, pin_number, initial_state) < 0)
    log_fatal("Error initializing GPIO %d as %s", pin_number, argv[2]);

  struct pack_buf *buf = pack_buf_new();

  log_debug("fangpio: started @ %d %s", pin_number, argv[2]);

  for (;;)
  {
    struct pollfd fdset[2];

    fdset[0].fd = STDIN_FILENO;
    fdset[0].events = POLLIN;
    fdset[0].revents = 0;

    fdset[1].fd = pin.fd;
    fdset[1].events = POLLPRI;
    fdset[1].revents = 0;

    // always fill out the fdset structure, but only have poll()
    // monitor the sysfs file if interrupts are enabled
    int rc = poll(fdset, pin.state == GPIO_INPUT_WITH_INTERRUPTS ? 2 : 1, -1);
    if (rc < 0) {
      // Retry if EINTR
      if (errno == EINTR) continue;
      log_fatal("poll");
    }

    // check stdin
    if (fdset[0].revents & (POLLIN | POLLHUP))
    {
      // read message
      if (pack_read(stdin, buf) < 0)
      {
        log_debug("fangpio: pack_read failed");
        pack_buf_clear(buf);
      }
      else if (buf->ready)
      {
        struct pack_map *req = pack_decode(buf->bytes);
        int r = on_proc_req(req, &pin);
        pack_map_free(req);
        pack_buf_clear(buf);
        if (r < 0) break;
      }
    }

    // push state change
    if (fdset[1].revents & POLLPRI) on_gpio(&pin);
  }

  return 0;
}
