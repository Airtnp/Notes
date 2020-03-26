# Optimization of Object-Oriented Programs Using Static Class Hierarchy Analysis

**Jeffrey Dean, David Grove, Craig Chambers  **

---



## Introduction

* static class analysis to deduce precise information about the possible classes of receivers of messages

  * dynamically-dispatched messages $\to$ direct procedure calls $\to$ inline-expansion

* examining the complete inheritance graph / class hierarchy analysis

* [[Q: how does it different from OOPLSA'94-Palsberg? lattice+constraints+untyped vs. class hierarchy analysis?]]

* OOP: reusable, extensible class libraries/frameworks

  * base class: a set of messages defined/overrideen in subclasses
  * client specialize by providing application-specific subclasses
  * inheritance, dynamic binding

* performance overhead

* reduce the cost of dynamically-dispatched messages

  * static class analysis: identify a superset of the set of possible classes of objects stored in the variables and returned from expressions
    * monotype class $\to$ direct procedure call (statically-bound)
    * type-case expression, based on dynamic runtime class tests
      * 1/2 runtime tests is faster than runtime method lookup
  * profile-guided receiver class prediction: hard-wired / on-line / offline + recompilation
  * method specialization: faster specialized version of a method for particular inheriting subclasses

* class hierarchy analysis: knows subclass of the base class, supply the compiler with complete knowledge of the program's inheritance graph & set of methods defined

  * infer statically a specific set of possible classes
  * [[Q: runtime errors? If programmer makes a bug about the classes?]]

* > We describe several implementation techniques for efficiently incorporating class hierarchy analysis into a compiler, in particular into an existing static class analysis framework. Our techniques scale to support **multi-method-based languages**; efficient compile-time method lookup in the presence of multi-methods is substantially harder than for mono-methods.
  > • We address programming environment concerns of achieving **fast turnaround for programming changes and supporting independent development of libraries**, which could be adversely affected by a whole-program analysis such as class hierarchy analysis.
  > • We measure the run-time performance benefit and compile-time cost of class hierarchy analysis on several large programs written in Cecil [Chambers 92, Chambers 93], a pure object-oriented language with multi-methods. Moreover, we also measure the run-time performance benefits and compile-time costs of profileguided receiver class prediction and method specialization separately and in combination with class hierarchy analysis.  





## Class Hierarchy Analysis

* ![image-20200104155503028](D:\OneDrive\Pictures\Typora\image-20200104155503028.png)
* If no overriding of `m` implementation in the subclasses of `F`, `self.m` in `F::p` can be replaced by `C::m` mono implementation
* Alternatives
  * C++: `virtual` keyword
    * must be explicit decisions. designer decisions may not match the needs of the client program
    * `virtual/non-virtual` annotations are embedded in the source program, must modiffy source program
    * subtree of the inheritance graph can't convert virtual functions to non-virtual
      * how to make leaf class calling to be non-virtual?
  * sealing (`final`): similar weaknesses, programmers have to predict in advance



### Implementation

* class hierarchy analysis must be integrated with intraprocedural static class analysis (efficiency issues)
* previous frameworks
  *  ![image-20200104163238702](D:\OneDrive\Pictures\Typora\image-20200104163238702.png)
* Cone class sets
  * initial class set w.r.t. receiver of the method: inheriting from the class containg the method
  * union is feasible, but space-inefficient $\to$  Cone(C)
  * ![image-20200104164515114](D:\OneDrive\Pictures\Typora\image-20200104164515114.png)
  * `Class(C)` instead of `Cone(C)` if `C` is a leaf class
  * [[R: Palsberg'94]]
  * static type `C`, inferred intersected with `Cone(C)`
* Method Applies-To Sets
  * If all the classes inherit the same method, the message send can be statically bound, replaced with a direct procedural call
  * 1 slow way: iterate through all elements of Union and Cone sets, perform method lookup for each class, checking each class inherits the same method
    * slow for large sets (e.g. cones of classes with many subclasses)
  * alternative way: compare whole sets of classes at once
    * applies-to set: precompute for each method the set of classes for which that method is the appropriate target
      * on-demand when a message with a paraticular name and argument count
      * when messages send (`class.method(msg)`), class set inferred for the receiver (`class`) $\cap$ each potentially-invoked method's applies-to set
        * if only one method's applies-to set verlaps? it's the only method that can be invoked, de-virtualized
          * compile-time method lookup cache
    * how to pre-compute efficiently?
      * construct a partial order over the set of methods ($M_1 < M_2$ in the partial ordering if $M_1$ overrides $M_2$)
        * ![image-20200104204113206](D:\OneDrive\Pictures\Typora\image-20200104204113206.png)
      * for each method defined on class `C`, initial its applies-to set to `Cone(C)`
      * traverse the partial order top-down (bottom-up in the graph). for each method `M`, visit each of the immediately overriding methods, subtract off their (initial) applies-to sets from `M`'s applies-to set
      * applies-to set for method `C::M` = `Diff(Cone(C), Union(Cone(D1), ..., Cone(Dn)))` where `Di` are classes containing the directly-overriding method
      * can ignore the subtracting and safe through conservative for applies-to sets to be larger than necessary
      * [[Q: what about multiple inheritance? interfaces?]]
    * overlap testing efficiency?
      * arbitrary union $O(N^2)$ or $O(N)$ if known and sorted
      * cone and class representations: constant time (assuming testing inheritance for constant time)
        * `Cone(C1)` overlaps `Class(C2)` iff. `C1 = C2` or `C2` inherits from `C1`
      * arbitrary difference: complex, expensive
      * use `BitSet` to present `Difference` 
    * how to compute the receiver?
      * initialized to `Cone(C)` where `C` is the class containing the method
      * `super`?: out of applies-to set
* Support for dynamically-typed languages
  * runtime message-not-understood error
  * introduce `error` method in the root class, block static binding as two applicable methods (real and error)
  * support receiver class prediction
    * name & hard-wired table (Smalltalk-80, Self-91)
    * dynamic profile data (Slef-93, Cecil)
    * ![image-20200104211412197](D:\OneDrive\Pictures\Typora\image-20200104211412197.png)
    * can make final "unexpected" case a runtime message lookup error trap
* Support for Multi-methods
  * multiple-dispatching
  * associate methods with sets of `k`-tuples of classes (`k` is the \# of dispatched arguments of the method)
  * applies-to tuple of class sets `<Cone(C1), ..., C(k)>`
  * ![image-20200104213015491](D:\OneDrive\Pictures\Typora\image-20200104213015491.png)
    * empty optimization
    * monotype optimization
    * but it grows exponentially with difference numbers
  * ![image-20200104215809814](D:\OneDrive\Pictures\Typora\image-20200104215809814.png)
    * avoid duplication
    * smaller, drop more
  * impose a limit on the number of class set terms
    * stop narrowing if beyond



### Incremental Programming Changes

* conflict with incremental compilation?: structure (class hierarchy, method addition/removal) might change

* intermodule dependency information

  * DAG structure

  * ![image-20200104223534951](D:\OneDrive\Pictures\Typora\image-20200104223534951.png)

  * change in program $\to$ change in dependency graph, propagate downstreams

  * ![image-20200104223700542](D:\OneDrive\Pictures\Typora\image-20200104223700542.png)

  * > • one kind of dependency node represents the BitSet representation of the set of subclasses of a class (one product of class hierarchy analysis),
    > • another kind of dependency node represents the set of methods with a particular name (another product of class hierarchy analysis),
    > • a third kind of dependency node represents the applies-to tuples of the methods, which is derived from the previous two pieces of information, and
    > • a fourth kind of dependency node guards each entry in the compile-time method lookup cache  

  * filter nodes: support greater selectivity, avoid unnecessarily invalidating any compiled code

    * check whether information it represents really has changed
    * guard compile-time method lookup cache



### Optimization of Incomplete Programs

* with header file, we know class hierarchy without source code
  * unavailable code, just won't inlined
* library-only? difficult for clients can create subclasses override methods
  * sealing approach
  * compile specialized versions of method applicable only to classes present in library





## Conclusion

* class hierarchy analysis improves performance while preserving the source-level semantics of message passing and the ability for clients to subclass any class  
* requirement to underlying programming environment (especially when support incremental compilation)
* profile-guided class prediction the most effective in isolation at improving program performance
* class hierarchy + profile-guided improves
* How to extend the performance study to include interprocedural static class analysis algorithms as they mature
* What's the effectiveness and relative performance applied to statically-typed OOP like C++/Modula-3









## Motivation

## Summary

## Strength

## Limitation & Solution



