# Structured Streaming: A Declarative API for Real-Time Applications in Apache Spark  

**Michael Armbrust, Tathagata Das, Ion Stoica, Matei Zaharia et al.**

---



## Introduction

* Structured Streaming: high-level streaming API in Apache Spark
* purely declarative API
  * automatically incrementalizing a static relational query (SQL / DataFrames)
  * not asking users to build a DAG of physical operators
* end-to-end real-time applications
  * integrate streaming with batch & interactive analysis
  * key challenge in practice
* rich operational features
  * rollbacks, code updates, mixed streaming/batch execution
* challenges
  * streaming systems ask users to think in terms of complex physical execution concepts
    * at-least-once delivery, state storage, triggering modes, unique to streaming
  * many systems focus only on streaming computations, streaming is only a part of a larger business applications (batch analytics + join with static data + interactive queries)
* Structured Streaming
  * high-level API for stream processing
  * separating processing time from event time & triggers
  * using a relational execution engine for performance
  * offering a language-integrated API
  * simple to use, integrate with Apache Spark
* Incremental query model
  * automatically incrementalize queries on static datasets expressed through Spark's SQL & DataFrame APIs
* Support for end-to-end applications
  * interacting with external systems
  * integrated into larger applications using Spark
  * data sources/sinks follow a transactional model (exactly-once by default)
  * easy to run a streaming query as a batch job or develop hybrid applications that join streams with static data computed through Spark's batch APIs
  * multiple streaming queries dynamically & run interactive queries on consistent snapshots of stream output
* Reuse Spark SQL execution engine
  * optimizer, runtime code generator
  * microbatch execution mode / low-latency continuous operators for some queries
* Support failures, code updates, recomputation
  * WAL logs



## Stream Processing Challenges



### Complex & Low-level APIs

* complex API semantics
  * what type of intermediate results the system should output
  * low-level nature of streaming APIs
    * level of physical operators
    * complex semantics
* Google Dataflow: powerful  API with rich set of options for handling event time aggreagation / windowing / OoO data
  * user specifies windowing mode, triggering mode, trigger refinement mode (delta / accumulated result) for each aggregation operator
  * physical operator graph, not logical query
* Spark Streaming / Flink DataStream
  * DAGs of physical operators
  * complex array of options for managing state
  * more complex for relax exactly-once semantics (consistency model)
* incremental query model
* customizable stateful processing operators (user own processing logic)
  * custom session-based window



### Integration in End-to-End Applications

* many streaming APIs focus on reading streaming inputs from sources & writing streaming output to sink
* end-to-end business applications require more
  * enable interactive queries on fresh data
    * update summary tables in a structured storage system (RDBMS, Apache Hive)
    * streaming job should do it atomically
  * Extract, Transform, Load (ETL) job need to join a stream with static data loaded from another storage system / transformed using a batch computation
    * reasonable consistency across 2 systems
    * whole computation in a single API
  * run its streaming business logic as a batch application
    * backfill a result on old data
    * test alternate versions of the code
    * no rewriting
* integrating Structured Streaming closely with Spark's batch / interactive APIs



### Operational Challenges

* management & operation issues
* **Failures**: single node failures / graceful shutdown + restart
* **Code Updates**: update code to restart, recompute / update runtime
* **Rescaling**: varying load over time, increasing load in the long term
  * scale up/down dynamically
  * shouldn't be static communication topology
* **Stragglers**: HW/SW issues, degrading throughput
* **Monitoring**: give operators clear visibility into system load/backlogs/state size & metrics



### Cost & Performance Challenges

* 24/7 applications
* leverage all execution optimizations in Spark SQL
* optimize throughput as main metric
* latency-sensitive applications (HFT, physical system control loops) often run on a single scale-up processor / custom hardware (ASIC, FPGA)
* continuous processing mode



## Structured Streaming Overview

* ![image-20191103150039127](D:\OneDrive\Pictures\Typora\image-20191103150039127.png)
* **Input/Output**
  * Input sources must be replayable
    * system to re-read recent input data if a node crashes
    * reliable message bus, like Amazon Kinesis / Apache Kafka / durable FS
  * Output sink must support idempotent writes
    * reliable recovery if a node fail while writing
    * atomic output for certain sinks that support it
      * entire update to the job's output appears atomically event multiple nodes working in parallel
  * I/O from tables in Spark SQL
* **API**
  * SQL / DataFrame
  * output table into a sink incrementally
    * incremental view maintenance
    * different output modes (append-only, record k-v)
  * Triggers: control how often the engine will attempt to compute a new result & update the output sink (like Dataflow)
  * Event time: a column (timestamp at data source), watermark policy (when enough data has been received to output for a specific event time)
  * Stateful operator: track/update mutable state by key in order to implement complex processing (Spark Steam `updateStateByKey`)
* **Execution**
  * query → optimize → incrementalize → execute
  * micro-batch model
    * dynamic load balancing, rescaling, fault recovery, straggler mitigation
  * continuous processing model
  * durable storage
    * write-ahead log
      * which data has been processed reliabily written to the output sink from each input source
    * large-scale state store for snapshots
      * operator states
      * asynchronously, automatically track, recompute on failure
    * pluggable storage systems
* **Operational Features**
  * several forms of rollback & recovery
  * entire Strcutured Streaming application can shutdown & restart on new hardware
  * tolerate node crashes/additions/stragglers
  * code updates to UDFs: stop & restart application
  * manually rollback in the log, redo computation
  * micro-batches → adaptively batch data for load spikes & rollback



## Programming Model

* ```scala
  // Define a DataFrame to read from static data
  data = spark . read . format (" json "). load ("/in")
  // Transform it to compute a result
  counts = data . groupBy ($" country "). count ()
  // Write to a static data sink
  counts . write . format (" parquet "). save ("/ counts ")
  
  // Define a DataFrame to read streaming data
  data = spark . readStream . format (" json "). load ("/in")
  // Transform it to compute a result
  counts = data . groupBy ($" country "). count ()
  // Write to a streaming data sink
  counts . writeStream . format (" parquet ")
  		. outputMode (" complete "). start ("/ counts ")
  
  // Count events by windows on the " time " field
  data . groupBy ( window ($" time ","1h","5min")). count ()
  ```

* Semantics

  * Each input source provides a partially ordered set of records over time
  * The user provides a query to execute across the input data → result table at any given point in processing time
    * prefix integrity/consistency: produce results consistent with running this query on a prefix of the data in all input sources
      * guarantee when input records are relatively ordered within a source → incorporate in the same records
      * all rows in the result table reflect all input records
    * contents of result table is independent of the output mode
  * Triggers: when to run a new incremental computation & update the result table
  * The sink's output mode specifies how the result table is written to the output system
    * `Complete`: whole result table at once
    * `Append`: add records to the sink
    * `Update`: update the sink in place based on a k-v
    * might be incompatible with certain types of query

* ![image-20191103163809393](D:\OneDrive\Pictures\Typora\image-20191103163809393.png)

* Streaming Specific Operators

  * Spark SQL opreators: selection, aggregation, join

  * watermarking: when to "close" an event time window, output results or forget state

    * treat application-specified timestamps as an arbitrary field in the data, allowing records to arrive out-of-order
    * [[Q: how to satisfy prefix consistency without watermark? by retraction?]]
    * Allowing arbitrary late data might require storing arbitrarily large state
    * Some sinks don't support data retraction, making it userful to write results for a given event time after a timeout
    * `withWatermark` operators
      * delay threshold $t_C$ for a given timestamp column $C$
      * watermark for $C$ is $max(C) - t_C$ ($t_C$ seconds before the maximum event time seen so far in $C$)
      * robust to backlogged data
    * affect when stateful operators can forget old state / when Structured Streaming will output data with an event time key to append-mode sinks

  * stateful operators: custom logic for complex processing

    * UDFs with state

    * `mapGroupsWithState: Set[K, V] → (Func(K, V, S) → R) → ?`

      * `K`: key type, `V`: new values of type Iteartor, `S`: state of type GroupState, `R`: a new table with final `R` record outputed for each group in the data

      * ```scala
        // Define an update function that simply tracks the
        // number of events for each key as its state , returns
        // that as its result , and times out keys after 30 min.
        def updateFunc ( key : UserId , newValues : Iterator [ Event ],
        				state : GroupState [Int ]): Int = {
            val totalEvents = state . get () + newValues . size ()
            state . update ( totalEvents )
            state . setTimeoutDuration ("30 min ")
            return totalEvents
        }
        
        // Use this update function on a stream , returning a
        // new table lens that contains the session lengths .
        lens = events . groupByKey ( event => event . userId )
        			. mapGroupsWithState ( updateFunc )
        ```

    * `flatMapGroupsWithState`

      * return 0+ values of type `R` per update instead of 1



## Query Planning

* using Catalyst extensible optimizer in Spark SQL
* **Analysis**
  * Spark SQL: resolve attributes & types
  * check if query executed incrementally by engine
  * check user's chosen output mode is valid for query
* **Incrementalizaiton**
  * incrementalizer aims to ensure the query result updated in time proportional to amount of new data received before each trigger / amount of new rows have to be produced
  * supported queries
    * Any # of selections, projections, `SELECT DISTINCT`s
    * Inner, left-outer, right-outer joins between stream & table / 2 streams.
      * for outer join with stream, join condition must involve a watermarked column
    * stateful operator like `mapGroupWithState`
    * up to 1 aggregation (possibly on compound keys)
    * sorting after an aggregation (only in complete output mode)
  * query -> Catalyst -> trees of physical operator (computation / state management)
  * track output mode for each physical operator (like refinement mode for Dataflow)
  * [WIP] automatic incrementalization (by SMT solver? [[C: distribute_aggregation]])
* **Query Optimization**
  * Spark SQL optimization rules: predicate pushdown, projection push down, expr, simplification
  * Tungsten binary format for data in memory (no overhead of Java object)
  * runtime code generator



## Application Execution

* ![image-20191104111846938](D:\OneDrive\Pictures\Typora\image-20191104111846938.png)
* execution mode
  * microbatching via fine-grained tasks
  * continuous processing via long-lived operators
* **State Management & Recovery**
  * state of application -> WAL (durable, atomic, low latency) + state store (large, durable, parallel)
  * As input operators read data, master node of the Spark application defines epochs based on offset in each input source. Master writes start/end offset of each epoch durably to the log.
  * Any operators requiring state checkpoint their state periodically & asynchronously to the state store
    * epochID along with each checkpoint
    * don't need happen on each epoch
    * don't block processing
  * Output operators write the epochs committed to the log. Master waits for all nodes running an operator to report a commit for a given epoch before allowing commits for the next epoch.
    * if sink permits, master run an operation to finalize the writes from multiple nodes.
    * If application fails, only 1 epoch partially written
    * [[Q: so this is a barrier for stages?]]
  * Upon recovery, new instance of application starts by reading the log, find last epoch has not been committed to the sink (start/end), use offsets to reconstruct the application's in-memory state from last epoch written to state store (load, run disabling output), rerun last epoch (sink idempotence).
* **Microbatch Execution Mode**
  * [[R: Aka BSP, check Drizzle]]
  * discretized stream
  * dynamic load balancing
    * small, independent tasks
  * rescaling
    * add/remove node is task migration
  * straggler mitigation
    * backup copy
  * fine-grained fault recovery
    * task re-run, not system
    * parallel recovery
  * scale & throughput
    * Spark optimization (high-perf shuffle...)
  * higher minimum latency
* **Continuous Processing Mode**
  * low-latency, less operational flexibility (low adaptability in Drizzle def.)
  * how to choose a declarative API for Structured Streaming? (unified API with microbatch)
  * SS API like more triggers
  * two difference
    * Master launches long-running tasks on each partition using Spark's scheduler that each read 1 partition of the input source but execute multiple-epochs
      * re-launch if fail
    * Epochs coordinated differently
      * Master periodically tells nodes to start new epoch, receive start offset for the epoch, insert into the WAL
      * Master asks nodes to start next epoch, receive end offset for the previous one, insert into WAL, tell nodes to commit the epoch when all end offsets written.
  * low-latency use
  * scale of a distributed processing engine is stream-stream map
  * minimize transformation job



## Operational Features

* easy to understand SS's semantics & fault tolerance model
* **Code Updates**
  * update (stateful) UDFs, restart
  * log/state store formats compatible between updates
* **Manual Rollback**
  * wrong results due to user application
  * WAL as JSON
  * remove faulty data from output sink
  * restart from a previous epoch
  * prefix consistency
    * running same code as a batch job, for rescaling
* **Hybrid Batch & Streaming Execution**
  * "Run-once" triggers for cost savings: batch job, ETL
  * Adaptive batching: large backlog, longer epochs
* **Monitoring**: Spark metrics
* **Fault & Straggler Recovery**
  * Microbatch: recover from node failures, stragglers, load balancing
  * Continuous: recover from node failures, not protect straggler & load balancing



## Production Use Cases

* ![image-20191104140515651](D:\OneDrive\Pictures\Typora\image-20191104140515651.png)
* building robust +scalable streaming pipeline
* providing the analysts with an effective environment to query both fresh & historical data
* Information Security
* Video Delivery
* Game Performance
* Cloud Monitoring
* [[T: Use cases]]







## Motivation

* Streaming processing is ubiquitous for processing real-time data. However, the existing systems remain fairly challenging to use in practice. They often provide complex and low-level APIs requiring DAG building and user-acknowledging semantics. Also streaming workload within the context of a larger applications requires significant engineering effort on integration. Meanwhile, the streaming applications need to care about their management, operation, cost and performance.

## Summary

* In this paper, the authors present Structured Streaming. Structured Streaming requires the source to by replayable and sink to support idempotent writes to satisfy its prefix consistency model. It uses a API similar to Apache Spark with extra watermarking, event time denotations and stateful operators. The input and output support different modes for various kinds of sources and sinks. The query planning is based on Spark Catalyst optimizer. The execution engine supports two mode: microbatch(BSP) and continuous operator. Both mode supports fault tolerance by write-ahead epoch offset logs and checkpoint state store to durable stores. Structured Streaming is widely used on production for different kinds of workloads.

## Strength

* Structured Streaming provides similar API to Spark, which unifies the execution mode of BSP and Continuous operators.
* Structured Streaming supports end-to-end applications, which makes it a ideal component in complicated systems. 
* Structured Streaming provides prefix consistency based on its sink and source requirements, which is indeed useful in production.

## Limitation & Solution

* Prefix consistency without watermark needs retraction support in sinks.
  * The paper doesn't mention without watermark, how Structured Streaming handles randomly-long event time delay.
* The incompability between operators and sources/sinks is discovered in optimizer, rather than early stage in developing.
  * Need a different layer of abstraction.

