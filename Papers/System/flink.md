# Apache Flink™: Stream and Batch Processing in a Single Engine  

**Paris Carbone, Stephan Ewen, Seif Haridi**

---



## Introduction

* Flink: open-source system for processing streaming & batch data
* data processing applications can expressed & executed as pipelined fault-tolerant dataflows
* data-stream processing + static (batch) data processing
* streams into static data sets, orchestrate the creation & processing of batches (continuous data processing pipeline), lambda architecture (multiple path of computation, a streaming approximate fast path + batch offline accurate path)
  * high latency (by batch)
  * high complexity (connecting & orchestrating several systems, implementing business logic twice)
  * arbitrary inaccuracy
* Flink: data-stream processing as unifying model for real-time, continuous, batch processing
  * durable message queues allowing quasi-arbitrary reply of data streams
  * stream processing
  * continuously aggregation data periodically in large windows
  * processing historical data
  * specialized API for processing static data sets



## System Architecture

* ![image-20191026111544573](D:\OneDrive\Pictures\Typora\image-20191026111544573.png)
* domain-specific API
* DataSet API for processing finite data sets (batch processing)
  * cost-based query optimization phase
* DataStream API for processing potentially unbounded data streams (stream processing)
* distributed dataflow engine
  * DAG of stateful operators connected with data streams
* client: program code → dataflow graph → JobManager
  * schema, serializer, type/schema specific code
* JobManager: coordinate the distributed execution
  * state/progress, scheduler, checkpoint/recovery
  * minimal set of metadata at each checkpointing to a fault-tolerant storage
  * standby reconstruction
* TaskManager: execute operators → streams
  * report status
  * buffer pools to buffer/materialize streams/network connections



## The Common Fabric: Streaming Dataflows

* ![image-20191026112840816](D:\OneDrive\Pictures\Typora\image-20191026112840816.png)
* Dataflow graph
  * DAG
  * stateful operators
    * 1+ parallel subtasks
    * stateless as processing logic
  * datastreams that represent data produced by an operator, available for consumption by operators
    * 1+ stream partitions (1 partition per producing subtask)
* Data exchange: intermediate data streams
  * logical handle to data
  * pipelined & blocking data exchange: 
    * pipelined intermediate streams
      * concurrently exchanging producer/consumers
      * propagate back pressure from consumers to producers
      * continuous streaming programs
    * blocking stream
      * buffer all producing operator's data
      * spill to secondary storage
      * don't propagate backpressure
      * isolate successive operators
  * balancing latency & throughput
    * exchange of buffers
      * as soon as it's full
      * when timeout condition is reached
  * control events
    * special events injected into data stream by operators
    * delivered in-order along with all other data records & events within a stream partition
    * receiving operators react to these events
    * checkpoint barriers: coordinate checkpoints (per-checkpoint/post-checkpoint)
    * watermarks: signaling the progress of event-time within a stream partition
    * iteration barriers: signaling a stream partition reaching end of a superstep
  * no order guarantee after re-partitioning
* Fault tolerance
  * strict exactly-once-processing consistency
  * checkpointing
    * distributed consistent snapshots
    * snapshot of state of operators
      * current position of the input stream at regular intervals
    * Asynchronous Barrier Snapshotting
      * ![image-20191026141053909](D:\OneDrive\Pictures\Typora\image-20191026141053909.png)
      * operator receives barrier → alignment → write current state to durable storage → forward barrier downstream → global snapshot completed
      * Chandy-Lamport algorithm 
  * partial re-execution
    * revert all operator states to their respective states taken from the last successful snapshot, restart the input stream starting from the latest barrier where snapshot is.
      * limited by the amount of input records between 2 consecutive barriers
      * additionally replaying unprocessed records buffered at the immediate upstream subtasks
  * exactly-once state updates without ever pausing the computation
  * completely decoupled from other forms of control messages
  * completely decoupled from the mechanism used for reliable storage
* Iterative dataflows
  * iteration steps, special operators that themselves can contain an execution graph
  * iteration head/tail tasks implicitly connected with feedback edges
  * Bulk Synchronously Parallel model
  * ![image-20191026145410634](D:\OneDrive\Pictures\Typora\image-20191026145410634.png)



## Stream Analytics on Top of Dataflows

* time

  * event-time (event timestamp)
    * reliable
    * ingestion time (events enter Flink)
  * processing -time (wall-clock time)
    * low latency, less reliable

* arbitrary skew?

* insert low watermark as global progress measure

  * time attribute $t$, all events lower than $t$ have already entered an operator
  * watermark propagation
    * forward
    * minimum
    * calculation

* stateful stream processing

  * counter, sum, classification tree, large sparse matrix
  * stream windows
  * providing
    * operator interfaces or annotations to statically register explicit local variables within the scope of an operator
    * an operator-state abstraction for declaring partitioned k-v states & associated operations
  * configure
    * how state stored, checkpointed by `StateBackend`

* stream windows

  * assigner/window: assigning each record to logical windows

  * trigger: when the operation associated with the window definition is performed

  * evictor: which record to retain within each window

  * ```
    stream
        .window(SlidingTimeWindows.of(Time.of(6, SECONDS), Time.of(2, SECONDS))
        .trigger(EventTimeTrigger.create())
    
    stream
        .window(GlobalWindow.create())
        .trigger(Count.of(1000))
        .evict(Count.of(100))
    ```

  * periodic time- / count-, punctuation, landmark, session, delta...

* asynchronous stream iteration

  * as iterative dataflows



## Batch Analytics on Top of Dataflows

* Batch computations are executed by the same runtime as streaming computations. parameterized with blocked data stream to break up large computations into isolated stages successively
* Periodic snapshotting is turned off when its overhead is high. Instead, replaying the lost stream partitions from latest materialized intermediate stream
* Blocking operators are simply operator implementations that happen to block until they have consumed their entire input. JVM heap, spill
* DataSet API
* Query optimization layer
  * plan equivalence, cost modelling, interesting-property propagation
  * UDF-heavy DAGs handing semantics → execution strategies like repartition, broadcast data transfer, sort-based grouping, sort-/hash-based join
  * enumerate different physical plans based on the concept of interesting properties propagation, using a cost-based approach to choose among multiple physical plans
* Memory management
  * JVM heap
  * sort/join as much as possible on binary data directly
  * type inference, custom serialization mechanisms
  * cache-efficient & robust algorithms
    * Batch Iterations
      * BSP, State Synchronous Parallel (SSP) model





## Motivation

* Data-stream processing and static batching data processing  are either considered distinct jobs, or combined with frameworks (streams to batched static data sets, or multi-paths handling approximate and accurate results). However, the existing unifying solutions suffer frame high latency, high complexity and arbitrary inaccuracy.

## Summary

* In this paper, the authors present Apache Flink, which is a open-source distributed system for unifying the real-time streaming data and static batched data computation. Flink provides DataStream and DataSet API for streaming and batch data analysis. Flink employs stateful operators and data streams as directed acyclic graphs to distribute and scale the computations. The control events are embedded into the data streams natively to provide fault tolerance.

## Strength

* Flink can provide exactly-once semantics by embedding checkpointing barriers into data streams.
* Flink can represent iterative computations by implicit feedback streams and iterative barriers.

## Limitation & Solution

* This paper lacks of evaluation part. Also, this paper contains little detail about optimizations, scheduling, handling real-time metrics.

