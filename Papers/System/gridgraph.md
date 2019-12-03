# GridGraph: Large-Scale Graph Processing on a Single Machine Using 2-Level Hierarchical Partitioning  

**Xiaowei Zhu, Wentao Han, and Wenguang Chen**

---



## Introduction

* GridGraph: large-scale graphs on a single machine
* graphs → 1-D partitioned vertex chunks + 2-D partitioned edge blocks
* 1st fine-grained level partitioning in preprocessing
* 2nd coarse-grained level partitioning applied in runtime
* dual sliding window method
* ![image-20191106000527481](D:\OneDrive\Pictures\Typora\image-20191106000527481.png)



## Graph Representation

* ![image-20191106105049681](D:\OneDrive\Pictures\Typora\image-20191106105049681.png)
* ![image-20191106105527946](D:\OneDrive\Pictures\Typora\image-20191106105527946.png)
* ![image-20191106105537848](D:\OneDrive\Pictures\Typora\image-20191106105537848.png)
* ![image-20191106105559008](D:\OneDrive\Pictures\Typora\image-20191106105559008.png)
* ![image-20191106105605480](D:\OneDrive\Pictures\Typora\image-20191106105605480.png)
* power-law edge block size distribution
  * extra merge phase
* no-sort edge blocks
* good for selective scheduling
* ![image-20191106111710887](D:\OneDrive\Pictures\Typora\image-20191106111710887.png)



## The Streaming-Apply Processing Model

* stream-apply processing model
  * 1 read-only pass over edges
  * 1 write pass over vertices
* ![image-20191106111843983](D:\OneDrive\Pictures\Typora\image-20191106111843983.png)
* ![image-20191106111853255](D:\OneDrive\Pictures\Typora\image-20191106111853255.png)
* ![image-20191106112319840](D:\OneDrive\Pictures\Typora\image-20191106112319840.png)
* ![image-20191106113902424](D:\OneDrive\Pictures\Typora\image-20191106113902424.png)
* Dual sliding window
  * ![image-20191106112835575](D:\OneDrive\Pictures\Typora\image-20191106112835575.png)
  * col-oriented
  * ![image-20191106113919441](D:\OneDrive\Pictures\Typora\image-20191106113919441.png)
  * [[T: the critism for GraphChi & X-Stream is this section is strange..]]
* 2-Level Hierarchical Partitioning
  * ![image-20191106114021799](D:\OneDrive\Pictures\Typora\image-20191106114021799.png)
  * ![image-20191106114519304](D:\OneDrive\Pictures\Typora\image-20191106114519304.png)
  * [[Q: where is the benefit explanation??]]
* Execution Implementation
  * ![image-20191106114545016](D:\OneDrive\Pictures\Typora\image-20191106114545016.png)
* 

















## Motivation

* Large-scale graph processing has attracted interests in both academic and industrial communities. There are some distributed graph processing systems where load imbalance due to graph nature, synchronization overhead due to BSP, fault tolerance overhead are still problems. Out-of-core shared-memory processing is an alternative solutions. However, the existing frameworks have problems in efficiency: sorting shards (GraphChi)  and large amount of updates (X-Stream).

## Summary

* In this paper, the authors present GridGraph, which is a fast stream-apply graph processing model. GridGraph splits graphs into vertices chunks and edges grid blocks. In execution, GridGraph also virtually splits edge blocks into second level grids. The 2-level hierarchical partitioning further reduces the amount of I/O. GridGraph provides two interfaces, one for vertices streaming and one for edges streaming.

## Strength

* GridGraph's grid representations, 2-level hierarchical partition, and vertice/edges streaming interface reduces the amount of I/O cost and doesn't need sorting the edges.
* GridGraph offers selective scheduling for eliminating unnecessary streaming data.

## Limitation & Solution

* The description for 2-level hierarchical partition is vague. How does it reduce amount of I/O operations?
* GridGraph has no support for evolving graphs.
* GridGraph can't do a sub-graph computation since it only provides interfaces for all vertices/edges streaming.
  * Workaround is selective scheduling.
    * But the paper mentions little about that. (Refer the ATC slides)
  * Limited the stream-apply processing and grid accessing model.

