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

//////////////////////////////////////////////////////////////////////////
// Private
//////////////////////////////////////////////////////////////////////////

static struct pack_entry* pack_add_entry(struct pack_map *map)
{
  struct pack_entry *e = (struct pack_entry *)malloc(sizeof(struct pack_entry));
  e->next = NULL;
  if (map->head == NULL)
  {
    map->head = map->tail = e;
  }
  else
  {
    map->tail->next = e;
    map->tail = e;
  }
  map->size++;
  return e;
}

static struct pack_entry* pack_find_entry(struct pack_map *map, char *name)
{
  struct pack_entry *e = map->head;
  while (e != NULL && strcmp(e->name, name) != 0) e = e->next;
  return e;
}

//////////////////////////////////////////////////////////////////////////
// Alloc
//////////////////////////////////////////////////////////////////////////

/*
 * Allocate a new pack_map instance.
 */
struct pack_map* pack_map_new()
{
  struct pack_map *map = (struct pack_map *)malloc(sizeof(struct pack_map));
  map->head = NULL;
  map->tail = NULL;
  map->size = 0;
  return map;
}

/*
 * Free memory used by given map.
 */
void pack_map_free(struct pack_map *map)
{
  // TODO
}

//////////////////////////////////////////////////////////////////////////
// Getters
//////////////////////////////////////////////////////////////////////////

/*
 * Return true if given list contains the key name or
 * false if name not found.
 */
bool pack_has(struct pack_map *map, char *name)
{
  return pack_find_entry(map, name) != NULL;
}

/*
 * Get value for given name as boolean. If name is not
 * found, or if type does not match returns false.
 */
bool pack_getb(struct pack_map *map, char *name)
{
  struct pack_entry *e = pack_find_entry(map, name);
  if (e == NULL) return false;
  if (e->type != PACK_TYPE_BOOL) return false;
  return e->val.b;
}

/*
 * Get value for given name as signed 64-bit integer. If
 * name is not found, or if type does not match, returns 0.
 */
int64_t pack_geti(struct pack_map *map, char *name)
{
  struct pack_entry *e = pack_find_entry(map, name);
  if (e == NULL) return 0;
  if (e->type != PACK_TYPE_INT) return 0;
  return e->val.i;
}

/*
 * Get value for given name as char string. If name is
 * not found, or if type does not match returns NULL.
 */
char* pack_gets(struct pack_map *map, char *name)
{
  struct pack_entry *e = pack_find_entry(map, name);
  if (e == NULL) return NULL;
  if (e->type != PACK_TYPE_STR) return NULL;
  return e->val.s;
}

//////////////////////////////////////////////////////////////////////////
// Setters
//////////////////////////////////////////////////////////////////////////

/*
 * Set 'name' to boolean 'val'.  If this name already exists
 * the value is updated, otherwise a new entry is added.
 */
void pack_setb(struct pack_map *map, char *name, bool val)
{
  struct pack_entry *e = pack_add_entry(map);
  e->name  = strdup(name);
  e->type  = PACK_TYPE_BOOL;
  e->val.b = val == 0 ? 0 : 1;
}

/*
 * Set 'name' to 64-bit signed integer 'val'.  If this name
 * already exists the value is updated, otherwise a new entry
 * is added.
 */
void pack_seti(struct pack_map *map, char *name, int64_t val)
{
  struct pack_entry *e = pack_add_entry(map);
  e->name  = strdup(name);
  e->type  = PACK_TYPE_INT;
  e->val.i = val;
}

/*
 * Set 'name' to char string 'val'  If this name already
 * exists the value is updated, otherwise a new entry is
 * added.
 */
void pack_sets(struct pack_map *map, char *name, char *val)
{
  struct pack_entry *e = pack_add_entry(map);
  e->name  = strdup(name);
  e->type  = PACK_TYPE_STR;
  e->val.s = strdup(val);
}

//////////////////////////////////////////////////////////////////////////
// Encode
//////////////////////////////////////////////////////////////////////////

/*
 * Encode pack map into byte buffer.  Returns pointer to buffer,
 * or NULL if error occurred.
 */
uint8_t* pack_encode(struct pack_map *map)
{
  struct pack_entry *p = map->head;

  // determine packet length
  uint16_t len = 0;
  while (p != NULL)
  {
    len += 1 + strlen(p->name);
    switch (p->type)
    {
      case PACK_TYPE_BOOL: len += 2; break;
      case PACK_TYPE_INT:  len += 9; break;
      case PACK_TYPE_STR:  len += 3 + strlen(p->val.s);
    }
    p = p->next;
  }

  uint8_t *buf = (uint8_t *)malloc(len+4);
  uint16_t off = 0;
  uint8_t i, nlen;
  uint16_t slen;

  // magic
  buf[off++] = 0x70;
  buf[off++] = 0x6b;

  // length
  buf[off++] = (len >> 8) & 0xff;
  buf[off++] = len & 0xff;

  // encode entries
  p = map->head;
  while (p != NULL)
  {
    nlen = strlen(p->name);
    buf[off++] = nlen;
    for (i=0; i<nlen; i++) buf[off++] = p->name[i];

    buf[off++] = p->type;
    switch (p->type)
    {
      case PACK_TYPE_BOOL:
        buf[off++] = p->val.i & 0xff;
        break;

      case PACK_TYPE_INT:
        buf[off++] = (p->val.i >> 56) & 0xff;
        buf[off++] = (p->val.i >> 48) & 0xff;
        buf[off++] = (p->val.i >> 40) & 0xff;
        buf[off++] = (p->val.i >> 32) & 0xff;
        buf[off++] = (p->val.i >> 24) & 0xff;
        buf[off++] = (p->val.i >> 16) & 0xff;
        buf[off++] = (p->val.i >> 8)  & 0xff;
        buf[off++] = p->val.i & 0xff;
        break;

      case PACK_TYPE_STR:
        slen = strlen(p->val.s);
        buf[off++] = (slen >> 8) & 0xff;
        buf[off++] = slen & 0xff;
        for (i=0; i<slen; i++) buf[off++] = p->val.s[i];
        break;
    }

    p = p->next;
  }

  return buf;
}

//////////////////////////////////////////////////////////////////////////
// Decode
//////////////////////////////////////////////////////////////////////////

/*
 * Decode byte buffer into pack_map instance. Returns pointer
 * new map, or NULL if error occurred.
 */
struct pack_map* pack_decode(uint8_t *buf)
{
  // sanity checks
  if (buf[0] != 0x70) return NULL;
  if (buf[1] != 0x6b) return NULL;

  // read length
  uint16_t len = (((buf[2] << 8) & 0xff) | (buf[3] & 0xff)) + 4;
  uint16_t off = 4;

  struct pack_map *map = pack_map_new();
  char *name;
  union pack_val val;
  uint8_t i, nlen, type;
  uint16_t vlen;
  char *sval;
  uint64_t uval;

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
        if (uval <= 0x7fffffffffffffffu) val.i = uval;
        else val.i = (-1 - (int64_t)(0xffffffffffffffffu - uval));
        off += 8;
        break;

      case PACK_TYPE_STR:
        vlen = ((buf[off] << 8) & 0xff) | (buf[off+1] & 0xff);
        off += 2;
        sval = (char *)malloc(vlen+1);
        for (i=0; i<vlen; i++) sval[i] = buf[off++];
        sval[vlen] = '\0';
        val.s = sval;
        break;


      case PACK_TYPE_LIST:
        vlen = ((buf[off] << 8) & 0xff) | (buf[off+1] & 0xff);
        off += 2;
        break;

      default:
        free(name);
        continue;
    }

    // append node to linked list
    struct pack_entry *e = pack_add_entry(map);
    e->name = name;
    e->type = type;
    e->val  = val;
  }

  return map;
}
