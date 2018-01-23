# 深入研究Windows内部原理

## I
* Windows NT
* + hybrid kernel
* + - [ref](https://www.zhihu.com/question/20314255)
* + - microkernel
* + - - 在微内核中，大部分内核都作为单独的进程在特权状态下运行，他们通过消息传递进行通讯。在典型情况下，每个概念模块都有一个进程。因此，假如在设计中有一个系统调用模块，那么就必然有一个相应的进程来接收系统调用，并和能够执行系统调用的其他进程（或模块）通讯以完成所需任务。
* + - monolithic kernel (Linux)
* + - - 单内核是个很大的进程。他的内部又能够被分为若干模块（或是层次或其他）。但是在运行的时候，他是个单独的二进制大映象。其模块间的通讯是通过直接调用其他模块中的函数实现的，而不是消息传递
* + User mode: system / service + user application / environment subsystems
* + Kernel mode: Executive = driver + kernel = HAL (硬件抽象层) / Windows User/GDI driver
* + Ntoskrnl: Executive + Kernel
* + - process / thread manager
* + - virtual memory
* + - security reference
* + - IO
* + - 即插即用 plug & play
* + - Power
* + - cache
* + - Object / LPC / Library
* + - Primitive
* + - Scheduler
* + - Interrupt
* + - Multiprocessor
* + Ntkrnlpa: PAE Executive + Kernel
* + Hal.dll: HAL
* + - [AIPC](https://zh.wikipedia.org/wiki/%E9%AB%98%E7%BA%A7%E9%85%8D%E7%BD%AE%E4%B8%8E%E7%94%B5%E6%BA%90%E6%8E%A5%E5%8F%A3)
* + - ACPI
* + - APIC
* + Ntdll: Executive API
* + - From user mode to kernel mode
* + - context switch (sysenter / sysexit)
* + - - INT 0x2Eh
* + - - Nt!KiSystemCall / KiFastSystemCall
* + - - after win10, only syscall [ref](https://www.evilsocket.net/2014/02/11/on-windows-syscall-mechanism-and-syscall-numbers-extraction-methods/)
* + - Nt (Ring3) => Zw => Ki / Ke / Ex
* + Kernel32/Advapi32/User32/GDI32: kernel win32 subsystem dll
* + IO Manager
* + - IRP request (excerpt for fast IO)
* + - IO Operation
* + - - ReadFile (Application) => NtReadFile (Kernel32.dll) => Sysenter (Int 2E, Ntdll.dll) => KiSystemService (Ntoskrnl.exe) => NtReadFile (Ntoskrnl.exe) => Driver (Driver.sys)
* Win32 Subsystem
* + Win32k.sys: Win32 subsystem kernel
* + - Windows manager
* + - - Show windows
* + - - Manager screen output
* + - - Collect input from IO device
* + - - pass user information
* + - GDI
* + csrss.exe 环境子系统进程
* + - cmd
* + - create/delete process/thread
* + - 16-bit DOS
* + kernel32 / advapi32 / User32 / Gdi32
* + graphics driver
* Vista improvement
* + Scheduler
* + IO
* + - CacncelSynchronousio
* + - Cancello/CancelloEx
* + - IO Priority / Bandwidth Reverse
* + Memory
* + - Dynamic memory pool
* + - SupeFetch
* + - ReadyBoost
* + - ReadyBoot
* + Boot
* + - Boot config database
* + - - HKLM\BCD00000000
* + - Windows Boot Manager \Bootmgr
* + - OS loader \Systemroot\System32\Winload.exe
* + - Session 0 隔离
* + - 控制台 Session 1
* + - Halt improvement
* + Reliability
* + - KTM (Transaction)
* + - Volume shadow copy
* + - Windows error reporting
* + - - WER service
* + Security
* + - BitLocker
* + - Code Integrity Verification
* + - Protected process
* + - ASLR
* + - UAC
* .NET
* + .NET (user exe) => user dll (delegated) => CLR DLLs (Com Server) => Windows API DLL => Kernel

## II
* x86 CPU
* + Real mode (Ring 0)
* + Protected mode (Ring 0 / 3)
* + Virtual 8086 mode
* + Supervisor mode
* + SMM (System Mangerment Mode) / Hypervisor mode (Ring -1) / 系统管理模式
* DPL (Descriptor Privilege Level) / CPL (Current) / RPL (Requested)
* + [ref](http://blog.csdn.net/huangkangying/article/details/44966585)
* + [Descriptor/Selector](http://blog.csdn.net/q1007729991/article/details/52538080)
* + [CS-selector-CPL-RPL](http://www.voidcn.com/article/p-ycohdqkm-wd.html)
* + [How-RPL-determined](https://www.zhihu.com/question/26188312)
* U/S (User/Supervisor)
* Kernel
* + INT 2E
* + sysenter/sysexit
* + SYSENTER_CS_MSR / SYSENTER_ESP_MSR / SYSENTER_EIP_MSR
* Address
* + Logical address: [Segment Selector:Offset]
* + Linear address: Selector=>GDT(CR3)=>Segment base address + offset
* + Virtual address: Offset
* + Physical address: Linear address=>Page Table(TLB/PGD/PMD/PDE/PTE)=>Hardware
* + 64bit segment is forbidden
* CR3
* + PDBR (page directory base register)
* + CR3 as part of context (including EFLAGS, EIP)
* Session
* NTOS (kernel-mode services)
* + Ntoskrnl.exe
* + - kernel (nt!Ke) / executive / dll api / kernel service
* + - initialization / boot
* + - - I/O manager => boot driver + system_start driver
* + - - SMSS.exe (session manager)
* HAL (hardware-adaptation/abstraction layer)
* + HAL!
* Drivers
* NTOS Kernel
* + processors (x86/Alpha/...)
* + context switching / thread scheduler
* + exception / interrupt dispatch
* + OS synchronization primitives
* + nt!Ke*
* IDT (Interrupt Descriptor Table)
* Windows Subsystem
* + 1 kernel, n subsystem
* + csrss.exe (Client/Server Runtime Server Subsystem)
* + winsrv.dll (console windows, harderror)
* + csrsrv.dll (process, thread, debug)
* + basesrv.dll (security, login)
* + win32k.sys
* + - GDI (draw)
* + - USER (input)
* Thread
* + schedule unit
* + task
* + [TSS (task state segment)](http://www.cnblogs.com/yasmi/articles/5198138.html)
* + KTHREAD
* + TEB
* + main/wmain/WinMain/wWinMain
* + return/ExitThread/TerminateThread/Process exits
* Process
* + thread container
* + OS program unit
* + EPROCESS
* + - PEB
* + Exit
* + - from main
* + - ExitProcess
* + - TerminateProcess from another process
* + - all thread exits

## III
* thread schedule
* + ready
* + end of time slice
* + drop running
* + change in priority
* + change in processor affinity
* context-switching
* + MLFQ: 32 level
* + thread context
* + - IP
* + - Stack pointer
* + - Page table directory pointer
* thread virtual memory
* + user 2gb/3gb (/3GB /USERVA)
* + free/reserving/committed
* Process memory
* + private bytes: allocated for self-process
* + virtual bytes: reserved for self and shared (like DLL)
* + working set: physical memory used
* Memory map file
* + DLL
* Paging file
* Thread stack
* + reserve 1MB, commit 2 page
* Heap
* + default 1MB
* + HeapCreate/HeapAlloc/HeapReAlloc
* DLL
* + DllMain
* + - DLL_PROCESS_ATTACH/DLL_PROCESS_DETACH
* + - DLL_THREAD_ATTACH/DLL_THREAD_DETACH
* + Known DLL
* + DLL hook
* Exception
* + trap handler => exception dispatcher
* + - debugger (first) LPC
* + - frame-based handlers
* + - debugger (second change) LPC
* + - environment subsystem LPC
* + - kernel default handler
* + WER