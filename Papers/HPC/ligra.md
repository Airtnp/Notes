# Ligra: A Lightweight Graph Processing Framework for Shared Memory  

**Julian Shun, Guy E. Blelloch**

---



## Introduction

* shared-memory multicore graph algorithms are efficient
* Ligra: lightweight interface for graph alg (graph traversal)
* race condition (atomic CAS)
* ![image-20191105133818463](D:\OneDrive\Pictures\Typora\image-20191105133818463.png)
* data types: graph with V, E  / subsets of V
* `vertexMap`, `edgeMap`
* ![image-20191105135143704](D:\OneDrive\Pictures\Typora\image-20191105135143704.png)



## Preliminaries

* ![image-20191105142114195](D:\OneDrive\Pictures\Typora\image-20191105142114195.png)



## Framework

* ![image-20191105142136262](D:\OneDrive\Pictures\Typora\image-20191105142136262.png)
* ![image-20191105142641391](D:\OneDrive\Pictures\Typora\image-20191105142641391.png)
* optimization
  * `edgeMapSparse`: two `F` for fast-fail for first-arg & complete (2 args)
  * remove-duplicate stage bypassed if no duplicate
  * no break `edgeMapDense`: parallel
  * ![image-20191105143013223](D:\OneDrive\Pictures\Typora\image-20191105143013223.png)
    * PageRank, B-F shortest paths



## Applications

* BFS
* betweenness centrality
  * [[T: definition]]
  * ![image-20191105143101342](D:\OneDrive\Pictures\Typora\image-20191105143101342.png)
* Graph Radii Estimation, Multiple BFS
  * [[T: definition]]
  * ![image-20191105143129757](D:\OneDrive\Pictures\Typora\image-20191105143129757.png)
* Connected Components
  * ![image-20191105143146877](D:\OneDrive\Pictures\Typora\image-20191105143146877.png)
* PageRank
  * ![image-20191105143159765](D:\OneDrive\Pictures\Typora\image-20191105143159765.png)
* Bellman-Ford Shortest Paths
  * ![image-20191105143215628](D:\OneDrive\Pictures\Typora\image-20191105143215628.png)

















## Motivation

* A modern single multicore server can support most of the graph computation. And graph algorithms perform better in shared-memory multicores machines (per core, per dollar, per joule) than distributed memory systems.

## Summary

* In this paper, the authors present Ligra, which is a shared-memory lightweight graph processing framework, especially for graph traversing algorithms. It provides two datatypes: graph `(V, E)` and `vertexSubset`, along with two interface `edgeMap` and `vertexMap`. With these two abstractions, Ligra is able to present a large set of graph algorithms and take advantage of shared-memory parallelism efficiently. It automatically deals with sparse and dense graphs based on number of vertices and out-degrees.

## Strength

* Ligra is able to provide a large set of graph algorithms, especially graph traversal, in some simple interfaces. It take advantages of the loop-parallelism efficiently.

## Limitation & Solution

* Ligra's interface is limited, thus the original graph algorithms might need to be re-designed to satisfy the Ligra's interface.
* Ligra's graph representation is vertices and edges, which might be unsuitable for matrix-based (CSR, ELL, ...) graph computations.
  * Like graph neural networks?
* Ligra's synchronization is based on compare-and-swap, which may cause large number of cache invalidations and large memory bus overhead, especially for NUMA systems.
  * Care about memory locality?

