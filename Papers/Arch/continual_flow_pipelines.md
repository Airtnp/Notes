# Continual Flow Pipelines

**Srikanth T. Srinivasan, Ravi Rajwar, Haiham Akkary, Amit Gandhi, Mike Upton**

---



## Introduction

* increased integration in the form
  * multiple processor cores on a single die
  * constant die sizese
  * shrinking power envelops
  * emerging applications
* high single-thread perf. with multiple placed on the same die for high throughput while dynamically adapting for future applications?
* Continual Flow Pipelines (CFP): non-blocking processor pipeline arch.
  * achieve the perf. of large inst. window without requiring cycle-critical structures like (scheduler, register file) to be large
  * [[Q: so to avoid renaming cost on large RS size?]]
  * non-blocking $\to$ key processor structures affecting cycle time & power, die size small
  * memory latency-tolerant CFP cores allows multiple cores on a single die while outperforming current processor cores for single-thread applications
* pipeline increasingly stalls waiting for data in the event of memory miss
* high single-thread perf. with increasing memory latency $\to$ large & complex cores to sustain large number of inst. on the fly waiting for mem.?
  * large die size, can't multicore
* CFP
  * sustain large \# of in-flight inst. without requiring the cycle-critical structures to scale up
  * large instruction inwdow $\to$ large ILP, memory latency tolerance
  * non-blocking fashion
    * load miss? dependent inst. occupy cycle-critical structures (reg file, scheduler). stall processor if following inst. unable to proceed due to lack of sufficient reg. file & scheduler resources
  * ensure miss-independent inst. successfully acquire reg. file & scheduler by making resources non-blocking
    * long-latency load ops. & dep. inst. release resources early once known as miss-dependent
    * [[Q: how to do precise state? address resolution?]]
* slice instructions: load & dep.
* Slice Processing Unit (SPU): managing slice inst. while miss is pending
  * information: completed source reg. values, data dep. infor
  * storing values cooresponding to source reg. written by completed instructions
  * correct execution while slice inst. re-mapped & re-introduced
* CFP 2 key actions
  * draining out long-latency-dependent slice (with ready source values) while releasing scheduler entries & registers
  * re-acquiring resource on re-insertion into the pipeline
* Checkpoint Processing & Recovery (CPR) as the baseline
  * outperform conventional ROB-based
  * ROB-free requiring a small number of rename-map table checkpoints selectively created at low-confidence branches
  * support an inst. window of the order of 1000+ insts.
  * scalable hierarchical solution for store queues
* CFP addresses CPR in the presence of long latency operations.
* ![image-20200111152704371](D:\OneDrive\Pictures\Typora\image-20200111152704371.png)
* ![image-20200111152715768](D:\OneDrive\Pictures\Typora\image-20200111152715768.png)



## Simulation Methodology

* detailed exec-driven timing simulator for IA32 inst. set & uops ([[Q: where is this simulator? PIN? GEM5? But it's 2004!]])
  * model all system activities (DMA traffic, system interrupts) & memory system
  * ![image-20200111152953228](D:\OneDrive\Pictures\Typora\image-20200111152953228.png)
* aggressive hardware data prefetcher & perfect trace cache (no trace cache misses)
  * [[Q: what is a trace cache?]]
* ![image-20200111153208419](D:\OneDrive\Pictures\Typora\image-20200111153208419.png)
* CPR: 8 checkpoints created at low confidence branches
  * large load/store buffers: 48-entry conventional L1 store queue, 1024-entry L2 store queue (off cri. path) [[N: 2-level store queue, see 3.1]]
  * store sets predictor to issue loads ahead of unknown stores
    * completed stores lookup a load buffer to roll back execution to an eariler checkpoint for memory dependent misprediction
  * 2048 entries load buffer (set-associative, off crit. path)
    * no store & forward any data



## Quanntifying CPR Performance



### CPR Overview

* ROB-free proposal for building scalable large instruction window processors
* small \# of reg. rename map table checkpoints selectively created at low-confidence branches ([[Q: interrupt? restore to latest checkpoint & restore?]], [[N: look at the CPR paper (same guys here...)]])
* checkpoint $\to$ register reclamation scheme decoupled from the reorder buffer & precise interrupt
* inst. completion $\to$ checkpoint counters
  * entire checkpoints committed instantaneously (bulk commit, breaking serial commit semantics imposed by ROB)
* decouple: misprediction recovery / register reclamation / commit inst.
* fast & efficient forwarding of data from stores to subsequent loads? hierarchical store queue
  * L1 queue: most recent stores
  * L2 queue: holds older stores displaced from the L1 ([[Q: like post retirement buffer?]])



### Quantifying CPR performence potential

* ![image-20200111160439667](D:\OneDrive\Pictures\Typora\image-20200111160439667.png)
* base CPR: register file & scheduler of (64 int, 64 fp, 32 mem) & (192 int, 192 fp). [[Q: scheduler = FU?]]
* ideal CPR: relax register file & scheduler, both infinite entires
* for 4-wide 8-GHz processor with 100ns load-to-use latency, a single load miss requires peak target window of 3200 (4 x 8 x 100)
  * miss-dependent? increase pressure



### Understanding CPR limitations

* ![image-20200111164628188](D:\OneDrive\Pictures\Typora\image-20200111164628188.png)

* perf-: sufficient size of corresponding resource for an 8192-entry instruction entry

  * STQ/MD: store queue (unlimited entiries, single cycle access), memory dependency predictor
    * small impact shown
  * RF: register file
  * SCHED: scheduler

* real-: previous Table size

* increasing register file without scheduler $\to$ no perf. benefits

* increasing scheduler with keeping register file $\to$ still substantial worse than ideal

  

### Scheduler

* decentralized blocking scheduler: entries may fill up in the presence of long latency operations
  * P4 uses decentralized & non-blocking scheduler
    * long latency ops (L1 miss) & dependent don't occupy scheduler entries
    * Waiting Instruction Buffer (WIB)
      * ![image-20200111170021418](D:\OneDrive\Pictures\Typora\image-20200111170021418.png)
      * small & fast scheduler backed by large buffer for storing inst. dependent upon long latency ops
    * need to assume sufficiently large register files - making blocking like non-blocking
  * [[Q: central: merging different FU or merging with inst. window? blocking: miss-dependent in scheduler?]]



### Register files

* > 1. The value has been written to the physical register
  >
  > 2. All issued instructions that need the value have read it. 
  > 3. The physical register has been unmapped.

* [[N: The thing is to have phy. reg. size < ROB size + virt. reg. size]]

* conventional: reclaiming a phy reg when no longer part of arch. state

  * inst. overwrite the logical reg. (mapping to phy. reg.) commits
  * allow state restoration on branch misprediction, interrupt, exceptions
  * phy reg. lifetime increases because reclamation is limited by serial retirement semantics of the reorder buffer
    * necessitate larger reg. file

* CPR: aggressive counter-based register reclamation

  * [[N: sounds like RUU with tag + copy-based $\to$ physical reg + index-based]]
  * reclaim all phy. egs. except those corresponding to a checkpoint (phy. reg. mapped to logical reg.  at the checkpoint creation) when counter -> 0
    * [[Q: won't this require a large number of phy. regs to be smooth?]]
  * work well for short latency ops
  * long latency ops result in increased reg. file pressure
  * ![image-20200111201926446](D:\OneDrive\Pictures\Typora\image-20200111201926446.png)
  * ![image-20200111201938061](D:\OneDrive\Pictures\Typora\image-20200111201938061.png)
  * ![image-20200111201946229](D:\OneDrive\Pictures\Typora\image-20200111201946229.png)

* hierarchical solution to large phy. reg. file (because of large inst. window)

  * reduce cycle time degradation
  * adding small fast level backed by a slower & larger second level



## Continual Flow Pipelines

* make scheduler & register file size independent of the target instruction window!
* [[N: scheduler: RS. inst window: ROB/uop queue.]]
* ![image-20200112001121601](D:\OneDrive\Pictures\Typora\image-20200112001121601.png)
* [[Q: CPR is ROB-free, therefore, the uOP queues serves as a temporary store for bulk checkpoint committment?]]



### De-linking instruction window from cycle-critical structures

* key problem: inefficiency in management of cycle-critical register file & scheduler in presence of long latency ops
* decouple RF & SCHED from inst. window
  * non-blocking RF & SCHED
  * inst. don't tie down entires in these structures in the event of a long latency miss



#### Continual flow scheduler

* FIFO buffer to store temporarily the slices corresponding to long latency ops in the inst. window
  * similar to WIB, but WIB buffer is the size of the target inst. window (i.e. ROB size if ROB-style processor)
  * only buffer actual slice
* slice inst. treat source reg. (dependent on long latency ops) as ready (not real)
  * drain out of the scheduler & into another buffer without changing scheduler design
  * [[Q: so trivial dependent spurce registers (like add, ..) are as not ready?]]
* [[Q: how to know a op is long latency? so L2 cache misses will occupy a bus to RS/scheduler]]



#### Continual flow register file

* 2 classes of registers
  * Completed source registers: registers mapped to completed instructions
    * read by inst. in a slice of a long latency ops
    * conventional reg. reclamation: cannot free until read by dependent slice inst.
    * inst. in slice cannot have both src op correspond to completed source regs.
  * Dependent destination registers: registers assigned to dest. op of slice inst.
    * not be written at least until long latency ops completes
    * convential reg. reclamation: ties regs. down unnecessarily for many cycles
* reclaiming these 2 register classes
  * when an inst. within the slice of a long-latency inst. leaves scheduler, drains through the pipeline
  * read any of its completed source reg., record value as part of the slice, mark register as read
    * since inst. has completed value available, the reg. storage can be reclaimed once all readers have dispatched
    * [[Q: so potentially haven't issued inst. need to read value from slice buffer?]]
    * [[Q: or logical registers have a separate storage for architectural values, therefore directly read is possible]]
  * record its phyiscal reg. map as part of the slice $\to$ true data dep. order among slice insts.
  * slice in the buffer is a self-contained subset of the program, execute independently since appropriate ready source values & data order are available
* ready source value, any dest. phys. reg. re-acquired when re-execution
* regs. can now be reclaimed at such a rate that whenever an inst. requires a physical register, such a register is always shortly available
* checkpoint recovery requirement: 2 types of reg. cannot be released until checkpoint is no longer required
  * registers belonging to the checkpoint's architectural state
  * register corresponding to the architectural live-outs
    * [[Q: what is live-outs? Does it mean the phys. regs binding to logical regs (in arch reg. table) with the on the fly execution?]]
  * $\propto$ logical registers
  * doesn't depend upon implementation details (outstanding misses, target inst. window size, etc)
* other reclaimable phy. registers when
  * all subsequent inst. reading the reg. have read them
    * by CFP: slice inst. mark completed source register ops as read
  * the phy. reg. have been subsequently re-mapped (i.e. overwritten)
    * by basic renaming principle



#### Re-introducing the slice back into the pipeline

* re-inserting long latency dep. inst. into the pipeline, event after their scheduler entires and registers have been previously reclaimed
* dest reg. need to be remapped to new phy. regs.
* Re-acquiring registers with back-end renaming and without deadlocks
  * front-end renaming: logical regs. maps to phys. regs.
  * back-end: phys. regs. maps to another phys. reg
  * when long latency ops completes, new front-end inst. wait until the slice inst. drain into the pipeline
    * allow re-entering slices to acquire scheduler entires
    * guaranteeing forward progress & avoiding deadlock
  * new free registers guaranteed by
    * exploiting the earilier mentioned basic register renaming principle: where registers in the slice are reclaimed when they are overwritten & an overwriting instruction is guaranteed to appear within a fixed number of rename operations
      * [[Q: that is normal method?]]
    * sizing the register file a priori to guarantee the slice remapper eventually finds a free physical register even when some phys. regs cannot be reclaimed because checkpoints & live-outs
      * $P_{FE}$ as the \# of phys. regs. available in the front-end
      * slice remapper observe potentially $P_{FE}$ unique physical registers while performing the phys 2 phys remapping
      * 1 uncommitted checkpoint is guaranteed to exist prior to the oldest load miss in the SDB
        * total `L` register cannot be released until checkpoint retires
      * so only $P_{FE} - L$ unique phys. registers names in the SDB can be seen by the slice remapper
      * If slice remappers has $P_{FE} - L + 1$ physical registers available for remapping? deadlock is avoided
      * For $C$ checkpoints, live-outs occupy an additional $L$ physical registers unavailable to the slice remappers.
        * Thus, to avoid deadlocks, the slice remapper needs $P_{FE} - L + 1$ physical registers, but may have only $P_{FE} - (C+1)L$ physicals registers available
        * additional $CL+1$ registers reserved only for slice remapper
          * this dependent on \# of checkpoints & architectural registers, not on any other impl. details (like miss latency & inst. window size)
* Synchronizing dependencies between slice & new instructions
  * new inst. fetched after slice reinsertion may have dependencies on slice inst.
  * slice dest. register that are still live (corresponding to the live-outs) at the time of slice reinsertion, must not be remapped by the slice remapper
  * rename filter is used for this
* ![image-20200112000519574](D:\OneDrive\Pictures\Typora\image-20200112000519574.png)



### CFP Implementation

* Slice Processing Unit (SPU): buffering the slice while long-latency miss is outstanding, processing the slice prior to re-introducting into the pipeline
* ![image-20200112001118931](D:\OneDrive\Pictures\Typora\image-20200112001118931.png)



#### Releasing scheduler entries & physical registers associated with slice instruction

* Not a Value bit (NAV bit)
  * init to 0
  * associated with each phy. register & store queue entry
  * On L2 cache load miss $\to$ NAV bit of the load's dest reg is set to 1
    * subsequent inst. reading this inherit for their dest. reg. (and store queue entry)
    * dest. regss of loads predicted to depend upon an eariler NAV store by the memory dep. predictors also have their NAV bits set
* slice inst.: if it reads a source op register / store queue entry with a NAV bit set
* draining process
  * when both source ready / NAV bit set
  * mark source reg. as having been read
    * CPR/CFP: decrementing the use counter for the register
    * don't decrement the checkpoint instruction counter (use to track inst. completion in CPR) since not completed
      * but non-slice will execute & decrement
  * slice inst. $\to$ SPU



#### The Slice Processing Unit

* It holds slice instructions, physical maps, and source data values for the slice in the Slice Data Buffer (SDB)
* It remaps slice instructions prior to re-introduction into the pipeline using the Slice Rename Filter and Slice Remapper
* Slice Data Buffer
  * two actions on slice inst. determine the ordering info. required in SDB
    * Back-end renaming when registers of slice inst. are released & re-acquired
      * logical names for renaming? original program order is required
      * physical names for renaming? data dependence order among inst. is sufficient
    * Branch misprediction recovery
      * branch mispredicts? slice inst. after that branch must be identified & squashed
      * ROB-style? maintain program order
      * CPR-style map table checkpoints? identify & squash using checkpoint identifiers of slice inst.
  * no need for program order, therefore SDB size is signficantly smaller than inst. window size
  * entry in FIFO SDB
    * instruction opcode
    * 1 source reg. data field to record values from a compelte resource register
    * 2 source reg. mappings
    * 1 dest. reg. mapping
    * control bits
      * re-insertion & squashing
    * ![image-20200112003146108](D:\OneDrive\Pictures\Typora\image-20200112003146108.png)
    * approximately 16 bytes
  * sufficient bandwidth to allowing writing & reading blocks of inst.
    * issue-width
  * SDB entries allocates as slice inst. leave the scheduler
  * block of slice inst. enter SDB in scheduler order, leave it in the same order
  * can be implemented
    * using a high density SRAM
    * area-efficient design: long-latency, high-bandwidth cache-like array structure with latency & bandwidth similar to an L2 cache
  * reading/writing of SDB not on critical path
    * model as 25 cycle latency
    * insertion + removal + processing through remapper & filter
* Slice Remapper
  * physical register in the slice to new physical registers
  * access to front-end mapper namespace & small number of reserved registers (CL + 1)
  * many entires as \# of phys. reg.
  * records only map information
* Slice Rename Filter
  * registers corresponding to live-outs must retain the original physical map
    * SRF is used to avoid remapping these registers
  * entry for each logical register: record identifier of the inst. that last wrote the logical register
  * renaming in front-end? rename filter updated with inst. identifier
    * if this inst. enter SDB? on its subsequent re-insertion into the pipeline, rename filter lookup using logical dest. reg of the inst.
    * if matched, register considered still live (no later remapping happens)
      * these registers don't pass through the slice remapper
    * if no match, must remap
      * acquire new reg. using slice remapper
  * physical reg. corresponding to checkpoitns handled similarly
  * entries: \# of logical registers $\times$ \# of checkpoints (+1?)
  * [[Q: how to avoid reclamation? dest reg. is not recycled?]]
* SDB & multiple independent loads
  * multiple slices in the event of multiple indep. load misses
    * [[Q: how to identify? the NAV bit propagates but load miss don't?]]
  * only live-ins: values of loads that missed
  * load misses may complete out of order $\to$ slice ready out of order
    * wait until oldest slice is ready, drain SDB in FIFO order
    * drain SDB in FIFO order when any miss in SDB returns
    * drain SDB sequentially from the miss serviced
      * reg. mapping from an eariler waiting slice that src inst. in a later ready-to-execute slice are detected using the slice remapper [[Q: how? the previous slice dependency, how to solve?]]
      * use SDB index stored in the outstanding miss cache fill buffer
  * [[Q: one possible way is to solve dependency op. by op. and store ready in slice remapper?]]
* SDB & chains of dependent loads
  * subsequent load in slice could miss again
  * inst. dependent on this slice may be part of the eariler load miss
  * re-enter SDB, preventing a stall of chained load miss
    * must occupy original position in SDB with their original physical map to maintain data dependence order of the original program
      * [[Q: how to get data dep. order? By scheduler setting ready bit and propagate, so it's data dep. order, not logical order?]]
    * release of SDB entry if the slice instruction associated with it successfully executes & completes
    * discard new mapping in the slice remapper, retain original mapping
    * read new produced source register values & store
    * head inst. always completes successfully to guaranteeing forward progress
  * re-insertion may result 0 entries for inst. that completed
    * may reduce bandwidth because individual entires are written
    * add write-combining queue in front of the SDB to match the single port SDB design with the pipeline
    * since needed again after 100+ cycles, any additional latency of the writing combining queue has no impact on performance



### CFP & base processor interactions

* 2 core CFP principle
  * draining out the long-latency-dependent slice (along with ready source values) while releasing scheduler entries & registersf
  * re-acquiring these resources on re-insertion into the pipeline
* applicable to conventional processors like ROB-based OoO or in-order processors
* CPR: checkpoints for coarse-grained scalable recovery & re-generate arch. state
  * supporting for recovering to a point prior to the load miss for CFP already exists
* ROB: roll-back required in the form of a minimum single checkpoint to support CFP



## CFP, Runahead & WIB

* inability to hide long memory latency $\leftrightarrow$ linear scaling of resources $\leftrightarrow$ large inst. window, high clock freq., low design complexity
* Runahead: checkpoint at long latency ops + speculative execution
  * with prefetching effects
  * have to discard work
  * CFP subsumes runahead execution
  * ![image-20200112121028754](D:\OneDrive\Pictures\Typora\image-20200112121028754.png)
* WIB vs. CFP
  * WIB requires large reg. file vs. CFP integrates a mechanism
  * non-blocking scheduler vs. reg file small + non-blocking scheduler
  * reg file are active, power-hungry cycle-critical
  * WEB needs to allocate entire window in its buffer (program order of the slice) vs. CFP using checkpoint



## Implications of CFP

* Branch prediction remaining key limiter
  * ![image-20200112121246218](D:\OneDrive\Pictures\Typora\image-20200112121246218.png)
  * branch dependent on long latency loads cannot be resolved until the load data returns
* Increased cache efficiency & small dies
  * ![image-20200112121338826](D:\OneDrive\Pictures\Typora\image-20200112121338826.png)
  * CFP allows high perf. even with a small cache
  * make more small cores on die
* Simplified structure sizing
  * cycle-critical structures need to be designed only for a small active set of instructions with CFP
    * L2, scheduler, register file



## Conclusion

* ![image-20200112121536734](D:\OneDrive\Pictures\Typora\image-20200112121536734.png)













* CS251A requirements
  * a short paragraph summarizing the problem and goal/contributions of paper
  * a short paragraph summarizing the paper’s methods and results
  * a short paragraph giving your opinion of what is good and bad about the paper.

## Summary

- Conventional approaches to sustain a large, adaptive instruction window (caused by long latency instructions, like load L2 miss) rely on large scheduler entries and numerous register files, which happen to cycle-critical components and increase die sizes and power consumption. Therefore, the single-threaded performance increases, but the total throughput decreases because fewer cores can be placed on the die. This paper introduces Continual Flow Pipelines (CFP) as a new non-blocking processor pipeline architecture. Based on Checkpoint Processing and Recovery (CPR) design, CFP adds the Slice Processing Unit (SPU) to decouple the demands of the instruction window from the register file and scheduler resources. As a result, CFP can achieve high performance when large instruction windows and long latency instructions are in presence while maintaining scalability.

## Methods & Results

- CPR is a scalable ROB-free pipeline design, which decouples the uop buffer from precise state recovery, register reclamation, and instruction commit. CFP employs a low-confidence checkpoint mechanism (register rename map table), reference count based register files and bulk commits. The authors quantified the CPR performance and found that there was a performance gap between the normal CPR with ideal CPR where having infinite scheduler and register file entries. Though CPR addresses the scalability and performance limitations by conventional ROB designs and works well for short-latency operations, the long latency operations can fill up the scheduler and result in increased register file pressure since they physical registers cannot be freed at least until the blocked instruction completes and dependent instructions make things worse. CFP solves this issue by draining long-latency-dependent instructions (called slice) out of the normal pipeline and releasing scheduler entries and registers and re-acquiring resources on re-insertion into the pipeline. To identify the slices, a Not a Value (NAV) bit is added to each physical registers and marked on L2 cache miss. The NAV bits propagate on dependent instructions and load from store queue entries. The draining process will copy the ready source register values and make slices self-contained for the following re-insertion. To make sure re-insertion of slice instructions correctly, the slice remapper takes care of the physical to physical renaming mapping of registers with some reserved physical registers (independent of instruction window size). Deadlocks are avoided by maintaining data dependency on physical registers and live-outs are filtered out by slice rename filters to retain original physical maps. The slice data buffer is FIFO and can have multiple outstanding slice instructions. The chained dependent loads are solved by reserving SDB buffer until the re-insertion instructions all complete and employing a write-combining queue for throughput. The results show that CFP outperforms normal CPR and conventional ROB-based pipelines and can tolerance around 80% independent instructions retired in the shadow of an L2 miss under very large instruction windows. The result implies that CFP pipelines can have small structures size (L2, register file, scheduler) and decrease die size for higher throughput.

## Personal Opinions

- In my opinion, it's a very solid paper since it presents a large number of details on CFP design (some need to read the previous paper on CPR). It successfully decouples the register file and scheduler sizes from the pressure on the instruction window when long-latency-operations present. However, can this design remain competitive with small instruction windows? Also, how large the instruction windows will be for normal workload programs? I think this method may not sound popular today since the frequency is locked up (due to technology node) but memory latency is highly reduced. For example, Intel Haswell has L2 cache latency as 12 cycles, far smaller than 100 cycles in the paper. Therefore, the performance gain from load-miss shadows is questionable for today's processors. Therefore, we still need to focus on small instruction window performance between CFP, CPR, and ROB-based designs.



