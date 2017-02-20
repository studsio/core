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
#include <err.h>
#include "../../common/src/pack.h"
#include "uart_enum.h"

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

  pack_write(map, stdout);

  serial_info_free_list(port_list);
  pack_map_free(map);
}

int main() //int argc, char *argv[])
{
  enum_ports();
  return 0;
}
