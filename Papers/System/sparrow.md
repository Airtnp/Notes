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
* place 1 of the job's $m$ tasks on each of the $m$ least loaded workers
* 0.73x better than per-task
* [[Q: batching across jobs?]]
* [[Q: locality issues?]]



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

* 













![1571635381452](D:\OneDrive\Pictures\Typora\1571635381452.png)







## Motivation

* Large-scale data analytics frameworks nowadays target on low latency and low response time. The trend presents a challenge on schedulers for providing milisecond-latency and high availability on millions of parallel tasks. Centralized schedulers are difficult to support sub-second parallel tasks, since it schedules all tasks through a single one and require replication or recovery of large amounts of state.

## Summary

## Strength

## Limitation & Solution



