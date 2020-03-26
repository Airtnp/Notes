# Object-Oriented Type Inference

**Jens Palsberg, Michael I. Schwartzbach**

---



## Introduction

* infer types in un-typed OOP (inheritance, assignments, late binding)
* allow 
  * polymorphic methods
  * all messages are understood
  * annotate program with type information
  * used as the basis of an optimizing compiler
* types: finite set of classes
* subtyping: set inclusion
* trace graph: set of conditional type constraints, compute the least solution by least fixed-point derivation
  * typable: constraints are solvable
  * handling late binding by conditional constraints
  * resolving the constraints by least fixed-point derivation rather than unification
* late binding: runtime method resolution
* untyped OOP with assignments & late binding allows rapid prototyping
  * classes inherit implementation, not specification
* example language: Smalltalk-like, no metaclasses/blocks/primitive methods
  * explicit `new`/`if-then-else` expressions
  * classes like Natural can be programmed



## Late Binding

* > OOP to me means only messaging, local retention and protection and hiding of state-process, and extreme LateBinding of all things.

* late binding: message send is dynamically bound to an implementation depending on the class of the receiver

  * danger: class of the receiver doesn't implement a method? / the receiver is `nil`?
  * make control flow of a program hard to follow, time-consuming runtime search for an implementation

* help an optimizing compiler: infer information about

  * Can the receiver be `nil`?
  * Can the receiver be an instance of a class which doesn't implement a method for the message?
  * What are the classes of all possible non-`nil` receivers in any execution of the program?

* Type := a finite set of classes

* Induced Type: set of classes of all possible non-`nil` values to which it may evaluate in any execution of that particular program

  * generally uncomputable
  * subtype (set inclusion) of any sound approximation

* Sound approximation: superset of the induced type

* Goals of type inference

  * Safety guarantee: any message is sent to either `nil` or an instance of a class which implements a method for the message
    * ignore the `nil` checking, a separate issues for standard data flow analysis
  * Type information: a sound approximation of the induced type of any receiver
    * if info is a singleton set? early binding / in-line substitution ([[N: de-virtualization]])
    * if info is a empty set? always be `nil`
    * can used for annotation
  * sensitive to small changes $\to$ separate compilation seems impossible?

* ![image-20191231232012888](D:\OneDrive\Pictures\Typora\image-20191231232012888.png)

* method type approaches

  * requiring programmer to specify types for instance variables whereas types of arguments are inferred
  * handling late binding by assuming that each message send may invoke all methods for that message
    * not capable of checking most common programs

* conditional constraints: derived from a finite graph

  * record types (extendible/recursive), producing less precise typings, not clear whether would be useful in an optimizing compiler
    * type schemes always correspond to singletons / infinite sets of monotypes



## The Language

* ![image-20191231232430133](D:\OneDrive\Pictures\Typora\image-20191231232430133.png)
* program := a set of classes followed by an expression whose value is the result of executing the program
* class := can be defined using inheritance + contains instance variables/methods
* method := message selector `(m1, ..., mn)` with formal parameters and an expression
* `if-then-else`: test if nill
* `self class new`: yields an instance of the class of `self`
* `E instanceOf ClassId`: yields an runtime check for class membership
* `Natural`: peano number
* ![image-20191231232843060](D:\OneDrive\Pictures\Typora\image-20191231232843060.png)
* ![image-20191231232909140](D:\OneDrive\Pictures\Typora\image-20191231232909140.png)





## Type Inference

* Inheritance: Classes inherit implementation and not specification
  * $\to$ separate type inference for class & its subclasses
    * expanding all classes before doing type inference
      * copying the text of a class to its subclasses
      * replacing each message send to `super` by a message send to a renamed version of the inherited method
      * replacing each `self class new` expression by a `ClassId new` expression where `ClassId` is the enclosing class in the expanded program
    * quadratic size of the original
* Classes: finitely many classes in a program
* Message sends: finitely many syntactic message sends in a program
  * finite representation of type info: trace graph
    * local constraints := generated from method bodies; contained in nodes
    * connecting constraints := reflect message sends; attached to edges
    * conditions := discriminate receivers; attached to edges



### Trace Graph Nodes

* each method yields a number of different nodes
  * each syntactic message send with the corresponding selector
  * ![image-20200101153258986](D:\OneDrive\Pictures\Typora\image-20200101153258986.png)
* single node for main expression of the program



### Local Constraints

* syntactic occurrence of an expression `E` in the implementation of the method, regard its type as an unknown variable $[[E]]$
* approximations
  * nil values: doesn't keep track of `nil` values
  * instance variables: doesn't flow analyze the contents of instance variables
    * an instance variable as having a single possibly large type
  * ![image-20200101155022602](D:\OneDrive\Pictures\Typora\image-20200101155022602.png)
* for an expression `E`, local constraints generated from all the phrases in its derivation
  * ![image-20200101155127801](D:\OneDrive\Pictures\Typora\image-20200101155127801.png)
  * only (4) & (8) shows approximations
  * [[Q: why (6) has type of C?]]
  * constant: classes
  * variable: expressions
  * constant $\subseteq$ variable
  * variable $\subseteq$ constant
  * variable $\subseteq$ variable
* each different node employs unique type variables, except that types of instances variables are common to all nodes corresponding to methods implemented in the same class



### Trace Graph Edges

* edge: possible connections between a message send & a method that may implement it
* ![image-20200101185542086](D:\OneDrive\Pictures\Typora\image-20200101185542086.png)
* generalize trivially to methods with several parameters
* \# of edges quadratic in the size of the program



### Global Constraints

* ![image-20200101193314250](D:\OneDrive\Pictures\Typora\image-20200101193314250.png)
* combine local & connecting constraints $\rightarrow$ conditional constraints (inequality holds when all conditions hold)
* global constraints: union of the conditional constraints generated by all paths in the graph (worst-case expoential size)
* any execution $\Rightarrow$ pattern of method execution in the trace graph
* `VAL(E)`: value of expression, `CLASS(b)` class of an object, `L`: solution to the global constraints
* Soundness Theorem: If `VAL(E) != nil` then `CLASS(VAL(E))` $\in$ $L([[E]])$
  * proof by induction in \# of message sends performed during the trace
* an expression `E` occurring `k` times has $[[E]])1, \cdots, [[E]]_k$ in the global constraints
  * can do a sound approximation, make it $\bigcup_i L([[E]]_i)$
* ![image-20200102144303289](D:\OneDrive\Pictures\Typora\image-20200102144303289.png)



### Type Annotations

* instance variable `x`: `L([[x]])`
* method `{C} x L([[F1]]) x ... x L([[Fn]]) -> L[[E]]`
* better than Suzuki



### Exponential Worst-Case

* ![image-20200102150248738](D:\OneDrive\Pictures\Typora\image-20200102150248738.png)
* similar  to type inference in ML
* worst-case EXPTIME, but useful in practice



## Conclusion

* sound, handle most common cases
* a set of uniform type constraints is constructed, solved by a fixed-point derivation
  * improved by an orthogonal effort in data flow analysis
* metaclasses $\to$ classes
* blocks $\to$ objects with a single method
* primitive methods $\to$ stating the constraints that machine code must satisfy
* challenge: how to extend algorithm to produce type annotations with type substitution



## Appendix: Solving Systems of Conditional Inequalities

* CI-system consists of
  * a finite set $\mathcal{A}$ of atoms
  * a finite set ${\alpha_i}$ of variables
  * a finite set of conditional inequalities of the form
    * $C_1, \cdots, C_k \Rightarrow Q$
    * $C_i$: condition of the form $a \in \alpha_j$ where $a \in \mathcal{A}$ is an atom
    * $Q$: inequality of one of the following forms
      * $A \subseteq \alpha_i$
      * $\alpha_i \subseteq A$
      * $\alpha_i \subseteq \alpha_j$
* solution $L$ of the system assigns to each variable $\alpha_i$ a set $L(\alpha_i) \subseteq \mathcal{A}$ such that all the conditional inequalities are satisfied
* ![image-20200102151441453](D:\OneDrive\Pictures\Typora\image-20200102151441453.png)
* $\mathcal{C}$: CI-system with atoms $\mathcal{A}$ and $n$ distinct variables
  * assignment: element of $(2^\mathcal{A})^n \cup \{ \text{error}\}$ ordered as a lattice
    * ![image-20200102151550762](D:\OneDrive\Pictures\Typora\image-20200102151550762.png)
  * if $V$ an assignment, $\tilde{C}(V)$ a new assignment
    * If $V$ error, $\tilde{C}(V)$ error
    * If for any enabled (all conditions true under $V$) inequality of the form $\alpha_i \subseteq A$ we don't have $V(\alpha_i) \subseteq A$, then $\tilde{C}(V)$ error
    * otherwise, $\tilde{C}(V)$ the smallest pointwise extension of $V$
      * $\forall A \subseteq \alpha_j$ (enabled), $A \subseteq \tilde{C}(V)(\alpha_j)$
      * $\forall \alpha_i \subseteq \alpha_j$ (enabled), $V(\alpha_i) \subseteq \tilde{C}(V)(\alpha_j)$
    * $\tilde{\mathcal{C}}$ is monotonic in above lattice
* ![image-20200102151924439](D:\OneDrive\Pictures\Typora\image-20200102151924439.png)
* ![image-20200102151938095](D:\OneDrive\Pictures\Typora\image-20200102151938095.png)
* ![image-20200102152005448](D:\OneDrive\Pictures\Typora\image-20200102152005448.png)
* 



## Question

* How to use fixed-point derivation to solve set constraints?
  * [how-to-solve-set-constraints](http://web.cs.ucla.edu/~palsberg/course/cs232/papers/how-to-solve-set-constraints.pdf)
  * efficiently $O(n^3)$
    * ![image-20200102153646944](D:\OneDrive\Pictures\Typora\image-20200102153646944.png)
* 













## Motivation

## Summary

## Strength

## Limitation & Solution



