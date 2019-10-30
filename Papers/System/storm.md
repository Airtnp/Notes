# Storm @Twitter  

**Ankit Toshniwal, Siddarth Taneja, Amit Shukla et al.**

---



## Introduction

* Storm: real-time fault-tolerant distributed **stream** data processing system
  * Scalable: add/remove machines without disrupt existing data flows through Storm topologies
  * Resilient: fault-tolerance
  * Extensible: call arbitrary external functions, needing a framework
  * Efficient: good performance characteristic
  * Easy to Administer: early warning, diagnosis tools
* open-source Storm at 2011
* Replaced by Heron at 2014
* This paper acts as a lament (



## Data Model & Execution Architecture

* streams of tuples flowing through topologies
* _topology_: directed graph, vertex computation, edge data flow.
* Vertex types
  * spout: tuple sources, pull data from queue
  * bolt: process incoming tuples, pass to bolt downstream
* ![image-20191025105224355](D:\OneDrive\Pictures\Typora\image-20191025105224355.png)
* ![image-20191025152019286](D:\OneDrive\Pictures\Typora\image-20191025152019286.png)
* _Nimbus_: master node, distributing, coordinating execution
  * Apache Thrift service, topology as Thrift objects
  * Summingbird: general stream processing abstraction
    * separate logica lplanner for variety of stream processing & batch processing systems
    * types, relationships between data processing
  * Summingbird → Storm topologies
  * user code as JAR
  * local disk + Zookeeper
  * fail-fast, stateless
* _worker nodes_: execution, run 1+ worker processes
  * worker process: JVM with 1+ executors
    * worker receive thread
    * worker send thread
  * tasks: (intra-bolt/intra-spout) parallelism, for 1 bolt/spout
  * executor: intra-topology parallelism, 1+ tasks
    * user logic thread
      * in queue
    * executor send thread
      * out queue
      * global transfer queue
  * Supervisor: communicate with Nimbus
    * periodic haertbeat event (per 15sec)
      * main thread
      * topology, vacancy
    * Zookeeper
    * fail-fast, stateless
    * synchronize supervisor event (per 10secs)
      * event manager thread
      * changing in assignments
    * synchronize process event (per 3secs)
      * process event manager thread
      * managing worker processes that run a fragment of the topology on the same node as the supervisor
      * valid/timed out/not started/disallowed
* partition
  * Shuffle: randomly partitions the tuples
  * Fields: hashes on a subset of the tuple attributes/fields
  * All: replicate the entire stream to all the consumer tasks
  * Global: send the entire stream to a single bolt
  * Local: send tuple to consumer bolt in the same executor
  * ![image-20191025105726606](D:\OneDrive\Pictures\Typora\image-20191025105726606.png)
* semantics
  * at least once: each tuple that is input to the topology will be processed at least once
    * acker bolt tacking DAG of tuples for each tuple emitted by a spout
    * ![image-20191025153553601](D:\OneDrive\Pictures\Typora\image-20191025153553601.png)
    * tuple id + provenance tree
    * backflow mechanism to retire the tuple
      * lineage for each tuple? large memory usage
      * bitwise XORs: acker bolt keeps track of all the tuples and XOR checksum until zero
        * failure → timeout
  * at most once: each tuple is either processed once, or dopped in the case of a failure
    * data source holding a tuple with timeout



## Storm@Twitter

* visualization
  * augmented metric bolt
  * system metric
    * CPU, network, GC, memory
  * topology metrix
    * tuples emitted/acks/fail/latency
* how to use Zookeeper
  * [[T: some experience of Zookeeper]]



## Future work

* exact-once semantics
* visualization tools
* integration with Hadoop
* declarative query paradigm





[Storm Limitatons]( https://blog.csdn.net/wzhg0508/article/details/46349323)

[Heron after Storm]( https://blog.csdn.net/wzhg0508/article/details/46380157)

[Twitter Heron: Stream Processing at Scale - Morning paper](https://blog.acolyer.org/2015/06/15/twitter-heron-stream-processing-at-scale/)



1. Multiple levels of scheduling and their complex interaction leads to uncertainty about when tasks are being scheduled.
2. Each worker runs a mix of tasks, making it difficult to reason about the behaviour and performance of a particular task, since it is not possible to isolate its resource usage.
3. Logs from multiple tasks are written into a single file making it hard to identify errors and exceptions associated with a particular task, and causes tasks that log verbosely to swamp the logs of other tasks.
4. An unhandled exception in a single task takes down the whole worker process killing other (perfectly fine) tasks.
5. Storm assumes that every worker is homogeneous, which results in inefficient utilization of allocated resources, and often results in over-provisioning.
6. Because of the large amount of memory allocated to workers, use of common profiling tools becomes very cumbersome. Dumps take so long that the heartbeats are missed and the supervisor kills the process (preventing the dump from completing).
7. Re-architecting Storm to run one task per-worker would led to big inefficiencies in resource usage and limit the degree of parallelism achieved.
8. Each tuple has to pass through *four* (count ’em) threads in the worker process from the point of entry to the point of exit. This design leads to significant overhead and contention issues.
9. Nimbus is functionally overloaded and becomes an operational bottleneck.
10. Storm workers belonging to different topologies but running on the same machine can interfere with each other, which leads to untraceable performance issues. Thus Twitter had to run production Storm topologies in isolation on dedicated machines. Which of course leads to wasted resources.
11. Nimbus is a single point of failure. When it fails, you can’t submit any new topologies or kill existing ones. Nor can any topology that undergoes failures be detected and recovered.
12. There is no backpressure mechanism. This can result in unbounded tuple drops with little visibility into the situation when acknowledgements are disabled. Work done by upstream components can be lost, and in extreme scenarios the topology can fail to make any progress while consuming all resources.
13. A tuple failure anywhere in the tuple tree leads to failure of the whole tuple tree.
14. Topologies using a large amount of RAM for a worker encounter gc cycles greater than a minute.
15. There can be a lot of contention at the transfer queues, especially when a worker runs several executors.
16. To mitigate some of these performance risks, Twitter often had to over provision the allocated resources. And they really do mean *over* provision – one of their topologies used 600 cores at an average 20-30% utilization. From the analysis, one would have expected the topology to require only 150 cores.









## Motivation

* Stream processing is quickly becoming a crucial component of a comprehensive data processing solution for enterprises. The real-time data management tasks are critical for providing services.

## Summary

* In this paper, the authors present Storm at Twitter, a real-time fault-tolerant distributed stream data processing systems. The stream work is modeled as topologies (DAGs) with vertices as computations and edges as data flow. The Storm cluster are separated into three layers, Nimbus (master node), supervisors and worker nodes, and persistent layer with Zookeeper. Storm is able to provide at least once and at most once semantics by manipulating the topologies.

## Strength

* Storm provides rich visualization tools for administors to diagnoize events.
* Storm architecture is simple and scalable.

## Limitation & Solution

* Nimbus is a single point of failure (availability) and limitation on scalability of Storm.
  * At least using Zookeeper for master election.
* Nimbus scheduler is not mentioned in this paper.
* Zookeeper replication writes limit the thoughput of the system.
  * Use lineage-based Tachyon-like file system?
* Storm has no backpressure mechanism, the downstream congestion may cause cascading failing affecting performance.
  * [Twitter Heron: Stream Processing at Scale](https://dl.acm.org/citation.cfm?id=2742788)

