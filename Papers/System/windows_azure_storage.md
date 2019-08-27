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

* 