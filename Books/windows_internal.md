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

## IV
* Preemption
* Interrupt
* 80386
* + Segment:Offset => Selector:Offset
* + segment => segment + page
* virtual memory
* + page <-> pagefile.sys
* + #PF (#4)
* + page out
* + paged pool / non-paged pool
* + GDT/LDT
* + PAE/AWE
* + application memory
* + /3GB /USERVA
* #GP (#13)
* + kill user-mode process
* + [IRQ(Interrupt-ReQuest)](http://guojing.me/linux-kernel-architecture/posts/irq-and-interrupt/)
* + [IRQL](https://blogs.msdn.microsoft.com/doronh/2010/02/02/what-is-irql/)
* + [Driver-document](https://msdn.microsoft.com/en-US/library/windows/hardware/dn550976)
* + [IPL(Interrupt Priority Level)](https://en.wikipedia.org/wiki/Interrupt_priority_level)
* + [IRQL_less_or_equal](https://docs.microsoft.com/en-us/windows-hardware/drivers/debugger/bug-check-0xa--irql-not-less-or-equal)
* Permission
* + SID (Security ID)
* + SAM (Security Account Manager)
* + Logon
* + GINA (Graphical identification and authentication)
* + Access Token
* + ACL (access-control list)
* + ACE (access-control entry)
* + Access Mask
* + Ownership
* Hardware
* + HAL (hardware abstraction layer)
* + Device driver
* + WDM (windows driver model)
* + plug & play
* I/O
* + async/synchronous
* + mapped file I/O
* + I/O request packet (IRP)
* Store
* + Sector
* + Partition
* + Disk
* + Volume
* + IDE/(p)ATA/SATA/SCS/iSCSI/SAN
* + Basic/Dynamic/LDM/GPT
* Network
* + Winsock
* + RPC (remote procedure call)
* + Web access APIs
* + Named pipes and mailslots
* + NetBIOS
* + Other
* + name resolution
* + net protocols

## V 
* Sysinternal
* process explorer
* process monitor
* autorun
* psexec
* tcpview
* pagedefrag

## VI
* UAC
* + SID
* + Priority
* + virtual redirection
* Process isolation
* + MIC
* + - ACL for files
* + UIPI

## VII Startup
* ROM POST (power on self-test)
* BIOS/EFI (Extended Firmware Interface)
* MBR (Main Boot Record)
* Boot sector
* NTLDR / WinLoad
* + 16bit real mode -> 32bit protected mode
* + enable paging
* + SCSI hdd => BtBootDD.sys / Other hdd => INT 13
* + hiberfil.sys ? => restore Hibernate
* + boot.ini
* + F8 options
* + load and execute ntdetect.com
* + - collect basic informations
* + - - time/bus type/IO device/port/GPU
* + start progress bar / splash
* + load Ntoskrnl.exe/HAL.dll
* + load system Hive
* + execute entrance of Ntoskrnl.exe
* Ntoskrnl/HAL/BOOTVID/KDCOM
* SMSS.exe
* CSRSS.exe
* WinLogon.exe
* CPU复位 -> EFI + BootMgr + WinLoad / 传统BIOS + MBR + Boot sector + NTLDR -> NTOS -> SMSS -> CSRSS / WinLogon -> LogonUI / Services / LSASS -> USERINIT / SvcHost
* Startup files
* + ntldr
* + boot.ini
* + hiberfil.sys
* + io.sys
* + msdos.sys
* + NTDETECT.COM
* + Pagefiles.sys
* Ntoskrnl.exe
* + See Note I
* KeStartAllProcessors
* + For every CPU
* + - Setup GDT / IDT / ISS
* + - Allocate TSS/Stack for double fault
* + - Allocate TSS/Stack for NMI interrupt
* + - Allocate DPC Stack
* + - ProcessorState->ContextFrame->EIP = KiSystemStartup
* + - Call KiInitializePcr (Processor Control Region) & PRCB (processor control block)
* + - Call HalStartNextProcessor
* NTOS
* + KiSystemStartup (Idle process)
* + - ++KeNumberProcessors
* + - HalInitializeProcessor
* + - KdInitSystem (debug engine)
* + - KiInitializeKernel (crate idle process / start executive)
* + - - KiInitSystem (Only for CPU 0 [bootstrap CPU])
* + - - KeInitializeProcess (Idle process)
* + - - ExpInitializeExecutive (Phase 0 / first debug condition PID = 0) => System process => SMSS process
* + - - - Memory manager (page table & ds)
* + - - - Object manager (ObInitSystem & namespace)
* + - - - Security (SeInitSystem & token)
* + - - - PsInitSystem (0, LoaderParaBlock)
* + - - - - define process / thread
* + - - - - PsActiveProcessHead (record active process thread linked list)
* + - - - - Create a PsIdleProcess (idle)
* + - - - - Create system process (global PsInitialSystemProcess) and thread, [PsInitialSystemProcess] = Phase1Initiaization
* + - - - PnP manager (initialize executive resources)
* + - - Decrease IRQL = DISPATCH_LEVEL
* + - - Call KiIdleLoop (back to idle process)
* Executive Initialization
* + Phase 0
* + - KiInitializeKernel => ExpInitializeExecutive
* + - Single thread environment
* + Phase 1 (Phase1Initialization)
* + - Phase1Initializeation in System process
* + - Create multiple threads
* + - HalInitSystem
* + - - HalpInitReversedPages
* + - - HalpInitNonBusHandler
* + - - HalpGetFeatureBits
* + - - HalpEnableInterruptHandler
* + - InbvEnableBootDriver
* + - InbvDriverInitialize
* + - InbvEnableDisplayString(0)
* + - DisplayBootBitmap
* + - PoInitSystem
* + - Hal!HalQueryRealTimeClock
* + - KeSetSystemTime
* + - PoNotifySystemTimeSet
* + - InbvUpdateProgressBar(0x05)
* + - ----00% - 05% Now system has 2 thread----
* + - ObInitSystem
* + - ExInitSystem (Semaphore / mutex / event / timer)
* + - KeInitSystem (scheduler, service dispatcher)
* + - KdInitSystem (debugger engine linked list)
* + - SeInitSystem
* + - InbvUpdateProgressBar(0x0a)
* + - ----05% - 10% Now system has 2 thread, InbvRotateGuiBootDisplay + System----
* + - MmInitSystem(1, LoaderParaBlock, x) (Section object / Memory manager system thread)
* + - CcInitializeCacheManager (Filesystem cache structure)
* + - CmInitSystem1 (Config manager \Registry)
* + - CcPfInitializePrefetcher (initialize prefetch)
* + - InbvUpdateProgessBar(0x0f)
* + - ----10% - 15% Now many threads, but all are in WrQueue waiting, since Phase1 in MLFQ Priority=31----
* + - ExpRefreshTimeZoneInformation
* + - FsRtlInitSystem (init filesystem)
* + - KdDebuggerInitialize1 (kdcom!KdCompInitialize1)
* + - PdInitSystem (PnP manager)
* + - InbvUpdateProgressBar(0x14)
* + - ----15% - 20% Now ...----
* + - LpcInitSystem (init LPC subsystem, port type) LPC (local procedure call)
* + - boot logging = ON => log file
* + - InbvUpdateProgressBar(0x19)
* + - ----20% - 25%----
* + - I/O manager init (load device drivers)
* + - IoInitSystem
* + - ----25% - 75%----
* + - MmInitSystem(2, LoaderParaBlock) (release memory used by boot)
* + - Write to registery if boot in security mode
* + - InbvUpdateProgressBar(0x50)
* + - ----75% - 80%----
* + - Kel386VdmInitialize (init DOS)
* + - KiLogMcaErrors (check and record MCA (Machine Check Architecture))
* + - PoInitSystem(1) (Power manger phase 1)
* + - PsInitSystem(1, LoaderParaBlock) (process manager phase 1)
* + - - PspInitializeSystemDll (NTDLL.dll)
* + - - PspMapSystemDll (NTDLL.dll)
* + - InbvUpdateProgressBar(0x55)
* + - ----80% - 85%----
* + - MmFreeLoaderBlock (release LOADER_PARAMETER_BLOCK)
* + - SeRmInitPhase1 (init security reference monitor phase1, create command server thread with LSASS)
* + - InbvUpdateProgressBar(0x5a)
* + - ----85% - 90%----
* + - RtlCreateUserProgress (create smss process)
* + - FinalizeBootLogo
* + - ZwResumeThread
* + - InbvUpdateProgressBar(0x64)
* + - InbvEnableDisplayString(1)
* + - ZwWaitForSingleObject (wait 5mins, if 5s smss exits, then bluescreen)
* + - Then Zw... turns into zero page
* + - ----90% - 100%----
* + Phase2
* + - global varaible InitializationPhase = 2
* SMSS
* + session manager subsystem
* + first user mode process
* + BootExecute
* + PendingFileRenameOperations
* + Paging file and Init registery
* + Load and Init win32k.sys
* + create CSRSS process
* + create WinLogon process
* WinLogon
* + create LSASS (local security authority subsystem service) process
* + create LogonUI process (WinXP)
* + Load GINA (MSGINA.DLL) logon dialogue
* + create Services.exe
* Logging
* + GINA => LSASS => Token => USERINIT => logon + init + shell => Exit

## VIII Memory
* Logical address (CPU) =>(MMU) Physical address
* Compile/Loader address (PIE/PIC)
* Runtime address
* Traditional
* Object-based
* + ACLs
* Instant-time
* Components
* + 6 system threads
* + - Working set manager (P = 16)
* + - Process/stack swapper (P = 23)
* + - Modified page writer (P = 17)
* + - Mapped page writer (P = 17)
* + - Dereference segment thread (P = 18)
* + - Zero page thread (P = 0)
* XP/2003
* + 64bit (1TB physical memory)
* + DEP (data execution prevention)

## IX Security
* Principals
* + single user
* + group of users
* + computer
* + identified by a unique human-readable name and a machine-readable identifier (SID)
* + database: account <=> principal
* SID (Security Identifier)
* + variable-length data structure (unlike a GUID - 128bit)
* + hierarchical structure 
* + - S-R-I-SA-SA-SA
* + - R (reversion number)
* + - I (48bit identifier authority, unique namespace)
* + - SA (sub authority)
* Credential
* Password (OWF)
* Security Subsystem
* + Authority and Domain Controller
* + - authenticate principals
* + Local Security Authority
* + - LSASS.exe NetLogon
* + LSA Server service
* + Security Support Providers/Authentication Package (SSP/AP)

## X Driver & Hardware
* I/O subsystem
* + define infrastructure
* + I/O interface
* + Packet Driven - IRP
* + loadable, layered drivers
* + Synchronous I/O
* + Asynchronous I/O
* Device drivers
* + Legacy drivers (NT 4.0)
* + WDM drivers
* + - Bus/Function/Filter
* + Filesystem drivers
* + Printer & Graphics drivers
* + Network drivers (NDIS)
* + Port vs Miniport drivers
* + - Video / SCSI
* + Class vs Miniclass drivers
* + - Disk / HID / CDROM
* I/O Subssytem  (Nt!)
* I/O Manager (Io!)
* Driver support routine (Io!/Ex!/Ke!/Mm!/Hal!/FsRtl!)
* Kernel mode device drivers
* HAL I/O access routines
* I/O port and register
* Plug & Play Manager
* + detecting devices / loading appropriate drivers
* + kernel vs user mode PnP manager
* + arbiter of resources and resouce balancing
* + provides notification mechanism for drivers
* Device Enumeration
* + user plug in a new device
* + - bus driver notices the arrival
* + - notifies the PnP manager
* + - enumerate the device
* + - retrieves identification information for the device
* + - device and instance ID
* + - device capabilities
* + - Hardware ID(s) and Compatible ID(s)
* + - Information passed to Usermode Plug & Play manager
* Power Manager
* + enables to suspend your machine or power doen your device when idle
* + work closely with the I/O & PnP manager
* + requires ACPI BIOS support
* + ACPI defines various power level for a system and for devices
* + Device drivers must be responsive to Power manager requests (IRPs)
* WMI (windows management instrumentation)
* + MMC =>(DCOM) => CIM Object Manager => GIM (gommon information) => Object providers => WDM/SNMP/DMI(RPC)/Win32 => IRP_MJ_SYSTEM_CONTROL
* WDM
* IRP (IO Request Packet)
* + travel down a driver stack
* + IRP stack location
* + create/read/write/PNP/devioctl/cleanup/close
* Layering Driver
* + Io Attach/Detach/Delete Device
* + dispatch table
* Sync IOMgr (IopParseDevice) =>(IRP) IoCallDriver => Each driver in turn
* Async IRP =>(STATUS_PENDING) => Interrupt/DPC => APC
* NT IO API
* + Establish IO Handles
* + IO Completion
* + Actual IO Operation
* + Meta IO
* + Administrative operations
* Driver as DLL
* + class drivers => miniport
* + USB/1394/SCSI/ATAPI/Serial/NICs
* Sleep/Hibernate/D-states

## XI Store
* volatile devices
* + Floppy
* + HDD
* + Optical Media
* + SAN
* + Tape
* + Removable Media
* storage stack
* + application
* + I/O subsystem
* + filesystem
* + Volume snapshot
* + Volume management
* + Partition management
* + Class
* + Port/Miniport
* + Disk subsystem
* MBR (Master Boot Record)
* + 磁盘签名 [0x1b8]
* + 分区表 [0x1be]
* + 扇区签名 [55AA]
* + primary / extended
* Filesystem
* + FAT12/16/32 / CDFS / UDF / NTFS
* FAT
* + simple file allocation table
* + linked list file access
* NTFS
* + 多重数据流
* + Unicode name
* + 文件属性索引
* + 动态坏扇区记录
* + hard link
* + 基于文件的压缩 + 稀疏文件
* + journals
* + encryption
* + POSIX
* + 磁盘碎片整理
* + reparse point / junction
* Boot Sector
* + BPB (BIOS Parameter Block)
* + OEM String [0x3-0xa]
* + Boot code
* MFT (Main File Table)
* + Volume
* + Cluster
* + MFT
* + $Mft [1st sector]
* + $MftMirr (backup of $Mft)
* + $LogFile (Volume structure and metadata log)
* + $Volume (NTFS volume basic information)
* + $AttrDef (file attributes)
* + $\ (root) [11th sector]
* + - LCN 35793
* + $Bitmap (cluster bitmap)
* + $Boot (boot sector)
* + $BadClus (bad sector sign)
* + $Secure (authority)
* + $Upcase (lower-upper case)
* + $\Extend (extended partition)
* + - $Quota
* + - $ObjID
* + - $UsnJrnl
* + - $Reparse
* + NTFS Metadata + File record + Directory record
* File Selector: Standard Information + Filename + Data + HPFS extended attribute
* + Data
* + - VCN
* + - LCN
* + - Number of clusters
* + Directory
* + - dense: index root + allocation + bitmap
* + - sparse: directly list of data
* + - B+ Tree

## XII Net protocol
* OSI
* + Application
* + - File I/O, Named Pipes or Mailslots
* + Presentation
* + - Environment subsystem
* + - Provider interface <=> SMB
* + Session
* + - Provider interface <=> SMB
* + - Redirector
* + - NetBIOS
* + - TDI (transport driver interface)
* + - Windows Sockets
* + Transport
* + - NetBIOS
* + - TDI (transport driver interface)
* + - Windows Sockets
* + - NetBEUI
* + - TCP/IP
* + Network
* + - NetBEUI
* + - TCP/IP
* + Data Link
* + - NetBEUI
* + - TCP/IP
* + - NDIS (Network driver interface specification) Interface/Environment/Drivers <=> NDIS protocol
* + Physical
* + - NDIS Interface/Environment/Drivers <=> NDIS protocol
* + - Ethemet
* + - Token Ring
* API
* + Windows I/O
* + - Kernel32.dll+Ntdll.dll => Rdbss.sys => TDI => NTFS+FAT
* + - Or by Object manager
* + WNet
* + Windows named pipe
* + - bidirection / reliable / based-on-connection
* + - CreateNamedPipe/ConnectNamedPipe/CloseHandle
* + Windows mailslot
* + - single direction / in-reliable / can broadcast
* + - CreateMailslot/GetMailslotInfo
* + NetBIOS
* + Winsock (Windows Sockets)
* + - start winsock
* + - create socket
* + - bind/listen/wait/connect/send/recv/interrupt socket
* + - SPI (service provider interface)
* + - Layered network services (VPN/LDAP/NLB/FRS/DFS/QoS/IPSec)
* + - TCP/IP / NetBEUI/Apple Talk/IPX/SPX/ATM/IrDA (Infrared Data Association)
* + - DNS/Active Directory/IPX/SPX
* + RPC
* + DCOM
* + CIFS (Common Internet File System) - SMB
* + WebServices
* + TDI
* + - driver
* + - asynchronous
* + - clients
* + - - AFD/MSFS/NPFS
* + - TDI transport <=>(NDIS IRP) NDIS library (miniport/protocol) <=> HAL
* NDIS
* + media sense
* + TCP/IP task offloading
* + fast packet forwarding
* + wake on LAN
* + 1394/USB
* Microsoft TCP/IP
* + Application and User Mode Service
* + - NetBIOS
* + - RPC
* + - Win32 WNet/WinlNet
* + - WinSock
* + Application Interfaces
* + - RPC
* + - WNet
* + - Winlnet
* + - NetBIOS support
* + - WinSock
* + Kernel
* + - named pipe
* + - redirector/server
* + - NetBT
* + - AFD
* + - TCP
* + - IP
* + - - ICMP/IP Forwarder/IP Filtering/IGMP/ARP
* + - Traffic Control
* + - - Packet queue/sceduler
* + Driver Interfaces
* + - NDIS Wrapper
* + - - NDIS WAN Miniport wrapper
* + - - - PPTP/Async/X.25/ISDN
* + - - - Frame Relay/ATM/Ethenet/FDDI/Token Ring
* + Implementation
* + - Different network/card
* + - Logical multi-homing
* + - Internal IP routing capabilitiy
* + - IGMP (IP Multicasting) support
* + - Duplicate IP address detection
* + - DGP (Dead gateway detection)
* + - PMTU (automatic path maximum transmission unit) discovery
* + Service
* + - DHCP (Dynamic Host Configuration Protocol)
* + - WINS (Windows Internet Name Service) NetBIOS
* + - DNS (Domain Name Server)
* + - PPTP (Point-to-Point tunneling protocol) VPN
* + - PPP/SLIP 特别
* + - LPR/LPD 网络打印
* + - SNMP agent
* + - IIS (Microsoft Internet Information Server)
* + - finger/FTP/Telnet
* + - Character Generator/Daytime/Discard/Echo/Quote of the Day
* + - arp/hostname/ipconfig/nbtstat/netstat/ping/route/tracert

## XIII BSoD
* stop code
* BugCheck -> BugCheckEx -> KeBegCheck2
* + disable interrupt
* + stop other CPU
* + draw BSoD
* + call register callback
* + save dump
* BSoD procedure
* + collect information (process/parameter/error module)
* + kernel debugger
* + disable interrupt
* + CPU.IRQL = HIGH_LEVEL
* + stop other CPUs
* + draw BSoD
* + - nt!InbvAcquireDisplayOwnerShip
* + - nt!InbvResetDisplay
* + - nt!InbvSolidColorFill
* + - nt!InbvSetTextColor
* + - InbvDisplayString
* + call registed bug check callback
* + - KeRegisterBugCheckCallback
* + KdInitSystem init kernel debug engine
* + IoWriteCrashDump => dump
* + - snapshot
* + - fail => disable paging file, no enough space
* + - SMSS => NtCreatePagingFile => WinLogon => SaveDump => Memory.dmp
* + auto restart
* + KiBugCheckDebugBreak

## XIV - XV Debug
* debugger
* + msdev
* + ntsd (NT symbolic debugger)
* + cdb (console debugger)
* + kd (kernel debugger)
* + windbg
* dump
* + complete memory dump
* + kernel memory dump
* + small memory dump (64KB)
* 