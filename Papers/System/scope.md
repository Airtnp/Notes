# SCOPE: Easy and Efficient Parallel Processing of Massive Data Sets 
**Ronnie Chaiken, Bob Jenkins, et al.**

------



## Introduction

* increasing need to store & analyze massive data sets
* processing done on large clusters of shared-nothing commodity machines
* developing a programming model
  * hide complexity of underlying system
  * flexibility by allowing users to extend functionality to meet a variety of requirements
* SCOPE: a new declarative & extensible scripting language
  * Structured Computation Optimized for Parallel Execution
  * no explicit parallelism
  * SQL features (row data model, select statements, aggregation)
  * operators
    * extractor (parsing & constructing rows from a file)
    * processors (row-wise processing)
    * reducers (group-wise processing)
    * combiner (combining rows from 2 inputs)
* Map-Reduce: group-by-aggregaton operations over a cluster of machines
  * users must map their applications to map-reduce model in order
  * map/reduce implementations are inevitable
    * equivalent to specifying physical execution plan
  * error-prone, hardly reusable
  * multiple stages of map-reduce
* SCOPE
  * declarative langauge
  * data transformation
  * extensible
  * functionality similar to views in SQL
  * traditional nested SQL expressions



## Platform Overview

* ![1570991376021](D:\OneDrive\Pictures\Typora\1570991376021.png)
* Cosmos platform
  * Availability
    * resilient to multiple hardware failures
    * file data replicated many times
    * file metadata is managed by a quorum group of $2f+1$ servers to tolerance $f$ failures
  * Reliability
    * recognize transient hardware conditions
    * checksummed end-to-end, crash faulty components
    * on-disk data periodically scrubbed to detect corrupt or bit rot data
  * Scalability
    * capable of storing / processing petabytes of data
  * Performance
    * job is broken down into small units of computation and distributed across a large number of CPUs and storage devices, reducing job completing times
  * Cost
    * cheap to build, operator, expand per gigabytes
* Cosmos storage: A distribtued storage subsystem designed to reliably & efficiently store extremely large sequential files
  * append-only, optimized for large sequential I/O
  * concurrent writers serialized
  * data distributed & replicated for fault-tolerance & compressed
  * directory with hierarchical namespace
  * sequential files of unlimited size
    * physically composed of a sequence of extents (unit of space allocation)
    * extents are eplicated for reliability, regularly scrubbed to protect
  * an extent consists of a sequence of appended blocks
    * block boundaries defined by application appends
    * collection of application-defined records
    * compressed form with compression & decompression done transparently.
* Cosmos execution environment: env for deploying, executing, debugging distributed plans
  * Cosmos execution protocol: upload application code & resources onto system
  * recipient server: assign task priority & execute t at appropriate time
  * application modeled as a dataflow graph (DAG)
    * vertex (processed), edges (data flows)
  * Job Manager (JM): runtime component, central & coordinating process for all processing vertices within an application
    * construct the runtime DAG from compile time representation of a DAG
    * execute DAG
    * schedule a DAG vertex on the system processing when all the input are ready
    * monitor progress
    * on failure, re-execute part of the DAG
  * [[R: Dryad]]
* SCOPE: high-levle scripting language for writing data analysis jobs
  * SCOPE compiler & optimizer translate scripts to parallel execution plans



## SCOPE Scripting Language

* resemble SQL but with C# expressions

  * reduce learning curve
  * ease porting of exsiting SQL into SCOPE

* a sequence of commands (data transformation operators)

* ```sql
  e = EXTRACT query
  	FROM “search.log"
  	USING LogExtractor;
  
  s1 = SELECT query, COUNT(*) as count
  	FROM e
  	GROUP BY query;
  
  s2 = SELECT query, count
  	FROM s1
  	WHERE count > 1000;
  
  s3 = SELECT query, count
  	FROM s2
  	ORDER BY count DESC;
  
  OUTPUT s3 TO “qcount.result";
  ```

* data types: int/long/double/float/DateTime/string/bool/nullable counterparts (C# null)

* input/output

  * input: built-in/user-written extractors

  * ```sql
    EXTRACT column[:<type>] [, …]
    FROM < input_stream(s) >
    USING <Extractor> [(args)]
    [HAVING <predicate>]
    ```

  * user-defined C# `Extractor`

    * ![1571003979511](D:\OneDrive\Pictures\Typora\1571003979511.png)

  * custom schema information by `Produce`

  * output

    * ```sql
      OUTPUT [<input>
      	[PRESORT column [ASC | DESC] [, …]]]
      TO <output_stream>
      [USING <Outputter> [(args)]]
      ```

  * user-defined C# `Outputter`

* select & join

  * ```sql
    SELECT [DISTINCT] [TOP count]
    	select_expression [AS <name>] [, …]
    FROM { <input stream(s)> USING <Extractor> |
    	{<input> [<joined input> […]]} [, …]
    }
    [WHERE <predicate>]
    [GROUP BY <grouping_columns> [, …] ]
    [HAVING <predicate>]
    [ORDER BY <select_list_item> [ASC | DESC] [, …]]
    
    joined input:
    	<join_type> JOIN <input> [ON <equijoin>]
    
    join_type:
    	[INNER | {LEFT | RIGHT | FULL} OUTER]
    ```

  * `COUNT`, `COUNTIF`, `MIN`, `MAX`, `SUM`, `AVG`, `STDEV`, `VAR`, `FIRST`, `LAST`

  * disallowing subquery → using outer join by subquerys

    * ```sql
      SELECT Ra, Rb
      FROM R
      WHERE Rb < 100
      	AND (Ra > 5 OR EXISTS(SELECT * FROM S
      						WHERE Sa < 20
      						AND Sc = Rc))
      						
      SQ = SELECT DISTINCT Sc FROM S WHERE Sa < 20;
      M1 = SELECT Ra, Rb, Rc FROM R WHERE Rb < 100;
      M2 = SELECT Ra, Rb, Rc, Sc
      	FROM M1 LEFT OUTER JOIN SQ ON Rc == Sc;
      Q = SELECT Ra, Rb FROM M2
      	WHERE Ra > 5 OR Rc != Sc;
      ```

* Expression & Functions

  * ```sql
    R1 = SELECT A+C AS ac, B.Trim() AS B1
        FROM R
        WHERE StringOccurs(C, “xyz”) > 2
    #CS
    public static
    int StringOccurs(string str, string ptrn)
    {
        int cnt=0; int pos=-1;
        while (pos+1 < str.Length) {
            pos = str.IndexOf(ptrn, pos+1) ;
            if (pos < 0) break;
            cnt++;
        }
        return cnt;
    }
    #ENDCS
    ```

* User-defined operators

  * `PROCESS`, `REDUCE`, `COMBINE` (map-reduce-merge)

  * ![1571005722757](D:\OneDrive\Pictures\Typora\1571005722757.png)

  * ![1571005566390](D:\OneDrive\Pictures\Typora\1571005566390.png)

  * ```c#
    PROCESS [<input>]
    USING <Processor> [ (args) ]
    [PRODUCE column [, …]]
    [HAVING <predicate> ]
        
    REDUCE [<input> [PRESORT column [ASC|DESC] [, …]]]
    ON grouping_column [, …]
    USING <Reducer> [ (args) ]
    [PRODUCE column [, …]]
    [HAVING <predicate> ]
        
    COMBINE <input1> [AS <alias1>] [PRESORT …]
    	WITH <input2> [AS <alias2>] [PRESORT …]
    ON <equality_predicate>
    USING <Combiner> [ (args) ]
    PRODUCE column [, …]
    [HAVING <expression> ]
    ```

* Importing Scripts

  * ```sql
    IMPORT <script_file>
    [PARAMS <par_name> = <value> [,…]]
    
    -- MyView.script
    E = EXTRACT query
        FROM @@logfile@@
        USING LogExtractor ;
    EXPORT
    R = SELECT query, COUNT() AS count
        FROM E
        GROUP BY query
        HAVING count > @@mincount@@;
    
    -- invoke script
    Q1 = IMPORT “MyView.script”
            PARAMS logfile=”Queries_Jan.log”,
            limit=1000 ;
    Q2 = IMPORT “MyView.script”
            PARAMS logfile=”Queries_Feb.log”,
            limit=1000 ;
    JQ = SELECT Q1.query, Q2.count-Q1.count AS diff,
                Q1.count AS jan_cnt,
                Q2.count AS feb_count,
    	FROM Q1 LEFT OUTER JOIN Q2
    			ON Q1.query == Q2.query
    	ORDER BY diff DESC;
    ```



## SCOPE Execution

* Compilation

  * parse the script, check the syntax, resolve the names
  * translation into physical executation plan (traversing parse tree bottom-up)
  * combine adjacent vertices with physical operator that can be easily pipelined into (super) vertices
    * 1:1 / 1:n / n:1 / n:m
    * E.g. filter + sort in a pipelined fashion

* Optimization

  * transformation-based optimizer based on the Cascade framework
  * generate all possible rewriting of a query expression and choose the one with the lowest estimated cost
  * applying local transformation rules on query subexpressions
  * traditional database optimization rules
    * removing unnecessary columns,
    * pushing down selection predicates
    * pre-aggregating when possible
  * right partition scheme, when topartition?
  * partiton, grouping, sorting operators, interactions
  * [[Q: I think this should be Cosmos's work??]]

* ![1571006438811](D:\OneDrive\Pictures\Typora\1571006438811.png)

* ```sql
  SELECT query, COUNT() AS count
  FROM "search.log"
  	USING LogExtractor
  GROUP BY query
  HAVING count > 1000
  ORDER BY count DESC;
  OUTPUT TO "qcount.result";
  ```

* ![1571006462675](D:\OneDrive\Pictures\Typora\1571006462675.png)

* ![1571006468156](D:\OneDrive\Pictures\Typora\1571006468156.png)

* runtime optimization

  * hierarchicallty structured network for clusters
    * rack switch, per rack switch to single common switch
    * locality



Schema-aware computation

* K-V/RDD/`PCollection<T>` (MapReduce, Hadoop, Spark, FlumeJava) -> Relation (SCOPE, Hive, DryadLINQ, SparkSQL)









## Motivation

- Companies providing cloud-scale services need large-scale store and analysis over datasets on clusters. MapReduce programming model provides a good abstraction of group-by-aggregation operations over a cluster of machines, but it is limited by the must-user-provided map/reduce functions, which are error-prone and equivalent to physical execution plans.

## Summary

- In this paper, the authors present a declarative scripting language SCOPE which serves as an abstraction of low-level primitives on Cosmos platform. Cosmos platform is a graph computation engine like Dryad working on DAGs. SCOPE includes SQL features, SQL translator and optimizer to transform user scripts to physical execution plans.

## Strength

- SCOPE syntaxes are similar to SQL with high extensibility using customized `Extractor`, `Outputter`, `Produce` (schema), `PROCESS` (map), `REDUCE`, `COMBINE` (merge) functions. Also SCOPE can incorporate with C# functions.

## Limitation & Solution

- SCOPE cannot fully utilize the C# procedural language features and give convenience for C# programmers.
  - Incorporate with DryadLINQ or other LINQ.
- Why SCOPE optimizers optimizes the data locality? It should be the work by the Cosmos platform. The abstraction are not transparent here.
  - Make SCOPE generating logical plan and Cosmos generating the physical plans.
- The contents about how the optimizer work is vague in this paper.

