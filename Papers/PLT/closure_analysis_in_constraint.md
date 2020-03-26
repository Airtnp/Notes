# Closure Analysis in Constraint Form

**Jens Palsberg**

---



## Introduction

### Abstract

* flow analysis of untyped high-order functional programs presented, ..., usually defined as abstract interpretations
* used for different tasks, type recovery, globalization, binding-time analysis
* contain a global closure analysis that computes information about higher-order control-flow
  * correct with call-by-name/call-by-value, remained open for arbitrary beta-reduction (solved by this paper)
* closure information is still valid after beta-reduction
  * closure analysis $\to$ constraint system



### Background

* optimization of higher-order functional languages $\to$ powerful program analyses

* traditional framework: abstract interpretation

  * typed language: suitable abstract domains can often defined by induction on the structure of types

    * > function spaces can be abstracted into function spaces.   

    * ???

  * untyped (lambda-calculus, Scheme): abstract domains cannot be defined by abstracting function spces to function spces

* untyped program analysis: in the absence of types, define the abstract domains in terms of program points

* consider $\lambda$-term

  * $(\lambda x.\lambda y. y(x I)(x K)) \Delta$ where $I = \lambda a.a$, $K = \lambda b.\lambda c. b$, $\Delta = \lambda d.d d$
  * label variables
    * bound: $\lambda$
    * free: arbitrary label
  * ![image-20200113203107400](D:\OneDrive\Pictures\Typora\image-20200113203107400.png)
  * ![image-20200113203204754](D:\OneDrive\Pictures\Typora\image-20200113203204754.png)

* For every application point, which abstractions can be applied?

* For every abstraction, which argument can it be applied?

* Closure analysis: Higher-order analysis = first-order analysis + closure analysis

  * can be defined in abstract interpretations
    * abstract domain: programs to be analyzed
      * traditional: can analyze pieces of program in isolation
    * global: complete program is required before abstract domain defined
    * cannot take higher-order input (add program points)
  * flow analyses: analyses based on closure analysis
  * can handle dynamic & multiple inheritance (according to Similix, Schism, Agesen on Self)
  * set-based analysis using constraints: Heinitze
    * difference: avoid analyzing code that will not be executed under call-by-value



### Our Results

* closure analysis is correct w.r.t. arbitrary beta-reduction (any reduction strategy)
* subject-reduction result: closure info is still valid after $\beta$-reduction
* ![image-20200113205937559](D:\OneDrive\Pictures\Typora\image-20200113205937559.png)
* ![image-20200113205945545](D:\OneDrive\Pictures\Typora\image-20200113205945545.png)
* constraint system doesn't depend on labels being distinct: possible to analyze $\lambda$-term, $\beta$-reduce, analyzing results without relabeling
  * a direct proof of correctness of modified abstract interpreation more complicated than proof presented here.
* ![image-20200113210415265](D:\OneDrive\Pictures\Typora\image-20200113210415265.png)



### Example

* constraints $\to$ Horn clauses
  * `n` abstractions & `m` applications, $n + (2 \times m \times n)$ constraints
    * worst-case quadratic
* ![image-20200113220409301](D:\OneDrive\Pictures\Typora\image-20200113220409301.png)
* metavariables: $[[\mathcal{v}^l]], [[\lambda^l]], [[@_i]]$ as variables with label $l$, abstractions with label $l$, applications with label $i$
  * don't assume just one abstraction with label $l$, do closure analysis of all terms
* ![image-20200113222043198](D:\OneDrive\Pictures\Typora\image-20200113222043198.png)
* minimal solution is a mapping $L$
  * ![image-20200113222333243](D:\OneDrive\Pictures\Typora\image-20200113222333243.png)
  * the whole λ-term will, if normalizing, evaluate to an abstraction with label 2 ($L[[@_4]] = \{2\}$)
  * at application point $@_3$, there can only be applied abstraction with label 2 ($L[[\mathcal{v}^1]] = \{2\}$)
  * the application point $@_3$ is the only point where abstractions with label 2 can be applied ($L[[\lambda^1]] = \{1\}$)
    * [[Q: ??? what does it matter with label 2]]
  * such abstractions can only be applied to $\lambda$-terms that either do not normalize / evaluate to an abstraction with label 2 ($L[[\mathcal{v}^2]] = \{2\}$)



## Closure Analysis

* ![image-20200113225356081](D:\OneDrive\Pictures\Typora\image-20200113225356081.png)
* redex: $(\lambda^l x. E) @_i E'$
  * ![image-20200113225455034](D:\OneDrive\Pictures\Typora\image-20200113225455034.png)
* abstract domain for closure analysis of $\lambda$-term E: `CMap(E)`
  * ![image-20200113225840489](D:\OneDrive\Pictures\Typora\image-20200113225840489.png)
* ![image-20200113230730257](D:\OneDrive\Pictures\Typora\image-20200113230730257.png)
* ![image-20200113230738553](D:\OneDrive\Pictures\Typora\image-20200113230738553.png)
* ![image-20200113233907920](D:\OneDrive\Pictures\Typora\image-20200113233907920.png)
* ![image-20200113234024570](D:\OneDrive\Pictures\Typora\image-20200113234024570.png)
* ![image-20200113234031656](D:\OneDrive\Pictures\Typora\image-20200113234031656.png)
* ![image-20200113234040070](D:\OneDrive\Pictures\Typora\image-20200113234040070.png)
* Bondorf's definition
  * ![image-20200113234102968](D:\OneDrive\Pictures\Typora\image-20200113234102968.png)
* Simpler Abstract Interpretation
  * ![image-20200113234358149](D:\OneDrive\Pictures\Typora\image-20200113234358149.png)
  * ![image-20200113234412015](D:\OneDrive\Pictures\Typora\image-20200113234412015.png)
* A Constraint System
  * ![image-20200113234450966](D:\OneDrive\Pictures\Typora\image-20200113234450966.png)



## Equivalence

* [[T: read original paper]]



## Correctness

* ![image-20200113235321557](D:\OneDrive\Pictures\Typora\image-20200113235321557.png)
* ![image-20200113235326894](D:\OneDrive\Pictures\Typora\image-20200113235326894.png)
* ![image-20200113235341797](D:\OneDrive\Pictures\Typora\image-20200113235341797.png)
* ![image-20200113235552414](D:\OneDrive\Pictures\Typora\image-20200113235552414.png)
* ![image-20200113235620245](D:\OneDrive\Pictures\Typora\image-20200113235620245.png)
* [[T: read original proof in induction]]













## Motivation

## Summary

## Strength

## Limitation & Solution



