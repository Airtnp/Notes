# Scalable Propagation-Based Call Graph Construction Algorithms  

**Frank Tip, Jens Palsberg**

---



## Introduction

* RTA: single set for the whole program, scale
* 0-CFA: one set per expressions, scale?
* don't analyze values on the run-time stack
* construct call-graph
  * remove unreachable methods
  * inline unique target calls
  * interprocedural constant propagation
  * object inlining
  * tranformations of the class hierarchy
* OOP call-graph: conservative approximation of the set of methods that can be invoked by a given virtual method call
  * `e.m()` $\to$ set of class names $S_e$ that approximates the run-time values of the receiver expression $e$
* ![image-20200105224034088](D:\OneDrive\Pictures\Typora\image-20200105224034088.png)
* CHA, RTA scales
* [[Q: what is 0-CFA/k-CFA? Is it like Palsberg'91?]]
* k-CFA doesn't scale well at all
* 0-CFA: doubtful
* ![image-20200105230012694](D:\OneDrive\Pictures\Typora\image-20200105230012694.png)



## The Algorithms

* ![image-20200105230048293](D:\OneDrive\Pictures\Typora\image-20200105230048293.png)
* previous algs: RA, CHA, RTA, 0-CFA
* new algs: CTA, FTA, MTA, XTA
  * multiple set variables ranging over sets of classes/methods/fields
  * each program entity with precise local view



### Name-Based Resolution (Reachability Analysis/RA)

* a set variable $R$ (for reachable "methods") ranges over sets of methods
* and constraints
  * $\text{main}\ \in R$: main method is reachable
  * for each method $M$, each virtual call site $e.m(\cdots)$ occurring in $M$, each method $M'$ with name $m$, $(M \in R) \Rightarrow (M' \in R)$: 
    * if a method is reachable, and a virtual method call `e.m(...)` occurs in its body, then every method with name $m$ is reachable



### Class Hierarchy Analysis (CHA)

* `StaticTypes(e)`: static type of expression `e`
* `SubTypes(t)`: set of declared subtypes of type `t`
* `StaticLookup(C, m)`: the definition (if any) of a method with name `m` that one finds when starting a static method lookup in the class `C`
* constraints on 1 set variable `R`:
  * $\text{main}\ \in R$: main method is reachable
  * for each method $M$, each virtual call site $e.m(\cdots)$ occurring in $M$, each class $C \in $ `SubTypes(StaticType(e))` where `StaticLookup(C, m) = M'`: $(M \in R) \Rightarrow (M' \in R)$: 
    * if a method is reachable, and a virtual method call `e.m(...)` occurs in its body, then every method with name $m$  that inherited by a subtype of the static type of `e` is reachable



### Rapid Type Analysis (RTA)

* set variable `R` ranging over sets of methods

* set variable `S` ranging over sets of class names

  * approximates the set of classes for which objects are created during a run of the program

* constraints:

  * $\text{main}\ \in R$: main method is reachable
  * for each method $M$, each virtual call site $e.m(\cdots)$ occurring in $M$, each class $C \in $ `SubTypes(StaticType(e))` where `StaticLookup(C, m) = M'`: $(M \in R) \wedge (C \in S) \Rightarrow (M' \in R)$: 
    * if a method is reachable, and a virtual method call `e.m(...)` occurs in its body, and class has been instantiated, then every method with name $m$ that inherited by a subtype of the static type of `e` is reachable
  * for each method $M$, for each `new C()` occurring in `M`: $(M \in R) \Rightarrow (C \in S)$
    * `S` contains the classes that are instantiated in a reachable method

* easy to implement

* scale well

* significantly more precise than CHA

  

### Separate sets of methods and fields (XTA)

* a distinct set variable $S_M$ for each method $M$
  * instantation set of classes inside each method
* a distinct set variable $S_x$ for each field $x$
  * [[Q: potential instantiation set of classes for variable `x`?]]
* `ParamTypes(M)`: set of static types of the arguments of the method `M`
  * exclusing `this` pointer
* `ReturnType(M)`: static return type of `M`
* `SubTypes(Y) = ` $\bigcup_{y \in Y}$ `SubTypes(y)`
* constraints
  * $\text{main}\ \in R$: main method is reachable
  * for each method $M$, each virtual call site $e.m(\cdots)$ occurring in $M$, each class $C \in $ `SubTypes(StaticType(e))` where `StaticLookup(C, m) = M'`: 
    * $$(M \in R) \wedge (C \in S_M) \Rightarrow \begin{cases} M' \in R \ \wedge \\ \text{SubTypes(ParamTypes(}M')) \cap S_M \subseteq S_{M'}\ \wedge \\   \text{SubTypes(ReturnType(}M')) \cap S_{M'} \subseteq S_M\ \wedge \\ C \in S_{M'} \end{cases}$$
    * refines RTA by
      * insisting that objects of the target class `C` are available in the local set $S_M$
      * adding 2 inclusions that capture a flow of data from `M` to `M'` and from `M'` back to `M`
      * stating that an object of type `C` (this pointer) is available in `M'`
  * for each method $M$, for each `new C()` occurring in `M`: $(M \in R) \Rightarrow (C \in S_M)$
    * refines RTA by adding class name `C` to just the set variable for the method `M`
  * for each method `M` in which a read of a field `x` occurs: $(M \in R) \Rightarrow (S_x \subseteq S_M)$
    * reflect a data flow from a field to a method body
  * for each method `M` in which a write of a field `x` occurs: 
    * $(M \in  R) \Rightarrow (\text{SubTypes(StaticType} (x)) \cap S_M) \subseteq S_x$
    * reflect a data flow from a method body to a field
* take hierarchy information & creation point information into account
  * [[N: data flow of local types & local instantiations]]



### Algorithms in the space between RTA & XTA (CTA, MTA)

* CTA
  * distinct set variable $S_C$ for each class $C$
    * unify the flow information for all methods and fields
  * constraints in addition to XTA
    * If a class $C$ defines a method $M$: $S_C = S_M$
    * If a class $C$ defines a field $x$: $S_C = S_x$
* MTA
  * distinct set variable $S_C$ for each class $C$
    * unify the flow information for all methods (not fields)
  * set variable $S_x$ for every field $x$
  * constraints in addition to XTA
    * If a class $C$ defines a method $M$: $S_C = S_M$
* FTA
  * distinct set variable $S_C$ for each class $C$
    * unify the flow information for all fields (not methods)
  * set variable $S_M$ for every method $M$
  * constraints in addition to XTA
    * If a class $C$ defines a field $x$: $S_C = S_x$



### Summary

* $\mathcal{C}$: the \# of classes in the program
* $\mathcal{M}$: the \# of methods in the program
* $\mathcal{F}$: the \# of fields in the program
* ![image-20200106211929698](D:\OneDrive\Pictures\Typora\image-20200106211929698.png)
* all new algorithms + 0-CFA: $O(n^2 \times \mathcal{C})$ where $n$ is the \# of set variables
* 0-CFA as a extension of XTA
  * 1 set variable for each argument and each expression that evaluates to an object (including references to objects on the run-time stack)



## Implementation Issues

* based on Jax, an application extractor for Java
  * RTA for constructing call graphs
* Jikes Bytecode Toolkit for reading the Java class files
  * creating internal representation of classes (string-based reference of class file format as pointer references)
* XTA implementation
  * iterative, propagation-based
  * 3 work-lists associated with each program compoent that keep track of processed types that have been propagated onwards from the components to other components
  * current types propagated onwards in the current iteration
  * new types propagated to the components in the current iteration and onwards in the next iteration
* FTA/MTA implementation
  * shared set for all the methods & fields in a class respectively
  * propagation between different methods/fields in the same class are not needed
  * once a type propagated to a method/field in class `C`, the other method/fields in `C` still have to be revistsed, because onward propagations from those methods/fields may have to take place
* CTA implementation not complete
* membership-test: array-based + hash-based
* subtype-test: associating 2 integer with each class (pre-order, post-order traversal)
  * subclass relationship $\to$ unit time comparing associated numbers
* On realistic Java applications
  * direct method calls: can be modeled using simple set-inclusion between the sets associated with the callee & the caller
  * arrays: modeled as classes with one instance fields that represents all of its elements
    * a method `m` assumed to read an element from array `A` if
      * an object of type `A` is propagated to `m`
      * `m` contains an `aaload` byte code instruction
    * a method `m` is assumed to write to `A`-element if
      * an object of type `A` is propagated to `m`
      * `m` contains an `aastore` instruction
  * exception handling: may cause nontrivial flow of types between methods
    * \# of types involved like to be small (subtypes of `java.lang.Throwable`)
    * hierarchy of user-defined exception types not very large/complex
    * use a single, global set of types represents the run-time type of all expressions in the entire program whose static type is a subtype of `java.lang.Throwable`
    * use that set to resolve all method calls on exception objects
  * stack examination: better precision & greater efficiency can be achieved by examining the instruction that follows a method call / field reaad
    * `checkcast C`? exception is thrown unless the runtime type of the object returned by the method is a subtype of `C`
    * can excluse from the types being propagated to the calling method any type that is not subtype of `C`
      * [[Q: ? what if type is not safe]]
    * `pop` stack? avoid propagating from the callee to the caller together
  * incomplete application: extend classes in standard lib, call library methods, override library methods
    * associate a single set of objects $S_E$ with the outside world
    * If a method `m` calls a method `m'` outwise the application, propagate $(S_m \cap \text{ParamTypes}(m'))$ to $S_E$.
      * for virtual methods, any types passed via `this` are also propagated to $S_E$
    * Whenever a method `m` writes to a field `f` outside the application, propagate $(S_m \cap \text{Type}(f))$ to $S_E$.
      * read-accessing an external field causes similar flow in the opposite direction
    * If a virtual method in the application overrides an external method `m`, conservative assupmtion: external code contains a call to `m'`
      * use the set $S_E$ to determine the set of methods in the application that may be invoked by the dynamic dispatch mechanism
      * for each such method `m'`, use the parameter type + return type of `m'` to model the flow of objects betwen $S_E$ and $S_{m'}$
    * For calls to certain methods in the standard lib, propagation to the set $S_E$ is unnecessary
      * objects passed to the method will not be the receiver of subsequent method calls
    * A separate set of objects $S_C$ can be associated with an external class $C$ in cases where the objects passed to methods in $C$ only interact with other external classes in limited ways
* ![image-20200107014607996](D:\OneDrive\Pictures\Typora\image-20200107014607996.png)
* ![image-20200107014617629](D:\OneDrive\Pictures\Typora\image-20200107014617629.png)
* ![image-20200107014624378](D:\OneDrive\Pictures\Typora\image-20200107014624378.png)
* ![image-20200107014640557](D:\OneDrive\Pictures\Typora\image-20200107014640557.png)



## Future Work

* program transformation names all stack locations
* Does 0-CFA use significantly more time & space than new algorithms for large benchmarks
* Is the potential extra precision of 0-CFA worth the increased cost?
* When used in a compiler for de-virtualization of monomorphic calls, does 0-CFA give significantly better speedups than our algorithms?
* Hindley-Milner polymorphism?
  * treat each distinct allocation site as a separate class, keep the fields in these artificial classes distinct
  * potential of significantly increasing the cost
  * accuracy may improve since unrelated instantiations of the same type kept separate















## Motivation

## Summary

## Strength

## Limitation & Solution



