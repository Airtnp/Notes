# Dryad: Distributed Data-Parallel Programs from Sequential Building Blocks

* [link](https://www.microsoft.com/en-us/research/wp-content/uploads/2007/03/eurosys07.pdf)



## Intro

* Large scale internet services
  * clusters of hundereds of general purpose servers
  * future advances local computing power will increase # of cores instead of speed or ILP
* Resources
  * a single adminstrative domain
  * connected using a known, high-performance communication topology
  * under centralized management & control
* Problems
  * high latency & unreliable networks
  * control of resources by separate federated or competing entities
  * issues of identify for authentication and access control
* simplicity, reliablity, efficiency, scalability
* data parallelism for resource-intensive applications
  * fully automatic exploit? -> limitations exist
  * inspiration
    * shader langauge for GPU
    * MapReduce system
    * parallel databases
  * communication graph
  * developers to supply subroutines to be executed at specified graph vertices
* major reason of success
  * explicitly forced to consider the data parallelism of the computation
  * application casted to framework -> automatic scheduling & distribution
  * no need for understanding concurrency, threads, fine-grained concurrency control
  * system abstraction hiding
    * resource allocation
    * scheduling
    * transient or permanent failure of a subset of components in the system
  * boundary between communication graph & subroutine
    * level of granularity
    * system not try hard to extract parallelism within developer-provided subroutine
    * exploit the fact that dependencies explicitly encoded in flow graph to efficienctly distributed execution across those subroutines
* restriction
  * GPU shader: tied to efficient underlying hardware implementation tuned for good performance for common graphics memory-access patterns
  * MapReduce: simplicity, single input, single output
  * Parallel database: relational algebra manipulations (communication graph is implicit). multiple inputs, single output (internally multiple outputs)
* Dryad
  * developed controlled communication graph & subroutine
  * specify arbitrary directed acyclic graph (communication patterns)
  * express data transport mechanisms (file, TCP pipes, shared memory FIFO) between computation vertices
  * allowing graph vertices (computation) to use arbitrary number of inputs & outputs
  * lower-level programming model  than SQL/DirectX → require developer understanding
* Dryad contributions
  * general-purpose, high performance distributed execution engine.
    * scheduling across resources
    * optimizing the level of concurrency within a computer
    * recovering from communication or computer failures
    * delivering data to where it is needed
    * supporting multiple different data transport mechanisms
  * excellent performance from single multi-core to clusters
  * programmability
    * simple graph description language
    * simpler, higher-level programming abstractions for specific application domains



## System Overview

*  Job: directed acyclic graph
  * vertex: program
  * edges: data channels
* Channel: transport a finite sequence of structured items
  * shared memory/TCP pipes/files temporarily persisted in a file system
  * produce/consume heap objects (inherit from  a base type)
* No native data model for serialization
* ![1570298181214](D:\OneDrive\Pictures\Typora\1570298181214.png)
* Job Manager (JM): coordinate Dryad jobs.
  * application-specific code → construct job's communication graph
  * library code → schedule the work across resources
  * only for control decisions (no data transfer)
* Name Server (NS): enumerate all the available computers
  * expose the position of each computer → scheduling on topology
* Daemon (D): create processes
  * as a proxy for JM
* Vertex (V)
  * binary: JM → D → V→ cache
* Distributed storage system (like GFS)/NTFS
* ![1570299540510](D:\OneDrive\Pictures\Typora\1570299540510.png)
* ![1570299547524](D:\OneDrive\Pictures\Typora\1570299547524.png)
  * U: `photoObjAll` divided by `objid`
  * N: `neighbors` divided by `objid`
  * X: join & filter of U & N
  * D: distribute result to M vertices
  * M: non-deterministic merge & in-memory Quicksort on `neighborObjID`
  * S: M output
  * Y: join & filter of U & 4 * S
  * H: hashtable merge, used for `distinct`
  * ![1570308731100](D:\OneDrive\Pictures\Typora\1570308731100.png)



## Describing a Dryad Graph

* $G = \langle V_G, E_G, I_G, O_G \rangle$
  * $V_G$: vertices
  * $E_G$: directed edges
  * $I_G \subseteq V_G$: input vertices (in degree 0)
  * $O_G \subseteq V_G$: output vertices (out degree 0)
* ![1570300847169](D:\OneDrive\Pictures\Typora\1570300847169.png)
* Singleton graph $G = \langle (v), \emptyset, \{v\}, \{v\}\rangle$
* Clone k copy:
  * $C = G \hat{} k = \langle V_G^1 \oplus \cdots \oplus V_G^k, E_G^1 \oplus \cdots \oplus E_G^k, I_G^1 \oplus \cdots \oplus I_G^k, O_G^1 \oplus \cdots \oplus O_G^k \rangle$
  * $\oplus$: sequence concatentation
* Composition of two graphs:
  * $C = A \circ B  = \langle V_A \oplus V_B, E_A \cup E_B \cup E_{new}, I_A, O_B \rangle$
  * $E_{new}$: directed edges from $O_A$ to $I_B$
  * $V_A, V_B$ should be disjoint to ensure acyclic graph
  * $ A >= B$: pointwise composition
    * round-robin for extra input or output
  * $A >> B$: complete bipartite graph
* Merge two graphs:
  * $C = A || B = \langle V_A \oplus^* V_B, E_A \cup E_B , I_A \cup^* I_B, O_A \cup^* O_B \rangle$
  * $\oplus^*$: concatentation removing duplicates
  * $\cup^*$: union minus vertices which will having an incoming edge after the merge, or outcoming edge after the merge
  * runtime check of acyclic invariant
* [[C: Pi-calculus?]]
* Channel type
  * default: temporary file
  * encapsulation: $G \rightarrow v_G$ graph to vertex (single process)
  * shared-memory FIFO/pipe
    * could deadlock → I/O processes must be executed concurrently → exhaust resources → break abstraction
    * downgrade pipe to temporary file
  * affinity to avoid extra I/O [[C: spark+RDD?]]
  * transport protocol
    * ![1570308480832](D:\OneDrive\Pictures\Typora\1570308480832.png)



## Writing a Vertex Program

* C++ base classes & objects
* incorporate legacy sources/libraries
* avoid adopting any Dryad-specific language or sandboxing restrictions
* vertex execution
  * runtime library
    * input: from JM
    * URI: input/output channels
  * `map`, `reduce`, `distribute`, `join`
* legacy executables
  * process wrapper vertex
* pipelined execution
  * channel
  * asynchronous
  * thread pool



## Job Execution

* JM tracks vertex states → JM failure → vertex scheduler checkpointing or replication
* vertex executed multiple times due to failures
* version number to avoid conflicts
* execution record: state of execution and versions of the predecessor vertices (inputs)
* hard constraint/preference for computers
* greedy scheduling
* Fault tolerance
  * deterministic execution
  * vertex report → D → JM
  * D crash with heartbeat timeout → JM
  * read error → propagate to re-execution
  * stage-manager callback → global lock on JM data structures
    * implement backup task mechanism
* Runtime graph refinement
  * [[C: PGO in graph execution?]]
  * stage-manager callback
  * associative & commutative computations + data reduction
    * ![1570315075944](D:\OneDrive\Pictures\Typora\1570315075944.png)
    * ![1570315784559](D:\OneDrive\Pictures\Typora\1570315784559.png)
    * having grouped the inputs into k sets, the optimizer replicates the downstream vertex k times to allow all of the sets to be processed in parallel 







## Motivation

* How to easily write efficient parallel and distributed applications? For resource-intensive applications, existing solutions (GPU shader language, MapReduce and parallel database) build their success on the explicit force to consider parallelism of computations and automatically handling of scheduling and distribution. However these solutions have restrictions on communication flow and number of inputs and outputs.

## Summary

* The Dryad system organization consists of three control panel components: Job Manager, Name Server and Daemon. They work together to create, schedule and monitor vertices.
* The Dryad graph is specified as vertices (programs) and edges (communications). Dryad exposes graph-related APIs including duplication, composition and merge.
* The jobs are split into stages. For each stage, Dryad can insert a stage-manager callback to do post-stage work including dynamic refinement and backup mechanism.

## Strength

* The way to explicitly specify the application code and acyclic communication graph  gives Dryad flexibility and high performance. Acyclic abstraction helps scheduling of resource allocation.
* Dryad abstraction of communication supports different implementations including message passing and shared memory.

## Weakness & Solution

* Graph based program grammar makes programmer harder to use than normal sequential program.
  * Use techniques like Database middle end SQL to volcano model translator (Like follow-up Dryad LINQ).
  * Use more programmable graph interface. (Like UE4 blueprint)
* Dryad only covers homogeneous programming on CPUs.
  * Add heterogeneous considerations. (Like follow-up Dandelion)