// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run
{
  struct run *next;
};

struct
{
  struct spinlock lock;
  struct run *freelist;
} kmem;

struct spinlock ref_lock;
int reference_arr[PGROUNDUP(PHYSTOP) >> 12];

uint64 get_ref_index(void *pa)
{
  return (uint64)pa >> 12;
}

void init_ref()
{
  initlock(&ref_lock, "ref_lock");
  acquire(&ref_lock);
  for (uint64 i = 0; i < (PGROUNDUP(PHYSTOP) >> 12); i++)
  {
    reference_arr[i] = 0;
  }
  release(&ref_lock);
}

void inc_ref(void *pa)
{
  acquire(&ref_lock);
  uint64 i = get_ref_index(pa);
  if (reference_arr[i] >= 0)
  {
    reference_arr[i] += 1;
    release(&ref_lock);
  }
  else
  {
    panic("inc_ref");
    return;
  }
}

void dec_ref(void *pa)
{
  acquire(&ref_lock);
  uint64 i = get_ref_index(pa);
  if (reference_arr[i] > 0)
  {
    reference_arr[i] -= 1;
    release(&ref_lock);
  }
  else
  {
    panic("dec_ref");
    return;
  }
}

void kinit()
{
   init_ref();
  initlock(&kmem.lock, "kmem");
  freerange(end, (void *)PHYSTOP);
}

void freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char *)PGROUNDUP((uint64)pa_start);
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
  {
    inc_ref(p);
    kfree(p);
  }
    
}

// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
  struct run *r;

  if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  dec_ref(pa);
  if (reference_arr[get_ref_index(pa)] == 0)
  {
    memset(pa, 1, PGSIZE);

    r = (struct run *)pa;

    acquire(&kmem.lock);
    r->next = kmem.freelist;
    kmem.freelist = r;
    release(&kmem.lock);
  }
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  acquire(&kmem.lock);
  r = kmem.freelist;
  if (r)
    kmem.freelist = r->next;
  release(&kmem.lock);

  if (r)
  {
    memset((char *)r, 5, PGSIZE);
    inc_ref((void*)r);
  }
     // fill with junk
  return (void *)r;
}
