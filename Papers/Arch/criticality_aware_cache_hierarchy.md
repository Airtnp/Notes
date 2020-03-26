# Criticality Aware Tiered Cache Hierarchy: A Fundamental Relook at Multi-level Cache Hierarchies  

**Anant Vithal Nori, Jayesh Gaur, Siddharth Rai, Sreenivas Subramoney,  Hong Wang**

---



## Introduction

* large cache vs. access latency $\to$ multi-level cache hierarchy

  * L1/L2 private, close to CPU core
  * LLC shared

* fundamental analysis of popular 3-level cache, understand perf. delivery using program criticality

* increasing L2 cache size to reduce average hit latency is an inefficient design choice

  * not all load accesses matter for core perf., only on critical path
  * current optimize for all load accesses: sub-optimal

* Criticality Aware Tiered Cache Hierarchy (CATCH)

  * accurate detection of program criticality in hardware
    * 3KB area, optimized representation of the data dependency graph
  * novel set of inter-cache prefetchers (Timeliness Aware & Criticality Triggered): on-die data accesses that lie on the critical path of execution served at the latency of fastest L1 cache
  * LLC: reducing slow memory accesses, large L2 redundant
  * eliminate L2

* > 1) We first do a detailed analysis of the three level cache hierarchy and develop an understanding of
  > the performance delivered from this hierarchy using program criticality. We show through oracle studies how criticality can be used as a central consideration  for achieving an efficient on-die cache hierarchy and how each level of such a cache hierarchy should be optimized.
  >
  > 
  >
  > 2) We propose, and describe in detail, a novel and fast incremental method to learn the critical path using an optimized representation of the data dependency graph first proposed in the seminal work by Fields et al. [1] in hardware, that takes just 3 KB of area. We use this to enumerate a small set of critical load instructions. 
  >
  > 
  >
  > 3) We then propose the Timeliness Aware and Criticality Triggered (TACT) family of prefetchers for these identified critical loads. The TACT prefetchers prefetch data lines accessed by the critical load PCs from the L2 or the LLC to the L1 cache. TACT utilizes the association between the address or data of load instructions in the vicinity of the target critical load to issue prefetches which bring the data from the LLC or L2 into L1, just before the actual load access is issued by the core. TACT also proposes a code run-ahead prefetcher that eliminates code stalls because of code L1 miss. We should note that unlike traditional prefetchers [21], [39] that target LLC misses, TACT is a unique inter-cache prefetcher which tries to hide the latency of L2 and LLC for a select subset of critical load and code accesses that are otherwise served in the baseline from the slower outer level caches.
  >
  > 
  >
  > 4) With TACT prefetchers incorporated into the design we demonstrate that most critical load accesses that would have hit in the outer level caches are served by the L1 cache. TACT-based critical path accelerations fundamentally enable the Criticality Aware Tiered Cache Hierarchy (CATCH). CATCH represents a powerful framework to explore broad chip-level area, performance and power trade-offs in cache hierarchy design. Supported by CATCH, we explore and analyze radical directions such as eliminating the L2 altogether to dramatically reduce area/cost and enable higher-performing CPUs at similar or lower power

* ![image-20200128214958890](D:\OneDrive\Pictures\Typora\image-20200128214958890.png)
* ![image-20200128215008087](D:\OneDrive\Pictures\Typora\image-20200128215008087.png)



## Background

* Skylake: 32KB L1I, L2D, 256KB L2 (not inclusive, allocate on L1 miss but no back-invalidate to L1 on L2 evictions), 8MB LLC (strictly inclusive of L1 + L2)
  * LLC eviction: back invalidate snoop out lines in L1/L2 to guarantee inclusion
  * LLC is large and has long latency
* Deploy large L2 cache
  * LLC as exclusive of L2 and L1: A cache hit/miss in LLC is filed in the L2 and an eviction from the L2 is filled in the LLC
  * help applications with large code footprints
  * reduce stalls in the core front-end because of code lines that would need to read from the slower LLC
  * filter requests that would need to travel on the interconnect to the LLC, saving power
* ![image-20200128220324803](D:\OneDrive\Pictures\Typora\image-20200128220324803.png)
* ![image-20200128220338565](D:\OneDrive\Pictures\Typora\image-20200128220338565.png)
* 7.8% drop if L2 removed, 5.1% loss if L2 area added to LLC
* However, 3-level hierarchy is actually inefficient for area & power
  * inclusive: area wasted in creating low latency L2 cache which essentially replicating some of the data present in the LLC
  * exclusive LLC: private L2 makes cache capacity seen by each core (L2 + shared LLC) is lower than what they would have seen with a large shared LLC
  * replicated code in L2 when symmetric processes run on many cores
  * replicated shared, read-only data
  * exclusive LLC: separate snoop filter or coherence directory, extra area
  * but gives a significant performance boost



### Program criticality

* OoO core bounded by critical path of execution
* criticality can be described with program's data dependency graph (DDG)
* critical path: maximum weighted length [[N: critical path is for both hardware (clock freq. vs slack)/software (latency)]]
* ![image-20200128222019755](D:\OneDrive\Pictures\Typora\image-20200128222019755.png)
* ![image-20200128222033203](D:\OneDrive\Pictures\Typora\image-20200128222033203.png)



## Motivation



### Latency sensitivity

* ![image-20200128222250643](D:\OneDrive\Pictures\Typora\image-20200128222250643.png)
* ![image-20200128224525544](D:\OneDrive\Pictures\Typora\image-20200128224525544.png)



### Criticality & cache hierarchy

* Criticality at L1
  * ![image-20200128225229400](D:\OneDrive\Pictures\Typora\image-20200128225229400.png)
  * 16% drop if all L1 hits to L2 hits
  * 4.8% drop if only non-critical L1 hits to L2 hits
  * small non-critical dependence chains will crease new critical paths
  * challenging to implement optim. at L1
* Criticality at L2
  * 7.8% loss if all L2 hits to LLC
  * 0.76% drop if only non-critical L2 hits to LLC
  * good candidate
* Criticality at the LLC
  * 7% drop if all LLC hits to memory
  * 33% hits as not critical
  * 1.2% drop if only non-critical LLC hits to memory
    * linear scaling
  * likely of creating new critical paths
* L2 is the ideal candidate



### CATCH - Performance potential

* oracle on-die prefetcher to convert L2/LLC hits to L1 hits
* ![image-20200128232635805](D:\OneDrive\Pictures\Typora\image-20200128232635805.png)
* ![image-20200128232646252](D:\OneDrive\Pictures\Typora\image-20200128232646252.png)
* ![image-20200128232746876](D:\OneDrive\Pictures\Typora\image-20200128232746876.png)
* ![image-20200128232759429](D:\OneDrive\Pictures\Typora\image-20200128232759429.png)



## Criticality Aware Tiered Cache Hierarchy (CATCH)

* accurate detection of criticality in hardware
* family of prefetchers corresponding to critical load accesses + code missing L1i



### Criticality Marking

* how to identify critical load PCs? including dependency chains
* data dependency graph
* past history of the execution to predict future instances of critical inst.
* retire $\to$ add to graph
* graph buffer inst. at least 2x ROB size, walk through the critical path in this buffered portion of the graph and record the PC of all loads that were on the critical path and had hit in the L2/LLC
  * the area of the graph can be prohibitive...
  * enumerate the critical path needs a DFS search in the graph to find out the longest path...
* Graph Buffering
  * ![image-20200128234133357](D:\OneDrive\Pictures\Typora\image-20200128234133357.png)
  * ![image-20200128233441196](D:\OneDrive\Pictures\Typora\image-20200128233441196.png)
  * `D`: allocation in the OOO
  * `E`: dispatch to execution units
  * `C`: write-back time
  * `D-D`: in-order allocation
  * `C-C`: in-order retirement
  * `D-E`: renaming latency
  * `E-D`: bad speculation
  * `C-D`: depth of the machine
  * `E-E`: actual data dependency
  * `E-C`: latency of execution
    * measured from the T the inst. dispatched to execution units till when it does the write-back
    * quantize (divided by 8) & store it as a 5-bit saturating counter
  * inst. retire $\to$ add to the end of the graph
  * buffered X insts. $\to$ enumerate critical path, identify critical inst. (equal to 2x ROB size is sufficient)
* Enumerating the Critical Path
  * critical path: longest path from `D` node of the first inst. to the `C` node of the last inst. in the buffered graph
  * On allocation to the graph, each node of the retired instruction checks all its incoming edges to determine the one it needs to take to maximize its distance from the beginning of the graph  
    * This distance is stored as the node cost and the identified incoming edge as the `prev-node`  
    * Since each node cumulatively stores its longest distance, incoming nodes only need to compare with their immediate edges
  * ![image-20200129001304634](D:\OneDrive\Pictures\Typora\image-20200129001304634.png)
* Recording the Critical Instructions
  * During the critical path walk through in the graph, we record the PC of the load instructions that are on the critical path and hit in the L2 or LLC in a 32 entry critical load table 
    * 8-way set-associative and maintained using LRU
    * 2 bit saturating confidence counter for each table entry
    * The PC is marked critical only if it is in the table and its confidence counter has saturated
  * After every 100K instructions have retired, we reset the confidence counters of those PCs that have not yet reached saturation and ask them to re-learn  
  * walking through the graph and recording in the critical table will take a finite number of clock cycles, depending on the length of the E-chain in the critical path  
    * normally a few cycle
    * the path can be long and it may take several cycles to walk through the graph (and in the meantime, ROB continues to retire) $\to$ keep larger buffered graph than actually needed (2.5X ROB size, but only walk through 2x ROB size)
  * Once we have walked through the critical path, we flush out the buffered instructions (this is done by just resetting the read pointer of the graph structure) and wait for the next set of instructions to be buffered
  * graph overflow $\to$ discard + start afresh
* Area Calculation
  * ![image-20200129001859590](D:\OneDrive\Pictures\Typora\image-20200129001859590.png)
  * 3KB (224 ROB entries, prev-node & node cost & PC address 10B)
  * ![image-20200129001942175](D:\OneDrive\Pictures\Typora\image-20200129001942175.png)



### Timeliness Aware & Criticality Triggered Prefetches

* critical load identified $\to$ prefetch into L1
* memory prefetch: fetch requests from DRAM, increase LLC hit rate
* our prefetch: timely prefetch of cache-lines, present in outer level caches, into L1 cache
  * hide smaller latency
* L1 is small in cap/bandwidth $\to$ direct prefetches to only select list of critical loads
* over-fetching $\to$ thrashing, new critical paths



### Data Prefetching

* ![image-20200129004149621](D:\OneDrive\Pictures\Typora\image-20200129004149621.png)
* prefetching tuple `(Target-PC, Trigger-PC, Association)`
  * `Target-PC`: the PC of the load that needs a prefetch  
    * dynamic instances of critical loads, identified using criticality detection
  * `Trigger-PC`: load instruction that will trigger the prefetch for the target
    * Attributes (address or data) of the Trigger-PC will have a relation to the address of the
      Target-PC. This relation needs to be learned by TACT to successfully issue just in time prefetches for the Target-PC  
* on dispatch / execution of an instance of `Trigger-PC`, the address of a subsequent instance of
  the `Target-PC` can be predicted using the relevant attributes of the `Trigger-PC` and its relation to the `Target-PC`. The specific instance of the Target-PC prefetched by a given instance of the Trigger PC is the measure of the _prefetch distance_ and is related to the timeliness of the prefetching.
  * prefetch distance of `p` is prefetching the `p`-th subsequent instance of the Target-PC on a trigger from the Trigger-PC. 
  * higher prefetching distance can pollute the small L1 cache
* optimal, least possible, distance for each instance of the `Target-PC`
* ![image-20200129004623587](D:\OneDrive\Pictures\Typora\image-20200129004623587.png)
* ![image-20200129145626591](D:\OneDrive\Pictures\Typora\image-20200129145626591.png)



#### TACT - Cross

* Cross trigger address associations typically arise due to load instructions where the Trigger-PC & Target-PC have the same `RegSrcBase` but different `Offsets`
* Examples: indirect program behavior where src reg. for Trigger-PCs & Target-PCs are loaded with data values with fixed deltas between them
* how to identify cross Trigger-PCs?
  * over 85% of cross addr. association delta values well within 4KB page
  * both Trigger-PC & Target-PC access same 4KB page
  * track last 64 4KB pages seen in a 64 enty 8 way set-associative _Trigger Cache_
    * indexed using 4KB aligned address
    * each entry in the cache tracks the first four load PCs that touch this 4 KB page during its residency in the Trigger Cache
* Critical Target-PCs instances, during training, lookup this Trigger Cache with their 4 KB aligned address and receive a set of four possible candidates for Trigger-PC. These load PCs may have a cross association with the target load
* Each Target-PC entry has a single current trigger candidate that is initially populated with the oldest of the four possible Trigger-PCs from the trigger cache and lasts till sixteen instances of the trigger
  * if stable delta between trigger & target isn't found $\to$ switch to next from possible candidate Trigger-PCs
  * allow wrapping around of the Trigger-PC candidates from the Trigger Cache a total of four times before we stop searching for a Cross Trigger PC  
  * stable Trigger-PC identified for Target-PC $\to$ issue prefetch whenever the OOO dispatch Trigger-PC
    * address: address of current Trigger-PC + offset TACT learned during training



#### TACT - Deep Self

* most common addr. association for loads: addrs of successive instances of iterations of the same load PC
* E.g.: loads in the loop, stable offset between load addrs in successive iterations
* already used in stride prefetching
* but baseline stride prefetcher uses a prefetch distance of 1 that may not be timely enough to save all of the L2/LLC hit latency
* increasing the prefetch distance of all load PC in baseline stride prefetcher hurt perf.
* TACT: add increased, deep, prefetch distance prefetching for only a small subset of critical load PCs
* Deep distance prefetch addresses are predicted by multiplying the learnt stride/offset by the desired distance and  adding to the triggering address. 
* Even PCs that have a frequently occurring high confidence stride in their addresses don’t necessarily have only a single stride in their access  pattern. 
  * E.g. loop exit + re-enter
* learn _safe_ length of stride by the critical Target-PC
* track current length of the stride seen by the Target-PC (capped to 32 with a wraparound), use it to update (incr/decr) safe length counter for the Target (capped to 32)
  * confidence: tracked using 2-bit safe length confidence counter (init. to 4)
    * if saturated, TACT issues prefetches for both distance 1 & maximum safe prefetch distance



#### Feeder

* addr. association don't exist for critical loads $\to$ data association
* how to identify Trigger-PC?
  * heuristics
  * track load to load dependencies
* tracking the last load that updates an architectural register
* for each arch. reg., store PC of the last load that updated it
  * updated by load inst.
  * non-load inst. $\to$ dest arch. reg. updated with youngest load PC across all of its source arch. reg.
  * propagate info. on load PCs that directly/indirectly update arch. reg.
* Trigger-PC for a Target-PC is the youngest load PC to have updated any of the load's src reg.
* TACT entry for a target increments 2-bit confidence counter for the Trigger-PC
  * saturate $\to$ Trigger-PC added to Feeder-PC-Table & TACT learn whether a linear relationship of the form `Address = Scale * Data + Base` exists between Trigger data & Target PC address
    * scale are limited to power of 2, 1/2/4/8
    * at most 3 shift op.
    * 2 bit confidence counter for Scale & Base $\to$ confident, data from a Trigger-PC can trigger a prefetch for the Target-PC.
* prefetch upto a prefetch distance of 4 for the Trigger-PC
* The prefetch for the Trigger-PC, when data is available, triggers the prefetch for the Target-PC. If the Trigger-PC doesn’t have a self trigger address association then we cannot do TACT-Feeder prefetching



### Code Prefetching

* in-order Front End (FE): fetch, decode, issue
* Next Instruction Pointer (NIP): use current NIP to predict next NIP
  * [[N: next-line, trace-cache]]
  * [[N: how many branch can co-exist for one fetch? how to fetch if many branch exists?]]
* L1 code miss $\to$ stall, NIP logic & branch pred. sit idle
* TACT code runahead to prefetch code lines while FE is stalled serving the code miss
* ![image-20200129152939837](D:\OneDrive\Pictures\Typora\image-20200129152939837.png)
* Code Next Prefetch IP (CNPIP) counter: prefetch code lines
  * NIP logic stalled by L1 code miss $\to$ current NIP checkpointed, NIP logic queried with with CNPIP instead (CNPIP runahead of NIP and prefetch the bytes CNPIP points to into the Code L1)
  * branch pred. predicts next IP, whenever a branch encountered for a given CNPIP
  * reset to base NIP on a branch mis-prediction or when the base NIP moves ahead of it.



### Hardware Requirement

* ![image-20200129152905349](D:\OneDrive\Pictures\Typora\image-20200129152905349.png)
* ~1.2KB



## Evaluation Methodology

* ![image-20200129153741494](D:\OneDrive\Pictures\Typora\image-20200129153741494.png)
* ![image-20200129153752207](D:\OneDrive\Pictures\Typora\image-20200129153752207.png)



## Summary

* ![image-20200129153827093](D:\OneDrive\Pictures\Typora\image-20200129153827093.png)















* CS251A requirements
  * a short paragraph summarizing the problem and goal/contributions of paper
  * a short paragraph summarizing the paper’s methods and results
  * a short paragraph giving your opinion of what is good and bad about the paper.

* ## Summary

* This paper inspects the current trending of increasing L2 cache size to reduce average hit latency in multi-level cache designs. The authors evaluate the effectiveness of large L2 cache on all accesses and critical accesses and find that increasing L2 cache size is an inefficient design choice. Furthermore, they propose Criticality Aware Tiered Cache Hierarchy design that leverages detections of criticality loads and prefetching code and data using novel prefetchers based on data dependency graphs.

  ## Methods & Results

* To evaluate the effectiveness of L2 cache, the authors simulate several surveys about cache sensitivity and criticality. It shows that if critical loads can be served by L1, L2 is an ideal candidate for criticality optimization which saves area and power on chips. Then the paper proposes Criticality Aware Tiered Cache Hierarchy (CATCH), which utilizes the Data Dependency Graph built on-the-fly with ROB instructions retirement. The graph nodes and values are updated incrementally and critical instructions are recorded. After identifying the critical loads, multiple novel prefetchers learn the pattern between Trigger-PC and Target-PC according to cross with the same base register (indirect pattern), deep self with successive iterations of same load PC (loop pattern), and feeder with data association (dependency of loads/data). For L1 code miss, it adds a Code Next Prefetch IP (CNPIP) counter to prefetch code lines on front-end stalls to allow run-ahead fetching and branch predictions. For evaluation, the authors leverage SPEC2006 benchmarks and an x86 simulator. The result shows that CATCH outperforms the traditional three-level cache hierarchy for single-thread workloads by about 10% while reducing area and power cost.

  ## Personal Opinions

* It's a very novel idea to discard L2 cache which is considered to be an orthodox three-level cache hierarchy. The critical-aware design is really interesting and I never imagine that the dependencies graph can be persisted on-chip to allow complex optimizations. However, I'm worried about the complex design in the circuits. Can it meet the slack requirement of other components? Can this design scale to large L1, large LLC, or a large number of cores? Meanwhile, has any chip employed this design and given some real benchmarks? Those questions still make me curious.

