# Large-scale cluster management at Google with Borg

**Abhishek Verma, Luis Pedrosa, Madhukar Korupolu et al.**

------



## Introduction

* Borg: cluster manager that runs ~100, 000 jobs, from ~1000 applications, across a number of clusters each with up to ~10,000 clusters.
  * High utilization
    * admission control
    * efficient task-packing
    * over-commitment
    * machine sharing with process-level performance isolation
  * High availability
    * minimize fault-recovery time
    * scheduling policies that reduce the probability of correlated failures
  * declarative job specification language
  * name service integration
  * real-time job monitoring
  * tools to analyze & simulate system behavior

* Benefits
  * hide the detail of resource management & failure handling so its users can focus on application development
  * operate with very high reliability & availability, support applications that do the same
  * let us run workloads across ~10,000 machines efficiently



## The user perspective

* ![1571788116277](D:\OneDrive\Pictures\Typora\1571788116277.png)
* Borg _cell_: a set of machines that are managed as a unit
* jobs, tasks
* workload: heterogeneous workload
  * long-running services that should "never" go down (`prod`)
    * short-lived latency-sensitive requests (~1us - ~100ms)
      * end-user-facing products
      * internal infrastructure services
  * batch jobs (1s ~ 10days) (`non-prod`)
* clusters & cells
  * machine - cell - cluster - datacenter - site
  * ~10,000 heterogeneous machines per cell
* jobs & tasks
  * ![1571798056263](D:\OneDrive\Pictures\Typora\1571798056263.png)
  * job properties
    * name, owner, # of tasks
    * constraints for particular attributes for tasks to run on
      * hard/soft constraints
    * run in just 1 cell
  * task: map to a set of Linux processes running in a container in a machine
    * no virtualization, but cgroups
  * task properties
    * resource requirement, task index within the job, task-specific command-line flags
    * statically linked to reduce dependencies on their runtime environment
    * structured as packages of binary and data files, installation is orchestrated by Borg
  * RPC to borg, from command-line tool
  * declarative configuration language BCL
    * variant of GCL, generates protobuf files, extended with Borg-specific keyword
    * lambda function
  * user update tasks descriptions
    * lightweight, non-atomic transaction which be easily undone until it's closed (committed)
    * update in rolling fashion with disruption constraints
    * reschedule, preemption, restart, move between machines
    * notified via `SIGTERM` before `SIGKILL`, cleanup, save state, finishing any concurrent requests, decline new ones.
    * set a delay bound.
    * [[N: hot upgradation!]]
* _alloc_: reserved set of resources on a machine in which 1+ tasks can be run
  * remain assigned whether or not they are used
  * gather tasks from different jobs
  * retrain resources between stopping a task
  * set resources aside for future tasks
  * _alloc set_: group of allocs that reserve resources on multiple machines
* priority, quota, admission control
  * _priority_: small positive integer, relative importance for jobs within a cell
    * high-priority task can obtain resources preempting (killing) the latter
    * non-overlapping priority bands for different sets
      * monitoring - production - batch - best effort (testing/free)
    * preemption cascade? disallow tasks in production priority band to preempt one another
  * _quota_: a vector of resource quantities at a given priority for a period of time, decide which jobs to admit for scheduling
    * maximum amount of resources that a user's job requests can ask for at a time
    * quota-checking: part of admission control
    * over-selling quota at low-priority levels
      * production: actual resources available in the cell
      * otherwise: every user has infinite quota at priority zero
    * allocation: tied to physical capacity planning
    * reduce the need for policies like DRF
  * admission control: special privileges, kernel features, Borg behaviors
* naming and monitoring
  * Borg name service (BNS) names for each task
    * cell name, job name, task number, job size, task health information
    * task's hostname & port into a consistent, highly available file in Chubby with that name
    * RPC uses Chubby file to find task endpoint
    * BNS name forms the basis of task's DNS name
  * task contains a built-in HTTP server that publishes information about the health of the task & 1000 of performance metrics.
  * Borg monitors the health-check URL & restarts tasks that do not respond promptly or return an HTTP error code
  * Other data tracked by monitoring tools for dashboard & alerts on service level objective violations
  * Sigma: web-based user interface for metrics
  * rotating logs
    * state of jobs/cell/tasks, resource behavior, detailed logs, execution history, eventual fate, why pending, guidance, conforming resource shape



## Borg architecture

* Borgmaster
  * main Borgmaster process: 
    * client RPC (mutate, or read-only access)
    * state machines for all of the objects in the system
    * communicate with the Borglets
    * offer a web UI as a backup to Sigma
  * scheduler process
  * replicated 5 times
    * replica with in-memory copy of most of the state of the cell
      * also recorded in a highly-available, distributed, Paxos-based store on the replica's local disks
    * single elected master per cell as Paxos leader & state mutator
    * re-elect if failure → a Chubby lock for visibility
      * ~10s - 1min, in-memory reconstruction
      * dynamically re-synchronize its state from other Paxos replicas
  * checkpoint, periodic snapshot + change log kept in Paxos store
    * restoring Borgmaster's state to an arbitrary point in the past
      * fixing it by hand in extremis
    * building a persistent log of events for future queries
    * offline simulation
  * high-fidelity Borgmaster simulator: Fauxmaster
    * read checkpoint files
    * complete copy of production Borgmaster code with stubbed-out inferface for Borglets
    * debug failures
    * capacity planning
    * sanity checking by cell configuration changing

* scheduling
  * job submitted → Borgmaster persistent stores it to Paxos store, adds tasks to pending queue
  * scheduler asynchronously scans the pending queue → assign tasks to machines
    * Multi-level Fair Queue scheduling
    * feasibility check: find machines on which task could run
      * includes preemption
    * scoring: picks one of the feasible machines
      * includes user-specified preferences
      * minimize the # & priority of preempted tasks
      * picking machines that already have a copy of the task's packages
      * spreading tasks across power & failure domains
      * packing quality including putting a mix of high & low priority onto a single machine that allow high-priority ones to expand in a load spike
      * E-PVM: generates a single cost value across heterogeneous resources & minimizes the change in cost when placing a task
        * end up spreading load across all the machines, leading headroom for load spikes but at the expense of increased fragmentation
        * "worst fit"
      * "best fit": fill machines as tightly as possible
        * penalize any mis-estimation in resource requirement by user / Borg
        * hurt applications with bursty loads, bad for batch jobs
      * hybrid, 3-5% better packing efficiency than best fit
      * preempt (kill) low-priority tasks from lowest - highest priority until it does
      * add preempted tasks to the scheduler's pending queue (not migrate / hibernate)
    * startup latency: package installation (80%), contention of local disk
      * prefer assign tasks to machines already having necessary packages installed
      * most packages are immutable, shared, cached
        * the only form of data locality Borg supports
        * [[N: The rest data locality is handled by job constraints]]
* Borglet: local Borg agenet present on every machine in a cell
  * start/stop/restart tasks
  * manage local resources by manipulating OS settings
  * roll over debug logs
  * report the state of the machine to the Borgmaster & other monitoring system
  * Borgmaster polls each Borglet every few seconds to retrieve the machines' current state & send it any outstanding requests
    * Borgmaster controls the rate of communication
    * avoid need for an explicit flow control mechanism
    * prevent recovery storms
  * each Borgmaster runs a stateless link shard to handle the communication with some of the Borglets
    * partition recalculated whenever a Borgmaster election occurs
    * prepare/send messages to Borglets for updating cell's state with Borglets' responses
    * Borglet: always report full state
    * link shards: aggregate & compress information by reporting only differences to the state machines (COW)
  * no response for several poll messages → down → reschedule
  * communication restored → Borgmaster tells Borglet to kill tasks rescheduled, avoid duplicates
* Scalabilty
  * unknown limit...
  * early version of Borgmaster: simple, synchronous loop accepting requests, scheduling tasks, communicating with Borglets
  * split into separate scheduler process & replicated other functions
    * [[Q: so how many schedulers per Borgmaster? five? two? one?]]
  * scheduler replica: operates on a cached copy of the cell state
    * retrieves state changes from the elected master (assigned/pending work)
    * update local copy
    * scheduling & assign tasks
    * inform the elected master of assignments
    * master will accept & apply assignments unless inappropriate (based on out of date state [[Q: network issue? add timestamp/version number]])
    * like OCC used in Omega
  * separate threads to talk to the Borglets & respond to read-only RPCs
  * shard functions across 5 Borgmaster replicas
  * Score caching: Borg caches scores until properties of the machine/task change (task terminate, attribute altered, requirements changed)
    * ignoring small changes in resource quantities reduces cache invalidations
  * Equivalence classes: identical task requirements → 1 feasibility/score for 1 task per equivalence class
  * Relaxed randomization: schedulers examine machines in a random order until it has found enough feasible machines to score, selects the best within that set
    * reduce # of scoring & cache invalidation
    * speedup assignment
    * like batched sampling of Sparrow ([[N: power of two choices]])



## Availability

* ![1571806813075](D:\OneDrive\Pictures\Typora\1571806813075.png)
* Avoid breakdowns
  * automatically reschedule evicted tasks, on a new machine if necessary
  * reduce correlate failures by spreading tasks of a job across failure domains such as machines/racks/power domains
  * limit the allowed rate of task disruption & # of tasks from a job that can be simultaneously down during maintenance activities such as OS or machine upgrades
  * use declarative desired-state representations & idempotent mutating operations, failed client can harmlessly resubmit any forgotten requests
  * rate-limits finding new places for tasks from machines that become unreachable, because it cannot distinguish between large-scale machine failure & a network partition
  * avoid repeating task::machine partings that cause task / machine crashes
  * recover critical intermediate data written to local disk by repeatedly re-running a logsaver task
* key design: already-running tasks continue to run even if the Borgmaster or a task's Borglet goes down
* Borgmaster techniques
  * replication for machine failures
  * admission control to avoid overload
  * deploy instances using simple, low-level tools to minimize external dependencies



## Utilization

* cell compaction: given a workload, how small a cell it could be fitted into by removing machines until the workload no longer fitted, repeatedly re-packing the workload from scratch to ensure we didn't get hung up on an unlucky configuration
* cell sharing
* large cells
* fine-grained resource requests
* resource reclamation



## Isolation

* security: `chroot` jail, `ssh`/`borgssh`
  * VM & security sandboxing for external software
    * Google AppEngine (GAE), Google Compute Engine (GCE)
    * hosted VM in a KVM process as a Borg task
* performance
  * cgroup-based resource container
  * OS kernel isolation
  * occasional low-level resource interference (memory bandwidth, L3 cache pollution)
  * overload & overcommitment
    * application class `appclass`
      * latency-sensitive (LS) appclasses / non-prod
      * batch appclasses
  * compressible vs non-compressible resources
    * rate-based, reclaimable from a task vs. can't reclaim without killing the task
  * user-space control loop assigns memory to containers. handles OOM events from the kernel, kills tasks allocate beyond limitation
    * based on prediction future usage (prod tasks)
    * memory pressure (non-prod)
    * Linux's eager file-caching significantly complicates the implementation due to accurate memory accounting
  * LS can reserve entire physical CPU cores
  * dynamically adjust the resource caps of greedy LS tasks, do not starve batch tasks for multiple minutes, selectively applying CFS bandwidth control when needed
  * standard Linux CPU scheduler (CFS) requires substantial tuning to support low latency & high utlization
    * Borg-CFS: extended per-cgroup load history, allow preemption of batch tasks by LS tasks, reduce scheduling quantum when multiple LS tasks are runnable on a CPU
    * thread-per-request mitigates the effects of persistent load imbalance
    * sparingly use `cpusets` to allocate CPU cores to applications with particular tight latency requirements
  * WIP: thread placement, CPU management (NUMA-aware, hyperthreading-aware, power-aware), control fidelity of the Borglet
  * tasks are permitted to consume resources up to their limits: slack resources



## Lessons & Future work



### The Bad

* Jobs are restrictive as the only grouping mechanism for tasks
  * no first-class way to manage an entire multi-job service as a single entity, or refer to related instances of a service (canary, production tracks)
  * users encode their service topology in job name
  * Kubernetes rejects the job notion, organizes its scheduling units (pods) using labels
    * arbitrary key/value pairs that users can attach to any object in the system
    * useful grouping: service, tier, release-type (production, staging, test)
    * more flexibility than single fixed grouping of a job
* One IP address per machine complicates things
  * tasks use single IP address, share the host's port space
  * Borg must schedule ports as a resource
  * tasks must pre-declare how many ports they need, be willing to be told which ones to use when they start
  * Borglet must enforce port isolation
  * naming/RPC systems must handle ports as well as IP address
  * Kubernetes: every pod & service gets its own IP address
    * allowing developers to choose ports
    * Linux namespaces, VMs, IPV6, SDN
* Optimizing for power users at the expense of causal ones
  * richness of BCL API make things harder for the casual user, constraints its evoluation
  * build automation tools and services that run on top of Borg & determine appropriate settings from experimentation. [[R: greedy LS handling]]



### The Good

* Allocs are useful: alloc abstraction spawns the widely-used logsaver pattern / simple data-loader task periodically updates the data used by a web server
  * Allocs & packages: helper services to be developed by separate teams
  * Kubernetes equivalent: `pod`, resource envelope for 1+ containers that are always scheduled onto the same machine, can share resources
    * use helper containers in the same pod instead of tasks in an alloc, but the same
* Cluster management is more than task management
  * manage lifecycles of tasks & machines
  * naming, load balancing
  * Kubernetes supports naming & load balancing using `service` abstraction
    * a service has a name & a dynamic set of pods defined by a label selector
    * any container in the cluster can connect to the service using the service name
    * automatically load-balance connection to the service among the pods matching label selectors
    * keep track of where the pods are running as they get rescheduled over time due to failures
* Introspection is vital
  * surface debugging information to all users rather than hiding it
  * several levels of UI & debugging tools
  * Kubernetes: replicate many of Borg's introspection techniques
    * cAdvisor for resource monitoring
    * log aggregation based on ElasticSearch/Kibana & Fluentd
    * master can be queried for a snapshot of its objects' state
    * unified mechanism that all components can use to record events
      * pod scheduled
      * container failing
* The master is the kernel a distributed system
  * Borgmaster from monolithic system → kernel sitting at the heart of an ecosystem of services that cooperate to manage user jobs
  * split off scheduler, primary UI (Sigma) into separate processes
  * admission control, vertical/horizonal auto-scaling, re-packing tasks, periodic job submission (cron), workflow management, archiving system actions for off-line querying
  * Kubernetes goes further: API server at its core responsible only for processing requests & manipulating the underlying state objects
    * cluster management logic: small, composable micro-services
      * replication controller: maintain the desired # of replicas of a pod in face of failures
      * node controller: machine lifecycle
* 













## Motivation

* A cluster manager should achieve high utilization, high availability, high scalability and have a easy-to-use user interface. Google developers and system administrations need a cluster manager to submit their work upon it to hide the detail of resource management and failure handling.

## Summary

* In this paper, the authors present Borg, which is a monolithic cluster management system for 100, 000 machines. Borg clusters are split into cells where each cell contains a Paxos controlled replicated Borgmaster with their scheduler process and master process separated for handling asynchronous scheduling and RPC requests. Borglet runs on each machines, controlling the execution of tasks. The scheduling choice is based on feasibility check and scoring with polled information from Borgmaster from machines. To scale up, Borg uses OCC-like scheduling control and caching, aggregating, randomizing results.

## Strength

* The scalability of Borg is really impressive, the design of separating functionalities into composable process and usage of caching, aggregating, randomizing, optimistic results improves its scalability.
* The introspection support of Borg is very good. It has high fidelity Borgmaster simulator Faxumaster and Borglet simulators. It provides many user friendly interfaces, including BNS, Borgmaster UI, Sigma, logs.
* Borg introduces the idea of job/task constraints, quotas, allocs, DSL for better scheduling choices.
* Borg has good support for long-running jobs (the job/task lifetime, hot update) and latency-sensitive jobs (appclass, oversubscription for slack resources).

## Limitation & Solution

* Borg can only organize workloads as jobs, Kubernetes can organize as key-value labels for useful grouping properties and naming, load-balancing under the service abstraction.
* Borg optimizes for long-running jobs / power users / high-priority jobs, and it might let low-priority jobs starve.
  * Use better multi-queue priority-based scheduling algorithms

