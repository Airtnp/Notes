# [Spanner: Google’s Globally-Distributed Database](https://static.googleusercontent.com/media/research.google.com/zh-CN//archive/spanner-osdi2012.pdf)

###### James C. Corbett, Jeffrey Dean, Michael Epstein et al.

------

From EECS582/Wk9 + CS239A/Wk1

[[T: Re-read the proof of timestamp assignment based Paxos]]



### What is the Problem? [Good papers generally solve *a single* problem]

- Google needs a database that provides global availability, geographic locality and high scalability to deal with wide-area natural disasters by replicating data within or even across continents. BigTable is difficult to use for some kinds of applications with complex evolving schemas or requring strong consistency in the presence of wide-area replication. Megastore, through having semirealtional data model and support for synchronous replication, fails to meet due to its relatively poor write throughtput.

### Summary [Up to 3 sentences]

- In this paper, the authors present Spanner, which is Google's scalable, multi-version, globally distributed and synchronously-replicated database. This paper describes how Spanner is structured, its feature set and rationale underlying various design decisions. Also, they present a novel time API that exposes clock uncertainty.

### Key Insights [Up to 2 insights]

- Spanner assigns globally-meaningful commit timestamps to transactions to reflect serialization order which satisfies external consistency (or linearizability). This is enabled by TrueTime API exposing clock uncertainty.
- A directory is the smallest unit whose geographic-replication properties can be specified by an application.

### Notable Design Details/Strengths [Up to 2 details/strengths]

- Spanner provides several interesting features: First, the replication configuration for data can be dynamically controlled by applications at a fine grain; Second, Spanner provides externally consistent reads and writes and globally-consistent reads across the database at a timestamp.
- On top of the bag of key-value mappings, Spanner implementation supports a buckering abstraction called a directory, which is a set of contiguous keys that share a common prefix. When data is moved between Paxos groups, it is moved directory by directory.

### Limitations/Weaknesses [up to 2 weaknesses]

- The node-local data structures have relatively poor performance on complex SQL queries, because they were designed for simple kv accesses.
- To use TrueTime API we need to setup many time master machines with GPS receivers and Armageddon masters with atomic clocks.

### Summary of Key Results [Up to 3 results]

- Spanner is able to reach low latency with replication and read-only transactions,and high availability across different datacenters.
- TrueTime API provides a small clock drift and small bound for clock uncertainty.

### Open Questions [Where to go from here?]

- The idea of using time api which exposing clock uncertainty to achieve consistency is really astonishing. Can TrueTime API be used in other distributed systems to achieve consistency?
- Can we use other physical clocks or logical clocks to build Spanner? (Cockroachdb - Hybrid Logic Clock)



![1569993576278](D:\OneDrive\Pictures\Typora\1569993576278.png)



![1569993583091](D:\OneDrive\Pictures\Typora\1569993583091.png)



![1569993754092](D:\OneDrive\Pictures\Typora\1569993754092.png)



![1569993776515](D:\OneDrive\Pictures\Typora\1569993776515.png)





## Summary

- In this paper, the authors present Spanner, which is Google's scalable, multi-version, globally distributed and synchronously-replicated database. This paper describes how Spanner is structured, its feature set and rationale underlying various design decisions. Also, they present the novel TrueTime API that exposes clock uncertainty.
- Spanner assigns globally-meaningful commit timestamps to transactions to reflect serialization order which satisfies external consistency (or linearizability). This is enabled by TrueTime API exposing clock uncertainty.
- Spanner is organized as universe (global) - zone (administrative) -spanserver (data). Each spanserver implements a Paxos state machine and the leader implements a lock table to implement concurrency control and a transaction manager to support distributed transactions. The transaction involving other groups will have a two-phase commit.
- `directory` (or bucket) is the unit of data placement and geographic-replication which is a set of contiguous keys that share a common prefix.
- TrueTime API provides `TT.now()` (low uncertainty current time), `TT.after(t)` (whether `t` has definitely passed) and `TT.before(t)` (whether `t` has deininitely not arrived). It's implemented with a set of `time master` per data center with GPU and `time slave` per machine with atomic locks.
- The concurrency control is divided into four kinds. For each kind, Spanner will assign a timestamp to the transaction.

| Operation                               | Concurrency Control          | Replica Required     |
| --------------------------------------- | ---------------------------- | -------------------- |
| Read-Write Transaction                  | pessimistic (2PL wound-wait) | leader               |
| Read-Only Transaction                   | lock-free                    | leader for timestamp |
| Snapshot Read, client-provided timstamp | lock-free                    |                      |
| Snapshot Read, client-provided bound    | lock-free                    |                      |





## Strength

- Spanner provides externally consistent reads and writes and globally-consistent reads across the database at a timestamp.
- Spanner provides lock-free distributed read transactions.
- The TrueTime API gives accurate global wall-time (strong guarantee on the uncertainty of the time), which can represent the commit order. So timestamp order equals commit order and external consistency is built easily.

## Limitation & Solution

- The TrueTime API requires multiple modern clocks including GPS and atomic clocks.
  - Use other kinds of physical/logical clocks for implementing Spanner. [AugmentedTime](http://muratbuffalo.blogspot.com/2013/08/beyond-truetime-using-augmentedtime-for.html) [HybridClocks](http://muratbuffalo.blogspot.com/2014/07/hybrid-logical-clocks.html)
- Lack of proof on absolute error bounds of the TrueTime API