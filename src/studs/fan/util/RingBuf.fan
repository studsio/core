//
// Copyright (c) 2021, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   16 Apr 2021  Andy Frank  Creation
//

**
** RingBuf is a FIFO buffer using a fixed max size. As new
** items are added, the oldest items are evicted.
**
@Js class RingBuf
{
  ** Construct a new buffer with max size.
  new make(Int max)
  {
    this.max = max
    this.items.size = max
  }

  ** Number of items in buffer.
  Int size { private set }

  ** Add new item to the buffer. If max size is
  ** reached, evict the oldest item.
  This add(Obj? item)
  {
    tail = tail + 1
    if (tail >= max) tail = 0
    items[tail] = item
    size = (size + 1).min(max)
    return this
  }

  ** Clear all items in buffer.
  This clear()
  {
    this.items = Obj?[,] { it.size = this.max }
    this.size = 0
    this.tail = -1
    return this
  }

  ** Iterate items from newest to oldest.
  Void each(|Obj?| f)
  {
    end := size
    i := tail
    n := 0
    while (n < end)
    {
      f(items[i])
      n++
      i--
      if (i < 0) i = max - 1
    }
  }

  ** Iterate items from oldest to newest.
  Void eachr(|Obj?| f)
  {
    end := size
    i := tail+1; if (i >= size) i = 0
    n := 0
    while (n < end)
    {
      f(items[i])
      n++
      i++
      if (i >= max) i = 0
    }
  }

  private const Int max
  private Obj?[] items := [,]
  private Int tail := -1
}