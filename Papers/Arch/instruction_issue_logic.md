# Instruction Issue Logic for High-Performance, Interruptible, Multiple Functional Unit, Pipelined Computers

**Gurindar S. Sohi, Sriram Vajapeyam**

---



## Introduction

* perf. of pipelined processors limited by data dependencies.
* issues of dependency-resolution with precisenesss of state
* dynamic resolving dependencies + guarantee a precise state without significant hardware overhead
* [[Q: fairness issues? like imbalanced load issue from ROB to load queue fill the whole load queue]]
* 2 major impediments to performance
  * data dependencies
  * branch inst.
* interrupt can be imprecise
* previous works
  * delayed branch instructions: limited for long pipelines
  * branch prediction: predict fetch / conditional mode executing
  * software solutions: code scheduling techniques (large set of regs) $\to$ increase dep. distance for interlock
  * wating stations / reservation stations
* software precise state solution is impossible
* ![image-20200110004643591](D:\OneDrive\Pictures\Typora\image-20200110004643591.png)
* model architecture
  * ![image-20200110004708809](D:\OneDrive\Pictures\Typora\image-20200110004708809.png)
  * CRAY-1 like (sota scalar unit)
  * all inst. (16bit/32bit) can issue in a single cycle if issue conditions are favorable
  * only 1 function can output data onto the result bus in any clock cycle
  * FU results directly to register file
  * register file: 8 A, 8 S, 64 B, 64 T registers
  * [[Q: no connection between load/store unit to memory bus?]]



## Dependency Resolution: OoO Instruction Execution

* Tomasulo's Algorithm
  * forwarded to Reservation Station (RS) associated with RS
  * waiting for data dependencies to be solved by CDB (common data bus)
  * ![image-20200110135520558](D:\OneDrive\Pictures\Typora\image-20200110135520558.png)
  * copy-based register renaming, eliminate WAR, WAW
  * need tag-matching process, which is hard if \# of regs are large
* Extensions to Tomasulo's Algorithm
  * separate tag unit (MapTable + FreeList?)
    * few of all possible sink registers may actually active
    * a  tag pool, assign tag only to currently active sink register
    * source busy? lookup TU for tag
    * dest busy? new tag obtained
    * TU forwards the CDB result to registers
      * update when data is available, no direct connection is needed
      * no physical renaming happens here
    * 1 bit associate latest tag & if the instruction has a key to unlock the register (clear the busy bit)
  * ![image-20200110153331826](D:\OneDrive\Pictures\Typora\image-20200110153331826.png)
  * ![image-20200110155131989](D:\OneDrive\Pictures\Typora\image-20200110155131989.png)
* Merging the Reservation Stations
  * combine all RS of all FU (common RS Pool)
  * single path from RS Pool to FUs
* Merging RS Pool with the Tag Unit
  * 1-1 correspondence between entires in TU & RS
  * RS Tag Unit (RSTU)
    * inst. obtains a tag from RSTU, automatically reserves a RS
  * ![image-20200110164906586](D:\OneDrive\Pictures\Typora\image-20200110164906586.png)



## Implementation of Precise Interrupts

* reorder buffer
  * aggravate data dep.
  * value of register cannot be read till it has been updated by the re-order buffer
  * even though the inst. computed a value may have completed already
  * [[Q: different from P6/R10K, which bypass from MT-ROB/MT-PhyReg]]
* associate bypass logic with ROB
  * bypass fetched value from the reorder-buffer
  * using CDB? FU -> ROB -> CDB -> RS (R10K will be FU -> Complete -> CDB -> ROB/RS)
  * expensive for search cap. & data paths for each buffer entry
  * [[Q: P6? I don't understand what kind of ROB it describes (P6, R10K uses simple monitor way)]]



## Merging Dependency Resolution & Precise Interrupts

* If RSTU as a queue, it can behave like a reorder buffer
* ![image-20200110193752521](D:\OneDrive\Pictures\Typora\image-20200110193752521.png)
* ![image-20200110200339867](D:\OneDrive\Pictures\Typora\image-20200110200339867.png)
* [[N: P6 (RS) vs. R10K (Tag-indexed)]]
* [[Q: why not separate renaming vs. ROB/PRF storage?]]
* Register Update Unit (RUU)
  * RSTU constrainedd to commit inst. in order the instructions received by the decode & issue logic
  * [[N: ROB + RS, separate is P6 style]]
  * [[Q: who did the renaming? RF keeps the busy & tag of source, RS keeps the tag of dest]]
  * ![image-20200110193403358](D:\OneDrive\Pictures\Typora\image-20200110193403358.png)
  * no direct path between decode & issue logic to FU
    * precise $\to$ no bypass, all in ROB
* Decode & Issue Unit
  * request entry in RUU? stall if fail
  * forward contents of source register / register identifier (reg num + extra control bits) to RUU
  * control bits for dest reg in the register file are updated, identifier forwarded to RUU
* RUU details
  * determine which inst. should be issued, reserve result bus, dispatches the inst. to FU
  * determine which inst. can commit, i.e., update the state of the machine
  * provide tags to & accepts new inst. from decode & issue logic
  * queue as `RUU_Head` & `RUU_Tail` pointers
  * should not involve large amount of comparison hardware
  * should not affect the clock speed to an intolerable extent
  * Source Operand Fields
    * ![image-20200110194915618](D:\OneDrive\Pictures\Typora\image-20200110194915618.png)
    * tag sub-field monitors the result bus for a matching tag $\to$ pass results
  * Destination Field
    * providing new instance for busy dest. reg., process WAW conflicts simultaneously
      * WAR solved by forwarding values
    * guarantee results return to reg. in-order (precise) $\to$ elinminate associative search, using counter to provide multiple isntances
    * 2 n-bit counters (control bits) with each register in the register file
      * no busy bit
      * Number of Instances (NI): \# of instances of a register in the RUU
      * Latest Instance (LI): number of the lastest instance
      * inst. write to register $\to$ RUU $\to$ increment NI, LI (% n)
        * block if NI = $2^n - 1$
      * inst. leave RUU, update register $\to$ decrement NI
        * free if NI = 0
        * [[Q: Is NI totally for load/store proceeding?]]
    * decode $\to$ RUU: Ri + LI counter
      * future instruction access the latest instance
        * latest copy of the reg. content
        * inst. present in RUU get the correct version of the data
  * Bypass Logic 
    * bypass value when completed instruction in RUU, but not committed yet
      * P6 by ROB -> CDB -> RS, R10K by either ROB -> CDB -> RS, or FU -> CDB -> ROB+RS
    * extend the monitoring of RS to monitor result bus (capture completion after issued to) + RUU to register bus (capture completion before issued to)
      * [[Q: why we need the second monitor here? For issue-RUU bypassing? Why don't we just look at the register file? Is there some time logic here?]]
* Interaction with Memory
  * load/store
    * Load addresses, Store data buffer, Conflict buffer?
    * keep a set of Load Registers to resolve dependencies in the memory FU
      * value: addresses of currently active memory locations
      * L1 NI for multiple instances of memory address
    * address unavailable? not allowed to proceed subsequent load/store (no forwarding)
    * proceed load
      * check if addr for load matches addr stored in load register
        * NI !=0 && match, forward a tag to RUU (not submitted to memory)
        * pending load/store
    * no match
      * free load register obtained (NI = 0)
      * NI -> 1, LI -> 0
      * load request to memory
      * tag submitted to memory so that data supplied by the memory may be read by the appropriate operands in the RUU
        * [[Q: ?? why we need tag here? for forwarding? tag only appears on bus, not real DRAM?]]
      * load returns / store committed -> NI decrement
  * need to associatively search for memory address
    * but load registers number is small
* Operations of RUU
  * each clock cycle (in parallel):
    * accept an instruction from the issue logic
    * commit an instruction (i.e. update the reg file)
    * issue an inst. to FU
      * priority given to load/store, then in order
    * monitor the bus for matching tags
      * tag matching in the source-operands fields
  * each entry in RUU
    * ![image-20200110232901651](D:\OneDrive\Pictures\Typora\image-20200110232901651.png)
  * PC is for precise interrupts



## Branch Prediction & Conditional Instructions

* RUU for nullifying instructions
  * previous interrupt
  * incorrect execution path
* conditional mode execution
  * identify with an additional field
* no hard limit



## Conclusion

* dependency resolution + implementation of precise interrupts
  * OoO without associating tag-matching hardware with each register
  * [[Q: but still tag-matching with bus tags..?]]
  * [[Q: maybe tag-matching on RUU indexes vs. register indexes (though dynamic? virt reg + ROB size = phy reg. is big?. So diffs in virt reg. size) has different cost]]









* CS251 requirements
  * a short paragraph summarizing the problem and goal/contributions of paper
  * a short paragraph summarizing the paper’s methods and results
  * a short paragraph giving your opinion of what is good and bad about the paper.

## Summary

- This paper wants to address the problem: how to resolve the false dependencies (WAW, WAR) while allowing the precise out-of-order instruction execution. Especially, the authors want to eliminate the high hardware cost with previous solutions on associating tag-matching if the architecture consists of a large number of registers. The paper purposes a solution called Register Update Unit (RUU) combing the dependency resolution and precise state preservation. RUU can achieve a significant performance improvement over a simple instruction issue mechanism, while doesn't introduce a substantial cost in hardware.

## Methods & Results

- The author did incremental modifications from the normal Tomasulo algorithm to the final RUU design. First, the author purposes a Tag Unit (TU) design to allocate tags of registers on demand. Then by observing TU tags are one-to-one correspondent to reservation station (RS) entries, the author discusses the design of combing TU and RS to be RSTU. Finally, to introduce the precise state, the RSTU must behave like a queue, then it finalized the RUU design. The registers in the register file are tagged with one reference counting fields for load/store forwarding and one latest number field for the latest tag per register. The RUU unit will accept instructions from decoding logic, commit instructions at the head (for precise state), issuing ready instructions to function units (load/store first, then in order), and monitoring result bus for matching tags in its entries and copy values. To bypass results, the monitoring should both monitor the Common Result Bus and the bus of RUU to register file. The load/store instructions are resolved as special Load Registers which contain the addresses of the memory location. The load and store proceeding and forwarding problems became the tag-matching on Load Registers with respect to reference counters. In addition, RUU can support conditional execution by adding one field to RUU entries which can be cleared as interrupts happened. Based on the Lawrence Livermore loops benchmark, RUU reached significant performance up-gradation (about 80%) compared to a simple CRAY-like instruction issue mechanism (raw Tomasolu).

## Personal Opinions

- In my opinion, this paper is good to read since it presents an incremental design on optimizing the core out-of-order component step by step. However, it seems to lack some details, like how to RUU update the register file on instruction completion. Another question is why tag-matching on register tags is expensive? I suppose the difference between tag-matching between RUU and normal register renaming is (RS size) vs. (ROB size + virtual register size). I can imagine there is some difference if the number of virtual registers is way larger than ROB or RS size, but I don't think this system is practical. The final question is the modern designs (as far as I know), like R10K and P6, separate the ROB and RS, while RUU combines them. What concerns cause this design choice?


