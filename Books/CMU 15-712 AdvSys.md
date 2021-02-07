# Advanced Operating System and Distributed System

[winter2020](https://www.cs.cmu.edu/~15712/syllabus.html)



## A Few Classics

* The End-to-End Argument
  * The function in question can completely and correctly be implemented ONLY with the knowledge and help of the application standing at the endpoints of the communication system. 
  * Therefore, providing that questioned function as a feature of the communication system itself is not possible
  * Application
    * Careful file transfer
      * Enforce desired reliability guarantees only at end points (but each of the steps must be sufficiently reliable)
    * Other reasons for end-to-end vs. low-level 
      * Other apps using the low-level may not need these checks 
      * Low-level may have too little information to do checks well
    * Delivery guarantees
    *  Secure transmission of data
    *  Duplicate message suppression
      * Duplicates may be caused by the end-point application
    * Guaranteeing FIFO message delivery
    * Transaction management
  * Challenges
    * How to identify the “ends”?
      * Your application may be “internal” to another application
    * What to still include at the low level?'
      * Sometimes an incomplete version of the function provided by the communication system may be useful as a performance enhancement.
    * • Tension with clean layering, clean APIs
* Hints for Computer System Design
  * Designing a computer system is different from designing an algorithm
    * The external interface is less precisely defined, more complex, more subject to change
    * The system has much more internal structure, and hence many internal interfaces
    * Measure of success is much less clear
  * Defining interfaces is the most important part of system design
    * Each interface is a small programming language
    * Conflicting goals:
      * simple, complete, admit a sufficiently small/fast implementation
  * Functionality: Keep it Simple
    * Do one thing well
      * Don’t generalize
      * Get it right
      * Don’t hide power
      * Use procedure arguments
      * Leave it to the client
    * Service must have fairly predictable cost.
    * Interface must not promise more than the implementer knows how to deliver.
    * Bad choice for interface can lead to inefficiencies.
      * O(n^2) algorithm for FindNamedField
    * Clients should only pay for power they want (e.g., RISC vs. CISC).
    * Purpose of abstraction is to hide undesirable properties; desirable ones should not be hidden.
  * ![image-20200914165903251](D:\OneDrive\Pictures\Typora\image-20200914165903251.png)
  * Functionality: Continuity
    * Keep basic interfaces stable
    * Keep a place to stand
  * Making Implementations Work
    * Plan to throw one away
    * Keep secrets:  ability to improve each part separately
    * Divide and conquer
    * Use a good idea again: instead of generalizing it
  * Handling All the Cases
    * Make normal case fast
    * Make worse case ensure progress
  * Speed: Interface
    * Split resources in a fixed way
    * Use static analysis
    * Dynamic translation from convenient to fast
  * Speed: Implementation
    * Cache answers
    * Use hints (may be wrong)
    * When in doubt, use brute force
    * Compute in background
    * Batch processing
  * Speed: Completeness
    * Safety first
    * End-to-end
    * Shed load
  * Fault-tolerance
    * End-to-end
      * For reliability
      * Can add intermediate checks for performance reasons, error codes for visibility reasons
      * Problems: Need cheap test for success. Can mask severe performance defects until operational at scale.
    * Log updates to record the truth about the state of an object
    * Make actions atomic or restartable (idempotent)
* The UNIX Time-Sharing System
  * Key Features of UNIX
    * Hierarchical file system incorporating demountable volumes
    * Compatible file, device, inter-process I/O
    * Ability to initiate asynchronous processes
    * System command language selectable on a per-user basis
    * Over 100 subsystems including a dozen languages
  * What Influenced the Design
    * Make it easy to write, test, and run programs
      * Interactive use
      * Interface to the file system is extremely convenient
      * Contents of a program’s address space are the property of the program (e.g., no file system control blocks)
    * Severe size constraint on the system & its software
    * The system was able to, and did, maintain itself



## Implementing Remote Procedure Calls

* Goal: Communication Across a Network Between Programs Written in a High-level Language
* Use Message Passing?
  * Would encounter same design problems
  * Procedure calls already in high-level languages
  * Aside: HPC community uses MPI (messages)
* Use Remote Fork?
  * Would encounter same design problems
  * Also, what do you return, entire contents of memory??
* Use Distributed Shared Memory? 
  * Need to represent remote addresses in PL (may need to extend address width)
  * Likely too costly, done at page granularity
  * Aside: Long history of research into general DSM (mixed success)
  * Aside: Successful specialized DSM: key-value stores, parameter servers
* Remote Procedure Calls Benefits
  * Make Distributed Computation easy
    * Procedure calls are a well-known & well-understood mechanism for transfer of program control and data
    * Clean & simple semantics; Simple enough to be efficient; General
    * Design goal: RPC semantics should be as close as possible to single-machine procedure call semantics (e.g., no time-outs)
  * Make semantics of RPC package as powerful as possible, w/o loss of simplicity or efficiency 
    * “We wanted to make RPC communication highly efficient (within, say, a factor of five beyond the necessary transmission times of the network).” 
  * Provide secure communication with RPC
* RPC Major issues regarding old design (before 1976)
  * Precise semantics of a call in the presence of failures
  * Semantics of address-containing arguments in the absence of a shared address space
  * Integration of remote calls into existing programming systems
  * Binding (how caller determines location/identity of callee)
  * Suitable protocols for transfer of data & control between caller and callee
  * How to provide data integrity and security in an open communication network
* System Components
  * When Arguments & Return result each fit in a single packet
    * ![image-20200918193621421](D:\OneDrive\Pictures\Typora\image-20200918193621421.png)
    * Caller periodically probes, and callee acks
      * Less work for server vs. pushing “I’m alive” messages
      * Caller can get “called failed” exception (unlike a local call)
  * ![image-20200918193727886](D:\OneDrive\Pictures\Typora\image-20200918193727886.png)
* Stubs
  * User-stub and server-stub are automatically generated, using Mesa interface modules (basis for separate compilation)
    * Specification Interface: List of procedure names, together with the types of their arguments and results
  * Lupine stub generator checks that user avoids specifying args/results that are incompatible with the lack of a shared address space
* Binding
  * ![image-20200918193900923](D:\OneDrive\Pictures\Typora\image-20200918193900923.png)
  * Naming: Use Mesa interface module name + instance
  * Grapevine distributed database
    * Maps type to set of instances
    * Maps instance to network address
  * Importing an interface has no effect on exporting machine’s data structures (scalability)
  * Unique identifier means bindings broken on server crash
  * Can only call explicitly exported procedures
  * Grapevine enforces access control, facilitates authentication
  * Options include importer specifies type and gets nearest
* Packet-level Transport Protocol
  * Up to factor of 10 faster than using general protocols
    * Not doing large data transfers
    * Goals: Minimize latency to get result & Server load under many users (minimize state info & handshaking costs)
  * Guarantee: If call returns, procedure invoked exactly once [[Q: once semantics]]
  * Do not abort on server code deadlock or infinite loop
  * When connection is idle, only a single machine-wide counter
  * Rate of calls on ExportInterface in a single machine limited to an average rate of less than one per second
* Minimizing Process Swap Cost
  * Maintain at each machine idle server processes ready to handle incoming packets (avoid process creates)
  * For simple RPCs, only 4 process swaps
  * Also, bypass SW layers for intranet RPCs
    * Modularity vs. performance trade-off
    * Nowadays: EDMA
* Multicasting or broadcasting can be better than RPCs
* Today's replacement
  * RPC `->` RMI (remote method invocation)
  * Naming (Grapevine) `->` key-value store containing hostname (IP address) & port number
  * RPC over UDP/IP (unreliable, more efficient), IP handles multi-packet arguments
  * Sun’s RPC (ONC RPC) system, with stub compiler rpc-gen, is widely used, e.g., in Linux; provides XDR, a common data representation in messages



## Time, Clocks, and the Ordering of Events in a Distributed System

* A system is __distributed__ if the message transmission delay is not negligible compared to the time between events in a single process.
* “Happened before” is only a partial ordering of events
  * should be without using physical clocks
    * clock skew
    * system specification
* Happened Before
  * Two events on same process are ordered
  * Message receipt ordered after associated message send
  * Transitivity: 𝑎 → 𝑏 and 𝑏 → 𝑐 implies 𝑎 → c
* Logical Clocks (aka. Lamport Clocks)
  * If `a -> b` then `Clock(a) < Clock(b)`
  * Satisfied if two conditions hold:
    * C1: If 𝑎 and 𝑏 are events in process $P_i$ , and 𝑎 comes before 𝑏, then $𝐶𝑙𝑜𝑐𝑘_𝑖(𝑎) < 𝐶𝑙𝑜𝑐𝑘_𝑖(𝑏)$
    * C2: If 𝑎 is the sending of a message by process 𝑃𝑖 and 𝑏 is the receipt of that message by process 𝑃𝑗 then `𝐶𝑙𝑜𝑐𝑘_𝑖(𝑎) < 𝐶𝑙𝑜𝑐𝑘_𝑗(𝑏)`
  * An implementation using timestamps:
    * IR1: Each process 𝑃𝑖 increments 𝐶𝑖 between any two successive events
    * IR2: 
      * (i) Send 𝑇𝑚 = 𝐶𝑖 ⟨𝑎⟩ as part of the event 𝑎’s message
      * (ii) Upon receiving that message, 𝑃𝑗 sets its 𝐶𝑗 to be ≥ its present value and > 𝑇𝑚
* Distributed Mutual Exclusion
  * Must release granted resource before can be granted again
  * Grant resources in order they are made
  * Every request is eventually granted (assuming no process fails to release a granted resource)
  * ![image-20200920212519757](D:\OneDrive\Pictures\Typora\image-20200920212519757.png)
  * Problem: System halts if one process fails
    * With logical time, no way to distinguish a failed process from a paused/delayed/slow process
  * Generalization: Works for any synchronization that can be specified in terms of a State Machine 〈𝑪, 𝑺, 𝒆: 𝑪 × 𝑺 → 𝑺 〉
    * E.g., 
      * C is all possible requests/releases resource commands, 
      * S is the queue of waiting request commands, 
      * 𝑒 is the transition function
    * Run same basic algorithm: A process can execute a command timestamped T when it has learned of all commands issued by all other processes with timestamps ≤ T
* Out-of-band communication
  * Strong Clock Condition: 𝒂 ⤇ 𝒃 implies 𝑪(𝒂) < 𝑪(𝒃)
    * where ⤇ denotes happened-before when also include out-of-band events 
* Vector Clocks
  * Each local clock is a vector of N values for N processes
    * [[Q: must be fixed number of processes?]]
  * 𝑷𝒊 increments i’th value of local clock on internal event
  * Include entire vector clock when send message
  * When 𝑷𝒋 receives a message with clock V:
    * Increment j’th value of local clock
    * Set local clock to be elementwise max of its local clock and V 
  * ![image-20200920214023358](D:\OneDrive\Pictures\Typora\image-20200920214023358.png)
  * 𝒂 → 𝒃 implies 𝑽 𝒂 < 𝑽(𝒃) 
  * 𝑽 𝒂 < 𝑽 𝒃 implies 𝒂 → b
  * Vector Clocks vs. Lamport's time clock
    * pro: more precise
    * cons: much larger clocks, more complex
* Physical Clocks
  * Let 𝑪𝒊(𝒕) denote the reading of clock 𝑪𝒊 at physical time t
    * Assume 𝐶𝑖(𝑡) is a continuous, differentiable function of 𝑡, except for isolated jump discontinuities where clock is reset
    * PC1: [assumed upper bound on rate of clock drift]
      * ![image-20200920214209683](D:\OneDrive\Pictures\Typora\image-20200920214209683.png)
  * Goal: Bound pairwise clock skew to at most ϵ
    * PC2: For all 𝑖,𝑗: |𝐶𝑖(𝑡) − 𝐶𝑗(𝑡)| < 𝜖 for small constant ϵ
  * How small must 𝜿, 𝝐 be to avoid anomalous behavior?
    * Let μ be the minimum physical time needed to transmit out-of-band communication
    * Can ensure that 𝐶𝑖(𝑡 + 𝜇) − 𝐶𝑗(𝑡) > 0 if we have 𝜖(1−𝜅) ≤ μ
  * A distributed implementation:
    * ![image-20200920214336048](D:\OneDrive\Pictures\Typora\image-20200920214336048.png)
    * Pros: No need for reference clocks; Clocks never set backwards 
    * Cons: Skew versus real time; Frequent neighbor communications
* Network Time Protocol (NTP)



## Distributed Snapshots: Determining Global States of Distributed Systems

* > A **snapshot algorithm** is used to create a consistent snapshot of the global state of a [distributed system](https://link.zhihu.com/?target=https%3A//en.wikipedia.org/wiki/Distributed_system). Due to the lack of globally shared memory and a global clock, this isn't trivially possible.

* [zhihu1](https://zhuanlan.zhihu.com/p/53482103), [zhihu2](https://zhuanlan.zhihu.com/p/42442713)

* [proof](http://matt33.com/2019/10/27/paper-chandy-lamport/), [flink-implementation](http://matt33.com/2019/10/20/paper-flink-snapshot/)

* System Model [[R: Y calculus, CSP system]]
  * Finite labeled, directed graph in which vertices represent processes & edges represent channels
  * ![image-20200921003128424](D:\OneDrive\Pictures\Typora\image-20200921003128424.png)
  * Channels have infinite buffers, in-order delivery, arbitrary but finite delays, are uni-directional & error-free
* Events
  * defined by $\langle p, s, s', c, M \rangle$
  * process `p`
  * state `s` of `p` immediately before the event
  * state `s'` of `p` immediately after the event
  * channel `c` (if any) whose state is altered by the event
  * message `M` (if any) sent/received along `c`
* ![image-20200921003846090](D:\OneDrive\Pictures\Typora\image-20200921003846090.png)
  * leads to inconsistent global state (when doing state transition)
* Global-State-Detection Algorithm
  * [[N: marker as barrier / timestamps in distributed clocks. Similar to flink/naiad streaming system?]]
  * Marker-Sending Rule for `p`
    * For each channel `c` outgoing from `p`:
      * `p` records state, then sends a marker as its next message on `c`
  * Marker-Receiving Rule for `q`
    * On receiving a marker along a channel `c`:
      * If `q` has not recorded its state then `q` records its state; `q` records the state `c` as empty (initiating a snapshot)
      * Else `q` records state of `c` as the sequence of messages received along `c` after `q`'s state was recorded yet before `q` received the marker along `c` (propagating a snapshot)
  * Termination:
    * As long as at least 1 process spontaneously records it state & no marker remains stuck in a channel & the graph is strongly connected, then all processes record their states in finite time
  * ![image-20200921004807892](D:\OneDrive\Pictures\Typora\image-20200921004807892.png)
  * Why is the state meaningful (所有记录的状态累加并不是系统真实达到的状态之一，但是却可以跟某个真实的状态对等)?
    * There is a computation where
      * Sequence of states before the DS algorithm starts is unchanged
      * Sequence of states after the DS algorithm ends is unchanged
      * Sequence of events in between may (only) be reordered
      * Recorded global state is one of the states in between
    * Theorem
      * There is a computation `seq’` derived from `seq` where
        * Sequence of states before/after DS starts/ends is unchanged
        * Sequence of events in between may (only) be reordered
        * Recorded global state S* is one of the states in between
      * Prerecording event: occurs at `p` before `p` records its state 
      * Postrecording event: …after…
      * `seq’` is `seq` permuted such that all prerecording events occur before any postrecording events
      * ![image-20200921005357241](D:\OneDrive\Pictures\Typora\image-20200921005357241.png)
      * ![image-20200921005416841](D:\OneDrive\Pictures\Typora\image-20200921005416841.png)
      * [[Q: so, we get a re-ordered state because pre/post-recordings are re-ordered?]]
* Collecting the Global State
  * Each `p` repeatedly floods along all outgoing channel what it knows about the global state
  * [[N: kind like spreading routing table, Dijkstra?]]
* Stability Detection
  * Input: Any stable property `y` (consistent property)
    * Stable: `y(S)` implies `y(S’)` for all global states `S’` reachable from `S`
  * Return:
    * FALSE implies property `y` did not hold when DS algorithm starts
    * TRUE implies property `y` holds when DS algorithm ends
    * Note: If `y` starts holding after DS start, ok to return FALSE
  * SD Algorithm:
    * Record a global state `S`*; Return `y(S*)`
    * Correctness:
      * `y(S*)=TRUE` implies `y(DS end state)=TRUE [reachable, y stable]`
      * `y(DS start state)=TRUE` implies `y(S*)=TRUE [reachable, y stable] `
    * Proof sketch
      * `seq’` is a legal computation
      * `S*` is the global state in `seq’` at the transition point
      * Swapping Post & Pre
        * ![image-20200921010141958](D:\OneDrive\Pictures\Typora\image-20200921010141958.png)
        * ![image-20200921010148648](D:\OneDrive\Pictures\Typora\image-20200921010148648.png)



## Detecting Concurrency Bugs: Eraser & TSVD

* Eraser: A Dynamic Data Race Detector for Multithreaded Programs

  * Data Race: 

    * Two concurrent threads access a shared variable
    * At least one access is a write
    * The threads use no explicit mechanism to prevent the accesses from being simultaneous

  * Monitors [Hoare 1974] prevent data races at compile time, but only when all shared variables are static globals

  * Static Analysis must reason about program semantics

  * Happens-before Analysis

    * E.g., using vector clocks
      * Inter-thread arcs are from unlock L to next lock L; otherwise, report a data race
      * Check each access for conflicting access unrelated by →
    * Difficult to implement efficiently
      * Require per-thread info about concurrent accesses to each shared-memory location
    * Effectiveness highly dependent on interleaving that occurred
      * Can miss a data race
      * ![image-20200922020423714](D:\OneDrive\Pictures\Typora\image-20200922020423714.png)

  * Lockset Algorithm (1st version)

    * `locks_held(t)`: set of locks held by thead `t`
    * for each `v`, initialize `C(v)` to the set of all locks
    * on each access to `v` by thread `t`
      * set `C(v) := C(v) ∩ locks_held(t)`
      * if `C(v)` is empty, then issue a warning
    * can't handle read sharing
    * Empty lockset `C(v)` should be reported only if `v` is Shared-Modified
    * ![image-20200922020858800](D:\OneDrive\Pictures\Typora\image-20200922020858800.png)

  * Lockset Algorithm in Shared-Modified State

    * `locks_held(t)`: set of locks held by thread `t` 
    * `write_locks_held(t)`: set of locks held in write mode by `t`
    * When enter Shared-Modified state:
      * for each `v`, initialize `C(v)` to the set of all locks
      * on each read of `v` by thread `t`
        * set `C(v) := C(v) ∩ locks_held(t)`
        * if `C(v)` is empty, then issue a warning
      * on each write of `v` by thread `t`
        * set `C(v) := C(v) ∩ write_locks_held(t)`
        * if `C(v)` is empty, then issue a warning
    * Correct: Locks held purely in read mode do not protect against a data race between the writer & some other reader thread

  * Implementation

    * Binary instrumentation 
    * Instruments lock/unlock calls, thread init/finalize to maintain `lock_held(t)`
      * [[Q: like a sanitizer?]]
    * Instruments each load/store, malloc to maintain `C(v)`
      * 32-bit (aligned) words
      * But not stack-based accesses (stack is assumed private)
      * 32-bits in “shadow memory” for each word (holds 2-bit state + thread ID or “lockset index”)
      * [[Q: overhead?]]
    * Warnings report file, line number, active stack frames, thread ID, memory access address & type, PC, SP
      * Option: Log all accesses to v that modify `C(v)`
    * False Alarms & Annotations
      * Memory reused without resetting shadow memory
        * When app uses private memory allocator
        * Annotation: EraserReuse(address, size) – reset to Virgin
      * Synchronization outside of instrumented channels
        * E.g., Private lock implementations of MultiRd/SingleWr locks
        * E.g., Spin on flag
        * Annotation: `EraserReadLock(lock),EraserReadUnlock(lock),EraserWriteLock(lock),EraserWriteUnlock(lock)`
      * Benign races
        * Annotation: `EraserIgnoreOn(), EraserIgnoreOff()`

  * Performance

    * typical app slowdown: 10x-30x

      * half due to procedure call at every load/store

      * Today: dynamic binary instrumentation (DBI) using inlining for short code segments

      * > Eraser is fast enough to debug most programs and therefore meets the most essential performance criterion.

    * ![image-20200922021813931](D:\OneDrive\Pictures\Typora\image-20200922021813931.png)

* Race Detection in OS Kernel

  * OS often raises the processor interrupt level to provide mutual exclusion
    * Particular interrupt level inclusively protects all data protected by lower interrupt levels
    * Solution: Have a virtual lock for each level; when raise level to n, treat this as first n per-level locks acquired
  * OS makes greater use of POST/WAIT style synch, e.g., semaphores to signal when a device op is done
    * Problem: Hard to infer which data a semaphore is protecting
  * Race Detection in Kernels
    * DataCollider [OSDI’10]
      * Randomly delays a kernel thread to see if racy access occurs while stalled (but can’t use for time-critical interrupts) 
      *  “Active Delay Injection”
    * Guardrail [ASPLOS’14] for kernel-mode drivers addresses these challenges
      * Single thread can race itself (!)
      * Synchronization invariants based on context of device state
      * Synchronization based on deferred execution using softirqs or timers
      * Mutual exclusion via HW test-and-set or disabling interrupts & preemption
      * ![image-20200922022055671](D:\OneDrive\Pictures\Typora\image-20200922022055671.png)

* Representing `C(v)`s

  * Represent by small integer “lockset index” into table
  * Append-only table
  * Lock vectors sorted
  * Cache results of set intersections
  * Shadow word: 30-bit index, 2-bit state
    * Shadow memory doubles size of memory
    * Aside: Can fix with 2-level shadow memory
    * [[Q: for 64bit, just use the hole?]]

* Data Race Detection in 2000s

  * Valgrind tools: Helgrind, DRD, ThreadSanitizer
    * Use Happens-before
    * Only ThreadSanitizer also uses Lockset
    * Early versions of Helgrind used Lockset
  * Intel ThreadChecker
    * Uses Happens-before
  * Cilk: Nondeterminator, Cilkscreen
    * Relies on fork-join structure of Cilk programs to determine whether two conflicting accesses are ordered
    * Reports race or that no race can occur with the given input

* Efficient Scalable Thread-Safety-Violation Detection

  * ![image-20200922022348457](D:\OneDrive\Pictures\Typora\image-20200922022348457.png)
  * TSVD: A scalable dynamic analysis tool for TSVs
  * ![image-20200922022417635](D:\OneDrive\Pictures\Typora\image-20200922022417635.png)
  * How to achieve zero false positive?
    * Report after violation
    * inject delays to trigger violations
  * What are the potential unsafe calls?
    * ![image-20200922022504878](D:\OneDrive\Pictures\Typora\image-20200922022504878.png)
    * TSVD: likely Racing calls
      * Two conflict methods
      * Called from different threads
      * Accessing the same object
      * Having close-by physical timestamps
        * [[N: concurrent logical is impossible to achieve in reality]]
  * Synchronization inference
    * One common effect of all synchronizations:
      * If `m1` synchronized before `m2` and `m1—m2` are nearby
      * `->` delay to `m1` will cause delay to `m2`
    * transitive delay
      * ![image-20200922022722019](D:\OneDrive\Pictures\Typora\image-20200922022722019.png)
  * ![image-20200922022739837](D:\OneDrive\Pictures\Typora\image-20200922022739837.png)
  * TSVD infers synchronizations and uses them in the same run.
    * Easy integration: oblivious to synchronization patterns
    * Lightweight: 30% overhead
    * Accuracy: 0 false positives
    * Coverage: better than HB-based detection tools 
    * https://github.com/microsoft/TSVD
  * Limitations
    * Finds TSVs but not other data races or timing bugs
    * Assumes for each data structure:
      * Methods can be grouped into a read set and a write set
      * Two concurrent methods are TSVs iff. at least one in write set
    * Its parallel delay injection can muddy the waters
      * [[N: causing more strange TSVs...]]
    * Two TSV stack-trace pairs may correspond to the same bug
    * Implemented only for in-memory data structures and .NET applications (e.g., C# and F#)

  

  ## A Fast File System for UNIX

* Problem with “Traditional” File System

  * Poor data throughput: 2% of max disk bandwidth. Why?
    * Long seek from file’s inode to its data
    * Inodes for the files in a directory are scattered
    * Data blocks (unit of transfer) is too small (512 bytes)
    * Consecutive data blocks in a file are scattered across cylinders
  * “Old” File System (after first round of BSD improvements)
    * Doubled block size to 1024 bytes
    * Improved reliability (added fsck)
    * Throughput still only 4% of max disk bandwidth

* Improvements in New File System

  * Increased block size to 4096 bytes. Why 4096?
    * Files up to 2^32 bytes only need 2 levels of indirection
  * Divides each disk partition into “cylinder groups” (consecutive cylinders on a disk). Why?
    * Low seek times between nearby cylinders
  * • Bit map of available blocks in cylinder group (replaces free list)
  * Cylinder group bookkeeping info at varying offsets. Why?
    * Reliability: Not all on first platter

* File System Parameterization

  * Processor characteristics
    * Does I/O Channel require processor intervention
    * Expected time to service interrupt & schedule new disk transfer
  * Characteristics of each disk
    * Number of blocks/track
    * Rotational rate (RPMs)
  * Any HW support for mass storage transfers

* Layout Policies

  * Global Policies
    * Placement of new directories, new files, large files
    * Goals: 
      * (i) Localize concurrently accessed data
      * (ii) Spread out unrelated data
    * For each directory, place all its file inodes in same cylinder group 
    * For new directory, place in lightly-loaded cylinder group
    * Redirect block allocation to a different cylinder group when file > 48 KB, and every MB thereafter
  * Local Policy priority
    1. requested block, 
    2. rotationally-closest, 
    3. cylinder in same group, 
    4. quadratic hash to new group, 
    5. exhaustive search

* Functional Enhancements

  * Long File Names 
  * File Locking
  * Symbolic Links
  * Rename
  * Quotas
  * File Locking

* 10%+ free is 2X BW over when file system is full

* 40% of time spent copying from OS disk buffers to User buffers

* Inability to coalesce multiple requests into one long request limits throughput to 50% of disk BW

  

  

## Scale and Performance in a Distributed File System

* AFS v1

  * “Andrew: A Distributed Personal Computing Environment” [CACM 1986]
  * Cache whole file locally: client process (Venus) contacts server (Vice) only on file open/close
    * Workload locality makes caching attractive
    * Servers only contacted on opens/closes
    * Most files read in their entirety
      * Can use efficient bulk data transfer protocols
    * Disk caches retain contents across (frequent) reboots
    * Simplifies cache management
    * Drawbacks
      * Workstations must have disks
      * Files larger than local disk cannot be accessed at all
      * Can’t support 4.2BSD read/write semantics
      * Difficult or impossible to support a distributed DB
  * Each directory had a single server site for updates
  * File location: Navigate server directory with stub directories pointing to other servers

* Qualitative Observations on v.1

  * Commands were noticeably slower than w/local files
  * Performance anomaly
    * Apps used the “stat” primitive to test for presence of files or to obtain status info before opening them – many client-server interactions
  * Difficult to operate & maintain
    * Use of dedicated process per client on each server: excessive context switches, page faults, resource exhaustion
    * Kernel RPC support: network-related resource exhaustion
    * Stub directories: difficult to migrate directories between servers
  * Significant performance gains possible if:
    * Reduce the frequency of cache validity checks (TestAuth)
    * Reduce the number of server processes
    * Require clients rather than servers to do pathname traversals
    * Balance server usage by reassigning users

* AFS v.2: Cache Management Changes

  * Cache contents of directories & symbolic links, not just files
  * On open, assume cached entries are valid
    * Server does Callback to client cache before allowing others to update the file
    * Reduces load on servers
    * Enables pathnames resolved locally
    * Client caches & Servers must maintain callback state
    * Such state may become inconsistent
  * Changes to Name Resolution & Low-Level Storage Representation
    * Each Vice file or directory identified by Fid
      * (32-bit volume #, 32-bit vnode #, 32-bit uniquifier)
      * Vnode info includes the file’s BSD inode
    * Volume Location Directory replicated on each server
    * Can migrate files between servers w/o invalidating locally cached directory contents
  * Communication & Server Process Structure
    * Single server process to service all its clients
      * ~5 Lightweight processes (LWPs) within a process
      * LWP bound to a client only for duration of a single server op
      * [[N: worker mode]]
    * RPC code no longer in kernel
      * Later argue that other AFS code SHOULD be in kernel
  * File Consistency
    * Writes to an open file by a client process are visible to all other local processes immediately but invisible non-locally
    * Writes become visible on file close
      * Changes visible to any new open, invisible to already open
    * All other file ops are visible everywhere on op completion
    * No implicit locking: apps have to do own synchronization

* Volume

  * Collection of files forming a partial subtree of the name space
  * Glued together at Mount Points (invisible to name space)
  * Resides within a single disk partition on a server
  * On-the-fly (atomic) migration:
    * Create a Clone (copy-on-write snapshot)
    * Construct machine-independent rep of Clone
    * Regenerate at remote site
    * Any updates during migration patched using incremental clone
  * User assigned a volume; each volume has a quota
  * Read-only volume replicas improve availability & efficiency
    * Enable orderly release of SW updates
  * Provide a level of operational transparency not supported by other file systems
    * From an operation standpoint, system is a flat space of named volumes
  * Quite valuable: Volume quotas & Ease of migration
  * Backup mechanism is simple, efficient, non-disruptive
    * Read-only clone transferred in background to staging machine
    * 24 hours of backup in read-only subtree in user’s home dir

* NFS

  * Once file open, remote site treated like local disk

    * Return to server for each new page accessed (does prefetch)
    * Caches file pages locally in memory

  * No transparent file location facility; mounted individually

  * Client & server components are in kernel

  * Caches inodes locally in memory

    * Performs validity check on file open
    * Suppressed for directory inodes if checked in last 30 seconds

  * File consistency is messier

  * > “Low latency is an obvious advantage of remote-open FS”

* AFS vs. NFS

  * ![image-20200922044023649](D:\OneDrive\Pictures\Typora\image-20200922044023649.png)
  * Scales much better than NFS
  * Small-scale performance is nearly on par
  * NFS in kernel, AFS was not (potential perf. improvement)
  * Supports well-defined consistency semantics, security, operability

* Room for AFS Improvement

  * Querying/updating authentication & network DBs
  * Better fault tolerance
  * Put in kernel & use a standard kernel intercept mechanism
  * Allow users to define their own protection groups
  * Provide replication for writable files
  * Monitoring, fault isolation, diagnostics tools
  * Decentralized administration & physical dispersal of servers

* Leases: An Efficient Fault-Tolerant Mechanism for Distributed File Cache Consistency

  * Time-based mechanism that provides efficient consistent access to cached data in distributed systems
    * Only leaseholder can write to the data until the lease expires
    * Leaseholder can approve request from server to give up lease
  * Non-Byzantine failures affect performance, not correctness
    * If can’t communicate, wait for its leases to expire
    * On recovery, server honors leases granted before crash
  * Assumes write-through caches (but can extend to write-back)
  * Leases of short duration (10s) provide good performance
  * Longer term if accessed repeatedly with little write-sharing

* Leases & AFS

  * AFS v.1 akin to lease term=0
  * AFS v.2 akin to lease term=infinity
    * Relies on server to notify client when cached data changes
    * If server can’t reach client, updates still proceed
    * Client doesn’t learn of inconsistency until contacts server
    * Polling every 10 minutes limits window of inconsistency

* ![image-20200922044318691](D:\OneDrive\Pictures\Typora\image-20200922044318691.png)



## The Design and Implementation of a Log-Structured File System

* > The paper introduces log-structured file storage, where data is written sequentially to a log and continuously de-fragmented. The underlying ideas have influenced many modern file and storage systems like NetApp’s WAFL file systems, Facebook’s picture store, aspects of Google’s BigTable, and the Flash translation layers found in SSDs.

* Problems with Existing File Systems

  * Spread info around the disk, causing many small accesses
    * Berkeley UNIX FFS: 5 seeks + I/O to create a new file
  * Write synchronously (esp. directories & inodes)

* LFS

  * Log is the only structure on disk
    * Avoids large overheads of disk seeks, important for short files
    * Contains indexing info for efficient reading
  * Need large extents of free space available for writing new data
    * Solution: Segments with a Segment Cleaner process

* File Location

  * inode map: maintains current location in log of each inode
    * Include file version number
    * Keep active portions of inode map in memory
    * ![image-20200922211639033](D:\OneDrive\Pictures\Typora\image-20200922211639033.png)

* Free Space Management: Segments

  * Threading free extents would cause severe fragmentation
  * Copying is costly for long-lived files
    * ![image-20200922212128365](D:\OneDrive\Pictures\Typora\image-20200922212128365.png)
  * Segments
    * Any given segment is written sequentially from beginning to end
    * Log is threaded on a segment-by-segment basis
    * Sprite LFS uses segments of size=512KB or 1 MB
    * Cleaning
      * Read some segments into memory
      * Copy live data to a smaller number of clean segments
      * Reclaim original segments
    * Segment summary block: identifies each piece of info
      * File number & block number for File data blocks
      * Uid = version number & inode number
    * Determine liveness by checking if file’s inode or indirect block still refers to this block; otherwise block is dead
      * No free-block list/bitmap, simplifying crash recovery

* Analyzing Write Cost

  * ![image-20200922212512171](D:\OneDrive\Pictures\Typora\image-20200922212512171.png)
  * LFS performance “can be improved by reducing the overall utilization of the disk space”
  *  Locality & “better” grouping is worse! Why?
    * ![image-20200922212555271](D:\OneDrive\Pictures\Typora\image-20200922212555271.png)
    * Problem: Cold segments tie up many free blocks for long time
    * Solution: Factor in amount of time space likely to stay free

* Data Structures Stored on Disk

  * ![image-20200922212623851](D:\OneDrive\Pictures\Typora\image-20200922212623851.png)

* Crash Recovery

  * Checkpoints (every 30 secs – “probably much too short”)
    * Write all modified info to the log
    * Write a checkpoint region to fixed position on disk: addrs of all blocks in inode map & segment usage table, ptr to last segment written, current time
  * Roll-Forward from log
    * New inode: update inode map
    * New data blocks w/o new inode: ignore
    * Adjust stats in segment usage table
    * LFS writes directory changes to log before corresponding directory block/inode (no directory changes during checkpoints)

* LFS can use disks an order of magnitude more efficiently

  * Can use 70% of the disk bandwidth vs. 5-10% for Unix FFS

* How LFS Differs

  * From Garbage Collectors
    * Sequential accesses necessary for high FS performance
    * Blocks belong to one file at a time: easier to identify garbage
  * From Databases
    * Log is final repository for data, so must write entire blocks not deltas (compaction would hurt read performance)
    * Need cleaning to reclaim log space vs. delete on apply
    * Simpler crash recovery since don’t need redo



## A Case for Redundant Arrays of Inexpensive Disks (RAID)

