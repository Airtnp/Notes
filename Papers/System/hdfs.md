# The Hadoop Distributed File System

* [link](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=5496972)



## Intro

* ![1562662982227](D:\OneDrive\Pictures\Typora\1562662982227.png)
* file system component of Hadoop
  * reliable
  * high bandwidth
* MapReduce paradigm
  * +GFS
* metadata -> `NameNode`
* application data -> `DataNode`s
  * no RAID
  * replicated
* fully-connected, communicate using TCP-based



## Architecture

* `NameNode`
  * file, directory -> inodes
    * permissions
    * modification
    * access time
    * namespace
    * diskspace quotas
  * namespace tree
  * mapping of file blocks to `DataNode`s
  * in RAM
    * image
  * in FS
    * checkpoint
    * journal
* `DataNode`
  * (data, metadata[checksums, generation stamp])
  * 128mb blocks, replicated at `DataNode`s (usually 3)
  * startup: -> `NameNode`, handshake
    * verify namespace ID
    * verify software version
    * register with `NameNode`
    * <- block report ([id, generation stamp, length])
  * storage ID
  * heartbeats -> `NameNode`
    * use heartbeat replies as instructions
      * replicate blocks to other nodes
      * removal local block replicas
      * re-register or shut down the node
      * send an immediate block report
* HDFS Client
  * read/write/delete, create/delete dirs
  * first ask `NameNode` -> list of `DataNode`s that host replicas of the block of the file
  * write: data pipeline
    * ![1562664038630](D:\OneDrive\Pictures\Typora\1562664038630.png)
  * API exposing locations of file blocks
* Image & Journal
  * namespace image: file system metadata that describes the organization of application data as directories and files
  * checkpoint: persistent record of the image written to disk
  * journal: write-ahead commit log for changes to the file system (persistent)
    * flushed & synched before every change committed
      * bottleneck -> batching by `NameNode` transactions
    * never changed by the `NameNode`
    * replaced entirely when checkpoint created during restart
    * requested by the administrator
    * requested by the `CheckpointNode`
* `CheckpointNode`
  * `NameNode` -> primary / `CheckpointNode` / `BackupNode`
  * periodically combine checkpoint + journal -> checkpoint' + empty journal
* `BackupNode`
  * creating periodic checkpoints + maintain in-memory up-to-date image of namespace
  * journal stream of namespace transactions -> save + apply to own namespace image
  * create a checkpoint without downloading checkpoint & journals files from the active `NameNode`
  * read-only `NameNode`
  * all file system metadata except block locations
    * perform all operations of regular `NameNode` except modification of namespace + knowledge of block locations
* Upgrade, File System Snapshots
  * `NameNode` merge checkpoint & journal
  * `DataNode` (via handshake) create local snapshot
    * hard link copy of storage directory



## File I/O operations

* read & write
  * single-writer, multiple-reader
    * write -> lease granted (keep by heartbeat)
      * soft limit -> another client preempt
      * hard limit -> auto close & recover lease
  * append-only
  * data pipeline
    * ![1562767382897](D:\OneDrive\Pictures\Typora\1562767382897.png)
* block placement
  * nodes -> racks -> switch -> core switches
  * block placement policy (for replica)
    * configurable
    * 1st -> writer
    * 2nd, 3rd -> 2 diff nodes in diff racks
    * rest -> random nodes with restrictions
      * <= 1 replica per node
      * <=2 replica per rack
    * organized as pipeline in the order of their proximity to the first replica
    * no `DataNode` contains more than 1 replica
    * no rack contains more than 2 replica of the same block (providing there are sufficient racks)
* replication management
  * `NameNode` manages the under-/over-replicated
    * over-replicated -> remove
      * prefer not to reduce number of racks that host replicas
      * prefer to remove a replica from the `DataNode` with minimum available disk space
    * under-replicated -> replication priority queue
      * priority highest: 1 replica ----> 2/3 rep factor: priority lowest
      * background thread
* balancer
  * balance disk space usage on an HDFS cluster
  * |utilization of the node - utilization of the cluster| <= threshold value
  * maintain data availability
  * minimize inter-rack data copying
  * limited bandwidth
* block scanner
  * periodically scan & verify stored checksum === block data
  * store verification time in human readable log file
    * current / prev logs
  * corrupt block -> notify `NameNode`, replicate good copy -> reach replication factor -> remove corrupted block
    * preserve data ALAP
* decommissioning
  * keep include/exclude lists
  * `DataNode` decommissioning -> schedule replication -> decommissioned state -> safely removed
* Inter-cluster Data Copy
  * MapReduce type `DistCp`



## Practice at Yahoo

* `!TODO`
* future work
  * automated failover -> Zookeeper
  * scalability --> `NameNode` unresponsive due to Java GC
    * in memory namespace & block locations
    * solution: multiple namespace & `NameNode`



## Questions

1. What's the HDFS consistency model?
   * like GFS? (no write)
2. How to make consensus between `DataNode` block replicas?
   * extra consensus alg?
3. Difference with GFS



## Notes

* 