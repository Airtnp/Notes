# Roofline: An Insightful Visual Performance Model for Floating-Point Programs and Multicore Architectures

**Samuel Williams, Andrew Waterman, David Patterson**

---



[15418-slide](http://15418.courses.cs.cmu.edu/spring2017/lecture/perfeval/slide_040)



## Introduction

* Multicore, no conventional wisdom
* performance model for guideline?
* insightful, no need to be perfect



## Performance Models

* predict performance on multiprocessors
  * stochastic analytics models
  * statistical performance models
* provide valuable insight into the primary factors affecting the performance of compute systems
  * bound & bottleneck analysis
  * critical influence of the system bottleneck is highlighted & quantified
  * Amdahl's Law



## The Roofline Model

* off-chip memory bandwidth will often be the constraining resource
* operational intensity: operations per byte of DRAM traffic
  * total bytes accessed: go to the main memory after they have been filtered by the cache hierarchy
  * traffic between the caches & memory (not processor & caches)
  * instead of arithmetic intensity / machine balance
    * they measure traffic between caches & processor, not cache & DRAM
    * work with kernels where the operations not arithmetic
* floating-point performance + operatonal intensity + memory performance in 2D graph
* peak floating-point performance using hardware specifications / microbenchmarks
  * [[R: TMA analysis?]]
  * working sets of kernels not fit fully in on-chip caches
  * progressively optimized microbenchmarks
    * prefetching
    * data alignment
* ![image-20191028204900516](D:\OneDrive\Pictures\Typora\image-20191028204900516.png)
* log-log scale graph
  * Y-axis: attainable floating-point performance (Flops/second)
    * `Attainable (GFlops/sec) = Min(Peak Floating Point Performance, Peak Memory Bandwidth x Operational Intensity)`
  * X-axis: operational intensity (Flops/Bytes)
  * horizonal line: peak floating-point performance
  * diagonal line (45-degree): maximum floating-point performance that the memory system of that computer can support
  * vertical line: performance of the kernel on that computer based on operational intensity
  * ROOFLINE metaphor
  * ridge point: (minimum operational intesnity required for maximum perf, maxmimum perf)
    * level of difficulty for programmers & compiler writers to achieve peak performance



## Adding Ceilings to the Model

* upper-bound
* ![image-20191028223304475](D:\OneDrive\Pictures\Typora\image-20191028223304475.png)
* advantage of bound & bottleneck analysis: a number of alternative can be treated together, with a single bounding analysis providing useful informaton about them all.
* reduce computational bottlenecks
  * Improve ILP, apply SIMD: fetching, executing, committing maximum # of instructions per clock cycle
    * convert FU latency
    * unrolling loops
    * floating-point SIMD
  * Balance floating-point operation mix
    * significant fraction of the instruction mix be floating-point operations
    * equal # of simulatneous floating-point additions & multiplications (FMA)
* reduce memory bottlenecks
  * Restructure loops for unit stride accesses: hardware prefetching
  * Ensure memory affinity: multi-core local access to memory attached to local core
  * Use software prefetching: keeping many memory operations in flight
* operational intensity of a kernel → optimization region, which optimization should try
  * yellow: computational optimizations
  * blue: memory optimization



## Tying the 3Cs to Opertional Intensity

* operational intensity fixed? wrong for Dense Matrix/FFT
* caches affect # of accesses to memory → improve cache perf → increase operational intensity
* connect 3Cs model to Roofline model
  * Compulsory misses: set minimum memory traffic, highest possible operational intensity
  * Conflict/Capacity misses: lower operational intensity of a kernel, avoid such miesses
    * padding arrays to change cache line adderssing
    * direct-write (uncacheable) prevents loading a cache block with data to be overwritten
* shift-right of operational intensity could put a kernel in a different optimization region



## Demonstration of the Model

### Diverse Multicore Computers

* ![image-20191028234633935](D:\OneDrive\Pictures\Typora\image-20191028234633935.png)

* Intel Xeon

  * 2 SIMD per clock cycle, each 2 double-precision floating-point operations
  * front side bus connecting to a common north bridge chip & memory controller
    * otherwise, memory controller on chip

* Opteron X4

  * on-chip L3 caches
  * 2 sockets communicate over separate, dedicated Hypertransport links

* Sun UltraSPARC T2+

  * modest clock rate, twice as many cores per chip
  * 8 hardware-supported threads per core (SMT)
  * highest memory bandwidth
  * 2 dual-channel memory controller driving 4 set of DDR2/FBDIMMS per chip

* IBM Cell QS20

  * highest clock rate
  * heterogeneous design, 1 PowerPC core + 8 SPEs (Synergistic Processing Element) having own unique SIMD-style instruction set
    * SPE has own local memory instead of a caches, transfer data from main memory into local memory & back
    * use DMA, like software prefetching

  

  

### Diverse Floating-Point Kernels

* ![image-20191028234650975](D:\OneDrive\Pictures\Typora\image-20191028234650975.png)

  

### Roofline Model & Results

* Intel Xeon
  * highest peak double precision performance
    * but requires 6.7 operational intensities / 55 floating-point operations per double precision operand (8 bytes)
    * limitation of front side bus (coherency traffic can consume 1/2 bandwidths)
  * snoop filter: prevent unnecessary coherency traffic
    * working set small enough for hardware to filter → snoop filter nearly double the delivered memory bandwidth
  * ![image-20191029000153367](D:\OneDrive\Pictures\Typora\image-20191029000153367.png)
  * ![image-20191029000201536](D:\OneDrive\Pictures\Typora\image-20191029000201536.png)

* Opteron X4

  * memory controller on chip, own path to 667 MHz DDR2 DRAM, separate paths for coherency
  * rigid point: 4.4 operational intensity
  * ![image-20191029000210159](D:\OneDrive\Pictures\Typora\image-20191029000210159.png)
  * ![image-20191029000215958](D:\OneDrive\Pictures\Typora\image-20191029000215958.png)

* IBM Cell QS20

  * ridge point of operational intensity = 0.65
  * ![image-20191029000224752](D:\OneDrive\Pictures\Typora\image-20191029000224752.png)
  * ![image-20191029000231279](D:\OneDrive\Pictures\Typora\image-20191029000231279.png)

* Sun T2+

  * highest memory bandwidth → ridge point exceptionally low operational intensity
  * ![image-20191029000007655](D:\OneDrive\Pictures\Typora\image-20191029000007655.png)

* Kernel optimizations

  * ![image-20191029000904175](D:\OneDrive\Pictures\Typora\image-20191029000904175.png)

* Productivity vs. Performance

  * productivity: programming difficulty
  * low ridge point → productivity?
  * the higher the ridge point, the lower the unoptimized performance is

* summary

  * ![image-20191029001551670](D:\OneDrive\Pictures\Typora\image-20191029001551670.png)

  

## Fallacies about Roofline

* The model doesn't take into account all features of modern processors, like caches, prefetching?
  * No. Operational intensity cares caches
  * Do care about prefetching increasing operational intensity
* Double cache size will increase operational intensity?
  * No. Compulsory memory traffic will not help
* The model doesn't account for the long memory latency
  * ceiling for no software prefetching because of low memory bandwidth due to not hide memory latency
* The model ignores integer units in floating-point programs, which can limit performance
  * \# of integer & integer performance can affect performance
* The model has nothing to do with mulitcore
  * Little's Law, bandwidth orientation of the Roofline model
* You need to recalculate the model for every kernel
  * For given performance metrics, computer, just once
  * ceilings measured once
* The model is limited to easily optimized kernels that never hit in the cache
  * do hit the kernel
  * dwarfs are not easy to optimize
* The model is limited to floating-point programs
  * can work for performance was a function of different performance metrics
  * ![image-20191029115523329](D:\OneDrive\Pictures\Typora\image-20191029115523329.png)
* The Roofline model must use DRAM bandwidth
  * if fit in L2? just L2 cache bandwidth



## Conclusions

* simple & visual model to help see 
  * which systems would be a good match to important kernels
  * how to change kernel code or hardware to run desired kernels well
* microbenchmarks, or performance counters
* synergistic relationship between performance counter & Roofline model



## Appendix A

* Finding Operational Intensity, Rooflines & Ceilings
  * DRAM bandwidth-oriented Roofline model is built using three sets of numbers collected either from microbenchmarks / derived from a given architecture's software optimization mnaual
  * performance is minimum of
    * Op. Intensity * Bandwidth
    * In-core Flop/sec
    * In-core Flop/sec as a function of the floating-point fraction
  * Operational Intensity
    * architecture- / kernel- dependent
    * calculate per combination
    * calculate by performance counter & memory traffic measurement
  * Main Memory Bandwidth
    * ![image-20191029125647274](D:\OneDrive\Pictures\Typora\image-20191029125647274.png)
    * ![image-20191029125530106](D:\OneDrive\Pictures\Typora\image-20191029125530106.png)
    * highly tuned versions of STREAM benchmark for performing both a dot product & a copy
      * pad arrays to avoid bank / cache conflicts
      * exploit cache bypass instructions / increase conversion constant
      * exploiting memory affinity to collect a new bandwidth
      * software prefetching with an auto-tuned prefetch distrance to the loop
      * reduce dataset size to improve effectivenesss of a snoop filter
  * In-Core Parallelism
    * ![image-20191029125521691](D:\OneDrive\Pictures\Typora\image-20191029125521691.png)
    * TLP: lowest ceiling TLP-only, each thread receives N/NThreads elements
      * naively unrolled, dependent chain of scalar floating-point adds
      * no instruction-/data-/function unit- level parallelisms
      * expose latency of floating-point pipeline
      * throughput bound: `Cores x Frequency x max(1, ThreadsPerCore/Latency)`
    * ILP: unrolling & maintaining several partial sums
      * throughput bound: `Cores x Frequency`
    * DLP: SIMD
      * throughput bound: `Cores x Frequency x SIMD width / SIMD throughput`
    * with FMA
      * throughput bound: `2 x Cores x Frequency x SIMD width / SIMD throughput`
  * Instruction Mix
    * processors have limited instruction issue bandwidth
* Load balance & Roofline
  * Computation Imbalance
    * ![image-20191029125946259](D:\OneDrive\Pictures\Typora\image-20191029125946259.png)
    * ![image-20191029125956079](D:\OneDrive\Pictures\Typora\image-20191029125956079.png)
  * Memory Imbalance
    * main memory traffic generated by 1 core is dramatically different than another or when some of the memory controllers are much more heavily loaded than others
    * ![image-20191029130107419](D:\OneDrive\Pictures\Typora\image-20191029130107419.png)
* Interaction with Performance Counters
  * "architecture-oriented" vs. "runtime-oriented" (performance counter)
  * generate ceilings representing how much performance lost due to not exploiting the various architectural features
  * estimate the true limitatons to peak bandwidth
  * determine the true operational intensity
  * ![image-20191029130602748](D:\OneDrive\Pictures\Typora\image-20191029130602748.png)
  * ![image-20191029130619707](D:\OneDrive\Pictures\Typora\image-20191029130619707.png)













Dwarfs

Quantificatons

TPUs

GPU/CUDA

TVM operators





## Motivation

## Summary

## Strength

## Limitation & Solution



