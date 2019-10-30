# Tachyon: Reliable, Memory Speed Storage for Cluster Computing Frameworks  

**Haoyuan Li, Ali Ghodsi, Matei Zaharia, Scott Shenker, Ion Stonica**

---

Now [Alluxio](https://www2.eecs.berkeley.edu/Pubs/TechRpts/2018/EECS-2018-29.pdf )



## Introduction

* Tachyon: distributed file system enabling reliable data sharing at memory speed across cluster computing frameworks
* Write is bounded by replication synchronously
* Bottleneck: push lineage into storage layer (asynchronously)
  * make a long-running lineage-based storage system
  * challenge: timely data recovery
* checkpointing algorithms
* guarantee bounded recovery cost
* resource allocation strategies for recomputation under commonly used resource schedulers.
* I/O bound -> cache data into memory
* write must be fault-tolerant, replicated -> latency of network
* high throughput Tachyon -> lineage
* challenge
  * bounding the recomputation cost for a long-running storage system
    * checkpoint? storage layer is agnostic to the semantics, job execution characteristics can vary widely
    * fixed checkpoint interval can lead to unbounded recovery times if data is written faster than available disk bandwidth
    * Tachyon: continuously checkpointing files asynchronously
      * Edge algorithm for upper bound
  * how to allocate resources for recomputations
    * priorities? don't severely impact the performance of current running jobs with possibly higher priority
    * Tachyon: resource allocation schemes
      * strict priority
      * weighted fair sharing
      * avoid priority inversion by automatically increasing # of resources allocated
* general lineage-specification API



> 为了解释优先级倒置，首先假设现在有三个任务A， B， C（优先级分别是：３,２,１）；他们的优先级关系是：Ａ ＜Ｂ＜Ｃ并且Ａ和Ｃ需要访问共享资源。　
>
> ​    优先级倒置：当一个优先级任务通过同步机制（入mutex）访问共享资源时，如果该mutex已被一个低优先级任务（任务Ａ）占用（lock）,而这个低优先级任务正在访问共享资源时（unlock 互斥体之前）可能又被其他一些中等优先级的任务（任务Ｂ）抢先了（即任务Ｂ现在正在运行）．而如果此时，任务Ｃ（优先级比任务Ｂ高）除了需要的共享资源外运行任务Ｃ的条件都满足了（即现在任务Ｃ需要运行，但是被任务Ｂ阻塞了）。这样系统的实时性得不到保证，这就是优先级倒置问题。
>
> 　　产生原因：不同优先级线程对共享资源的访问的同步机制。优先级为１和３的线程Ｃ和线程Ａ需要访问共享资源，优先级为２的线程Ｂ不访问该共享资源。当Ａ正在访问共享资源时，Ｃ等待互斥体，但是此时Ａ被Ｂ抢先了，导致Ｂ运行Ｃ阻塞。即优先级低的线程Ｂ运行，优先级高的Ｃ被阻塞。
>
> 
>
> 　　解决方法：
>
> 　    方法1：将程序代码进行适当的组织安排，避免优先级倒置的发生（确保互斥体不被处于不同优先级的线程所共享）。
>
> ​    方法2：优先级置顶协议（priority ceiling protocol）:占有互斥体的线程在运行时的优先级比任何其他可以回去该互斥体的线程的优先级都要高。使用优先级置顶协议时，每个互斥体都被分配一个优先级，该优先级通常与所有可以拥有该互斥体的线程中的最高优先级相对应。当优先级较低的线程占有互斥体后，该线程的优先级被提升到该互斥体的优先级。
>
> ​    方法3：优先级继承协议（Priority  Inheritance Protocol）:将占有互斥体的线程优先级提升到所有正在等待该互斥体的线程优先级的最高值。



## Background

* Target workload properties
  * Immutable data (append-only)
  * Deterministic jobs: no-side-effect computations
  * Locality based scheduling: read can be data-local
  * All data vs. working set: working sets fit in memory
  * Program size vs. data size: replicating programs is much less expensive than replicating data in many cases
* Against replication
  * ![image-20191023131158176](D:\OneDrive\Pictures\Typora\image-20191023131158176.png)
  * fault-tolerant
  * inter-job data sharing cost often dominates pipeline's end-to-end latencies



## Design Overview

* ![image-20191023131313231](D:\OneDrive\Pictures\Typora\image-20191023131313231.png)
* Two layer: lineage & persistence
* Lineage layer
  * high throughput I/O
  * trace sequence of jobs with creating particular data output
* Persistent layer
  * persist data on storage without lineage concept
  * asynchronous checkpoints
* master-slave architecture
* workflow manager: within master
  * track lineage information
  * computing checkpoint order
  * interact with cluster manager to allocate resources for recomputation
* job P: input A → output B, lineage L → Tachyon
  * lineage L persistent
  * only single copy of B to memory without compromising fault-tolerance
* Recomputation
  * deterministic execution
  * immutable input
* Avoid replication, but client-side caching
  * [[Q: asynchronously replication?]]
* API summary: append-on file system
  * ![image-20191024130408480](D:\OneDrive\Pictures\Typora\image-20191024130408480.png)
* Lineage overhead
  * negligible
  * can garbage collect lineages (after checkpointing)
* Data eviction
  * Access Frequency: file access often follows a Zipf-like distribution
  * Access Temporal Locality: 75% of the re-access take place within 6 hours
  * Use LRU as default
  * Plugging in other eviction policies
* Master Fault-Tolerance
  * passive standby
  * master logs synchronously to the persistent layer
  * master election
  * recover from persistent logs
* Handling Environment Changes
  * checkpointing as a bound
  * switching system into synchronous mode
    * all currently unreplicated files are checkpointed
    * all new data is saved synchronously
  * OS version change
  * dependency version change
* Why Storage Layer
  * push lineage into storage layer
  * a data professing pipeline contains 1+ jobs
    * capture lineage across jobs
    * data producers/consumers written in different frameworks
    * lineage at job level or single framework can't solve this issue [[R: Spark]]
  * only storage layer knows when files are renamed/deleted
    * track lineage/checkpoint data in long-term operations
    * other layers don't have full control
    * user can manually delete a file



## Checkpointing

* asynchronously checkpoint in the background without stalling writes
* Bounded Recomputation Time
  * lineage can be long
* Checkpointing hot files
  * some files are more popular
  * dimension/scheme tables
* Avoid Checkpointing Temporary Files
* Edge Algorithm
  1. checkpoint the edge (leaves) of the lineage graph
     * file DAGs
     * satisfy bounded recovery time
     * ![image-20191024161754823](D:\OneDrive\Pictures\Typora\image-20191024161754823.png)
  2. incorporate priorities, favoring checkpointing high-priority files
     * LFU policy
     * frequently accessed files are checkpointed first
     * balance between leaves & hot files
       * Zipf-distributed workloads
       * high priority? access count higher than 2
  3. cache datasets that can fit in memory to avoid synchronous checkpointing
     * heavy-tailed input size
     * bursty behavior of frameworks
     * eviction of uncheckpointed files are rare
* Bounded Recovery Time
  * any file can be recovered in $3M$, where $M = \max_i\{T_i\}, T_i = \max(W_i, G_i)$
    * $W_i$: time for checkpointing a edge $i$
    * $G_i$: time to generating a edge $i$
    * independent of the depth of the DAG
    * ![image-20191024165805017](D:\OneDrive\Pictures\Typora\image-20191024165805017.png)
    * ![image-20191024165445193](D:\OneDrive\Pictures\Typora\image-20191024165445193.png)
  * [[Q: don't understand this...]]



## Resource Allocation

* recomputation resources
* statically partition? bad
* Priority Compatibility: follow priority of original jobs
  * Priority Based Scheduler
    * priority inheritance/donation
    * ![image-20191024202652087](D:\OneDrive\Pictures\Typora\image-20191024202652087.png)
  * Fair Sharing Based Scheduler
    * ![image-20191024205912628](D:\OneDrive\Pictures\Typora\image-20191024205912628.png)
    * all lost files are recomputed by jobs with a equal share under $W_R$ : $R_i$
    * when job requesting lost data, part of the requesting job's share is moved to the recomputation job. $aW_i + R_i$
* Resource sharing: no static partition
* Avoid cascading recomputation: must consider data dependencies
  * workflow manager: logical DAG for each file
  * DFS search



## Implementation

* Lineage Metadata
  * Ordered input file list (unique immutable file ID)
  * Ordered output file list
  * Binary program for recomputation
    * framework-implemented wrapper
  * Program configuration
    * byte array, leave program wrapper to understand
  * Dependency type
    * wide: do operations where each output file requiring multiple input files
    * narrow: do operations where each output file requiring 1 input file



## Limitations

* Random Access Abstractions
  * high-level read-only random-acess abstractions
* Mutable data
* Multi-tenancy
* Hierarchical storage
  * NVRAM, SSD
* Checkpoint Algorithm Optimizations
  * checkpoint cost
  * single file recovery cost
  * all file recovery cost







## Motivation

* Traditional distributed file systems bound the framework throughput by writing replications to persistent layers. The synchronous replication harms the performance of job pipelines where one job consumes the output of another. It's hard to do pipelining across jobs and between different producer/consumer frameworks.

## Summary

* In this paper, the authors present Tachyon, which is a memory-centric distributed file system speeding up cluster computing frameworks. Tachyon avoids file replication by asynchronously persisting job lineages and recomputing under failures. Tachyon presents Edge checkpointing algorithm which satisfying bounded recomputation time, considering priorities and handling bursty behavior of frameworks. Tachyon also handles priority-based resource allocation for dependency-related recomputations.

## Strength

* Tachyon avoids the output replication cost and relieves the write bound, then improves the end-to-end latency of workflow.
* Tachyon takes advantage of lineage and checkpointing with priority-based scheduling and checkpointing to bound recovery time smoothly.

## Limitation & Solution

* Tachyon has no traditional file system API provided, not a common file system like HDFS
  * Add APIs to Tachyon (like bypassing accessing to underlying persistent layer and combining lineage layer)
* Tachyon could take advantage of NVRAMs, SSDs for speeding up larger writings.
  * Lineage based file system upon NVRAMs (Intel Optane).

