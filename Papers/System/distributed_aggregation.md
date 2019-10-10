# Distributed Aggregation for Data-Parallel Computing: Interfaces and Implementations 
**Yuan Yu, Predeep Kumar Gunda, Michael Isard**

---

[link](https://www.sigops.org/s/conferences/sosp/2009/papers/yu-sosp09.pdf)

[Automating Distributed Partial Aggregation](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/main-8.pdf)

[Parallelizing User-Defined Aggregation using Symbolic Execution](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/143-raychev.pdf)





## Introduction

* Grouped aggregation is core primitive of many distributed programming models, most efficient available mechanism for computations like matrix multiplication & graph traversal.
* Language integration between user-defined functions & high-level query language → code legibility & simplicity
* **GroupBy-Aggregation**
* MapReduce/Hadoop: general, but no low-level interfaces (though having high abstraction level like Hive/Pig Latin)
* Parallel databases: provide user-defined GroupBy-Aggregation, but tightly with SQL
* Distributed Aggregation treated efficiently by DryadLINQ optimization phase.





## Distributed Aggregation

* Iterator-based programming model DA (MapReduce/Hadoop)
  * `Map`: extract keys, records (just identity function)
  * Partition on keys
  * `Reduce: (K, [R]) → [S]`: `GroupBy` + `Aggregate`
  * ![1570514546151](D:\OneDrive\Pictures\Typora\1570514546151.png)
* _partial aggregation_ optimization
  * initial Map phase & aggregation tree
  * Need a auxiliary function _Combiner_
  * `InitialReduce: (K, [R]) → (K, X)`: partial aggregation with intermediate type `X`
  * `Combine: (K, [X]) → (K, X)`:  fold partial aggregations into combined partial aggregation
  * `FinalReduce: (K, [X]) → [S]`
  * [[N: `X` should be `Functor, Foldable`. Lift from [R] → [S] to [X] → [X] ]]
  * ![1570514639078](D:\OneDrive\Pictures\Typora\1570514639078.png)
* Decomposable functions
  * $\overline{x}$ denotes a sequence of data items
  * $\overline{x}_1 \oplus \overline{x}_2$ denotes the concatenation
  * A function $H$ is decomposable if there exists $I$ and $C$ satisfying
    * $H$ is the composition of $I$ and $C$: $\forall \overline{x}_1, \overline{x}_2: H(\overline{x}_1 \oplus \overline{x}_2) = C(I(\overline{x}_1 \oplus \overline{x}_2)) = C(I(\overline{x}_1) \oplus I(\overline{x}_2))$
    * $I$ is communtative: $\forall \overline{x}_1, \overline{x}_2: I(\overline{x}_1 \oplus \overline{x}_2) = I(\overline{x}_2 \oplus \overline{x}_1)$
    * C is communtative: $\forall \overline{x}_1, \overline{x}_2: C(\overline{x}_1 \oplus \overline{x}_2) = C(\overline{x}_2 \oplus \overline{x}_1)$
  * A function $H$ is associative-decomposable if there exists $I$ and $C$ satisfying
    * conditions above
    * C is associative: $\forall \overline{x}_1, \overline{x}_2, \overline{x}_3: C(C(\overline{x}_1 \oplus \overline{x}_2) \oplus \overline{x}_3) = C(\overline{x}_1 \oplus C(\overline{x}_2 \oplus \overline{x}_3))$
* Aggregation computation can be represented as a set of associative-decomposble functions followed by some final processing → split like partial aggregation
* $I$: InitialReduce, $C$: Combine
* Binary function are represented as $F(x \oplus y)$ instead of $F(x, y)$



## Programming Model



### User-defined aggregation in Hadoop (iterator-based)

* 
  
  ```java
  // InitialReduce: input is a sequence of raw data tuples;
  // produces a single intermediate result as output
  static public class Initial extends EvalFunc<Tuple> {
      @Override public void exec(Tuple input, Tuple output)
          	throws IOException {
          try {
              output.appendField(new DataAtom(sum(input)));
              output.appendField(new DataAtom(count(input)));
          } catch(RuntimeException t) {
              throw new RuntimeException([...]);
          }
      }
  }
  // Combiner: input is a sequence of intermediate results;
  // produces a single (coalesced) intermediate result
  static public class Intermed extends EvalFunc<Tuple> {
  	@Override public void exec(Tuple input, Tuple output)
  			throws IOException {
  		combine(input.getBagField(0), output);
  	}
  }
  // FinalReduce: input is one or more intermediate results;
  // produces final output of aggregation function
  static public class Final extends EvalFunc<DataAtom> {
      @Override public void exec(Tuple input, DataAtom output)
  	    throws IOException {
          Tuple combined = new Tuple();
          if(input.getField(0) instanceof DataBag) {
          	combine(input.getBagField(0), combined);
          } else {
          	throw new RuntimeException([...]);
          }
          double sum = combined.getAtomField(0).numval();
          double count = combined.getAtomField(1).numval();
          double avg = 0;
          if (count > 0) {
  	        avg = sum / count;
          }
          output.setValue(avg);
      }
  }
  static protected void combine(DataBag values, Tuple output)
  	throws IOException {
      double sum = 0;
      double count = 0;
      for (Iterator it = values.iterator(); it.hasNext();) {
          Tuple t = (Tuple) it.next();
          sum += t.getAtomField(0).numval();
          count += t.getAtomField(1).numval();
      }
      output.appendField(new DataAtom(sum));
      output.appendField(new DataAtom(count));
  }
  static protected long count(Tuple input)
  	throws IOException {
      DataBag values = input.getBagField(0);
      return values.size();
  }
  static protected double sum(Tuple input)
  	throws IOException {
      DataBag values = input.getBagField(0);
      double sum = 0;
      for (Iterator it = values.iterator(); it.hasNext();) {
          Tuple t = (Tuple) it.next();
          sum += t.getAtomField(0).numval();
      }
      return sum;
}
  ```
  
* The users are responsible for understanding `DataAtom`, `Tuple` and using casts, accessors, marshalling, manually checking.



### User-defined aggregation in a database

* user-defined table functions

* ```sql
  SELECT Reduce()
      FROM (SELECT Map() FROM T) R
      GROUPBY R.key
  ;    
  
  STATIC FUNCTION ODCIAggregateInitialize
      ( actx IN OUT AvgInterval
      ) RETURN NUMBER IS
      BEGIN
          IF actx IS NULL THEN
              actx := AvgInterval (INTERVAL ’0 0:0:0.0’ DAY TO
  					            SECOND, 0);
          ELSE
              actx.runningSum := INTERVAL ’0 0:0:0.0’ DAY TO SECOND;
              actx.runningCount := 0;
          END IF;
          RETURN ODCIConst.Success;
      END;
  
  
  MEMBER FUNCTION ODCIAggregateIterate
      ( self IN OUT AvgInterval,
      val IN DSINTERVAL_UNCONSTRAINED
      ) RETURN NUMBER IS
      BEGIN
          self.runningSum := self.runningSum + val;
          self.runningCount := self.runningCount + 1;
          RETURN ODCIConst.Success;
      END;
  
  MEMBER FUNCTION ODCIAggregateMerge
      (self IN OUT AvgInterval,
      ctx2 IN AvgInterval
      ) RETURN NUMBER IS
      BEGIN
          self.runningSum := self.runningSum + ctx2.runningSum;
          self.runningCount := self.runningCount +
          ctx2.runningCount;
          RETURN ODCIConst.Success;
      END;
  
  MEMBER FUNCTION ODCIAggregateTerminate
      ( self IN AvgInterval,
      ReturnValue OUT DSINTERVAL_UNCONSTRAINED,
      flags IN NUMBER
      ) RETURN NUMBER IS
      BEGIN
          IF self.runningCount <> 0 THEN
          	returnValue := self.runningSum / self.runningCount;
          ELSE
       		returnValue := self.runningSum;
          END IF;
          RETURN ODCIConst.Success;
      END;
  ```

* `Initialize`: called once before any data is supplied with a given key, to initialize the state of the aggregation object

* `Iterate`: called multiple times, each time with a single record with the matching key, causing that record to be accumulated by the aggregation object

* `Merge`: called multiple time, each time with another aggregation object with the matching key, combining.

* `Final`: called once to output the final record

* Hard to manage, understand



### User-defined aggregation in DryadLINQ

* 
  
  ```c#
  var groups = source.GroupBy(KeySelect); // source: R, KeySelect: K → R, groups: IEnumerable<IGrouping<K, R>>
var reduced = groups.SelectMany(Reduce); // Reduce: IEnumerable<IGrouping<K, R>> → IEnumerable<S>, reduced: IEnumerable<S>
  ```
  
* statically strongly typed (no type-casting/marshalling)

* `Aggregate` operator

* Iterator-based aggregation

* 
  
  ```c#
  [AssociativeDecomposable("I", "C")] // indicate split computation into calls to I + C
  public static X H(IEnumerable<R> g) {
  	[ ... ]
  }
  
  public static IntPair InitialReduce(IEnumerable<int> g) {
  	return new IntPair(g.Sum(), g.Count());
  }
  public static IntPair Combine(IEnumerable<IntPair> g) {
      return new IntPair(g.Select(x => x.first).Sum(),
  				    g.Select(x => x.second).Sum());
  }
  
  [AssociativeDecomposable("InitialReduce", "Combine")]
  public static IntPair PartialSum(IEnumerable<int> g) {
  	return InitialReduce(g);
  }
  
  public static double Average(IEnumerable<int> g) {
      IntPair final = g.Aggregate(x => PartialSum(x)); // How LINQ knows to call `Combine`?? Reflection on expression tree
      if (final.second == 0) return 0.0;
      return (double)final.first / (double)final.second;
}
  ```
  
* Accumulator-based aggregation (perform better)

* ```c#
  public X Initialize();
  public X Iterate(X partialObject, R record);
  public X Merge(X partialObject, X objectToMerge);
  
  public static IntPair Initialize() {
  	return new IntPair(0, 0);
  }
  public static IntPair Iterate(IntPair x, int r) {
      x.first += r;
      x.second += 1;
      return x;
  }
  public static IntPair Merge(IntPair x, IntPair o) {
      x.first += o.first;
      x.second += o.second;
      return x;
  }
  [AssociativeDecomposable("Initialize", "Iterate", "Merge")]
  public static IntPair PartialSum(IEnumerable<int> g) {
  	return new IntPair(g.Sum(), g.Count());
  }
  public static double Average(IEnumerable<int> g) {
      IntPair final = g.Aggregate(x => PartialSum(x));
      if (final.second == 0) return 0.0;
      else return (double)final.first / (double)final.second;
  }
  ```



### Aggregating multiple functions

* Let `g` be the formal argument of a reducer. A reducer is decomposable if every terminal node of its expression tree satisfying one of the following conditions
  * It is a constant, or, if `g` is an `IGrouping` of the form `g.Key`, where `Key` is the property of the `IGrouping` interface that returns the group's key
  * It is of the form `H(g)` for a decomposable function `H`
  * It is a constructor or method call whose argument each recursively satisfying one of these  conditions.
* Using reflection to discover all decomposable function calls in the expression
* Automatic generation and use of `InitialReduce`, `Combine`, `FinalReduce`. [[Q: How to do this??]]



## System Implementation

* `G1 → IR → [MG → G2 → C] → MG → G2 → FR` (GroupBy1, InitialReduce, Merge, GroupBy2, Combiner)

* **FullSort**: iterator-interface (as MapReduce/Hadoop)
  * G1: accumulate all objects in memory and perform a parallel sort 
  * IR: `InitialReduce` for each unique key on stream → sorted result
  * MG: parallel merge sort on sorted result
    * must open all of its inputs at once and interleave reads
  * G2: simple stream operations since records arrive sorted in groups and ready for C
    * stateless, can be pipelined with a downstream computation with FR
  * Not suitable for large memory footprint
  * pipelined downstream computations
* **ParallelSort**: iterator-interface
  * read a bounded number of chunks of input records into memory, with each chunk occupying bounded storage
  * each chunk is processed independently in parallel; sorted; passed to IR; emitted
  * G1: sort chunks
  * IR: `InitialReduce` on chunks
  * MG: non-deterministic merge
    * can read sequentially from one input at a time
  * G2: **FullSort**
    * consume unbounded storage, but should expect a large degree of data reduction
    * can be pipelined with downstream computations (like external sort encap results)
  * pipelined upstream computations
* **Accumulator-FullHash**: accumulator-interface
  * build a parallel hash table containing one accumulator object for each key
  * `Initialize`: place new unique key in hashtable
  * `Iterate`: each record passed to `Iterate` of the accmulator object in the hashtable
  * MG: non-deterministic merge
  * G2: **Accumulator-FullHash**
  * storage is proportional to unique keys
  * only require Equal + Hash operation (sort need Comp)
* **Accumulator-PartialHash**: accumulator-interface
  * similar to **Accumulator-FullHash**
  * evict the accumulator object from the Hashtable then emits its partial aggregation whenever hash collision.
  * G2: **Accumulator-FullHash**, aggregate all the records for a particular key
  * storage is bounded by the size of the hash table
  * not enough reduction in stage 1
* **Iterator-FullHash**: iterator-interface
  * similar to **FullSort**, accumulate all records in memory before performing any aggregation
  * G1: accmulate the records into a hash table according to GroupBy keys
  * IR: emit each group in the hash table using `InitialReduce`
  * G2: **Iterator-FullHash**, since output is not partial sorted
* **Iterator-PartialHash**: interator-interface
  * similar to **Iterator-FullHash**
  * emit the group accmulated in the Hashtable wheneven hash collision
  * bounded storage in stage 1
  * G2: **Iterator-FullHash**
  * poor reduction in stage 1
* Aggregation tree
  * data locality (computer, rack, cluster)
  * highly dependent on dynamic scheduling decisions (Dryad callback)



## Questions

* How DryadLINQ/.NET knows to use annotated functions?
* How to automatically generate IR, C, FR?
  * [Automated Distributed Partial Aggregation](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/main-8.pdf)
  * decomposability verification: SMT solver
  * non-deterministic synthesis a Combiner
  * $C(s_1, s_2) = F(s_1, H(s_2))$ where $H = \forall s. F(s_0, H(s)) = s$
  * counting/state machine/single input
  * ![1570563378831](D:\OneDrive\Pictures\Typora\1570563378831.png)







## Motivation

- GroupBy-Aggregation is a fundamental subroutine in many data-mining computations. Systems like MapReduce and Hadoop provide general tasks but fail to offer low-level programming interfaces. Parallel databases permit user-defined selection and aggregation operations, but have restricted type systems and limited ability to interact with legacy code.

## Summary

- In this paper, the authors provide a abstraction for GroupBy-Aggregation called [associative-]decomposable functions. Associative-decomposable functions represent aggregation computations that can be split up into partial-aggregations. The authors place their decomposable abstractions on iterator interface or accumulator interface with annotations (or automatically generated using DryadLINQ. In each vertex of computation (GroupBy, Merge, or Reduce/Combine), the authors propose six implementations of two aggregation steps.

## Strength

- The simple interface of denoting associative-decomposable functions provides user-friendliness on parallel GroupBy-Aggregation operations.
- The concept of associative-decomposable functions points out the key abstraction in partial aggregation optimization and decompose the aggregation operators.

## Limitation & Solution

- The system highly relies on DryadLINQ for underlying graph execution and scheduling.
  - Use a flexibility backend for LINQ expressions
- The system can't deal with online streaming data
  - Optimize/decompose sliding-window aggregations instead.

