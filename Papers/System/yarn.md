# Apache Hadoop YARN: Yet Another Resource Negotiator 

**Vinod Kumar Vavilapalli, Arun C Murthy, Chris Douglas, et al.**

------



## Introduction

* Hadoop shortcomings
  * tight coupling of a specific programming model with the resource management infrastructure, forcing developers to abuse the MapReduce programming model
  * centrailized handling of jobs' control flow, resulting in endless scalability concerns for the scheduler
* next generation of Hadoop's compute platform: YARN
* separating resource management function from the programming model
* delegates many scheduling-related functions to per-job components



## History & Rationale

* Scalability: scalable framework [^R1]
* Multi-tenancy: cloud platform[^R2]
* Serviceability: decoupling of upgrade dependencies and service [^R3]
* Locality awareness: middling resource utilization [^R4]
  * locality
* High cluster utilization [^R5]
* Reliability / Availability [^R6]
  * fault tolerance
  * monitoring workloads for dysfunctional jobs
  * safeguards to protect its own availability (delay allocating fallow resources which will overwhelming JobTracer process)
* Secure & auditable operation [^R7]
  * authorization model, strong/scalable authentication
* Support for programming model diversity [^R8]
  * iterative jobs
  * bulk-synchronous parallel model (BSP)
* Flexible resource model: no fixed # of typed slot for mapper/reducer [^R9]
* Backward compatibility [^R10]
  * fairness
  * capacity

> Scalability 可扩展性：前文提过，由于jobtracker负载过大，造成单点性能瓶颈，影响系统给的可扩展性,这也是要考虑的主要标准 
>
> Multi-tenancy 多租户：为了解决这个问题，第一代hadoop引入HOD(Hadoop On Demand),它通过资源管理系统Torque将一个物理Hadoop集群隔离出若干个虚拟Hadoop集群，以应对不同类型的应用程序相互干扰的问题.Torque分配节点时不考虑本地性；资源调整粒度过粗，job之间无法共享资源。调度延迟过高，利用率过低。因此，在HoD之后，Hadoop还需要新的集群调度机制 
>
> Serviceability 可服务性：HoD是存在问题的，它为每一个job建立一个新的集群，而新和旧版本的hadoop同时存在，hadoop的更新发布周期非常短 
>
> Locality Awareness 位置感知：jobtrack尽量将任务部署到离输入的近的节点上，但是node allocator是不能感知到位置 
>
> High Cluster Utilization 高集群利用率：一个集群一个计算框架，造成各个集群管理复杂，资源的利用率低，例如某个时间段，hadoop集群忙而Spark集群闲着。
>
> Reliability/Availability 可靠性/可用性：主要是考虑到单点故障的问题，大型分享集群处理过多jobs时的overhead问题。 
>
> Secure and auditable operation 安全和可审计的操作：系统在安全方面依然是重要的需求，主要集中在Authentication方面 
>
> Support for Programming Model Diversity 支持多样的编程模型：由于第一代hadoop与MR的紧耦合，无法支持其他的编程模型。目前诸如Spark,Storm等越来越多的编程模型出现也非常的流行，这也是促使了Yarn诞生的主要原因。 
>
> Flexible Resource Model 灵活的资源模型：map和reduce的slot是由cluster operator设定，这容易造成资源利用瓶颈，闲置的map资源不能用于reduce，反之亦然，造成很大的延迟和资源紧缺与浪费。 
>
> Backward Compatibility 向后兼容：新的系统保证兼容原先的系统，做越少的更改越好。



## Architecture

* ![1571354975338](D:\OneDrive\Pictures\Typora\1571354975338.png)
* _platform layer_: responsible for resource management (RM)
* host of _framework_: coordination of logical execution plans (AM)
* `ResourceManager`: per-cluster
  * tracking resource usage & node liveness
  * enforce allocation invariants
  * arbitrates contention among tenants
* `ApplicationMaster`: coordinates the logical plan of a single job by requesting resources from the RM
  * managing all lifecycle aspects including dynamically increasing/decreasing resource consumption
  * managing the flow of execution
  * handling faults & computation skew
  * performing other local optimizations
  * arbitrary user code
  * written in any programming language since RM <-> NM encoded using `protobuf`
  * delegation to AM → scalability [^R1], programming model flexibility [^R8], improved upgrading/testing  [^R3] (multi-version coexisting)
  * AM <-> RM (multiple nodes resources)
    * specification of locality preferences
    * properties of the containers
    * lease, pulled by a subsequence AM heartbeat
  * AM <-> NM
    * token-based security mechanism
    * encode an application-specific launch request with the lease
  * application-specific semantics are managed by each framework [^R3, R8]

* RM as a daemon on a dedicated machine
  * central authority arbitrating resources among various competing applications in the cluster
  * central & global view → fairness [^R10] , capacity [^R10], locality [^R4]
  * dynamically allocate leases (containers) to allocations run on particular nodes [^R4, R9]
  * heartbeats <-> NM
  * assemble global view from snapshots of NM state
* `NodeManager`: system daemon running on each node
  * monitoring resources availability
  * reporting faults
  * container lifecycle management
* Client <-> RM: admission control phase during which security credentials are validated  & various operational & administrative checks performed [^R7]



### Resource Manager (RM)

* public interfaces
  * clients → submitting applications
    * authentication
  * AM → dynamically negotiating access to resources: `ResourceRequest`
    * \# of container
    * resources per container
    * locality preferences 
    * priority of requests within the application [[Q: how this be a moral way??]]
    * full detail | roll-up version (node, rack, global level [^R4])
      * roll-up as lossy compression
      * clear & compact [^R1, R5, R9]
    * returns containers + tokens + forwarded exit status of finished containers (NM)
* internal interface: → NM for cluster monitoring & resource access management
  * NM heartbeats  → track/update/satisfy requests
* Communication messages & scheduler state must be compact & efficient to scale [^R1]
  * balance between accuracy & compactness
  * homogeneous environment [[Q: what about heterogeneous?]]
* only global profile, global scheduling properties, ignoring local optimizations
* treat the cluster resources as a (discretized) continuum [^R9] [[Q: how? anywhere it shows that?]]
  * extensions
    * explicit tracking of gang-scheduling needs
    * soft/hard constraints to express arbitrary co-location | disjoint placement
* extensions
  * RM symmetrically request resources back from AM
    * similar to `ResourceRequest` to capture locality preferences (revoking preferences)
    * AM flexibly fulfills the preemption request (yielding containers) by checkpointing the state of tasks | migrating computations
    * allow AM to preserve work
    * non-collaborative AM? → instruct NM to terminate [[Q: same as fault recovery procedure?]]
* not responsible for coordinate application execution | task fault-tolerance (AM part)
* not charged with providing status/metrics for running applications (AM part) | serving framework specific reports of completed jobs (delegated to per-framework daemon)



### Application Master (AM) / Framework

* application: static set of processes | logical description of work | long-running service
* per-application [[Q: why AM starts each time? GC-style?]]
* AM coordinate the application execution, AM itself runs in the cluster just like any other container
* A component of RM negotiates for the container to spawn bootstrap process
* periodically heartbeats to RM to affirm liveness & update the record of its demand
  * [[Q: so rolling up preferences until converge? When to final start?]]
  * encoding preferences & constraints in a heartbeat message to the RM
  * RM responses container leases on bundles of resources bound to particular nodes in the cluster
  * AM may update its execution plan to accommodate perceived abundance or scarcity
* _late binding_: process spawn is not bound to the request, but to the lease → condition might not hold when receiving resources
  * semantics of the containers are fungible & framework-specific [^R3, R8, R10]
  * update resources asks to RM as the containers it receives affect both its present & future requirements
* AM optimizes for locality among map tasks with identical resources requirements
  * receive container, match it against the set of pending map tasks, selecting a task with input data close to the container
  * update requests to diminish weight on other k - 1 hosts (since not desirable)
  * opaque to RM
  * fail → updating demand to compensates
* Some JobTracker services (job progress, interface) → AM or framework daemons
* RM doesn't interpret the container status, AM determines the semantics of success/failure of the container exit status reported by NMs through the RM [[Q: why having extra communication?]]
* AM handles fault-tolerance (because intertwined with semantics)



### Node Manager (NM)

* worker daemon
* authenticate container leases [^R7]
* manage container's dependencies
* monitor execution
* provide a set of services to containers
* register with the RM
  * heartbeats: status
  * rececive instructions
* container: descripted by a container launch context (CLC)
  * map of environment variables
  * dependencies stored in remotely accessible storage
  * security tokens (for download authentication)
  * payloads for NM services
  * command necessary to create the process
  * [[R: compared to k8s?]]
* After validation, NM configures the environment for the container, including initializing its monitoring subsystem with the resource constraints specified in the lease
* Copy necessary dependencies: data files, executables, tarballs to local storage
* NM eventually garbage collects dependencies
  * [[Q: when? granularity?]]
* kill containers as directed by the RM or AM [^R2, R3, R7]
  * RM reports its owning application as completed
  * the scheduler decides to evict it for another tenant
  * NM detects the container exceeded the limits of its lease
  * AM finds the work isn't need any more
  * NM cleanup working directory in local storage
  * resources discarded
* periodically monitor the health of the physical node
  * local disks
  * admin configured scripts
  * hardware/software issues
  * change state to unhealthy → RM (killing, stopping allocations)
* local services to containers running on that node
  * log aggregation service uploading data written by the application to stdout/stderr to HDFS
* administrator configures the NM with a set of pluggable, auxiliary services
  * like pipelining intermediate results (delay cleanup)
  * in CLC payload



### YARN framework/application writer

* Submitting the application by passing a CLC for the AM to the RM
* When RM starts the AM, register with the RM, periodically advertise its liveness and requirements over heartbeat protocol
* Once the RM allocates a container, AM can construct a CLC to launch the container on the corresponding NM. Monitor the status of running container & stop it inside the container is strictly the AM's responsibility
* Once the AM is done with its work, it should unregister from the RM & exit cleanly
  * [[Q: But some AM/framework could hold it forever to hurt system? Force termination by RM? If AM is trustworthy, why AM needs tokens? user-programs unreliable?]]
  * [[Q: so users submitting application+framework or application? RM knows AM?]]
* Optionally, add control flow between own clients to report job status & expose control plane



### Fault tolerance & availability

* commodity hardware → building fault tolerance into each layer → hide the complexity of detection & recovery from hardware faults from users
* RM: a single point of failure
  * recover from its own failures by restoring its state from a persistent store on initialization
  * application written to persistent storage for recovery at receiving
  * recovery complete → kill all containers running, including live AMs → launch new instances of each AMs → AM supports recovery, then automatically restore users' pipelines [^R6]
    * [[N: directly kill users...]]
  * [WIP] add sufficient protocol support for AMs to survive RM restarts, resync
* NM failure
  * RM detects by timing out its heartbeat response
    * mark all containers running on that node as killed
    * report failure to all running AMs
    * transient failure ? → NM re-synchronize with the RM, cleanup its localstate, continue
  * AM responsible for reacting to node failures, potentially redoing work down by any containers running ont hat node during that fault
* AM failure
  * don't affect the availability of the cluster [^R6, R8]
  * application hiccup due to AM failure
  * RM may restart AM if fails
  * restarted AM synchronizing with its own running containers
    * [[Q: but AM writers must handle this?]]
* Container failures: left to the frameworks
  * RM collects all container exit events from NMs, propagates those to the corresponding AMs in a heartbeat response.
  * AM retreives them.



### Extras

* Client ~ RM
  * F: submitting applications (authentication)
  * B: ?
* RM ~ AM
  * F: container leases (tokens), container exit status (from NMs)s, NM node failures, extensions (RequestResourceBack), kill requests (recovery), application(?)
  * B: ResourceRequests (rolling up), heartbeats, registeration/unregisteration (framework-level), extensions (re-sync operations)
* AM ~ NM
  * F: container leases, CLC (including monitoring code + application), kill work requests (no longer need)
  * B: no explicit channel, but communication mechanism contained in CLC?
* NM ~ RM
  * F: heartbeats (container exit status, healthy status, resync)
  * B: kill requests, terminate requests (non-collaborative), AM bootstrap processes
* NM ~ framework daemons
  * F: statistics



## YARN in the real-world

* YARN increases pressure on the HDFS NameNode
* _Apache Hadoop MapReduce_: including Pig, Hive, Oozie, etc.
* _Apache Tez_: generic directed-acyclic-graph (DAG) exuection framework, providing query execution systems like Hive & Pig
* _Spark_: RDDs, iterative jobs
* _Dryad_: DAG with LINQ, eventually Java + protocol-buffer
* _Giraph_: scalable, vertex-centric graph computation framework
* _Storm_: distributed, real-time processing engine. provide parallel stream processing, online computation, :heavy_check_mark: flexible in resource allocation.
* _REEF meta-framework_: help writing AM on fault-tolerance, execution flow, coordination, storage management, caching, fault-detection, checkpointing, push-based control flow, container reuse.
* _Hoya_: spin up dynamic HBase clsuters on demand. grow/shrink on demand

* request-based approach (Mesos is offer-based)
* rolling upgrades, late binding (Mesos: central scheduler pools)



## Questions

* Does RM know the framework behind application? Should RM trust the framework, therefore trust AM?
  * if RM trusts framework, or restricts frameworks used by applications, why framework needs to authenticate with NMs
  * If not, without extension, a malicious framework can hold the resources forever. Though RM can never allow further allocation
* Can we do a non-intrusive scheduler/resource allocator?
* Could we apply some para-virtualization way here?
* Why not hosting (multiple) AMs for each framework as slots to avoid bootstrapping processes per application?







## Motivation

* Apache Hadoop has become the de facto place where data and computational resources are shared and accessed. However, it has been abused beyond the capabilities of the cluster management substrate. The limitations and misuses caused a lot of researching and arguments exposing its weakness.

## Summary

* In this paper, the authors present YARN, which is a request-based resource negotiator based on HDFS. YARN consists three layers of management: Resource Master (RM), ApplicationManager (AM), and Node Manager (NM). Resource Master is the central of accepting client applications, allocating resources and tracking status of nodes. RM holds the global properties without looking local optimizations. ApplicationManager is a per-application framework managing resource requests and application execution. AM represents the semantics of the framework and does local optimizations (E.g. improving application execution graph) in a rolling upgrading way coordinating with RM. Node Manager is a worker daemon receiving the working context and sending monitoring status.

## Strength

* The separation of global properties and local optimizations improve the decision making by making AM and RM coordinate in rolling up fasion.
* The separation abstraction of RM and AM gives YARN flexibilities to separate resource management and computations. And it helps YARN to support various computation frameworks.

## Limitation & Solution

* The framework/application writers need to handle extra fault tolerance issues due to resource negotiator failures (RM failures) or resynchronization between containers (AM failures).
* AMs can't directly negotiate with NMs, the message from NMs need to be forward from RM.
  * But applications in containers can freely send messages back to framework daemons.
  * Extra resource allocation to RM: requiring RDMA/RMA
* RM is the single point of failure.
  * multiple RMs design (with consensus protocol)

