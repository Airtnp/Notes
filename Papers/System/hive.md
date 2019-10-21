# Hive - A Warehousing Solution Over a Map-Reduce Framework 

**Ashish Thusoo, Joydeep Sen Sarma, et al.**

------



## Introduction

* MapReduce programming is very low-level, requires developers to write custom programs which are hard to maintain and reuse
* Hive, open-source data warehousing solution built on top of Hadoop
* HiveQL: SQL-like declarative language with custom map-reduce scripts plugins
  * type system with support for tables containing primitive types, collections (arrays, maps), nested compositions of same
* Hive-Metastore: system catalog, containing schemas & statistics



## Hive Database



### Data Model

* Tables: analogous to tables in relational databases. Each table has a corresponding HDFS directory (serialized and stored in files)
  * Hive builtin serialization format: exploit compression & lazy de-serialization
  * user-defined serialize/de-serialize methods (`SerDe`)
  * serialization format stored in system catelog, automatically used by Hive during query compilation & execution
  * support external tables on HDFS/NFS/local directories
* Partitions: each table can have 1 or more partitions determining distribution of data within sub-directories of the table directory.
* Buckets: data in each partition may in turn divided into buckets based on hash of a column in the table. Each bucket is stored as a file in the partition directory.



### Query Language

* HiveQL: select, project, join, aggregate, union all, sub-queries in the from clause.
* data definition (DDL) statements: create tables with specific serialization formats, partitioning and bucketing columns.
* data manipulation (DML) `load`, `insert`: load data from external sources / insert query results into Hive tables
* not support: updating / deleting rows in existing tables
* multi-table insert: perform multiple queries on the same input data using a single HiveQL statement (sharing the scan of input data)
* user-defined column transformation (UDF) & aggregation (UDAF)
* embed custom map-reduce scripts written in any language using a simple row-based streaming interface



### Example

* ```sql
  -- update from NFS file
  -- status_update(userid int, status string, ds string)
  LOAD DATA LOCAL INPATH ‘/logs/status_updates’
  INTO TABLE status_updates PARTITION (ds=’2009-03-20’)
  
  -- daliy update on summary
  -- profiles(userid int, school string, gender int)
  -- school_summary(school string, cnt int, ds string)
  -- gender_summary(gener int, cnt int, ds string)
  FROM (SELECT a.status, b.school, b.gender
  	FROM status_updates a JOIN profiles b
  		ON (a.userid = b.userid and
      		a.ds=’2009-03-20’ )
      ) subq1
  INSERT OVERWRITE TABLE gender_summary
  					PARTITION(ds=’2009-03-20’)
  SELECT subq1.gender, COUNT(1) GROUP BY subq1.gender
  INSERT OVERWRITE TABLE school_summary
  					PARTITION(ds=’2009-03-20’)
  SELECT subq1.school, COUNT(1) GROUP BY subq1.school
  
  -- ten most popular memes per school
  REDUCE subq2.school, subq2.meme, subq2.cnt
  	USING ‘top10.py’ AS (school,meme,cnt)
  FROM (SELECT subq1.school, subq1.meme, COUNT(1) AS cnt
  	FROM (MAP b.school, a.status
  		USING ‘meme-extractor.py’ AS (school,meme)
        		FROM status_updates a JOIN profiles b
  				ON (a.userid = b.userid)
          	) subq1
  	GROUP BY subq1.school, subq1.meme
  	DISTRIBUTE BY school, meme
  	SORT BY school, meme, cnt desc
  ) subq2;
  ```





## Hive Architecture

* ![1570777357875](D:\OneDrive\Pictures\Typora\1570777357875.png)

* External Interface: user interface (CLI/web UI), application programming interface (like JDBC/ODBC)
* Hive Thrift Server: expose a very simple client API to execute HiveQL statements
  * Thrift: cross-language service framework where a server written in one language can also clients in other languages
* Metastore: system catalog
* Driver: manage the lifecycle of a HiveQL statements during compilation, optimization, execution.
  * Thrift/interface → HiveQL statement → session handle for statistics (exec time, # of output rows)
* Compiler: invoked by the driver upon receiving HiveQL statements. Compiler tanslate statement into a plan which consists of a DAG of map-reduce jobs
* Execution Enginer: driver submits individual map-reduce jobs from the DAG to the Execution Engine in a topological order.



### Metastore

* system catalog, metadata about tables
* metadata: specified during table creation, reused every time the table is referenced in HiveQL
* Database: namespace for tables
* Table: Metadata for table contains list of columns and their types, owners, storage , `SerDe` information. Also contain user-supplied key-value data
  * storage info: location of table data in FS, data formats, bucket information
  * `SerDe`: implementation class of serializer/deserializer methods, supporting information
* Partition: each partition can have its own columns & `SerDe` & storage information
* storage system should be optimized for online transactions with random access & updates
  * either traditional relational database
  * or file system not HDFS
  * low latency accessing metadata objects
  * need explicitly matain consistency between metadata & data [[Q: so metadata is separated from actual datas and not scale?]]



### Compiler

* input: HiveQL string (DDL/DML/query statements)
* output: execution plan
* DDL: only metadata operations
* `LOAD`: only HDFS operations
* Parser: query string → parse tree representation
* Semantic Analyzer: parse tree → block-based internal query representation
  * retrieve scheme info of the input table from metastore
  * verify column names
  * expand `select *`
  * type-checking (with implicit type conversions)
* Logical Plan Generator: internal query representation → logical plan (tree of logical operators)
* Optimizer: multiple passes over logical plan
  * [[C: CMU 15-445 DB]]
  * Combine multiple joins which share the join key into a single multi-way join → single map-reduce job
  * Add repartition operators (ReduceSinkOperator) for join, group-by, custom map-reduce operators
    * mark boundary between map phase & reduce phase
  * Prune columns early & push predicates closer to the table scan operators to minimize data transfer
  * Partitioned table? prune partitions not needed by the query
  * Sampling query? prune buckets not needed by the query
  * User hints
    * partial aggregation operators for large cardinality grouped aggregations
    * repartition operators to handle skew in grouped aggregation
    * perform joins in the map phase instead of reduce phase
* Physical Plan Generator: logical plan → physical plan (DAG of map-reduce jobs)
  * 1 map-reduce job for each marker operators (repartition / union-all)
  * assign portions of logical plan enclosed between marker to mappers & reducers
* ![1570776576180](D:\OneDrive\Pictures\Typora\1570776576180.png)



## Future Work

* only a subset of SQL → subsume SQL syntax
* naive rule-based optimizer with small number of simple rules → cost-based optimizer & adaptive optimization techniques
* columnar storage & intelligent data placement for scan performance
* performance benchmarks
* enhance JDBC/ODBC drivers for Hive for integration with commerical BI tools
* exploreing methods for multi-query optimization techniques & performing generic n-way joins in a single map-reduce job











## Motivation

* Hadoop is a popular open-source MapReduce implementation widely used for data intensive applications. However, MapReduce programming model is very low-level and requires developers to write programs which are hard to reuse and simplified.

## Summary

* Hive is an open-source wareouse solution built on top of Hadoop to provide enough abstraction for processing data intensive applications in commerical BI ways.

* The data model of Hive is split into layers of Tables, Partitions and Buckets. Tables are similar to normal relational tables with extra serialization formats so it can be stored in distributed file systems. Partitions are tables split by key ranges and buckets are partitions split by hash values.
* The language used by Hive is HiveQL, which supports a subset of SQL and extra operations like DDL and DML statements. HiveQL can also supports user-defined column transformation and aggregation written in given interface.
* The architecture of HiveQL consists of interfaces, thrift servers, metastore for table metadata, driver for statements lifttimes, compiler for generating and optimizing logical plans and execution enginer for generating physical plans represented by DAGs.

## Strength

* HiveQL is similar to standard SQL database query language and it can also incorporate with Hadoop or other distributed file system settings and user-defined scripts.

## Limitation & Solution

* The paper lacks benchmarking about how much does the abstraction hide performance? Or how well is the optimizer working?
  * Present benchmarking on standard testing SQL sets (might with modifications to handle unsupported SQL statements)
* The megastore is separated in non-HDFS like distributed file system and the consistency needs to be handled manually by Hive.
  * Hold a metastore cluster for accessing in-memory metadata for tables like Spanner (spanserver leader) / Azure (Partition Layer)?

