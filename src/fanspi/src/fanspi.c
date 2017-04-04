/*
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    3 Apr 2017  Andy Frank  Creation
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

#ifndef _IOC_SIZE_BITS
// Include <asm/ioctl.h> manually on platforms that don't include it
// from <sys/ioctl.h>.
#include <asm/ioctl.h>
#endif
#include <linux/spi/spidev.h>

#include "../../common/src/log.h"
#include "../../common/src/pack.h"

// Max SPI transfer size that we support
#define SPI_TRANSFER_MAX 256

struct spi_info
{
  int fd;
  struct spi_ioc_transfer transfer;
};

//////////////////////////////////////////////////////////////////////////
// Helpers
//////////////////////////////////////////////////////////////////////////

/*
 * Send an ok pack response to stdout.
 */
// static void send_ok()
// {
//   struct pack_map *res = pack_map_new();
//   pack_set_str(res, "status", "ok");
//   if (pack_write(stdout, res) < 0) log_debug("fanspi: send_ok failed");
//   pack_map_free(res);
// }

/*
 * Send an error pack response to stdout.
 */
// static void send_err(char *msg)
// {
//   struct pack_map *res = pack_map_new();
//   pack_set_str(res, "status", "err");
//   pack_set_str(res, "msg",    msg);
//   if (pack_write(stdout, res) < 0) log_debug("fanspi: send_err failed");
//   pack_map_free(res);
// }

//////////////////////////////////////////////////////////////////////////
// SPI
//////////////////////////////////////////////////////////////////////////

/**
 * @brief  Initialize a SPI device
 *
 * @param  spi            Handle to initialize
 * @param  devpath        Path to SPI device file
 * @param  mode           SPI mode
 * @param  bits_per_word  Number of bits
 * @param  speed_hz       Bus speed
 * @param  delay_usecs    Delay between transfers
 *
 * @retur  1 if success, -1 if fails
 */
static void spi_init(struct spi_info *spi,
                     const char *devpath,
                     uint8_t mode,
                     uint8_t bits_per_word,
                     uint32_t speed_hz,
                     uint16_t delay_usecs)
{
  memset(spi, 0, sizeof(*spi));

  spi->transfer.speed_hz = speed_hz;
  spi->transfer.delay_usecs = delay_usecs;
  spi->transfer.bits_per_word = bits_per_word;

  // Fail hard on error. May need to be nicer if this makes the
  // Erlang side too hard to debug.
  spi->fd = open(devpath, O_RDWR);
  if (spi->fd < 0)
    err(EXIT_FAILURE, "open %s", devpath);

  if (ioctl(spi->fd, SPI_IOC_WR_MODE, &mode) < 0)
    err(EXIT_FAILURE, "ioctl(SPI_IOC_WR_MODE %d)", mode);

  // Set these to check for bad values given by the user. They get
  // set again on each transfer.
  if (ioctl(spi->fd, SPI_IOC_WR_BITS_PER_WORD, &bits_per_word) < 0)
    err(EXIT_FAILURE, "ioctl(SPI_IOC_WR_BITS_PER_WORD %d)", bits_per_word);

  if (ioctl(spi->fd, SPI_IOC_WR_MAX_SPEED_HZ, &speed_hz) < 0)
    err(EXIT_FAILURE, "ioctl(SPI_IOC_WR_MAX_SPEED_HZ %d)", speed_hz);
}

/**
 * @brief spi transfer operation
 *
 * @param  tx   Data to write into the device
 * @param  rx   Data to read from the device
 * @param  len  Length of data
 *
 * @return  1 for success, 0 for failure
 */
static int spi_transfer(struct spi_info *spi, const char *tx, char *rx, unsigned int len)
{
  struct spi_ioc_transfer tfer = spi->transfer;

  // The Linux header spidev.h expects pointers to be in 64-bit integers (__u64),
  // but pointers on Raspberry Pi are only 32 bits.
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wpointer-to-int-cast"
  tfer.tx_buf = (__u64) tx;
  tfer.rx_buf = (__u64) rx;
#pragma GCC diagnostic pop
  tfer.len = len;

  if (ioctl(spi->fd, SPI_IOC_MESSAGE(1), &tfer) < 1)
    err(EXIT_FAILURE, "ioctl(SPI_IOC_MESSAGE)");

  return 1;
}

//////////////////////////////////////////////////////////////////////////
// Pack
//////////////////////////////////////////////////////////////////////////

/*
 * TODO
 */
static void on_transfer(struct pack_map *req)
{
  // debug
  char *d = pack_debug(req);
  log_debug("fanspi: on_transfer %s", d);
  free(d);

  // TODO
}

/*
 * Callback to process an incoming Fantom request.
 * Returns -1 if process should exit, or 0 to continue.
 */
static int on_proc_req(struct pack_map *req)
{
  char *op = pack_get_str(req, "op");

  if (strcmp(op, "transfer") == 0) { on_transfer(req); return 0; }
  if (strcmp(op, "exit")     == 0) { return -1; }

  log_debug("fanspi: unknown op '%s'", op);
  return 0;
}

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

int main(int argc, char *argv[])
{
  if (argc != 6)
    log_fatal("%s <device path> <SPI mode (0-3)> <bits/word (8)> <speed (1000000 Hz)> <delay (10 us)>", argv[0]);

  const char *devpath = argv[2];
  uint8_t mode   = (uint8_t)  strtoul(argv[3], 0, 0);
  uint8_t bits   = (uint8_t)  strtoul(argv[4], 0, 0);
  uint32_t speed = (uint32_t) strtoul(argv[5], 0, 0);
  uint16_t delay = (uint16_t) strtoul(argv[6], 0, 0);

  struct spi_info spi;
  spi_init(&spi, devpath, mode, bits, speed, delay);

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
      log_debug("fanspi: pack_read failed");
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
  log_debug("fanspi: bye-bye");
  return 0;
}