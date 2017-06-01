/*
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    1 Jun 2017  Andy Frank  Creation
*/

#include <err.h>
#include <errno.h>
// #include <fcntl.h>
#include <poll.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <unistd.h>
#include <netinet/in.h>
#include <net/if.h>
#include <net/if_arp.h>

#include "../../common/src/log.h"
#include "../../common/src/pack.h"

// From Nerves.NetworkInterface:
// https://github.com/nerves-project/nerves_network_interface
//
// In Ubuntu 16.04, it seems that the new compat logic handling is preventing
// IFF_LOWER_UP from being defined properly. It looks like a bug, so define it
// here so that this file compiles.  A scan of all Nerves platforms and Ubuntu
// 16.04 has IFF_LOWER_UP always being set to 0x10000. this being defined as
// 0x10000.
#define WORKAROUND_IFF_LOWER_UP (0x10000)

//////////////////////////////////////////////////////////////////////////
// Helpers
//////////////////////////////////////////////////////////////////////////

// /*
//  * Send an ok pack response to stdout.
//  */
// static void send_ok()
// {
//   struct pack_map *res = pack_map_new();
//   pack_set_str(res, "status", "ok");
//   if (pack_write(stdout, res) < 0) log_debug("fannet: send_ok failed");
//   pack_map_free(res);
// }

/*
 * Send an error pack response to stdout.
 */
static void send_err(char *msg)
{
  struct pack_map *res = pack_map_new();
  pack_set_str(res, "status", "err");
  pack_set_str(res, "msg",    msg);
  if (pack_write(stdout, res) < 0) log_debug("fannet: send_err failed");
  pack_map_free(res);
}

//////////////////////////////////////////////////////////////////////////
// Pack
//////////////////////////////////////////////////////////////////////////

/*
 * Return list of available network interfaces.
 */
static void on_list(struct pack_map *req)
{
  // debug
  char *d = pack_debug(req);
  log_debug("fannet: on_list %s", d);
  free(d);

  struct if_nameindex *s = if_nameindex();
  if (s == NULL) { send_err("if_nameindex failed"); return; }

  struct pack_map *res = pack_map_new();
  struct if_nameindex *i = s;
  for (; !(i->if_index == 0 && i->if_name == NULL); i++)
    pack_set_int(res, i->if_name, i->if_index);
  if_freenameindex(s);

  // write resp
  if (pack_write(stdout, res) < 0) log_debug("fannet: on_list write failed");
  pack_map_free(res);
}

/*
 * Return status information about an interface.
 */
static void on_status(struct pack_map *req)
{
  // debug
  char *d = pack_debug(req);
  log_debug("fannet: on_status %s", d);
  free(d);

  char *name = pack_get_str(req, "name");
  if (name == NULL) { send_err("missing 'name'"); return; }

  // open socket
  int h = socket(AF_INET, SOCK_DGRAM, IPPROTO_IP);
  if (h < 0) { send_err("socket failed"); return; }

  // read ifreq
  struct ifreq s;
  strncpy(s.ifr_name, name, sizeof(s.ifr_name));
  int r = ioctl(h, SIOCGIFFLAGS, &s);
  close(h);
  if (r == -1) { send_err("ioctl failed"); return; }

  // pack
  struct pack_map *res = pack_map_new();
  pack_set_str(res,  "status",       "ok");
  pack_set_str(res,  "name",         name);
  pack_set_int(res,  "index",        s.ifr_ifindex);
  pack_set_str(res,  "type",         s.ifr_hwaddr.sa_family == ARPHRD_ETHER ? "ethernet" : "other");
  pack_set_bool(res, "up",           s.ifr_flags & IFF_UP);
  pack_set_bool(res, "broadcast",    s.ifr_flags & IFF_BROADCAST);
  pack_set_bool(res, "loopback",     s.ifr_flags & IFF_LOOPBACK);
  pack_set_bool(res, "pointtopoint", s.ifr_flags & IFF_POINTOPOINT);
  pack_set_bool(res, "running",      s.ifr_flags & IFF_RUNNING);
  pack_set_bool(res, "multicast",    s.ifr_flags & IFF_MULTICAST);
  pack_set_bool(res, "lowerup",      s.ifr_flags & WORKAROUND_IFF_LOWER_UP);
  pack_set_int(res,  "mtu",          s.ifr_mtu);
  pack_set_buf(res,  "mac",          (uint8_t*)s.ifr_hwaddr.sa_data, 6);

  // write resp
  if (pack_write(stdout, res) < 0) log_debug("fannet: on_status write failed");
  pack_map_free(res);
}

/*
 * Callback to process an incoming Fantom request.
 * Returns -1 if process should exit, or 0 to continue.
 */
static int on_proc_req(struct pack_map *req)
{
  char *op = pack_get_str(req, "op");

  if (strcmp(op, "status") == 0) { on_status(req); return 0; }
  if (strcmp(op, "list")   == 0) { on_list(req);   return 0; }
  if (strcmp(op, "exit")   == 0) { return -1; }

  log_debug("fannet: unknown op '%s'", op);
  return 0;
}

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

int main(int argc, char *argv[])
{
  struct pack_buf *buf = pack_buf_new();

  for (;;)
  {
    struct pollfd fdset[3];

    fdset[0].fd = STDIN_FILENO;
    fdset[0].events = POLLIN;
    fdset[0].revents = 0;

    int rc = poll(fdset, 1, -1);
    if (rc < 0)
    {
      // Retry if EINTR
      if (errno == EINTR) continue;
      log_fatal("poll");
    }

    if (fdset[0].revents & (POLLIN | POLLHUP))
    {
      // read message
      if (pack_read(stdin, buf) < 0)
      {
        log_debug("fannet: pack_read failed");
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

  // graceful exit
  log_debug("fannet: bye-bye");
  return 0;
}
