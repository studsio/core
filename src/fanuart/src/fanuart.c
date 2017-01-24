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
#include "uart_enum.h"

static void enum_ports()
{
  struct serial_info *port_list = find_serialports();

  for (struct serial_info *port=port_list; port != NULL; port=port->next)
  {
    printf("%s", port->name);
    if (port->description)   printf(" %s", port->description);
    if (port->manufacturer)  printf(" %s", port->manufacturer);
    if (port->serial_number) printf(" %s", port->serial_number);
    if (port->vid)           printf(" %d", port->vid);
    if (port->pid)           printf(" %d", port->pid);
    printf("\n");
  }

  serial_info_free_list(port_list);
}

int main() //int argc, char *argv[])
{
  enum_ports();
  return 0;
}
