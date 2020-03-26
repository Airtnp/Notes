# Implementation of Precise Interrupts in Pipelined Processors

**James E. Smith, Andrew R. Pleszkun**

---



## Introduction

* precise interrupt: saved process state corresponds with the sequential model of program execution where one instruction completes before the next begins.
  * difficult for pipelined, instruction may completed before predecessors
* 5 solution
* CRAY-1S simulation
* Interrupts $\to$ state saved by hw/sw (PC, reg., memory.) $\to$ precise
  * all inst. preceding the inst. indicated by the saved PC have been executed & modified the process state correctly
  * all inst. following the inst. indictaed by the saved PC are unexecuted & have not modified the process state
  * if interrupt by an exception condition raised by an instruction in the program, the saved PC points to the interrupted instruction
    * may or may not have been executed
    * completed / has not started execution
* ![interrupt](D:\OneDrive\Pictures\Typora\20171005083159808.png)

* [Exceptions](https://wiki.osdev.org/Exceptions)
* ![image-20200121002414796](D:\OneDrive\Pictures\Typora\image-20200121002414796.png)
* ![image-20200121002420223](D:\OneDrive\Pictures\Typora\image-20200121002420223.png)
* [Register renaming](https://zh.wikipedia.org/wiki/%E5%AF%84%E5%AD%98%E5%99%A8%E9%87%8D%E5%91%BD%E5%90%8D)



### Classification of Interrupts

* Program interrupts: traps, result from exception conditions detected during fetching & execution of specific instructions
  * may due to software errors
  * illegal opcode (`ud2`), overflow, page faults
* External interrupts: outside sources
  * I/O interrupts, timer
* Precise interrupts conditions
  * I/O, timer interrupts $\to$ enable restarting
  * software debugging: isolating exact instruction & circumstances that caused the exception condition
  * recovery from arithmetic exceptions: re--scale floating point numbers, or handled by software; gradual underflow in IEEE floating point standard
  * VM: correctly restart after page fault
  * Unimplemented opcode simulation
  * VM by privileged instruction faults cause precise interrupts (popek & goldberg theorem)



### Historical Survey

* IBM 360/370: less aggressive pipeline
* Amdahl 470/580, Gould/SEL 32/87: extra stage at the end
* CDC 6600/7600, Cray: I/O precise, no VM
* CDC STAR-100/CYBER 200: with VM, vector inst.
  * invisible exchange package: capture machine-dependent suite info. resulting from partially completed instructions
* mIPS: pipeline info. dumped at interrupt, restore when resumed
  * restartable, but precise? questionable
  * need impl.-dependent softwre sift through machine-dep. state in order to provide complete debug info.
* CDC CYBER 180/990: history buffer
  * state info. saved just prior to being modified.



## Preliminaries



### Model Architecture

* reg.-reg. arch.
* load: Ri = (Rj + disp)
* store: (Rj + disp) = Ri
* functional: Ri = Rj op Rk / Ri = op Rk
* conditional: P = disp : Ri op Rj (branch target displacement)
* ![image-20200121003017967](D:\OneDrive\Pictures\Typora\image-20200121003017967.png)
* ![image-20200121004826270](D:\OneDrive\Pictures\Typora\image-20200121004826270.png)
* ![image-20200121004832078](D:\OneDrive\Pictures\Typora\image-20200121004832078.png)



### Interrupts Prior to Instruction Issue

* handled the same way by all the methods
* process state is not modified by an instruction before it issues
* priviledged instruction faults / unimplemented instructions / external interrupts (checked at the issue stage)
* halt instruction issuing when detected $\to$ wait complete $\to$ precise state !



## In-order Instruction Completion

* ![image-20200121005818253](D:\OneDrive\Pictures\Typora\image-20200121005818253.png)
* Instruction takes `i` clock periods reserves stage `i`. valid by control bit in result bus
  * if held? check next cycle
* possible for a short instruction to be placed at stage `i` when previous issued instructions are in stage `j` and `j > i`



### Registers

* reserve stages i < j as well as stage j 
  * the stages i < j that were not previously reserved by other instructions are reserved, loaded with null control information so that don't affect process state
* non-masked exception on result bus? cancel all subsequent inst. coming on the result bus



### Main Memory

* force store inst. to wait the result shift register to be empty before issuing
* or, store can issue and be held in the load/store pipeline untill all preceding inst. known to be exception-free
  * special FU & dummy store entry in result shift register
  * reach stage 1? all prev. inst. completed without exception, signal load/store unit to release store
  * store cancelled/exception? following load/store cancelled, signal pipeline all inst. issued subsequent to the store are cancelled



### Program Counter

* include a field for PC in result shift register



## The Reorder Buffer

* fast inst. get held on result shift register even though no dependency, also block issue register
* ![image-20200121012350443](D:\OneDrive\Pictures\Typora\image-20200121012350443.png)
* [[Q: result shift $\to$ reservation station?]]



### Main Memory

* similar way, store FU & dummy store



### Program Counter

* reserved in ROB
* RS will contain more stages than ROB
* RS must be as long as the longest pipeline stage
  * [[Q: why?]]
* ROB size can be small



### Bypass Paths

* ![image-20200121020222753](D:\OneDrive\Pictures\Typora\image-20200121020222753.png)
* data held in the reorder buffer to be used in place of register data
* comparator for each reorder buffer stage & op designator
  * multiplexer set to gate the data from reroder buffer to the register output latch
* only latest entry should generate a bypass path $\to$ when inst. placed in ROB, any entries with the same destination designator must be inhibited from matching a bypass check
  * [[N: replaced by map table & register renaming then...]]
* too many bypass comparators & circuitry required



## History Buffer

* reduce/eliminate perf. losses with a simple ROB, but without all the control logic needed for multiple bypass paths
* place computed results in working register file, retain state info. so precise state can be restored
* ![image-20200121021109610](D:\OneDrive\Pictures\Typora\image-20200121021109610.png)
* issue $\to$ buffer entry loaded with control info., value of dest. reg. read front the register file and written into the buffer entry
* complete $\to$ directly write register file
* exception (as inst. complete) $\to$ written to history buffer by RS tags
* reach head without exception $\to$ re-used by increasing head pointer
* reach head with exception $\to$ wait pipelien activity compeltes, active buffer entries emptied from tail to head, history values are loaded back into their original registers
* memory: as previous
* hardware requirement: large buffer contain the history information
  * 3 read ports for register file: dest & src read at issue time
    * bypass to history buffer



## Future File

* ![image-20200121022917999](D:\OneDrive\Pictures\Typora\image-20200121022917999.png)
* 2 separate reg. file
  * 1 for state of architecetural (sequential) machine (architectural file)
  * 1 for future (runahead of arch. file, updated ASAP)
* [[N: so 470 we are implemening R10K tag-based renaming + future file]]
* implement interrupts via an "exchange"
  * no extra store as in history buffer method
  * no bypass problem



## Extensions

* handle additional state info.
  * VM, cache, linear pipelines



### Handling Other State Values

* state regs. to page, segment tables, interrupt mask conditions
* precisely maintained with a method similar to the stores to memory
  * ROB: reserve entry and proceed to the part of the machine, wait until receiving a signal to continue from the reorder buffer, reach head to send signal
* condition codes ([[N: EFLAGS dependency?]])
  * ROB: add condition code column and updated with execution, reach head to interrupt
  * history buffer: condition code setting at the time of instruction issue must be saved in the history buffer
    * restore processor state
  * future file: just like ROB (it uses a ROB buffer!)



### Virtual Memory

* must possible to recover fro page faults
* address translation pipeline designed that load/store inst. pass through it in order
* load/store inst. reserve time slots in the result pipeline and/or re-order buffer that read no eariler than the time at which the inst. checked
* store: not used for data, for exception reporting/PC
* addressing fault: inst. cancelled, subsequent loast/store cancelled



### Cache Memory

* update main memory must be precise, but store can be made to cache earlier



#### Store-through Caches

* cache can be updated immediately, while store-through to main memory handled as previous sections
  * all previous inst must first to be known as exception-free
* load inst.: free to use cached copy
* main memory always in precise state
* cache in runahead mode
* cache should be flushed for exception in runahead mode
* --another way--
* cache as register file: cache location have to be read just prior to writing it with new value
  * read cycle for history data can be done in parallel with hit check
* store inst. makes a buffer entry indicating that cache location written, used to restore the suite of the cache



#### Write-Back Cache

* built-in delay between updating cache & main memory
* before write-back: ROB emptied, or checked for data belonging to the line being written back
  * wait until data made its way into the cache
* history buffer: either cache line saved, or write-back wait until associated inst. to the end of buffer



### Linear Pipeline Structures

* ![image-20200121025501542](D:\OneDrive\Pictures\Typora\image-20200121025501542.png)
* ![image-20200121025550429](D:\OneDrive\Pictures\Typora\image-20200121025550429.png)



## Summary & Conclusions

* ![image-20200121025654813](D:\OneDrive\Pictures\Typora\image-20200121025654813.png)
* Five methods
  * Halting issuing for known exceptions?
  * Force instructions to complete & modify the process state in architectural order.
  * Result shift register
  * Reorder buffer
  * History buffer
  * Future file









* CS251A requirements
  * a short paragraph summarizing the problem and goal/contributions of paper
  * a short paragraph summarizing the paper’s methods and results
  * a short paragraph giving your opinion of what is good and bad about the paper.

## Summary

- Precise state means when interrupts happen, the predecessors must have been completed and the following instructions should not change the saved processor state. Precise interrupts are difficult because in out of order pipelined processors, instructions are not completed in sequential order. This paper describes five solutions to implement the precise state and with one solution causing 16% performance, the rest ones result in as little as 3% performance loss.

## Methods & Results

- Apart from forcing instructions to complete and modify the process state in architectural order, four solutions proposing different architectural components to implement the precise state. Register shift registers record all issued instruction in the order of execution latencies. It shifts entries cycle by cycle. To ensure precise state, the instructions above existing instructions in RSS are reserved until the below ones complete. On exceptions and the instruction causing the exception reaches the RSS head, the saved PC is read and RSS is flushed. For the reorder buffer, it records the dependencies of destination registers and broadcasts buffer tags for completion signals. The reorder buffer acts as a circular queue and commits instruction in a FIFO order. To bypass results, each ROB entry must have a comparator for matching tags from result buses and RSS. On exception, ROB also flushes all entries and restores the PC. History buffer fetches old data in the destination registers and stores in the buffer. When an exception instruction reaches the head, the architectural state is restored from the tail pointer to the head pointer and old values are set one by one. It requires more path for data copying and buffer areas for storing temporary values. Future file maintains two separate register files: one for the architectural state (consistent, precise) and one for the active state which gets updated as soon as instructions complete. When exceptions happen and get to the head, the scheme exchanges the architectural state to the current/active state. For memory operations (load/store, VM, cache), they can be handled by reserving entries in the buffer and maintain uncommitted until all previous instructions commit to keep the main memory in a precise state. The author uses the CRAY-1S simulation system and Livermore Loops workload to measure the performance loss when applying these methods. The result shows that about 15% of performance degradation appears by applying the first method and about 3% for the other methods.

## Personal Opinions

- The paper shows several practical methods for implementing precise state in microarchitecture. It's hard to imagine that these well-known methods arising from one single paper. The evaluation part is kind of weak compared to the intensive designs in the paper, since it only uses 14 loops and tested under 5 kinds of number of entries. Some undiscussed aspects are checkpointing-based precise state implementations, how to maintain precise state with these methods and load/store queues (post-retirement buffer, ...), and how tag-based register file interacting with these methods.

