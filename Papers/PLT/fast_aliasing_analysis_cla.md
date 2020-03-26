# Ultra-fast Aliasing Analysis using CLA: A Million Lines of C Code in a Second 

**Nevin Heintze, Olivier Tardieu**

---



## Introduction

* CLA: compile-link-analyze architecture
  * Andersen-style points-to
  * dependence
  * unification-style points-to
  * scale to large code base
  * support separate and/or parallel compilation of collections of source files
  * indexing structure: support rapid dynamic loading of just those components of object files needed for a specific analysis
* dynamic transitive closure (DTC)
  * previous: transitively closed constraint graph (Andersen's)
  * pre-transitive graph: not transitively closed
  * perform graph reachability computation when a node info is requested
  * caching of reachability computation
  * cycle elimination
    * cycle detection: non-trivial for previous, essentially free for this one
* points-to analysis $\to$ forward data-dependence analysis tool deployed within Lucent
* given a million+ lines of C code, and a proposed change of the form "change the type of this object (e.g. a variable or struct field) from type l to type 2", find all other objects whose type may need to be changed to ensure the "type consistency" of the code base.  
* avoid data loss through implicit narrowing conversions
* global data-dep. analysis that in effect performs a forward data-dependence analysis
* critical part: points-to analysis `*p =x `



## Motivating Application - Dependence Analysis

* ```c++
  short x, y, z, *p, v, w;
  y = x;
  z = y+l;
  p = &v;
  *p = z;
  w = 1;
  ```

* `struct`, type dependencies

* ![image-20200126224516486](D:\OneDrive\Pictures\Typora\image-20200126224516486.png)

* ![image-20200126220920984](D:\OneDrive\Pictures\Typora\image-20200126220920984.png)

* important of paths



## Andersen's Points-to Analysis

* unification-based: an assignment such as x = y invokes a unification of the node for x and the node for y in the points-to graph
  * The algorithms for the unification-based approach typically involve union/find and have essentially linear-time complexity.
  * less accurate
* subset relationships: an assignment such as x = y gives rise to a subset constraint x D y between the nodes x and y in the points-to graph   
  * subtyping system/subset constraints/dynamic transitive closure
  * easy to understand results
  * cubic-time complexity



### A Deductive Reachability Formulation

* context-insensitive, flow-insensitive version of the subset-based approach
  * better accuracy
  * inspect dependency chains
* simple deductive reachability system
  * CFA style
  * tiny language: operators * and &
* ![image-20200126224037574](D:\OneDrive\Pictures\Typora\image-20200126224037574.png)
* ![image-20200126224053230](D:\OneDrive\Pictures\Typora\image-20200126224053230.png)
* nested use of * and & are removed by a preprocessing phase
  * programs are sequences of $e_1 = e_2$ where $e_1$ cannot be $\&x$
* ![image-20200126224448944](D:\OneDrive\Pictures\Typora\image-20200126224448944.png)
* ![image-20200126224534864](D:\OneDrive\Pictures\Typora\image-20200126224534864.png)



### Analysis of Full C

* values like integer $\to$ trivial
* `struct/union`: complex
  * 1 possibility: each declaration of a variable of `struct/union` treated as an unstructured memory location, any assignment to a field as an assignment to the entire chunk
    * $x.f$ as an assignment to `x` where `f` is ignored
    * field-independent approach
  * field-based treatment: collect info. with each field of each struct
    * `x.f` as assignment to `f` and the based object is ignored
* ![image-20200126224906213](D:\OneDrive\Pictures\Typora\image-20200126224906213.png)
* our solution: field-based, because dep. analysis is field-based, significant implication in practice (for large codebase)



## Compile-Link-Analyze

* modularity problem: scale to large code base, avoid re-parsing/reprocessing the entire code base when changes are made to 1/2 files
* basic approach: parse compilation units down to an IR, defer analysis to a hybrid link-analyze phase
  * DEC's MIPS: frontend  $\to$ internal ucode files $\to$ hybrid linker (uld)
    * concatenate ucode files together into a single big ucode, then perform analysis, optimization, code generation
  * modularize parsing
* analyze problem components (at the level of functions/source files), compute summary info capturing the results of these local analyses
  * summary combine/link together in subsequent global analysis phase
  * analogous to the construction of principle types in type inference systems (some type annotations, [[N: pyi, sig]])
  * full polymorphic typing goes well beyond simply analyzing code in a modularity way, since it allows different type instantiations for different uses of a function (akin to context-sensitive analysis)
* Das: hybrid unification-based points-to analysis
  * each source file is parsed, and the assignment statements therein are used to construct a points-to graph with flow edges, which is simplified using a propagation step  
  * The points-to graph so computed is then "serialized" and written to disk, along with a table that associates symbols and functions with nodes in the graph  
  * reads in all of these (object) files, unifies nodes corresponding to the same symbol or function from different object files, and reapplies the propagation step to obtain global points-to information  
  * analysis algorithm is first applied to individual files and the internal state of the algorithm (which in this case is a points-to graph, and symbol information) is frozen and written to a file. Then, all of these files are thawed, linked and the algorithm re-applied  
* object files: specific to particular class of analysis (points-to) & algorithm (hybrid unification-based) & implementation



### The CLA Model

* local computation + linking + global analysis
* local computation: parse source files + extract assignment statements (no actual analysis performed)
* linking: link together the assignment statements
  * unchanged for many diff. impl. of points-to analysis & diff. alg. of analysis
  * justify investing resources into optimizing the representation of the collections of assignments
* compile phase
  * parse source file
  * extract assignments & function call/return/definitions
  * write an object file (indexed DB)
  * temporary variables introduced to break complex assignment
* link phase
  * merge all DB file
  * link info in object files to link global symbols
  * recompute indexing info.
* analyze phase
  * load linked object file (only required part)
  * easy to reading & re-reading index info.
    * reduce memory footprint
  * Andersen's analysis
* ![image-20200127145441217](D:\OneDrive\Pictures\Typora\image-20200127145441217.png)
* [[Q: locality issues & improvement?]]
* object files don't depend on the internals of our impl. & freely change the impl. details without changing the object file format
* pre-analysis optimizer: DB-to-DB transformers
* context-sensitive analysis: control duplication of primitive assignment in the DB
* [[N: A decouple layer, why not another IR?]]
* ![image-20200127210603539](D:\OneDrive\Pictures\Typora\image-20200127210603539.png)
* ![image-20200127210610978](D:\OneDrive\Pictures\Typora\image-20200127210610978.png)
* ![image-20200127210623627](D:\OneDrive\Pictures\Typora\image-20200127210623627.png)
* ![image-20200127210643787](D:\OneDrive\Pictures\Typora\image-20200127210643787.png)



## A Graph-Based Algorithm For Andersen's Analysis

* join-point effect of context-insensitive flow-insensitive analysis: results from different execution paths can be joined together and distributed to the points-to sets of many variables.  
  * points-to set computed by the analysis can be O(n)
  * scalability disaster if all points-to sets are explicitly enumerated
* Aiken addressing issues of Andersen's analysis
  * elimination of cycles in the inclusion graph
  * projection merging to reduce redundancies in the inclusion graph
  * transitive-closure based algorithm
* context/flow-sensitive to reduce effect of join-points
  * but cost large
  * unlikely to scale
* sub-transitive control-flow analysis to avoid propagation of info. from join points
  * usual dynamic transitive closure formulation of CFA redesigned so dynamic edge-adding rules are de-coupled from the transitive closure rules
  * linear time algorithms
  * effective on bounded-type programs, an unreasonable restriction for C
* deductive reachability system
  * simple assignments `x = y`
  * base assignment `x = &y`
  * complex assignment `x = *y` or `*x = y`
    * omit `*x = *y` (split into 2)
* graph `G`: initially contains all info. about the simple assignment & base assignment
  * initial nodes: for each variable `x` in the program, introduce node $n_x$ and $n_{*x}$
    * $n_{*x}$ is needed only if when a complex assignment of `y = *x`
  * initial edges: corresponding to each simple `x = y`, there is an edge $n_x \to n_y$ from $n_x$ to $n_y$
  * any any point, `G` represents what we explicitly know about the set of lvals for each program variable
  * maintain in pre-transitive form: we don't transitively close the graph
    * whenever need to determine the current lvals of a specific variable, must perform graph reachability (`getLval(n_x)`)
      * find the set of lvals of variable `x` $\to$ find set of nodes reachable from $n_x$ in 0+ steps
      * compute the union of the `baseElements` sets for all of these nodes
* set of base elements
  * `baseElement(n_x) = {y: x = &y appears in P}`
* another set `C`: complex assignments
* algorithm
  * iterating through the complex assignments in `C`
  * adding edges to `G` based on the info. currently in `G`
  * ![image-20200128004651625](D:\OneDrive\Pictures\Typora\image-20200128004651625.png)
* Tradeoff in pre-transitive & on demand
  * with cycle-elimination, cheaper to compute all lvals for all nodes when the alg. terminates than it is to do so during execution
  * the pre-transitive algorithm trades off traversal of edges versus flow of lvals along edges  
    * ![image-20200128005437157](D:\OneDrive\Pictures\Typora\image-20200128005437157.png)
* ![image-20200128005459549](D:\OneDrive\Pictures\Typora\image-20200128005459549.png)
* cycle elimination :star:
* cache computations: for lvals & current iteration :star:
* hash table + per-node list
* share common lvals set
* ![image-20200128005611899](D:\OneDrive\Pictures\Typora\image-20200128005611899.png)
* ![image-20200128005618836](D:\OneDrive\Pictures\Typora\image-20200128005618836.png)





## Conclusion

* ![image-20200128005654365](D:\OneDrive\Pictures\Typora\image-20200128005654365.png)
* ![image-20200128005703195](D:\OneDrive\Pictures\Typora\image-20200128005703195.png)
* 





## Motivation

## Summary

## Strength

## Limitation & Solution



