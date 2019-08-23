# Bigtable: A Distributed Storage System for Structured Data

[link](https://static.googleusercontent.com/media/research.google.com/zh-CN//archive/bigtable-osdi06.pdf)



## Data Model

* wide applicability  + scalability + high performance + high availbility
* Bigtable -> sparse, distributed, persistent, multi-dimensional sorted map
  * `(row: string, column: string, time: int64) -> string`
  * ![1563027800286](D:\OneDrive\Pictures\Typora\1563027800286.png)
  * rows
    * arbitrary strings (up to 64KB in size, ~10-100 bytes typical)
    * atomic read/write for a single row key
    * lexicographic ordered row keys
    * dynamically partitioned row range -> tablets
      * unit of distribution
      * unit of load balancing
  * column families
    * column key groups
      * unit of access control
      * unit of disk/memory accouting
    * `family:qualifier`
  * timestamps
    * each cell contains multiple versions of the same data, indexed by timestamp
    * 64bit integers
    * garbage collections: last n versions / only new-enough versions



## API

* ```c++
  // Writing to Bigtable
  // Open the table
  Table *T = OpenOrDie("/bigtable/web/webtable");
  // Write a new anchor and delete an old anchor
  RowMutation r1(T, "com.cnn.www");
  r1.Set("anchor:www.c-span.org", "CNN");
  r1.Delete("anchor:www.abc.com");
  Operation op;
  Apply(&op, &r1);
  
  // Reading from Bigtable
  Scanner scanner(T);
  ScanStream *stream;
  stream = scanner.FetchColumnFamily("anchor");
  stream->SetReturnAllVersions();
  scanner.Lookup("com.cnn.www");
  for (; !stream->Done(); stream->Next()) {
      printf("%s %s %lld %s\n",
          scanner.RowName(),
          stream->ColumnName(),
          stream->MicroTimestamp(),
          stream->Value());
  }
  ```

* single-row transactions

  * atomic read-modify-write on data stored under a single row key

* cell as integer counters

* execution of client-supplied scripts in the address space of the servers

  * Sawzall language

* with MapReduce



## Building Blocks

* GFS
* cluster management system
  * scheduling jobs
  * managing resources on shared machines
  * dealing with machine failures
  * monitoring machine status
* `SSTable` file format
  * persistent, ordered immutable map from keys (string) to values (string)
  * lookup (key -> value)
  * iterate over all key, values in specified key range
  * sequence of blocks (64KB, configurable)
    * block index
  * optional mapped to memory
* Chubby
  * lock service
  * 5 active replicas (1 master)
  * Paxos
  * namespace with directories & files
  * consistent caching
  * session & lease & callback



## Implementation

* library linked into every client
  * cache tablet locations
  * prefetch tablet locations
* master server
  * assign tablets to tablet servers
  * detect addition & expiration
  * balancing
  * garbage collection
  * handle schema changes
  * lightly loaded (no need for location info)
* tablet servers
  * set of tablets
  * read/write requests
  * split tablets
* tablet location
  * ![1563179272001](D:\OneDrive\Pictures\Typora\1563179272001.png)
  * 1st level
    * chubby
    * location of root tablet
  * root tablet -> location of all tablets in special `METADATA` table
  * `METADATA` -> location of set of user tablets + log
* tablet assignment
  * tablet server creates + acquires exclusive lock on uniquely-named file in a specific Chubby directory
  * lose lock (eg. network partition) -> reacquire -> kill self
  * master check tablet servers status of locks -> lost? / unable to reach -> master acquires lock -> success? -> Chubby live, tablet server dead (reassigned)
  * master startup
    * grab a unique master lock in Chubby, prevent concurrent master
    * scan server directory in Chubby, find live tablet servers
    * communicate with every live tablet servers, discover assignment
    * (due to `METADATA` / root tablet absence) add root tablet.
    * scan `METADATA` table
  * tablets changing
    * create
    * delete
    * merge
      * by master
    * split
      * by tablet server
      * commit by recording info in `METADATA` table
      * notify master, detect immediately or when loading the being split tablet (inconsistent `METADATA`)
* tablet serving
  * ![1563198591065](D:\OneDrive\Pictures\Typora\1563198591065.png)
  * memtable
    * recently committed updates
    * in memory in a sorted buffer
  * a sequence of `SSTable`s
    * older updates
  * recover a tablet -> `METADATA` -> list of `SSTables`
    * tablet + redo points (pointers into any commit logs that may contain data for the tablet)
    * read `SSTable` -> apply updates since redo points -> reconstruct memtable
  * write op -> check well-formedness -> authorize sender (list of writer in Chubby client cache) -> write mutation log (grouped) -> insert into memtable
  * read op -> check well-formedness -> authorize reader -> read on merged view of the sequence of `SSTable` + memtable
  * incoming r/w continue when merge/split
* Compaction
  * minor compaction
    * memtable size reachs threshold -> frozen -> `SSTable`
    * shrink memory usage
    * reduce amount of data read from commit log during recovery
    * deletion entries still live
  * incoming r/w continue when compact
  * merging/major compaction
    * read a few `SSTable`s + memtable -> `SSTable`
    * deletion entries removed



## Refinements

* locality groups
  * client group multiple column families together
  * generate a separate `SSTable` per locality group
  * efficient read
  * option: in memory lazily
* compression
  * `SSTable` for locality group can be compressed
  * user-specified compression format
  * 2-pass
    * Bentley & Mcllroy (long common string across large window)
    * fast compression algorithm (repetition in a small window)
    * small portion can be read without decompression
* caching
  * 2-level caching for read performance
    * Scan Cache: high-level cache for k-v pairs returned by `SSTable`
      * temporal locality
    * Block Cache: low-level cache for `SSTable` blocks from GFS
      * spatial locality
* bloom filters
  * read op has to read from all `SSTable` -> not in memory -> disk accesses
  * bloom filter for `SSTable` in a locality group -> whether an `SSTable` contain any data for a specified row/column pair
* commit-log implementation
  * commit log per tablet -> large number of files concurrently in GFS -> large number of disk seeks (by implementation)
  * separate log files -> reduce effectiveness of group commit optimization
  * single commit log per tablet server, co-mingling mutations for different tablets in the same physical log
    * complicate recovery -> each new tablet server need to read full commit log and reapply
    * sorting commit log by `<Table, RowName, LogSeqNum>` -> parallelize sorting
  * writing commit logs to GFS -> performance hiccup (write crash, network path congestion, heavily loaded)
    * 2 log writing threads to own file
    * 1 of 2 is actively in use
    * hiccup -> switch threads
    * sequence number -> elide duplicated entries from log switching
* speeding up tablet recovery
  * move tablet -> source do minor compaction (reduce recovery time) -> source stop serving -> source do another minor compaction (eliminate remaining uncompacted state) -> loaded in destination without log entries recovery
* exploiting immutability
  * immutable `SSTable`
  * no need any synchronization of accesses
  * only mutable data is memtable
    * each row copy-on-write + allow r/w in parallel
  * removing deleted data -> garbage collection obsolete `SSTable`
    * mark & sweep, `METADATA` as set of roots
  * split tablets quickly
    * child tablets share the `SSTable` of the parent



## Lessons

* large distributed systems are vulnerable to many types of failures
  * standard network partition
  * fail-stop failures in protocols
  * memory/network corruption
  * large clock skew
  * hung machines
  * extended & asymmetric network partitions
  * bugs in other systems
  * overflow of GFS quotas
  * planned & unplanned maintenance
  * solutions
    * checksum for RPC mechanism
    * remove assumptions by parts of system
* it's important to delay adding new features until it's clear how the new features will be used
  * general-purpose transaction? X
* importance of proper system-level monitoring
* value of simple designs
  * code & design clarity



## Questions

* Why memtable is allowed to have r/w in parallel? What role does the COW of each rows act?
* Is reapplying each operation of `SSTable` + memtable really efficient?
* Why some portion of compressed data can be read without decompression?
  * succinct?
* Can Bigtable rebuild its index?
  * unclustered (now) -> clustered index -> hash/B-tree
  * data entry (k*) -> data record (now) -> <k, rid>

