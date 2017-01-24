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

#ifndef UART_ENUM_H
#define UART_ENUM_H

struct serial_info {
    char *name;
    char *description;
    char *manufacturer;
    char *serial_number;
    int vid;
    int pid;

    struct serial_info *next;
};

// Common code
struct serial_info *serial_info_alloc();
void serial_info_free(struct serial_info *info);
void serial_info_free_list(struct serial_info *info);

// Prototypes for device-specific code
struct serial_info *find_serialports();

#endif // UART_ENUM_H
