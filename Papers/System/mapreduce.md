# [MapReduce: Simplified Data Processing on Large Clusters](https://static.googleusercontent.com/media/research.google.com/en//archive/mapreduce-osdi04.pdf)

###### Jeffrey Dean, Sanjay Ghemawat

------

### What is the Problem? [Good papers generally solve *a single* problem]

- For special-purpose computations, the input data is large and the computations have to be distributed across hundreds of thousands of machines and here comes the problem about how to parallelize the computation, distribute the data and handling failures.

### Summary [Up to 3 sentences]

- The paper presents a new programming model and an associated implementation for processing and generating large data sets called MapReduce. MapReduce provides a interface that enables automatic parallelization and distribution of large-scale computations, combined with an implementation of this interface that achieves high performance on large cluster of commodity PCs.

### Key Insights [Up to 2 insights]

- Most of the computations involves applying a map operation to each logical record in our input in order to compute a set of intermediate key/value pairs, and then applying a reduce operation to all the values that shared the same key, in order to combine the derived data appropriately.
- When the user-supplied map and reduce operators are deterministic functions of their input values, the distributed implementation produces same output as would have been produced by a non-faulting sequential execution of the entire program.
- Restricting the programming model makes it easy to parallelize and distribute computations and to make such computations fault-tolerant. Network bandwidth is a scarce resource. Redundant execution can be used to reduce the impact of slow machines, and to handle machine failures and data loss.

### Notable Design Details/Strengths [Up to 2 details/strengths]

- MapReduce takes advantage of the fact that the input data on GFS is stored on the local disks of the machines that make up the computational cluster. Thus it attempts to schedule a map task on a machine that contains a replica of near a replica of the input data.
- When a MapReduce operation is close to completion, the master schedules backup executions of the remaining in-progress tasks.

### Limitations/Weaknesses [up to 2 weaknesses]

- For large scale worker failures, MapReduce needs to re-execute all the work done by the unreachable worker machines.
- MapReduce needs to transmit and receive large number of files and the network bandwidth might be the limit point.
- The application writer needs to make side-effect of map and reduce operations atomic and idempotent.

### Summary of Key Results [Up to 3 results]

- MapReduce is able to reach high performance with effective backup tasks and dealing with machine failures.
- MapReduce is able to replace the production indexing system used for Google web search service with simple code, little complexity for dealing with parallelization, tolerance, distribution, high performance and high scalability.

### Open Questions [Where to go from here?]

- What's the common schema for a task that can be done by map and reduce operations? (Like the universal and expressiveness of fold)
- Do we have better options for faulting tolerance, parallelization, distribution on the choice of writing and renaming files?