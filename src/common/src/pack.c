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
  struct pack_entry *p = map->head;
  struct pack_entry *q;

  while (p != NULL)
  {
    q = p->next;
    free(p->name);
    switch (p->type)
    {
      case PACK_TYPE_STR: free(p->val.s); break;
      case PACK_TYPE_MAP: pack_map_free(p->val.m); break;
    }
    free(p);
    p = q;
  }

  free(map);
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

/*
 * Get value for given name as pack_map. If name is not
 * found, or if type does not match returns NULL.
 */
struct pack_map* pack_getm(struct pack_map *map, char *name)
{
  struct pack_entry *e = pack_find_entry(map, name);
  if (e == NULL) return NULL;
  if (e->type != PACK_TYPE_MAP) return NULL;
  return e->val.m;
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

/*
 * Set 'name' to pack_map 'val'  If this name already exists
 * the value is updated, otherwise a new entry is added.
 */
void pack_setm(struct pack_map *map, char *name, struct pack_map *val)
{
  struct pack_entry *e = pack_add_entry(map);
  e->name  = strdup(name);
  e->type  = PACK_TYPE_MAP;
  e->val.m = val;
}

//////////////////////////////////////////////////////////////////////////
// Encode
//////////////////////////////////////////////////////////////////////////

/*
 * Determine number of bytes required to encode given map.
 * Does not include 4-byte header (magic + len).
 */
static uint16_t pack_map_enc_size(struct pack_map *map)
{
  struct pack_entry *p = map->head;
  uint16_t len = 0;

  while (p != NULL)
  {
    len += 1 + strlen(p->name);
    switch (p->type)
    {
      case PACK_TYPE_BOOL: len += 2; break;
      case PACK_TYPE_INT:  len += 9; break;
      case PACK_TYPE_STR:  len += 3 + strlen(p->val.s); break;
      case PACK_TYPE_MAP:  len += 3 + pack_map_enc_size(p->val.m); break;
    }
    p = p->next;
  }

  return len;
}

/*
 * Encode pack map into byte buffer.  Returns pointer to buffer,
 * or NULL if error occurred.
 */
uint8_t* pack_encode(struct pack_map *map)
{
  struct pack_entry *p = map->head;

  // TODO: use a auto-grow byte buffer to avoid double scan
  uint16_t len = pack_map_enc_size(map);

  uint8_t *buf = (uint8_t *)malloc(len+4);
  uint16_t off = 0;
  uint8_t i, nlen;
  uint16_t vlen;
  uint8_t *sub_buf;

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
        vlen = strlen(p->val.s);
        buf[off++] = (vlen >> 8) & 0xff;
        buf[off++] = vlen & 0xff;
        for (i=0; i<vlen; i++) buf[off++] = p->val.s[i];
        break;

      case PACK_TYPE_MAP:
        // TODO: encode directly into auto-grow byte buffer
        vlen = p->val.m->size;
        buf[off++] = (vlen >> 8) & 0xff;
        buf[off++] = vlen & 0xff;
        sub_buf = pack_encode(p->val.m);
        vlen = pack_map_enc_size(p->val.m);
        memcpy(&buf[off], sub_buf, vlen);
        off += vlen;
        free(sub_buf);
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

      // case PACK_TYPE_LIST:
      //   vlen = ((buf[off] << 8) & 0xff) | (buf[off+1] & 0xff);
      //   off += 2;
      //   break;

      // case PACK_TYPE_MAP;
      //   vlen = ((buf[off] << 8) & 0xff) | (buf[off+1] & 0xff);
      //   off += 2;
      //   break;

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

//////////////////////////////////////////////////////////////////////////
// Encode
//////////////////////////////////////////////////////////////////////////

/*
 * Write Pack map to given file handle. Returns 0 if map
 * was written successfully, or non-zero if failed.
 */
int pack_write(struct pack_map *map, FILE *f)
{
  uint8_t *buf = pack_encode(map);
  uint16_t len = (((buf[2] << 8) & 0xff) | (buf[3] & 0xff)) + 4;
  uint16_t off = 0;

  while (off < len)
  {
    if (putc(buf[off], f) == EOF) break;
    off++;
  }

  free(buf);
  return off == len ? 0 : -1;
}
