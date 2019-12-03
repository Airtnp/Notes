  # Pregel: A System for Large-Scale Graph Processing

**Grzegorz Malewicz, Matthew H. Austern et al.**

---



## Introduction

* programs as sequence if iterations
* vertex: receive messages sent in previous iterations, send message to other vertices, modify own state, mutate graph topology
* existing solutions
* ![image-20191104234842471](D:\OneDrive\Pictures\Typora\image-20191104234842471.png)
* graph algorithms
  * poor locality
  * little work per vertex
  * changing degree of parallelism
* Pregel system
  * BSP model
  * iterators → supersteps (stages?)
  * single vertex `V`
    * read messages sent in superstep `S - 1`
    * send messages received at superstep `S + 1`
    * modify state at `V`
* vertex-centric
  * focus on local action
  * no order within superstep
* synchronicity
  * free of deadlocks, data races



## Model of Computation

* ![image-20191105000810451](D:\OneDrive\Pictures\Typora\image-20191105000810451.png)
* vote to halt: deactivate node itself
  * no future work unless triggered
* ![image-20191105000903763](D:\OneDrive\Pictures\Typora\image-20191105000903763.png)



## The C++ API

* ![image-20191105000939507](D:\OneDrive\Pictures\Typora\image-20191105000939507.png)
* override virtual `Compute`
* user-defined handlers: create missing vertex / remove dangling edges from source vertex
* `Combiner` + `Combine()`: merge messages
* `Aggregator`: vertex provides value in superstep, system combines using a reduction operator, value available in next superstep
  * statistics
  * global coordination
  * sticky aggregator: all supersteps input
* Topology mutation 
  * requests to add/remove vertices/edges
    * global
    * local: self edges, remove self
  * generate conflict requests
    * removal first → edge addition → mutation before `Compute` (partial-order)
    * user-defined handlers
  * lazy coordination: global mutations don't require coordination until applied
* IO: `Reader`/`Writer`



## Implementation

* Execution
  * ![image-20191105002100536](D:\OneDrive\Pictures\Typora\image-20191105002100536.png)
  * ![image-20191105002112747](D:\OneDrive\Pictures\Typora\image-20191105002112747.png)
  * ![image-20191105002122885](D:\OneDrive\Pictures\Typora\image-20191105002122885.png)
  * [[Q: 1 thread per partition? overhead?]]
* Fault tolerance
  * checkpointing on supersteps
  * ping worker failure
  * reassign graph partition
  * confined recovery: log outgoing messages, refined recovery to lost partitions from checkpoints
    * [[Q: lineage? or just missing part count]]
    * ↓latency, ↑overhead (saving messages, but I/O is not bottleneck)
    * deterministic
      * random alg → seeding
* Worker
  * state: vertex ID, current value, outgoing edges (target + value), queue for incoming messages, flag for active (duplicate for different superstep)
  * remote message: buffer / network message
  * local: bypass
* Master
  * assign worker ID, worker status (ID, addr, portion of graph)
  * barriers synchronization (BSP model)
  * statistics
* Aggregator
  * worker values supplied to aggregator → worker single value → reduction tree → master
  * tree-based, not pipeling, parallelize CPU usage



## Applications

* ![image-20191105003212138](D:\OneDrive\Pictures\Typora\image-20191105003212138.png)
* ![image-20191105003222562](D:\OneDrive\Pictures\Typora\image-20191105003222562.png)
* Shortest Path [[C: RIP routing, Distance Vector]]
* PageRank
* Bipartite Matching
* Semi-Clustering
* [[T: read graph algorithm descriptions]]

 

## Conclusion & Future Work

* performance, scalability, fault-tolerance satisfactory
* relax synchronicity model
* spill data to disk if RAM not enough
* dynamic re-partitioning mechanism
* designed for sparse-graph (comm. low, mainly over edge).
* 











## Motivation

* Many practical problems concern about large graphs. Efficient graph processing is challenging since it exhibits poor locality, little work per vertex, changing degree of parallelism during execution. Traditionally, implementing an graph algorithms has options: custom distributed infrastructure; existing ill-suited platform; single-computer graph algorithm library; existing parallel graph system. However these alternatives fail to satisfy fault tolerance, scalability, graph processing pattern computation.

## Summary

* In this paper, the authors present Pregel, which is a graph processing system. Pregel is based on Bulk Synchronization Model, where vertices are graph computations and edges are inherited from graph definitions. The master assigns vertices to nodes and divides computations into supersteps, which act like barriers to synchronize different stages. The fault tolerance is done by checkpointing and potentially refined missing-part-only recovery. Pregel uses simple C++ class APIs and supports some optimizations including combiner, aggregator and vertex states.

## Strength

* Pregel is a simple but powerful framework for handling graph algorithms. It supplies easy-to-use C++ APIs and has nice synchronicity semantics between supersteps. The master-slave architecture and checkpointing are traditional, but it contains special optimizations designed for graph computations.

## Limitation & Solution

* The recovery processes can be accelerate by lineage tracking to avoid re-computations.
* The single master, global mutable state design limits its scalability.
  * De-centralized? Let vertices decide how to start new nodes, re-start?
* The vertices partition are fixed, somehow harms the performance for graph algorithms which dynamically changes degrees of parallelism.
  * dynamically re-partitions, which may involve large synchronization, migration overhead.

