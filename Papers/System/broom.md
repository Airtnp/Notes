# Broom: sweeping out Garbage Collection from Big Data systems

  

**Ionel Gog, Jana Giceva, Michael Isard et al.**

---



## Introduction

* region-based memory management instead of GC
* implicit/explicit graph of stateful data-flow operators executed by worker threads, event-based processing
* ![image-20191107150551400](D:\OneDrive\Pictures\Typora\image-20191107150551400.png)
* ![image-20191107150716957](D:\OneDrive\Pictures\Typora\image-20191107150716957.png)



## Motivation

* Naiad for testing
* Batch processing workflows
* Synchronized iterative workflow



## Case study: Naiad

* ![image-20191107151014907](D:\OneDrive\Pictures\Typora\image-20191107151014907.png)
* ![image-20191107151029836](D:\OneDrive\Pictures\Typora\image-20191107151029836.png)
* ![image-20191107151037174](D:\OneDrive\Pictures\Typora\image-20191107151037174.png)



## Broom: out with the GC?

* ![image-20191107151315796](D:\OneDrive\Pictures\Typora\image-20191107151315796.png)
* Only three regions required for distributed data processing using communicating actors
  * ![image-20191107151346283](D:\OneDrive\Pictures\Typora\image-20191107151346283.png)
  * ![image-20191107151353307](D:\OneDrive\Pictures\Typora\image-20191107151353307.png)
* ![image-20191107151459996](D:\OneDrive\Pictures\Typora\image-20191107151459996.png)
* ![image-20191107152135531](D:\OneDrive\Pictures\Typora\image-20191107152135531.png)
* ![image-20191107152142316](D:\OneDrive\Pictures\Typora\image-20191107152142316.png)



## Discussion

* ![image-20191107152415323](D:\OneDrive\Pictures\Typora\image-20191107152415323.png)
* ![image-20191107152426363](D:\OneDrive\Pictures\Typora\image-20191107152426363.png)
* ![image-20191107152459795](D:\OneDrive\Pictures\Typora\image-20191107152459795.png)
* ![image-20191107152635483](D:\OneDrive\Pictures\Typora\image-20191107152635483.png)
* 

















## Motivation

* Memory-managed languages dominate the landscape of systems for computing with Big Data. Most of the data intensive systems are based on Java Virtual Machine or .NET CLR. Automated memory management improves productivity of system developers and end-users, but stresses the runtime GC by allowing a large number of objects, resulting long GC pauses. Since most systems are based on an implicit or explicit graph of stateful data-flow operators executed by worker threads where the operators perform event-based processing of arriving input data, behave as independent actors, the architecture presents an opportunity to revisit standard memory-management, because: actor explicitly share state via message-passing; state held by actors conssits of many fate-sharing objects with common lifetimes; end-users only supply code fragments to system defined operators.

## Summary

* In this paper, the authors present Broom, a region-based memory manager based on Naiad. Broom observes that region-based memory management works well when similar objects with known lifetimes are handled and the information is available in the distributed data processing systems. Only three types of regions are required: transferable regions for messages extending lifetime and accessing by owner; actor-based regions private to owning actors and living as long as actors; temporary regions for short-lived scratchpad memory blocks which are lexically scoped. Users need to annotate their Naiad operators with region-based memory primitives.

## Strength

* Broom solves memory challenges in data intensive frameworks by revisiting old memory management techinique: region-based memory management. Actually Broom explicitly bounds the lifetime of memory objects in a distributed lifetime fashion.
* Broom can co-exist with local GCs. A local GC can be used for actor-scoped regions.

## Limitation & Solution

* Broom needs users to manually annotate the memory regions (lifetime). And it takes extra efforts to care about memory safety between regions.
  * Add a static analysis phase to automatically generate region annotations and avoid invalid memory accessing (like Rust borrow checker? Not need for NLL though)

