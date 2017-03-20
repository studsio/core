/*
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Jan 2017  Andy Frank  Creation
//
// Based on nerves_uart by Frank Hunleth:
// https://github.com/nerves-project/nerves_uart
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <poll.h>
#include <unistd.h>
#include "../../common/src/log.h"
#include "../../common/src/pack.h"
#include "uart_enum.h"
#include "uart_comm.h"

static struct uart *uart = NULL;
static struct uart_config cur_config;

static uint8_t empty_buf[] = {};
static char err_msg[128];

//////////////////////////////////////////////////////////////////////////
// Helpers
//////////////////////////////////////////////////////////////////////////

/*
 * Send an ok pack response to stdout.
 */
static void send_ok()
{
  struct pack_map *res = pack_map_new();
  pack_sets(res, "status", "ok");
  if (pack_write(stdout, res) < 0) log_debug("fanuart: send_ok failed");
  pack_map_free(res);
}

/*
 * Send an ok pack response with a data buffer to stdout.
 */
static void send_ok_data(uint8_t *buf, uint16_t len)
{
  struct pack_map *res = pack_map_new();
  pack_sets(res, "status", "ok");
  pack_seti(res, "len",    len);
  pack_setd(res, "data",   uart->read_buffer, len);
  if (pack_write(stdout, res) < 0) log_debug("fanuart: send_ok_data failed");
  pack_map_free(res);
}

/*
 * Send an error pack response to stdout.
 */
static void send_err(char *msg)
{
  struct pack_map *res = pack_err(msg);
  if (pack_write(stdout, res) < 0) log_debug("fanuart: send_err failed");
  pack_map_free(res);
}

//////////////////////////////////////////////////////////////////////////
// Enum
//////////////////////////////////////////////////////////////////////////

/*
 * Enumerate the available serial ports.
 */
static void enum_ports()
{
  struct serial_info *port_list = find_serialports();
  struct pack_map *map = pack_map_new();

  for (struct serial_info *port=port_list; port != NULL; port=port->next)
  {
    struct pack_map *m = pack_map_new();
    if (port->description)   pack_sets(m, "desc",    port->description);
    if (port->manufacturer)  pack_sets(m, "man",     port->manufacturer);
    if (port->serial_number) pack_sets(m, "ser_num", port->serial_number);
    if (port->vid)           pack_seti(m, "vid",     port->vid);
    if (port->pid)           pack_seti(m, "pid",     port->pid);
    pack_setm(map, port->name, m);
  }

  pack_write(stdout, map);

  serial_info_free_list(port_list);
  pack_map_free(map);
}

//////////////////////////////////////////////////////////////////////////
// Callback handlers
//////////////////////////////////////////////////////////////////////////

/*
 * Parse uart_config from pack_map.
 */
static void parse_config(struct pack_map *m, struct uart_config *config)
{
  // TODO
  // if (pack_has("speed")) config->speed = pack_geti(m, "speed");
  // if (pack_has("data")) config->data_bits = 8;
  // if (pack_has("stop")) config->stop_bits = 1;
  // if (pack_has("parity")) config->parity = UART_PARITY_NONE;
  // if (pack_has("flow")) config->flow_control = UART_FLOWCONTROL_NONE;
}

/*
 * Open serial port.
 */
static void on_open(struct pack_map *req)
{
  // debug
  char *d = pack_debug(req);
  log_debug("fanuart: on_open %s", d);
  free(d);

  // check name
  if (!pack_has(req, "name")) { send_err("missing 'name' field"); return; }
  char *name = pack_gets(req, "name");

  // check config
  struct uart_config config = cur_config;
  parse_config(req, &config);

  // if uart already open, close and open it again
  if (uart_is_open(uart)) uart_close(uart);

  // open
  if (uart_open(uart, name, &config) >= 0)
  {
    cur_config = config;
    send_ok();
  }
  else
  {
    send_err((char *)uart_last_error());
  }
}

/*
 * Close serial port.
 */
static void on_close(struct pack_map *req)
{
  // debug
  char *d = pack_debug(req);
  log_debug("fanuart: on_close %s", d);
  free(d);

  // close of open
  if (uart_is_open(uart)) uart_close(uart);
  send_ok();
}

/*
 * Read bytes from serial port.
 */
static void on_read(struct pack_map *req)
{
  // debug
  char *d = pack_debug(req);
  log_debug("fanuart: on_read %s", d);
  free(d);

  // verify open
  if (!uart_is_open(uart))
  {
    send_err("port not open");
    return;
  }

  struct pollfd fdset[1];
  fdset[0].fd = uart->fd;
  fdset[0].events = POLLIN;
  fdset[0].revents = 0;
  int timeout = 10000; // 10sec

  // wait until timeout for data to be available
  int c = poll(fdset, 1, timeout);
  if (c < 0)
  {
    if (errno == EINTR)
    {
      // ok if interrupted -- return we read zero bytes
      send_ok_data(empty_buf, 0);
      return;
    }
    else
    {
      // send_err(why)
      send_err("TODO");
      return;
    }
  }
  if (c == 0)
  {
    send_err("Read timed out");
    return;
  }

  // read available data
  ssize_t len;
  do {
    len = read(uart->fd, uart->read_buffer, sizeof(uart->read_buffer));
  } while (len < 0 && errno == EINTR);

  // send response
  if (len > 0)
  {
    send_ok_data(uart->read_buffer, len);
  }
  else if (len == 0 || (len < 0 && errno == EAGAIN))
  {
    // nothing to read
    send_ok_data(empty_buf, 0);
  }
  else
  {
    // unrecoverable error
    uart_close(uart);
    sprintf(err_msg, "Read failed [err=%d]", errno);
    send_err(err_msg);
  }
}

/*
 * Write bytes to serial port.
 */
static void on_write(struct pack_map *req)
{
  // debug
  char *d = pack_debug(req);
  log_debug("fanuart: on_write %s", d);
  free(d);

  // TODO
  send_ok();
}

/*
 * Callback to process an incoming Fantom request.
 * Returns -1 if process should exit, or 0 to continue.
 */
static int on_proc_req(struct pack_map *req)
{
  char *op = pack_gets(req, "op");

  if (strcmp(op, "read")  == 0) { on_read(req);  return 0; }
  if (strcmp(op, "write") == 0) { on_write(req); return 0; }
  if (strcmp(op, "open")  == 0) { on_open(req);  return 0; }
  if (strcmp(op, "close") == 0) { on_close(req); return 0; }
  if (strcmp(op, "exit")  == 0) { return -1; }

  log_debug("fanuart: unknown op '%s'", op);
  return 0;
}

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

static void on_write_completed(int rc, const uint8_t *data) {}
static void on_read_completed(int rc, const uint8_t *data, size_t len) {}
static void on_notify_read(int rc, const uint8_t *data, size_t len) {}

/*
 * Main process loop.
 */
static void main_loop()
{
  // init uart
  uart_default_config(&cur_config);
  if (uart_init(&uart, on_write_completed, on_read_completed, on_notify_read) < 0)
    log_fatal("uart_init failed");

  struct pack_buf *buf = pack_buf_new();

  for (;;)
  {
    struct pollfd fdset[1];
    fdset[0].fd = STDIN_FILENO;
    fdset[0].events = POLLIN;
    fdset[0].revents = 0;

    // wait for stdin message
    int rc = poll(fdset, 1, -1);
    if (rc < 0)
    {
      // Retry if EINTR
      if (errno == EINTR) continue;
      log_fatal("poll");
    }

    // read message
    if (pack_read(stdin, buf) < 0)
    {
      log_debug("fanuart: pack_read failed");
      pack_buf_clear(buf);
    }
    else if (buf->ready)
    {
      struct pack_map *req = pack_decode(buf->bytes);
      int r = on_proc_req(req);
      pack_map_free(req);
      pack_buf_clear(buf);
      if (r < 0) break;
    }
  }

  // graceful exit
  if (uart_is_open(uart)) uart_flush_all(uart);
  log_debug("fanuart: bye-bye");
}

/*
 * Entry-point
 */
int main(int argc, char *argv[])
{
  if (argc == 1)
  {
    main_loop();
  }
  else if (argc == 2 && strcmp(argv[1], "enum") == 0)
  {
    enum_ports();
  }
  else
  {
    log_err("usage: %s [enum]", argv[0]);
    exit(1);
  }
  return 0;
}
