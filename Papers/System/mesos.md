# Mesos: A Platform for Fine-Grained Resource Sharing in the Data Center

**Benjamin Hindman, Andy Konwinski, et al.**

------



## Introduction

* Mesos: platform for sharing commodity clusters between multiple diverse cluster computing frameworks
* Sharing improves cluster utilization & avoid per-framework data replication
* Mesos shares resources in a fine-grained manner
  * data locality → take turns reading data stored on each machine
* sophisticated scheduler → distributed two-level scheduling mechanism (resource offers)
* multiplexing a cluster between frameworks
* common solutions
  * statically partition, 1 framework per partition
  * allocate a set of VMs to each framework
  * neither high utilization, nor efficient data sharing
* mismatch between allocation granularities of solutions & of existing frameworks
  * framework: find-grained resource sharing model
    * node → slots, jobs → short tasks
* Mesos: thin resource sharing layer, fine-grained sharing across diverse cluster computng frameworks, by giving frameworks a common interface for accessing cluster resources
* Challenge
  * each framework will have different scheduling needs, basedon programming model / communication pattern / task dependencies / data placement
  * scheduling system must scale to clusters
  * system must be fault-tolerant & highly available
* Approach
  * takes input framework requirements, resource availability, organizational policies → compute a global schedule
    * can optimize scheduling across frameworks
    * high complexity → scalability/resilience?
    * new framework needs new scheduling policies → need extensible in future
    * framework having own sophisticated scheduling → moving this functionality would require expensive refactoring
  * delegating control over scheduling to the frameworks → Mesos way
    * _resource offer_: encapsulates a bundle of resources that a framework can allocate on a cluster node to run tasks
    * Mesos decides how many resource to offer each framework based on an organizational polciy (fair sharing, ...)
    * Framework decides which resources to accept & which tasks to run on them
* Practitioner benefits
  * even 1 framework can use Mesos to run multiple instances (may multiple versions)
  * easier to develop & immediately experience with new frameworks
    * free developers to build & run specialized frameworks targeted at particular problem domains rather than 1-size-fits-all abstraction
* ZooKeeper for fault tolerance
* Hadoop, MPI, Torque batch scheduler
* Spark





## Architecture

* Design philosophy: provide a scalable & resilient core for enabling various frameworks to efficiently share clusters

  * cluster framework: highly diverse & rapidly evolving
  * minimal interface that enabling efficient resource sharing across frameworks
    * push control of task scheduling & execution to the frameworks
      * allowing framework to implement diverse approaches to various problems in the cluster (locality, faults)
      * keep Mesos simple, minimize the rate of change required of the system (robust & scalable)

* ![1571437154900](D:\OneDrive\Pictures\Typora\1571437154900.png)

* ![1571437586836](D:\OneDrive\Pictures\Typora\1571437586836.png)

* components

  * a master process

    * fine-grained sharing across frameworks using _resource offer_
      * _resource offer_: list of free resources on multiple-slaves
      * [[Q: communication cost? scalability?]]
    * decide how many resources to offer to each framework according to an organizational policy
      * inter-framework allocation policies: organizations define own policies via a pluggable allocation module

  * slave daemons

    * report free resources to master

  * frameworks

    * scheduler: register with the master to be offered resources
      * select which of the offered resources to use → pass Mesos a description of the tasks it wants to launch on thems
      * can reject resources
        * may have to wait a long time before it receives an offer satisfying its constraints
        * Mesos may have to send an offer to many frameworks before 1 of them accepts
        * allow framework to set _filters_ (E.g. whitelist)
        * delay scheduling: framework waits for a limited time to acquire nodes storing their data, yielding nearly optimal data locality with a wait time (1-5s)
    * executor: launched on slave nodes to run the frameworks' tasks

  * resource allocation

    * delegate allocation decisions to a pluggable allocation module
      * fair sharing based on a generalization of max-min fairness for multiple resources (DRF)
      * strict priorities
    * most task short → reallocate resources when task finish
    * revocation
      * filled by long tasks → allocation module revoke (kill) tasks → Mesos gives its framework a grace period to cleanup
        * revoke policy: implementation-defined
        * kill MR is cheap, kill MPI tasks (interdependent) might be expensive
        * _guaranteed allocation_: allocation modules exposing to framework, a quantity of resources that the framework may hold without losing tasks.
        * framework → Mesos: interests for using more resources if they were offered them
    * supporting long tasks
      * frameworks mark short/long tasks, revoke if dishonest one
      * sharing nodes in space between long/short tasks
      * 4-core node could be MPI in 2 cores + MR tasks accessing local data
      * bound total resources on each node that can run long tasks
      * short tasks can use any resources
    * long tasks can only use up to the amount specified in the offer
  
* isolation
  
    * performance isolation between framework executors by leveraging OS isolation mechanisms
      * platform-dependent
      * multiple isolation mechanisms through pluggable isolation modules
    * Linux Containers / Solaris Project
    * CPU / memory / network bandwidth / I/O usage of a process tree
  
* scalable & robust
  
    * always-reject-certain-resources frameworks: short-circuit the rejection process by _filter_
      * only offer nodes from list L
      * only offer nodes with at least R resource free
      * Boolean predicates → reject bundle of resources
    * count resources offered to a framework towards its allocation
    * framework not responed to an offer for a sufficiently long time ? → Mesos rescinds the offer, re-offer the resources to other frameworks
    * [[N: not serial, but master first divide resources]]
  
* fault tolerance
  
    * master to be soft state
      * a new master can completely reconstruct its internal state from information held by the slaves & framework schedulers
    * state: list of active slaves, active frameworks, running tasks
    * multiple-master in a hot-standby configuration using ZooKeeper for leader election
      * slave/scheduler connect to the next elected master & repopulate its master
    * node/executor failures/crashes → Mesos → framework schedulers
    * scheduler failures → Mesos → notified another scheduler (multiple schedulers registered) (must have own mechanisms to sync states)
      * [[Q: how to sync states without information? persistent?]]
    * [[Q: can we have multiple schedulers at the same time?]]
  
* API
  
  * ![1571441375451](D:\OneDrive\Pictures\Typora\1571441375451.png)
  
  * `kill_task`: scheduler may call to kill 1 of its tasks
  
  * ![1571527125467](C:\Users\xiaol\OneDrive\ASemesters\CS239A\Wk4\Presentation\Pics\api1.png)
  
  * ![1571527589568](C:\Users\xiaol\OneDrive\ASemesters\CS239A\Wk4\Presentation\Pics\api2.png)
  
  * ![1571527168795](C:\Users\xiaol\OneDrive\ASemesters\CS239A\Wk4\Presentation\Pics\api3.png)
  
  * ![1571527187485](C:\Users\xiaol\OneDrive\ASemesters\CS239A\Wk4\Presentation\Pics\api4.png)
  
    * ```c++
      
      virtual void registered (ExecutorDriver *driver, const ExecutorInfo &executorInfo, const FrameworkInfo &frameworkInfo, const SlaveInfo &slaveInfo);
      virtual void reregistered (ExecutorDriver *driver, const SlaveInfo &slaveInfo);
      virtual void disconnected (ExecutorDriver *driver);
      virtual void launchTask (ExecutorDriver *driver, const TaskInfo &task);
      virtual void killTask (ExecutorDriver *driver, const TaskID &taskId);
      virtual void frameworkMessage (ExecutorDriver *driver, const std::string &data);
      virtual void shutdown (ExecutorDriver *driver);
      virtual void error (ExecutorDriver *driver, const std::string &message);
          
      virtual Status start_stop_abort_join_run();
      virtual Status sendStatusUpdate (const TaskStatus &status);
      virtual Status sendFrameworkMessage (const std::string &data);
      
      virtual void registered (SchedulerDriver *driver, const FrameworkID &frameworkId, const MasterInfo &masterInfo);
      virtual void reregistered (SchedulerDriver *driver, const MasterInfo &masterInfo);
      virtual void disconnected (SchedulerDriver *driver); 
      virtual void resourceOffers (SchedulerDriver *driver, const std::vector< Offer > &offers); 
      virtual void offerRescinded (SchedulerDriver *driver, const OfferID &offerId); 
      virtual void statusUpdate (SchedulerDriver *driver, const TaskStatus &status);
      virtual void frameworkMessage (SchedulerDriver *driver, const ExecutorID &executorId, const SlaveID &slaveId, const std::string &data);
      virtual void slaveLost (SchedulerDriver *driver, const SlaveID &slaveId); 
      virtual void executorLost (SchedulerDriver *driver, const ExecutorID &executorId, const SlaveID &slaveId, int status);
      virtual void error (SchedulerDriver *driver, const std::string &message);
          
      virtual Status start_stop_abort_join_run();
      virtual Status requestResources (const std::vector< Request > &requests);
      virtual Status launchTasks (const std::vector< OfferID > &offerIds, const std::vector< TaskInfo > &tasks, const Filters &filters=Filters());
      virtual Status launchTasks (const OfferID &offerId, const std::vector< TaskInfo > &tasks, const Filters &filters=Filters());
      virtual Status killTask (const TaskID &taskId);
      virtual Status acceptOffers (const std::vector< OfferID > &offerIds, const std::vector< Offer::Operation > &operations, const Filters &filters=Filters());
      virtual Status declineOffer (const OfferID &offerId, const Filters &filters=Filters());
      virtual Status reviveOffers ();
      virtual Status reviveOffers (const std::vector< std::string > &roles);
      virtual Status suppressOffers ();
      virtual Status suppressOffers (const std::vector< std::string > &roles);
      virtual Status acknowledgeStatusUpdate (const TaskStatus &status);
      virtual Status sendFrameworkMessage (const ExecutorID &executorId, const SlaveID &slaveId, const std::string &data);
      virtual Status reconcileTasks (const std::vector< TaskStatus > &statuses);
      virtual Status updateFramework (const FrameworkInfo &frameworkInfo, const std::vector< std::string > &suppressedRoles);
      ```
  
     



### Dominant Resource Fairness (DRF)

* From paper: NSDI'11-Dominant Resource Fairness: Fair Allocation of Heterogeneous Resources in Datacenters 
* micro-economics CEEI for fairness
  * freeing up of resources might punish an existing user's allocation
  * envy-freedom: leading users gaming the system by hoarding resources they don't need
* _dominant resource fairness_ (DRF): attempt to equalize each framework's fractional share of its dominant resources
  * dominant resource: the resource that it has the large fraction share of
  * natural generalization of max/min fairness
  * performs scheduling in $O(\log n)$ time for $n$ frameworks (binary heap)
* ![1571451441979](D:\OneDrive\Pictures\Typora\1571451441979.png)
* ![1571451448203](D:\OneDrive\Pictures\Typora\1571451448203.png)
* Model
  * $n$ users: $u_1, \cdots, u_n$
  * $m$ resources: $R_1, \cdots, R_m$
  * resource vector: $\langle r_1, \cdots, r_m \rangle$, $r_i$ denotes the total quantity of resource $R_i$
  * user demand of resources $j$ as $D_{i, j}$ ($ > 0$ positive demand vector) 
  * allocation $A = \langle a_1, \cdots, a_n \rangle$, signify that user $u_i$ gets to run $a_i$ tasks, dimensioned according to its demand vector $D_i$
  * ecah user wants to run $d_i$ tasks in total ($=\infty$ infinite task demand)
  * divisible | indivisible (approximation)
  * user $i$'s fractional share of resource $j$: $s_{i, j} = a_i D_{i, j} / r_j$
  * Each user $i$ has a dominant share $x_i = \max_j\{s_{i, j}\}$: $i$'s share of its dominant resource
* $A$ Pareto efficient: if it's not possible to find an allocation in which 
  * every user has at least as many tasks as in $A$
  * and at least one user has more tasks than in $A$
* Might be impossible to equalize all users' dominant resource allocation & satisfy Pareto efficiency
* DRF as the allocation that results from the following simple algorithm
  * Repeatedly allocate one task to the user with minimum dominant share, for whom there are enough resources to allocate another task
  * Among the users that can be allocated a task, allocate a task to $\min_i \max_j s_{i, j}$ → Repeat to Pareto efficient
  * ![img](C:\Users\xiaol\OneDrive\ASemesters\CS239A\Wk4\Presentation\Pics\drf1.png)
  * ![img](C:\Users\xiaol\OneDrive\ASemesters\CS239A\Wk4\Presentation\Pics\drf3.png)
* Jain's Fairness Index (JFI)
  * $\frac{(\sum y_i)^2}{n \sum y_i^2}$: n is # of users, $y_i$ is their resource of a single common resource
  * JFI can be extended to multiple resources by letting $y_i$ be the dominant share of user $i$, $y_i = x_i$
  * DRF can be a greedy algorithm for maximizing JFI
* Max-Min Fairness
  * any increase in a user p’s tasks will be at the expense of a decrease in another user q’s task, where q had a smaller share of its dominant resource than p had of hers.
  * dominant resource fairness is an approximation of progressive filling, in which all users’ usage of their dominant resource is increased at the same rate, while proportionally increasing their other resource consumption, until some resource is exhausted, in which case those users’ allocation is finalized.
    * This process is repeated recursively for remaining users, until no more task allocations are possible 
  * A DRF allocation is equivalent to an allocation in which each user has a bottleneck resource (Max-min theorem)
  * user $u_j$ has a bottleneck resource $R_k$ in an allocation: if $R_k$ is fully utilized, and for each user $u_i$ using $R_k, x_j \geq x_i$
* Weighted Dominant Resource Fairness
  * DRF supports weighted fair sharing similarly to Lottery Scheduling
  * Each user $i$ has a vector of weights of positive real numbers $w_{i, j}, 1 \leq j \leq m$ for $m$ resources
  * $w_{i,j} = \frac{w_{i, j}}{\sum_k w_{k, j}}$ user $i$'s fair proportion of resource $j$
  * dominant share for user $i$: $x_i = \max_j \{ \frac{s_{i, j}}{w_{i, j}}\}$
* Desirable Fairness Properties
  * Single Resource Fairness
    * In the case of a single resource, every allocation should be max-min fair.
    * each user should allocated $x_i = \min \{ D_{i, 1}, \alpha \}$, where $\alpha$ is chosen such that $\sum_i x_i = r_1$
  * Bottleneck Fairness
    * bottleneck resource: if when all users' dominant resource coincides
    * If there is a bottleneck resource, the bottleneck resource is allocated according to max-min fairness
  * Share Guarantee
    * share guarantee requires each user to receive $1/n$ fraction of at least one of her resources
    * each user will get at least at much resources as it would get by running its own cluster
    * +infinite task demand → bottleneck fairness
  * Population Monotonicity
    * If a user is removed, her resources are relinquished, resulting allocation shouldn't make any user worse off
  * Resource Monotonicity
    * Available amount of some resource increasing, resulting allocation shouldn't make any user worse off
    * less desirable than population monotonicity
  * Envy-freeness
    * A user _envies_ another if it prefers that user's allocation to her own
    * requires that no user ever envies another user in any allocations
* ![img](C:\Users\xiaol\OneDrive\ASemesters\CS239A\Wk4\Presentation\Pics\drf2.png)
* Asset scheduling violates the share guarantee and bottleneck fairness.
* DRF satisfies the share guarantee and bottleneck fairness.
* Given positive demands, DRF guarantees that every user gets identical allocation of their dominant resource
  * every DRF allocation ensures $x_i = x_j, \forall i, j$. 
* Given positive demands, DRF satisfies population monotonicity.
* Without positive demands, DRF violates population monotonicity. 
* DRF violates resource monotonicity.
* Every DRF allocation is envy-free.
  * direct implication by Max-min Theorem (each user having bottleneck resources)





## Mesos Behavior

* perform well when
  * framework scale up/down elastically
  * task durations are homogeneous
  * frameworks prefer all nodes equally
* Mesos can emulate a centralized scheduler that performs fair sharing across frameworks
* Mesos can handle heterogeneous task durations without impacting the performance of frameworks with short tasks
* Framework incentives
* _Framework ramp-up time_: time it takes a new framework to achieve its allocation
* _Job completion time_: time it takes a job to complete, assuming 1 job per framework
* _System utilization_: total cluster utilization
* _Scale up_: frameworks can elastically increase their allocation to take advantage of free resources
* _Scale down_: frameworks can relinquish resources without significantly impacting their performance
* _Minimum allocation_: frameworks require a certain minimum # of slots before they can start using their slots
* _Task distribution_: distribution of the task duration
* workload dimensions: elasticity (elastic vs rigid)s & task duration distribution (homogeneous vs heterogeneous)
* elastic framework (Hadoop, Dryad): can scale its resources up & down, starting using nodes as soon as it acquires them & releases them as soon it tasks finish
* rigid framework (MPI): running its job only after it has acquired a fixed quantity of resources, can't scale up dynamically to take advantages of new resources, or scale down without a large impact on performance
* resource types
  * mandatory: framework must acquire it to run
  * preferred: framework performs better using it
  * assume # of mandatory resources requested by a framework never exceeds its guaranteed share. (no deadlock [[R: deadlock 4 conditions]])
  * assume all tasks having the same resource demands & run on identical slices of machines (slots),
  * assume each framework runs a single job



### Homogeneous Tasks

* cluster: $n$ slots, $f$ framework (entitled to $k$ slots)
* task duratons: constant | exponential
* mean task duration $T$, runs a job requring $\beta k T$ total computaton time
* ![1571442476209](D:\OneDrive\Pictures\Typora\1571442476209.png)



#### Elastic Frameworks

* ramp-up time
  * constant: $T$
    * during a $T$ interval, every slot will become available, enable Mesos to offer the framework all its $k$ preferred slots
  * exponential $T\ln k$
    * $pdf = \lambda  e^{-\lambda t}, \lambda = 1/T$
    * wait on average $T / k$ to acquire first slot from the set of its $k$ preferred slots
    * $T/(k-1)$ on second, ...
    * $T (1 + 1/2 + \cdots + 1/k) = T \ln k$
    * pseudo-proof? on average expectation time for first completed node in k nodes
      * $f(x) = pdf = \lambda e^{-\lambda x}$, $cdf = 1 - e^{-\lambda x}$
      * $\int_{0}^{\infty} x \cdot (1-cdf(x))^{k-1} \cdot pdf(x) dx = \frac{1}{k\lambda}$
* completion time
  * $\beta T$ is the completion time where the frameworks acquire all its $k$ slots instantaneously
  * constant: $(1/2 + \beta)T$
    * assuming starting/ending times of tasks are uniformly distributed
    * 1 slot every $T/k$ on average
    * $kT/2$ computation time during first $T$ interval
    * the rest is $(\beta k -1/2 k)T / k$, so total is $(1/2+\beta)T$
  * exponential distribution: $(1+\beta)T$
    * $(k - i) T/(k - i)$ computation lost per slots
    * total $kT$, amortized to having 1 more $T$ to $(1 + \beta)T$
* system utilization: fully utilized, $1$



#### Rigid Framework

* ramp-up time: same
* completion time
  - constant: $T(1 + \beta)$
    - doesn't use any slots during the first $T$ interval (until it acquires all $k$ slots)
  - exponential $T(\ln k + \beta)$
* system utilization
  * constant: $\beta/(1/2+\beta)$
    * waste $kT/2$ computation time during the ramp-up phase
    * $\beta k T/(kT / 2 + \beta k T)$
  * exponential: $\beta / (\ln k - 1 + \beta)$
    * wasting $T(k\ln(k - 1) - (k - 1))$ time
    * ![1571462997463](D:\OneDrive\Pictures\Typora\1571462997463.png)
    * with k >> 1



### Placement Preference

* if there exists a system configuration in which each framework gets all its preferred slots & achieves its full allocation
  * irrespective of the initial configuration, will converge to the state where each framework allocates its preferred slots after at most $T$ interval
    * because after $T$ all slots become available
* if there is no such configuration (demand for preferred slots exceed the supply)
  * assume there are $x$ slots preferred by $m$ frameworks, where framework $i$ requests $r_i$ such slots, $\sum_{i=1}^m r_i > x$.
  * weighted fair allocation policy, framework $i$ will get $xs_i/sum$
  * ![1571473278611](D:\OneDrive\Pictures\Typora\1571473278611.png)
* simply offer slots to frameworks proportionally to their intended allocations
  * when a slot becomes available, Mesos offers that slot to framework $i$ with probability $s_i/\sum s_i$
  * lottery scheduling
  * select agents: random
  * offering resources: DRF



### Heterogeneous Tasks

* long tasks' mean can be significant longer than mean of short tasks
* ensure there are enough short tasks on each node whose slots become available with high frequency
* differentiate between short/long slots, bound # of long slots on each node
* reserve some resources on each node for short tasks
* expose time limits with resources in offers to frameworks



### Framework Incentives

* decentralized scheduling approach
* short tasks: incentivized to use short tasks
  * allocate any slots (long restricted to subset of slots)
  * minimize the wasted work due to revocation / failures
* no minimum allocation: use resources as soon as it allocates
  * lack of minimum allocation constraint implies the ability of the framework to scale up (adding more resources)
  * no wait for reaching a given minimum allocation, start/complete its job earlier
* scale down: grab opportunistically the available resources
  * release with little negative impact
* do not accept unknown resources: not accept resources they cannot use
  * most allocation policies will account for all the resources that a framework owns when deciding which framework to offer resources to next
    * [[N: not enforced...]]



### Limitations of Distributed Scheduling

* Fragmentation: heterogeneous demands → distributed collection of frameworks may not able to optimize bin packing as centralized scheduler
  * large resource requirement framework may starve
    * allocation modules can support a minimum offer size on each slave
    * abstain from offering resources on that slave until this minimum amount is free
  * wasted space due to both suboptimal bin packing & fragmentation bounded by ratio between largest task size & node size
    * larger node + smaller tasks → achieve high utilization
* Interdependent framework constraints
  * because of esoteric interdependencies between frameworks' performance, a single global allocation could perform better
  * rare
* Framework complexity: using resource offers may make framework scheduling more complex
  * not in fact onerous
    * whether using Mesos or centralized scheduler, frameworks need to know preference
      * decide which offers to accept vs. send preferences
    * scheduling policies are online algorithms



## Implementation

* `libprocess`: actor-based programming model using efficient asynchronous I/O mechanism (`epoll`, `kqueue`, etc)
* ZooKeeper: leader election
* HDFS: share data
* Hadoop port
  * JobTracker: schedule MapReduce tasks using resource offer
    * reuse heartbeat mechanism
    * dynamically change the # of possible slots on TaskTrackers
    * decide if it wants to run any map | reduce tasks on the slave included in the offer using delay scheduling
      * if does, creates a new Mesos task for the slave that signals the TaskTracker (Mesos executor) to increase its # of total slots
      * next time TT sends a heartbeat, JT assign runnable map/reduce tasks to the new empty slot
      * TT finishes running, TT decrements its slot count, reports Mesos
    * chaining map data to reduce
      * shared file server on each node in the cluster
* Torque & MPI port
  * Torque cluster resource manager: 3 lines to allow it to elastically scale up & down
    * schedule wrapper: configure & launch a Torque server, periodically monitors the server's job queue
      * queue empty → refuse all resource offers it receives
      * job added → inform Mesos master for receiving new offers
    * executor wrapper: start a Torque backend daemon registering with the Torque server
      * enough Torque backend daemons → server launch first job
    * job not resilient to failures → Torque never accepts resources beyond its guaranteed allocation to avoid having its tasks revoked
* Spark framework
  * ![1571474913355](D:\OneDrive\Pictures\Typora\1571474913355.png)
  * long-lived nature of Mesos executor to cache a slice of the data set in memory at each executor
    * fault-tolerance by lineage
* Elastic Web Server farm
  * scheduler wrapper: haproxy load balancer, periodically monitors its web requests statistics to decide when to launch/teardown servers
  * executor wrapper



![1571525455580](C:\Users\xiaol\OneDrive\ASemesters\CS239A\Wk4\Presentation\Pics\delaysched1.png)



![1571525247644](C:\Users\xiaol\OneDrive\ASemesters\CS239A\Wk4\Presentation\Pics\delaysched.png)



![1571559268779](C:\Users\xiaol\OneDrive\ASemesters\CS239A\Wk4\Presentation\Pics\modules.png)



![1571601863188](C:\Users\xiaol\OneDrive\ASemesters\CS239A\Wk4\Presentation\Pics\mesos_drf.png)

* random select agents
* calculate agents available resource
* calculate framework shares by current allocated resources
* give them to many framework (1st round all available)
* only available until framework declines the resources
* So DRF demands is expressed in exchanging resources



[Offer starvation](https://docs.google.com/document/d/1uvTmBo_21Ul9U_mijgWyh7hE0E_yZXrFr43JIB9OCl8/edit#)

* `SUPPRESS + REVIVE`
* `refuse_seconds`
* `quota`
* demand awareness
* shared state - optimistic concurrent
* random sorter
* less critical section







[[I: rewrite [MesosAllocator](https://github.com/apache/mesos/blob/master/src/master/allocator/mesos/hierarchical.cpp)]



![1571550254662](D:\OneDrive\Pictures\Typora\1571550254662.png)



![1571553701885](C:\Users\xiaol\OneDrive\ASemesters\CS239A\Wk4\Presentation\Pics\dynamicresshare.png)

* Fast ramp up
* Fair sharing, spike is due to Spark stages.



![1571555159243](C:\Users\xiaol\OneDrive\ASemesters\CS239A\Wk4\Presentation\Pics\datalocality.png)

batched interval allocation

![1571555411580](C:\Users\xiaol\OneDrive\ASemesters\CS239A\Wk4\Presentation\Pics\scalability.png)



[Mesos vs. Yarn](https://www.youtube.com/watch?v=aXJxyEnkHd4)

[Mesos NSDI'11](https://www.usenix.org/conference/nsdi11/mesos-platform-fine-grained-resource-sharing-data-center)

[Scaling Mesos to thousands of frameworks](https://www.youtube.com/watch?v=95emU1PK1A0)



![1571561568162](D:\OneDrive\Pictures\Typora\1571561568162.png)











![1571569424371](C:\Users\xiaol\OneDrive\ASemesters\CS239A\Wk4\Presentation\Pics\mesos_arch2.png)



![1571710543556](D:\OneDrive\Pictures\Typora\1571710543556.png)





## Motivation

* Common solutions for multiplexing clusters for multiple frameworks include statically partition and allocate a set of VMs to each framework, which both fail to achieve high utilization or efficient data sharing. The granularity of common solutions mismatches the granularity of existing frameworks which employ fine-grained resource sharing model.

## Summary

* In this paper, the authors present Mesos, which is a offer-based distributed decentralized fine-grained resource scheduler. Mesos allocates resources by gathering informaton from slaves and sending resource offers to framework executors. Mesos provides a scalable & resilient core for enabling various frameworks to efficiently share clusters by offering a minimal interface based on offers. Both Mesos is good at and the frameworks are motivated to do homogeneous short tasks with ability to scale up and down, because of the allocation module (counting/resource fairness) and framework filters. 

## Strength

* Mesos can handle short, homogeneous tasks on scalability frameworks well.
* The Dominant Resource Fairness scheduler satisfies many good properties in scheduling and fairness estimation.
* Mesos master is resilient to failures due to ZooKeeper election and soft state reconstruction.
* The interface of Mesos is simple for only few functions.
* The delay scheduling of frameworks behave well (accepting more proper offers)
* Lightweight, low-level DC/OS

## Limitation & Solution

* Mesos is not good at heterogeneous or long or rigid frameworks
* The intermediate results caching mechanism is unclear, long-lived feature is a implemented-defined not enforced.
  * Add a hint to notice Mesos decrease the priority offering in-memory caching node
* The communication cost between Mesos and frameworks might harm scalability
  * Use compressed protocol, rolling upgrade fashion
* Only 1 scheduler per framework is online and the failure recovery on backup schedulers can be hard
  * Allow multiple same framework schedulers online.

* No support for stateful service
  * Persistent resource
* Resource fragmentation





|                      | Mesos (2011)                                                 | Yarn (2013)                                                  | Borg (2015)                                                  |
| -------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Parent               | Borg'? (2003)                                                | Hadoop MRv1 (2007?)                                          | Borg' (2006), cgroup (2006-), Omega (2013)                   |
| Architecture         | Master/Slave                                                 | Master/Slave                                                 | Master/Slave                                                 |
| Resource Granularity | CPU/Memory/IO/Network                                        | Application/Job                                              | Job + Tasks                                                  |
| Scheduler            | DRF/Alloc Module                                             | FIFO/Fair/Capacity                                           | Feasibility + Scoring                                        |
| Resource Scheduling  | Mesos Master + Framework <br />Centralized + Two-level       | Resource Manager <br />Centralized + Two-level               | BorgMaster <br />Centralized + Monolithic                    |
| Task Scheduling      | Framework                                                    | Application Master                                           | BorgMaster scheduler threads                                 |
| Task Executor        | Executor (Mesos/Docker)                                      | Node Manager + Container                                     | Borglet                                                      |
| Task Delivery        | Framework - Master - Agent                                   | AM - NM                                                      | BorgMaster main threads - Borglet                            |
| Agent Interaction    | Heartbeat <br />Match agents with tasks                      | Heartbeat <br />Match agents with tasks                      | Polling <br />Match tasks with agents                        |
| Mechanism            | Resource Offer <br />Push-based                              | ResourceRequest <br />Pull-based                             | Job constraints + Task properties <br />Preemption           |
| Fault Tolerance      | Soft state reconstruction <br />ZooKeeper election           | Persistent state recovery <br />Single master                | Checkpointing from Paxos store <br />Paxos election + Chubby lock |
| Hadoop Support       | Coarse-grained <br />as Scheduler                            | Fine-grained (aware of app) <br />as Applicaton Master       |                                                              |
| Features             | Good support for extensions <br />OS level scheduler         | Good support for Hadoop jobs <br />Application level scheduler | Good support for long/heterogeneous jobs <br />High scalability across Cells |
| Problems             | Scalability, Fragmentation, Stateful service <br />Starvation, Community support | Scalability, Fault Tolerance, Starvation                     |                                                              |
| Common Techniques    | Quota, Oversubscription<br />Multi-tenancy, Reservation      | Authentication<br />On/Off-line task separation              | Alloc, Preemption<br />Containerization                      |





![img](D:\OneDrive\Pictures\Typora\image4-2.png)