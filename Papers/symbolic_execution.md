# Symbolic Execution

## KLEE: Unassisted and Automatic Generation of High-Coverage Tests for Complex Systems Programs
* LLVM assembly (LLVM bitcode)
* state: representation of a symbolic process
* conditional branches => boolean expression => constraint solver
* + update IP
* + clone if both provably by constraint solver
* + error => negation => generate testcases + terminate this state
* + load/store => boundary check => flat array
* + - every memory object => distinct STP array (flat address space)
* hit every line of executable code in the program
* detect at each dangerous operation (dereference/assertion)

### Optimization
* memory management
* + pointer aliasing
* + - When a dereferenced pointer p  can refer to N objects, KLEE clones the current state N times. In each state it constrains p to be within bounds of its respective object and then performs the appropriate read or write operation.
* + - copy-on-write at object level
* + heap as immutable map, portions of the heap structure itself can also be shared amongst multiple states. heap structure can be cloned in constant time
* + contrast to EXE (native OS process per state)
* query optimization (optimizing NP-hard)
* + expression rewriting
* + - as in compilers, arithmetic simplification
* + constraint set simplification
* + - rewriting previous constraints when new equality constraints are added to the constraint set. In this example, substituting the value for x into the first constraint simplifies it to true, which KLEE eliminates.
* + implied value concretization
* + - constraint: (x + 1 == 10) => concrete x = 9
* + counter-example cache
* + -  The counter-example cache maps sets of constraints to counter-examples (i.e., variable assignments), along with a special sentinel used when a set of constraints has no solution.   This mapping is stored in a custom data structure — derived from the UBTree structure of Hoffmann and Hoehler [28] — which allows efficient searching for cache entries for both subsets and supersets of a constraint set.
* + - ![image_1cacn3ie11f5s2fa1e7717vs1m959.png-50kB][1]
* state scheduling
* + Random Path Selection maintains a binary tree recording the program path followed for all active states.
* + Coverage-Optimized Search tries to select states likely to cover new code in the immediate future. It uses heuristics to compute a weight for each state and then randomly selects a state according to these weights.  
* + round robin

### Environment modelling
* Mechanically, we handle the environment by redirecting calls that access it to models that understand the semantics of the desired action well enough to generate the required constraints.
* Filesystem
* + read => fd refers to a concrete file => pread
* System call
* + optionally simulate environmental failures by failing system calls in a controlled manner
* Rerun testcases
* + KLEE-generated test cases are rerun on the unmodified native binaries by supplying them to a replay driver we provide.

## Failure Sketching: A Technique for Automated  Root Cause Diagnosis of In-Production Failures


### Overview
* failure sketching, an automated debugging technique that   provides developers with an explanation (“failure sketch”)
* record/replay: high overhead
![image_1cacq97ei13pa7eok511cr310p6m.png-33.1kB][2]
1. Gist takes as input a program (source code and binary) and a failure report (e.g., stack trace, the statement where the failure manifests itself, etc). Gist, being a developer tool has access to the source code. 
2. Using these inputs, Gist computes a backward slice  [72] by computing the set of program statements that potentially affect the statement where the failure occurs. Gist uses an interprocedural, path-insensitive and flow-sensitive backward slicing algorithm. Then, Gist instructs its runtime, running in a data center or at user endpoints, to instrument the programs and gather more traces (e.g., branches taken and values computed at runtime).
3. Gist then uses these traces to refine the slice: refinement removes from the slice the statements that don’t get executed during the executions that Gist monitors, and it adds to the slice statements that were not identified as being part of the slice initially. Refinement also determines the inter-thread execution order of statements accessing shared variables and the values that the program computes. Refinement is done using hardware watchpoints for data flow and Intel Processor Trace (Intel PT) for control flow.
4. Gist’s failure sketch engine gathers execution information from failing.
5. Then, Gist determines the differences between failing and successful runs and builds a failure sketch

### Static Slice
![image_1cacr9lmqhnkt821pj118utn6513.png-76.4kB][3]

* static slice computation
* + item: arbitrary program element
* + CFG: control flow graph
* + source: a item that is global variable/function argument/call/memory access
* + item excerpt source: compiler intrinsics/debug info/inline assembly
* + `getitems`: return all items in a given statement
* + `getRetValues`: intraprocedural analysis to compute and return set of items that can be returned from a given function call
* + `getArgValues`: computes and returns the set of argument that can be used when calling a given function
* + `getReadOperand`: return item that is read
* + `getWrittenOperand`: return item that is written
* + ICFG: interprocedural control flow graph: connect each functions's CFG with function call and return edges
* + TICFG: thread interprocedural control flow graph. ICFG with edges that represent thread creation and join statments
* + No static alias analysis => Runtime data flow tracking
* slice refinement: removes the extraneous statements from the slice and adds to the slice the statements that could not be statically identified.
* + ideal failure sketch
* + - contains only statements that have data and/or control dependencies to the statement where the failure occurs; 
* + - shows the failure predicting events that have the highest positive correlation with the occurrence of failures.
* + AsT: adaptive slice tracking
![image_1cacueahg33avfl85fji75c01g.png-18.5kB][4]
* Tracking control flow
![image_1caf5qsiiv841lba1kff3um12tm1t.png-35.3kB][5]
* + predecessor basic blocks: (of bb1) blocks from which control can flow to bb1 via branches
* + - As a result, Gist starts control flow tracking in each predecessor basic block p11...p1n (i.e., entry points). If Gist’s control flow tracking determines at runtime that any of the branches from these predecessor blocks to bb1 was taken, Gist deduces that stmt1 was executed.
* + statement d strictly dominate a statement n (d sdom n): if every path from the entry node of the control flow graph to n goes through d and d != n
* + - if d sdom n => no special handling
* + - if d not sdom n => Gist stops control flow tracking  after stmt2 and before stmt2’s immediate postdominator.
* + node p strictly postdominate a node n: if all the paths from n to the exit node of the control flow graph pass through p and n != p
* + - immediate postdominator ipdom(n): a unique node that strictly postdominates n and does not strictly postdominate any other strict postdominators of n
* Tracking in Hardware
* + Gist tracks the total order of memory accesses that it monitors to increase the accuracy of the control flow shown in the failure sketch.
* + Discover statements that access the data items in the monitored portion of the slice that were missing from that portion of the slice. (Because Gist has no alias analysis)
* + Hardware watchpoints (drx register) of address of access variable right before the access instruction 
* + - Gist only tracks accesses to shared variables, it does not place a hardware watchpoint for the variables allocated on the stack. 
* + - Gist maintains a set of active hardware watchpoints to make sure to not place a second hardware watchpoint at an address that it is already watching.
* + - More than 4 watchpoints => Gist’s collaborative approach instructs different production runs to monitor different sets of memory locations in order to monitor all the memory locations that are in the slice portion that Gist monitors
* Identify Root cause
* + cooperative bug isolation: statistical methods to correlate failure predictors to failures in programs
* + - failure predictor: a predicate that, when true, predicts that a failure will occur
* + - - sequential: branches / data values
* + - - multithreaded: single-variable atomicity violation (RWR, WWR, RWW, WRW) and data race patterns (WW, WR, RW)
* + the precision P (a predicate that, when true, predicts that a failure will occur)
* + the recall R (how many runs are predicted to fail by the predictor among those that fail?)
* + ![image_1caf72g8r1ro212oidfa14ps8b2a.png-27.6kB][6]
* + ![image_1caf77p9tvfmprh1gd21ojugen2n.png-8kB][7]
* + ![image_1caf785o14pjgoa1lg114qd14vl34.png-82.1kB][8]

### Implementation
* static analyses and instrumentation
* + LLVM framework
* + intraprocedural control flow graph(ICFG) + thread creation => TICFG
* Intel PT kernel driver
* + insert PT watchpoints
* + - ptrace system call
* + bsdiff
* + MSR (machine specific register)
* Python code for cooperative framework
* C++ simulation for Intel PT based on PIN
* Error collected => Failure predictor by Slice Analyzer => Statistical Analysis

### Limitation
* Intel PT
* + partially ordered per CPU core
* + multithreaded diagnosis needs control flow trace totally ordered across CPU cores
* + only trace control flows, no data values => hardware watchpoints
* + Intel PT may trace statement not pertain to failture => static analysis
* + overhead => combination of static analysis and adaptive slice tracking
* Privacy problem
* ptrace
* + overhead of system call => user space instruction RDTSC
* + already in use of ptrace => agument ptrace / using third party interface (like new syscall for ioctl)
* variable on stack
* + alloca

## Lazy Diagnosis of In-Production Concurrency Bugs


### Overview
* coarse interleaving hypothesis: the events leading to many concurrency bugs are coarsely interleaved. 
* + Therefore, a fine-grained and expensive recording is unnecessary for diagnosing such concurrency bugs.
* +  a coarse-grained timing information is suficient to infer thread interleavings leading to many concurrency bugs.
* Lazy Diagnosis
* + a novel hybrid dynamic-static program analysis technique that leverages the coarse interleaving hypothesis to accurately and efficiently diagnose concurrency bugs. 

### Challenge
* overhead
* + custom hardware support
* + sampling
* + heavyweight in-house analyses
* + LD: hybrid dynamic-static program analysis that combines non- intrusive and low-overhead hardware control flow tracing, coarse-grained timing information, and powerful interproce- dural static program analysis
* accuracy
* + non-commodity hardware support
* + heavyweight analyses
* + LD: hybrid ...
* latency
* + sampling in time (turning monitoring on/off at certain time intervals)
* + sampling in space (turns on monitoring for certain portion of a program)
* + LD: Intel PT/ARM ETM

### Coarse Interleaving Hypothesis
* target event/instruction: thread interleaving of shared memory accesses and synchronization operations
* diagnosis of a bug: identification of the failure's root cause
* root cause: execution order of target events across threads
* pattern
* + ![image_1cas1q6hk1dsfqp34vo10ga18e99.png-35kB][9]

### Lazy Diagnosis
* ![image_1cas3frdrljog4rf34n5u1ni013.png-60.9kB][10]
* hybrid points-to analysis
* + lazy
* + construct mapping from trace processing results 
* + ![image_1cauc0ppm126dgurbtsgv11fegm.png-11.2kB][11]
* + instruction-based 
* + scope restriction
* + flow insensitive
* + - discard the execution order of program instructions
* type-based ranking
* + input: points-to set of the operand of a failing instruction
* + - deadlock: pointer to lock object
* + - crash: invalid pointer
* + - - ![image_1caucf16f1kpjb7d172vdpet6813.png-22.9kB][12]
* + - - ![image_1cauci5q85pc7m41lko1je61igs3g.png-21.7kB][13]
* + ranks the instructions accessing the memory location based on the likelihood with which these instructions could be involved in a concurrency bug. (exact match the type highest)
* + decrease latency
* bug pattern computation
* + partial flow sensitivity: determinte the execution order
* + - execution-before relation
* + - ![image_1cauci5q85pc7m41lko1je61igs3g.png-21.7kB][14]
* + deadlock
* + order violation and atomicity violation
* + - ![image_1caucuf1e1ls9uennte1ki8qtg4d.png-25.3kB][15]
* statistical diagnosis
* + ![image_1caue8tot15lj1k0c1lksnli15s669.png-23.3kB][16]

### Implementation
* custom 3773 LOC Intel PT driver
* + expose ioctl interface for configuring the driver the save trace when executing specific instruction / fail-stop event
* + hardward breakpoints
* + kernel module
* + ring buffer of 64KB control flow trace
* + insert time packets (MTC/CYC Mini Time Counter/Cycle Count Packet) into PT trace => get ordering
* + decoder
* + - stock decoder from Intel
* hybrid points-to + type-based ranking
* + LLVM

### Comparsion
* Snorlax
* + failure trace => dynamic tracking => hybrid points-to analysis => type-based ranking => pattern => statistical
* Gist
* + failure trace => static slicing => refinement => dynamic tracking => failure trace => pattern => statistical => failure sketching

|       Aspect    | Gist                              | Snorlax | 
|---------------|-----------------------------------|---------|
|Intrusiveness  | repeated modified the source code | No modification |
|Bug recurrence Requirement | sampling in space, bad for multiple bug | always-on monitoring |
| Static analysis | static backward slice including all could-effect intructions and refine | static points-to analysis and control flow trace to determine execution order |
| Diagnosis latency | 3.7 recurrences / bug, evert time a failure recurs, Gist broaden its scope to reduce overhead | always on and tracing the entire control flow |
| Scalability | blocking synchronization to track order | coarse interleaving hypothesis and Intel PT buffer per thread |
| Generality | perform broader class | only coarse interleaving hypothesis |





  [1]: http://static.zybuluo.com/Airtnp/2ataqym7llg9qo1jta0i2x7h/image_1cacn3ie11f5s2fa1e7717vs1m959.png
  [2]: http://static.zybuluo.com/Airtnp/d635wghum8lrocs8aacd7yqh/image_1cacq97ei13pa7eok511cr310p6m.png
  [3]: http://static.zybuluo.com/Airtnp/xi8n75bvw1q2l7crss03mol9/image_1cacr9lmqhnkt821pj118utn6513.png
  [4]: http://static.zybuluo.com/Airtnp/dwp6htwef20vf66pr5xw6sad/image_1cacueahg33avfl85fji75c01g.png
  [5]: http://static.zybuluo.com/Airtnp/fldu29sd33c4wtr67c7l7wk8/image_1caf5qsiiv841lba1kff3um12tm1t.png
  [6]: http://static.zybuluo.com/Airtnp/adytrq42ofvdk0i697c6k0um/image_1caf72g8r1ro212oidfa14ps8b2a.png
  [7]: http://static.zybuluo.com/Airtnp/4770i3rr0clwzyj9rdfno1fx/image_1caf77p9tvfmprh1gd21ojugen2n.png
  [8]: http://static.zybuluo.com/Airtnp/9fdk4er12ivo5asb15sfqkg0/image_1caf785o14pjgoa1lg114qd14vl34.png
  [9]: http://static.zybuluo.com/Airtnp/98zdi2j0f2je9urlu1lemhf5/image_1cas1q6hk1dsfqp34vo10ga18e99.png
  [10]: http://static.zybuluo.com/Airtnp/v5y7akw32fbg3fi2h1szt6un/image_1cas3frdrljog4rf34n5u1ni013.png
  [11]: http://static.zybuluo.com/Airtnp/swoplzc6nbsdilddtou7poqj/image_1cauc0ppm126dgurbtsgv11fegm.png
  [12]: http://static.zybuluo.com/Airtnp/i15c7lbsrqnemxky6fggvy80/image_1caucf16f1kpjb7d172vdpet6813.png
  [13]: http://static.zybuluo.com/Airtnp/1b302sqlyp48lsjqsye1j6m8/image_1cauci5q85pc7m41lko1je61igs3g.png
  [14]: http://static.zybuluo.com/Airtnp/1b302sqlyp48lsjqsye1j6m8/image_1cauci5q85pc7m41lko1je61igs3g.png
  [15]: http://static.zybuluo.com/Airtnp/c076so8aeg8ka568759f0a6j/image_1caucuf1e1ls9uennte1ki8qtg4d.png
  [16]: http://static.zybuluo.com/Airtnp/h7oe2dai2kay8g2db21i0nk7/image_1caue8tot15lj1k0c1lksnli15s669.png