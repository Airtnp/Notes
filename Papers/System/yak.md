# Yak: A High-Performance Big-Data-Friendly Garbage Collector  

**Khanh Nguyen, Lu Fang, Guoqing Xu, Shan Lu et al.**

---



## Introduction

* big data friendly GC
* high throughput, low latency for all JVM-based languages
* control space | data space
* lifetime aligns with epochs
* ![image-20191107161559039](D:\OneDrive\Pictures\Typora\image-20191107161559039.png)
* ![image-20191107161800136](D:\OneDrive\Pictures\Typora\image-20191107161800136.png)
* ![image-20191107161818301](D:\OneDrive\Pictures\Typora\image-20191107161818301.png)
* two path: control path / data path
* two hypothesis: generational hypothesis vs. epochal hypothesis
* ![image-20191107162009896](D:\OneDrive\Pictures\Typora\image-20191107162009896.png)
* ![image-20191107162024183](D:\OneDrive\Pictures\Typora\image-20191107162024183.png)
* region-based GC => static analysis, manual refactoring
* Yak GC: hybrid GC splitting heap into a control space (CS) & a data space (DS).
  * ![image-20191107162717557](D:\OneDrive\Pictures\Typora\image-20191107162717557.png)
  * ![image-20191107162753467](D:\OneDrive\Pictures\Typora\image-20191107162753467.png)
  * automated & systematic solution, zero code refactoring
    * ![image-20191107162831753](D:\OneDrive\Pictures\Typora\image-20191107162831753.png)
  * ![image-20191107162840965](D:\OneDrive\Pictures\Typora\image-20191107162840965.png)
  * co-existing GCs
  * correctly managing DS region
  * efficiently managing DS region



## Motivation

* ![image-20191107163244819](D:\OneDrive\Pictures\Typora\image-20191107163244819.png)



## Design Overview

* When to Create & Deallocate DS Regions?
  * region created (deallocated) in the DS whenever an epoch starts (ends).
  * region holds all objects created inside the epoch.
  * epoch: execution of a block of data transformation code
  * `epoch_start` / `epoch_end`: user annotations
  * ![image-20191107171005333](D:\OneDrive\Pictures\Typora\image-20191107171005333.png)
  * nested regions
    * ![image-20191107171103381](D:\OneDrive\Pictures\Typora\image-20191107171103381.png)
  * create multi-threaded shared region
    * 1 region for each dynamic instance of an epoch
    * get own regions without synchronization
      * [[Q: COW?]]
  * Semilattice structure for multiple epochs & regions
    * ![image-20191107171243855](D:\OneDrive\Pictures\Typora\image-20191107171243855.png)
* How to Deallocate Regions Correctly & Efficiently?
  * outlived objects
  * identifying escaping objects
    * ![image-20191107173822406](D:\OneDrive\Pictures\Typora\image-20191107173822406.png)
  * deciding the relocation destination for these objects
    * ![image-20191107173831552](D:\OneDrive\Pictures\Typora\image-20191107173831552.png)
    * ![image-20191107173844136](D:\OneDrive\Pictures\Typora\image-20191107173844136.png)

## Yak Design & Implementation

* JVM, JIT compiler (C1, Opto), interpreter, object/heap layout, Parallel Scavenge collector (CS)



### Region & Object Allocation

* Region Allocation
  * ![image-20191107174125391](D:\OneDrive\Pictures\Typora\image-20191107174125391.png)
* Heap Layout
  * ![image-20191107174138367](D:\OneDrive\Pictures\Typora\image-20191107174138367.png)
  * ![image-20191107174212761](D:\OneDrive\Pictures\Typora\image-20191107174212761.png)
* Allocating Objects in the DS
  * ![image-20191107174224672](D:\OneDrive\Pictures\Typora\image-20191107174224672.png)
  * young generation (Eden) => `Region_Alloc`



### Tracking Inter-region References

* 4-byte field `re` into the header space of each object to record the region information of the object
* modify the write barrier to detect & record heap-based inter-region/space references
  * ![image-20191107174417438](D:\OneDrive\Pictures\Typora\image-20191107174417438.png)
* detect & record local-stack-based inter-region references & remote-stack-based references when `epoch_end` triggered.
  * ![image-20191107174501744](D:\OneDrive\Pictures\Typora\image-20191107174501744.png)
* places of references to an escaping object reside in
  * in the heap
    * ![image-20191107174557520](D:\OneDrive\Pictures\Typora\image-20191107174557520.png)
  * on the local stack
    * ![image-20191107174814815](D:\OneDrive\Pictures\Typora\image-20191107174814815.png)
    * ![image-20191107174823567](D:\OneDrive\Pictures\Typora\image-20191107174823567.png)
  * On the remote stack
    * ![image-20191107174905729](D:\OneDrive\Pictures\Typora\image-20191107174905729.png)
    * ![image-20191107174956095](D:\OneDrive\Pictures\Typora\image-20191107174956095.png)
    * dangerous object moving
      * ![image-20191107175008647](D:\OneDrive\Pictures\Typora\image-20191107175008647.png)
      * ![image-20191107175024823](D:\OneDrive\Pictures\Typora\image-20191107175024823.png)
    * dangerous object deallocation
      * ![image-20191107175035159](D:\OneDrive\Pictures\Typora\image-20191107175035159.png)
  * ![image-20191107175050199](D:\OneDrive\Pictures\Typora\image-20191107175050199.png)



### Region Deallocation

* ![image-20191107175123767](D:\OneDrive\Pictures\Typora\image-20191107175123767.png)
* Finding escaping roots
  * pointees of inter-region/space references recorded in the remember set of `r`
  * object referenced by the local stack of the deallocating thread `t`
    * captured by write barrier
  * object referenced by the remote stacks of other threads
  * ![image-20191107175247615](D:\OneDrive\Pictures\Typora\image-20191107175247615.png)
* Closure computation
  * ![image-20191107175302335](D:\OneDrive\Pictures\Typora\image-20191107175302335.png)
  * ![image-20191107175318335](D:\OneDrive\Pictures\Typora\image-20191107175318335.png)
  * ![image-20191107175324576](D:\OneDrive\Pictures\Typora\image-20191107175324576.png)
* Identifying Target Regions
  * ![image-20191107175341896](D:\OneDrive\Pictures\Typora\image-20191107175341896.png)
  * ![image-20191107175350184](D:\OneDrive\Pictures\Typora\image-20191107175350184.png)
  * ![image-20191107175358375](D:\OneDrive\Pictures\Typora\image-20191107175358375.png)
* Updating Remember Sets & Moving Objects
  * ![image-20191107175418000](D:\OneDrive\Pictures\Typora\image-20191107175418000.png)
  * ![image-20191107175426984](D:\OneDrive\Pictures\Typora\image-20191107175426984.png)
* Collecting the CS
  * ![image-20191107175445057](D:\OneDrive\Pictures\Typora\image-20191107175445057.png)















## Motivation

* Manage languages come at a cost: memory management in Big Data systems is often prohibitively expensive. The massive-volume of objects created by Big Data systems at run time contributes to slow GC execution. The data path of Big Data frameworks mismatches with the state-of-the-art GCs by violating generational hypothesis but conforming to epochal hypothesis. However, the region-base techniques based on epochal hypothesis will need either sophisticated static analyses (not scalable) or heavy manual refactoring.

## Summary

* In this paper, the authors present Yak, a big data friendly garbage collector for JVM-based languages. Yak separates the control space and data space and employs the epochal hypothesis. Developers are required to mark the beginning and end points of each epoch in the program. Each epoch creates a data space region and due to nested relationship, the regions form a semilattice structure. In order to correctly and efficiently deallocate regions, Yak uses an efficient algorithm to track cross-region/space references and records all incoming references to identify escaping objects, and computes least upper bound on the region semilattice to decide the relocation destinations for these objects. Yak splits heap to control space controlled by generational GC and data space containing regions. Yak adds a remember set to control space to keep escaping object information. The inter-region references are captured by the write barrier in JVM and `epoch_end` stack scanning (with pausing threads). At region deallocation, Yak will compute the closure of escaping objects from escaping roots from remember sets by BFS, identify target regions of moved objects by topological sort, update remember sets and moving objects by recalculating reference relationships.

## Strength

* Yak is able to provide epoch-based, big data friendly garbage collection automatically with minimal changing of code.
* Yak is able to solve nested epochs and inter-region references cleverly and thoroughly by changing JVM, GC, JIT source codes, which requires impressively hard work.

## Limitation & Solution

* Yak still needs programmers to write `epoch_start`/`epoch_end` primitives.
  * For each framework, the primitives might be encoded into programming model with normal operators.
* Yak deallocations will pause the entire JVM (lightweight stop-the-world), including other threads.
  * Force inter-region object to be pinned in JVM?
* Will the stack scanning be incremental? Can we cache the results?

