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

/*
 * Open serial port.
 */
static void on_open(struct pack_map *req)
{
  char *d = pack_debug(req);
  log_debug("fanuart: on_open %s", d);
  free(d);

  struct pack_map *res;
  res = pack_err("open: not yet implemented");
  pack_write(stdout, res);
  pack_map_free(res);
}

/*
 * Close serial port.
 */
static void on_close(struct pack_map *req)
{
  char *d = pack_debug(req);
  log_debug("fanuart: on_close %s", d);
  free(d);

  struct pack_map *res;
  res = pack_err("close: not yet implemented");
  pack_write(stdout, res);
  pack_map_free(res);
}

/*
 * Callback to process an incoming Fantom request.
 * Returns -1 if process should exit, or 0 to continue.
 */
static int on_proc_req(struct pack_map *req)
{
  char *op = pack_gets(req, "op");

  if (strcmp(op, "open")  == 0) { on_open(req);  return 0; }
  if (strcmp(op, "close") == 0) { on_close(req); return 0; }
  if (strcmp(op, "exit")  == 0) { return -1; }

  log_debug("fanuart: unknown op '%s'", op);
  return 0;
}

/*
 * Main process loop.
 */
static void main_loop()
{
  struct pack_buf *buf = pack_buf_new();

  for (;;)
  {
    struct pollfd fdset[3];

    fdset[0].fd = STDIN_FILENO;
    fdset[0].events = POLLIN;
    fdset[0].revents = 0;

    int timeout = -1; // Wait forever unless told by otherwise
    int count = 0; //uart_add_poll_events(uart, &fdset[1], &timeout);

    int rc = poll(fdset, count + 1, timeout);
    if (rc < 0)
    {
      // Retry if EINTR
      if (errno == EINTR) continue;
      log_fatal("poll");
    }

    if (fdset[0].revents & (POLLIN | POLLHUP))
    {
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
  }

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
