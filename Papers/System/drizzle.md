#    Drizzle: Fast and Adaptable Stream Processing at Scale

  **Shivaram Venkataraman, Aurojit Panda, Ion Stoica**

---



## Introduction

* high throughput, low latency, mission-critical application, 24x7, fault tolerance, adaptive (failures, changes of workloads)
* current framework: 
  * high overhead during adaption (Naiad, Flink)
    * continuous operator streaming model
    * low latency during normal execution
    * recovering from failures is expensive
    * single machine fail → all reset to last checkpoint
  * adapt rapidly at the cost of high latency (Spark Streaming, FlumeJava)
    * micro-batch based system
    * Bulk-Synchronous Processing (BSP) model
    * fault-recovery fast, reuse partial results, parallel recovery
    * barrier across all nodes after every batch
* Drizzle: decouple processing interval from coordination interval (fault-tolerance / adaptability)
  * micro-batch processing model
  * centralized scheduler
    * group scheduling, multiple batches scheduled at once
    * decouple granularity of data processing from scheduling decisions
    * pre-scheduling: proactively queue tasks to be run on worker machines, rely on workers to triggers tasks when their input dependency met
      * [[R: like Sparrow]]
  * query optimization
* adapt with satisfying throughput / latency goals
  * dynamic change nodes on which operators are executed
  * update the execution plan while ensuring consistent results
* processing interval
* coordination interval: fault tolerance, adaptability



## Background



### Desirable Properties of Streaming

* **Case Study: Video Quality Prediction**
  * streaming application computing # of aggregates based on heartbeats from clients → query ML model → optimal parameters (bitrate, CDN location)
  * 100ms deadline → user perceivable degradation
  * recover from failures
  * minimize violation of target latency
  * viewers/heartbeats vary over the course of a day with specific events
* **High Throughput**
* **Low Latency**
  * latency of stream processing syste,: elapse between receiving a new record & producing output accounting for that record
* **Adaptability**
  * live data, long-lived
  * adapt to workload/cluster properties
* **Consistency**
  * application-level semantics / low-level message delivery semantics
  * prefix integrity: every output produced is equivalent to processing a well-specified prefix of the input stream
  * exactly-once-semantics



### Computation Models for Streaming

* **BSP for Streaming Systems**
  * ![image-20191103115635631](D:\OneDrive\Pictures\Typora\image-20191103115635631.png)
  * local computation phase + blocking barrier (communication)
  * DAG of operators, partitioned stages
  * micro-batch of duration T seconds
    * T is lower bound for record processing latency
    * can't adequately small due to barrier implementation
      * communication overhead by barrier
  * barrier simplifies fault-tolerance & scaling
    * scheduler notified at the end of each stage, reschedule if necessary
      * scalable on resources
    * snapshot at the barrrier as fault tolerance
      * physical: output from each task
      * logical: computational dependencies (lineage)
      * failures by snapshots
* **Continuous Operator Streaming**
  * dataflow computation model with long running or continuous operators
  * DAG of operators, placed on a processor as a long running task
  * operators update local state & messages directly transferred from between operators
  * no scheduling / communication overhead with a centralized driver
  * distributed checkpointing algorithms → consistent snapshots periodically
    * flexible, asynchronous/synchronous checkpoints
    * checkpointing replay during recovery can be expensive



### Comparing Computation Models

* ![image-20191103115455509](D:\OneDrive\Pictures\Typora\image-20191103115455509.png)
* BSP: poor latency due to scheduling & communication overheads
* Continuous operators: roll-back to checkpoint



## Design

* Drizzle: based on BSP
* remove overhead in the BSP-based model
  * decouple the size of the micro-batch being processed from the interval at which coordination takes place
  * centralized coordination between micro-batches → group scheduling
  * barrier within a micro-batch → pre-scheduling
* **Group Scheduling**
  * ![image-20191103122946328](D:\OneDrive\Pictures\Typora\image-20191103122946328.png)
  * centralized scheduler: locality, straggler mitigation, fair sharing
  * centralized scheduler computes assignment, task serialized, sent by RPC
  * limitation: restrict to scheduled tasks independent
  * observation
    * streaming processing computation DAG is largely static
  * reusing scheduling decisions across micro-batches
* **Pre-Scheduling Shuffles**
  * ![image-20191103124441077](D:\OneDrive\Pictures\Typora\image-20191103124441077.png)
  * upstream tasks write to disk → notify centralized driver → apply task placement to minimize network overheads → create downstream tasks pull data from upstream tasks
  * pre-schedule downstream tasks before upstream tasks
    * downstreams launch first → upstream scheduled with metadata which machine downstream tasks running on → directly transferred between workers without any centralized coordination
    * scale better avoiding centralized metadata management
    * remove barrier, succeeding stages are launched only when all the tasks in the preceding stage complete
      * [[Q: can't organize all downstream tasks first? bottom-up technique, how to care about fair sharing, load balancing? AKA. at what stage the down-down-down-stream is scheduled?]]
  * local-scheduler each worker managing pre-scheduled tasks
    * inactive, track data dependencies → update list of outstanding dependencies → active → fetch files materialized
    * upstream task finishes → materialize outputs →notify corresponding downstream workers + asynchronously notify centralized worker
    * push-metadata, pull-based approach
    * [[Q: in-memory cache, lineage?]]



### Adaptability in Drizzle

* **Fault tolerance**
  * synchronous checkpoints at regular intervals like BSP
  * at the end of any micro-batch / end of a group of micro-batches presents 1 natural boundary
  * heartbeats from workers, resubmit tasks
  * deterministic task → parallel recovery + intermediate data (lineage tracking)
  * centralized scheduler pre-populate the list of data dependencies for new machine tasks
    * maintained based on asynchronous updates from upstream tasks
  * also update active upstream tasks to send outputs for successing micro-batches to the new machines
  * send/receive failure → notify centralized scheduler
* **Elasticity**
  * node added/removed
  * integrate existing cluster managers (YARN/Mesos)
  * update list of available resources & adjust tasks to be scheduled for the next group
  * larger group size could lead to larger delays in responding to cluster changes



### Automatically selecting group size

* group size that smallest possible while having a fixed bound on coordination overheads
  * large group size, overhead decreasing, adaptability decreasing
  * small group size, overhead increasing, adaptability increasing
* adaptive group-size tuning like TCP congestion control (AIMD)
  * count to track # of time spent in various parts of the system
  * what fraction of the end-to-end execution time was spent in 
    * scheduling other coordination 
    * the worker executing tasks
  * ratio above upper bound → multiplicatively increase the group size ensuring overhead decreases rapidly
  * ratio below lower bound → additively decrease the group size



### Data-plane Optimization

* Workload analysis
  * ![image-20191103131818588](D:\OneDrive\Pictures\Typora\image-20191103131818588.png)
  * stream queries update dashboards requiring aggregation across time
  * aggregation with partial merge operation (sum)
    * merge can be distributed
  * complete aggregation (median)
    * require data to be collected & preprocessed on a single machine
* Optimization within a batch
  * vectorized operations on CPUs
  * minimize network traffic from partial merge operations
* Optimization across batches & queries
  * useful in case the query plan needs to be changed due to changes in the data distribution
  * during every micro-batch, a number of metrics about the execution are collected
  * aggregate at the end of a group → query optimizer
  * micro-batch based architecture enabling reuse of intermediate results across streaming queries



### Discussion

* **Other design approaches**
  * treat existing scheduler in BSP as a black-box, pipeling scheduling of 1 micro-batch with task execution of the previous micro-batch [[C: mapreduce-online?]]
    * $b \times \max(t_{exec}, t_{sched})$ instead of $b \times t_{exec} + t_{sched}$
    * insufficient for larger cluster sizes, where $t_{sched} > t_{exec}$
  * model task scheduling as leases that can be revoked if the centralized scheduler wished to make any changes to the execution plan
    * adjusting lease duration
    * require re-implementing the task-based execution model used by BSP-style systems
* **Improving Pre-Scheduling**
  * reduce # of inputs wait if sufficient semantics information
    * binary-tree reduction, only 2 map tasks
    * inferring communication structure is hard
    * high-level operator `treeReduce`, `broadcast`
* **Quality of Scheduling**
  * coarser scheduling granularity impacts fair sharing, bounded by size of a group
  * pre-scheduling is unaware of size of data produced from upstream tasks
    * data transfer, dynamic rebalancing can't be used
    * apply using previous collected data



### Implementation

* Apache Spark 2.0.0 + 4k lines of Scala code
* Spark improvement
  * existing 2 thread: 1 for compute stage dependencies + locality preferences / 1 for task launching
  * task serialization/launch as bottleneck
  * separate serializing & launching tasks to new thread (multi-thread if multi-stage)
  * optimize locality lookup for pre-scheduled tasks
  * [WIP] amortize the closure serialization across iterations (analysis of the Scala bytecode)
* Spark Streaming
  * `JobGenerator` creating Spark RDD & closure operate on RDD
  * execution timestamp
  * extend `JobGenerator` to submit few RDDs, with continuous timestamp $t, t + k$



## Conclusion & Future Work

* extend Drizzle to other execution engines
* control plane optimizations
* 





## Motivation

* Stream processing engines require low latency and high throughput processing. These engines must handle changes in the cluster (failures, stragglers), workload (various patterns) or incoming data. To handle changes, the systems have to adapt without sacrificing throughput or latency, dynamically change nodes on which operators are executed and update the execution plan while ensuring consistent results. The existing stream processors either focus on providing low-latency during normal operation (Naiad, Flink) but recovering is expensive, or ensuring the adaptation not affecting latency (Spark Streaming, FlumeJava) but imposing a barrier across all nodes resulting high latency.

## Summary

* In this paper, the authors present Drizzle, a fast and adaptable stream processing system. Drizzle is based on existing Bulk Synchronous Processing model, dynamically adjusts its latency and adaptability in a AIMD-fashion group scheduling, and avoids coordination by push-based metadata, pull-based data pre-scheduling shuffles to keep recovery latency low and reduce coordinations in traditional BSP model: centralized coordination between micro-batches and barrier between stages. Apart from control-plane optimizations, Drizzle also applies some data-plane optimizations.

## Strength

* The group scheduling can adaptively adjust the latency and adaptability based on group size for centralized schedulers.
* The pre-scheduling shuffles can remove barriers between BSP computation stages, which reduces many synchronization between workers and centralized schedulers, improving scalability. 

## Limitation & Solution

* The pre-scheduling is a bottom-up technique for building DAGs. However, pre-scheduling is unaware of data sizes, especially how much data reduction is performed, which affecting the worker efficiency.
  * The paper doesn't mention if pre-scheduling can mix with traditional scheduling. Pre-scheduling can speculatively stop at high data reduction stages and re-consider scheduling decisions in a finer-grained fashion.
* The paper doesn't mention if the data between upstreams and downstreams can be cached in memory.
  * Should be feasible to have in-memory cache for pull-based downstream nodes.