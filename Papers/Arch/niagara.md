# NIAGARA: A 32-WAY MULTITHREADED SPARC PROCESSOR

**Poonacha Kongetira, Kathirgamar Aingaran, Kunle Olukotun  **

---



## Introduction

* Niagara processor: thread-rich arch.
  * 32 threads
  * memory subsystem
    * on-board crossbar
    * L2 cache
    * memory controller for highly integrated design that exploits the TLP
* Sparc V9
* 32 hardware threads
* ![image-20200209170610942](D:\OneDrive\Pictures\Typora\image-20200209170610942.png)
* crossbar interconnects scheme routes memory references to a banked on-chip L2 cache that all threads share
* 4 indep. on-chip memory controllers $\to$ 20Gbytes/s
* 60W
* Solaris OS
* application level
  * Niagara $\to$ 32 discrete processors (OS abstract away the hardware sharing)
* supplying power & dissipating server-generated heat
  * Google: 400-700 W/sq. foot for racked server clusters
  * Commercial data center: 70-150W/sq.foot
    * low ILP
    * large working set
    * poor locality of reference on memory access
    * high cache-miss
    * data-dependent branches
    * high TLP
* use of an SMP composed of multiple processors designed to exploit ILP is neither power efficient nor cost efficient
  * better, build a machine using simple cores aggregated on a single die with a shared on-chop cache & high bandwidth to large off-chip memory, thereby aggregating an SMP server on a chip.



## Niagara Overview

* 32 threads of execution in hardware
* 4 threads into a thread group; shares a processing pipeline (_Sparc pipe_)
* 8 thread groups
* Sparc pipe
  * L1i/d cache
* hide memory/pipeline stalls on a given thread by scheduling other threads in the group onto the SPARC pipe with a zero cycle switch penalty ([[N: 4-thread CGMT]])
* ![image-20200210223958759](D:\OneDrive\Pictures\Typora\image-20200210223958759.png)
* 3M L2 cache
  * 4-way banked
  * pipelined for bandwidth
  * 12-way set-associative (to minimize conflict misses from many threads)
* SMP server data sharing $\to$ coherence miss
  * In conventional SMP systems using discrete processors with coherent system interconnects, coherence misses go out over low-frequency off-chip buses or links, and can have high latencies.
  * Niagara: shared on-chip cache, replace high latency coherence misses as low-latency shared-cache comm.
* crossbar interconnect: link between Sparc pipes, L2 cache banks, other shared res.
  * \> 200Gbytes/s
  * 2-entry queue is available for each src-dest pair
    * queue up to 96 transactions each way in the crossbar
  * port for comm. with I/O subsystem
    * simple age-based priority scheme for dest. arbitration
  * point of memory ordering
* 4 channels of DDR2 DRAM: 20Gbytes/s bandwidth, 128Gbytes capacity
* ![image-20200210224558122](D:\OneDrive\Pictures\Typora\image-20200210224558122.png)



## Sparc Pipeline

* each thread
  * unique reg., inst./store buffers
* thread group
  * share L1 cache, TLB, FU, pipeline regs.
* single-issue pipeline with six stages
  * fetch, thread select, decode, execute, memory, write back
* ![image-20200210225651857](D:\OneDrive\Pictures\Typora\image-20200210225651857.png)
* fetch
  * icache, ITLB
  * selecting the way
  * critical path: 64-entry, fully-associative ITLB
  * thread-select multiplexer determines which PC should perform the access
  * 2 inst. each cycle
  * predecode bit: long-latency inst.
* thread-select
  * thread-select multiplexer: choose thread from available pool to issue an inst. into the downstream stages
  * Instructions fetched from the cache in the fetch stage can be inserted into the instruction buffer for that thread if the downstream stages are not available  
* Pipeline registers for the first two stages are replicated for each thread  
* decode
  * inst. decode, reg file access
  * bypass unit: handle inst. result that must be passed to dependent inst. before the reg. file is updated
  * mul/div: long latency, thread switch
* load store unit
  * data TLB (DTLB)
    * memory stage
    * critical path, 64-entry, fully associative
  * data cache
    * memory stage
  * store buffer
    * 4 x 8-entry store buffers (one per thread)
    * checking phy. tags in the store buffer $\to$ RAW hazards between load/stores
      * after TLB access in the early part of write back stage
    * bypassing of data to a load to resolve RAW hazards
    * load data is available for bypassing to dep. inst. late in the write back stage
* single-cycle inst. update reg. file in the write back stage
* The thread-select logic uses information from various pipeline stages to decide when to select or deselect a
  thread. 
  * For example, the thread-select stage can determine instruction type using a predecode bit in the instruction cache, while some traps are only detectable in later pipeline stages. Therefore, instruction type can cause deselection of a thread in the thread-select stage, while a late trap detected in the memory stage needs to flush all younger instructions from the thread and deselect itself during trap processing.  



## Pipeline Interlocks & Scheduling

* single-cycle inst. $\to$ full bypassing to younger inst. from the same thread
* load latency: 3-cycle
* long-latency inst. $\to$ pipeline hazards
* structural hazards



### Thread Selection Policy

* switch between available threads every cycle, giving priority to the least recently used thread  
* unavailable thread
  * long latency inst.
  * pipeline stalls (cache misses, traps, resource conflicts)
* assumes that loads are cache hits, and can therefore issue a dependent instruction from the same thread speculatively  
  * such a speculative thread is assigned a lower priority for instruction issue as compared to a thread that can issue a non-speculative instruction 
* ![image-20200210232438560](D:\OneDrive\Pictures\Typora\image-20200210232438560.png)
* ![image-20200210232640668](D:\OneDrive\Pictures\Typora\image-20200210232640668.png)
* ![image-20200210232702339](D:\OneDrive\Pictures\Typora\image-20200210232702339.png)
* ![image-20200210232714028](D:\OneDrive\Pictures\Typora\image-20200210232714028.png)



## Integer Register File

* 3 read port
  * single-issue machine (2)
  * store & few other 3 src instructions
  * the registers of all threads share the read circuitry because only one thread can read the register file in a given cycle
* 2 write ports
  * single-cycle & long-latency operations
  * write-back: arbitrarte port
* Register window
  * ![image-20200210235022762](D:\OneDrive\Pictures\Typora\image-20200210235022762.png)
  * A single window consists of eight in, local, and out registers; they are all visible to a thread at a given
    time.
    * out registers of a window are addressed as the in registers of the next sequential window, but are the same physical registers.  
    * ![image-20200210235840248](D:\OneDrive\Pictures\Typora\image-20200210235840248.png)
* Procedure calls can request a new window, in which case the visible window slides up, with the old outputs becoming the new inputs.   
* Return from a call causes the window to slide down  
* Working set: set of registers visible to a thread (fast register file cells)
  * transfer port link
* window changing event $\to$ deselection of the thread + transfer of data between old & new windows
  * 1-2 cycles
  * complete $\to$ thread available again
  * independent of operations to registers from other threads
* [register window](https://projects.cerias.purdue.edu/stackghost/stackghost/node5.html)



## Memory Subsystem

* L1i: 16KB, 4-way set associative, 32 byte block

  * random replacement for area saving
  * fetch 2 inst. per cycle
  * line fill 2nd inst.

* L1d: 8KB, 4-way set associative, 16 byte line size

  * write-through policy
  * not hide large working set from commerical server application
    * but thread group does
  * small area, good trade-off between miss rates, area, ability of other threads in the group

* cache coherence

  * L1: write through, allocate on load, no-allocate on stores

    * valid/invalid lines
    * [[N: not write-back, just write through (direct pass) to L2 cache]]

  * L2: directory that shadows the L1 tags

    * interleave data across banks at a 64-byte granularity
    * copy-back policy: writing back dirty evicts, dropping clean evicts

  * load miss in L1 $\to$ source bank of the L2 cache + replacement way from L1 cache

    * the load miss address is entered in the corresponding L1 tag location of the directory,

    * the L2 cache is accessed to get the missing line

    * data is then returned to the L1 cache

    * directory thus maintains a sharers list at L1-line granularity  

      * A subsequent store from a different or same L1 cache will look up the directory and queue up invalidates to the L1 caches that have the line  

      * Stores do not update the local caches until they have updated the L2 cache  (atomic visibility)

      * During this time, the store can pass data to the same thread but not to other threads;  

        * store attains global visibility in the L2 cache (!)

        * crossbar

          * memory order (execute order) between transactions from the same and different L2 banks  

          * guarantees delivery of transactions to L1 caches in the same order

          * [[N: notice that in LSU, the store can bypass to load, so it's TSO order. ]]

          * > TSO: store effects can be observed after sequent loads (since stores are buffered)
            >
            > Processor P can read B before its write to A is seen by all processors (processor can move its own reads in front of its own writes) (relax program order) 
            >
            >  Reads by other processors cannot return new value of A until the write to A is observed by all processors (relax atomicity)  
            >
            > once in L2, observed by anyone

![image-20200211002159397](D:\OneDrive\Pictures\Typora\image-20200211002159397.png)

![image-20200211002404359](D:\OneDrive\Pictures\Typora\image-20200211002404359.png)

[TSO-order](https://www.cs.rice.edu/~johnmc/comp522/lecture-notes/COMP522-2019-Lecture9-HW-MM.pdf)

[SC-TSO](https://www.cis.upenn.edu/~devietti/classes/cis601-spring2016/sc_tso.pdf)

![image-20200211010219099](D:\OneDrive\Pictures\Typora\image-20200211010219099.png)











* CS251A requirements
  * a short paragraph summarizing the problem and goal/contributions of paper
  * a short paragraph summarizing the paper’s methods and results
  * a short paragraph giving your opinion of what is good and bad about the paper.

## Summary

- This paper describes the design of Sparc Niagara. This processor targets the commercial symmetric multiprocessor (SMP) systems (e.g. Web servers). These systems have large working sets, poor locality of reference on memory access and high cache miss rates. Therefore the systems have low available ILP but can exploit high TLP. To efficiently execute these systems, we should build a machine using simple cores on the same die, shared on-chip cache, and high bandwidth memory. Niagara is the typical implementation of this pattern.

## Methods & Results

- Niagara supports 32 threads of execution in hardware. Each four threads are grouped into a thread group, which shares a processing pipeline (Sparc pipe). The way Niagara used is like fine-grained multithreading. An extra stage, thread-select, is inserted between the fetch and decode stage as in the normal five-stage pipeline. The thread selection is based on various stage information, including predecode bits indicating short/long-latency instructions, availability of threads by pipelining hazards (cache misses, traps, resource conflicts), register window allocation/deallocation, and priorities based on least recently used threads. Niagara employs a small L1 cache for saving areas and power and assumes that large TLP parallelism can hide the load miss latencies. Since all caches are on-chip, Niagara can replace all high latency coherence misses to low latency shared memory communications. The L1 cache is write-through and the L2 cache leverages the scheme of directory-based coherence protocol. The crossbar between thread groups provides high memory bandwidth between Sparc pipes, communication ports for I/O subsystems, and establishes the memory order since stores in L2 serve as the global visibility signal.

## Personal Opinions

- This paper is interesting since it provides a simple but effective design for SMP tasks that highly exploit thread-level parallelism. However, this paper lacks of real performance results, so the efficiency of Niagara is questionable. Meanwhile, I suspect there are some limitations in this design. First, does this design area-efficient (though it claims itself to be)? There are a large number of physical registers and buffer entries (per thread: instruction, store; per group: L1, TLB, pipeline) on the chip. The relatively small L1 data cache looks suspicious that the other components may occupy too much area. Second, can this design be scalable? The design places high pressure on crossbar and memory bandwidth to efficiently exchange memory contents. Therefore, we might need to change memory types (e.g. HBM) or on-chip topology (e.g. InfiniFabric, Mesh, Ring) to make the design scale to a larger number of threads. Some potential future discussions can be more complex thread-select logic; performance of this design on non-Sparc chips (so we don't need register windows anymore); comparing/extending this design with GPU/SPMD (How to add SIMD operations? How can we leverage the locality of processors to do warp-like execution?).



