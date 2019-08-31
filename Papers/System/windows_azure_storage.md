# Windows Azure Storage: A Highly Available Cloud Storage Service with Strong Consistency
[link](https://www.sigops.org/s/conferences/sosp/2011/current/2011-Cascais/11-calder-online.pdf)



## Intro

* Windows Azure Storage (WAS)
* Storage forms
  * Blob (user files): incoming & outgoing data shipping
  * Tables (structured storage): intermediate service state & final results
  * Queue (message delivery): overall workflow for processing Blobs
* Strong consistency
  * conditional r/w/d for optimistic concurrency control
  * provide CAP (strong consistency, high availability, partition tolerance)
* Global & Scalable namespace/storage
  * global namespace
* Disaster recovery
  * natural disaster
* Multi-tenancy & Cost of storage



## Global Partitioned Namespace

* http(s)://**AccountName**.<service>.core.windows.net/**PartitionName**/**ObjectName**
* **AccountName**
  * account name for accessing storage, part of DNS host name
  * locate primary storage cluster & data center
* **PartitionName**
  * request in storage cluster
* **ObjectName**
  * identify individual objects
  * atomic transaction between objects with the same **PartitonName**
* Data abstractions
  * Blob -> `PartitionName`
  * Table -> each row 1 primary key -> (`PartitionName`, `ObjectName`)
    * group by same partition
  * Queue -> (`PartitonName` + `ObjectName` per message)



## High Level Architecture



### Windows Azure Cloud Platform

* Windows Azure Fabric Controller
  * resource provisioning & management layer
  * resource allocation
  * deployment/upgrade
  * management for cloud service
  * For WAS
    * node management
    * network configuration
    * health monitoring
    * starting/stopping of service instances
    * service deployment
    * network topology
    * physical layout of clusters
    * hardware configuration of storage nodes
* WAS
  * manage the replication & data placement
  * load balancing data & application traffic



### WAS Architecture Components

* ![1566293909076](D:\OneDrive\Pictures\Typora\1566293909076.png)
* **Storage Stamps**
  * a cluster of N racks of storage nodes, where each rack is built out as a separate fault domain with redundant networking & power
  * provisioned storage in production, ~70%
    * disk short stroking -> better seek time + higher throughput y utilizing outer tracks
    * continue providing storage capacity & availability in presence of a rack failure within a stamp
* **Location Service** (LS)
  * manage all storage stamps
  * manage account namespace across stamps
    * allocate accounts to storage stamps
    * manage accounts for storage stamps for disaster recovery & load balancing
  * distributed across 2 geographic locations
  * register virtual IP -> DNS



### Three Layers within a Storage Stamp

* **Stream Layer**
  * store bits on disk
  * in charge of distributing & replicating data across many servers -> durability
  * distributed file system layer
* **Partition Layer**
  * managing high level data abstractions (Blob/Table/Queue)
  * providing a scalable object namespace
  * providing transaction ordering & strong consistency
  * storing object data on the top of the stream layer
  * cache object data to reduce disk I/O
  * partitioning data objects within a stamp to achieve scalability
* **Front-End (FE) Layer**
  * a set of stateless servers taking incoming requests
  * lookup `AccountName` -> authenticate + authorize -> route to partition server in Partition Layer (`PartitionName`)
  * Partition Map: `PartitionName` ranges -> partition server
  * cache data
  * bypass Partition Layer (directly -> Stream Layer)



### Two Replication Engines

* **Intra-Stamp Replication** (stream layer)
  * synchronous replication: all the data written into a stamp is kept durable within that stamp.
  * keep enough replicas across different nodes in different fault domains
  * critical path of customer's write requests
  * focusing on replicating blocks of disk storage
  * durabilty against hardware failures
  * low-latency
  * single storage stamp, in memory meta-state, enabling WAS to provide fast replication with strong consistency by quickly committing transactions within a single stamp
* **Inter-Stamp Replication** (partition layer)
  * asynchronous replication: replicating data across stamps
  * background, off critical path of customer's write requests
  * keeping a copy of an account's data in two locations for disaster recovery
  * migrating an account's data between stamps
  * focusing on replicating objects & transactions applied
  * durability agianst geo-redundancy of geo-disasters
  * acceptable levle of replication delay
  * across data centers, location service controls & understand global object namespace across stamps



## Stream Layer

* ![1566722326295](D:\OneDrive\Pictures\Typora\1566722326295.png)
* internal interface used only by partition layer
* append-only file system like namespace & API (open, close, delete, rename, read, append to, concatenate)
* **Stream**: ordered list of extent pointers
  * name in hierarchical namespace, like a big file
  * maintained by stream manager
* **Extent**: a sequence of append blocks
  * unit of replication in the stream layer
  * default replication policy: 3 replicas within a storage stamp for an extent
  * NTFS file
  * 1GB target size
* **Block**: minimum unit of data for writing & reading
  * data is appended as one or more concatenated blocks to an extent, not have ot be same size
  * checksum validation at block level, 1 checksum per block, check per read



### Stream Manager & Extent Nodes

* ![1566733631664](D:\OneDrive\Pictures\Typora\1566733631664.png)
* **Storage Manager (SM)**
  * keep track of the stream namespace, extent arrangement in each stream, extent allocation across the Extent Nodes (EN).
  * standard Paxos cluster
  * off the critical path of client requests
  * maintaining the stream namespac eand state of all active streams and extents
  * monitoring the headlth of the ENs
  * creating & assigning extents to ENs
  * performing the lazy re-replication of extent replicas lost due to hardware failure or unavailability
  * garbage collecting extents that are no longer pointed by any stream
  * scheduling the erasure coding of extent data according to stream policy
  * periodically poll (sync) the state of ENs and extents
    * replicated few than expected -> re-prelication lazilly
    * randomly choose EN across different fault domains
  * in-memory state
  * only care about stream & extent
* **Extent Nodes (EN)**
  * maintain the storage for a set of extent replicas assigned to it by the SM
  * N disks attached, control for storing extent replicas & blocks
  * only care about extent & block
  * Map[extent offset + blocks, file location]
  * cache about extents & peer replica locations



### Append Operation & Sealed Extent

* atomic append -> duplicate records
* single atomic "multi-block append"
* metadata & commit log duplicate -> sequence number
* row data & blob data stream duplicate -> only last write will be pointed to by the `RangePartition`, the rest will be GCed.
* sealed extent: immutable, can do optimizations by stream layer (size > target size at a block boundary)



### Stream Layer Intra-Stamp Replication

* strong consistency guarantee
  * Once a record is appended and acknowledged back to the client, any later reads of that record from any replica will see the same data (the data is immutable) 
  * Once an extent is sealed, any reads from any sealed replica will always see the same contents of the extent 
* malicious adversaries -> data center / Fabric Controller / WAS



#### Replication Flow

* create a stream -> SM assigns 3 replicas for the first extent (1 primary + 2 secondary) to 3 extent nodes
* write: client -> primary EN (active-passive) -> secondary ENs
* allocate/seal -> send location to client (cached)
* read -> any replicas
* primary EN
  * determining the offset of the append in the extent
  * ordering (choose the offset of) all of the appends if there are concurrent append requests to the same extent outstanding
  * sending the append with its chosen offset to 2 secondary extent nodes
  * only returning success for the append to the client after a successful append has occurred to disk for all 3 ENs
  * labelled in with number in previous graph
* replica failure -> client contact SM -> seal extent at commit length -> allocate new extent with replicas -> back to client



#### Sealing

* while sealing, choose the smallest commit length (for append failure)
* force synchronize to given extent to the chosen commit for a reconnected EN



#### Interaction with Partition Layer

* Read records at known locations: read at (extent + offset, length)
  * row/blob data stream
  * only read streams using location info returned from a previous successful append (which means all 3 replicas success)
* Iterate all records sequentially in a stream on partition load
  * metadata/commit log
  * happens on partition load
  * send "check for commit length" to primary EN of the last extent of these stream for whether all the replicas are available and they all have the same length



#### Erasure Coding Sealed Extent

* erasure codes sealed extents for Blob storage
* extent -> N roughly equal sized fragments at block boundary -> M error correcting fragments using Reed-Solomon
  * [分布式系统下的纠删码技术](https://blog.csdn.net/u011026968/article/details/52295666)
  * [Reed-Solomon纠删码简析](https://blog.mythsman.com/post/5d2fe60e976abc05b345448d/)
  * [Erasure-Code原理](https://blog.csdn.net/BtB5e6Nsu1g511Eg5XEg/article/details/82321298)
* reduce cost of storing, from 3x -> 1.3/1.5x



#### Read Load-Balancing

* read deadline value: read should not be attempted if it cannot be fulfilled within the deadline
* select a different EN to read from
* read not serviced due to heavily loaded spindle to the data fragment -> faster read by reconstruction from erasure code -> issued to all fragments of an erasure coded extent -> first N response used to reconstruction to desired fragment



#### Spindle Anti-Starvation

* avoid scheduling new IO to a spindle when there is over 100ms of expected pending IO already shceduled but not serviced for over 200ms
* achieve fairness across r/w (through slightly increase overall latency on some sequential requests)



#### Durability & Journaling

* durability contract: when data is acknowledged as written by the stream layer, at least 3 durable copies of the data stored in the system
* optimization: reserve a whole disk drive or SSD as a journal drive for all writes into the extent node on each extent node.
  * avoid append-read contend
  * consistent & low latency append
* journal drive: solely for writing a single sequential journal of data
  * reaching full write throughput potential
* append -> write to primary || send requests to secondary -> write all the data for the append to journal drive || queue up the append to go to the data disk -> return succeed (either one)
* journal succeed first?
  * data buffered in memory, any read for that data served from memory
  * better scheduling of concurrent writes
  * batching contiguous write



## Partition Layer

* Store & Understand Blob/Table/Queue
* data model for different types of objects stored
* logic & semantics to process different types of objects
* massively scalable namespace for objects
* load balancing to access objects across the available partition servers
* transaction ordering & strong consistency for accessing to the objects



### Partition Layer Data Model

* `Object Table (OT)`: a massive table which can grow to several petabytes
  * dynamically broken up into `RangePartitions` (based on traffic load to the table)
  * Account Table: stores metadata & configuration for each storage account assigned to the stamp
  * Blob Table: stores all blob objects for all accounts in the stamp
  * - primary key: `(AccountName, PartitionName, ObjectName)`
  * Entity Table: stores all entity rows for all accounts in the stamp (for Windows Azure Table)
    * primary key: `(AccountName, PartitionName, ObjectName)`
  * Message Table: stores all message for all accounts' queues in the stamp
  * - primary key: `(AccountName, PartitionName, ObjectName)`
  * Schema Table: keep track of the schema for all OTs
  * Partition Map Table: keep track of the current `RangePartition`s for all OTs and which partition server is serving each `RangePartition` (for Front-End servers)
* `RangePartition`: contiguous range of rows in an OT from a given low-key to a high-key
  * for a given OT, non-overlapping, every row is represented in some `RangePartition`



### Supported Data Types & Operations

* property types for an OT's schema
  * standard simple types: bool, binary, string, DateTime, double, GUID, int32, int64 
  * special types: DictionaryType, Blob Type
  * DictionaryType: flexible properties to be added to a row at any time
    * `(name, type, value)`
    * flexible properties -> first-order properties
  * BlobType: store large amounts of data (only used by Blob Table)
    * data bits stored in a separate blob data stream & a pointer to the blob's data bits (list of (extent + offset, length))
* operations
  * standard: insert, update, delete, query/get
  * batch transactions acros rows with the same `PartitionName`
  * snapshot isolation read



### Partition Layer Architecture

* ![1567072503959](D:\OneDrive\Pictures\Typora\1567072503959.png)
* **Partition Manager (PM)**
  * responsible for keeping track of and splitting the massive Object Table into `RangePartition`s
  * each `RangePartition` -> 1 active PS
  * each stamp multiple PM, contend for a leader lock stored in LS. PM with lease is the active PM
* **Partition Servers (PS)**
  * responsible for serving requests to a set of `RangePartition` assigned to it by the PM
  * store all the persistent state of the partitions into streams
  * maintain a memory cache of the partition state for efficiency
  * no 2 PS can serve same RP by using lease with LS
  * can serve multiple RP from different OTs concurrently
* **Lock Service (LS)**
  * Paxos lock service used for leader election for the PM
  * PS maintain a lease with the lock service in order to serve partitions
  * similar to Chubby Lock
* PS failure -> N RP assigned by PM to available PSs -> update Partition Map Table



### RangePartition Data Structure

* ![1567096260940](D:\OneDrive\Pictures\Typora\1567096260940.png)
* Log-Structured Merge-Tree



#### Persistent Data Structure

* **Metadata Stream**: root stream for RP
  * PM -> PS by providing RP's metadata stream
  * name of commit log stream, data stream for that RP
  * pointer (extent + offset) into those streams
  * PS write metadata stream the status of outstanding split & merge operation
* **Commit Log Stream**: commit log to store recent insert/update/delete since last checkpoint
* **Row Data Stream**: stores the checkpoint row data & index for RP
* **Blob Data Stream**: only used by the Blob Table to store the blob data bits



#### In-Memory Data Structures

* **Memory Table**: in-memory version of the commit log
* **Index Cache**: checkpoint indexes of row data stream
* **Row Data Cache**: memory cache of checkpoint row data pages. read-only
* **Bloom Filters**: search index/checkpoint in the data stream. For each checkpoints.
* SImilar to BigTable



#### Data Flow

* write request to RP -> PS -> append into the commit log -> put newly changed row into memory table -> return to FE servers
* memory table / commit log reaches threshold size -> write into a checkpoint in row data stream
* periodically combine checkpoints, remove old by GC
* Blob data bits -> commit log, but not memory table -> BlobType property for the row tracks the location of the Blob data bits -> on checkpoint concatenate to Blob data stream (fast concatenation provided by stream layer, adding pointer to extents)
* load partition -> read metadata stream to locate active set of checkpoints & replaying transactions in commit log -> rebuild in-memory state



#### RangePartition Load Balancing

* PM spread load across PS, control total # of partitions in a stamp
* **Load Balance**: identify when a given PS has too much traffic and reassigns 1+ RP to less loaded PS
  * PM -> offload command -> PS -> checkpoint -> PM -> reassign RP to PS, update Partition Map Table -> new PS reload
* **Split**: identify when a single RP has too much load and split RP into 2+ smaller & disjoint RP, reassign to 2+ PS
  * PM -> split -> PS choose key `(AccountName, PartitionName)` -> checkpoint
  * split based on size: keep track of total size
  * split based on load: Adaptive Range Profiling
  * use a special stream opeation "MultiModify"
  * take the RP's each stream (metadata, commit log, data). stop serving
  * create new sets of stream for 2+ RPs with the same extents in the same order. PS append new partition key ranges to 2+ RPs metadata stream
  * start serving to 2+ new RP for disjoint `PartitionName`
  * notify PM of completion -> PM update PMT & metadata -> reassign
* **Merge**: merge together cold or lightly loaded RP together form a contiguous key range within their OT
  * merge (C, D) -> E
    * PM move (C, D) to served by same PS
    * PM -> merge -> PS
    * PS checkpoint for C, D, stop serving
    * use MultiModify to create new commit log & data stream for E (concatenation of extents)
    * PS construct metadata stream for E
      * name of new commit log & data stream
      * combined key range
      * pointer for start & end of the commit log
      * root of data index
    * start serving
    * PM update PMT & meatadata
* low watermark, high watermark
* track RP info in heartbeats from PS to PM
  * transactions / second
  * average pending transaction count
  * throttling rate
  * CPU usage
  * network usage
  * request latency
  * data size of the RP



#### Partition Layer Inter-Stamp Replication

* primary stamp P: AccountName via DNS to a single location & storage stamp
* secondary stamp S: assigned by Location Service
* geo-replicate
  * LS choose a stamp each location, register AccountName with both stamp
  * P take live traffic, S take only inter-stamp replication traffic from P
  * LS update DNS to have hostname `AccountName.service.core.windows.net` point to P's VIP
  * write to P will be replicated using intra-stamp replication at stream layer
  * after committed in P, partition layer in P will asynchronously geo-replicate changes to S using inter-stamp replication
  * S apply and replicate using intra-stamp replication
* migration: clean failover
* disaster recovery: abrupt failover
* LS make an active secondary stamp for the account the new primary and switch DNS to point to the S's VIP



## Application Throughput

* Statistics



## Workload Profiles

* Statistics



## Design Choices & Lessons Learned

* Scaling Computation Separate from Storage
* Range Partitions vs. Hashing
  * easier performance isolation vs simplicity of distribution (lose locality)
  * for sequential access, range partition might be bad, extra hashing of client needed
* Throttling/Isolation
  * PS keep track of request rate of AccountName & PartitionName
  * Sample-Hold algorithm of top N busiest AN/PN
  * well-behaving testing with statistical method
* Automatic Load Balancing
  * high avialability in multi-tenancy environment/traffic spikes
  * every N seconds, PM sort all RP based on each of the split triggers. Go through each, looking at detailed statistics, pick small number to split
  * PM sort all of the PSs based on each of the load balancing metrics, choose heavily loaded & recent splitted, offload reassign
  * load balancing algorithm can be dynamically swapped out via configuration updates
* Separate Log Files per RangePartition
  * isolate load time of a RP
* Journaling
  * single log per RangePartition
  * no hiccup with r/w contending
* Append-only System
  * simplify replication protocol & handling of failure scenarios
  * consistency to be enforced across all the replicas via their commit length
  * keep snapshots of previous states at virtually no extra cost -> snapshot/versioning
  * simplify erasure coding
  * better diagnosing by preserving history of changes
  * need efficient & scalable GC
  * need prefetching logic for streaming large data sets (since WAS stream pointer, need gather)
* End-to-end Checksums
  * each layer verify the checksum
  * help maintain data integrity
  * help identify servers with consistent hardware issues
* Upgrades
  * fault domain: A rack in a storage stamp
  * upgrade domain: a set of servers briefly taken offline at the same time during a rolling upgrade
* Multiple Data Abstraction from a Single Stack
  * Blob/Table/Queue for same intra-stamp/inter-stamp replication, same load balancing
  * reduce cost by running all services on the same set of hardware
  * Blob -> massive disk capacity
  * Table-> I/O spindle from the many disks on a node
  * Queue -> memory
* Use of System-defined Object Tables
  * fixed number of system defined OTs to build abstractions, instead of exposing raw OTs semantics to end users
  * reduce management
  * easy maintenance & upgrade
* Offering Storage in Buckets of 100TBs
* CAP Theorem
  * high availability & strong consistency & partition tolerance, violates the CAP?
  * layering & specific fault model
  * stream layer
    * simple append-only data model
    * high availability in the face of network partitioning & other failures
    * node failures / top-of-rack switch failures -> stop using & start using extents on available racks
  * partition layer
    * strong consistency
    * failures -> reassign RP to PS on available racks -> high availability & strong consistency
  * decoupling & targeting a specific set of failures
  * [[Note: I think this is nonsense. It's CP without A]]
  * [Azure & CAP](https://stackoverflow.com/questions/2502024/azure-slas-and-cap-theorem), 99% availability
  * enforce append-only consistency
* High-performance Debug Logging
  * automatically tokenizing & compressing log output
  * critical for investigating
* Pressure Point Testing
  * programmable interface for all main operations



## Questions

* The availability of Azure is questionable.
* Won't these level of abstractions harm performance?

