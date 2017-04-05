/*
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    5 Apr 2017  Andy Frank  Creation
//
// Based on elixir_ale by Frank Hunleth:
// https://github.com/fhunleth/elixir_ale
*/

#include <err.h>
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include "linux/i2c-dev.h"
#include "../../common/src/log.h"
#include "../../common/src/pack.h"

#define I2C_BUFFER_MAX 8192

struct i2c_info
{
  int fd;
};

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
  if (pack_write(stdout, res) < 0) log_debug("fani2c: send_ok failed");
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
  if (pack_write(stdout, res) < 0) log_debug("fani2c: send_ok_data failed");
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
  if (pack_write(stdout, res) < 0) log_debug("fani2c: send_err failed");
  pack_map_free(res);
}

//////////////////////////////////////////////////////////////////////////
// I2C
//////////////////////////////////////////////////////////////////////////

static void i2c_init(struct i2c_info *i2c, const char *devpath)
{
  // Fail hard on error. May need to be nicer if this makes the
  // Fantom side too hard to debug.
  i2c->fd = open(devpath, O_RDWR);
  if (i2c->fd < 0) err(EXIT_FAILURE, "open %s", devpath);
}

/**
 * @brief I2C combined write/read operation
 *
 * This function can be used to individually read or write
 * bytes across the bus. Additionally, a write and read
 * operation can be combined into one transaction. This is
 * useful for communicating with register-based devices that
 * support setting the current register via the first one or
 * two bytes written.
 *
 * @param  addr          The device address
 * @param  to_write      Optional write buffer
 * @param  to_write_len  Write buffer length
 * @param  to_read       Optional read buffer
 * @param  to_read_len   Read buffer length
 *
 * @return  1 for success, 0 for failure
 */
static int i2c_transfer(const struct i2c_info *i2c,
                        unsigned int addr,
                        const char *to_write, size_t to_write_len,
                        char *to_read, size_t to_read_len)
{
  struct i2c_rdwr_ioctl_data data;
  struct i2c_msg msgs[2];

  msgs[0].addr = addr;
  msgs[0].flags = 0;
  msgs[0].len = to_write_len;
  msgs[0].buf = (uint8_t *) to_write;

  msgs[1].addr = addr;
  msgs[1].flags = I2C_M_RD;
  msgs[1].len = to_read_len;
  msgs[1].buf = (uint8_t *) to_read;

  if (to_write_len != 0)
    data.msgs = &msgs[0];
  else
    data.msgs = &msgs[1];

  data.nmsgs = (to_write_len != 0 && to_read_len != 0) ? 2 : 1;

  int rc = ioctl(i2c->fd, I2C_RDWR, &data);
  if (rc < 0)
    return 0;
  else
    return 1;
}

//////////////////////////////////////////////////////////////////////////
// Pack
//////////////////////////////////////////////////////////////////////////

/*
 * Status check.
 */
static void on_status(struct i2c_info *i2c, struct pack_map *req)
{
  // debug
  char *d = pack_debug(req);
  log_debug("fani2c: on_status %s", d);
  free(d);

  send_ok();
}

/*
 * Read data.
 */
static void on_read(struct i2c_info *i2c, struct pack_map *req)
{
  // debug
  char *d = pack_debug(req);
  log_debug("fani2c: on_read %s", d);
  free(d);

  uint8_t addr = pack_get_int(req, "addr");
  uint16_t len = pack_get_int(req, "len");

  // check inputs
  if (addr > 127) { send_err("invalid 'addr' field"); return; }
  if (len <= 1 || len > I2C_BUFFER_MAX) { send_err("invalid 'len' field"); return; }

  char data[I2C_BUFFER_MAX];
  if (i2c_transfer(i2c, addr, 0, 0, data, len))
    send_ok_data((uint8_t*)data, len);
  else
    send_err("i2c_read failed");
}

/*
 * Write data.
 */
static void on_write(struct i2c_info *i2c, struct pack_map *req)
{
  // debug
  char *d = pack_debug(req);
  log_debug("fani2c: on_write %s", d);
  free(d);

  uint8_t addr  = pack_get_int(req, "addr");
  uint16_t len  = pack_get_int(req, "len");
  uint8_t *data = pack_get_buf(req, "data");

  // check inputs
  if (addr > 127) { send_err("invalid 'addr' field"); return; }
  if (len <= 1 || len > I2C_BUFFER_MAX) { send_err("invalid 'len' field"); return; }
  if (data == NULL) { send_err("missing or invalid 'data' field"); return; }

  if (i2c_transfer(i2c, addr, (char *)data, len, 0, 0))
    send_ok();
  else
    send_err("i2c_write failed");
}

/*
 * Callback to process an incoming Fantom request.
 * Returns -1 if process should exit, or 0 to continue.
 */
static int on_proc_req(struct i2c_info *i2c, struct pack_map *req)
{
  char *op = pack_get_str(req, "op");

  if (strcmp(op, "read")   == 0) { on_read(i2c, req);   return 0; }
  if (strcmp(op, "write")  == 0) { on_write(i2c, req);  return 0; }
  if (strcmp(op, "status") == 0) { on_status(i2c, req); return 0; }
  if (strcmp(op, "exit")   == 0) { return -1; }

  log_debug("fani2c: unknown op '%s'", op);
  return 0;
}

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

int main(int argc, char *argv[])
{
  if (argc != 2) log_fatal("Must pass device path");

  struct i2c_info i2c;
  i2c_init(&i2c, argv[1]);

  struct pack_buf *buf = pack_buf_new();
  log_debug("fani2c: open %s", argv[1]);

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
      log_debug("fani2c: pack_read failed");
      pack_buf_clear(buf);
    }
    else if (buf->ready)
    {
      struct pack_map *req = pack_decode(buf->bytes);
      int r = on_proc_req(&i2c, req);
      pack_map_free(req);
      pack_buf_clear(buf);
      if (r < 0) break;
    }
  }

  // graceful exit
  log_debug("fani2c: bye-bye");
  return 0;
}