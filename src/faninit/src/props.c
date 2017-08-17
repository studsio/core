/*
// Copyright (c) 2016, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   30 Aug 2016  Andy Frank  Creation
*/

#include "faninit.h"

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>

// push back for read
int unread = 0;

/**
 * Read next character from stream or return EOF
 */
int read_char(FILE* fp)
{
  if (unread != 0)
  {
    int c = unread;
    unread = 0;
    return c;
  }
  else
  {
    return fgetc(fp);
  }
}

/**
 * Pushback a character to reuse for next read_char()
 */
void unread_char(int ch)
{
  assert(unread == 0);
  unread = ch;
}

/**
 * Convert a hexadecimal digit char into its numeric
 * value or return -1 on error.
 */
int hex(int c)
{
  if ('0' <= c && c <= '9') return c - '0';
  if ('a' <= c && c <= 'f') return c - 'a' + 10;
  if ('A' <= c && c <= 'F') return c - 'A' + 10;
  return -1;
}

/**
 * Return if specified character is whitespace.
 */
int is_space(int c)
{
  return c == ' ' || c == '\t';
}

/**
 * Given a pointer to a string of characters, trim the leading
 * and trailing whitespace and return a copy of the string from
 * heap memory.
 */
char* make_trim_copy(char* s, int num)
{
  // trim leading/trailing whitespace
  int start = 0;
  int end = num;
  while (start < end) if (is_space(s[start])) start++; else break;
  while (end > start) if (is_space(s[end-1])) end--; else break;
  s[end] = '\0';
  s = s+start;

  // make copy on heap
  char* copy = (char *)malloc(end-start+1);
  strcpy(copy, s);
  return copy;
}

/**
 * Parse the specified props file according to the file format
 * specified by sys::InStream - this is pretty much a C port of
 * the Java implementation.  Return a linked list of Props or if
 * error, then print error to stdout and return NULL.
 */
struct prop* read_props(const char* filename)
{
  char name[512];
  char val[4096];
  int name_num = 0, val_num = 0;
  int in_val = 0;
  int in_block_comment = 0;
  int in_end_of_line_comment = 0;
  int c = -1, last = -1;
  int line_num = 1;
  FILE* fp;
  struct prop* head = NULL;
  struct prop* tail = NULL;

  fp = fopen(filename, "r");
  if (fp == NULL) fatal("/etc/faninit.props not found");

  for (;;)
  {
    last = c;
    c = read_char(fp);
    if (c == EOF) break;

    // end of line
    if (c == '\n' || c == '\r')
    {
      in_end_of_line_comment = 0;
      if (last == '\r' && c == '\n') continue;
      char* n = make_trim_copy(name, name_num);
      if (in_val)
      {
        char* v = make_trim_copy(val, val_num);

        struct prop* p = (struct prop *)malloc(sizeof(struct prop));
        p->name = n;
        p->val = v;
        p->next = NULL;
        if (head == NULL) { head = tail = p; }
        else { tail->next = p; tail = p; }

        in_val = 0;
        name_num = val_num = 0;
      }
      else if (strlen(n) > 0)
      {
        warn("Invalid name/value pair [%s:%d]\n", filename, line_num);
        return NULL;
      }
      line_num++;
      continue;
    }

    // if in comment
    if (in_end_of_line_comment) continue;

    // block comment
    if (in_block_comment > 0)
    {
      if (last == '/' && c == '*') in_block_comment++;
      if (last == '*' && c == '/') in_block_comment--;
      continue;
    }

    // equal
    if (c == '=' && !in_val)
    {
      in_val = 1;
      continue;
    }

    // bash-style comment
    if (c == '#')
    {
      in_end_of_line_comment = 1;
      continue;
    }

    // c-style comment
    if (c == '/')
    {
      int peek = read_char(fp);
      if (peek < 0) break;
      if (peek == '/') { in_end_of_line_comment = 1; continue; }
      if (peek == '*') { in_block_comment++; continue; }
      unread_char(peek);
    }

    // escape or line continuation
    if (c == '\\')
    {
      int peek = read_char(fp);
      if (peek < 0) break;
      else if (peek == 'n')  c = '\n';
      else if (peek == 'r')  c = '\r';
      else if (peek == 't')  c = '\t';
      else if (peek == '\\') c = '\\';
      else if (peek == '\r' || peek == '\n')
      {
        // line continuation
        line_num++;
        if (peek == '\r')
        {
          peek = read_char(fp);
          if (peek != '\n') unread_char(peek);
        }
        while (1)
        {
          peek = read_char(fp);
          if (peek == ' ' || peek == '\t') continue;
          unread_char(peek);
          break;
        }
        continue;
      }
      else if (peek == 'u')
      {
        int n3 = hex(read_char(fp));
        int n2 = hex(read_char(fp));
        int n1 = hex(read_char(fp));
        int n0 = hex(read_char(fp));
        if (n3 < 0 || n2 < 0 || n1 < 0 || n0 < 0)
        {
          warn("Invalid hex value for \\uxxxx [%s:%d]\n", filename, line_num);
          return NULL;
        }
        c = ((n3 << 12) | (n2 << 8) | (n1 << 4) | n0);
      }
      else
      {
        warn("Invalid escape sequence [%s:%d]\n", filename, line_num);
        return NULL;
      }
    }

    // normal character
    if (in_val)
    {
      if (val_num+1 < (int)sizeof(val)) val[val_num++] = c;
    }
    else
    {
      if (name_num+1 < (int)sizeof(name)) name[name_num++] = c;
    }
  }

  char* n = make_trim_copy(name, name_num);
  if (in_val)
  {
    char* v = make_trim_copy(val, val_num);

    struct prop* p = (struct prop *)malloc(sizeof(struct prop));
    p->name = n;
    p->val = v;
    p->next = NULL;
    if (head == NULL) { head = tail = p; }
    else { tail->next = p; tail = p; }
  }
  else if (strlen(n) > 0)
  {
    warn("Invalid name/value pair [%s:%d]\n", filename, line_num);
    return NULL;
  }

  return head;
}

/**
 * Get a property from the linked list or return def if not found.
 */
const char* get_prop(struct prop* props, const char* name, const char* def)
{
  struct prop *p = props;
  for (; p != NULL; p = p->next)
    if (strcmp(p->name, name) == 0)
      return p->val;
  return def;
}

/**
 * Get a substring
 */
char* substr(const char *src, int start, int len)
{
  char *sub = malloc((len+1) * sizeof(char));
  memcpy(sub, &src[start], len);
  sub[len] = '\0';
  return sub;
}
