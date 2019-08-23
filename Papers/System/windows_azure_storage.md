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

* 