# xv6 System Enhancements

This repository contains enhancements made to the xv6 operating system, including new system calls, scheduling policies, and features such as copy-on-write fork.

## System Calls

### 1. getreadcount

#### Description:
- Added the system call `getreadcount` to xv6.
- Returns the value of a counter which is incremented every time any process calls the `read()` system call.

#### Function Signature:
```c
int getreadcount(void);
```

### 2. sigalarm and sigreturn

#### Description:
- Implemented a feature to periodically alert a process as it uses CPU time.
- Added a new system call `sigalarm(interval, handler)`:
  - Calls the application function `handler` after every `interval` ticks of CPU time.
- Added system call `sigreturn()` to reset the process state after the handler is called.

## Scheduling

### 1. First Come First Serve (FCFS)

#### Description:
- Implemented a policy that selects the process with the lowest creation time.
- Process runs until it no longer needs CPU time.

### 2. Multi-Level Feedback Queue (MLFQ)

#### Description:
- Implemented a preemptive MLFQ scheduler with four priority queues.
- Time slices:
  - Priority 0: 1 timer tick
  - Priority 1: 3 timer ticks
  - Priority 2: 9 timer ticks
  - Priority 3: 15 timer ticks
- Processes move between queues based on behavior and CPU bursts.
- Aging implemented to prevent starvation.
- Round-robin scheduler used for processes at the lowest priority queue.

### 3. Modified Priority-Based Scheduler

#### Description:
- Implemented a preemptive priority-based scheduler.
- Dynamic Priority (DP) based on Static Priority (SP) and Recent Behavior Index (RBI).
- RBI measures recent behavior (Running Time, Sleeping Time, Waiting Time).
- `set_priority()` system call to change Static Priority and reset RBI.
- User program `setpriority` to change priority via syscall.

## Copy on Write Fork

#### Description:
- Implemented copy-on-write (COW) fork in xv6.
- Parent and child initially share all physical pages, mapped read-only.
- On write, kernel makes a copy of the page, updating page tables.
- Child and parent have separate copies for modified pages.
