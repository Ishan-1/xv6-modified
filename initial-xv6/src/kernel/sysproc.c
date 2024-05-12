#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0; // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if (growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while (ticks - ticks0 < n)
  {
    myproc()->hastosleep=1;
    if (killed(myproc()))
    {
      myproc()->hastosleep=0;
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  myproc()->hastosleep=0;
  myproc()->stime=0;
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

// return how many times read is called
uint64
sys_getreadcount(void)
{
  printf("Read count: %d\n", myproc()->readcount);
  return myproc()->readcount;
}

uint64
sys_sigalarm(void)
{
  uint64 n;
  argaddr(0, &n);
  if (n < 0)
  {
    return -1;
  }
  uint64 handler;
  argaddr(1, &handler);
  if (handler < 0)
  {
    return -1;
  }
  myproc()->n = n;
  myproc()->alarmhandler = handler;
  myproc()->aset=1;
  return 0;
}

uint64 sys_setpriority(void)
{
  int pid,new_priority;
  argint(0,&pid);
  argint(1,&new_priority);
  struct proc* p;
  for(p=proc;p<&proc[NPROC];p++)
  {
    acquire(&p->lock);
    if(p->pid==pid)
    {
      p->priority=new_priority;
      p->rbi=25;
      p->dp=p->priority+p->rbi;
      release(&p->lock);
      break;
    }
    release(&p->lock);
  }
  return 0;
}

uint64
sys_sigreturn(void)
{
   *(myproc()->trapframe)=*(myproc()->alarm_tp);
   myproc()->astate=0;
   myproc()->atime=0;
   usertrapret();
   return 0;
}

uint64
sys_waitx(void)
{
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
  argaddr(1, &addr1); // user virtual memory
  argaddr(2, &addr2);
  int ret = waitx(addr, &wtime, &rtime);
  struct proc *p = myproc();
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    return -1;
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    return -1;
  return ret;
}