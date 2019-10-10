# The Google File System

[link](https://static.googleusercontent.com/media/research.google.com/zh-CN//archive/gfs-sosp2003.pdf)

Check EECS582/Notes/Wk9

Check EECS485/Lectures



## Intro

* Component failures are the norm rather than the exception
* Files are huge by traditional standards
* Most files are mutated by appending new data rather than overwriting existing data
* Co-designing the applications and the file system API benefits the overall system by increasing our flexibility.



## Design

* Assumptions
  * The system is built from many inexpensive commodity components that often fail. Constantly monitor, detect, tolerate, recover.
  * Store a modest number of large files. >100MB (~GB) x 1M
  * Large streaming reads (MB x 100) & small random reads (KB)
  * The workloads also have many large, sequential writes that append data to files.
  * Well-defined semantics for multiple clients that concurrently append to the same file. (consumer-producer)
  * High sustained bandwidth > low latency
* Interface
  * `create`/`delete`/`open`/`close`/`read`/`write`
  * `snapshot`/`record append`
* Architecture
  * single `master` + multiple `chunkservers` + multiple `clients`
  * files -> fixed-size chunks
    * chunk -> immutable, globally unique 64bit chunk handle
    * replicated (3 by default)
  * master maintains all fs metadata
    * namespace
    * access control information
    * mapping from files to chunks
    * current locations of chunks
    * chunk lease management
    * garbage collection of orphaned chunks
    * chunk migration between chunkservers
    * communicate by HeartBeat
  * only cache metadata, not file data
* single master
  * ![1562940505038](D:\OneDrive\Pictures\Typora\1562940505038.png)
  * chunk size = 64MB
    * reduce read need
    * reduce network overhead
    * reduce metadata size
    * hot spots x
* Metadata
  * file & chunk namespaces
    * persistent -> operation log
  * mapping from files to chunks
    * persistent -> operation log
  * locations of each chunk's replicas
    * restore at master startup instead of persistent
  * in memory
* operation log
  * batching
  * replicated
  * checkpoint -> compact B-tree form (directly mapped into memory and used for namespace lookup without extra parsing) succinct?
    * checkpoint include everything before the switch & without delaying incoming mutations
* consistency model
  * relaxed
  * ![1562948140295](D:\OneDrive\Pictures\Typora\1562948140295.png)
  * consistent
    * all clients will always see the same data, regardless of which replicas whey read from
  * defined
    * consistent & client will see what the mutation writes in its entirely
  * write: data written at an application-specified file offset
  * record append: data be appended atomically (at least once even in the presence of concurrent mutations)
    * padding & duplicate
  * chunk version number
  * may return stale replica



## System Interaction

* lease & mutation order
  * global mutation order -> lease grant order chosen by master -> within a lease by the serial number assigned by the primary
  * ![1562950072121](D:\OneDrive\Pictures\Typora\1562950072121.png)
    * client -> master -> lease
    * master -> primary & replicas -> client cache
    * client -> all replicas (in any order) -> chunkserver LRU buffer cache
    * all replicas acknowledged -> client -> primary (write request) -> assign serial number
    * primary -> secondary replicas for application
    * secondary replicas -> primary for completed
    * primary -> client (errors -> inconsistent)
* data flow
  * data pushed linearly along a picked chain of chunkservers in a pipelined fashion
  * fully utilize network bandwidth
    * chain topology
  * avoid network bottleneck & high-latency links
    * closest machine in the network topology
  * minimize the latency to push through all the data
    * over TCP connection
    * forward immediately
* atomic record appends
  * `record append`
  * padding chunks before write
  * retry for fails at any replica
* snapshot
  * copy-on-write
  * revoke outstanding leases -> log the operations -> apply operation to in-memory state by duplicating the metadata from the source file / directory tree.
  * client request -> master find refcnt of chunk C > 1 -> defer replying & ask chunkserver creating new chunk and copy locally
  * lazy?



## Master Operation

* namespace management & locking
  * lock over regions of the namespace
  * namespace as lookup table mapping full pathnames -> metadata
    * prefix compression
  * RWLock for directories
* replica placement
  * maximize data reliability & availability
  * maximize network bandwidth utilization
  * spread chunk replicas across racks
    * survive & available even if damaged rack
    * traffic for a chunk can exploit aggregate bandwidth of multiple racks
* creation, re-replication, rebalancing
  * create -> initial empty replicas
    * below-average disk space utilization
    * limit the number of "recent" creations on each chunkserver
    * spread replicas across racks
  * re-replicate
    * priority: how far it's from its replication goal + lost 2 replica > lost 1 replica + blocking client progress
    * clone by instruction chunkserver to copy from existing valid replica
  * rebalance
* garbage collection
  * log deletion + rename to hidden name
  * scan -> remove hidden names if >3 days
  * scan -> identify orphaned chunks -> erase metadata -> notify chunkserver by heartbeat
  * simple & reliable in large-scale distributed system
  * merge storage reclamation into regular background activities, amortize cost
  * done only when master is relatively free
  * safety net against accidental, irreversible deletion
* stale replica detection
  * chunk version number
    * increase for each lease and inform replicas
  * remove stale replicas in regular GC



## Fault Tolerance & Diagnosis

* high availability
  * fast recovery
  * chunk replication
  * master replication
    * operation log & checkpoint
    * "shadow" master
      * read-only when primary master is down
* data integrity
  * checksum -> corruption
  * incrementally update checksum
* diagnosis tools





## Miscs

* [GFS: Evolution on Fast-forward](http://web.eecs.umich.edu/~mosharaf/Readings/GFS-ACMQueue-2012.pdf)
  * single master -> bottleneck -> 1 master per cell, ~1 cell per data center
  * file-count (metadata requirement) -> distributed master & task design
  * BigTable
  * weak consistency -> problems -> append-only
  * snapshot -> barely used
* [Colossus](https://cloud.google.com/files/storage_architecture_and_challenges.pdf)

