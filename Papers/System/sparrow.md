# Sparrow: Distributed, Low Latency Scheduling

**Kay Ousterhout, Patrick Wendell, Matei Zaharia, Ion Stoica **

------



## Introduction

* Scheduling highly parallel jobs that compete in 100+ ms poses a major challenge for task schedulers
  * millions of tasks per second on appropriate machines while offering milisecond-level latency & high availability
* Sparrow: Decentralized, randomized sampling approach provides near-optimal performance while avoiding the throughput & availability limitations of centralized design.
* ![1571615942630](D:\OneDrive\Pictures\Typora\1571615942630.png)
* Low latency interactive data processing → 100ms response time range
* short, sub-second tasks presents a difficult scheduling challenge
  * targeting low latency
  * breaking long-running batch jobs into a large # of short tasks
  * schedule decisions must be made at very high throughput
* scheduling from a set of machines that operate autonomously & without centralized/logically centralized state
  * scalable
  * availability properties
  * challenge: providing response time comparable to provided by a centralized scheduler
* Sparrow: stateless distributed scheduler
  * power of two choices load balancing technique
    * scheduling each task by probing 2 random servers & placing the task on the server with fewer queued tasks
  * bach sampling
    * job response time is sensitive to tail task wait time
    * applying the multiple choices approach
    * place $m$ tasks in a job on the least loaded $d m$ randomly selected worker machines
    * not degrade as a job's parallelism increases
  * late binding
    * server qeuue length is a poor indicator of wait time
    * due to messaging delays, multiple schedulers sampling in parallel may experience race condition
    * delaying assignments of tasks to worker machines until workers are ready to run the task
  * policy & constraint
    * multiple queue on worker machines to enforce global policies
    * support per-job & per-task placement constraints need by analytic frameworks



## Design Goals

* Fine-grained task scheduling for low-latency applications
  * Complementary to functionality provided by cluster resource managers
  * YARN/Mesos already has 2-level scheduler, Omega already has shared-state scheduler
* Sparrow assumes that a long-running executor process is already running on each worker for each framework → only send short task description (not big binary)
* Executor process may be launched within a static portion or via a cluster resource manager (YARN/Mesos/Omega)
* Approximations, Tradeoff many of the complex features
  * no certain types of placement constraints
  * no perform bin packing
  * no support gang scheduling
* Support a small set of features in a way that can be easily scaled, minimize latency, keep the design simple
  * strict priorities / weighted fair share
  * basic constraint (per-task/job constraint)



## Sample-Based Scheduling for Parallel Jobs

* traditional: maintain a complete view
* Sparrow: many schedulers operate in parallel, schedulers do not maintain any state about cluster load
* schdulers rely on instantaneous load information acquired from worker machines



### Terminology & Job model

* A job consists of $m$ tasks that are each allocated to a worker machine
* workers run tasks in a fixed number of slots
* _wait time_: time from when a task is submitted to the scheduler → when the task begins executing
* _service time_: time the task spends executing on a worker machine
* _job response time_: time from the job is submitted to the scheduler → last task finishing executing
* _delay_: total delay within a job due to both scheduling & queueing
* assume each job runs as a single wave of tasks
  * most negatively affects by the approximations
  * even a single delayed task affects the job's response time
* ![1571684652715](D:\OneDrive\Pictures\Typora\1571684652715.png)



### Per-task sampling

* power of two choices load balancing technique
  * low expected task wait time using a stateless, randomized approach
  * place each task on the least loaded of two randomly selected worker machines
  * improve expected wait time exponentially
  * ![1571684937846](D:\OneDrive\Pictures\Typora\1571684937846.png)
* direct application of the power of 2-choice
  * scheduler randomly selects 2 worker machines for each task, send a probe to each (probe: lightweight RPC)
  * worker machines reply to the probe with # of current queued tasks
  * scheduler places the task on the worker machine with the shortest queue
  * [[Q: locality?]]
* per-task sampling: job's response is dictated by the longest wait time of any the job's tasks
  * job response time sensitive to tail performance
  * avg. job response time much higher than avg. task response time
  * 3x better than random placement
  * 2.6x worse than omniscent
* ![1571685711291](D:\OneDrive\Pictures\Typora\1571685711291.png)



### Batch sampling (Job-level batching)

* ![1571685427068](D:\OneDrive\Pictures\Typora\1571685427068.png)
* sharing informaton across all of the probes  for a particular job
* lucky lightly loaded probe will be aggregated
* randomly select $dm$ worker machines
* send probes to each of the workers
* as with per-task sampling, workers reply # of queued tasks
  * [[N: for homogeneous short tasks]]
* place one of the job's $m$ tasks on each of the $m$ least loaded workers
* 0.73x better than per-task
* [[Q: batching across jobs?]]



### Problems with sample-based scheduler

* perform poorly at high load: schedulers place tasks based on the queue length at worker nodes
  * queue length is only a coarse prediction of wait time
    * heterogeneous tasks
  * estimating task durations is difficult
    * should be effective (scale)
* race conditions where multiple schedulers concurrently place tasks on a worker appears lightly loaded



### Late binding

* workers do not reply immediately to probes, instead, place a reservation for the task at the end of an internal worker queue
* reservation reaches the front of the queue → workers send RPC to the scheduler requesting a task for the corresponding job
* scheduler assigns the job's tasks to the first $m$ workers with a no-op signalling that all of the  job's tasks have been launched.
* downsides: workers are idle while sending an RPC to request [[N: bad for unreliable network]]
  * schedulers wait to assign tasks until a worker signals that it has enough free resources to launch the task
  * idle waste time: $d \cdot RTT / (t + d \cdot RTT)$ (d: # of probes per task, RTT: mean round-trip-time, t: task service time)
* [[Q: how this solve prediction & race condition?]]
  * [[N: by real-time responsing, converting estimation time to ready time + RTT]]



### Proactive Cancellation

* handle outstanding probes
  * proactively send a cancellation RPC to all workers with outstanding probes
  * wait for the workers to request a task & reply requests with a message indicating no unlaunched tasks remain
* extra RPCs tradeoff



## Scheduling Policies & Constraints

* placement constraints (locality)
  * per-job constraints: trivially handled at a Sparrow scheduler (select $dm$ from satisfied workers)
  * per-task constraints: cannot use aggregation, use per-task sampling + late binding instead
    * shares information across task when possible
* resource allocation policies
  * allocate resources according to a specific policy when aggregate dmeands for resources exceeds capacity
  * strict priorities (FIFO, EDF, SJF)
    * multiple queue on worker nodes
    * 1 queue for each priority at each work node
    * trade simplicity for accuracy
  * weighted fair sharing
    * a separate queue for each user per worker



## Analysis

* batch sampling achieves near-optimal regradless of the task duration distribution
* ![1571724642362](D:\OneDrive\Pictures\Typora\1571724642362.png)
* assumptions
  * zero network delay
  * an infinitely large number of servers
  * each server runs 1 task at a time
* batch sampling is better when $d \geq 1 / (1 - \rho)$
* multi-core environment assumption
  * probability that a core is idle is independent of whther other cores on the same machine are idle
  * scheduler places at most 1 task on each machine, even if multiple cores are idle
    * otherwise exacerbate "gold rush effect": many schedulers concurrently place tasks on an idle machine
  * $\rho \to \rho^c$



## Implementation

* ![1571726500528](D:\OneDrive\Pictures\Typora\1571726500528.png)

* components

  * ![1571727078514](D:\OneDrive\Pictures\Typora\1571727078514.png)
  * distributed set of schedulers (no communications in between)
  * Thrift remote procedure calls as service to scheduler API (multi-language)
    * list of task specifications
      * a list of constraints governing where the task can be placed
  * Sparrow node monitor per worker
    * federate resource usage on the worker by enqueuing reservations & requesting task specifications from schedulers when resources become available
    * fixed # of slots (configured based on the resources of underling machine)
  * frameworks: long-lived front-end & executor process
    * frontend: accept high level queries / job specifications from exogenous sources → parallel tasks
      * distributed over multiple machines
      * a scheduler on each machine where an application frontend is running to ensure minimum scheduling latency
    * executor process: executing tasks
      * long-lived to avoid startup overhead (binary shipping, caching large datasets in memory)
      * may co-resident on a single machine
        * node monitor deferates resource usage between co-located frameworks
        * `launchTask()` RPC from a local node monitor

* Spark on Sparrow

  * Spark frontend: compiles a functional query definition into multiple parallel stages
  * Each stage is submitted as a Sparrow job, including a list of task descriptions & associated placement constraints
  * [[Q: how to read outputs? by Spark worker?]]

* Fault tolerance

  * frameworks using failed scheduler → detect failure & connect backup scheduler → backup scheduler triggers callback at the application
  * Sparrow schedulers managing client → heartbeats with scheduler
  * in-flight tasks during scheduler failures
    * ignore failed task & process with a partial result
    * Spark: instantly relaunches any phases that were in-flight
  * frameworks elected to re-launch tasks must ensure that tasks are idempotent
  * designed for short jobs: simplicity benefit of no learning about in-progress jobs outweights the efficiency loss from needing to restart jobs (scheduled by the failed scheduler)
  * in-progress fail jobs: no handling.
  * worker failures: no handling, no persist scheduling state, just restart

* no safeguards against rogue schedulers

  * trust environment: ok
  * otherwise, authentication

  

## Limitations  & Future Work

* Scheduling policies: more exact policy enforcement without adding significant complexity
* Constraints: inter-job constraints?
* Gang scheduling: bin-packing, lacking central point, Sparrow may cause deadlock?
* Query-level policies: a user query may be composed of many stages that are each executed using a separate Sparrow scheduling request
* Worker failures: all schedulers with oustanding requests at that worker must be informed (centralized info!)
  * centralized state store relying on occasional heartbeats to maintain a list of currently alive workers
  * state store would perioidcally disseminate the list of live workers to all schedulers
  * soft state store
* Dynamically adapting the probe ratio: sacrifice some simplicity











![1571635381452](D:\OneDrive\Pictures\Typora\1571635381452.png)







## Motivation

* Large-scale data analytics frameworks nowadays target on low latency and low response time. The trend presents a challenge on schedulers for providing milisecond-latency and high availability on millions of parallel tasks. Centralized schedulers are difficult to support sub-second parallel tasks, since it schedules all tasks through a single one and require replication or recovery of large amounts of state.

## Summary

* In this paper, the authors present Sparrow, a stateless decentralized scheduler providing near-optimal performance comparing to omniscent schedulers. Sparrow uses power of two choices techniques with batch sampling and late binding to aggregation estimation of workers and trade network for accurate prediction. Framework frontends can communicate with distributed Sparrow schedulers and node monitors to place tasks on executors.

## Strength

* The stateless distributed decentralized design enables the high scalability of Sparrow schedulers.
* The use of batched sampling and late binding techniques provides accurate waiting time estimaton and near optimal task placement.

## Limitation & Solution

* The resources are split into fixed slots rather than elastically allocations
* Sparrow architecture can't handle worker failures since no persistent state or centralized point can be used to collect and spread informations.
* Sparrow will perform bad in unreliable network environment, since the RPC requests between workers and schedulers will be cost much.
  * Switch back to per-task sampling with batch sampling while network is detected to be unreliable.
* Sparrow can't do inter-job scheduling including inter-job batching, constraints.

