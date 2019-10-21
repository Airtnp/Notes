# DryadLINQ: A System for General-Purpose Distributed Data-Parallel Computing Using a High-Level Language 

**Yuan Yu, Michael Isard, Dennis Fetterly, et al.**

------



## Introduction

* generalize previous execution environments (SQL/MR/Dryad)
  * adopting an expressive data model of strongly typed .NET objects
  * supporting general-purpose imperative & declarative operations on datasets within a traditional high-level PL
* DryadLINQ: sequential program composed of LINQ expressions performing arbitrary side-effect-free transformations on datasets. 
  * Written & Debugged using .NET tools
  * translate data-parallel portions to distributed execution plan in Dryad
* imperative/declarative operations on datasets within .NET, strongly typed
* illusion of writing for a single computer & having the system dealing with the complexities
* LINQ (Language INtegrated Query)
* Parallel database: restricted type system & declarative query-oritented nature (low expressiveness)
* MapReduce: join, scripting language required, optimizations lacking, type system support lacking, pipelines lacking
* DSL (Sawzall, Pig, HIVE): limited hybridizations of declarative & imperative program model & generalization SQL's stored-procedural model with automatic optimizations. inherit SQL disadvantages, adopting simple custom type system, provided limited support for iterative computations (MR is less flexible than Dryad)
* DryadLINQ: virtualized expression plan



## System Architecture

* ![1571253433066](D:\OneDrive\Pictures\Typora\1571253433066.png)
* ![1571255681259](D:\OneDrive\Pictures\Typora\1571255681259.png)
* 1. .NET user application creates DryadLINQ expression lazily
  2. call `ToDryadTable` into data-parallel execution
  3. DryadLINQ compiles LINQ expression into a distributed Dryad execution plan
     1. decomposition of the expr into sub-expr (Dryad vertex)
     2. generation of code & static data for remote Dryad vertices
     3. generation of serialization code for the required data types
  4. DryadLINQ invokes a custom DryadLINQ-specific, Dryad job manager (behind a cluster firewall)
  5. Job manager creates job graph using Step 3 plan. Schedule & spawn vertices
  6. Each Dryad vertex executes a vertex-specific program
  7. Dryad job complete successfully -> it writes data back to output tables
  8. Job manager process terminates, return control back to DryadLINQ. DryadLINQ creates the local `DryadTable` object encapsulating the outputs (input to subsequent expr)
  9. Control returns to the user application. Iterator interface fetching contents
  10. user applications generate subsequence DryadLINQ



## Programming with DryadLINQ

* LINQ: a set of .NET constructs for manipulating sets & sequences for data items
  * base type `IEnumerable<T>` (accessed using an iterator interface)
  * `IQueryable<T> <: IEnumerable<T>`: (unevaluated) expression constructed by combing LINQ datasets using LINQ operators
  * in general the programmer neither knows nor cares what concrete type implements any given datasets' `IEnumerable` interfaces
  * DryadLINQ composes all LINQ expressions into `IQueryable` objects and defers evaluation until result is needed
  * strongly typed
* DryadLINQ constructs
  * data model: distributed implementation of LINQ collections
  * ![1571257789177](D:\OneDrive\Pictures\Typora\1571257789177.png)
  * hash-partition / range-partition / round-robin
    * `HashPartition<T, K>`, `RangePartition<T, K>`
    * LINQ no-ops
  * input/output: `DryadTable<T> <: IQueryable<T>`
    * subtype supporting underlying storage providers (NTFS, SQL tables, metadata)
    * metadata, schema
    * `GetTable<T>(URI)`, `ToDryadTable<T>(LINQExpr, URI)`
  * restriction: all function called in DryadLINQ expressions must be side-effect free
  * `Apply (fmap)` + `Fork (dup)`: escape-hatch that when a computation is needed that cannot be expressed using any of LINQ's built-in operators.mo
    * no info about `f` -> serialized computation onto a single computer
    * user annotations of `f` that it can be paralleled
    * conditional homomorphism
  * Annotations
    * manual hints to guide optimizations (preserving semantics)
    * `Resource`: discriminate functions that require constant storage from those whose storage grows along with the input collections size
      * detect buffering strategies, pipelining



## System Implementation

* LINQ expression → Execution Plan Graph (EPG) DAG
* term rewriting optimizations on the EPG
* optimizer annotations on EPG
  * nodes: details of the partitioning scheme, ordering information within each partition
  * propagating metadata properties is hard (rich data model & expression language) → infer properties (static typing, static analysis, reflection)
* optimizations
  * static optimizations
    * **Pipelining**: multiple operators inside a single process
    * **Removing redundancy**: DryadLINQ removes unnecessary hash/range partition steps
    * **Eager Aggregation**: re-partitioning datasets is expensive → down-stream aggregation moved in front of partitioning operators
    * **I/O Reduction**: Dryad's TCP pipe & in-memory FIFO instead of persisting temporary data to files
  * dynamic optimizations
    * hooks in the Dryad API
    * locality aggregation
    * topology at runtime
  * `OrderBy`
    * ![1571259688434](D:\OneDrive\Pictures\Typora\1571259688434.png)
    * deterministic sampling → histogram → re-partitioning → merge → sort
  * MapReduce
    * ![1571260050592](D:\OneDrive\Pictures\Typora\1571260050592.png)
    * `SelectMany → GroupBy → Reduction`
    * statically transformed into
    * `SelectMany → sort → GroupBy → Reduction → hash-partition → merge-sort → GroupBy → Reduction → X`
    * dynamic aggregation (partial aggregation [[C: distributed aggregation]])
* code generation
  * code for the LINQ subexpression executed by each node
  * serialization code for the channel data
  * context dependency
    * reference variables in the local context → partial evaluation at code-generation time / primitive values replacement + Object values serialized at runtime
    * reference .NET libraries → .NET reflection finds the transitive closure of all non-system libraries referenced by the executable, shipped to cluster computers at runtime
* Other LINQ providers
  * PLINQ: multi-core
  * LINQ-to-SQL system
  * LINQ-to-Object implementation
* Debugging
  * strong typing & narrow inference
  * straightforward way to run in a single computer
  * deterministic-replay execution model
  * centralized job manager → performance debugging monitoring progress  



## Motivation

* Microsoft wants to provide a high level abstraction over Dryad which provides illusion of writing for a single computer in high level .NET programming language. Parallel databases, raw MapReduce system, DSLs on top of MR abstraction all fail to satisfying the all requirements of having a strong type system, combining procedural and declarative programming and embedding into high level programming languages.

## Summary

* In this paper, the authors present DryadLINQ, which is an LINQ abstraction over Dryad graph execution engine. DryadLINQ includes the .NET expressions and type system supports, optimizer for optimization and code/execution plan generation.

## Strength

* LINQ expressions are strongly integrated into .NET language and can extend to other backends besides DryadLINQ.
* DryadLINQ can be extended by reflection and user defined annotations (E.g. distributed aggregation paper)

## Limitation & Solution

* User can't define optimization rules, namely, the optimizer is not extensible unless hacking into the code.
  * Having user-defined rewriting rules like Spark SQL
* The `Apply` operators extend the generality by introducing .NET functions but hurts purity and optimization
  * Do static analysis on function referenced
  * Disable `Apply`

