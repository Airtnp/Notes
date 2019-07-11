# [Spanner](https://static.googleusercontent.com/media/research.google.com/zh-CN//archive/spanner-osdi2012.pdf)

###### James C. Corbett, Jeffrey Dean, Michael Epstein et al.

------

From EECS582/Notes/Wk9

Re-read? `!TODO`



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