# Conference List

[TOC]

---



[[S: Content]]

- S = C: Check, random or related insights
- S = I: Idea, random ideas or project thoughts
- S = N: Note, some notes
- S = T: Todo, literally
- S = R: Refer, cross reference
- S = Q: Question, some questions, might be collected at the end





## What appears in every paper

* CAP (Consistency/Availability/Partition Tolerance)
* ACID (Atomicity/Consistency/Isolation/Durability)
* Data Model
  * data types
* Programming Model
  * language model
* Storage
  * file system
* Share
  * Share nothing
  * Share-Disk/Memory
* Locality
  * Temporal: Cache
  * Spatial: Machine/Rack/Cluster/Datacenter
  * Push filter down
  * Push computation down (in-chip computation)
* Pipeline (break dependency)
  * Out-of-Order design
* Communication
  * Shared address space
  * Message passing
* Scalability
  * utilization ratio
  * dataset sharing
  * randomization
  * batching work
  * reuse cached data
  * push predicates down (filter)
* Scheduling
  * Thread pool
  * Real time
* Resource allocation
  * Memory Management
    * Cache/ObjectTable Eviction Policy
  * Resource Management
    * Monolithic, Two-level, Shared-state, Decentralized
* Fault Tolerance
  * Persistent storage
  * Checkpoint (E.g. database)
  * Recomputing/Immutable
    * Lineage (E.g. Spark)
  * Error recovery
  * Soft / Hard state
    * reconstruction among slaves/components
* Availability/Replication
  * Sync/Async update
  * Master/Slave
    * shadow master
  * Leader/Coordinator/Participants Cluster
* Consistency
  * Consensus: Paxos/Raft/BPFT
  * Single master
  * Order
    * Physical lock
    * Logical lock
    * Timestamp
    * Version number
* Identifier
  * Global timestamp
  * UUID
  * URI + DNS (virtual IP)
* Computation
  * Sequential
  * Parallel
  * Graph computing (mostly DAG)
* Expressiveness
  * Functional programming
* Event-driven vs. Message driven
* Synchronous vs. Asynchronous
* Blocking vs. Non-blocking
* Mutable vs. Immutable
* Latency vs Throughput
  * Data-parallel
* Distributed system
  * Consensus: Paxos/Raft/BPFT
* Heterogeneous system
* Abstraction Layer
  * transparency
  * illusion of model, hiding complexity (E.g. C++ machine)
  * Control plane vs Data plane
  * lift -> inter-job, inter-procedural
  * unlift -> fine-grained
* Coarse/Fine-grained
* Cloud
  * multi-tenancy













## Arch

### ASPLOS (April)



### HPCA (Feb.)



### ISCA (June)



### MICRO (Oct.)



### FAST (Feb.)



---

## System

### OSDI/SOSP (Oct.)

* [OSDI'08-KLEE: Unassisted and Automatic Generation of High-Coverage Tests for Complex Systems Programs](./Security/symbolic_execution.md)
* [SOSP'15-Failure Sketching: A Technique for Automated  Root Cause Diagnosis of In-Production Failures](./Security/symbolic_execution.md)
* [SOSP'17-Lazy Diagnosis of In-Production Concurrency Bugs](./Security/symbolic_execution.md)
* [SOSP'03-The Google File System](./System/gfs.md)
* [OSDI'06-Bigtable: A Distributed Storage System for Structured Data](./System/bigtable.md)
* [OSDI'12-Spanner: Google's Globally-Distributed Database](./System/spanner.md)
* [SOSP'11-Windows Azure Storage: A Highly Available Cloud Storage Service with Strong Consistency](./System/azure.md)
* [OSDI'04-MapReduce: Simplified Data Processing on Large Clusters](./System/mapreduce.md)
* [SOSP'09-Distributed Aggregation for Data-Parallel Computing: Interfaces and Implementations](./System/distributed_aggregation.md)
* [OSDI'08-DryadLINQ: A System for General-Purpose Distributed Data-Parallel Computing Using a High-Level Language](./System/dryadlinq.md)
* [OSDI'08-Improving MapReduce Performance in Heterogeneous Environments](./System/late.md)
* [SOSP'13-Sparrow: Distributed, Low Latency Scheduling](./System/sparrow.md)
* [SOSP'13-Naiad: A Timely Dataflow System](./System/naiad.md)



### HotOS (May)



### USENIX ATC (July)

* Slides: [ATC'19](https://www.usenix.org/conference/atc19/technical-sessions)



### EuroSys (May)

* [EuroSys'07-Dryad: Distributed Data-Parallel Programs from Sequential Building Blocks](./System/dryad.md)
* [EuroSys'15-Large-scale cluster management at Google with Borg](./System/borg.md)
* 



### Linux Kernel (Aug.)



---

## Distributed/Parallel/HPC

### ICDCS (July)



### HPDC (June)



### ICS (June)



### PPoPP (Feb.)



### ICPP (Aug.)



### HotCloud (July)

* [HotCloud'10-Spark: Cluster Computing with Working Sets](./System/spark.md)



### PACT (Sept.)



### TACO (Trans.)



---

## Security

### SP/Oakland (May)



### CCS (Oct.)



### USENIX Security (Aug.)



### NDSS (Feb.)



---

## PL

### POPL (Jan.)



### PLDI (June)

* [PLDI'10-FlumeJava: Easy, Efficient Data-Parallel Pipelines](./System/flumejava.md)



### ECOOP (July)



### CGO (Feb.)



### CC (Feb.)



### OOPSLA/PACMPL (Nov.)



### ICFP (Sept.)



### ICSE (May)



---

## Database

### SIGMOD/PODS (July)

* [SIGMOD'07-Map-Reduce-Merge: simplified relational data processing on large clusters](./System/mapreduce_merge.md)
* [SIGMOD'15-Spark SQL: Relational Data Processing in Spark](./System/spark_sql.md)
* [SIGMOD'14-Storm@Twitter](./System/storm.md)



### VLDB (Aug.)

* [VLDB'09-Hive - A Warehousing Solution Over a Map-Reduce Framework](./System/hive.md)
* [VLDB'08-SCOPE: Easy and Efficient Parallel Processing of Massive Data Sets ](./System/scope.md)
* [VLDB'14-Trill: A High-Performance Incremental Query Processor for Diverse Analytics](./System/trill.md)



### ICDE (April)

* [ICDE'15-Apache Flink™: Stream and Batch Processing in a Single Engine](./System/flink.md)



---

## Network

### NSDI (Feb.)

* [NSDI'12-Resilient Distributed Datasets: A Fault-Tolerant Abstraction for In-Memory Cluster Computing](https://www.usenix.org/system/files/conference/nsdi12/nsdi12-final138.pdf)
* [NSDI'10-MapReduce Online](./System/mapreduce_online.md)
* [NSDI'11-Mesos: A Platform for Fine-Grained Resource Sharing in the Data Center](./System/mesos.md)



### SIGCOMM (Aug.)



### DSN (June)



### WWW (May)



---

## TCS

### STOC (June)



### FOCS (Oct.)





## Others

### ACCU (Nov.)

* [ACCU2017](https://github.com/Airtnp/ACppLib/tree/master/notes/ACCU 2017)

* [ACCU2019](../Miscs/ACCU2019.md)



### CppNow (May)

* [CppNow2017](https://github.com/Airtnp/ACppLib/tree/master/notes/CppNow 2017)

* [CppNow2018](../Miscs/CppNow2018.md)
* [CppNow2019](../Miscs/CppNow2019.md)



### CppCon (Sept.)

* [CppCon2017](https://github.com/Airtnp/ACppLib/blob/master/notes/CppCon 2017/Notes.md)
* [CppCon2018](../Miscs/CppCon2018.md)
* [CppCon2019](../Miscs/CppCon2019.md)



### ItCppCon (June) & CppDay (Nov.)





### RustConf (Aug.)



### LambdaConf (June)

* [LambdaConf2018](../Miscs/LambdaConf2018.md)



### RECon (June / Feb.)



### EuroLLVM (April)

* [homepage](http://llvm.org/devmtg/)



### USLLVM (Oct.)

- [homepage](http://llvm.org/devmtg/)



### Papers We Love Conf (Sept.)

* [homepage](https://pwlconf.org/)





### DeepSpec summer school (July)



### Oregon PL summer school (June)



### Programming Language Implementation summer school (May)



### PetaScale Tools Workshop (July)

* [homepage'2019](https://dyninst.github.io/scalable_tools_workshop/petascale2019/)



### Curry-On (July)



### TVMConf (Dec.)



### HoTT Summer School (Aug.)



### Linux Plumbers Conference (Sept.)



### GPU Technology Conference (March)





## Miscs

* [MSST'10-The Hadoop Distributed File System](./System/the_hadoop_distributed_file_system.md)
* [SoCC'13-Apache Hadoop YARN: Yet Another Resource Negotiator](./System/yarn.md)
* [SoCC'14-Tachyon: Reliable, Memory Speed Storage for Cluster Computing Frameworks](./System/tachyon.md)
* [NetDB'11-Kafka: a Distributed Messaging System for Log Processing](./System/kafka.md)
* [CACM'08-Roofline: An Insightful Visual Performance Model for Floating-Point Programs and Multicore Architectures](./HPC/roofline.md)





## Calendar

|                   | Jan. | Feb.        | March | April    | May               | June                             | July                                   | Aug.                 | Sept.                        | Oct.      | Nov.   | Dec.    |
| ----------------- | ---- | ----------- | ----- | -------- | ----------------- | -------------------------------- | -------------------------------------- | -------------------- | ---------------------------- | --------- | ------ | ------- |
| Arch              |      | HPCA        |       | ASPLOS   |                   | ISCA                             |                                        |                      |                              | MICRO     |        |         |
| System            |      | FAST        |       |          | HotOS EuroSys     |                                  | USENIX ATC                             | Linux Commit         |                              | OSDI/SOSP |        |         |
| Dist/Parallel/HPC |      | PPoPP       |       |          |                   | HPDC<br />ICS                    | ICDCS HotCloud                         | ICPP                 | PACT                         |           |        |         |
| Security          |      | NDSS        |       |          | S&P               |                                  |                                        | USENIX Security      |                              | CCS       |        |         |
| PL                | POPL | CGO<br />CC |       |          | ICSE              | PLDI                             | ECOOP                                  |                      | ICFP                         |           | OOPSLA |         |
| Database          |      |             |       | ICDE     |                   |                                  | SIGMOD                                 | VLDB                 |                              |           |        |         |
| Network           |      | NSDI        |       |          | WWW               | DSN                              |                                        | SIGCOMM              |                              |           |        |         |
| TCS               |      |             |       |          |                   | STOC                             |                                        |                      |                              | FOCS      |        |         |
| Others            |      | RECon       | GTC   | EuroLLVM | CppNow<br />PLISS | LambdaConf<br />OPLSS<br />RECon | DSSS<br />CASS<br />PSTW<br />Curry-On | RustConf<br />HoTTSS | CppCon<br />LPC<br />PWLConf | USLLVM    | ACCU   | TVMConf |

