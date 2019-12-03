# X-Stream: Edge-centric Graph Processing using Streaming Partition  

**Amitabha Roy, Ivo Mihailovic, Willy Zwaenepoel**

---



## Introduction

* X-Stream: in-memory / out-of-core graphs on a single shared-memory machine
* scatter-gather model
* edge-centric
* streaming completely unordered edge lists
  * sequential bandwidth > random access bandwidth
* scalable under cores, I/O devices, storage media
* no sort edge lists during preprocessing
* ![image-20191105183920273](D:\OneDrive\Pictures\Typora\image-20191105183920273.png)
* ![image-20191105184512467](D:\OneDrive\Pictures\Typora\image-20191105184512467.png)
* state in vertices
* computation structured as a loop, scatter - gather
* ![image-20191105185637226](D:\OneDrive\Pictures\Typora\image-20191105185637226.png)
* ![image-20191105185646691](D:\OneDrive\Pictures\Typora\image-20191105185646691.png)



## The X-Stream Processing Model

* Streams
  * input stream: iterator
  * output stream: append
  * ![image-20191105190952458](D:\OneDrive\Pictures\Typora\image-20191105190952458.png)
* Streaming Partitions
  * vertex set + edge list + update list
  * ![image-20191105191044274](D:\OneDrive\Pictures\Typora\image-20191105191044274.png)
  * vertex set partitioned
* Scatter-Gather with Partitions
  * ![image-20191105191131243](D:\OneDrive\Pictures\Typora\image-20191105191131243.png)
* Size & # of Partitions
  * ![image-20191105191439612](D:\OneDrive\Pictures\Typora\image-20191105191439612.png)
* API Limitation
  * no way to iterate edges / updates belong to a vertex
  * can iterate all vertices



## Out-of-core Streaming Engine

* how to reach sequential access in shuffle phase?
* ![image-20191105192255710](D:\OneDrive\Pictures\Typora\image-20191105192255710.png)
* In-memory data structures
  * edges during scatter & updates during gather phase & i/o of shuffle phase
  * statically sized, statically allocated _stream buffer_
    * array of bytes (chunk array) + index array with K entries for K streaming partitions
    * ![image-20191105192435818](D:\OneDrive\Pictures\Typora\image-20191105192435818.png)
  * 1 streaming buffer for storing updates from scatter
  * 1 streaming buffer for result of in-memory shuffle
* Operation
  * ![image-20191105192610659](D:\OneDrive\Pictures\Typora\image-20191105192610659.png)
  * optimizations
    * ![image-20191105192639786](D:\OneDrive\Pictures\Typora\image-20191105192639786.png)
* Disk I/O
  * asynchronous direct I/O to/from stream buffer, bypass OS page cache
  * actively prefetch
  * ![image-20191105192802562](D:\OneDrive\Pictures\Typora\image-20191105192802562.png)
  * ![image-20191105192812658](D:\OneDrive\Pictures\Typora\image-20191105192812658.png)
* \# of Partitions
  * ![image-20191105194315564](D:\OneDrive\Pictures\Typora\image-20191105194315564.png)
  * ![image-20191105194331914](D:\OneDrive\Pictures\Typora\image-20191105194331914.png)



## In-memory Streaming Engine

* consider CPU cache for partitioning
* 1 stream buffer for edges of the graph
* 1 stream buffer for updates
* 1 stream buffer for shuffling
* Parallel Scatter-Gather
  * ![image-20191105195609282](D:\OneDrive\Pictures\Typora\image-20191105195609282.png)
  * thread private buffer -> flushed to shared -> atomic reserving + appending
  * workload imbalance? work stealing
* Parallel Multistage Shuffler
  * hardware stride prefetcher
  * spatial locality by sequential accessing
  * ![image-20191105200149713](D:\OneDrive\Pictures\Typora\image-20191105200149713.png)
  * ![image-20191105200202843](D:\OneDrive\Pictures\Typora\image-20191105200202843.png)
  * assign X-Stream threads disjoint equally sized slices of the stream buffer
  * [[I: CUDA accelerated graph computation?]]
* Layering over Disk Streaming
  * ![image-20191105200508585](D:\OneDrive\Pictures\Typora\image-20191105200508585.png)
  * [[Q: what does this mean??]]

















## Motivation

* Analytics over large graphs poses an system challenge on the lack of access locality and scale up. The intuitive approach is sorting the edges of the graph by originating vertices and building indexes over the sorted edge list. These methods is vertex-centric and involves random access through the edge indexes. This reveals a tradeoff between a small number of random accesses to locate edges connected to active vertices and streaming a large number of potentially unrelated edges and picking up connected ones. Random access to any storage medium delivers less bandwidth than sequential access.

## Summary

* In this paper, the authors present X-Stream, which is a edge-centric graph processing framework. X-Stream takes full advantage of the sequential bandwidth of disks by providing edge-centric processing and APIs. The user-defined scatter (send message) and gather (update) functions are applied through the edges connected to some vertices. The updates sent by scatter and shuffled in a sequential accessing-friendly way. X-Scale provides both in-memory and out-of-core engines for sufficent memory and disk-based mode. X-Stream is able to scale up and performs many types of graph algorithms.

## Strength

* The edge-centric semantics of X-Stream takes full advantage of sequential bandwidth. X-Stream notifies the tradeoff between small number of random accessing indexes and large number of sequential filtered accessing edges.
* X-Stream explicitly cares about the disk-based computation and in-memory computations.

## Limitation & Solution

* X-Stream's edge-centric APIs can't provide ways to iterate the edges or updates of given vertices, which limits its application on some graph algorithms.
* The relation between in-memory and out-of-core engine is vague. They employs different paradigms of scattering, shuffling, and gathering. How to choose them? How to combine them?
  * Can the system dynamically change the engines to use.
* Does X-Stream support evolving graphs?
  * How to modify the stream partitions and edge relationships?

