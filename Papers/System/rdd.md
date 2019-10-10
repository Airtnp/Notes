# Resilient Distributed Datasets: A Fault-Tolerant Abstraction for In-Memory Cluster Computing 

**Matei Zaharia, Mosharaf Chowdhury, Tathagata Das, Ankur Dave, Justin Ma, Murphy McCauley, Michael J. Franklin, Scott Shenker, Ion Stoica**

---



[link](https://www.usenix.org/system/files/conference/nsdi12/nsdi12-final138.pdf)

[[R: Spark paper]]





## Introduction

* Resilient Distributed Dataset (RDD): distributed memory abstraction



## RDDs

* ![1570424105889](D:\OneDrive\Pictures\Typora\1570424105889.png)

* ```scala
  lines = spark.textFile("hdfs://...")
  errors = lines.filter(_.startsWith("ERROR"))
  errors.persist()
  
  // Count errors mentioning MySQL:
  errors.filter(_.contains("MySQL")).count()
  // Return the time fields of errors mentioning
  // HDFS as an array (assuming time is field
  // number 3 in a tab-separated format):
  errors.filter(_.contains("HDFS"))
  	.map(_.split(’\t’)(3))
  	.collect()
  ```

* RDDs can only be created through coarse-grained transformations, DSM allows r/w to each memory location

* RDDs are immutable → backup mechanism

* bulk operations scheduled based on locality

* Applications Not Suitable for RDDs 

  * make asynchronous fine-grained updates to shared state
  * storage system for a web application or an incremental web crawler
  * use traditional update logging/data checkpointing (DB, RAMCloud, Piccolo, Percolator)

* Extra `count` operation



## Spark Programming Interface

* ![1570425396049](D:\OneDrive\Pictures\Typora\1570425396049.png)

* Logistic Regression

  * ```scala
    val points = spark.textFile(...)
    				.map(parsePoint).persist()
    var w = // random initial vector
    for (i <- 1 to ITERATIONS) {
        val gradient = points.map{ p =>
    	    p.x * (1/(1+exp(-p.y*(w dot p.x)))-1)*p.y
    	}.reduce((a,b) => a+b)
    	w -= gradient
    }
    ```

* PageRank

  * ```scala
    // optimize communication by controlling partitioning of the RDDs
    var links = spark.textFile(...).map(...)
    			.partitionBy(myPartFunc).persist()
    var ranks = // RDD of (URL, rank) pairs
    for (i <- 1 to ITERATIONS) {
        // Build an RDD of (targetURL, float) pairs
        // with the contributions sent by each page
        val contribs = links.join(ranks).flatMap {
    	    (url, (links, rank)) =>
        		links.map(dest => (dest, rank/links.size))
    	}
        // Sum contributions by URL and get new ranks
        ranks = contribs.reduceByKey((x,y) => x+y)
    	    .mapValues(sum => a/N + (1-a)*sum)
    }
    ```

  * ![1570425569201](D:\OneDrive\Pictures\Typora\1570425569201.png)



## Representing RDDs

* A set of _partitions_: atomic pieces of the dataset
* A set of _dependencies_ on parent RDDs
  * ![1570425955849](D:\OneDrive\Pictures\Typora\1570425955849.png)
  * _narrow_ dependencies: each partition of the parent RDD is used by most one partition of the child RDD. (`map`)
    * allow pipelined execution
    * recovery more efficient (only the lost parent partitions recomputed in parallel)
  * _wide_ dependencies: multiple child partitions may depend on it (`join` unless hash-partitioned)
    * require data from all parent partitions
    * complete re-execution of parent
* A function for computing the dataset based on its parents
* Metadata about its partitioning scheme and data placement
* ![1570425808536](D:\OneDrive\Pictures\Typora\1570425808536.png)
* HDFS files
  * `partitions`: one partition for each block of the file
  * `preferredLocations`: node the block is on
  * `iterator`: read the block
* `map : RDD[T] → MappedRDD[T]`
  * `partitions`: same as input
  * `preferredLocations`: same as parent
  * `iterator`: `= f . p.iterator`
* `union : (RDD[T], RDD[T]) → RDD[T]`
  * each child partition is computed through narrow dependency on the corresponding parent
  * don't drop duplicates
* `sample`: random sampling
  * similar to mapping, but RDD stores a RNG seed
* `join : (RDD[(K, T)], RDD[(K, U)]) → RDD[(K, (U, T))]`
  * if both hash/range partitioned with the same partitioner → two narrow dependencies
  * if both not partitioned → two wide dependencies
  * otherwise → mix
  * the output RDD will have a partitioner (inherited / default hash partitioner)
* ![1570426355320](D:\OneDrive\Pictures\Typora\1570426355320.png)



## Implementation

* Job Scheduling
  * ![1570426395553](D:\OneDrive\Pictures\Typora\1570426395553.png)
  * Examines RDD's lineage → build DAG of stages
  * boundary of stages: shuffle operations (wide dependency) or computed partitioned (short-circuited of a parent RDD)
  * launches tasks to compute missing partitions from each stage
  * delay scheduling: data locality
    * in node memory ? send to node
    * preferred node ? send to preferred node
  * wide dependencies → materialize intermediate records on the nodes holding parent partitions to simplify fault recovery
* Interpret Integration
  * _Class shipping_: interpreter serves classes over HTTP
  * _Modified code generation_: reference the instance of each line object
  * ![1570426722537](D:\OneDrive\Pictures\Typora\1570426722537.png)
* Memory Management for persistent RDDs
  * in-memory storage as deserialized Java Objects
    * compute efficient
  * in-memory storage as serialized data
    * memory efficient
  * on-disk storage
  * LRU eviction policy at the level of RDDs
    * keep old RDDs in memory to prevent cycling partitions
    * persistence priority in future
  * sharing RDDs across instances of Spark through a unified memory manager ([[Q:back to DSM?]]) in future
* Checkpointing
  * `REPLICATE` flag or `persist()`
  * automatic checkpointing in future
  * immutable → no need for concerning consistency



## Discussion



### Expressing Existing Programming Models

* **MapReduce**: `flatMap` + `groupByKey` / `reduceByKey`
* **DryadLINQ**: directly map to RDD operators
* **SQL**: like DryadLINQ
* **Pregel**: specialized model for iterative graph application, each superstep vertex runs a user function that update state associated, change graph topology, send messages.
* **Iterative MapReduce**: iterative MapReduce model with data partitioned consistently across iterations, easy to be implemented using Spark.
* **Batched Stream Processing**: periodically update a result with new data, bulk op like Dryad, store application state in distributed FS.
* Why are RDDs able to express these diverse programming models? 
  * The restrictions on RDDs have little impact in many parallel applications 
  * Though RDDs can only be created through bulk transformations, many parallel programs naturally apply the same operation to many records, making them easy to express.
  * The immutability of RDDs is not an obstacle because one can create multiple RDDs to represent versions of the same dataset 



### Leveraging RDDs for Debugging

* logging the lineage of RDDs created during a job
  * reconstruct these RDDs later and query interactively
  * re-run any task from the job in a single-process debugger, by recomputing dependencies
  * zero overhead for recording & replaying



## Questions

* Won't they cache code & DAG for machine learning jobs?
* [RDD Limitations](https://data-flair.training/blogs/apache-spark-rdd-limitations/)







## Motivation

* Current computing frameworks handle iterative algorithms and interactive data mining tools inefficiently. The applications reuse intermediate results across multiple computations.

## Summary

* In this paper, the authors propose a new abstraction Resilient Distributed Datasets (RDDs) for efficient data reuse in a broad range of applications. RDDs are fault-tolerance and parallelized data structures with a rich set of operators.
* RDDs files are represented by a set of partitions, a set of dependencies, a function for computing the dataset and metadata about its partitioning scheme and data placement.
* The job scheduler computes the DAG of stages to execute and assigns tasks to machines based on data locality.

## Strength

* RDDs abstraction improve the data reuse for applications and have extremely high expressiveness covering current computing networks.
* The modified interpreter and Scala language improves the expressiveness of RDD code.
* RDDs is a persistent, coarse-grained replacement for DSM, which makes it fault-tolerant and low overhead.

## Limitation & Solution

* The expressiveness of RDDs might be hidden due to datatype abstraction, so we need another layer of compiling. (E.g. It's not easy to convert SQL to RDD operators). And some optimizing might be done in these conversions.
  * Add a front end converter. Like [Catalyst Optimizer](https://data-flair.training/blogs/spark-sql-optimization/)
  * Add datatypes. Like [DataFrame & Datasets](https://spark.apache.org/docs/2.2.0/sql-programming-guide.html)