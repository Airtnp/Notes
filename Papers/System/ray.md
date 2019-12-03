# Ray: A Distributed Framework for Emerging AI Applications

**Philipp Moritz, Robert Nishihara, Michael I. Jordan, Ion Stoica et al.**

---



## Introduction

* Ray: unifying task-parallel & actor-based computations, by a single dynamic execution engine
* RL
  * simulation to evaluate policies
  * distributed training
* system for RL
  * fine-grained computations
  * lots of simulations
  * heterogeneity in time & resource usage
  * dynamic execution
* Task: efficiently, dynamically load balance, processing, recovert
* Actor: stateful computation
* Lineage-based fault tolerance fot tasks/actors
* Replication-based fault tolerance for metadata store
* ![image-20191106162624406](D:\OneDrive\Pictures\Typora\image-20191106162624406.png)



## Motivation & Requirements

* ![image-20191106162801213](D:\OneDrive\Pictures\Typora\image-20191106162801213.png)
* ![image-20191106162824120](D:\OneDrive\Pictures\Typora\image-20191106162824120.png)
* two-step process: policy evaluation & policy improvement
* ![image-20191106163149579](D:\OneDrive\Pictures\Typora\image-20191106163149579.png)
* ![image-20191106163209292](D:\OneDrive\Pictures\Typora\image-20191106163209292.png)
* ![image-20191106193157584](D:\OneDrive\Pictures\Typora\image-20191106193157584.png)
* millions of tasks per second
* seamless integration with existing simulators & DL frameworks



## Programming & Computation Model

* ![image-20191106200712039](D:\OneDrive\Pictures\Typora\image-20191106200712039.png)
* ![image-20191106201611883](D:\OneDrive\Pictures\Typora\image-20191106201611883.png)
* ![image-20191106201641768](D:\OneDrive\Pictures\Typora\image-20191106201641768.png)
* ![image-20191106201925359](D:\OneDrive\Pictures\Typora\image-20191106201925359.png)
* ![image-20191106202049984](D:\OneDrive\Pictures\Typora\image-20191106202049984.png)
* Computation Model
  * dynamic task graph computation model
  * ![image-20191106205718217](D:\OneDrive\Pictures\Typora\image-20191106205718217.png)
  * ![image-20191106205725967](D:\OneDrive\Pictures\Typora\image-20191106205725967.png)
  * data objects
  * remote function invocations / tasks
  * edges: data edges (data object-task dependency) / control edges (computation dependencies from nested functions) / stateful edges (sequential invocation on actors)
  * actor methods invocation (nodes)
  * ![image-20191106212934198](D:\OneDrive\Pictures\Typora\image-20191106212934198.png)

## Architecture

* ![image-20191106212955925](D:\OneDrive\Pictures\Typora\image-20191106212955925.png)
* ![image-20191106213003165](D:\OneDrive\Pictures\Typora\image-20191106213003165.png)
* ![image-20191106213010829](D:\OneDrive\Pictures\Typora\image-20191106213010829.png)
* [[N: Driver -> DL frameworks / simulators]]
* A global control store (GCS)
  * entire control state
  * k-v with pub-sub
  * sharding to achieve scale
  * per-shard chain replication to provide fault tolerance
  * decouple durable lineage storage from other system components
    * no single node storing all lineage
  * decouple task dispatch from task scheduling
    * store object metadata in GCS, not scheduler
  * enable every component in the system to be stateless
    * [[Q: why this doesn't affect scalability?]]
* A distributed scheduler (bottom-up distributed)
  * ![image-20191106214105918](D:\OneDrive\Pictures\Typora\image-20191106214105918.png)
  * 2-level hierarchical
  * ![image-20191106214201229](D:\OneDrive\Pictures\Typora\image-20191106214201229.png)
  * ![image-20191106214208501](D:\OneDrive\Pictures\Typora\image-20191106214208501.png)
  * ![image-20191106214218237](D:\OneDrive\Pictures\Typora\image-20191106214218237.png)
  * [[N: currently it's decentralized scheduler]]
* A distributed object store
  * in-memory storing I/O of every tasks / stateless computation
  * object store via shared memory
    * zero copy between tasks running on the same node
    * Apache Arrow
  * ![image-20191106214458085](D:\OneDrive\Pictures\Typora\image-20191106214458085.png)
  * ![image-20191106214530293](D:\OneDrive\Pictures\Typora\image-20191106214530293.png)
* Implementation
  * C++ (system layer), Python (application layer)
  * Redis k-v per pershard, single-key operations
  * GCS tables sharded by object & task IDs
  * chain-replicated for fault tolerance
* ![image-20191106215041518](D:\OneDrive\Pictures\Typora\image-20191106215041518.png)
* ![image-20191106215106124](D:\OneDrive\Pictures\Typora\image-20191106215106124.png)
* ![image-20191106215115885](D:\OneDrive\Pictures\Typora\image-20191106215115885.png)





## Discussion & Experiences

* ![image-20191106222417873](D:\OneDrive\Pictures\Typora\image-20191106222417873.png)
* ![image-20191106222425708](D:\OneDrive\Pictures\Typora\image-20191106222425708.png)
* ![image-20191106222431683](D:\OneDrive\Pictures\Typora\image-20191106222431683.png)
* ![image-20191106222441548](D:\OneDrive\Pictures\Typora\image-20191106222441548.png)















## Motivation

* The emerging AI applications are framed within the paradigm of reinforcement learning (RL), which targets to learn a policy (mapping from state of the environment to a choice of action). RL methods often rely on simulation to evaluate policies, and like supervised learning counterparts, need to perform distributed training. Therefore, a system for RL must support fine-grained computations, heterogeneity in time and resource usage and dynamic execution as simulations or interactions with environments. The existing frameworks fail to support fine-grained simulation, policy serving or distributed training. Some systems are tightly coupled to their components within applications.

## Summary

* In this paper, the authors present Ray, which is a general-purpose cluster computing framework enabling simulation, training and serving for RL applications. Ray unifies the computations between stateless task-parallel and stateful actor-based on top of a dynamic task execution engine. Ray supports fine-grained heterogeneous computations, dynamic execution graph, millions of tasks per second and seamless integration with existing simulators and deep learning frameworks. Ray tasks represent asynchronously remote function invocation on a stateless worker, and Ray actors represent stateful computation (the state is stored in GCS). Ray transforms the methods calling into dynamic task graph, by using nodes as data objects, remote function invocations and actor method invocations and using three types of edges: data edge (data object & task dependencies), control edge (nested function dependencies), and stateful edges (actor method invocation sequence). The application level of Ray consists of Driver (processing executing user programs), Worker (stateless process executing tasks) and Actor (stateful process only executing the exposed methods). The system layer of Ray consists of a global control store (GCS), a bottom-up distributed scheduler and a in-memory distributed object store. The GCS maintains the entire control state, sharded and chain replicated. GCS decouples the durable lineage storage from other components and decouples task dispatch from task scheduling to enable every component in the system to be stateless. The node will first do local scheduling then forward to global scheduler. The in-memory distributed object store uses Apache Arrow and keep inputs and outputs of every task. The inputs will be replicated to nodes if not in local shared memory.

## Strength

* The global control store design makes every component stateless by providing a global sharding of states managing fault tolerance lineage and task dispatching.
* Ray unifies the abstraction of task-parallel and actor-based computation, making it suitable for not only reinforcement learning jobs, but general computations.
* Ray's innovative graph representation makes the unifications naturally by using nodes as data objects and computations and edges as data dependencies, nested function dependencies and stateful happen-before dependencies.  

## Limitation & Solution

* The bottom-up scheduler makes it hard to make good scheduling decisions because local nodes are considered first.
  * Add runtime profiling
* The paper talks vaguely on actors. How actor states store? In GCS, object store or process-private? Will the actors migrate due to dynamic execution graph evolving?
* The GCS maintains all the control state, will it be the bottleneck on scalability?
  * How to garbage collect the lineages?
  * The global scheduler might be the limit, using decentralized scheduler like Sparrow.

