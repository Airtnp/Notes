# FlumeJava: Easy, Efficient Data-Parallel Pipelines

**Craig Chambers, Ashish Raniwala, Frances Perry, et al.**

------



## Introduction

* Managing MapReduce pipeline is difficult
* FlumeJava library: easy to develop/test/run efficient data parallel pipelines
  * immutable parallel collections
  * a modest # of operations for processing them in parallel
* A single, high-level, uniform abstraction over different data representations and execution strategies
* defer evaluation, internally constructing an execution plan dataflow graph
* MapReduce: map+shuffle+reduce
* real-world: pipeline of MapReduce → additional creation, deletion, low-level coordination details
* FlumeJava: parallel collections
  * abstract away details of data representation / operator implementation
  * deferred evaluation
  * creation/clean-up management





## FlumeJava Library

* `PCollection<T>`: immutable bag of elements of type `T`

  * well-defined order : _sequence_
  * unordered: _collection_

* `PTable<K, V>`: immutable multi-map with keys of type `K` and values of type `V`

  * subclass of `PCollection<Pair<K, V>>`

* data-parallel operations

  * `parallelDo(DoFn<T, S>, Dtype)`: elementwise computation like `fmap` on Functor `PCollection`

  * ```java
    PCollection<String> words =
        lin	es.parallelDo(new DoFn<String,String>() {
        	void process(String line, EmitFn<String> emitFn) {
        		for (String word : splitIntoWords(line)) {
        			emitFn.emit(word);
        		}
        	}
    	}, collectionOf(strings()));
    ```

    * `Dtype`: `collectionOf(T)`, `sequenceOf(elemEncoding)`, `tableOf(keyEncoding, valueEncoding)`
    * `emitFn`: callback function for mapper

  * `groupByKey()`: converts a multi-map of type `PTable<K, V>` into a uni-map of type `PTable<K, Collection<V>>`

    * ```java
      PTable<URL,DocInfo> backlinks =
          docInfos.parallelDo(new DoFn<DocInfo,
          					Pair<URL,DocInfo>>() {
              void process(DocInfo docInfo,
                              EmitFn<Pair<URL,DocInfo>> emitFn) {
              	for (URL targetUrl : docInfo.getLinks()) {
              	emitFn.emit(Pair.of(targetUrl, docInfo));
              	}
              }
          }, tableOf(recordsOf(URL.class),
      			 recordsOf(DocInfo.class)));
      PTable<URL,Collection<DocInfo>> referringDocInfos = backlinks.groupByKey();
      ```

  * `combineValues()`: converts a `PTable<K, Collection<V>>` and an associative combing function on `V`s, returns a `PTable<K, V>`

  * `flatten()`: list of `PCollection<T>`s and returns a single `PCollection<T>`

    * no copy, but a view of logical `PCollection<T>`

* derived operation

  * `count`: `groupByKey()` + `combineValues()`
  * `join`: 
    * apply `parallelDo()` to each input to convert into a common format of type `PTable<K, TaggedUnion2<V1, V2>>`
    * combine two tables using `flatten`
    * apply `groupByKey()` to the flatten table to produce a `PTable<K, Collection<TaggedUnion2<V1, V2>>>`
    * apply `parallelDo()` to the key-grouped table, converting each `Collection<TaggedUnion2<V1, V2>>` into a `Tuple2` of a `Collection<V1>` and a `Collection<V2>`
  * `top(comp, N)`: `parallelDo()` + `groupByKey()` + `combineValues()`

* deferred evaluation

  * `PCollection`: _deferred_ (pointer to the deferred operation) / _materialized_
  * trigger evaluation: `run()`

* `PObject<T>`: container for a single Java object of type `T`

  * deferred or materialized

  * `getValue()`

  * act much like a future

  * ```java
    PTable<String,Integer> wordCounts = ...;
    PObject<Collection<Pair<String,Integer>>> result =
    	wordCounts.asSequentialCollection();
    ...
    FlumeJava.run();
    for (Pair<String,Integer> count : result.getValue()) {
    	System.out.print(count.first + ": " + count.second);
    }
    
    PCollection<Data> results =
    	computeInitialApproximation();
    for (;;) {
        results = computeNextApproximation(results);
        PCollection<Boolean> haveConverged =
    	    results.parallelDo(checkIfConvergedFn(),
        					 collectionOf(booleans()));
        PObject<Boolean> allHaveConverged =
    	    haveConverged.combine(AND_BOOLS);
        FlumeJava.run();
        if (allHaveConverged.getValue()) break;
    }
    ```

  * `operate()`: `[Pobject<S>] → OperateFn → [PObject<T>]`

    * extract the contents of its now-materialized argument `PObjects` and pass to `OperateFn`
    * return a list of Java objects
    * wrap inside `PObject`



## Optimizer

* `parallelDo/combineValues` fusion
  * producer-consumer fusion
  * ![1571195373143](D:\OneDrive\Pictures\Typora\1571195373143.png)
  * function composition, loop fusion
  * sibling fusion: apply when 2 or more `parallelDo` operations reading same `PCollection`
    * fused into a single multi-output `parallelDo` operation in one pass
* MapShuffleCombineReduce (MSCR) Operation
  * ![1571195781629](D:\OneDrive\Pictures\Typora\1571195781629.png)
  * `parallelDo` + `groupByKey` + `combineValues` + `flatten`
  * `M` input channels (each performing a map operation)
    * `PCollection<Tm> → [PTable<Kr, Vr>]` (by `parallelDo`)
    * choose to emit 1 or a few of its possible output channels
  * `R` output channels (optionally performing a shuffle, an optional combine, and a reduce)
    * flatten `M` inputs (by `flatten`)
    * either
      * `groupByKey` shuffle + optional `combineValues` combine + `Or` output `parallelDo` reduce (default identity) + `Or` output `PCollection`
        * grouping channel
      * write its input directly as its output
        * pass-through channel
  * generalize MapReduce 
    * by multiple reducers/combiners
    * multiple outputs from reducers
    * removing requirements that reducer must provide outputs with the same key as input
    * allowing pass-through outputs
* MSCR fusion
  * MSCR from a set of related `groupByKey` operations
    * related: consuming (possibly via `flatten`) same input or input created by the same (fused) `parallelDo`
  * input/output channels derived from related `groupByKey` operations & adjacent operations
    * `parallelDo` operation with 1+ output consumed by 1 of the `groupByKey` (flatten?) → fused → new input channel
    * `groupByKey` result consumed solely by a `combineValues` → fused into output channel
    * `groupByKey` / fused `combineValues` consumed solely by `parallelDo` → fused into output channel (if it cannot be fused into a different MSCR's input channel)
  * output of a mapper that flows to an operation or output other than related `groupByKey`s generates its own pass-through channels
  * ![1571197489962](D:\OneDrive\Pictures\Typora\1571197489962.png)
* optimizer strategy
  * sink `flatten`: $h(f(a) + g(b)) \to h(f(a)) + h(g(b))$
  * lift `combineValues`: GBK followed by CV → GBK records that and CV treated as `parallelDo`
  * insert fusion blocks: 2 GBK connected by a producer-consumer chain of 1+ `parallelDo`, then choose which `parallelDo` fuse up into the output channel of the earlier GBK, which `parallelDo` fuse down into the input channel of the later GBK. Estimate the size of intermediate `PCollections` to identify minimal expected size as boundary blocking `parallelDo` fusion
  * fuse `parallelDo`
  * fuse MSCRs
  * ![1571198161289](D:\OneDrive\Pictures\Typora\1571198161289.png)
* limitations
  * don't analysis user-written functions
  * optimization decisions on structure of the execution plan + optional hints (size of output)
    * static analysis
  * don't modify user code
  * generating new code to represent the appropriate composition of the user's functions
  * additional common-subexpression elimination to avoid duplicates
  * identify & remove unnecessary `groupByKey` operations



## Executor

* batch execution: traverse operations in the plan in forward topological order, executes each one
* locally + sequentially vs. remote + parallel MR
  * user assistance choice (expected ratio of output data size to input data size)
  * dynamic monitoring not done yet
* temporary files to hold outputs (automatically deletion) [[Q: fault tolerance??]]
* cached execution mode: instead of recompute, attempt to reuse the result of that operation from the previous run (if internal / user-visible file + if unchanged result)
  * unchanged: operation input/code + captured state not changed
  * automatic, conservative analysis to identify when reusing is guaranteed to be safe
  * quick edit-compile-run-debug cycles
* batched evaluation







## Motivation

* It's hard to use raw MapReduce for a chain of MapReduce stages since the data-parallel pipelines require coordination code and management of intermediate results creation and deletion. Also simple chaining hides the opportunity of optimizations (like fusion, pipelining) and reusing intermediate results.

## Summary

* In this paper, the authors present FlumeJava, which is a Java library representing parallel collections and parallel operations. FlumeJava provides `PCollection<T>` abstraction for immutable bag of elements and `parallelDo/groupByKey/combineValues/flatten` abstractions for parallel operations (map/reduce, groupBy, combine, flatten).
* FlumeJava's parallel operations are executed lazily using deferred evaluation. The `PCollection<T>` objects are materialized in need and an execution plan (DAG) is generated before execution with optimizations like pushing down `flatten` and fusion operations into MSCRs.

## Strength

* The abstraction of `PCollection<T>` and `parallelDo/groupByKey/combineValues/flatten` are powerful and enable optimizations especially fusions.
* The `PObject<T>`, library form of FlumeJava and deferred evaluation helps FlumeJava's integration with native Java code.

## Limitation & Solution

* The paper doesn't mention fault tolerance of FlumeJava. A lots of fusions and MSCR operations could make recomputation expensive.
  * Add runtime monitoring for backup tasks and frequently failed large operations and do fission on them.
* The granularity of optimization is coarse since it doesn't analysis the dataflow inside the user-defined functions, while SQL-like declarative / procedural style systems can do.
  * Since FlumeJava is a Java library, it could do analysis on bytecode of closures. 

