# Trill: A High-Performance Incremental Query Processor for Diverse Analytics  

**Badrish Chandramouli, Jonathan Goldstein, Mike Barnett et al.**

---



## Introduction

* Trill: query processor for analytics
  * Query Model: tempo-relational model that enables it to handle streaming & relational queries with early results, across the latency spectrum from real-time to offline
  * Fabric & Language Integration: high-level language library supporting rich data-types & user libraries, integrate well with existing distribution fabrics & applications
  * Performance: high throughput across latency spectrum
  * streaming batched-columnar data representation
  * dynamic compilation-based system architecture
* Analytics types
  * Real-time streaming queries
    * real-time data
    * reference slow-changing data
  * Temporal queries on historical logs
    * back-testing streaming queries on historical logs
  * Progressive relational queries on collected data
    * interactive exploratory queries over logs
  * interconnected analytics
* ![image-20191027223943339](D:\OneDrive\Pictures\Typora\image-20191027223943339.png)
* Query Model: tempo-relational (temporal) query model concepts unify the diverse analytics space
  * datasets as time-versioned database
    * tuple is associated with a validity time interval
  * temporal datasets presented as an incremental stream to temporal stream processing engine (SPE)
    * process a query incrementally to produce a result temporal dataset
    * deploy continuous queries across real-time streams & historical data
    * back-test real-time queries over historical logs
    * run relational / temporal queries over log data
* Fabric & Language Integration: integration of distribution fabrics for different parts of the execution
  * usable as a library from a hosting high-level language (HLL)
    * DBMS, restricted SQL data-types & expressiones, relational algebra (need richer logic by SQL CLR)
    * Spark with Scala, server model
    * StreamInsight uses LINQ, server model & restricts data-types
    * Naiad uses LINQ, processes arbitrary HLL data-types & expressions
    * Storm, low-level k-v API with rich data-type support, lack performance & declarative query model
      * [[N: Storm doesn't talk about APIs]]
* Performance: automatically & seamless adapt performance in terms of latency & throughput, across the analytics spectrum from offline to real-time
  * SPE-X/DB-X: modern commerical SPE & columnar DBMS
  * SPE has lower throughput than modern columnar DBMS's such as Vertica/SQL Server/Shark (approaching memory bandwidth limit)
  * [[I: Columnar refresh]]
* Architecture
  * ![image-20191027230450594](D:\OneDrive\Pictures\Typora\image-20191027230450594.png)
  * Event-at-a-time
    * low latency
    * low throughput
    * SPE systems
  * Batch-at-a-time
    * mid throughput
    * Naiad
  * Offline
    * high throughput
    * Columnar DBMSs
  * performance difference
    * language intergration preclude the use of efficient DB-style data organization (user-expressions are evaluated as black-boxes over individual rows)
    * user manually navigate the latency spectrum by selecting individual batch sizes
    * temporal operators written as layer outside the engine, cannot be optimized for performance
* Trill (trillion events per day) Architecture
  * Query Model: temporal logical data model
    * diverse spectrum of analytics (real-time/offline/temporal/relational/progressive)
  * Fabric & Language Integration: library in C# HLL
  * Performance: 2-4 order higher than existing on streaming data, comparable to DBMS on offline data
    * fast for simple payload types
    * degrade gracefully as payload become complex
* Trill novelty
  * Support for Latency Spectrum
    * query consist of DAG of operators that process a stream of data-batch messages
    * data-batch: multiple events carefully laid out in timestamp order in main memory
    * batching → high throughput in SPE
      * purely physical, easily variable
    * query results are always identical to the case of per-event processing, regardless of batch size & data arrival rates
    * _punctuations_: user-control desired latency
      * transparently tradeoff throughput for latency
  * Columnar Processing in a HLL:
    * columnar data organization within batches
    * apply over temporal data
    * control fields are columnar
    * dynamic HLL code generation: construct & compile HLL source code on-the-fly for batches & operators, operating over columnar batched data
      * AST of lambda expressions to interpret & rewrite user queries into inlined columnar access inside tight per-batch loops with few sequential memory access & no method calls inside the loop
      * handle string more efficiently by storing as batches with char arrays & rewriting user expressions
      * enable fast serialization by sending columns over the wire without any fine-grained encoding/decoding
  * Fast Streaming Operators
    * coarse-grained columnar nature of data-batches
    * timestamp-order of data
    * → grouped user-defined aggregation framework
      * expression-based user API, comparable to hand-written performance
    * stream proerty derivation framework
      * data characteristics → select from a small set of generated physical operators at compile-time
  * Library Mode & Multi-core
    * query run only on the thread that feed data to it
    * pure library mode, ideal for embedding within frameworks
    * multicore → two-level streaming temporal map-reduce operation, with lightweight optional scheduler



## User Experience

* ingress source

  * real-time push-based sources

  * datasets cached in main memory

  * data streamed from a file / network

  * user-specified latency requirement

  * ```c#
    var str = Network.ToStream(e => e.ClickTime, Latency(10secs));
    var query = str.Where(e => e.UserId % 100 < 5)
    	.Select(e => { e.AdId })
    	.GroupApply(e => e.AdId,
    				s => s.Window(5min).Aggregate(w => w.Count()));
    query.Subscribe(e => Console.Write(e)); // write to console
    ```

* System Overview

  * user query as standard techniques into a DAG of streaming query operators
  * message streams: unit of granularity flowing through Trill
  * data pushed from external sources
    * fine-grained events / batches of events
  * batch data at ingress into messages → operators
  * output directly consumed as messages / converted into fine-grained events for human

* System Challenges

  * Support for Latency Spectrum
    * adaptive physical batching to support latency spectrum from real-time to offline
    * types of messages: data-batch & punctuation
    * data-batch: variable-sized batch of events
    * punctuation: control message forcing Trill to produce output, terminating batches if necessary
  * Enabling Columnar with a HLL
    * columnar organization in operators
    * providing row-oriented user view of data in a HLL
    * dynamic HLL code generation
  * Fast Grouped Streaming Operators
    * `GroupApply`
    * efficient grouping, algorithms for temporal operators fully exploiting batched nature of input/output streams (temporal/progressive)
    * exploiting data characteristics to select from a small set of generated physical operators at compile-time
  * Library Mode & Multi-core Support
    * no-scheduler library mode (1 thread)
    * lightweight scheduler, temporal map-reduce operation (on multi-core)



## Support for Latency Spectrum

* **Data-batch**: batch of events in Trill

  * event: 1 payload + 2 timestamp

    * _sync time_: logical time for event
      * events in a batch occur strictly non-decreasing sync-time order

    * _other time_: indicate extent of the data window

  * offline → maximum batch size, progressive/real-time → based on latency

* **Punctuation**: control message with a timestamp $T$

  * denote the passage of application time until $T$
  * enforce flushing of data-batch messages through Trill
  * Trill injects punctuations based on user-specified latency, dynamically adapt batch size to latency requirements



## Enabling Columnar with a HLL

* data-batch contains arrays

  * _SyncTime_: array of all sync-time in the batch

  * _OtherTime_: array of other-time values in the batch

  * _BitVector_: "event absence" vector, array with 1 bit per event (whether data event is absent)

  * ```c#
    class DataBatch {
        long[] SyncTime;
        long[] OtherTime;
        Bitvector BV;
    }
    ```

  * payload format generated on-the-fly

  * ```c#
    class UserData_Gen : DataBatch {
        long[] col_ClickTime;
        long[] col_UserId;
        long[] col_AdId;
    }
    ```

* generating operators

  * `Where` (filtering)

    * ```c#
      // e => e.UserId % 100 < 5
      void On(UserData_Gen batch) {
          batch.BV.MakeWritable(); // bitvector copy on write
          for (int i=0;i<batch.Count; i++)
              if ((batch.BV[i]==0) &&
      	        !(batch.col_UserId[i] % 100 < 5))
              batch.BitVector[i] = 1;
          nextOperator.On(batch);
      }
      ```

    * if filter invokes black-box method?

      * transform the data to its row-oriented form using `ColumnToRow` operation

  * `Select` (projection)

    * ```c#
      // e => { e.AdId }
      void On(UserData_Gen batch) {
          var r = new AdId_Gen(); // generated result batch
          r.CloneControlFieldsFrom(batch);
          // constant time pointer swing of AdId column
          r.col_AdId = batch.col_AdId.AddReference();
          batch.Free();
          nextOperator.On(r);
      }
      ```

* exploiting columnar batches

  * serialization & deserialization
    * Trillium on columnar Trill stream
      * serializer/deserializer code-generated compile-time
      * generated data-batches handled by transferring arrays directly without fine-grained encoding/tests, fill factor to limit how much data tranferred
      * memory pools
  * string handling using `MultiString`
    * `MultiString`: individual string end-to-end in a large single string
    * +offsets, lengths
    * split/substring by offsets
    * [[I: use rope?]]
    * Regular expression on large string, small span than re-execute
    * Substring matching by KMP directly apply to `MultiString`
    * backoff by copying
  * columnar memory pooling
    * memory pools, reusable sets of ref-counted HLL data structures



## Grouping & Stateful Operators

* ![image-20191028161635618](D:\OneDrive\Pictures\Typora\image-20191028161635618.png)

* `GroupApply(key-selector, sub-query)`

  * stateless `Group` operator + compute & materialize a grouping key for each event
  * add 2 columns to each data batch
    * `Key`: array of grouping key values of all events in the batch
    * `Hash`: array of hash values (4-bytes) of the keys
  * sub-query executed on resulting "grouped-stream"
  * aggregate on <group-key, payload> data-batch pairs
  * `Ungroup` operator to remove grouping key & exit `GroupApply` context

* Temporal Operator Algorithms

  * stream as a temporal database (TDB), presented incrementally

  * event is associated with a data window / interval denoting period of validity → snapshots (sequence of data verions across time)

  * ![image-20191028155822307](D:\OneDrive\Pictures\Typora\image-20191028155822307.png)

  * events

    * arrive directly as an interval
    * get broken up into separate insert into (start-edge) / delete-from (end-edge) the TDB
    * When other-time > sync-time, other-time → 1 interval with a data window [sync-time, other-wise)
    * When other-time is $\infty$ → start-edge as insertion of an item at sync-time
    * When other-time < sync-time → end-edge that occurs at sync-time, deletes an earlier start-edge occurred at previous timestamp
      * drop end-edges by setting bitvector entry to 1

  * user-defined snapshot aggregation

    * ```c#
      Expression<Func<TState>> InitialState();
      Expression<Func<TState, long, TInput, TState>> Accumulate();
      // data expiration when windows end
      Expression<Func<TState,long, TInput, TState>> Deaccumulate();
      // subtracking one state from another
      Expression<Func<TState, TState, TState>> Difference();
      Expression<Func<TState, TResult>> ComputeResult();
      
      // for count
      InitialState: () => 0L
      Accumulate: (oldCount, timestamp, input) => oldCount + 1
      Deaccumulate: (oldCount, timestamp, input) => oldCount - 1
      Difference: (leftCount, rightCount) => leftCount - rightCount
      ComputeResult: count => count
      ```

    * custom incremental HLL logic into stream processing without scrificing performance

    * `AggregateByKey`: 

      * hash table stores, 
        * for every distinct key associated with non-empty aggregate state (`TState`) at the current sync-time
        * an entry with that key & the aggregate state

    * `HeldAggregates`

      * use a hash table `FastDictionary`, store (for current sync-time $T$) the aggregated state corresponding to keys for which events arrive with sync-time = $T$
        * handle fast iteration through all the entires
        * support a fast clear when time move forward

    * `Endpoint Compensation Queue` (ECQ)

      * for each future endpoint (interval event), partially aggregated state (`HeldAggregates`) for that endpoint
      * priority queue / FIFO

    * for each data-batch

      * iterate through the events in that batch
      * lookup events in `HeldAggregates`
        * not found, look in `AggregateByKey`
          * if contains, ref-copy state into `HeldAggregates`
      * update current state for that key
        * `Accumulate`: start-edge / interval
        * `Deaccumulate`: end-edge
        * intervals → ECQ

    * sync-time forward / punctuaton

      * `ComputeResult`
      * output start-edge for the non-empty aggregates in `HeldAggregates`
      * clear `HeldAggregates`
      * Empty entries removed from `AggregateByKey`
      * process endpoints in ECQ between now & new sync-time
      * `Difference` to update
      * output state for each endpoint
      * [[ Q: what is start-edge/end-edge/interval/endpoint? ]]

  * temporal join & other operators

    * temporal equi-joins, by temporal grouped cross-product (GCP) operators
      * 2 grouped input stream
      * per-group temporal cross-product across input streams
      * temporal symmetric hash join with stream grouping key serving equi-join keys
      * sync-time order, 2 hash-tables
        * left & right side
        * start-edge & intervals added to the hash tables if the other side has not reached its end-of-stream
        * end-edge (& interval endpoints stored in an ECQ) remove entries from the hash tables
        * start-edge only? avoiding ECQ together

* Compile-time Stream Properties

  * `IsIntervalFree(bool)`: no intervals, only start-/end-edges → elide ECQ
  * `IsConstantDuration(bool, long)`: all events in the stream having same fixed duration → endpoints as a FIFO queue instead of priority queue
    * duration = $\infty$ → start-edge-only stream
      * progressive queries / non-windowed aggregates
  * `IsColumnar`: columnar/row-oriented mode
    * some property of user type prevents it from being used in columnar processing
    * an expression in the query is too complex or opaque to allow its transformations



## Library Mode & Multi-core

* physical plan → query fragments
* Streaming Temporal Map-Reduce
  * ![image-20191028161957893](D:\OneDrive\Pictures\Typora\image-20191028161957893.png)
  * Spray: stream of batches, stateless spray to $n$ downstream endpoints
  * Map/Group/Shuffle: map sub-query, shuffle on key
  * Merge/Reduce/Ungroup: temporal merge, feed the result stream to the reduce sub-query, ungroup to unnest the grouping key, final merge results
  * Temporal Cascading Binary Merge: tree of streaming binary merges
    * sync-time values from left/right input batches
    * merge data in sync-time order
  * Two-Input Reduce
* Performance Optimizations
  * Exploiting Sort-Order & Packing
    * Is input snapshots are sorted?
    * Is sorted stream is packed according to
      * for a given batch B, data with a given sort key value K cannot spill to next batch B+1 unless all the data in batch B has the same sort key value K
      * temporal map-reduce can retain sort order under spray, avoid shuffle
  * Exploiting Skew in Input Streams
    * 2-input reduce is skewed, broadcast smaller to all map endpoints, spray the larger side round-robin



## Motivation

* Modern business accumulate large amounts of data and derive value from the data by enabling timely analytics. There are different types of queries including real-time streaming logs, temporal queries on historical logs and progressive relational queries on collected data. The existing solutions, like streaming processor engine (SPE, event-at-a-time), batched processor engine (Naiad, batch-at-a-time) and columnar databases (Vertica, offline) fail to satisfy the requirement of high throughput, temporal and incremental query model, high level language and fabrics integration and user controlled latency (latency spectrum).

## Summary

* In this paper, the authors present Trill, which is a new query processor for analytics. Trill is based on tempo-relational model enabling it for handling relational and streaming queries. Trill uses data-batches and punctunations to control the latency spectrum for high overall throughput. Trill takes advantages of Columnar data structures and high level language integration by dynamically generating code and operators in columnar form. Apart from single thread pure library mode, Trill can also act on multi-core systems using temporal map-reduce techinique. Trill's throughput is 2-4 orders magnitude higher than existing streaming engines for streaming data and comparable to columnar DBMSs for offline data.

## Strength

* Trill has very high throughput based on its usage of punctunations to control latency spectrum and columnar data processing with dynamic code generation.
* Trill can incorporate with existing language lightweightly, since it's almost a pure library, not a framework.

## Limitation & Solution

* Trill has no ability to scale out and distribute. It's described as a single machine library for computing streaming data and offline data.
  * Extend multi-core temporal Map-Reduce to multi-node Spark?
* Trill has to abandon some columnar processing for handling user-defined blackboxes, due to its integration with high level languages.
  * Abandon the full integration, but force columnar processing.

