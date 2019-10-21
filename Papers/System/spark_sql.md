# Spark SQL: Relational Data Processing in Spark

**Michael Armburst, Reynold S. Xin, Cheng Lian, et al.**

------



## Introduction

* Spark SQL: new module to Spark, integrate relational processing with Spark functional programming API.
* tighter intergration between relational & procedural processing, through a declarative DataFrame API with procedural Spark code
* higher extensible optimizer Catalyst (Scala), with composable rules, control code generation, extension points
  * schema inference for JSON
  * machine learn types
  * query federation to external database
* Big data applications
  * a mix of processing techniques / data sources / storage fomrats
  * MapReduce - powerful, but low-level procedural programming interface
  * New systems - productive user experience by offering relational (declarative queries) interfaces to big data (Pig, Hive, Dremel, Shark) 
    * bad for performing ETL (extract, transform, load) to and from various data sources (semi-/un-structured) with custom code
    * bad for performnig advanced analytics (ML, graph processing), hard to express in relational systems
    * disjoint procedural & relational system
  * Shark: SQL-on-Spark, must pick between procedural & relational
* DataFrame API: perform relational operations on external data sourcess / Spark built-in distributed collections
  * like data frame concept in R
  * evaluate operations lazily → relational optimizations
  * collections of structured records (can be manipulated by Spark's procedural API)
  * created from Spark's built-in distributed collections of Java/Python objects
* Catalyst: extensible optimizer
  * support wide range of data sources & algorithms
  * add data sources (semi-structured JSON, HBase with filters pushed) / optimization rules / data types for domains (ML)
  * general framework for transforming trees



## Background & Goals

* Shark: modify the Apache Hive system to run on Spark and implemented traditional RDBMS optimiziations (E.g. columnar processing)

  * only be used to query external data stored in the Hive catalog, not useful for relational queries on data inside a Spark program (RDDs)
  * only way to call Shark from Spark is to put together a SQL string, inconvenient, error-prone
  * optimizer tailored for MapReduce, difficult to extend and build new features
  * HiveQL replacing MR to Spark, so a Spark interface
  * rely on Hive for SQL parser, logical plan translation, physical plan optimization, Metastore, SerDe

* Spark SQL goals

  * support relational processing both with Spark programs (on native RDDs) and on external data sources using a programmer-friendely API.
  * provide high performance using established DBMS techniques
  * easily support new data sources, including semi-structured data & external databases amemable to query federation
  * enable extension with advanced analytics algorithms such as graph processing & machine learning
  * rely on Hive for parser, Metastore, SerDe. The new thing is Catalyst, RDD support, Scala DSL

  > https://www.zhihu.com/question/23182567
  >
  > 
  >
  > Shark为了实现Hive兼容，在HQL方面重用了Hive中HQL的解析、逻辑执行计划翻译、执行计划优化等逻辑，可以近似认为仅将物理执行计划从MR作业替换成了Spark作业（辅以内存列式存储等各种和Hive关系不大的优化）；同时还依赖Hive Metastore和Hive SerDe（用于兼容现有的各种Hive存储格式）。这一策略导致了两个问题，第一是执行计划优化完全依赖于Hive，不方便添加新的优化策略；二是因为MR是进程级并行，写代码的时候不是很注意线程安全问题，导致Shark不得不使用另外一套独立维护的打了补丁的Hive源码分支（至于为何相关修改没有合并到Hive主线，我也不太清楚）。
  >
  > Spark SQL解决了这两个问题。第一，Spark SQL在Hive兼容层面仅依赖HQL parser、Hive Metastore和Hive SerDe。也就是说，从HQL被解析成抽象语法树（AST）起，就全部由Spark SQL接管了。执行计划生成和优化都由Catalyst负责。借助Scala的模式匹配等函数式语言特性，利用Catalyst开发执行计划优化策略比Hive要简洁得多。去年Spark summit上Catalyst的作者Michael Armbrust对Catalyst做了一个简要介绍：[2013 | Spark Summit](https://link.zhihu.com/?target=http%3A//spark-summit.org/summit-2013/)（知乎竟然不能自定义链接的文字？）。第二，相对于Shark，由于进一步削减了对Hive的依赖，Spark SQL不再需要自行维护打了patch的Hive分支。Shark后续将全面采用Spark SQL作为引擎，不仅仅是查询优化方面。
  >
  > 此外，除了兼容HQL、加速现有Hive数据的查询分析以外，Spark SQL还支持直接对原生RDD对象进行关系查询。同时，除了HQL以外，Spark SQL还内建了一个精简的SQL parser，以及一套Scala DSL。也就是说，如果只是使用Spark SQL内建的SQL方言或Scala DSL对原生RDD对象进行关系查询，用户在开发Spark应用时完全不需要依赖Hive的任何东西。



## Programming Interface

* ![1570835286124](D:\OneDrive\Pictures\Typora\1570835286124.png)
* as a library on top of Spark



### DataFrame API

* equivalent to a table in a relational database

* also viewed as an RDD of Row objects

* mainpulated in similar ways to the native distributed collections in Spark (RDDs)

  * relational operators: `where`, `groupBy` in DSL
  * procedural Spark APIs: `map`

* constructed from

  * tables in a system catalog (based on external data sources)
  * existing RDDs of native Java/Python objects

* ```scala
  ctx = new HiveContext()
  users = ctx.table("users")
  young = users.where(users("age") < 21)
  println(young.count())
  ```

* represent a logical plan, then build a physical plan by Spark SQL



### Data Model

* nested data model based on Hive for tables & DataFrames
* major SQL data types: boolean, integer, double, decimal, string, date, timestamp, complex types (struct, array, map, union)
* first-class support for complex data types
* user-defined types



### DataFrame Operations

* DSL relational operations

  * projection, filter, join, aggregations
  * take expression objects in a limited DSL that Spark capturing the structure of the expression
  * build up AST of the expression → Catalyst

* ```scala
  employees // DataFrame
      .join(dept , employees("deptId") === dept("id")) // expression objects
      .where(employees("gender") === "female")
      .groupBy(dept("id"), dept("name"))
      .agg(count("name"))
  ```

* registered as temporary tables

* ```scala
  users.where(users("age") < 21)
  	.registerTempTable("young")
  ctx.sql("SELECT count(*), avg(age) FROM young")
  ```



### DataFrames vs. Relational Query Languages

* breakup code into functions, benefit from optimization across the whole plan
* analyze logical plan eagerly (identify whether column name exists, data type correct) but results lazily



### Querying Native Datasets

* ```scala
  case class User(name: String , age: Int)
  // Create an RDD of User objects
  usersRDD = spark.parallelize(
  	List(User("Alice", 22), User("Bob", 19)))
  // View the RDD as a DataFrame
  usersDF = usersRDD.toDF
  
  // query native datasets
  views = ctx.table("pageviews")
  usersDF.join(views , usersDF("name") === views("user"))
  ```

* Spark SQL creates a logical data scan operator that points to the RDD → physical operator accessing fields of the native objects

* different from object-relational mapping (ORM)

  * incur expensive conversions
  * translate an entire object into a different format



### In-Memory Caching

* materialize hot data in memory using columnar storage
* Spark stores data as JVM objects
* columnar cache reduce memory footprint because of columnar compression schemes (dictionary encoding / run-length encoding)
* `cache()`



### User-Defined Functions

* inline definition of UDFs without complicated package & registeration process in other database systems

* ```scala
  val model: LogisticRegressionModel = ...
  ctx.udf.register("predict",
  	(x: Float , y: Float) => model.predict(Vector(x, y))) // operate on scalar values, can also defined on tables
  ctx.sql("SELECT predict(age, weight) FROM users")
  ```

* can also be used via JDBC/ODBC interfaces by BI tools



## Catalyst Optimizer

* Make it easy to add new optimization techniques and features to Spark SQL
* Enable external developers to extend the optimizer
  * rule-based + cost-based optimizations
  * in past DSL + optimizer complier → Scala with FP
* [[I: Spark SQL API on Rust?????]]
* library for representing trees & applying rules
* library specific to relational query processing
* several sets of rules that handle different phases of query executions: analysis, logical optimizations, physical planning, code generations
* public extension points: external data sources & user-defined types



### Trees

* ![1570856209919](D:\OneDrive\Pictures\Typora\1570856209919.png)
* tree: composed of node objects
* node: node type with 0 or more children `<: TreeNode`
* `Literal(value: Int)`
* `Attribute(name: String)`
* `Add(left: TreeNode, right: TreeNode)`



### Rules

* manipulate trees

* pattern matching: tree `transform` method

* ```scala
  tree.transform {
      case Add(Literal(c1), Literal(c2)) => Literal(c1+c2)
      case Add(left , Literal(0)) => left
      case Add(Literal(0), right) => right
  }
  ```

* partial function

* multiple runs: `batches` (or just passes)

  * execute until reaching fixed point [[Q: what? what if 2 rules conflict each other]]

* arbitrary Scala code (better than DSL)



### Using Catalyst in Spark SQL

* ![1570856423727](D:\OneDrive\Pictures\Typora\1570856423727.png)

* analyzing a logical plan to resolve references

  * relation: AST from SQL parser or DataFrame object
  * unresolved attributes (unknown type / match in input table)
  * solving references
    * Looking up relations by name from the catalog
    * Mapping named attributes
    * Determining which attributes refer to the same value to give them a unique ID
    * Propagating and coercing types through expressions

* logical plan optimization

  * rule-based optimizing

    * constant folding
    * predicate pushdown
    * projection pruning
    * null propagation
    * Boolean expression simplification [[I: Introduce SMT solver here]]
    * other rules

  * E.g. optimize newly added `DECIMAL` type

    * ```scala
      object DecimalAggregates extends Rule[LogicalPlan] {
          /** Maximum number of decimal digits in a Long */
          val MAX_LONG_DIGITS = 18
          def apply(plan: LogicalPlan): LogicalPlan = {
              plan transformAllExpressions {
                  case Sum(e @ DecimalType.Expression(prec , scale))
           	       if prec + 10 <= MAX_LONG_DIGITS =>
               		   MakeDecimal(Sum(LongValue(e)), prec + 10, scale)
          }
      }
      ```

* physical planning

  * logical plan → generating 1+ physical plans by physical operators matching Spark execution engine.
  * cost-based optimization (only used to select-join)
    * small relations: broadcast join, peer-to-peer broadcast facility
  * rule-based optimizating
    * pipeling projections
    * filters into one Spark `map` operations
  * push operations from the logical plan into data sources that support predicate or projection pushdown

* code generation to compile parts of the query to Java bytecode

  * CPU-bound since in-memory dataset operating

  * quasiquote feature, `q"xxx" : universal.Tree` (which converts words xxx to AST)

  * ```scala
    def compile(node: Node): AST = node match {
        case Literal(value) => q"$value"
        case Attribute(name) => q"row.get($name)"
        case Add(left , right) =>
    	    q"${compile(left)} + ${compile(right)}"
    }
    ```

  * compile-time type checking

  * highly composable

  * further optimized by the Scala compiler (expression-level optimization)

* extension points

  * data sources

    * `createRelation : Set[K, V] → BaseRelation`

    * `BaseRelation`: schema & optional estimated size in bytes

      * `TableScan`: requires the relation to return an RDD of `Row` objects for all of the data in the Table
      * `PruendScan`: an array of column names to read → Rows containing only those columns
      * `PrunedFilteredScan`: desired column names and array of `Filter` objects (allowing predicate pushdown) → allow false positive rows

    * `CatalystScan`: complete Sequence of Catalyst expression trees used in predicate pushdown → advisory

    * CSV files / Avro / Parquet / JDBC

    * ```scala
      CREATE TEMPORARY TABLE messages
      USING com.databricks.spark.avro
      OPTIONS (path "messages.avro") // source to file with k-v options for configurations
      ```

    * expose network locality through RDD objects they return

    * also for writing data to an existing or new table

  * user-defined types (UDT)

    * mapping UDT to structure composed of Catalyst built-in types

    * ```scala
      class PointUDT extends UserDefinedType[Point] {
          def dataType = StructType(Seq( // Our native structure
              StructField("x", DoubleType),
              StructField("y", DoubleType)
          ))
          def serialize(p: Point) = Row(p.x, p.y) // mapping from UDT to built-in type
          def deserialize(r: Row) = // inverse mapping
      	    Point(r.getDouble(0), r.getDouble(1))
          }
      ```

    * with UDFs



## Advanced Analytics Features

* Schema inference for semi-structured data

  * JSON type inference
    * ![1570857570959](D:\OneDrive\Pictures\Typora\1570857570959.png)
    * prior work on schema inference for XML & object databases
  * tree of `STRUCT` types infer (atoms, arrays, or other `STRUCT`s)
    * find most specific Spark SQL data type matching observed instances of the field
      * array → most specific supertype logic
    * single `reduce` operation over the data
      * start with schemata for each individual record
      * merge them using an associative "most specific supertype" function
      * single-pass & communication efficent
      * [[C: TAPL's join (least common supertype)]]
  * RDD schemas infer

* Integration with Spark's ML library (high-level API)

  * MLlib
  * machine learning pipelines
    * pipeline: a graph of transformation on data, such as feature extraction, normalization, dimensionality reduction, model tranning.
  * ![1570858089895](D:\OneDrive\Pictures\Typora\1570858089895.png)
  * UDTs for vectors (sparse / dense)
    * boolean for sparse/dense
    * size
    * array of indices (for sparse)
    * array of double values
  * expose MLlib's new API in all Spark's supported programming languages
  * expose algorithms in SQL

* Query federation to external Databases (query disparate sources)

  * heterogeneous sources [[C: MapReduce Merge]]

  * ```scala
    CREATE TEMPORARY TABLE users USING jdbc
    OPTIONS(driver "mysql" url "jdbc:mysql://userDB/users")
    
    CREATE TEMPORARY TABLE logs
    USING json OPTIONS (path "logs.json")
    
    SELECT users.id, users.name , logs.message
    FROM users JOIN logs WHERE users.id = logs.userId
    AND users.registrationDate > "2015-01-01"
    ```

  * leverage Catalyst to push predicates down into data sources whenever possible



## Research Applications

* Generalized Online Aggregation
  * arbitrarily nested aggregate queries [[C: MapReduce Online]]
  * view progress of executing queries by seeing results computed over a fraction of the total data (with accuracy measures)
  * new operator to represent a relation broken into sampled batches
  * `transform` used to replace full query to several queries
  * modify operator tree until it produces correct online answers
* Computational Genomics





















## Motivation

* Big data applications require a mixture of processing techniques, data sources and storage formats. MapReduce/Hadoop systems only provide a low-level procedural mechanisms. Previous systems like Shark, Hive introduce relational interface and declarative programming but fail to join the relational and procedural models.

## Summary

* In this paper, the authors present Spark SQL, which is a framework built on top of Spark providing relational processing with declarative DataFrame API and extensible optimizer Catalyst. DataFrame can viewed as relational tables or Spark native RDDs and can support relational operators and procedural RDD operators. DataFrames can be constructed from external data sources (by system catalog) or RDD objects.
* Catalyst resolves the unresolved reference in SQL ASTs or DataFrame operations, optimizing the logical plan with extensible transformations on logical trees, generating physical plans and doing code generations. It can be extended with data sources with extra interfaces or user-defined types with serialization/deserialization functions.

## Strength

* Spark SQL, unlike Shark, reduces its dependency on HiveQL so that it can replace the compatitble APIs due to old Hadoop (MapReduce like framework) to developing new interfaces incorporating new underlying system Spark with RDDs.
* The new compiler backend Catalyst is simple but powerful with its extensibility and well-designed abstractions.
* Spark SQL utilizes Spark with functional programmig to build extensible compiler with more concise syntaxes and procedures.

## Limitation & Solution

* It's hard to do online aggregation within Spark SQL since it's designed for offline queries.
* The tree transformation is computed until a fixed point, which I assume there might be infinte loops or performance downgradation due to problematic rules.
  * Like LLVM, introduce multiple passes (batches) instead of computing fixed points.

