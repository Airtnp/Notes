# GraphChi: Large-Scale Graph Computation on Just a PC

  

**Aapo Kyrola, Guy Blelloch, Carlos Guestrin**

---



## Introduction

* disk-based system graph computation
* graph to small parts
* parallel sliding windows method (PSW)
  * asynchronous
* advanced graph computation in personal computer
* continuously evolving graph
* GraphChi
* ![image-20191105160046626](D:\OneDrive\Pictures\Typora\image-20191105160046626.png)



## Disk-based Graph Computation

* directed sparse graph
* ![image-20191105161131685](D:\OneDrive\Pictures\Typora\image-20191105161131685.png)
* PSW
  * asynchronous model
  * dynamic selective scheduling
* ![image-20191105161244612](D:\OneDrive\Pictures\Typora\image-20191105161244612.png)
* CSR: in-edge inefficient
* CSC format (CSR for transpose?)
* Random access problem
* Alternative solutions
  * SSD as a memory extension: read/write equal, rendering caching inefficient
  * Exploting locality: reduce random disk access, but real-world graph limited locality, skewed vertex degree
  * Graph compressions: 4 bits/edge, associate data take more space
  * BSP: can't efficiently perform asynchronous computation



## Parallel Sliding Windows

* ![image-20191105161734629](D:\OneDrive\Pictures\Typora\image-20191105161734629.png)
* ![image-20191105161934932](D:\OneDrive\Pictures\Typora\image-20191105161934932.png)
* load a subgraph from disk
  * ![image-20191105162311740](D:\OneDrive\Pictures\Typora\image-20191105162311740.png)
  * disjoint intervals, associate a shard storing all edges have dest in the interval
  * ![image-20191105162656036](D:\OneDrive\Pictures\Typora\image-20191105162656036.png)
  * ![image-20191105162710243](D:\OneDrive\Pictures\Typora\image-20191105162710243.png)
  * [[N: good placement of datas, like clustered database pages...]]
* update vertices & edges
  * parallel update → race condition
  * external determinism: each execution produces exactly same result
    * vertices have edges with both end-points in the same interval flagged as critical, sequential update, (can observe precede changes)
    * can abandon consistency
* write updated value to disk
  * memory-shard completely rewritten
  * active sliding window of each sliding shard is rewritten
  * [[N: mainly for sparse graph..]]
* ![image-20191105163128437](D:\OneDrive\Pictures\Typora\image-20191105163128437.png)
* ![image-20191105163139708](D:\OneDrive\Pictures\Typora\image-20191105163139708.png)
* Evolving graphs
  * allow adding edges by simplified version of I/O efficient buffer trees
  * ![image-20191105163243340](D:\OneDrive\Pictures\Typora\image-20191105163243340.png)
  * ![image-20191105163249756](D:\OneDrive\Pictures\Typora\image-20191105163249756.png)
  * ![image-20191105163342964](D:\OneDrive\Pictures\Typora\image-20191105163342964.png)
  * support removal (flagged edge & ignored & removed when written to disk)
  * visible only after execution interval ended
* I/O Cost
  * cost of an alg = # of blocks transfer from disk to main memory
  * ![image-20191105163505750](D:\OneDrive\Pictures\Typora\image-20191105163505750.png)
  * ![image-20191105163602733](D:\OneDrive\Pictures\Typora\image-20191105163602733.png)
* Remarks
  * not efficiently support dynamic ordering (priority-like)
  * graph traversal not efficient (loading neighborhood of a single vertex requires scanning a complete memory-shard)
    * [[Q: why? we always need in-/out-edges in our UDFs]]
  * didn't utilize full RAM (can pin shard to memory)



## System Design & Implementation

* Shard data format
  * ![image-20191105164747382](D:\OneDrive\Pictures\Typora\image-20191105164747382.png)
* Preprocessing
  * Sharder: creating shards from standard graph file formats
  * ![image-20191105164812756](D:\OneDrive\Pictures\Typora\image-20191105164812756.png)
  * ![image-20191105164822155](D:\OneDrive\Pictures\Typora\image-20191105164822155.png)
* ![image-20191105165141268](D:\OneDrive\Pictures\Typora\image-20191105165141268.png)
* Execution
  * degree file, eliminate dynamic allocation
  * use prefix-sum of degrees to allocate prior fixed arrays
  * ![image-20191105165022651](D:\OneDrive\Pictures\Typora\image-20191105165022651.png)
    * [[Q: like columnar?]]
  * ![image-20191105165038724](D:\OneDrive\Pictures\Typora\image-20191105165038724.png)
* Sub-intervals: balance edges
* ![image-20191105165303525](D:\OneDrive\Pictures\Typora\image-20191105165303525.png)
* Selective scheduling
  * ![image-20191105165404428](D:\OneDrive\Pictures\Typora\image-20191105165404428.png)
  * schedule as bit array



## Programming Model

* ![image-20191105165510195](D:\OneDrive\Pictures\Typora\image-20191105165510195.png)
* ![image-20191105165520115](D:\OneDrive\Pictures\Typora\image-20191105165520115.png)
* ![image-20191105165527723](D:\OneDrive\Pictures\Typora\image-20191105165527723.png)
* ![image-20191105165539244](D:\OneDrive\Pictures\Typora\image-20191105165539244.png)
* ![image-20191105165614853](D:\OneDrive\Pictures\Typora\image-20191105165614853.png)



## Applications

* [[T: read definitions]]
* SpMV, PageRank
* Graph Mining
* Collaborative Filtering
* Probabilistic Graphical Model





## Motivation

* Current systems for graph computation require a distributed compute cluster to handle large real-world problems. Large graphs, which may have billions of edges, if all put into memory, would require distributed memory or hundreds of gigabytes of DRAM on high-end servers. Would it be possible to do advanced graph computation on just a personal computer? Known that processing large graphs efficiently from disk is a hard problem and generic solutions not perform well.

## Summary

* In this paper, the authors present GraphChi, which is a disk-based asynchronous graph computation framework. GraphChi is based on Parallel Sliding Window (PSW) to separate vertices to intervals and in-/out- edges into shards. Due to the sorted characteristics inside the sharded edge data, the I/O cost is reduced and only part of the graph data is processed in memory per execution interval. GraphChi can support evolving graphs, selective scheduling with vertices masks and in-memory vertices model.

## Strength

* GraphChi uses PSW, which is a good solution for graph processing under limited memory. PSW significantly reduces the amount of data required in memory and keeps the I/O cost low.
* GraphChi's asynchronous execution model alleviates the overhead in synchronization and strong consistency model.

## Limitation & Solution

* Since GraphChi and PSW mainly focus on edge data processing, it's mainly suitable to sparse graphs, not dense graphs.
* GraphChi is not suitable for graph traversal works.
  * Inherit natures of edge-centric framework.
  * Vertex-centric framework might be better.
* GraphChi may not dynamically utilize the available memory efficiently.
  * Use pinned memory.
  * Dynamically re-partition the intervals and edge shards?

