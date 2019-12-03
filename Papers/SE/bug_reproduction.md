# Bug Reproduction

标签（空格分隔）： CLAP H3

---

## Towards Production-Run Heisenbugs Reproduction on Commercial Hardware

### Overview
* Heisenbugs: concurrency bugs which is notoriously difficult to reproduce
* RnR: record & replay system
* CLAP
* + recording only thread-local information (thread-local control flow)
* + use offline constraint solving to reconstruct the shared memory dependencies
* + runtime overhead 3x
* + complex and large constraints
* H3
* + hardware-supported control-flow tracing (Intel PT)
* + - compacted packet (1-bit for each conditional branch)
* + - memory accesses executed on each core are ordered internally
* ![image_1ccmu53auqcvf5us911cn3l8n29.png-35.5kB][1]
* COTS: commerical off-the-shelf <-> thread context switch log + PT trace <-> developer <-> binary + H3
* TSO: This memory consistency model relaxed the write-read constraint. The write does not need to be finished before read to a given location takes place. More intuitively, this model allows the read operation to take place before the write finishes and thus allowing read operations to bypass pending write operations took place before them. However, the Bold(write operations) need to be completely in order as in the sequential consistency model. Imagine the memory has a buffer for all the pending write operations and these write exit the buffer in a FIFO order.
* PSO: Partial Store Ordering (PSO) is a more relaxed memory consistency model compare to the Total Store Ordering (TSO). PSO is essentially TSO with one additional relaxation to the consistency: PSO only guarantees writes to the same location is in order whereas writes to different memory location may not be in order at all. The processor may rearrange writes so that a sequence of write to memory system may not be in their original order.

### CLAP
* memory order
* + SC / TSO / PSO (partial store order)
* collecting per-thread control flow information via software path-recording
* + extended Ball-Larus path-recording algorithm
* assembling a global schedule by solving symbolic constraints constructed over the thread local paths
* + Along the local path of each thread, it collects all the critical accesses (read, write or synchronization) to shared variables.
* + It introduces a fresh symbolic value for each read  access, and collects the path constraints following the control flow for each thread via symbolic execution; it introduces an order variable for each critical  access, and generates additional constraints according to synchronization, memory-consistency model, and potential inter-thread memory dependencies.
* + It uses an SMT solver to solve the constraints, to which the solutions correspond to global schedules that can reproduce the error. In other words, the SMT solver computes what inter-thread  memory dependencies would satisfy the memory-consistency model and enable the recorded local execution path.
* ![image_1ccmvvfhrgit33sls9n5r4jf2m.png-46kB][2]
* + error PSO order: $1-2-3_{R_x}-3_{W_x}-4_{R_y}-5-7-8_{R_x}-8_{R_y}$
* + $R^i_v$: value returned by the read access to the variable v at line i
* + $O_i^{R/W_v}$: order of corresponding access at line i
* + assertion: $true \equiv (R^7_z = 1 \wedge R^8_x + 1 \neq R_y^8)$
* Limitations
* + Expoential complexity of read-write constraints
* + - expoential space
* + Slowdown of software path-recording
* + - Ball-Larus for optimized algorithm tracking control flow information for each thread
* + Difficulty of code instrumentation
* + - external library
* + - uninstrumented external code

### Hardware Control-Flow Tracing
* tracing
* + PT generates a single bit 1/0 to indicate whether a conditional branch
* + PT omits everything that can be deduced from the code (like unconditional direct jump)
* decoding
* + reconstruct the control flow
* + synchronize the packet streams with the synchronization packets generated during tracing and then iterates over the instructions from the binary image to identify what instructions have been executed.
* configuring
* + set of MSR (model-specific register) by the kernel driver
* + privilege-level filtering function on (kernel vs. user-space)
* + CR3 filtering function to trace only a single application or process
* + > Skylake, filteriing by the instruction pointer addresses

### H3
* challenge
* + absence of the thread information
* + - no thread information for PT trace
* + gap between low-level hardware traces and high-level symbolic traces
* + - decoded execution is assembly => high-level IR
* + no data values for memory accesses
* + - no record for data value, find ways to match read/write without using values

#### thread local execution generation
* + context-switching event by Linux Perf tool
* + - TID / CPUID / TIME (timestamp)
* + frequent synchonrization packets (timestamp) by PT

#### symbolic trace generation
* + instrument all basic blocks of target program and assign each a unique identifer
* + compare generated assembly code from instrumented program with the decoded instruction from the PT trace to identify which basic blocks are executed by each thread
* + ![image_1ccn42d3ds1b64evv0e801psr3j.png-27.3kB][3]

#### matching read and write
* + symbolic constraints over the per-thread symbolic traces. 
* + introduce an order variable for each read/write denoting the unknown scheduling order, and a symbolic variable for each read/address denoting the unknown read value and address. 
* + We symbolically execute the program following the recorded per-thread control flow, and constructs constraints over the order and symbolic variables to determine the inter-thread orders and values of reads/addresses.
* + $\Phi_g$: a system of SMT constraint formula
* + - $Phi_g = \Phi_{path} \wedge \Phi_{bug} \wedge P_{sync} \wedge P_{mo} \wedge P_{rw}$
* + - $\Phi_{path}$: path condition by each thread
* + - - path constraints are constructed by a conjunction of all the path conditions of each thread, with each path condition corresponds to a branch decision by that path. (collected via symbolic execution)
* + - $\Phi_{bug}$: condition for the bug manifestation
* + - - enforce the conditions for a bug to happen (segfault, assert, overflow...). constructed by an expression over symbolic values for satisfying the bug conditions
* + - $\Phi_{sync}$: interactions between inter-thread synchonrization
* + - - partial order constraints: order between different threads caused by synchonrizations (fork/join/signal/wait). begin event of thread t happens after fork event. join event happens after last event of t
* + - - locking constraints: events guarded by the same lock are mutually exclusive. For each lock, all unlock/lock pairs of events are extracted, and the following constraints for each two pairs $(l_1, u_1)$ and $(l_2, u21)$ are constructed: $O_{u1} < O_{l2} \vee O_{u2} < O_{l1}$
* + - $\Phi_{mo}$: memory model constraints
* + - - enforce orders specified by the underlying memory models. (SC/TSO/PSO)
* + - - - SC: all events by a single thread should happen in the program order
* + - - - TSO: read to complete before an eariler write to a different memory location. total order over writes and operations accessing same memory location
* + - - - PSO: similar to TSO, excerpt it allows reordering writes on different memory locations
* + - $\Phi_{rw}$: potenial inter-thread dependencies
* + - - encoding constraints to enforce the read to return the value written by the write. If read $r$ on $v$ is matched to a write $w$. The order variable of all the other writes that $r$ can be matched are either less than $O_w$ or greater than $O_r$
* + - - cubic in trace size
* + - Variable: $V$ (symbolic value), $O$ (order variable)

#### Core-based constraints reduction
* ![image_1ccn7ahrm91n1jprvdtd57r2q40.png-36.3kB][4]
* executed memory accesses on each core decoded from PT trace are already ordered, following the program order. Once the order of a certain write in the global schedule is determined, all the writes that happen before or after this write, on the same core, should occur before or after this write in the schedule correspondingly. This eliminates a large number of otherwise necessary read-write constraints for capturing the potential inter-thread memory dependencies.
* ![image_1ccn9k9u91uaj8fco00iak1mne4d.png-26.5kB][5]
* ![image_1ccn9qb561r1k4ai7hok6j1er84q.png-12.5kB][6]
* ![image_1ccn9rj7jal8h2bb34ve28ci5n.png-24kB][7]

### Implementation
* Linux Perf
* + control Intel PT to collect the packet streams and the context switch events
* + insert context switch events to the packet stream by comparing the timestamps information and then use the PT decoding library to decode the packets information
* PT decoding library (01org/processor-trace)
* Z3 SMT Solver
* + solve the constraints
* CLAP
* KLEE
* + **Unsolved**: what's this for?
* Shared Variable Indentification
* + Locksmith race detector
* + manually mark each shared variable x as symbolic by klee_make_symbolic(&x, sizeof(x), "x")
* + external function => mark input and return as symbolic
* Constraint Reduction
* + for the core-based constraint reduction, first extract the writes on the same core from the PT trace and store these writes in a map (coreId: w_i[line], ...). This map is used to determine which write blongs to which core by comparing the associated line number information.
* + all writes on the same core occur in the order that they are executed => happens-before constraint over these writes
* + first constrain r to happen after w and happen before the write that occurs right after w on the same core, then only need to disjunct the order constraints between w and those writes from a different core

### Limitation
* Large PT Trace Data
* Data Values
* Constraint Solving for Long Traces
* Non-deterministic Program Inputs


  [1]: http://static.zybuluo.com/Airtnp/gbtwzoz00hpk6eqg6n4m2phj/image_1ccmu53auqcvf5us911cn3l8n29.png
  [2]: http://static.zybuluo.com/Airtnp/y2z3k2obdvhakcl3u2dqrfwy/image_1ccmvvfhrgit33sls9n5r4jf2m.png
  [3]: http://static.zybuluo.com/Airtnp/ntm80ozbdh5wzjkg9t45l8h0/image_1ccn42d3ds1b64evv0e801psr3j.png
  [4]: http://static.zybuluo.com/Airtnp/5uplp6pcnrwa79nb7oa9qwvs/image_1ccn7ahrm91n1jprvdtd57r2q40.png
  [5]: http://static.zybuluo.com/Airtnp/ue5qxnrcrzem4o7svrxvfuaf/image_1ccn9k9u91uaj8fco00iak1mne4d.png
  [6]: http://static.zybuluo.com/Airtnp/7pgo8upedh5qlag6wrk3ela3/image_1ccn9qb561r1k4ai7hok6j1er84q.png
  [7]: http://static.zybuluo.com/Airtnp/aw8mpvxgr9t2z975oe3xctwg/image_1ccn9rj7jal8h2bb34ve28ci5n.png