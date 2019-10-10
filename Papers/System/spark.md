# Spark: Cluster Computing with Working Sets

[link](https://www.usenix.org/legacy/event/hotcloud10/tech/full_papers/Zaharia.pdf)



## Introduction

* MapReduce is built around an acyclic data flow model
* Cyclic data intensive: Reuse a working set of data across multiple parallel operations.
  * iterative jobs: machine learning algorithms
  * interactive data analysis tools
  * reuse in acyclic tools → reload 
* Resilient Distributed Datasets (RDDs)
  * read-only collection of objects partitioned across a set of machines that can be rebuilt if a partition is lost.
  * explicitly cache an RDD in memory across machines and reuse it in multiple MapReduce-like parallel operations
  * fault tolerance: lineage if a partition of RDD is lost, the RDD has enough information about how it was derived from other RDDs to be about to rebuild just that partition.
* Scala: statically typed high-level P{L for JVM, exposing functional interface like DryadLINQ



## Programming Model



### Resilient Distributed Datasets (RDDs)

* read-only collection of objects partitioned across a set of machines that can be rebuilt if a partition is lost.
* handle to an RDD contains enough information to compute the RDD starting from data in reliable storage. (can always be reconstructed if nodes fail)
* 4 ways to construct RDD
  * From a _file_ in a shared filesystem (HDFS)
  * By _parallelizing_ s Scala collections in the driver program
    * divide it into a number of slices that will be sent to multiple nodes
  * By _transforming_ an existing RDD.
    * `flatMap : A ⇒ List[B]` = `fmap . pure`
    * `map : A ⇒ B`
  * By changing the _persistence_ of an existing RDD.
    * By default, RDDs are lazy & ephemeral (materialization on demand)
    * `cache` operation: leave dataset lazy, hint it should be kept in memory after 1st it computed, will be reused (only a hint, not forced. might recompute RDD if no enough memory)
    * `save` operation: evaluate the dataset and write it to a distributed filesystem (HDFS)



### Parallel Operations (Actions)

* `reduce`: Combine dataset elements using an associative function to produce a result at the driver program
  * one collected at one process (the driver)
  * currently not a grouped reduce like MapReduce
* `collect`: Send all elements of the dataset to the driver program. (Consumer, like Rust `IntoIterator::collect`)
* `foreach`: Pass each element through a user provided function. (Done for side effects of the function)
* `shuffle`: grouped reductions on distributed datasets



## Shared Variables

* parallel operations with closure copy variables to worker (message passing)
* _Broadcast variable_: If a large read-only piece of data (E.g. a LUT) is used in multiple parallel operations, it is preferable to distribute it to the worker only once instead of packaging it with every closure. Broadcast variable object wraps the value and ensures that it is only copied to each worker once. (`__constant__`, constant remains the entire computation)
* _Accumulator_: variables that workers can only "add" to using an associative operation, only the driver can read. Used for counter & imperative syntax for parallel sums. Defined for any type having an "add" and a "zero" (Monoid). Add-only semantics make it fault tolerant.
  * [[C: pipe? MPSC queue?]]



## Examples

* [[R: Spark on Rust?]]
  * [[C: DataFusion]]
  * [[C: Apache Arrow (columnar in-memory data)]]
  * [The Origin of Apache Arrow](https://www.dremio.com/origin-history-of-apache-arrow/)



### Text Search

* ```scala
  val file = spark.textFile("hdfs://...")
  val errs = file.filter(_.contains("ERROR"))
  val cachedErrs = errs.cache() // really unique, persist intermediate results
  val ones = cachedErrs.map(_ => 1)
  val count = ones.reduce(_+_)
  ```



### Logistic Regression

* ```scala
  // Read points from a text file and cache them
  val points = spark.textFile(...)
  				.map(parsePoint).cache()
  // Initialize w to random D-dimensional vector
  var w = Vector.random(D)
  
  // Run multiple iterations to update w
  for (i <- 1 to ITERATIONS) {
  	val grad = spark.accumulator(new Vector(D))
  	for (p <- points) { // Runs in parallel, syntax sugar for `points.foreach(p => {body})`
  		val s = (1/(1+exp(-p.y*(w dot p.x)))-1)*p.y
  		grad += s * p.x
  	}
  	w -= grad.value
  }
  ```



### Alternating Least Squares

* ```scala
  // approximate R by MU
  // Check EECS445 Machine Learning
  val Rb = spark.broadcast(R)
  for (i <- 1 to ITERATIONS) {
  	U = spark.parallelize(0 until u)
      		.map(j => updateUser(j, Rb, M))
  			.collect()
      M = spark.parallelize(0 until m)
  		    .map(j => updateUser(j, Rb, U))
      .		collect()
  }
  ```



## Implementation

* Built on top of Mesos (cluster operating system that lets multiple parallel applications share a cluster in a fine-grained manner with API)
* ![1570404932316](D:\OneDrive\Pictures\Typora\1570404932316.png)
* RDD interfaces
  * `getPartitions`: returns a list of partition IDs
  * `getIterator(partition)`: iterates over a partition
  * `getPreferredLocations(partition)`: task scheduling to achieve data locality
* RDD Types: how to implement the RDD interface
  * `HdfsTextFile` 
    * partitions → block ID
    * preferred locations → block locations
    * `getIterator` → opens a stream to read a block
  * `MappedDataset`
    * partition → parent
    * preferred locations → parent
    * iterator → mapped parent element
  * `CachedDataset`
    * preferred locations → start out equal to parent's preferred location, then updated after it is cached on some node
    * iterator → looking for a locally cached copy of a transformed partition
* _task_: wrapper for processing each partition of the dataset and send to worker nodes
* shipping tasks to workers
  * shipping closures
    * closures for defining RDDs
    * closure for operations
  * Java objects → serialization
  * might reference closure's outer scope not used → bugs
  * static analysis of closure classes' bytecode.
* **Shared Variables**: implemented by custom serialization formats
  * broadcast variables: saved to a file in a shared filesystem, then serial it by path
    * potential more efficient streaming broadcast system
  * accumulator: each accumulator is given a unique ID, then serial it by ID and "zero" value.
    * worker uses TLS copy from "zero" and sends message to driver containing updates
      * [[Q: the final result or updates?]]
* **Interpreter Integration**: Scala interpreter (1 class with 1 singleton object per line) with two changes
  * interpreter output the classes it defines to a shared filesystem, from which they can be loaded by workers using customized Java class loader.
  * enable to reference to singleton objects from previous lines



## Related Works

* RDDs differences from DSM (Distributed Shared Memory)
  * more restricted programming model, but let datasets be rebuilt efficiently under failure (DSM achieve fault tolerance by checkpointing)
    * Spark reconstructs by lineage information captured in RDD objects. (No need for whole stage recompute and can be done parallelly)
  * RDDs push computation to the data as in MapReduce, rather than arbitrary nodes accessing a global address space.



## Future Work

* Formally characterize the properties of RDDs and Spark's other abstractions.
* Enhance the RDD abstraction to allow programmers to trade between storage cost and re-construction cost.
* Define new operations to transform RDDs, including a `shuffle` operation that repartitions an RDD by a given key. (May used for implementing `groupBy`, `join`)
* Provide higher-level interactive interfaces on top of the Spark interpreter, such as SQL & R shells.





## Questions

* Why can't I just use chained MapReduce tasks in Interactive analytics?
* What steps does Spark really improve? Reload? Error recovery?





## Motivation

* Traditional MapReduce-like solutions for implementing large scale data-intensive applications have problem that it must have a acyclic data flow model. Some applications, including iterative jobs (machine learning) and interactive analytics (OLAP) require reusing a working set of data across multiple parallel operations, where MapReduce is deficient and will cause reloading inputs/outputs.

## Summary

* Spark supports applications with working sets who providing similar scalability and fault tolerance properties to MapReduce. Spark provides two main abstractions for parallel programming: Resilient Distributed Datasets (RDD) and Parallel Operation.
* RDDs are read-only collections of objects partitioned across a set of machines that can be rebuilt if a partition is lost using lineage information. Each RDD provides a unified interface with three API specifying the partition ID, iterator and affinity. Parallel Operations specify the program behavior in functional programming way. Shared variables optimizes the computation by providing extra constraints on datasets.

## Strength

* The use of modern Scala programming language improves the expressiveness of Spark model. Especially it provides sufficient features including JVM, strong type system, functional programming and function chaining.
* RDDs with lineage allow parallel and minimum recomputation under node failure. RDD provides a powerful abstraction for distributed shared memory which facilitates error recovery and reusing of inputs/outputs.

## Limitation & Solution

* Spark highly relies on Mesos to schedule the tasks and allocate resources.
* The control of RDDs is coarse-grained. Programmers have little freedom on specifying the reduction and data collection methods. Also programmers can't decide whether do recomputation or loading from storage (Like NVMe devices, *LC SSD).
  * Allow more advanced, find-grained control planes of computations. One for controlling the communication graph and one for computation preferences.