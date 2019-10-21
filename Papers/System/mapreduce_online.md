# MapReduce Online

**Tyson Condie, Neil Conway, Peter Alvaro, Joseph M. Hellerstein **

------

## Introduction

* MapReduce materialized outputs to disk
* should pipelined between operators
* online aggregation: allows users to see "early returns" from a job as it is being computed
* continuous query: MapReduce written for applications such as event monitoring & stream processing

* data-centric fashion: applying transformations to sets of data records, allow the details of distributed execution, network communication, coordination, fault tolerance handled by MapReduce framework
* pipelining
  * downstream dataflow elements can begin consuming data before a producer element finishing execution.
  * _online aggregation_: reducer immediate processing → generate & refine an approximation of their answer during the course of execution.
  * _continuous query_: accepting new data and online analyzing
  * challenges: fault-tolerance (in MapReduce, provided by materialization, in Spark, lineage + checkpoint) . greedy communication implicit (compression/pre-aggregation → reduce network issues)



## Programming Model

* `Combiner`: summarize input values (preaggregation)

* Hadoop: Job Tracker → jobs → workers (TaskTracker, fixed # of slots for executing tasks) → heartbeats → Job Tracker

* ```java
  // accumulate the output records produced by map function
  public interface Mapper<K1, V1, K2, V2> {
      void map(K1 key, V1 value,
  		    OutputCollector<K2, V2> output);
      void close();
  }
  
  public interface Reducer<K2, V2, K3, V3> {
  	void reduce(K2 key, Iterator<V2> values,
  				OutputCollector<K3, V3> output);
  	void close();
  }
  ```

* Map Task Execution

  * `map` phase: read splits from HDFS, parse, apply map
  * `close`: commit phase, register final output with TaskTracker
  * `OutputCollector<K, V>`: accumulate the output records in a format that easy for reducer to consume. responsible for spilling this buffer to disk when it reaches capacity.
    * spill: sorting by (partition number, key)
    * index file (offset to each partition/key), data file
  * `commit` phase: generate final output, in-memory buffer flushed, spill files merged

* Reduce Task Execution

  * `shuffle` phase: fetch input (key range partition)
    * issue HTTP request to a configurable number of TaskTrackers
    * JobTracker relays the locations of TaskTracker
  * `sort` phase: group records with same key
    * map output is sorted, so merge runs and produce a single run
  * `reduce` phase: user-defined reduce function



## Pipelined MapReduce

* ![1570741959129](D:\OneDrive\Pictures\Typora\1570741959129.png)

* Within a job: mappers push data to reducers

  * naïve pipelining: directly connect mapper to reducers, the mapper determines which partition (reduce task) the record should be sent to, via appropriate socket
  * problems
    * not enough slots available to schedule every task in a new job
    * open sockets between each map/reduce task requiring large # of TCP connections
    * pipeline stall should not prevent mapper tasks in progress
  * refinement
    * if a reduce task has not yet been scheduled, any map tasks that produce records for that partition write them to disk (the rest in normal Hadoop fashion)
    * reducer can be configured to pipeline data from a bounded # of mappers (the rest in normal Hadoop fashion)
    * do not reuse mapper threads, using separate threads storing its outputs in an in-memory buffer, another thread periodically send the contents to the buffer to the pipelining reducers.
  * granularity of map outputs
    * memory buffer reaching threshold → combiner function → spill file → reducer
    * reducer  can't follow mapper → mapper periodically apply combiner to spill files to merge multiple spill files (adaptively moving load)

* Between Jobs (iterative jobs)

  * reducer can't overlap with next mapper

* [^Fault Tolerance]: Fault Tolerance

  * mapper fail: reducers only merge spill files from the same uncommitted mapper, but not merge spill files with other map tasks until the uncommitted mapper committed. Ignore any tentative spill file produced by the failed map attempt.
    * or checkpoint: map tasks periodically notify JobTracker that it has reached offset `x` in its input split. The JobTracker notifies any reducers: map task output that before offset `x` can then be merged. Avoid duplicate results → map task fail, restart at offset `x`
  * reducer fail: restart task. map tasks retain outputs and write a complete output file to disk before committing.



## Online Aggregation

* Single job online aggregation
  * snapshot: output of an intermediate reduce operation (result of data received so far)
    * job progress: user correlates progress to a formal notion of accuracy
    * computed periodically
    * atomically rename snapshot to appropriate snapshot directory
  * applications can consume snapshots by polling HDFS in a prediction location
  * not enough free slots for all reduce tasks? not available snapshot for not executing reducers
    * avoid by configuration
    * or wait to execute an online aggregation job until there are enough reduce slots
  * _progress score_: map task progress, collected and mean by reducer
* Multi-Job Online Aggregation
  * ![1570745442786](D:\OneDrive\Pictures\Typora\1570745442786.png)
  * inter-job online aggregation
    * not monotonic reduce function, must recompute new snapshots from scratch (may not related to data amount)
    * optimized for reduce functions that are declared to be distributive or algebraic aggregation
    * fault tolerance
      * first fail: first recovers like [^Fault Tolerance]. To handle failure in first, tasks in second cache the most recent snapshot received by first and replace it when they receive a new snapshot with a higher progress
      * second fail: restart, since first is monotonic, next snapshot received by second will have a higher progress score.
      * both fail: second recovers the most recent snapshot from first and then wait for snapshots with a higher progress.



## Continuous Query

* Just pipelining, must periodically extract map outputs by reducer functions
* fault tolerance
  * map side spill maintained in a ring buffer with unique IDs
  * reducer notifies JobTracker about the run of map outputs records it no longer need (only suffix is needed)
  * having reducer checkpoint internal state to HDFS
* prototype monitoring system
  * agents for statistics (`/proc`)
  * forward statistics to an aggregator



## Conclusion & Future Work

* scheduling for pipeline parallelism, for deep pipelines with direct communication between reduces and maps (co-locating)
* full-featured interface for script performance monitoring tasks that gather system-wide information in near-real-time
* interactive applications
* 













## Motivation

* MapReduce is a popular framework for data-intensive distributed computing of batch jobs. For fault tolerance issues, the output of MapReduce tasks are materialized to distributed file system, which can be avoided by pipelined executions.

## Summary

* In this paper, the authors present Pipelined MapReduce which can chaining the map and reduce tasks and tasks between multiple MapReduce jobs to avoid materialization cost. The pipeling is done by redesign mappers and reducers to push data to next steps instead of materialize outputs and let next steps pull the data from the distributed system.
* To reach fault tolerance, the JobTracker and TaskTrackers will monitor the data progress and mapper number so no more than one uncommitted mapper data is read by reducer and mappers retain the data for reducer in memory until the outputs get spilled.
* The Pipelined MapReduce model makes online aggregation and continuous queries possible by using the pipelined execution and progress recording.

## Strength

* The pipelining between tasks reduce the cost of writing and reloading outputs, so it helps iterative jobs and interactive jobs to reuse data (like Spark motivation).
* The pipelining between tasks allow online operations like aggregation and queries.

## Limitation & Solution

* The fault tolerance of this model is complex. Even with two MapReduce jobs connected, there are three different fault scenarios to consider because of the snapshot design.
  * Use RDD-like lineage design along with checkpoint/snapshot?
* The scheduling is a key point to there. The paper doesn't implement its own scheduler which is bad.
* Good approximation metric is undefined



## Scriber

* good presentation, nice analysis of the evaluation
* should make stronger accents, not monotonic speaking...
* missing critical parts in paper
* very naive

