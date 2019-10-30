# Naiad: A Timely Dataflow System  

**Derek G. Murray, Frank McSherry, Rebecca Isaacs et al.**

---



## Introduction

* Naiad: distributed system for executing data parallel, cyclic dataflow programs
  * high throughput of batch processors
  * low latency of stream processors
  * able to perform iterative & incremental computations
  * working set fits in the aggregate RAM
  * coordinate distributed process with low overhead
  * avoid stalls from lock contention/dropped packets/garbage collection
* _timely dataflow_ computation model
  * timestamp represents logical points in the computation
* ![image-20191027010706818](D:\OneDrive\Pictures\Typora\image-20191027010706818.png)
* requirements
  * iterative processing on a real-time data stream
  * interactive queries on a fresh & consistent view of the results
* existing systems
  * stream processors can produce low-latency results for non-iterative algorithms
  * batch systems can iterate synchronously at the expense of latency  
  * trigger-based approaches support iteration with only weak consistency guarantees
* timely dataflow
  * structured loops allowing feedback in the dataflow
  * stateful dataflow vertices capable of consuming & producing records without global coordination
  * notifications for vertices once they have received all records for a given round of input or loop iteration
  * low-level primitives
  * directed, cylic
  * stateful vertices: asynchronously receive messages & notifications of global progress
  * edges: records with logical timestamp enabling global progress to be measured
    * logical timestamps reflect graph topology



## Timely dataflow

* computational model based on a directed graph
  * stateful vertices send & receive logically timestamped messages along directed edges
  * dataflow graph may contain nested cycles
  * timestamps reflect this structure in order to distinguish data that arise in different input epochs & loop iterations
  * concurrent execution of different epochs & iterations
  * explicit vertex notification after all messages with a specified timestamp have been delivered
* timely dataflow graph
  * external producer
    * label message with integer epoach
    * notify input vertex when it will not receive any more messages with a given epoch label
    * may close an input vertex to indicate it will receive no more messages from any epoch
  * input vertices, receive sequence of messages from an external producer
  * output vertices, emit sequence of messages back to an external consumer
    * labeled with its epoch
    * signal the external consumer when it will not output any more messages from a given epoch / all output is complete
  * vertices are organized into possibly nested loop contexts with 3 associated system provided vertices
    * ![image-20191027103730235](D:\OneDrive\Pictures\Typora\image-20191027103730235.png)
    * edges entering a loop context: pass through ingress vertex
    * edges leaving: pass through egress vertex
    * each cycle in graph: contained entirely within loop contexts, include 1+ feedback vertex
  * message timestamp
    * ![image-20191027104005634](D:\OneDrive\Pictures\Typora\image-20191027104005634.png)
    * loop counter: for each of the k loop contexts that contain the associated edge
      * distinguish different iterations
      * allow a system to track forward proress as messages circulate around the dataflow graph
    * ![image-20191027104309186](D:\OneDrive\Pictures\Typora\image-20191027104309186.png)
* vertex computation
  * ![image-20191027105910760](D:\OneDrive\Pictures\Typora\image-20191027105910760.png)
  * `v.ONRECV(e : Edge, m : Message, t : Timestamp)`
    * queued
    * arbitrary code, modify arbitrary per-vertex state
    * only call `SENDBY` with `t' >= t`
    * may send elements on the first output ASAP, for low latency
  * `v.ONNOTIFY(t : Timestamp)  `
    * queued
    * arbitrary code, modify arbitrary per-vertex state
    * only call `NOTIFYAT` with `t' >= t`
    * invoked only after no further invoationof `v.ONRECV(e, m, t')` for `t' <= t`
    * indicate all `v.ONRECV(e, m, t)` invocations have been delivered to the vertex
    * opportunity for the vertex to finish any work associated with time `t`
    * delay sending the counts until all inputs have been observed
  * `this.SENDBY(e : Edge, m : Message, t : Timestamp)
    `
    * dual of `ONRECV`
  * `this.NOTIFYAT(t : Timestamp)  `
* Achieving timely dataflow
  * the set of timestamps where future message can occur is constrained by
    * current set of unprocessed events (messages / notifications)
    * graph structure
  * event as timestamp + location (vertex / edge) -> pointstamp
    * ![image-20191027111357619](D:\OneDrive\Pictures\Typora\image-20191027111357619.png)
    * `v.SENDBY(e, m, t)` $\to$ `(t, e)`
    * `v.NOTIFYAT(t)` $\to$ `(t, v)`
  * order on pointstamp
    * $(t_1, l_1)$ could-result-in $(t_2, l_2)$
      * iff. $\exists \psi = \langle l_1, \cdots, l_2 \rangle$ such that $\psi(t_1)$ results from adjusting $t_1$ according to each ingress, egress or feedback vertex occurring on that path satisfies $\psi(t_1) \leq t_2$
      * $\Psi[l_1, l_2](t_1) \leq t_2$
    * path summary between $l_1$ and $l_2$ is a function that transforms a timestamp at $l_1$ to a timestamp at $l_2$
      * summary the path by loop coordinates that its vertices remove/add/increment
    * For any locations $l_1$ & $l_2$ connected by 2 paths with different summaries, 1 of the path summaries always yields adjusted timestamps earlier than the other.
    * $\Psi[l_1, l_2]$: the minimal path summary over all paths from $l_1$ to $l_2$ using graph propagation algorithm
  * single-threaded scheduler
    * maintain a set of active pointstamps (correspond to 1+ unprocessed events)
    * occurrence count: how many outstanding events bear the pointstamp
      * ![image-20191027154515146](D:\OneDrive\Pictures\Typora\image-20191027154515146.png)
      * scheduler apply update at the start of calls to `SENDBY` & `NOTIFYAT`, as `ONRECV` & `ONNOTIFY` complete
      * leave active set when its occurrence count drops to 0
    * precursor count: how many active pointstamp precede it in the could-result-in order
      * when pointstamp $p$ active, scheduler initializes its precursor count to # of existing active pointstamps that could-result-in $p$
      * decrement precursor count for any pointstamp that leaving active set and could-result-in this pointstamp
    * frontier: no other pointstamp in the active set that could-result-in $p$
      * scheduler deliver any notification in the frontier
  * system initializations
    * 1 active pointstamp at the location of each input vertex,
      * timestamped with the 1st epoch, 
      * occurrence count of 1, 
      * precursor count of 0
    * when a epoch $e$ is marked complete the input vertex adds a new active pointstamp for epoch $e + 1$, then removes the pointstamp for $e$
      * permitting downstream notifications to be deliveered for epoch $e$
    * when the input vertex is closed, it removes any active pointstamps at its location
      * allowing all events downstream of the input to eventually drain from the computation
  * Check [Formal Analysis of a Distributed Algorithm for Tracking Progress](https://www.microsoft.com/en-us/research/publication/formal-analysis-of-a-distributed-algorithm-for-tracking-progress/?from=http%3A%2F%2Fresearch.microsoft.com%2Fapps%2Fpubs%2Fdefault.aspx%3Fid%3D199767 ) for detail
* Discussion
  * vertex explicitly request notifications (not passively receive)
    * make performance tradeoff by choosing when to use coordination
  * notification in timely dataflow
    * guaranteed not to be delivered before a time $t$ (guarantee time $t_g$)
    * has capability to send messages at times greater or equal $t$ (capability time $t_c$)



## Distributed implementation

* Naiad: high performance distributed implementation of timely dataflow
* ![image-20191027190844466](D:\OneDrive\Pictures\Typora\image-20191027190844466.png)
* group of processes hosting workers managing partition of the timely dataflow vertices
  * [[N: process hosting multiple workers]]
* Data parallelism
  * increase aggregation computation/memory & bandwidth available
  * _logical graph_ of _stages_ linked by typed _connectors_
    * connectors optionally have partitioning function to control the exchange of data between stages `H(m)`
  * logicla graph into → physical graph (stage is replaced by a set of vertices & each connector by a set of edges)
  * regular structure
    * simplfy vertex implementation
    * simplfy reasoning about the could-result-in relation
      * project each pointstamp $p$ from physical graph to pointstamp $\hat{p}$ in the logical graph
      * evaluate could-result-in relation on the projected pointstamps
      * may loss of resolution
      * but ensures the size of data structure depends only on the logical graph, not the much larger physical graph
* Workers
  * responsible for delivering messages & notifications to vertices in its partition of the timely dataflow graph
    * multiple runnable actions (msg/notification) → break ties by delivering msgs before notys → reduce amount of queued data
  * communicate using shared queues (only shared state)
    * only a single thread of control ever executes within a vertex
    * allow simpler vertex implementation
    * `SENDBY` → calling vertex yield if destination the destiniation vertex by same worker → `ONRECV` callback rather than queuing
      * keep queue small, low latency
      * re-entrancy: cycles of dataflow graphs
        * vertex interrupted by `SENDBY` it calls may re-enter by 1 of its `ONRECV` callbacks
        * default, just enqueue the messages (since vertices are not re-entrant)
        * could optionally specify a bounded depth for re-entrant calls
* Distribtued progress tracking
  * before delivering a notification, a Naiad worker must know that there are no outstanding events at any worker in the system with a pointstamp that could-result-in the pointstamp of the notification
  * progress tracking based on a single global frontier to a distributed setting in which multiple workers coordinate independent sets of events using a local view of the global state
    * broadcasting occurrence count updates
    * For each active pointstamp, each worker maintains
      * a local occurrence count: local view of the global occurrence counts
      * a local precursor count: omputed from its local occurrence counts
      * a local frontier: defined using the could-result-in relation on the local active pointstamps
      * broadcast (to all workers, include self) progress updates
        * pairs $p \in$ Pointstamp, $\delta \in \mathbf{Z}$ 
          * $\delta$ chosen described above
        * when a worker receives a progress update $(p, \delta)$, it adds $\delta$ to its local occurrence count for $p$
    * no local frontier ever moves ahead of the global frontier, taken across all out-standing events in the system.
  * optimizations
    * use projected pointstamps in the progress tracking protocol
      * keep tracks of occurence/precursor count for each stages & connector (not each vertex/edge)
        * reduce opportunity for concurrent
        * reduce volumes of update & size of state maintained
    * accumulate updates in a local buffer before broadcasting them
      * update with the same pointstamp combined into a single entry in the buffer by summing their deltas
      * accumulate should satisfy
        * either some other element of the local frontier could-result-in $p$
        * or $p$ corresponds to a vertex whose net update (sum of local occurrence count + buffered update count + any updates that the worker has broadcast but not yet received) is strictly positive
          * [[Q: why???]]
      * test condition, if not, broadcast, otherwise, accumulate as long as possible
        * positive values must be send before negative values
      * any fixed group of workers can perform accmulation
      * may performed hierarchically
        * default, process level, cluster level
    * decrease expected latency of broadcasting updates
      * central cluster-level accumulator optimistically broadcasts a UDO packet containing each update before re-sending updates on the TCP connections between the accumulator & other processes
        * sequence id for idempotent & acknowledgement
      * eventcount synchronization primitive: allow threads to be woken by either a broadcast/unicast notifications
* Fault tolerance
  * each stateful vertex implements a `CHECKPOINT` & `RESTORE` interface
    * either log, respond to checkpoint requests with low latency
    * or write a full & potentially more compact, checkpoint when requested
  * system invokes these as appropriate to produce a consistent checkpoint across all workers
    * pause worker & message delivery threads
    * flush message queues by delivering outstanding `ONRECV` events (buffering & logging any message are sent by doing so)
    * invoke `CHECKPOINT` on each stateful vertex
    * resume worker & message delivery threads
    * flush buffered messages
  * stateful progress tracking components implement full checkpoints
  * recovery
    * live processes revert to last durable checkpoint
    * vertices from the failed process reassigned to remaining processes
    * `RESTORE`: reconstructs the state of each stateful vertex using its respective checkpoint file
  * fine-grained updates to mutable state vs. reliably logging enough info for consistent recovery
  * favor performance in the common case, at the expense of availability in the event of a failure
    * consume inputs from a reliable message queue & write outputs to distributed k-v store
      * fast recovery, but cost some freshness
* Preventing micro-stragglers
  * sensitive to latency: transient stall at a single worker can have disproportionate effects on overall performance
  * micro-stragglers as the main obstacle to scalability for low-latency workloads
  * mutable state to decrease the latency of execution → speculative execution would request heavier coordination update to replicate states
  * source & mitigations
    * networking
      * TCP over Ethernet for remove messages, NIC accelerates protocol stacks
      * bursty throughput (begin with large data exchange, downward to tail small packets)
      * Nagle & delayed acknowledge increases delay
      * disable Nagle's algorithm, reduce delayed acknowledgement timeout
      * reduce minimum retransmit timeout
      * Datacenter TCP
      * specialized transport protocol
        * RDMA over InfiniBand → microsecond message ltency, reliable multicast, user-space acccess to message buffers
          * avoid TCP-related timers
          * attention to QoS
    * data structure contention
      * most data structured, particular vertex state accessed from a single worker thread
      * coordinate required to exchange message between workers
        * .NET concurrent queues
        * lightweight spinlocks
      * decrease clock granularity to 1ms
      * backoff by sleeping 1ms
    * garbage collection
      * .NET runtime: mark & sweep garbage collector
        * suspend thread execution during allocations & micro-stragglers
        * cost is proportional to # of pointers (not objects)
      * use bufferpools to recycle message buffers & transient operator state (queues)
      * value type arrays (single pointer)



## Writing programs with Naiad

* common pattern

  * define a dataflow graph

    * input stages
    * computational stages
    * output stages

  * repeatedly supply the input stages with data

  * ```c#
    // 1a. Define input stages for the dataflow.
    var input = controller.NewInput<string>();
    
    // 1b. Define the timely dataflow graph.
    // Here, we use LINQ to implement MapReduce.
    var result = input.SelectMany(y => map(y))
    				.GroupBy(y => key(y),
    						(k, vs) => reduce(k, vs));
    
    // 1c. Define output callbacks for each epoch
    result.Subscribe(result => { ... });
    
    // 2. Supply input data to the query.
    input.OnNext(/* 1st epoch data */);
    input.OnNext(/* 2nd epoch data */);
    input.OnNext(/* 3rd epoch data */);
    input.OnCompleted();
    ```

* data parallel pattern

  * a library of incremental LINQ-like opeators
    * unary/binary form of a generic buffering operators
      * `ONRECV` add records to list indexed by timestamp
      * `ONNOTIFY`: apply a suitable transformation to the list for timestamp $t$
    * no coordination operators in library code
      * decouple evoluation of the LINQ implementation from improvements to the underlying system
      * `Concat`: immediately forward records from both inputs
      * `Select`: transform & output data without buffering
      * `Distinct`: output a record ASA it seen the first times

* construct timely dataflow graphs
  * behavior of dataflow vertices
    * `ONRECV` typed, `ONNOTIFY` if stage support notification
  * define dataflow topology (including loops)
  * stage: collection of vertices defined by a vertex factory
    * multiple I/O with associated record type
      * input partitioning requirement
      * output partitioning guarantee
      * exchange connectors when necessary
    * connect using typed streams whose endpoints must have matching record types
  * `LoopContext` allow programmers to define multiple ingress/egree/feedback stages
    * only feedback stages have their outputs connected before their inputs
    * all cycles conform to the constraints of valid timely dataflow graphs



















[[I: timely dataflow on other systems, main coordination is progress tacking]]

[[I: some new abstraction over timely dataflow?]]

[timely-dataflow in Rust]( https://github.com/frankmcsherry/timely-dataflow )

[naiad-faq-6.824](https://pdos.csail.mit.edu/6.824/papers/naiad-faq.txt)

[naiad-note-6.824](https://pdos.csail.mit.edu/6.824/notes/l-naiad.txt)

[Frank Mcsherry's Blog](https://github.com/frankmcsherry/blog)



## Motivation

* Many data processing tasks require low-latency interactive access to results, iterative sub-computations and consistent intermediate outputs. However, no existing systems satisfies the requirements to perform iterative processing on real-time data streams, support interactive queries on a fresh, consistent view of the results.

## Summary

* In this paper, the authors present Naiad and timely dataflow. Timely dataflow is a powerful general-purpose low-level programming abstraction for iterative, streaming, and batch computation. Timely dataflow coordinates via four primitives `ONRECV`, `ONNOTIFY`, `SENDBY`, `NOTIFYAT` and could-result-in partial order relation on time-based pointstamps. Naiad is built upon timely dataflow with worker threads, processes, and a cluster. Naiad converts logical graphs of stages linked by typed connectors to physical graphs with vertices and edges onto distributed nodes.

## Strength

* Timely dataflow uses simple primitives to coordinate works by tracking progress distributedly. The computation model is powerful and efficient for representing streaming, batching, iterative jobs.
  * without global coordination, but Naiad has a global frontier state.
* Timely dataflow can deal with cylic graphs, which is common among iterative jobs.
* Naiad has impressive performance on high throughput, low latency and scalability.

## Limitation & Solution

* The overhead of failure recovery of Naiad system is high. The system needs to pause the workers to checkpoint into persistent layer and revert to last checkpoint for recovery.
* Naiad is sensitive to straggler performance, and costs much to use traditional speculative execution to solve straggler problems due to mutable state.

