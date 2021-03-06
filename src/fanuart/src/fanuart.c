/*
// Copyright (c) 2017, Andy Frank
// Licensed under the Apache License version 2.0
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
  pack_set_str(res, "status", "ok");
  if (pack_write(stdout, res) < 0) log_debug("fanuart: send_ok failed");
  pack_map_free(res);
}

/*
 * Send an ok pack response with a data buffer to stdout.
 */
static void send_ok_data(uint8_t *buf, uint16_t len)
{
  struct pack_map *res = pack_map_new();
  pack_set_str(res, "status", "ok");
  pack_set_int(res, "len",    len);
  pack_set_buf(res, "data",   buf, len);
  if (pack_write(stdout, res) < 0) log_debug("fanuart: send_ok_data failed");
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
    if (port->description)   pack_set_str(m, "desc",    port->description);
    if (port->manufacturer)  pack_set_str(m, "man",     port->manufacturer);
    if (port->serial_number) pack_set_str(m, "ser_num", port->serial_number);
    if (port->vid)           pack_set_int(m, "vid",     port->vid);
    if (port->pid)           pack_set_int(m, "pid",     port->pid);
    pack_set_map(map, port->name, m);
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
  if (pack_has(m, "speed")) config->speed     = pack_get_int(m, "speed");
  if (pack_has(m, "data"))  config->data_bits = pack_get_int(m, "data");
  if (pack_has(m, "stop"))  config->stop_bits = pack_get_int(m, "stop");
  if (pack_has(m, "parity"))
  {
    char *p = pack_get_str(m, "parity");
         if (strcmp(p, "none") == 0) config->parity = UART_PARITY_NONE;
    else if (strcmp(p, "even") == 0) config->parity = UART_PARITY_EVEN;
    else if (strcmp(p, "odd")  == 0) config->parity = UART_PARITY_ODD;
  }
  if (pack_has(m, "flow"))
  {
    char *f = pack_get_str(m, "flow");
         if (strcmp(f, "none") == 0) config->flow_control = UART_FLOWCONTROL_NONE;
    else if (strcmp(f, "hw")   == 0) config->flow_control = UART_FLOWCONTROL_HARDWARE;
    else if (strcmp(f, "sw")   == 0) config->flow_control = UART_FLOWCONTROL_SOFTWARE;
  }
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
  char *name = pack_get_str(req, "name");

  // check config
  struct uart_config config = cur_config;
  parse_config(req, &config);
  log_debug("fanuart: parse_config speed=%d data=%d stop=%d parity=%d flow=%d",
    config.speed, config.data_bits, config.stop_bits, config.parity, config.flow_control);

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

  // verify open
  if (!uart_is_open(uart))
  {
    send_err("port not open");
    return;
  }

  uint16_t len  = pack_get_int(req, "len");
  uint8_t *data = pack_get_buf(req, "data");
  ssize_t written = 0, w = 0;

  if (len  <= 0)    { send_err("missing or invalid 'len' field"); return;  }
  if (data == NULL) { send_err("missing or invalid 'data' field"); return; }

  // loop until all bytes written
  while (written < len)
  {
    do {
      w = write(uart->fd, data+written, len-written);
      log_debug("fanuart: wrote %d/%d, errno=%d (%s) data=%p, fd=%d",
        (int)len, (int)len, errno, strerror(errno), data, uart->fd);
    } while (w < 0 && errno == EINTR);

    // write failed
    if (w < 0) { send_err("write failed"); return; }

    written += w;
  }

  send_ok();
}

/*
 * Callback to process an incoming Fantom request.
 * Returns -1 if process should exit, or 0 to continue.
 */
static int on_proc_req(struct pack_map *req)
{
  char *op = pack_get_str(req, "op");

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
