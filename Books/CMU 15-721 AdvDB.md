# Advanced Database Systems

[spring2019](https://15721.courses.cs.cmu.edu/spring2019/)



## In-Memory Databases

* disk-oriented database
  * slotted page: fixed-length blocks
  * buffer pool
  * stall when try to access data that is not in memory
  * ![image-20191218170102147](D:\OneDrive\Pictures\Typora\image-20191218170102147.png)
* bottlenecks shifts
  * locking/latching
  * cache-line misses
  * pointer chasing
  * predicate evaluation
  * data movement/copying
  * networking
* data organization
  * direct memory pointers vs. record ids
  * fixed-length vs variable-length data pools
  * checksums for corruption
* `mmap + madvise + msync`?
  * MongoDB/MonetDB/LMDB/MemSQL
  * no fine-grained control
* concurrency control
  * cost of a txn acquiring a lock is the same as accessing data
* indexes
  * specialized main-memory indexes
  * cache-aware indexes (B+ tree is cache-aware)
* query processing
* logging & recovery
  * WAL on non-volatile storage since the system could halt at any time
  * group commit: batch log entries, flush together to amortize `fsync`
  * lightweight logging schemes (e.g. only store redo information)
  * no dirty pages, no need to maintain LSNs
  * checkpointing
    * second copy of the database, updating by replaying WAL
    * special copy-on-write mode, write a dump to disk
    * fork the DBMS process, have child process write its contents to disk
* larger-than-memory databases
  * hot data: OLTP operations
  * cold data: OLAP queries
* Notable in-memory dbmss
  * ![image-20191218212321666](D:\OneDrive\Pictures\Typora\image-20191218212321666.png)
  * TimesTen: multi-process, shared memory DBMS
    * single-version, 2PL
    * dictionary-encoded columnar compression
    * as a cache in front of Oracle DBMS
  * Dali/DataBlitz: multi-process, shared memory storage, memory-mapped files
    * fault tolerant
    * metadata is stored in non-shared location
    * page's checksum tested on read, if corrupted, recover from log
  * P*Time
    * differential encoding for log records (XOR)
    * hybrid storage layouts
    * support for larger-than-memory databases



## Transaction Model & Concurrency Control

* Workload: OLT(ransaction)P, OLA(Analytical)P, Hybrid
* OLTP -> ETL(Extract, Transform, Load) -> OLAP
* actions
  * unprotected actions: lack all of the ACID properties, except for consistency
  * protected actions, fully ACID, no externalize results before completed
  * real actions: affect physical world, hard to reverse
* Transaction models
  * Flat transactions: `BEGIN, Actions, COMMIT/ROLLBACK`
    * can only rollback the entire txn
    * if DBMS fails before txn finishes, all work lost
    * each txn takes place at a single time point
    * E.g. multi-stage planning, bulk updates
  * Savepoints: save current state of processing for the txn and provide a handle for the application to refer to that savepoint
    * `ROLLBACK`: revert all changes back to the state of the DB at the savepoint
    * `RELEASE`: destroy a savepoint previously defined in the txn
    * sequence of actions, can be rolled back individually
    * ![image-20191218214506598](D:\OneDrive\Pictures\Typora\image-20191218214506598.png)
  * Nested transactions
    * hierarchy of work
    * ![image-20191218214437707](D:\OneDrive\Pictures\Typora\image-20191218214437707.png)
  * Transaction chains
    * combined `COMMIT/BEGIN` operation is atomic
      * no other txn can change the state of the database as seen by the 2nd txn from the time that the 1st txn commits and the 2nd txn begins
    * differences with savepoints
      * `COMMIT` allows the DBMS to free locks
      * cannot rollback previous txns in chain
    * ![image-20191218214853754](D:\OneDrive\Pictures\Typora\image-20191218214853754.png)
  * Compensating transactions: a special type of txn designed to semantically reverse the effects of another already committed txn
    * logical reversal (+1, -1)
  * Sage transactions
    * a sequence of chained txns $T_1 - T_n$ and compensating txns $C_1 - C_{n - 1}$ where one of the following is guaranteed
      * The txns will commit in the order $T_1, \cdots T_j, C_j \cdots C_1$ (where $j < n$)
    * support long-running, multi-step txns without application managed logic
    * ![image-20191218215413538](D:\OneDrive\Pictures\Typora\image-20191218215413538.png)
* Concurrency control
  * provides Atomicity + Isolation in ACID
  * access database in a multi-programmed fashion while preserving the illusion that each of them is executing alone on a dedicated system
* Transaction Internal State
  * Status: the current execution state of the txn
  * Undo Log Entries
    * stored in an in-memory data structure
    * dropped on commit
  * Redo Log Entries
    * Append to the in-memory tail of WAL
    * Flushed to disk on commit
  * Read/Write Set
    * Depends on the concurrent control scheme
* Concurrency control schemes
  * two-phase locking (2PL)
    * deadlock detection
      * each txn maintains a queue of the txns that hold the locks that it waiting for
      * a separate thread checks these queues for deadlocks
      * if deadlock found, use a heuristic to decide what txn to kill in order to break deadlock
    * deadlock prevention
      * check whether another txn already holds a lock when another txn requests it
      * if lock is not available, the txn will either wait/commit suicide/kill the other txn
  * timestamp ordering (T/O)
    * basic T/O
      * check for conflicts on each read/write
      * copy tuples on each access to ensure repeatable reads
    * optimistic concurrency control (OCC)
      * store all changes in private workspace
      * check for conflicts at commit time and then merge
* Concurrency control evaluation
  * DBx1000 database system
    * in-memory DBMS with pluggable lock manager
    * no network access/logging/concurrent indexes
  * MIT Graphite CPU simulator
    * single-socket, tiled based CPU
    * shared L2 cache for groups of cores
    * tiles communicate over 2D-mesh network
  * Yahoo! Cloud Serving Benchmark (YCSB)
    * 20 million tuples
    * each tuple is 1KB
    * each txn read/modifies 16 tuples
    * varying skew in transaction access patterns
    * serializable isolation level
* ![image-20191218220315564](D:\OneDrive\Pictures\Typora\image-20191218220315564.png)
* ![image-20191218220323250](D:\OneDrive\Pictures\Typora\image-20191218220323250.png)
* Bottlenecks
  * Lock thrashing: `DL_DETECT`, `WAIT_DIE`
    * removing deadlock detection/prevention overhead
    * force txns to acquire locks in primary key order
    * deadlocks are not possible
  * Timestamp allocation: all T/O + `WAIT_DIE`
    * mutex: worst option
    * atomic addition: requires cache invalidation on write
    * batched atomic addition: needs a back-off mechanism to prevent fast burn
    * hardware clock: not sure if will exist in future CPUs
    * hardware counter: not implemented in existing CPUs
  * Memory allocation: OCC + MVCC
    * copy data, contention on the memory controller
    * no default libc `malloc`
* Isolation levels
  * ![image-20191218220633088](D:\OneDrive\Pictures\Typora\image-20191218220633088.png)
  * ![image-20191218220649976](D:\OneDrive\Pictures\Typora\image-20191218220649976.png)
* Cursor stability (CS)
  * The DBMS’s internal cursor maintains a lock on a item in the database until it moves on to the next  item.
  * CS is a stronger isolation level in between REPEATABLE READS and READ COMMITTED that can (sometimes) prevent the Lost Update Anomaly
  * ![image-20191218220754034](D:\OneDrive\Pictures\Typora\image-20191218220754034.png)
* Snapshot Isolation (SI)
  * Guarantees that all reads made in a txn see a consistent snapshot of the database that existed at the time the txn started.
    * A txn will commit under SI only if its writes do not conflict with any concurrent updates made since that snapshot.
  * SI is susceptible to the Write Skew Anomaly
  * ![image-20191218220857161](D:\OneDrive\Pictures\Typora\image-20191218220857161.png)
* ![image-20191218220909105](D:\OneDrive\Pictures\Typora\image-20191218220909105.png)
* ![image-20191218220916449](D:\OneDrive\Pictures\Typora\image-20191218220916449.png)





## Multi-Version Concurrency Control

* MVCC: The DBMS maintains multiple physical versions of a single logical object in the database
  * When a txn writes to an object, the DBMS creates a new version of that object
  * When a txn reads an object, it reads the newest version that existed when the txn started.
* Benefits:
  * writer don't block readers
  * read-only txns can read a consistent snapshot without acquiring locks
  * easily support time-travel queries
* SI is automatically free with MVCC
* Concurrency control protocol
  * Timestamp Ordering (MVTO)
    * Assign txns timestamps that determine serial order
    * Considered to be original MVCC protocol
    * ![image-20191218232543958](D:\OneDrive\Pictures\Typora\image-20191218232543958.png)
  * Optimistic Concurrency Control (MV-OCC)
    * 3-phase protocol
    * private workspace for new versions
  * 2PL (MV2PL)
    * Txns acquire appropriate lock on physical version before they can read/write a logical tuple
    * ![image-20191218232627490](D:\OneDrive\Pictures\Typora\image-20191218232627490.png)
* wrap around TS (overflow)
  * Postgres: set a flag in each tuple header that says that it is "frozen" in the past. Any new txn id will always be newer than a frozen version
    * Runs the vacuum before the system gets close to this upper limit
    * Otherwise it has to stop accepting new commands when the system gets close to the max txn id
* version storage
  * The DBMS uses the tuples’ pointer field to create a latch-free version chain per logical tuple
    * index point to the head of the chain
    * DBMS find the version that is visible to a particular txn at runtime
  * Threads store versions in “local” memory regions to avoid contention on centralized data structures
  * Append-only storage: New versions are appended to the same table space
    * ![image-20191219145918569](D:\OneDrive\Pictures\Typora\image-20191219145918569.png)
    * Version chain ordering
      * Oldest-to-Newest (O2N)
        * Just append new version to end of the chain
        * Have to traverse chain on look-ups
      * Newest-to-Oldest (N2O)
        * Have to update index pointers for every new version
        * Don’t have to traverse chain on look ups
  * Time-travel storage: Old versions are copied to separate table space
    * ![image-20191219150050108](D:\OneDrive\Pictures\Typora\image-20191219150050108.png)
  * Delta storage: The original values of the modified attributes are copied into a separate delta record space
    * ![image-20191219150101171](D:\OneDrive\Pictures\Typora\image-20191219150101171.png)
* non-inline attributes
  * ![image-20191219150517804](D:\OneDrive\Pictures\Typora\image-20191219150517804.png)
* garbage collection
  * remove reclaimable physical versions from the database over time
    * No active txn in the DBMS can “see” that version (SI)
    * The version was created by an aborted txn
  * how to look for expired versions?
  * how to decide when it is safe to reclaim memory?
  * where to look for expired versions?
  * tuple-level: find old versions by examining tuples directly
    * background vacuuming
      * Separate thread(s) periodically scan the table and look for reclaimable versions. Works with any storage.
    * cooperative cleaning
      * Worker threads identify reclaimable versions as they traverse version chain. Only works with O2N.
  * transaction-level: txns keep track of their old versions, so the DBMS does not have to scan tuples to determine visibility
    * Each txn keeps track of its read/write set
    * The DBMS determines when all versions created by a finished txn are no longer visible
    * May still require multiple threads to reclaim the memory fast enough for the workload
* index management
  * primary key
    * PKey indexes always point to version chain head
    * txn updates a tuple's pkey $\to$ `DELETE + INSERT`
  * secondary key
    * logical pointers
      * Use a fixed identifier per tuple that does not change (pkey, tuple id)
      * requires an extra indirection layer
    * physical pointers
      * Use the physical address to the version chain head
* ![image-20191219154511484](D:\OneDrive\Pictures\Typora\image-20191219154511484.png)
* Microsoft Hekaton
  * Had to integrate with MSSQL ecosystem
  * Had to support all possible OLTP workloads with predictable performance.
    * Single-threaded partitioning (e.g., H-Store/VoltDB) works well for some applications but terrible for others
  * Each txn is assigned a timestamp when they begin (BeginTS) and when they commit (CommitTS)
  * Each tuple contains two timestamps that represents their visibility and current state
    * `BEGIN-TS`: BeginTS of the active txn / CommitTS of the comitted txn that created it
    * `END-TS`: BeginTS of the active txn that created the next version / infinity / CommitTS of the committed txn that created it
  * Transaction state map
    * `ACTIVE`: The txn is executing read/write operations
    * `VALIDATING`:  The txn has invoked commit and the DBMS is checking whether it is valid
    * `COMMITTED`: The txn is finished, but may have not updated its versions’ TS
    * `TERMINATED`: The txn has updated the TS for all of the versions that it created
  * ![image-20191219162629879](D:\OneDrive\Pictures\Typora\image-20191219162629879.png)
  * transaction metadata
    * read set: Pointers to every version read
    * write set: Pointers to versions updated (old and new), versions deleted (old), and version inserted (new)
    * scan set: Stores enough information needed to perform each scan operation
    * commit dependencies: List of txns that are waiting for this txn to finish
  * optimistic txns
    * Check whether a version read is still visible at the end of the txn
    * Repeat all index scans to check for phantoms
  * pessimistic txns
    * Use shared & exclusive locks on records and buckets.
    * No validation is needed
    * Separate background thread to detect deadlocks
  * lessons
    * Use only lock-free data structures
      * no latches, spinlocks, critical sections
      * indexes, txn map, memory alloc, garbage collector
      * Bw-Trees + SkipList
    * Only one single serialization point in the DBMS to get the txn’s begin and commit timestamp
      * Atomic Addition (CAS)
  * observations
    * Read/scan set validations are expensive if the txns access a lot of data
    * Appending new versions hurts the performance of OLAP scans due to pointer chasing & branching
    * Record-level conflict checks may be too coarse-grained and incur false positives
* Hyper MVCC
  * Column-store with delta record versioning.
    * In-Place updates for non-indexed attributes
    * Delete/Insert updates for indexed attributes
    * N2O version chaining
    * No predicate locks / No scan checks
  * Avoids write-write conflicts by aborting txns that try to update an uncommitted object
  * ![image-20191219165549389](D:\OneDrive\Pictures\Typora\image-20191219165549389.png)
  * validation
    * First-Writer Wins
      * The version vector always points to the last committed version
      * Do not need to check whether write-sets overlap
    * Check the undo buffers (i.e., delta records) of txns that committed after the validating txn started]
      * Compare the committed txn's write set for phantoms using [Precision Locking](https://dl.acm.org/citation.cfm?id=582340)
      * Only need to store the txn's read predicates and not its entire read set
  * precision locking
    * ![image-20191219174110264](D:\OneDrive\Pictures\Typora\image-20191219174110264.png)
  * version synopses
    * Store a separate column that tracks the position of the first and last versioned tuple in a block of tuples
    * When scanning tuples, the DBMS can check for strides of tuples without older versions and execute more efficiently
    * ![image-20191219174204641](D:\OneDrive\Pictures\Typora\image-20191219174204641.png)
* SAP Hana
  * In-memory HTAP DBMS with time-travel version storage (N2O)
    * Supports both optimistic and pessimistic MVCC
    * Latest versions are stored in time-travel space
    * Hybrid storage layout (row + columnar)
  * Based on P*Time/TREX/MaxDB
  * Version storage
    * Store the oldest version in the main data table.
    * Each tuple maintains a flag to denote whether there exists newer versions in the version space
    * Maintain a separate hash table that maps record identifiers to the head of version chain
    * ![image-20191219174304560](D:\OneDrive\Pictures\Typora\image-20191219174304560.png)
  * transactions
    * Instead of embedding meta-data about the txn that created a version with the data, store a pointer to a context object
      * Reads are slower because you have to follow pointers
      * Large updates are faster because it's a single write to update the status of all tuples
    * Store meta-data about whether a txn has committed in a separate object
    * ![image-20191219174401211](D:\OneDrive\Pictures\Typora\image-20191219174401211.png)
* MVCC Limitations
  * Computation & Storage Overhead
    * Most MVCC schemes use indirection to search a tuple's version chain. This increases CPU cache misses
    * Requires frequent garbage collection to minimize the number versions that a thread has to evaluate
  * Shared Memory Writes
    * Most MVCC schemes store versions in "global" memory in the heap without considering locality
  * Timestamp Allocation
    * All threads access single shared counter
* OCC Limitations
  * Frequent Aborts
    * Txns will abort too quickly under high contention, causing high churn
  * Extra Reads & Writes
    * Each txn has to copy tuples into their private workspace to ensure repeatable reads. It then has to check whether it read consistent data when it commits
  * Index Contention
    * Txns install "virtual" index entries to ensure unique-key invariants
* CMU CICADA
  * In-memory OLTP engine based on optimistic MVCC with append-only storage (N2O)
    * Best-effort Inlining
      * Record meta-data is stored in a fixed location
      * Threads will attempt to inline read-mostly version within this meta-data to reduce version chain traversals
      * ![image-20191219174625748](D:\OneDrive\Pictures\Typora\image-20191219174625748.png)
    * Loosely Synchronized Clocks
    * Contention-Aware Validation
    * Index Nodes Stored in Tables
  * Fast validation
    * Contention-aware Validation
      * Validate access to recently modified records first
    * Early Consistency Check
      * Pre-validate access set before making global writes
    * Incremental Version Search
      * Resume from last search location in version list
    * Skip contention-aware validation/early consistency check if all recent txns committed successfully.
  * Index storage
    * ![image-20191219174750625](D:\OneDrive\Pictures\Typora\image-20191219174750625.png)
* Garbage collection
  * problem: HTAP long running queries
* MVCC Delete
  * The DBMS physically deletes a tuple from the database only when all versions of a logically deleted tuple are not visible
    * If a tuple is deleted, then there cannot be a new version of that tuple after the newest version
    * No write-write conflicts / first-writer wins
  * Denote logical deletion
    * Deleted Flag
      * Maintain a flag to indicate that the logical tuple has been deleted after the newest physical version
      * Tuple header / Separate column
    * Tombstone Tuple
      * Create an empty physical version to indicate that a logical tuple is deleted
      * Use a separate pool for tombstone tuples with only a special bit pattern in version chain pointer to reduce the storage overhead
* MVCC Indexes
  * MVCC DBMS indexes (usually) do not store version information about tuples with their keys
    * Exception: Index-organized tables (E.g. MySQL)
  * Every index must support duplicate keys from different snapshots
    * The same key may point to different logical tuples in different snapshots
  * ![image-20191220104442395](D:\OneDrive\Pictures\Typora\image-20191220104442395.png)
  * non-unique keys
  * execution logic to perform conditional inserts for pkey/unique indexes
    * atomically check whether the key exists and then insert
  * Workers may get back multiple entries for a single fetch. They then have to follow the pointers to find the proper physical versio
* GC Design Decisions
  * Index cleanup
    * remove a tuples' keys from indexes when version no longer visible to active txns
    * Track the txn's modifications to individual indexes to support GC of older versions on commit and removal modifications on abort
    * ![image-20191220104738890](D:\OneDrive\Pictures\Typora\image-20191220104738890.png)
  * Version tracking/identification
    * tuple-level
    * transaction-level
  * Granularity
    * How should the DBMS internally organize the expired versions that it needs to check to determine whether they are reclaimable
    * ability to fast reclaim versions vs. computational overhead
    * single version: track the visibility of individual versions and reclaim them separately
      * fine-grained, high overhead
    * group version: organize versions into groups and reclaim all of them together
      * delay reclamation, less overhead
    * tables: reclaim all versions from a table if the DBMS determines that active txns will never access it
      * Special case for stored procedures and prepared statements since it requires the DBMS knowing what tables a txn will access in advance
  * Comparison unit
    * How should the DBMS determine whether version(s) are reclaimable
    * latch-free examination
    * Timestamp: use a global minimum timestamp to determine whether versions are safe to reclaim
      * easy to implement/execute
    * Interval: excise timestamp ranges that are not visible
      * difficult to identify ranges
    * ![image-20191220110806814](D:\OneDrive\Pictures\Typora\image-20191220110806814.png)
* MVCC Deleted Tuples
  * Reuse slot: Allow workers to insert new tuples in the empty slots
    * trivial for append-only storage
    * destroy temporal locality of tuples in delta storage
  * Leave slot unoccupied: Workers can only insert new tuples in slots that were not previously occupied
    * ensure tuples in the same block were inserted into the DB at around the same time
    * need an extra mechanism to fill holes
  * Block compaction: consolidating less-than-full blocks into fewer blocks
    * `DELETE + INSERT`?
    * Ideally the DBMS will want to store tuples that are likely to be accessed together within a window of time together in the same block
      * especially for compression & moving cold data to disk
    * Targets
      * Time since last update: `BEGIN-TS` in each tuple
      * Time since last access: `READ-TS` (or it's expensive to keep)
      * Application-level semantics: tuples in the same table?
    * `TRUNCATE`: removes all tuples in a table
      * Fastest way to execute is to drop the table and then create it again
        * no visibility tracking
        * GC free all memory
        * catalog transactional, then easy
* ![image-20191220112017211](D:\OneDrive\Pictures\Typora\image-20191220112017211.png)





## Index Locking & Latching

* Order preserving indexes
  * A tree-like structure that maintains keys in some sorted order
  * Supports all possible predicates with O(log n) searches
  * B-tree: store keys + values in all nodes in the tree (memory efficient)
  * B+-tree: store values in leaf nodes, inner nodes only a guide (easy to manage concurrent index access, cache aware)
* Hashing indexes
  * An associative array that maps a hash of the key to a particular record
  * Only supports equality predicates with O(1) searches
* Locks vs Latches
  * locks
    * protect the index's logical contents from other txns
    * hold for txn duration
    * able to rollback
  * latches
    * protect critical sections of the index's internal data structurs
    * hold for operation duration
    * no need to rollback
  * ![image-20191221121742579](D:\OneDrive\Pictures\Typora\image-20191221121742579.png)
* Lock-free indexes
  * no locks: txns don't acquire locks to access/modify database
    * use latches to install updates
  * no latches: swap pointers using atomic updates to install changes
    * use locks to validate txns
* Latch implementations
  * blocking OS mutex
    * not scalable (25ns per lock/unlock)
    * `std::mutex` -> `pthread_mutex_t` -> `futex` (NPTL)
  * test-and-set spinlock (TAS)
    * efficiently, single instruction `test`
    * not scalable, not cache friendly
    * `std::atomic_flag`/`std::atomic<bool>`
  * queue-based spinlock (Mellor-Crummey & Scott, MCS)
    * more efficient than mutex, better cache locality
    * non-trivial memory management
    * `std::atomic<Latch*>`
    * ![image-20191221122318808](D:\OneDrive\Pictures\Typora\image-20191221122318808.png)
  * reader-writer locks
    * allows for concurrent readers
    * read/write queue to avoid starvation
    * built on top of spinlocks
  * CAS
    * Atomic instruction that compares contents of a memory location M to a given value V 
      * If values are equal, installs new given value V’ in M
      * Otherwise operation fails
    * `__sync_bool_compare_and_swap(&M, 20, 30)`
* Latch crabbing/coupling
  * acquire/release latches on B+Tree nodes when traversing the data structure
  * A thread can release latch on a parent node if its child node considered safe
    * Any node that won’t split or merge when updated
    * Not full (on insertion)
    * More than half-full (on deletion)
  * crabbing
    * Search: Start at root and go down; repeatedly
      * acquire read (R) latch on child
      * unlock the parent node
    * Insert/Delete: Start at root and go down
      * obtaining write (W) latches as needed
      * once child is locked, check if it is safe, if safe, release all locks on ancestors
  * better latch crabbing
    * Optimistically assume that the leaf is safe.
    * Take R latches as you traverse the tree to reach it and verify
    * If leaf is not safe, then do previous algorithm
  * crabbing ensures that txns do not corrupt the internal data structure during modifications
    * but cannot guarantee that phantoms do not occur
* Index locks
  * protect index's logical contents from other txns to avoid phantoms
  * only acquired at the leaf nodes
  * not physically stored in index data structure
  * Predicate locks
    * System R
    * Shared lock on the predicate in a `WHERE` clause of a `SELECT` query
    * Exclusive lock on the predicate in a `WHERE` clause of any `UPDATE/INSERT/DELETE` query
  * Key-Value locks
    * locks that cover a single key value
    * virtual keys for non-existent values
  * Gap locks
    * Each txn acquires a key-value lock on the single key it wants to access. Then get a gap lock on the next key gap
    * ![image-20191222134019338](D:\OneDrive\Pictures\Typora\image-20191222134019338.png)
  * Key-Range locks
    * A txn takes locks on ranges in the key space
      * each range is from one key that appears in the relation to the next that appears
      * define locks modes so conflict table will capture commutativity of the operations available
    * locks that cover a key value and the gap to the next key value in a single index
      * virtual keys for artificial values (infinity)
    * next key lock
    * ![image-20191222134941338](D:\OneDrive\Pictures\Typora\image-20191222134941338.png)
    * ![image-20191222134948572](D:\OneDrive\Pictures\Typora\image-20191222134948572.png)
  * Hierarchical locking
    * allow for a txn to hold wider key-range locks with different locking modes
      * reduce # of visits to lock manager
    * ![image-20191222140256314](D:\OneDrive\Pictures\Typora\image-20191222140256314.png)
    * predicate locking without complications





## OLTP Indexes

* T-Tree
  * based on AVL tree
  * instead of storing keys in nodes -> store pointers to their original values
  * ![image-20191222144342596](D:\OneDrive\Pictures\Typora\image-20191222144342596.png)
  * ![image-20191222144351774](D:\OneDrive\Pictures\Typora\image-20191222144351774.png)
  * Advantages
    * less memory (doesn't store keys inside of each node)
    * inner nodes contain key/value pairs (like B-tree)
  * Disadvantages
    * difficult to rebalance
    * difficult to implement safe concurrent access
    * have to chase pointers when scanning ranges or performing binary search inside of a node
* Skiplist
  * multiple levels of linked list with extra pointers that skip over intermediate nodes
    * lowest level: sorted, singly linked list of all keys
    * 2nd: every other
    * 3rd: every fourth
  * flip a coin to decide how many levels to add the new key into $O(\log n)$
  * advantages
    * less memory than typical B+ tree (if not include reverse pointers)
    * insertion/deletion don't require rebalancing
    * concurrent skip list using only CAS instructions
      * only support links in one direction
      * never fail operations (retry)
      * ![image-20191222150136367](D:\OneDrive\Pictures\Typora\image-20191222150136367.png)
  * delete:
    * first logically remove a key from the index by setting a flag to tell threads to ignore
    * then physically remove once we know no other thread is holding the reference
      * CAS to update predecessor's pointer
    * ![image-20191222150254061](D:\OneDrive\Pictures\Typora\image-20191222150254061.png)
  * CAS limitations
    * no reverse pointers in a latch-free concurrent skip list
    * no latch-free B+tree
* Bw-Tree
  * latch-free B+Tree index
  * Deltas
    * no updates in place
    * reduces cache invalidation
    * ![image-20191222153234082](D:\OneDrive\Pictures\Typora\image-20191222153234082.png)
    * ![image-20191222153253145](D:\OneDrive\Pictures\Typora\image-20191222153253145.png)
    * ![image-20191222153318826](D:\OneDrive\Pictures\Typora\image-20191222153318826.png)
  * Mapping Table
    * allow for CAS of physical locations of pages
    * ![image-20191222152608210](D:\OneDrive\Pictures\Typora\image-20191222152608210.png)
  * Garbage collection
    * operations tagged with an epoch (epoch-based GC [[C: Yak]])
      * each epoch tracks the threads that are part of it, and the objects that can be reclaimed
      * thread joins an epoch prior to each operation and post objects that can be reclaimed for the current epoch (not necessarily the one joined)
    * garbage for an epoch reclaimed only when all threads have exited the epoch
    * Split Delta Record
      * Mark that a subset of the base page's key range is now located at another page
      * logical pointer to the new page
    * Separator Delta Record
      * provide a shortcut in the modified page's parent on what ranges to find the new page
    * ![image-20191222160609444](D:\OneDrive\Pictures\Typora\image-20191222160609444.png)
    * CMU open Bw-Tree
      * Pre-allocated delta records
        * store the delta chain directly inside of a page
        * avoids small object allocation/list traversal
        * ![image-20191222160703600](D:\OneDrive\Pictures\Typora\image-20191222160703600.png)
      * Mapping Table Expansion
        * fastest associative data structure -> plain array
        * allocating full array for each index is wasteful
        * virtual memory to allocate the entire array without backing it with physical memory
* reference counting -> cache coherence traffic overhead
* epoch GC: global epoch counter that is periodically updated
  * keep track of what threads enter the index during an epoch & when they leave
  * mark current epoch of a node when it is marked for deletion
  * known as Read-Copy-Update (RCU) in Linux [[Q: ?? RCU is based on preempt_disable & every CPU run once grace period]]
* memory pools
* non-unique indexes
  * duplicate keys: same node layout but store duplicated keys multiple times
    * ![image-20191222162822004](D:\OneDrive\Pictures\Typora\image-20191222162822004.png)
  * value lists: store each key only once, maintain a linked list of unique values
    * ![image-20191222162829244](D:\OneDrive\Pictures\Typora\image-20191222162829244.png)
* variable length keys
  * pointers: pointer to tuple attributes
  * variable length nodes
  * padding: key to max length of the key type
  * key map/indirection: embed an array of pointers that map to the key + value list within the node
    * ![image-20191222162927252](D:\OneDrive\Pictures\Typora\image-20191222162927252.png)
* prefix compression: sorted key in the same leaf node are likely to have the same prefix
* suffix truncation: keys in the inner nodes are only used to direct traffic. only store a minimum prefix needed to correctly route probes into the index
* Trie Index: digital search tree / prefix tree
  * Use a digital representation of keys to examine prefixes oneby-one instead of comparing entire key
  * shape only depends on key space & lengths
    * insertion order independent
    * don't need rebalancing
  * $O(k)$ complexity where $k$ is length
  * key span: # of bits that each partial key / digit represents
    * fan-out of each node + physical height of the tree
  * ![image-20191222163558290](D:\OneDrive\Pictures\Typora\image-20191222163558290.png)
* Radix Tree: Patricia Tree
  * omit all nodes with only a single child
  * ![image-20191222163604123](D:\OneDrive\Pictures\Typora\image-20191222163604123.png)
* Judy Arrays (HP)
  * variant of a 256-way radix tree, adaptive node representation
  * Judy1: bit array that maps integer keys to true/false
  * JudyL: map integer keys to integer values
  * JudySL: map variable-length keys to integer values
  * don't store metadata about node its header (no additional cache miss)
  * pack metadata about a node in 128-bit Judy Pointer stored in its parent node
    * node type / population count / child key prefix (value if 1 child below) / 64-bit child pointer
  * node type
    * each node stores up 256 digits
    * Linear node: sparse population
      * store sorted list of partial prefixes up to 2 cache lines
      * store separate array of pointers to child ordered according to prefix sorted
      * ![image-20191222163944665](D:\OneDrive\Pictures\Typora\image-20191222163944665.png)
    * Bitmap node: typical population
      * 256-bit map to mark whether a prefix is present in node
      * Bitmap is divided into eight segments, each with a pointer to a sub-array with pointers to child nodes
      * ![image-20191222164059097](D:\OneDrive\Pictures\Typora\image-20191222164059097.png)
    * Uncompressed node: dense population
* Adaptive Radix Tree (ART) (HyPer)
  * 256-way radix tree supports different node types based on its population
  * store metadata about each node in its header
  * ![image-20191222164208817](D:\OneDrive\Pictures\Typora\image-20191222164208817.png)
  * inner node types
    * ![image-20191222164226001](D:\OneDrive\Pictures\Typora\image-20191222164226001.png)
    * ![image-20191222164245458](D:\OneDrive\Pictures\Typora\image-20191222164245458.png)
    * ![image-20191222164254306](D:\OneDrive\Pictures\Typora\image-20191222164254306.png)
  * binary comparable digits for a radix tree
    * unsigned integer: Byte order must be flipped for little endian machines
    * signed integer: Flip two’s-complement so that negative numbers are smaller than positive
    * floats:  Classify into group (neg vs. pos, normalized vs. denormalized), then store as unsigned integer
    * compound: transform each attribute separately
    * ![image-20191222164405641](D:\OneDrive\Pictures\Typora\image-20191222164405641.png)
  * not latch-free
  * optimistic latch coupling
    * optimistic crabbing scheme where writers are not blocked on readers
    * every node has a version number (counter)
      * Writers increment counter when they acquire latch
      * Readers proceed if a node’s latch is available but then do not acquire it
      * It then checks whether the latch’s counter has changed from when it checked the latch
    * rely on epoch GC to ensure pointers valid
    * ![image-20191222164639526](D:\OneDrive\Pictures\Typora\image-20191222164639526.png)
  * read-optimized write exclusion
    * Each node includes an exclusive latch that blocks only other writers and not readers
      * Readers proceed without checking versions or latches
      * Every writer must ensure that reads are always consistent
    * Requires fundamental changes to how threads make modifications to the data structure
      * Creating new nodes means that we have to atomically update pointers from other nodes (see Bw-Tree)
* MassTree
  * ![image-20191222164813646](D:\OneDrive\Pictures\Typora\image-20191222164813646.png) 





## Storage Models & Data Layout

* ![image-20191223004209118](D:\OneDrive\Pictures\Typora\image-20191223004209118.png)
* ![image-20191223004424005](D:\OneDrive\Pictures\Typora\image-20191223004424005.png)
* data layout
  * ![image-20191223140443415](D:\OneDrive\Pictures\Typora\image-20191223140443415.png)
* variable-length fields
  * ![image-20191223140526292](D:\OneDrive\Pictures\Typora\image-20191223140526292.png)
* null data types
  * special values: `NULL` by `INT32_MIN`
  * null column bitmap header: store a bitmap in the tuple header that specifies what attributes are null
  * per attribute null flag: store a flag marks that a value is null
    * have to use more than 1 bit (word alignment)
  * ![image-20191223140646203](D:\OneDrive\Pictures\Typora\image-20191223140646203.png)
* word-aligned tuples
  * All attributes in a tuple must be word aligned to enable the CPU to access it without any unexpected behavior or additional work (SIGBUS)
  * ![image-20191223140732330](D:\OneDrive\Pictures\Typora\image-20191223140732330.png)
  * perform extra readers: execute two reads to load the appropriate parts of the data word and reassemble them
  * random readers: read some unexpected combination of bytes assembled into a 64-bit word
  * reject: throw an exception
  * padding: Add empty bits after attributes to ensure that tuple is word aligned (C)
  * reordering: Switch the order of attributes in the tuples' physical layout to make sure they are aligned (Rust)
* Storage models
  * N-ary Storage Model (NSM)
    * The DBMS stores all of the attributes for a single tuple contiguously
    * ideal for OLTP wordloads
      * txns tend to operate only on individual entity and insert-heavy workloads
    * tuple-at-a-time iterator model
    * Heap-Organized Tables: tuples stored in blocks called a heap
    * Index-Organized Tables: tuples stored in the primary key index itself
      * not quite the same as a clustered index
    * Advantages
      * Fast inserts/updates/deletes
      * good for queries that need the entire tuple
      * index-oriented physical storage
    * Disadvantages
      * not good for scanning large portions of the table and/or a subset of the attributes
      * [[N: bad for subset attr scanning]]
  * Decomposition Storage Model (DSM)
    * The DBMS stores a single attribute for all tuples contiguously in a block of data
    * ideal for OLAP workloads
      * read-only queries perform large scans over a subset of the table's attributes
    * vector-at-a-time iterator model
    * ![image-20191223141712443](D:\OneDrive\Pictures\Typora\image-20191223141712443.png)
    * fixed-length offsets: each value is the same length for an attribute
    * embedded tuple ids: each value is stored id in a column
      * ![image-20191223145006986](D:\OneDrive\Pictures\Typora\image-20191223145006986.png)
    * query processing
      * late materialization
      * columnar compression
      * block/vectorized processing model
    * advantages
      * Reduces the amount wasted work because the DBMS only reads the data that it needs
      * better compression
    * disadvantages
      * Slow for point queries, inserts, updates, and deletes because of tuple splitting/stitching
  * Hybrid Storage Model
    * Single logical database instance that uses different storage models for hot and cold data
    * data obeys generational-hypothesis
    * Store new data in NSM for fast OLTP 
    * Migrate data to DSM for more efficient OLAP
    * Separate Execution Engines
      * Use separate execution engines that are optimized for either NSM or DSM databases
      * Run separate “internal” DBMSs that each only operate on DSM or NSM data
        * Need to combine query results from both engines to appear as a single logical database to the application
        * Have to use a synchronization method (e.g., 2PC) if a txn spans execution engines
        * Fractured Mirrors (Oracle/IBM)
          * Store a second copy of the database in a DSM layout that is automatically updated
            * All updates are first entered in NSM then eventually copied into DSM mirror
          * ![image-20191223151220595](D:\OneDrive\Pictures\Typora\image-20191223151220595.png)
        * Delta Store (SAP HANA)
          * Stage updates to the database in an NSM table
          * A background thread migrates updates from delta store and applies them to DSM data
          * ![image-20191223151326090](D:\OneDrive\Pictures\Typora\image-20191223151326090.png)
    * Single, Flexible Architecture
      * Use single execution engine that is able to efficiently operate on both NSM and DSM databases
    * Categorizing data
      * Manual Approach: DBA specifies what tables should be stored as DSM
      * Off-line Approach: DBMS monitors access logs offline and then makes decision about what data to move to DSM
      * On-line Approach: DBMS tracks access patterns at runtime and then makes decision about what data to move to DSM
    * Peloton adaptive storage
      * Employ a single execution engine architecture that is able to operate on both NSM and DSM data
        * no need for 2 copies of the database
        * no need to sync multiple database segments
      * DBMS can still use delta-store approach with single-engine architecture
      * ![image-20191223151612811](D:\OneDrive\Pictures\Typora\image-20191223151612811.png)
      * Tile architecture
        * Introduce an indirection layer that abstracts the true layout of tuples from query operators
        * ![image-20191223151644481](D:\OneDrive\Pictures\Typora\image-20191223151644481.png)
        * ![image-20191223151926308](D:\OneDrive\Pictures\Typora\image-20191223151926308.png)
        * 

* System Catalogs: database's catalog
  * wrap object abstraction around tuples
  * specialized code for "bootstrapping" catalog tables
  * The entire DBMS should be aware of transactions in order to automatically provide ACID guarantees for DDL commands and concurrent txns
* ![image-20191223152109382](D:\OneDrive\Pictures\Typora\image-20191223152109382.png)
* ![image-20191223152117074](D:\OneDrive\Pictures\Typora\image-20191223152117074.png)
* ![image-20191223152134978](D:\OneDrive\Pictures\Typora\image-20191223152134978.png)
* hybrid storage model -> significant engineering overhead
  * delta-version storage + column store is almost equivalent





## Database Compression

* I/O is the main bottleneck
* in-memory tradeoff: speed vs. compression ratio
* real-world data sets tend to have highly skewed distributions for attribute values
  * Zipfian distribution of the Brown Corpus
* real-world data sets tend to have high correlation between attributes of the same tuples
  * zipcode to city, order data to ship date
* database compression
  * produce fixed-length values
    * exception: var-length data stored in separate pool
  * postpone decompression for as long as possible during query execution
    * late materialization
  * lossless scheme
* data skipping
  * Approximate Queries (Lossy)
    * Execute queries on a sampled subset of the entire table to produce approximate results
    * BlinkDB/SnappyData/XDB/Oracle (2017)
  * Zone Maps  (Lossless)
    * Pre-compute columnar aggregations per block that allow the DBMS to check whether queries need to access it
    * Oracle/Vertica/MemSQL/Netezza
    * ![image-20191223153137317](D:\OneDrive\Pictures\Typora\image-20191223153137317.png)
* Compression granularity
  * block-level: compress a block of tuples for the same table
  * tuple-level: compress the contents of the entire tuple (NSM-only)
  * attribute-level: compress a single attribute value within one tuple
    * can target multiple attributes for the same tuple
  * column-level: compress multiple values for one or more attributes stored for multiple tuples (DSM-only)
* Naive Compression
  * compress data using a general purpose algorithm
  * scope of compression is only based on the data provided as input
    * LZO(1996)/LZ4(2011)/Snappy(2011)/Brotli(2013)/Oracle OZIP(2014)/Zstd(2015)
    * computational overhead
    * compress vs.  decompress speed
* MySQL InnoDB Compression
  * ![image-20191223153823572](D:\OneDrive\Pictures\Typora\image-20191223153823572.png)
* We can perform exact-match comparisons and natural joins on compressed data if predicates and data are compressed the same way
  * ![image-20191223153930231](D:\OneDrive\Pictures\Typora\image-20191223153930231.png)
* Columnar Compression
  * Null Suppression: consecutive zeros/blanks in the data are replaced with a description of how many there were and where they existed
    * Oracle's Byte-Aligned Bitmap Codes (BBC)
    * wide table with sparse data
  * Run-Length Encoding: compress runs of the same value in a single column into triplets
    * value of the attribute
    * start position in the column segment
    * \# of elements in the run
    * requires the columns to be sorted intelligently to maximize compression opportunities
    * ![image-20191223154140302](D:\OneDrive\Pictures\Typora\image-20191223154140302.png)
  * Bitmap Encoding: store a separate bitmap for each unique value for a particular attribute where an offset in the vector corresponds to a tuple
    * i-th position in the Bitmap corresponds to the i-th tuple in the table
    * segmented into chunks to avoid allocating large blocks of contiguous memory
    * practical if value cardinality is low
    * ![image-20191223154358150](D:\OneDrive\Pictures\Typora\image-20191223154358150.png)
    * Compression
      * General Purpose Compression: standard compression algorithm (e.g. LZ4, Snappy)
        * have to decompress before you can use it to process a query,
        * not useful for in-memory DBMS
      * Byte-Aligned Bitmap Codes: structured run-length encoding compression
    * Oracle Byte-Aligned Bitmap Codes: divide bitmap into chunks that contain different categories of bytes
      * Gap Byte: all the bits are 0s
      * Tail Byte: some bits are 1s
      * encode each chunk that consists of some Gap Bytes followed by some Tail Bytes
        * Gap Bytes: compressed with RLE
        * Tail Bytes: stored uncompressed unless it consists of only 1-byte  / has only 1 non-zero bit
      * ![image-20191223154858500](D:\OneDrive\Pictures\Typora\image-20191223154858500.png)
      * ![image-20191223154915895](D:\OneDrive\Pictures\Typora\image-20191223154915895.png)
    * Oracle BBC is an obsolete format
      * slower than recent alternatives due to excessive branching
      * Word-Aligned Hybrid (WAH) encoding is a patented variation on BBC providing better performance
      * none of these support random access
        * start from beginning & decompress the whole thing
  * Delta Encoding: recording the different between values that follow each other in the same column
    * store base value in-line / in a separate lookup table
    * combined with RLE to get better compression ratios
    * ![image-20191223155209543](D:\OneDrive\Pictures\Typora\image-20191223155209543.png)
  * Incremental Encoding: type of delta encoding whereby common prefixes/suffixes & their length are recorded so that no duplication
    * best with sorted data
    * ![image-20191223155341998](D:\OneDrive\Pictures\Typora\image-20191223155341998.png)
  * Mostly Encoding: when the value for an attribute are "mostly" less than the largest size, store them as a smaller data type
    * ![image-20191223155418390](D:\OneDrive\Pictures\Typora\image-20191223155418390.png)
* Dictionary Compression
  * replace frequent patterns with smaller codes
  * need to support fast encoding/decoding/range queries
  * When to construct the dictionary?
    * All At Once: compute the dictionary for all the tuples at a given timepoint
      * new tuples must use a separate dictionary / recompute
    * Incremental: merge new tuples in with an existing dictionary
      * likely requires re-encoding to existing tuples
  * What is the scope of the dictionary?
    * Block-level: subset of tuples within a single table
      * potentially lower compression ratio
      * add new tuples easily
    * Table-level: construct a dictionary for the entire table
      * better compression ratio
      * expensive to update
    * Multi-Table: either subset / entire tables
      * help with join/set operations
  * What data structure do we use for the dictionary?
    * Array: 1 array of variable length strings, 1 array with pointers that maps to string offsets
      * expensive to update
    * Hash Table
      * fast & compact
      * unable to support range/prefix queries
    * B+Tree
      * slower than hash table, takes more memory
      * support range/prefix queries
      * ![image-20191223160232533](D:\OneDrive\Pictures\Typora\image-20191223160232533.png)
  * What encoding scheme to use for the dictionary?
    * Multi-Attribute Encoding: store entries that span attributes
      * ![image-20191223155931787](D:\OneDrive\Pictures\Typora\image-20191223155931787.png)
    * Encode/Locate: given uncompressed value, convert to compressed form
    * Decode/Extract: given compressed value, convert to uncompressed form
    * Order-Preserving Encoding: support sorting in the same order
      * ![image-20191223160039477](D:\OneDrive\Pictures\Typora\image-20191223160039477.png)
      * ![image-20191223160048486](D:\OneDrive\Pictures\Typora\image-20191223160048486.png)
* Hybrid Indexes: split a single logical index into 2 physical indexes
  * dynamic stage: new data, fast to update (updates + reads)
  * static stage: old data, compressed + read-only (reads)
  * ![image-20191223160403013](D:\OneDrive\Pictures\Typora\image-20191223160403013.png)





## Larger-than-Memory Databases

* Bloom Filter: probabilistic data structure (bitmap) answering set membership queries

  * never false negative
  * sometimes false positive
  * `Insert(x)`: use `k` hash functions to set bits in the filter to 1
  * `Lookup(x)`: check whether the bits are 1 for each hash function
  * ![image-20191223160814234](D:\OneDrive\Pictures\Typora\image-20191223160814234.png)

* Large-than-memory Databases: Allow an in-memory DBMS to store/access data on disk without bringing back all the slow parts of a disk-oriented DBMS

  * in-memory storage: tuple-oriented
  * disk storage: block-oriented

* OLAP

  * OLAP queries generally access the entire table. Thus, there isn’t anything about the workload for the DBMS to exploit that a disk-oriented buffer pool can’t handle
  * ![image-20191223161440109](D:\OneDrive\Pictures\Typora\image-20191223161440109.png)

* OLTP

  * hot/cold portions of the database
  * move cold to disk

* Why not `mmap`?

  * WAL requires that a modified page cannot be written to disk before the log records that made those changes is written
  * no mechanism for asynchronous read-ahead / writing multiple pages concurrently

* OLTP Issues

  * Runtime Operations
    * Cold Data Identification
      * On-line: DBMS monitors txn access patterns & tracks how often tuples are used
        * embed the tracking meta-data directly in tuples
      * Off-line: maintain a tuple access log during txn execution
        * process in background to compute frequencies
  * Eviction Policies
    * Timing
      * Threshold: monitors memory usage, evicting tuples when it reaches a threshold
        * manually move data
      * OS Virtual Memory: in background
    * Evicted Metadata
      * Tombstones: leave the marker that points to the on-disk tuple
        * update indexes to point to the tombstone tuples
        * ![image-20191223162045883](D:\OneDrive\Pictures\Typora\image-20191223162045883.png)
      * Bloom Filters: approximate data structure for each index
        * index + filter for each query
      * OS Virtual Memory
  * Data Retrieval Policies
    * Granularity
      * All Tuples in Block: merge all tuples retrieved from a block regardless of whether they are needed
      * Only Tuples Needed: merge the tuples accessed by a query back into the in-memory table heap
        * additional bookkeeping to track holes
    * Retrieval Mechanism
      * Abort-n-Restart
        * abort the txn that accessed the evicted tuple
        * retrieve the data from disk & merge it into memory with a separate background thread
        * restart the txn when the data is ready
        * cannot guarantee consistency for large queries
      * Synchronous Retrieval
        * stall the txn when it accesses an evicted tuple while the DBMS fetches the data & merges it back into memory
    * Merging
      * Always Merge: retrieved tuples are always put into table heap
      * Merge Only on Updates: retrieved tuples are only merged into table heap if they are used in an `UPDATE` query
        * other tuples put into a temporary buffer
      * Selective Merge: keep track of how often each block is retrieved
        * block's access frequency above threshold -> merge it back into the table heap

* H-Store - Anti-Caching (tuple)

  * On-line Identification 
  * Administrator-defined Threshold 
  * Tombstones 
  * Abort-and-restart Retrieval 
  * Block-level Granularity 
  * Always Merge

* Hekaton - Project Siberia (tuple)

  * Off-line Identification 
  * Administrator-defined Threshold 
  * Bloom Filters 
  * Synchronous Retrieval 
  * Tuple-level Granularity 
  * Always Merge

* EPFL's VoltDB Prototype (tuple)

  * Off-line Identification 
  * OS Virtual Memory 
  * Synchronous Retrieval 
  * Page-level Granularity 
  * Always Merge
  * ![image-20191223162855290](D:\OneDrive\Pictures\Typora\image-20191223162855290.png)

* Apache Geode - Overflow Tables (tuple)

  * On-line Identification 
  * Administrator-defined Threshold 
  * Tombstones (?) 
  * Synchronous Retrieval 
  * Tuple-level Granularity 
  * Merge Only on Update (?)

* LeanStore - Hierarchical Buffer Pool

  * handle both tuples + indexes (unified way to evict cold data from both tables + indexes with low overhead)

  * Hierarchical + Randomized Block Eviction

    * [pointer swizzling](http://www.mathcs.emory.edu/~cheung/Courses/554/Syllabus/2-disks/pointer-swizzling.html) to determine whether a block is evicted or not (swizzling -> convert data to memory pages)

      * > The control blocks containing file pages are put to a hash table according to the file address of the page. We could speed up the access to an individual page by using "pointer swizzling": we could replace the page references on non-leaf index pages by direct pointers to the page, if it exists in the buf_pool. We could make a separate hash table where we could chain all the page references in non-leaf pages residing in the buf_pool, using the page reference as the hash key, and at the time of reading of a page update the pointers accordingly. Drawbacks of this solution are added complexity and, possibly, extra space required on non-leaf pages for memory pointers. A simpler solution is just to speed up the hash table mechanism in the database, using tables whose size is a power of 2.

      * switch the contents of pointers based on whether the target object resides in memory/disk

        * 1st bit in address to tell what kind of address it is
        * if there only 1 pointer to the object

      * ![image-20191223163236041](D:\OneDrive\Pictures\Typora\image-20191223163236041.png)

      * ![image-20191223163241177](D:\OneDrive\Pictures\Typora\image-20191223163241177.png)

  * Replacement Strategy: randomly select blocks for eviction

    * don't have to update metadata every time a txn accesses a hot tuple
    * unswizzle their pointer, but leave in memory
      * add to a FIFO queue of blocks staged for eviction
      * page access again? remove from queue
      * otherwise, evict pages when reaching front of queue

  * Block Hierarchy

    * blocks are organized in a tree hierarchy
      * each page has only 1 parent, only 1 single pointer
    * DBMS can only evict a page if its children are also evicted
      * avoids the problem of evicting pages that contain swizzled pointers
      * page selected but has in-memory children, then it automatically switches to select one of its children
    * ![image-20191223164101401](D:\OneDrive\Pictures\Typora\image-20191223164101401.png)
    * ![image-20191223164105489](D:\OneDrive\Pictures\Typora\image-20191223164105489.png)
    * ![image-20191223164110546](D:\OneDrive\Pictures\Typora\image-20191223164110546.png)

* MemSQL - Columnar Tables

  * Administrator manually declares a table as a distinct disk-resident columnar table
    * separate logical table to the application
    * `mmap` to manage buffer pool
    * pre-computed aggregates per block always in memory
  * Manual Identification 
  * No Evicted Metadata is needed.
  * Synchronous Retrieval 
  * Always Merge

* working around the block-oriented access and slowness of secondary storage

  * none of these techniques handle index memory

* fast & cheap byte-addressable NVM make this lecture unnecessary



## Recovery Protocols

* consistency, atomicity, durability
* recovery algorithms have 2 parts
  * actions during normal txn processing is ensured that the DBMS can recover from a failure
  * actions after a failure to recover the database to a state ensures ACD
* new hardware: battery-backed DRAM / NVM
* in-memory DBMS recovery
  * less work than disk-oriented DBMS
  * no need to track dirty pages in case of crash during
  * no need to store undo records (only need redo)
  * no need to log changes to indexes
  * [[Q: what about larger-than-memory DBMS?]]
  * problem: slow sync time of non-volatile storage ([[C: cache invalidation?]])
* Logging Schemes
  * Physical Logging: record the changes made to a specific record in the DB (original + after value)
  * Logical Logging: high-level operations executed by txns
    * `UPDATE`/`DELETE`/`INSERT`
    * less data in each log record
    * difficult to implement recovery if having concurrent txns
      * Harder to determine which parts of the database may have been modified by a query before crash if running at lower isolation level
      * Takes longer to recover because you must re-execute every txn all over again
* Silo: in-memory OLTP DBMS from Harvard/MIT
  * single-versioned OCC with epoch-based GC
  * Eddie Kohler, Masstree
  * SiloR: physical logging + checkpoints
    * parallelize all aspects of logging/checkpoints/recovery
    * logging protocol
      * assume 1 storage device per CPU socket
      * 1 logger thread per device
        * maintain a pool of log buffers given to its worker threads
        * worker buffer full? give back to logger thread to flush to disk, attempts to acquire a new one
          * stall for available buffers
          * [[Q: why is this scheme durable?]]
      * worker threads grouped per CPU socket
      * As the worker executes a txn, it creates new log records that contain the values that were written to the database (i.e., REDO)
      * Log files
        * The logger threads write buffers out to files:
          * After 100 epochs, it creates a new file
          * The old file is renamed with a marker indicating the max epoch of records that it contains
        * Log record format
          * Id of the txn that modified the record (TID)
          * A set of value log triplets (Table, Key, Value)
          * The value can be a list of attribute + value pairs
          * ![image-20191224143400295](D:\OneDrive\Pictures\Typora\image-20191224143400295.png)
      * ![image-20191224143506072](D:\OneDrive\Pictures\Typora\image-20191224143506072.png)
      * ![image-20191224143516137](D:\OneDrive\Pictures\Typora\image-20191224143516137.png)
      * Persistent Epoch: a special logger thread keeps track of the current persistent epoch (`pepoch`)
        * special log files that maintain the highest epoch that is durable across all loggers
        * Txns that executed in epoch `e` can only release their results when the `pepoch` is durable to non-volatile storage
      * ![image-20191224143703016](D:\OneDrive\Pictures\Typora\image-20191224143703016.png)
    * recovery protocol
      * Phase 1: Load Last Checkpoint
        * rebuild indexes
      * Phase 2: Log Replay
        * process logs in reverse order to reconcile the last version of each tuple
          * check the `pepoch` file to determine the most recent persistent epoch
            * any log record from after the `pepoch` is ignored
          * Value logging is able to be replayed in any order. 
          * For each log record, the thread checks to see whether the tuple already exists. 
          * If it does not, then it is created with the value. 
          * If it does, then the tuple’s value is overwritten only if the log TID is newer than tuple’s TID.
        * the txn ids generated at runtime to determine serial order on recovery
    
    

* Usually slowest part of the txn is waiting for the DBMS to flush the log records to disk
* Group Commit: batch together log records from multiple txns, flush together with single `fsync`
  * logs are flushed either after a timeout / when buffer full
  * IBM IMS FastPath in the 1980s
  * amortize the cost of I/O over several txns
* Early Lock Release
  * A txn's locks can be released before its commit record is written to disk if it does not result results to the client before becoming durable
    * [[C: RAW, WAR, WAW conflicts]]
  * Other txns that read data updated by a pre-committed txn become dependent on it, and also have to wait for their predecessor's log records to reach disk
    * [[C: precise interrupt]]
* In-memory Checkpoints
  * Do not slow down regular txn processing.
  * Do not introduce unacceptable latency spikes.
  * Do not require excessive memory overhead.
  * Consistent Checkpoints: represent a consistent snapshot of the database at some timepoint
    * no uncommitted changes
    * no additional processing during recovery
  * Fuzzy Checkpoints: could contain records updated from unfinished transactions
    * additional processing
  * Checkpoint Mechanism
    * DIY: creating a snapshot of the database in memory
      * leverage on multi-versioned storage
    * OS Fork Snapshots: fork the process & have the child process write out the contents of the database to disk
      * copy everything in memory
      * extra work: remove uncommitted changes
      * HyPer: forking DBMS process
        * child process contains a consistent checkpoint if there are not active txns
        * otherwise, in-memory undo log to roll back txns in the child process
      * H-Store
  * Checkpoint Contents
    * Complete Checkpoint: write out every tuple in every table regardless of whether were modified since last checkpoint
    * Delta Checkpoint: write out only the tuples that were modified since the last checkpoint
      * merge checkpoints in the background (LSM-Tree?)
  * Frequency
    * Time-based: wait for a fixed period of time after the last checkpoint completed before starting a new one
    * Log File Size Threshold: after a certain amount of data been written to the log file
    * On Shutdown (Mandatory): DBA instruction
  * ![image-20191224195851915](D:\OneDrive\Pictures\Typora\image-20191224195851915.png)
* Fast Restart - Facebook Scuba
  * decouple the in-memory database lifetime from the process lifetime
  * storing the database shared memory, DBMS restart, contents survive
  * Scuba: distributed, in-memory DBMS for time-series event analysis & anomaly detection
    * Heterogeneous Architecture
      * Leaf Node: execute scans/filters on in-memory data
      * Aggregator Nodes: combine results from leaf nodes
    * ![image-20191224200131989](D:\OneDrive\Pictures\Typora\image-20191224200131989.png)
  * Shared Memory Restarts
    * Shared Memory Heaps
      * All data is allocated in SM during normal operations
      * Have to use a custom allocator to subdivide memory segments for thread safety and scalability
      * Cannot use lazy allocation of backing pages with SM ([[C: Scuba paper]])
    * Copy on Shutdown
      * All data is allocated in local memory during normal operations
      * On shutdown, copy data from heap to SM
  * When the admin initiates restart command, the node halts ingesting updates
  * DBMS starts copying data from heap memory to shared memory
    * Delete blocks in heap once they are in SM
  * Once snapshot finishes, the DBMS restarts
    * On start up, check to see whether the there is a valid database in SM to copy into its heap
    * Otherwise, the DBMS restarts from disk
* Physical logging is a general purpose approach that supports all concurrency control schemes
* Copy-on-update checkpoints are the way to go especially if you are using MVCC
* Non-volatile memory, like 3DXPoint?



## Networking

* ![image-20191224200654942](D:\OneDrive\Pictures\Typora\image-20191224200654942.png)
* Database Access through an API
  * Direct Access (DBMS-specific)
  * Open Database Connectivity (ODBC)
    * Microsoft & Simba,  1990s
    * Standard API independent of DBMS & OS
    * device driver model: driver encapsulate the logic needed to convert a standard set of commands into the DBMS-specific calls
  * Java Database Connectivity (JDBC)
    * Sun Microsystem 1997
    * JDBC-ODBC Bridge: JDBC method calls into ODBC function calls
    * Native-API Driver: JDBC method calls into native calls of the target DBMS API
    * Network-Protocol Driver: middleware that converts JDBC calls into a vendor-specific DBMS protocol
    * Database-Protocol Driver: pure java implementation that converts JDBC calls into a vendor-specific DBMS protocol
* Database Networking Protocols: wire protocol over TCP/IP
  * connections/authentication, SSL handshake
  * query
  * execute query, serialize results
  * ![image-20191224201609968](D:\OneDrive\Pictures\Typora\image-20191224201609968.png)
* Protocol Design Space
  * Row vs. Column Layout
    * ODBC/JDBC: inherently row-oriented APIs
    * send data in vectors (batch of rows in a column-oriented layout)
  * Compression
    * Naive Compression
    * Columnar-Specific Encoding
  * Data Serialization
    * Binary Encoding: endianness problem
      * ProtoBuf/Thrift/CapnProto/FlatBuffer/Avro
    * Text Encoding
  * String Handling
    * Null Termination `\0`
    * Length-Prefixes
    * Fixed Width
* OS TCP/IP stack is slow...
  * context switches / interrupts
  * data copying
  * latches in the kernel
* Kernel Bypass Methods
  * Data Plane Development Kit (DPDK)
    * Set of libraries that allows programs to access NIC directly. Treat the NIC as a bare metal device
    * no data copying
    * no syscalls
    * ScyllaDB
  * Remote Direct Memory Access (RDMA)
    * Read and write memory directly on a remote host without going through OS
      * The client needs to know the correct address of the data that it wants to access
      * The server is unaware that memory is being accessed remotely (i.e., no callbacks)
    * Oracle RAC, Microsoft FaRM



## Scheduling

* query plan: comprised of operators
* operator instance: invocation of an operator on some segment of data
* task: execution of a sequence of 1+ operator instances
* where/when/how?: how many tasks, how many CPU cores, what CPU, where task stores output
* Process Model: how the system is architected to support concurrent requests from a multi-use application
  * worker: executing tasks on behalf of the clients & returning the results
  * Process per DBMS Worker: each worker is a separate OS process
    * OS scheduler
    * shared-memory for global data structure
    * process crash doesn't take down entire system
    * IBM DB2, Postgres, Oracle
  * Process Pool: a worker uses any process free in a pool
    * OS scheduler
    * shared-memory
    * bad for CPU cache locality
    * IBM DB2, Postgres (2015)
  * Thread per DBMS Worker: single process with multiple worker threads
    * own scheduling
    * optional dispatcher thread
    * thread crash kills entire system
    * IBM DB2, MSSQL, MySQL, Oracle (2014)
    * less overhead per context switch
* Data Placement
  * UMA vs. NUMA
  * ![image-20191224223453466](D:\OneDrive\Pictures\Typora\image-20191224223453466.png)
  * partition memory for a database, assign each to a CPU
  * [`move_pages`](http://man7.org/linux/man-pages/man2/move_pages.2.html)
  * Memory Allocation
    * page fault -> physical memory location in a NUMA system?
    * Interleaving: distributed allocated memory uniformly across CPUs
    * First-Touch: at the CPU of the thread that accessed the memory location that caused the page fault
  * ![image-20191224223731411](D:\OneDrive\Pictures\Typora\image-20191224223731411.png)
* Scheduling
  * Static Scheduling: The DBMS decides how many threads to use to execute the query when it generates the plan
    * \# of tasks as the \# of cores
  * Morsel-driven Scheduling: Dynamic scheduling of tasks that operate over horizontal partitions called “morsels” that are distributed across cores
    * 1 worker per core
    * pull-based task assignment
    * round-robin data placement
    * support parallel/NUMA-aware operator
* HyPer
  * no separate dispatcher thread
  * cooperative scheduling for each query plan using a single task queue
    * Each worker tries to select tasks that will execute on morsels that are local to it
    * If there are no local tasks, then the worker just pulls the next task from the global work queue
  * ![image-20191224224011647](D:\OneDrive\Pictures\Typora\image-20191224224011647.png)
  * work stealing to solve stragglers
  * lock-free hash table to maintain the global work queues
* SAP HANA
  * NUMA-aware scheduler
    * pull-based scheduling with multiple worker threads organized into groups (pools)
    * each CPU have multiple groups
    * each group has a soft + hard priority queue (+ work stealing from soft queues)
  * Uses a separate “watchdog” thread to check whether groups are saturated and can reassign tasks dynamically
  * Thread Groups
    * Working: actively executing a task
    * Inactive: blocked inside of the kernel due to a latch
    * Free: sleeps for a little, wake up to see whether there is a new task to execute
    * Parked: like Free, but doesn't wake up on its own
  * Can dynamically adjust thread pinning based on whether a task is CPU or memory bound
  * Found that work stealing was not as beneficial for systems with a larger number of sockets
  * Using thread groups allows cores to execute other tasks instead of just only queries
  * ![image-20191224224414587](D:\OneDrive\Pictures\Typora\image-20191224224414587.png)
* Flow control
  * Throttling: delay the response to clients to increase the amount of time between requests
    * assume synchronous submission scheme
  * Admission Control: abort new requests when the system believes that it will not have enough resources to execute
* ![image-20191224225400698](D:\OneDrive\Pictures\Typora\image-20191224225400698.png)



## Query Execution & Processing

* Optimizing goals
  * Reduce Instruction Count
  * Reduce CPI
    * cache misses, stalls due to memory load stores
    * branch prediction
    * dependencies
  * Parallelize Execution
    * multiple threads
* MonetDB/X100
  * Vectorwise (Actian) -> Vector -> Avalance
* Selection Scans
  * ![image-20191225101716156](D:\OneDrive\Pictures\Typora\image-20191225101716156.png)
* Excessive Instructions
  * DBMS check a value type before it performs any operations on that type
    * giant switch statements -> more branches to predict
  * [[C: gcc-label as value]]
* Processing Model
  * Iterator/Volcano/Pipeline Model: each query plan operator implements a `next` function
    * on each invocation, the operator returns either a single tuple / null marker
    * loop to fetch all
    * ![image-20191225101940926](D:\OneDrive\Pictures\Typora\image-20191225101940926.png)
    * allow for tuple pipelining
    * ![image-20191225102001029](D:\OneDrive\Pictures\Typora\image-20191225102001029.png)
  * Materialization Model: each operator processes its input all at once, emit its output all at once
    * allows for pushing down hints into to avoid scanning unnecessary tuples
    * send either a materialized row / a single column
    * output: whole tuples (NSM) / subsets of columns (DSM)
    * ![image-20191225102109095](D:\OneDrive\Pictures\Typora\image-20191225102109095.png)
    * better for OLTP (small subset of queries): lower execution/coordination overhead, fewer function calls
    * bad for OLAP
    * ![image-20191225102142844](D:\OneDrive\Pictures\Typora\image-20191225102142844.png)
  * Vectorized/Batch Model: like iterator model, emits a batch of tuples
    * ![image-20191225102217293](D:\OneDrive\Pictures\Typora\image-20191225102217293.png)
    * ideal for OLAP
    * allows for SIMD instructions
* Plan Processing Direction
  * Top-to-Bottom: start with the root, pull data up from its children
  * Bottom-to-Top: start with leaf, push data to parents
    * allow for tighter control of caches/registers in pipelines
    * HyPer, Peloton ROF
* Intra-query Parallelism
  * multiple queries to execute simultaneously
  * provide isolation though
  * Intra-Operator (Horizontal): operators are decomposed into independent instances that perform the same function on different subsets of data
    * `exchange` operator into query plan to coalesce ([[C: `shuffle` in Spark]])
    * ![image-20191225125305757](D:\OneDrive\Pictures\Typora\image-20191225125305757.png)
  * Inter-Operator (Vertical): operations are overlapped in order to pipeline data from one stage to the next without materialization
    * pipelined parallelism
    * not popular in traditional relational DBMS
      * not all operators can emit output until they have seen all of the tuples from their children
      * more common in stream processing systems
      * ![image-20191225125419676](D:\OneDrive\Pictures\Typora\image-20191225125419676.png)
    * [[C: `map` in Spark]]
    * ![image-20191225125428878](D:\OneDrive\Pictures\Typora\image-20191225125428878.png)
* Worker Allocation
  * One Worker per Core: Each core is assigned one thread that is pinned to that core in the OS
    * `sched_setaffinity`
  * Multiple Workers per Core: Use a pool of workers per core (or per socket)
    * take advantage of blocking time
* Task Assignment
  * Push: a centralized dispatcher assigns tasks to workers & monitor their progress
  * Pull: worker pull the next task from a queue, process, return results





## Server-side Logic Execution

* conversational API vs. embedded logic

* User-Defined Function (UDF)

  * ```sql
    CREATE FUNCTION cust_level(@ckey int)
    RETURNS char(10) AS
    BEGIN
        DECLARE @total float;
        DECLARE @level char(10);
        SELECT @total = SUM(o_totalprice)
    	    FROM orders WHERE o_custkey=@ckey;
        IF (@total > 1000000)
        	SET @level = 'Platinum';
        ELSE
        	SET @level = 'Regular';
        RETURN @level;
    END
    ```

  * encourage modularity & code reuse

  * fewer network round-trips between application & DBMS

  * query optimizer treat UDFs as black boxes

  * difficult to parallelize UDFs due to correlated queries inside of them

  * complex UDFs in `SELECT/WHERE` clauses force DBMS to execute iteratively

    * RBAR (Row By Agonizing Row)
    * worse if UDF invokes queries due to implicit joins

  * ![image-20191225130141761](D:\OneDrive\Pictures\Typora\image-20191225130141761.png)

* Sub-queries

  * nested sub-queries as functions take parameters & return a single/set of values
  * rewrite to de-correlate and/or flatten
    * ![image-20191225130519532](D:\OneDrive\Pictures\Typora\image-20191225130519532.png)
  * decompose nested query, store result to temporary table

* Lateral Join

  * a lateral inner subquery can refer to fields in rows of the table reference to determine which nrows to return
    * allow for sub-queries in `FROM` clause
  * DBMS iterates each row in the table reference, evaluate the inner sub-query for each row
    * the rows returned by the inner sub-query added to the result of the join with the outer query
  * [sub-query vs. lateral join](https://stackoverflow.com/questions/28550679/what-is-the-difference-between-lateral-and-a-subquery-in-postgresql)

* Froid

  * automatically convert UDFs into relational expressions inlined as sub-queries
  * conversion during the rewrite phase (no need to change the cost-base optimizer)
  * Step 1: Transform Statements
    * ![image-20191225132655447](D:\OneDrive\Pictures\Typora\image-20191225132655447.png)
  * Step 2: Break UDF into Regions
    * ![image-20191225132736564](D:\OneDrive\Pictures\Typora\image-20191225132736564.png)
  * Step 3: Merge Expressions
    * ![image-20191225132750307](D:\OneDrive\Pictures\Typora\image-20191225132750307.png)
  * Step 4: Inline UDF Expression into Query
    * ![image-20191225132800396](D:\OneDrive\Pictures\Typora\image-20191225132800396.png)
  * Step 5: Run Through Query Optimizer
    * ![image-20191225132818019](D:\OneDrive\Pictures\Typora\image-20191225132818019.png)
    * ![image-20191225132840611](D:\OneDrive\Pictures\Typora\image-20191225132840611.png)
  * Supported Operations
    * T-SQL Syntax
    * `DECLARE`, `SET` (variable declaration, assignment)
    * `SELECT` (SQL query, assignment)
    * `IF`/`ELSE`/`ELSE IF` (arbitrary nesting)
    * `RETURN` (multiple occurrences)
    * `EXISTS`/`NOT EXISTS`/`ISNULL`/`IN`/...
    * UDF Invocation (nested/recursive with configurable depth)
    * all SQL datatypes

* Another solution: compile UDF into machine code

  * doesn't solve optimizer's cost model problem



## Parallel Join Algorithms

* ![image-20191225134816357](D:\OneDrive\Pictures\Typora\image-20191225134816357.png)
* ![image-20191225134822560](D:\OneDrive\Pictures\Typora\image-20191225134822560.png)
* Join Algorithms Goals
  * Minimize synchronization (no latches)
  * Minimize CPU cache miss (locality)
    * Non-Random Access (Scan): clustering to a cache line
    * Random Access (Lookups): partition data to fit in cache + TLB
* Hash Join (R $\bowtie$ S)
  * Phase 1: Partition (optional)
    * divide the tuples of `R` & `S` into sets using a hash on the join key
    * hybrid hash join
    * NSM: entire tuples / subset of attributes
    * DSM: columns needed for the join + offset
    * Non-Blocking Partitioning
      * only scan the input relation once
      * produce output incrementally 
      * Shared Partitions: single global set of partitions that all threads update
        * have to use a latch to sync
        * ![image-20191225140430515](D:\OneDrive\Pictures\Typora\image-20191225140430515.png)
      * Private Partitions: each thread has its own set of partitions
        * have to consolidate them after all threads finish
        * ![image-20191225140448063](D:\OneDrive\Pictures\Typora\image-20191225140448063.png)
    * Blocking Partitioning (Radix)
      * scan the input relation multiple times
      * only materialize results all at once
      * radix hash join
      * Step 1: scan `R` & compute a histogram of the \# of tuples per hash key for the radix at some offset
      * Step 2: use the histogram to determine output offset by computing the prefix sum
      * Step 3: scan `R` again & partition them according to the hash key
      * ![image-20191225141035734](D:\OneDrive\Pictures\Typora\image-20191225141035734.png)
  * Phase 2: Build
    * scan relation `R` & create a HT on join key
    * Hash Function
      * large key space to small domain
      * fast vs. collision rate
      * ![image-20191225141449285](D:\OneDrive\Pictures\Typora\image-20191225141449285.png)
    * Hashing Scheme
      * key collisions after hashing
      * large HT vs. instructions to find/insert keys
      * Chained Hashing: linked list of buckets
        * ![image-20191225141530390](D:\OneDrive\Pictures\Typora\image-20191225141530390.png)
      * Linear Probe Hashing: single giant table of slots, linear searching for next free slots
        * ![image-20191225141610430](D:\OneDrive\Pictures\Typora\image-20191225141610430.png)
        * 2x \# of slots as the \# of elements in R
      * Robin Hood Hashing: steal slots from rich keys, give to poor keys
        * Each key tracks the number of positions they are from where its optimal position in the table
        * On insert, a key takes the slot of another key if the first key is farther away from its optimal position than the second key
        * ![image-20191225141715798](D:\OneDrive\Pictures\Typora\image-20191225141715798.png)
      * Cuckoo Hashing: multiple table with different hash functions
        * on insert, check every table, pick anyone has a free slot
        * no free slot, evict 1 of them, re-hash it to find a new location
        * infinite loop/cycle -> rebuild entire hash table
          * 2 hash f -> 50% full
          * 3 hash f -> 90% full
  * Phase 3: Probe
    * for each tuple in `S`, lookup its join key in hash table for `R`
    * create a Bloom Filter during the build phase
      * when the key is likely to not exist in the HT
      * filter fit into the CPU cache -> faster
      * sideways information passing
* ![image-20191225142229708](D:\OneDrive\Pictures\Typora\image-20191225142229708.png)
* ![image-20191225142322765](D:\OneDrive\Pictures\Typora\image-20191225142322765.png)
* On modern CPUs, a simple hash join algorithm that does not partition inputs is competitive
  * due to hyperthreading + multi-threading
* SIMD operations
  * x86: MMX, SSE, SSE2, SSE3, SSE4, AVX{128, 256, 512}
  * PowerPC: Altivec
  * ARM: NEON
  * performance gain, resource utilization
  * SIMD needs manual implementation
  * restrictions on data alignment
  * gather + scatter is tricky/inefficient
* Sort-Merge Join (R$\bowtie$S)
  * Phase 1: Partition (optional): partition `R` & assign them to workers / cores
    * Implicit Partitioning: partitioned on the join key when loaded into the database
    * Explicit Partitioning: divide only the outer relation & redistribute among the different CPU cores
      * can use the same radix partitioning approach
  * Phase 2: Sort: sort the tuples of `R` & `S` based on the join key
    * always to most expensive part
    * CPU cores, NUMA, SIMD
    * create runs of sorted chunks of tuples for both input relations
    * Cache-Conscious Sorting
      * Level 1: In-Register Sorting: runs fit into CPU register
        * sorting networks: abstract model for sorting keys
          * fixed wiring paths for lists with the same \# of elements
          * efficient to execute on modern CPUs because of limited data dependencies, no branches
        * ![image-20191225143146968](D:\OneDrive\Pictures\Typora\image-20191225143146968.png)
        * ![image-20191225143206357](D:\OneDrive\Pictures\Typora\image-20191225143206357.png)
      * Level 2: In-Cache Sorting: merge \#1 output into runs fit into CPU cache
        * Bitonic Merge Network: like sorting network but merge 2 locally-sorted list into a globally-sorted list
          * expand network to merge progressively larger lists (1/2 cache size)
          * ![image-20191225143253844](D:\OneDrive\Pictures\Typora\image-20191225143253844.png)
      * Level 3: Out-of-Cache Sorting
        * Multi-Way Merging: use bitonic merge network, but split process up into tasks
          * link together tasks with a cache-sized FIFO queue
          * a task blocks when either its input queue is empty / output queue is full
          * more CPU instructions -> bandwidth + balance
          * ![image-20191225143408987](D:\OneDrive\Pictures\Typora\image-20191225143408987.png)
  * Phase 3: Merge: scan the sorted relations & compare tuples
    * backtrack if duplicates
    * in parallel if separate output buffers
* Multi-Way Sort-Merge (M-WAY)
  * Outer Table: each core sorts in parallel on local data (level \#1/\#2)
    * redistribute sorted runs across cores using multi-way merge (level \#3)
  * Inner Table: same as outer table
  * Merge: matching pairs of chunks of outer/inner tables at each core
  * ![image-20191225143651091](D:\OneDrive\Pictures\Typora\image-20191225143651091.png)
* Multi-Pass Sort-Merge (M-PASS)
  * Outer Table: same \#1/\#2 sorting as M-Way
    * instead of redistributing, use a multi-pass naive merge on sorted runs
  * Inner Table: same as outer table
  * Merge: pairs of chunks of outer table + inner table
  * ![image-20191225143757297](D:\OneDrive\Pictures\Typora\image-20191225143757297.png)
* Massively Parallel Sort-Merge (MPSM)
  * Outer Table: range-partition outer table, redistribute to cores
    * each core sorts in parallel on their partitions
  * Inner Table: not redistributed like outer table
    * each core sorts its own data
  * Merge: between entire sorted run of outer table +  segment of inner table
  * ![image-20191225143937955](D:\OneDrive\Pictures\Typora\image-20191225143937955.png)
* HyPer's Rules for Parallelization
  * No random writes to non-local memory
    * chunk the data, redistribute, each core works on local data
  * Only perform sequential reads on non-local memory
    * hardware prefetching to hide remote access latency
  * No core should ever wait for another
    * avoid fine-grained latching / sync barriers



## Query Compilation

* Query Interpretation
  * ![image-20191225215002714](D:\OneDrive\Pictures\Typora\image-20191225215002714.png)
* Predicate Interpretation
  * ![image-20191225215742386](D:\OneDrive\Pictures\Typora\image-20191225215742386.png)
* Code Specialization: any CPU intensive entity of database natively compiled (JIT?)
  * Access Methods
  * Stored Procedures
  * Operator Execution
  * Predicate Evaluation
  * Logging Operators
  * known types (inline pointer casting), predicates (primitive comparison)
  * no function calls in loops (efficiently distribute data to registers & increase cache reuse)
* ![image-20191225220251195](D:\OneDrive\Pictures\Typora\image-20191225220251195.png)
* Code Generation
  * Transpilation: write code that converts a relational query plan into C/C++, run it through a conventional compiler to generate native code
    * HiQue: off-self compiler to convert the code into a shared object, link it to the DBMS process, invoke the `exec` function
      * not allow full pipelining
        * ![image-20191225223443912](D:\OneDrive\Pictures\Typora\image-20191225223443912.png)
      * long compilation time
  * JIT Compilation: generate an IR of query, quickly compiled into native code
    * HyPer: LLVM toolkit
      * push-based / bottom-to-top
      * not vectorizable
      * Push-based vs Pull-based
        * ![image-20191225224748581](D:\OneDrive\Pictures\Typora\image-20191225224748581.png)
      * Data centric vs. Operator centric
    * Query compilation cost
      * LLVM compilation time grows super-linearly relative to the query size
        * \# of joins/predicates/aggregations
      * not a big issue with OLAP
      * major problem with OLAP
    * Adaptive Execution
      * Step 1: Generate LLVM IR for the query
      * Step 2: Execute the IR in an interpreter
      * Step 3: Compile the query in the background
      * Step 4: When ready, seamlessly replace the interpretive execution
      * ![image-20191225225025669](D:\OneDrive\Pictures\Typora\image-20191225225025669.png)
* Operator Templates
  * ![image-20191225220543536](D:\OneDrive\Pictures\Typora\image-20191225220543536.png)
* DBMS Integration
  * generate query code can invoke any other function in the DBMS
* ![image-20191225223138406](D:\OneDrive\Pictures\Typora\image-20191225223138406.png)
* ![image-20191225223200782](D:\OneDrive\Pictures\Typora\image-20191225223200782.png)
* IBM System R
  * primitive form of code generation / query compilation by IBM in 1970s
    * compile SQL statements into assembly code by selecting code templates for each operator
  * abandoned when DB2
  * high cost of external function calls
  * poor portability
  * software engineer complications
* Oracle
  * PL/SQL stored procedures into Pro*C code, then to native C/C++ code
  * Oracle-specific operations in the SPARC chips as co-processors
    * Memory Scans
    * Bit-pattern Dictionary Compression
    * Vectorized instructions designed for DBMSs
    * Security/Encryption
* Microsoft Hekaton
  * compile both procedure & SQL
    * non-Hekaton queries access Hekaton tables through compiled inter-operators
  * generate C code from an imperative syntax tree $\to$ DLL $\to$ runtime linking
  * employ safety measures to prevent injecting malicious code in a query
* Cloudera Impala
  * LLVM JIT compilation for predicate evaluation & record parsing
  * handle multiple data formats stored on HDFS
* Actian Vector
  * pre-compiled thousands of primitives that perform basic operations on typed data
  * DBMS executes a query plan that invokes these primitives at runtime
  * ![image-20191225225629243](D:\OneDrive\Pictures\Typora\image-20191225225629243.png)
* MemSQL (pre 2016)
  * same as HIQUE, C/C++ code generation + gcc
  * convert all queries into a parameterized form, cache the compiled query plan
  * ![image-20191225225711394](D:\OneDrive\Pictures\Typora\image-20191225225711394.png)
* MemSQL (2016-)
  * query plan $\to$ imperative plan in a high-level imperative DSL
    * MemSQL Programming Language (MPL)
    * C++ dialect
  * DSL $\to$ opcodes
    * MemSQL Bit Code (MBC)
    * JVM bytecode
  * opcodes $\to$ LLVM IR $\to$ native code
* VitesseDB
  * query accelerator for Postgres/Greenplum that uses LLVM + intra-query parallelism
    * JIT predicates
    * push-based processing model
    * indirect calls $\to$ direct / inlined
    * hardware for overflow detection
  * DML operations are still interpreted
* Apache Spark
  * Tungsten engine in 2015
  * `WHERE` clause expression tree into ASTs
  * AST $\to$ JVM bytecode $\to$ native execution
* Peloton (2017)
  * HyPer-style full compilation of the entire query plan using LLVM
  * relax the pipeline breakers create mini-batches for operators that can be vectorized
  * software pre-fetching to hide memory stalls
* Unnamed CMU DBMS (2019)
  * MemSQL-style conversion of query plans into a database-oriented DSL
  * DSL $\to$ opcodes
  * HyPer-style interpretation of opcodes
  * compilation in background with LLVM
  * ![image-20191225230110363](D:\OneDrive\Pictures\Typora\image-20191225230110363.png)



## Vectorized Execution

* scalar, single pair of operands $\to$ vector, multiple pairs of operands
* Multi-core CPUs: small \# of high-powered cores
  * Intel Xeon Skylake / Kaby Lake
  * high power consumption & area per core
  * massively superscalar
  * aggressive OoO
* Many Integrated Cores (MIC): large \# of low-powered cores
  * Intel Xeon Phi
  * low power consumption & area per core
  * expand SIMD instructions with larger register sizes
  * Knights Ferry (Columbia Paper)
    * non-superscalar, in-order
    * cores = Intel P54C (aka Pentium from 1990s)
  * Knights Landing (since 2016)
    * superscalar + OoO
    * cores = Silvermont (aka Atomc)
* SIMD instructions
  * data movement
  * arithmetic operations
  * logical instructions
  * comparison instructions
  * shuffle instructions (between SIMD registers)
  * miscellaneous
    * conversion (between SIMD & x86 registers)
    * cache control (SIMD register to memory, bypass CPU cache)
  * ![image-20191226152909999](D:\OneDrive\Pictures\Typora\image-20191226152909999.png)
* Vectorization
  * Automatic Vectorization: compiler, rare in database operators
    * `restrict`, `memmove`, `memcpy`
    * ![image-20191226153004844](D:\OneDrive\Pictures\Typora\image-20191226153004844.png)
  * Compiler Hints: explicit information about memory locations / ignore vector dependencies
    * `restrict`: distinct pointers
    * `#pragma ivdep` / `#pragma simd`: ignore loop dependencies (gcc + icc + msvc)
  * Explicit Vectorization: CPU intrinsics to manually marhsal data
    * ![image-20191226153242771](D:\OneDrive\Pictures\Typora\image-20191226153242771.png)
    * Linear Access Operators
      * predicate evaluation
      * compression
    * Ad-hoc Vectorization
      * sorting
      * merging
    * Composable Operations
      * multi-way trees
      * bucketized hash tables
* Vectorization Direction
  * Horizontal: operation on all elements together within a single vector
  * Vertical: operation in an elementwise manner on elements of each vector
    * prefer vertical vectorizations
    * maximize lane utilization by executing different things per lane subset
* Fundamental Vector Operations
  * Selective Load
    * ![image-20191226153537210](D:\OneDrive\Pictures\Typora\image-20191226153537210.png)
  * Selective Store
    * ![image-20191226153552658](D:\OneDrive\Pictures\Typora\image-20191226153552658.png)
  * Selective Gather
    * ![image-20191226153612593](D:\OneDrive\Pictures\Typora\image-20191226153612593.png)
    * [[C: CS239B for gather implementation in OpenMP]]
  * Selective Scatter
    * ![image-20191226153635291](D:\OneDrive\Pictures\Typora\image-20191226153635291.png)
  * gather & scatters are not really executed in parallel: L1 cache only allows 1/2 distinct access per cycle
  * gather only supported in newer CPUs
  * load/store can be implemented using vector permutations
* Vectorized Operators
  * Selection Scans
    * ![image-20191226153905114](D:\OneDrive\Pictures\Typora\image-20191226153905114.png)
  * Hash Tables
    * probing
      * SIMD Map (hash) + SIMD Gather (match) + SIMD Compare (check) + SIMD Map (linear probing addition) ...
  * Partitioning
    * scatter + gathers to increment counts
    * replicate the histogram to handle collisions
    * ![image-20191226154400529](D:\OneDrive\Pictures\Typora\image-20191226154400529.png)
  * Joins
    * No Partitioning: 1 shared HT using atomics
      * partially vectorized
    * Min Partitioning: partition building table, 1 HT per thread
      * fully vectorized
    * Max Partitioning: partition both tables repeatedly
      * build & probe cache-resident HT
      * fully vectorized
  * Sorting/Bloom FIlters
* Vectorization is essential for OLAP queries
* when data exceed CPU cache?



## Vectorizaton vs. Compilaton

* vectorwise $\to$ precompiled primitives
* hyper $\to$ JIT compilation
* Data-centric is better for computational queries with few cache misses
* Vectorization is slightly better at hiding cache miss latencies
* ![image-20191226155115493](D:\OneDrive\Pictures\Typora\image-20191226155115493.png)
* Fusion: unable to look ahead in tuple stream, unable to overlap computation & memory access
  * cannot SIMD
  * cannot prefetch
  * [[Q: why?]]
* Relaxed Operator Fusion
  * vectorized processing model designed for query compilation execution engine
  * decompose pipelines into stages that operate on vectors of tuples
    * stage: multiple operators, granularity of vectorization + fusion
    * communicate through cache-resident buffers
  * [[N: for UDFs, can we apply this to BSP-based systems?]]
  * ![image-20191226160846061](D:\OneDrive\Pictures\Typora\image-20191226160846061.png)
  * software prefetching
    * prefetch-enabled operators define start of new stage
      * hide cache miss latency
    * prefetching techniques
      * group prefetching, [software pipelining](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.574.2606&rep=rep1&type=pdf), [AMAC](https://labs.oracle.com/pls/apex/f?p=LABS:0::APPLICATION_PROCESS%3DGETDOC_INLINE:::DOC_ID:985)
        * [软件流水](https://blog.csdn.net/diyinqian/article/details/86360396)
      * [Relaxed Operator Fusion for In-Memory Databases: Making Compilation, Vectorization, and Prefetching Work Together At Last](https://www.jianshu.com/p/6834b458b513)
      * [When Prefetching Works, When It Doesn't, and Why](https://hackmd.io/@jserv/HJtfT3icx)
* ROF combines vectorization and compilation into a hybrid query processing model



## Optimizer Implementation

* ![image-20191226164357632](D:\OneDrive\Pictures\Typora\image-20191226164357632.png)

* logical vs. physical plan

  * [[C: SparkSQL paper]]

* OLTP queries: search argument able / SARGable

  * > In other words, a sargable predicate is such that can be resolved by the storage engine (access method) by directly observing the table or index record. A non-sargable predicate, conversely, requires a higher level of the DBMS to take action. For example, the outcome of `WHERE lastname = 'Doe'` can be decided by the storage engine by simply looking at the contents of the field `lastname` of each record. On the other hand, `WHERE UPPER(lastname) = 'DOE'` requires execution of a function by the SQL engine, which means the storage engine will have to return all rows it reads (provided they match possible other, sargable predicates) back to the SQL engine for evaluation, incurring additional CPU costs.

  * usually picking the best index with simple heuristics

  * joins are almost always on foreign key relationships with a small cardinality

* Cost Estimation: generate an estimate of the cost of executing a plan for the current state of the database

  * interaction with other work in DBMS (cache?)
  * size of intermediate results
  * choices of algorithms / access methods
  * resource utilization (CPU, I/O, network)
  * data properties (skew, order, placement)

* Optimization Granularity

  * Single Query: small search space
    * usually doesn't reuse results across queries
    * account for resource contention, must consider what is currently running
  * Multiple Queries: more efficient if there are many similar queries, large search space
    * useful for data / intermediate result sharing

* Optimization Timing

  * Static Optimization: best plan prior to execution
    * amortize over execution with prepared stmts (!)
    * plan quality on cost model accuracy
  * Dynamic Optimization: on-the-fly
    * re-optimize for multiple executions
    * difficult to implement/debug (non-deterministic)
  * Hybrid Optimization: compile using a static, error > threshold? re-optimize

* Prepared Statements

  * Re-Optimize: rerun optimizer each time the query is invoked
    * reuse existing plan as start point
  * Multiple Plans: multiple plans for different values of the parameters
  * Average Plan: average value for a parameter, use that for all invocations
  * [[C: partial evaluator?]]

* Plan Stability

  * Hints: DBA to provide hints
  * Fixed Optimizer Versions: set the optimizer version number, migrate queries to the new optimizer one-by-one
  * Backwards-Compatible Plans: save query plan from old version, provide to new DBMS

* Search Termination

  * Wall-clock Time: physical length of time
  * Cost Threshold: lower cost than threshold
  * Transformation Exhaustion: no more ways to transform the target plan, done per group

* Optimization Search Strategies

  * Heuristics: define static rules that transform logical operators to a physical plan
    * most restrict selection early
    * all selections before joins
    * predicate/limit/projection pushdowns
    * join ordering based on cardinality
    * [[C: SparkSQL fixpoint]]
    * INGRES & Oracle (-mid 1990s)
      * ![image-20191226170825190](D:\OneDrive\Pictures\Typora\image-20191226170825190.png)
    * Advantages
      * easy to implement + debug
      * work reasonably well & fast for simple queries
    * Disadvantages
      * rely on magic constants to predicate the efficacy of a planning decision
      * nearly impossible to generate good plans when operators have complex inter-dependencies
  * Heuristics + Cost-based Join Order Search
    * initial optimization: static rule
    * best join order: dynamic programming
      * 1st cost-based query optimizer (Patricia Selinger on System R)
      * bottom-up planning (forward chaining) using a divide-n-conquer search method
    * System R, early IBM DB2, most open-source DBMSs
      * break query up into blocks, generate logical operators for each block
      * for each logical operator, generate a set of physical operators that implements it
        * all combination of join algorithms + access paths
      * iteratively construct a "left-deep" tree that minimize the estimated amount of work to execute the plan
      * ![image-20191226171232254](D:\OneDrive\Pictures\Typora\image-20191226171232254.png)
      * ![image-20191226171254369](D:\OneDrive\Pictures\Typora\image-20191226171254369.png)
      * ![image-20191226171305647](D:\OneDrive\Pictures\Typora\image-20191226171305647.png)
    * Postgres Optimizer
      * Imposes a rigid workflow for query optimization:
        * First stage performs initial rewriting with heuristics
        * Then executes a cost-based search to find optimal join ordering
        * Everything else is treated as an “add-on”
        * Then recursively descends into sub-queries
      * Difficult to modify or extend because the ordering has to be preserved.
    * Advantages
      * Usually finds a reasonable plan without having to perform an exhaustive search
    * Disadvantages
      * same problems as the heuristic-only approach
      * left-deep is suboptimal
      * physical properties of data in the cost model
        * e.g. sort order
        * meta table
  * Randomized Algorithms
    * Perform a random walk over a solution space of all possible (valid) plans for a query
    * Continue searching until a cost threshold is reached or the optimizer runs for a particular length of time
    * Simulated Annealing
      * Start with a query plan that is generated using the heuristic-only approach
      * Compute random permutations of operators (e.g., swap the join order of two tables)
        * Always accept a change that reduces cost
        * Only accept a change that increases cost with some probability
        * Reject any change that violates correctness (e.g., sort ordering)
    * Postgres's genetic algorithms
      * More complicated queries use a genetic algorithm that selects join orderings (GEQO)
      * At the beginning of each round, generate different variants of the query plan
      * Select the plans that have the lowest cost and permute them with other plans. Repeat
        * mutator function only generates valid plans
      * ![image-20191226171822532](D:\OneDrive\Pictures\Typora\image-20191226171822532.png)
    * Advantages
      * Jumping around the search space randomly allows the optimizer to get out of local minimums
      * Low memory overhead (if no history is kept)
    * Disadvantages
      * Difficult to determine why the DBMS may have chosen a particular plan (rationale?)
      * Have to do extra work to ensure that query plans are deterministic
      * Still have to implement correctness rules
  * Optimizer Generator: use a rule engine that allows transformation to modify the query plan operators
    * physical properties of data is embedded with the operators themselves
    * Writing query transformation rules in a procedural language is hard and error-prone
      * No easy way to verify that the rules are correct without running a lot of fuzz tests
      * Generation of physical operators per logical operator is decoupled from deeper semantics about query
      * A better approach is to use a declarative DSL to write the transformation rules and then have the optimizer enforce them during planning
    * Stratified Search: planning is done in multiple stages
      * rewrite the logical query plan using transformation rules
        * engine checks whether the transformation is allowed before it can be applied
        * cost is never considered in this step
      * perform a cost-based search to map the logical plan to a physical plan
      * Starburst Optimizer
        * declarative rules
        * Latest version of IBM DB2
        * Stage 1: Query Rewrite: compute a SQL-block-level, realtional calculus-like representation of queries
        * Stage 2: Plan Optimization: execute a System R-style dynamic programming phase once query rewrite has completed
      * Advantages
        * works well in practice + fast performance
      * Disadvantages
        * difficult to assign priorities to transformations
        * some transformations are difficult to access without computing multiple cost estimations
        * rules maintenance is a huge plan
      * [[C: SCOPE, SparkSQL, ...]]
    * Unified Search: perform query planning all at once
      * unify the notion of both logical $\to$ logical + logical $\to$ physical transformations
      * generates a lot more transformations 
        * heavy use of memoization to reduce redundant work
      * Volcano Optimizer
        * General purpose cost-based query optimizer, based on equivalence rules on algebras
          * easily add new operations & equivalence rules
          * treat physical properties of data as first-class entities during planning
          * top-down approach (backward chaining) using branch-n-bound search
        * ![image-20191226172712374](D:\OneDrive\Pictures\Typora\image-20191226172712374.png)
      * Advantages
        * declarative rules to generate transformations
        * better extensibility with an efficient search engine
        * reduce redundant estimations using memoization
      * Disadvantages
        * all equivalence classes are completely expanded to generate all possible logical operators before the optimization search
        * not easy to modify predicates

* Top-Down vs. Bottom-Up

  * top-down: start with final outcome, then work down the tree to find the optimal plan
    * Volcano, Cascades
  * bottom-up: start with nothing, build up the plan to get to the final outcome
    * System R, Starburst

* ![image-20191226192414393](D:\OneDrive\Pictures\Typora\image-20191226192414393.png)

* Cascades Optimizer

  * OO implementation of the Volcano query optimizer
  * simplistic expression re-writing can be through a direct mapping function rather than an exhausive search
  * [[N: Catalyst is the embedded version of Cascade in Scala]]
  * Optimization tasks as data structures
  * Rules to place property enforcers
  * Ordering of moves by promise
  * Predicates as logical/physical operators
  * Expressions: an operator with 0+ input expressions
    * ![image-20191226200102323](D:\OneDrive\Pictures\Typora\image-20191226200102323.png)
  * Groups: a set of logically equivalent logical & physical expressions that produce the same output
    * all logical forms of an expression
    * all physical expressions that can be derived from selecting the allowable physical operators for the corresponding logical forms
    * ![image-20191226200215062](D:\OneDrive\Pictures\Typora\image-20191226200215062.png)
    * Multi-expressions: optimizer implicitly represents redundant expressions in a group as a multi-expressions
      * reduce the \# of transformations / storage overhead / repeated cost estimation
  * Rules: transformation of an expression to a logically equivalent expression
    * transformation rule: logical $\to$ logical
    * implementation rule: logical $\to$ physical
    * pair of (pattern, substitute)
    * pattern: the structure of the logical expression that can be applied to the rule
    * substitute: the structure of the result after applying the rule
    * ![image-20191226201315078](D:\OneDrive\Pictures\Typora\image-20191226201315078.png)
  * Memo Table: stores all previously explored alternatives in a compact graph structure / hash table
    * equivalent operator trees & corresponding plans stored together in groups
    * memoization, duplicate detection, property + cost management
    * ![image-20191226201713572](D:\OneDrive\Pictures\Typora\image-20191226201713572.png)
  * Principle of Optimality: every sub-plan of an optimal plan is itself optimal
    * allow the optimizer to restrict the search space to a smaller set of expressions
  * ![image-20191226201736572](D:\OneDrive\Pictures\Typora\image-20191226201736572.png)

* Complex queries?: outer joins, semi-joins, anti-joins

* Reordering limitatons

  * ![image-20191226201837231](D:\OneDrive\Pictures\Typora\image-20191226201837231.png)

* Plan Enumerations

  * generate different join ordering to feed into the optimizer's search model (efficiently)
  * Generate-and-Test
  * Graph Partitioning

* Dynamic Programming Optimizer

  * model the query as a hypergraph, incrementally expand to enumerate new plans
  * algorithm overview
    * iterate connected sub-graphs & incrementally add new edges to other nodes to complete query plan
    * rules to determine which nodes the traversal is allowed to visit & expand

* Predicate Expressions

  * predicates: defined as part of each operator
    * typically represented as an AST
    * Postgres: flatten lists
  * same logical operators can be represented in multiple physical operators using variations of same expression
  * Predicate Pushdown
    * Logical Transformation
      * like any other transformation rule in Cascades
      * can use cost-model to determine benefit
    * Rewrite Phase
      * perform pushdown before starting searching using an initial rewrite phase
      * tricky to support complex predicates
    * Late Binding
      * perform pushdown after generating optimal plan in Cascades
      * likely to produce a bad plan
    * not all predicates cost the same to evaluate on tuples (`SHA_512`)
      * optimizer should consider selectivity & computation cost when determining the evaluate order of predicates

* Pivotal Orca

  * standalone Cascades implementation
    * written for Greenplum
    * extended to support HAWQ (Hadoop native SQL query engine)
  * use Orca by implementing API to send catalog + stats + logical plans, then retrieve physical plans
  * support multi-threaded search
  * engineering
    * Remote Debugging
      * automatically dump the state of the optimizer (with inputs) whenever an error occurs
      * dump is enough to put the optimizer back in the exact same state later on for further debugging
    * Optimizer Accuracy
      * automatically check whether the ordering of the estimate cost of 2 plans matches their actual execution cost

* Apache Calcite

  * standalone extensible query optimization framework for data processing systems
    * support pluggable query languages / cost models / rules
    * doesn't distinguish logical/physical operators
    * physical properties as annotations
  * LucidDB

* MemSQL Optimizer

  * Rewriter: logical $\to$ logical transformation with access to the cost-model
  * Enumerator: logical $\to$ physical transformation, mostly join ordering
  * Planner: convert physical plans back to SQL
    * MemSQL-specific commands for moving data
  * ![image-20191226203318527](D:\OneDrive\Pictures\Typora\image-20191226203318527.png)





## Cost Models

* Cost-based Query Planning
  * generate an estimate of the cost of executing a particular query plan for the current state of the database
  * independent of search strategy
* Cost Model Components
  * Physical Costs
    * predicate CPU cycles, I/O, cache misses, RAM consumption, pre-fetching
    * depends heavily on hardware
  * Logical Costs
    * estimate result sizes per operator
    * independent of the operator algorithm
    * need estimations for operator result sizes
  * Algorithmic Costs
    * complexity of the operator algorithm implementation
* Disk-based DBMS Cost Model
  * \# of disk accesses dominate the execution time of aquery
    * CPU cost are negligible
    * sequential vs. random I/O
  * easier to model if full control over buffer management
* Postgres Cost Model
  * combination of CPU & I/O costs that are weighted by magic constant factors
  * default settings: for disk-resident database without lot of memory
    * processing a tuple in memory is 400x faster than reading a tuple from disk
    * sequential I/O is 4x faster than random I/O
* IBM DB2 Cost Model
  * Database characteristics in system catalogs 
  * Hardware environment (microbenchmarks) 
  * Storage device characteristics (microbenchmarks) 
  * Communications bandwidth (distributed only) 
  * Memory resources (buffer pools, sort heaps) 
  * Concurrency Environment
    * average number of users
    * isolation level / blocking
    * number of available locks
* In-memory DBMS Cost Model
  * No I/O costs, but account for CPU & memory access costs
  * Memory cost is more difficult
    * DBMS has no control cache management
    * unknown replacement strategy, no pinning, shared caches, NUMA
  * \# of tuples processed per operator is reasonable estimate for the CPU cost
* Smallbase Cost Model
  * 2-phase model automatically generates hardware costs from a logical model
  * Phase 1: Identify Execution Primitives
    * list of ops that DBMS does when executing a query
    * E.g.: evaluating predicates, index probe, sorting
  * Phase 2: Microbenchmark
    * on start-up, profile ops to compute CPU/memory costs
    * formulas to compute operator cost based on table size
* Selectivity: percentage of data accessed for a predicate
  * modeled as probability of whether a predicate on any given tuple will be satisified
  * DBMS estimates selectivity using
    * Domain Constraints
    * Precomputed Statistics (Zone Maps)
    * Histograms / Approximations
      * maintaining exact statistics about the database is slow & expensive
      * sketches: approximate data structures to generate error-bounded estimates
        * count distincts
        * quantiles
        * frequent items
        * tuple sketch
    * Sampling
      * execute a predicate on a random sample of the target data set
      * \# of tuples to examine depends on the size of the table
      * Maintain Read-Only Copy: periodically refresh to maintain accuracy
      * Sample Real Tables
        * use `READ UNCOMMITTED` isolation
        * may read multiple versions of same logical tuple
* The number of tuples processed per operator depends on three factors
  * access methods available per table
  * distribution of values in the database's attributes
  * predicate used in the query
* Result Cardinality
  * Assumption 1: Uniform Data: distribution of values (except for the heavy hitters) is the same
  * Assumption 2: Independent Predicates: predicates on attributes are independent
  * Assumption 3: Inclusion Principle: domain of join keys overlap such that each key in the inner relation will also exist in the outer table
* Column Group Statistics
  * DBMS can track statistics for groups of attributes together rather than just treating them all as independent variables
    * only supported in commercial systems
    * DBA to declare manually
* Estimator Quality
  * Evaluate the correctness of cardinality estimates generated by DBMS optimizers as the number of joins increases.
    * Let each DBMS perform its stats collection
    * Extract measurements from query plan
  * ![image-20191226211700986](D:\OneDrive\Pictures\Typora\image-20191226211700986.png)
* Lessons from the Germans
  * Query opt is more important than a fast engine
    * Cost-based join ordering is necessary
  * Cardinality estimates are routinely wrong
    * Try to use operators that do not rely on estimates
  * Hash joins + seq scans are a robust exec model
    * The more indexes that are available, the more brittle the plans become (but also faster on average)
  * Working on accurate models is a waste of time
    * Better to improve cardinality estimation instead
* IBM DB2 - Learning Optimizer
  * Update table statistics as the DBMS scans a table during normal query processing
  * Check whether the optimizer’s estimates match what it encounters in the real data and incrementally updates them
* Using number of tuples processed is a reasonable cost model for in-memory DBMSs
  * but computing this is non-trivial



## Self-Driving DBMS

*  Self-adaptive Databases (1970s - 1990s)

  * Index Selection
  * Partitioning / Sharding Keys
  * Data Placement
  * ![image-20191226212110806](D:\OneDrive\Pictures\Typora\image-20191226212110806.png)

* Self-Tuning Databases (1990s - 2000s)

  * ![image-20191226212127637](D:\OneDrive\Pictures\Typora\image-20191226212127637.png)

* Cloud-managed Databases (2010s)

  * Initial Placement
  * Tenant Migration
  * ![image-20191226212202422](D:\OneDrive\Pictures\Typora\image-20191226212202422.png)

* Previous Work

  * Problem #1: Human Judgements 
    * User has to make final decision on whether to apply recommendations. 
  * Problem #2: Reactionary Measures
    * Can only solve previous problems. 
    * Cannot anticipate upcoming usage trends / issues. 
  * Problem #3: No Transfer Learning
    * Tunes each DBMS instance in isolation. 
    * Cannot apply knowledge learned about one DBMS to another.

* Autonomous DBMS Taxonomy (like SAE Automation Levels on cars)

  * Level \#0: Manual
    * System only does what humans tell it to do
  * Level \#1: Assistant
    * Recommendation tools that suggest improvements. 
    * Human makes final decisions
  * Level \#2: Mixed Management
    * DBMS and humans work together to mange the system. 
    * Human guides the process
  * Level \#3: Local Optimizations
    * Subsystems can adapt without human guidance. 
    * No higher-level coordination
  * Level \#4: Direct Optimizations
    * Human only provides high-level direction + hints. 
    * System can identify when it needs to ask humans for help
  * Level \#5: Self-Driving
    * A DBMS that can deploy, configure, and tune itself automatically without any human intervention
      * Select actions to improve some objective function (e.g., throughput, latency, cost)
      * Choose when to apply an action
      * Learn from these actions and refine future decision making processes
    * ![image-20191226212602403](D:\OneDrive\Pictures\Typora\image-20191226212602403.png)
    * Environment Observations: how DBMS collects training data
      * Logical Workload History
        * SQL queries with their execution context
        * need to compress to reduce storage size
      * Runtime Metrics
        * internal measurements about the DBMS's runtime behavior
      * Database Contents
        * succinct representation/encoding of the database tables
    * Action Meta-Data: how DBMS implements & exposes methods for controlling & modifiying the system's configuration
      * Configuration Knobs
        * Untunable flags
          * Anything that requires a human value judgement should be marked as off-limits to autonomous components
            * File Paths
            * Network Addresses
            * Durability / Isolation Levels
        * Value ranges
        * Hints
          * ranges
          * separate knobs to enable/disable a feature
          * non-uniform deltas
            * ![image-20191226213115716](D:\OneDrive\Pictures\Typora\image-20191226213115716.png)
      * Dependencies
        * No hidden dependencies
        * Dynamic actions (actions creating new actions)
    * Action Engineering: how DBMS deploys actions either for training / optimization
      * No Downtime
        * The DBMS must be able to deploy any action without incurring downtime
          * Restart vs. Unavailability
        * Or include the downtime in its cost model estimation
          * Bad Example: MySQL Log File Size
      * Notifications
        * Provide a notification to indicate when an action starts and when it completes
          * Need to know whether degradation is due to deployment or bad decision
        * Harder for changes that can be used before the action completes
      * Replicated Training
        * ML models need lots of training data. But getting this data is expensive in a DBMS
          * simulator is too hard
          * don't want to slow down a production DBMS
        * Ongoing Research: how to use the DBMS's replicas to explore configurations & train its models
        * ![image-20191226213401219](D:\OneDrive\Pictures\Typora\image-20191226213401219.png)
    * Sub-Component Metrics
      * If the DBMS has sub-components that are tunable, then it must expose separate metrics for those components
      * Bad Examples: RocksDB
        * ![image-20191226212939545](D:\OneDrive\Pictures\Typora\image-20191226212939545.png)
        * ![image-20191226212946852](D:\OneDrive\Pictures\Typora\image-20191226212946852.png)

* ![image-20191226213440509](D:\OneDrive\Pictures\Typora\image-20191226213440509.png)

* There are many places in the DBMS that use human-engineered components to make decisions about the behavior of the system

  * Optimizer Cost Models
  * Compression Algorithms
  * Data Structures
  * Scheduling Policies

* replace DBMS components with ML models

* True autonomous DBMSs are achievable in the next decade

  

