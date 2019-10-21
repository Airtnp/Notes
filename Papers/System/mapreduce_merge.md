# Map-Reduce-Merge: Simplified Relational Data Processing on Large Clusters 

**Hung-chih Yang, Ali Dasdan , Ruey-Lung Hsiao, D. Stott Parker**

------



## Introduction

* MapReduce does not directly support processing multiple related heterogeneous datasets.
* ![1570592044289](D:\OneDrive\Pictures\Typora\1570592044289.png)
* Simplified distributed storage & parallel programming infrastructure
  * GFS, MapReduce, BigTable, Nepture (Data Aggregation Call), Dryad
  * `map` function to process input k/v pair, generate intermediate k/v (`local` in DAC)
  * `reduce`: merge all intermediate pairs associated with the same key (`reduce` in DAC)
  * [[Q: why don't talk about Dryad??]]
  * best at homogeneous datasets
  * `join` multiple heterogeneous :x:
* Search Engine
  * crawler database of URLs
  * inverted indexes in index database
  * click/execution logs in log databases
  * URL linkages with URL properties in webgraph database
  * index needs crawler + webgraph
  * webgraph needs crawler + prev webgraph
  * MapReduce?: process database while accessing otherse on the fly / treat at homogeneous inputs with heterogeneous encoding (data-source attributes)
* Need a join-enabled MapReduce system to process data relationship
* Include relational algebra in MapReduce
* A Merge phase (naming & configuring scheme)
* Map-Reduce-Merge
* A paper full of philosophy from Eric Brewer & Jim Gray...



## Map-Reduce

* low-cost unreliable commodity hardware
  * no high performance SMP/MPP with high-end network & storage
* extremely scalable RAIN cluster
  * :x: centralized RAID-based SAN/NAS storage
  * loose coupling nodes & shared-nothing architecture
  * Redundant Array of Independent (and Inexpensive) Nodes
* fault-tolerant yet easy to administer
  * no backup/restore/recovery, but off-line, rerun, backup tasks
* simplified & restricted yet powerful
* highly parallel yet abstracted
  * automatic parallelization & execution
* high throughput
* high performance by the large
* shared-disk storage yet shared-nothing computation
* set-oriented keys & values
* functional programming primitives
* distributed partitioning/sorting framework
* designed for search engine operations yet applicable to generic data processing tasks
* **Homogenization**: _equi_join_ to multiple heterogeneous datasets



## Map-Reduce-Merge

* ![1570653884463](D:\OneDrive\Pictures\Typora\1570653884463.png)
* ![1570654349623](D:\OneDrive\Pictures\Typora\1570654349623.png)
* `map`, `reduce`: same, but with lineage
* `merge`: `self-merge` like `self-join`, list comprehension
* key transformation preserving partition in `map`-`reduce`



## Implementation

* ```c++
  1: PartitionSelector partitionSelector; // user-defined logic
  2: LeftProcessor leftProcessor; // user-defined logic
  3: RightProcessor rightProcessor; // user-defined logic
  4: Merger merger; // user-defined logic
  5: IteratorManager iteratorManager; // user-defined logic
  6: int mergerNumber; // assigned by system
  7: vector<int> leftReducerNumbers; // assigned by system
  8: vector<int> rightReducerNumbers; // assigned by system
  9: // select and filter left and right reducer outputs for this merger
  10: partitionSelector.select(mergerNumber,
  11: 						leftReducerNumbers,
  12: 						rightReducerNumbers);
  13: ConfigurableIterator left = /*initiated to point to entries
  14: 							in reduce outputs by leftReducerNumbers*/
  15: ConfigurableIterator right =/*initiated to point to entries
  16: 							in reduce outputs by rightReducerNumbers*/
  17: while(true) {
  18: 	pair<bool,bool> hasMoreTuples =
  19: 		make_pair(hasNext(left), hasNext(right));
  20: 	if (!hasMoreTuples.first && !hasMoreTuples.second) {break;}
  21: 	if (hasMoreTuples.first) {
  22: 		leftProcessor.process(left→key, left→value); }
  23: 	if (hasMoreTuples.second) {
  24: 		rightProcessor.process(right→key, right→value); }
  25: 	if (hasMoreTuples.first && hasMoreTuples.second) {
  26: 		merger.merge(left→key, left→value,
  27: 					right→key, right→value); }
  28: 	pair<bool,bool> iteratorNextMove =
  29: 		iteratorManager.move(left→key, right→key, hasMoreTuples);
  30: 	if (!iteratorNextMove.first && !iteratorNextMove.second) {
  31: 		break; }
  32: 	if (iteratorNextMove.first) { left++; }
  33: 	if (iteratorNext\Move.second) { right++; }
  34: }
  ```

* ![1570674460701](D:\OneDrive\Pictures\Typora\1570674460701.png)

* `merge` function
  
  * user-defined data processing logic
  
  * 2 pair of k/v from distinguishable sources
  
  * ```c++
    1: merge(const LeftKey& leftKey,
    2: 		/* (dept id, emp id) */
    3: 		const LeftValue& leftValue, /* sum of bonuses */
    4: 		const RightKey& rightKey, /* dept id */
    5: 		const RightValue& rightValue /* bonus-adjustment */){
    6: 	if (leftKey.dept id == rightKey) {
    7: 		bonus = leftValue * rightValue;
    8: 		Emit(leftKey.emp id, bonus); }
    9: }
    ```
* `processor` function
  * user-defined function that process data from each source
  * like build/probe phase in (grace) hash join
* _partition selector_
  * user-definable module dealing number determining from which reducer the merge  retrievees its data.
  
  * mapper num: input file split
  
  * reducer num: input bucket
  
  * merger num
  
  * utilize numbers to associate I/O between mergers and reducers
  
  * determines which data partitions produced by up-stream reducers should be retrieved then merged
  
  * given: merger number, 2 collections of reducer number
  
  * ```c++
    1: bool select(int mergerNumber,
    2: 				vector<int>& leftReducerNumbers,
    3: 				vector<int>& rigthReducerNumbers) {
    4: 	if (find(leftReducerNumbers.begin(),
    5: 			leftReducerNumbers.end(),
    6: 			mergerNumber) == leftReducerNumbers.end()) {
    7: 		return false; }
    8: if (find(rightReducerNumbers.begin(),
    9: 			rightReducerNumbers.end(),
    10: 		mergerNumber) == rightReducerNumbers.end()) {
    11: 	return false; }
    12: 	leftReducerNumbers.clear();
    13: 	leftReducerNumbers. push back(mergerNumber);
    14: 	rightReducerNumbers.clear();
    15: 	rightReducerNumbers. push back(mergerNumber);
    16: 	return true;
    17: }
    ```
* configurable iterator
  * logicical iterator like mapper/reducer
  
  * 2 logical iterators
  
  * user-defined _iterator-manager_
  
  * ```c++
    // sort-merge
    1: move(const LeftKey& leftKey,
    2: 		const RightKey& rightKey,
    3: 		const pair<bool, bool>& hasMoreTuples) {
    4: 	if (hasMoreTuples.first && hasMoreTuples.second) {
    5: 		if (leftKey < rightKey) {
    6: 			return make pair(true, false); }
    7: 		return make pair(false, true); }
    8: 	return hasMoreTuples;
    9: }
    
    // nested-loop
    1: move(const LeftKey& leftKey,
    2: 		const RightKey& rightKey,
    3: 		const pair<bool, bool>& hasMoreTuples) {
    4: 	if (!hasMoreTuples.first && !hasMoreTuples.second) {
    5: 		return make pair(false, false); }
    6: 	if (!hasMoreTuples.first && hasMoreTuples.second)
    7: 		/* throw a logical-error exception */
    8: 	if (hasMoreTuples.first && !hasMoreTuples.second) {
    9: 		/* reset the right iterator to the beginning */
    10: 	return make pair(true, false); }
    11: return make pair(false, true);
    12: }
    
    // hash
    1: move(const LeftKey& leftKey,
    2: 		const RightKey& rightKey,
    3: 		const pair<bool, bool>& hasMoreTuples) {
    4: 	if (!hasMoreTuples.first && !hasMoreTuples.second){
    5: 		return make pair(false, false); }
    6: 	if (hasMoreTuples.first) {
    7: 		return make pair(true, false); }
    8: 	return make pair(false, true);
    9: }
    ```
  
* ![1570659090452](D:\OneDrive\Pictures\Typora\1570659090452.png)



## Applications to Relational Data Processing

* relationally complete
* `(A, R) → (K, V)` relation `R`, attribute set (schema) `A`, schema of the key part `K`, value part `V`
* Projection: map-phase `t = (k, v) → (k', v')`
* Aggregation: reduce-phase `t = (k, [v])`
* Generalized Selection
  * 1 data source → mapper
  * on aggregation/group → reducer
  * 2 data source → merger
* Join
  * sort-merge join
    * map: range partitioner, ordered mutually exclusive key range buckets
    * reduce: reducer reads designated buckets from all the mappers. merge into sorted set
    * merge: read 2 sets of reducer output and sort-merge join (merge part)
  * hash join
    * map: hash partitioner
    * reduce: read every mapper for one designated partition. using same hash function, group & aggregate the partitions using hashtable.
    * merge: read 2 sets of reducer output sharing same hashing buckets. 1 for build and 1 for probe.
  * block nested-loop join
    * map: same as hash join
    * reduce: same as hash join
    * merge: nested-loop join instead of hash join
* Set Union
  * mapper: sort, grouped
  * reducer: discard duplicated tuples
  * merger: iterate union
* Set Intersection: same, with merger different
* Set Difference: same, with merger different
* Cartesian Product: merger nested loop (need N^2 mergers?)
* Rename: trivial



## Optimizations

* MapReduce: locality & backup tasks
* Optimal reduce-merge connections
  * $M_A$ # of mappers, $R_A$: # of reducers
  * total $R(M_A + M_B)$ remote reads
  * one-to-one $2R$ connections (nearly same dataset)
  * remote reads $R^2 + R$ (1 dataset much larger than other)
* Combining Phases
  * ReduceMap, MergeMap: reducer/merger outputs fed into down-stream mapper for a subsequent joins. Simply be sent directly to a co-located mapper
  * ReduceMerge: combined with 1 of the reducer of the partition
  * ReduceMergeMap: combine of above 2
  * disk → network
    * difficulty for upstream processes to recollect the data
    * connecting up/down-stream processes



## Enhancements

* Map-Reduce-Merge Library
* Map-Reduce-Merge Workflow
  * customized workflow vs Map-Reduce (unskippable partitioning/sorting)
  * ![1570738760443](D:\OneDrive\Pictures\Typora\1570738760443.png)
  * 



















## Motivation

* Map-Reduce doesn't support heterogeneous datasets processing directly and the workflow of Map-Reduce is fixed with inevitable partition and sorting. The limitations make Map-Reduce not relational-complete (do all relational operations like databases).

## Summary

* In this paper, the authors presents Map-Reduce-Merge model. The model adds a new Merge phase after Map-Reduce. The merger collects reduce results from heterogeneous datasets and processes them with customized `merge`, `processor`, partition selector, iterator manager functions. This merger phase, with some optimizations, can provide all relational primitives.

## Strength

* Map-Reduce-Merge is strong to process heterogeneous datasets and its custom points are more than Map-Reduce such as the functions in the merger and workflow optimizations.

## Limitation & Solution

* The paper lacks benchmarking results.
  * Add test results in TPC-H comparing Map-Reduce with data source attribute and Map-Reduce-Merge
* The reducer logic is complicated with user-defined partition select and `process` functions.
  * Have a better abstraction rather than directly exposing mapper, reducer details to users.

