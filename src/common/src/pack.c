/*
// Copyright (c) 2017, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Jan 2017  Andy Frank  Creation
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "pack.h"

/*
 * Decode byte buffer into pack_entry linked list. Returns
 * pointr to entry, or NULL if error occurred.
 */
struct pack_entry * pack_decode(char *buf)
{
  // sanity checks
  if (buf[0] != 0x70) return NULL;
  if (buf[1] != 0x6b) return NULL;

  // read length
  uint16_t len = ((buf[2] << 8) & 0xff) | (buf[3] & 0xff) + 4;
  uint16_t off = 4;

  // check endianess
  int n = 1;
  int le = (*(char *)&n == 1);

  struct pack_entry *head = NULL;
  struct pack_entry *tail = NULL;
  char *name;
  union pack_uval val;
  uint8_t i, nlen, type;
  uint32_t slen;
  char *sval;
  uint64_t uval;
  union float_u { double d; char bytes[8]; } fval;

  while (off < len)
  {
    // read name
    nlen = buf[off++];
    name = (char *)malloc(nlen+1);
    for (i=0; i<nlen; i++) name[i] = buf[off++];
    name[nlen] = '\0';

    // read value
    type = buf[off++];
    switch (type)
    {
      case PACK_TYPE_BOOL:
        val.i = buf[off++] == 0 ? 0 : 1;
        break;

      case PACK_TYPE_INT:
        uval = ((uint64_t)buf[off]   << 56) |
               ((uint64_t)buf[off+1] << 48) |
               ((uint64_t)buf[off+2] << 40) |
               ((uint64_t)buf[off+3] << 32) |
               ((uint64_t)buf[off+4] << 24) |
               ((uint64_t)buf[off+5] << 16) |
               ((uint64_t)buf[off+6] << 8)  |
               ((uint8_t)buf[off+7]);
        val.i = (uval <= 0x7fffffffffffffffu)
          ? uval
          : (-1 - (int64_t)(0xffffffffffffffffu - uval));
        off += 8;
        break;

      case PACK_TYPE_FLOAT:
        // TODO FIXIT: do we support float?
        for (i=0; i<8; i++)
        {
          if (le) fval.bytes[7-i] = buf[off+i];
          else    fval.bytes[i]   = buf[off+i];
        }
        val.d = fval.d;
        off += 8;
        break;

      case PACK_TYPE_STR:
        slen = ((buf[off] << 8) & 0xff) | (buf[off+1] & 0xff);
        off += 2;
        sval = (char *)malloc(slen+1);
        for (i=0; i<slen; i++) sval[i] = buf[off++];
        sval[slen] = '\0';
        val.s = sval;
        break;

      default:
        free(name);
        continue;
    }

    // append node to linked list
    struct pack_entry *p = (struct pack_entry *)malloc(sizeof(struct pack_entry));
    p->name = name;
    p->type = type;
    p->val  = val;
    p->next = NULL;
    if (head == NULL) { head = tail = p; }
    else { tail->next = p; tail = p; }
  }

  return head;
}

/*
 * Find the entry for the given name in this list, or
 * returns NULL if name not found.
 */
struct pack_entry * pack_find(struct pack_entry *p, char *name)
{
  while (p != NULL)
  {
    if (strcmp(p->name, name) == 0) return p;
    p = p->next;
  }
  return NULL;
}

/*
 * Return TRUE if given list contains the key name or
 * FALSE if name not found.
 */
int pack_has(struct pack_entry *p, char *name)
{
  return pack_find(p, name) != NULL;
}

/*
 * Get value for given name as boolean. If name is not
 * found, or if type does not match returns FALSE.
 */
int pack_getb(struct pack_entry *p, char *name)
{
  p = pack_find(p, name);
  if (p == NULL) return 0;
  if (p->type != PACK_TYPE_BOOL) return 0;
  return p->val.i;
}

/*
 * Get value for given name as signed 64-bit integer.
 * If name is not found, or if type does not match,
 * returns 0.
 */
int64_t pack_geti(struct pack_entry *p, char *name)
{
  p = pack_find(p, name);
  if (p == NULL) return 0;
  if (p->type != PACK_TYPE_INT) return 0;
  return p->val.i;
}

/*
 * Get value for given name as 64-bit float. If name
 * not found, or if type does not match, returns 0.0.
 */
double pack_getf(struct pack_entry *p, char *name)
{
  p = pack_find(p, name);
  if (p == NULL) return 0.0;
  if (p->type != PACK_TYPE_FLOAT) return 0.0;
  return p->val.d;
}

/*
 * Get value for given name as char string. If name
 * not found, or if type does not match, returns NULLv.
 */
char * pack_gets(struct pack_entry *p, char *name)
{
  p = pack_find(p, name);
  if (p == NULL) return NULL;
  if (p->type != PACK_TYPE_STR) return NULL;
  return p->val.s;
}