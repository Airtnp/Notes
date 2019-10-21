# Improving MapReduce Performance in Heterogeneous Environments 

**Matei Zaharia, Andy Konwinski, Anthony D. Joseph, Randy Katz, Ion Stoica**

------



## Introduction

- Hadoop performance ← task scheduler ← homogeneous assumption: cluster node homogeneous + task progress linearly
  - speculative execution, straggler
  - speculative tasks are not free (competing resources)
  - choosing the node to run a speculative task is important
  - heterogeneous environment → hard to distinguish between stragglers & normal
  - stragglers should be identified as early as possible
- virtualized data center → scheduler causing severe performance degradation in heterogeneous environments
  - virtualized resources with uncontrollable variations in performance
  - heterogeneous environments
- Longest Approximate Time to End (LATE): highly robust to heterogeneity
  - prioritizing tasks to speculate
  - selecting fast nodes to run on
  - capping speculative tasks to preventing thrashing



## Background: Scheduling in Hadoop

* ![1571346693188](D:\OneDrive\Pictures\Typora\1571346693188.png)

* speculation tasks
  * Hadoop monitors task progress using a progress score between 0 and 1
    * map: fraction of input data read
    * reduce: three phases, the score is the fraction in each phase
      * copy phase: fetching map outputs
      * sort phase: map outputs are sorted by key
      * reduce phase: user-defined function applied
  * looks at the average progress score of each category of tasks to define a threshold for speculative execution
    * task progress score is less than average for its category minus 0.2 → straggler
  * FIFO discipline for multiple jobs
  * homogeneous assumptions
    * nodes can perform work at roughly the same rate → breakdown virtualized data center
    * tasks progress at a constant rate throughout time → breakdown virtualized data center
    * no cost launching a speculative task on a node (which would otherwise having an idle slot) → breakdown homogeneous data center
    * task's progress score is representative of fraction of its total work that it has done. → breakdown homogeneous data center
    * tasks tend to finish in waves (a low progress score is likely a straggler) → breakdown homogeneous data center
    * tasks in the same category require roughly the same amount of work →  inherent in MapReduce paradigm



## How the Assumptions Break Down

* heterogeneity
  * non-virtualized data center: multiple generations of hardware
  * virtualized data center: co-location of VMs competing for disk & network bandwidth (EC2)
  * causing cascading speculative tasks
* shared resource → speculative tasks on idle nodes compete resources
* copy >> sort + reduce → fraction by progress score is inaccurate
  * will make copy phase reducers marked as straggler if average suddenly jumps to 100%
* lots of mappers starts in wave → different generations run in concurrent → progress score != progress rate
* 20% threshold → tasks with more than 80% progress can never be speculative executed



## The LATE Scheduler

* always speculatively execute the task what we think will finish farthest into the future
  * the greatest opportunity for a speculative copy to overtake the original and reduce jobs' response time
* default heuristic
  * estimate the progress rate of each task as `ProgressScore/T` (`T`: the amount of time the task has been running for)
  * estimate the time to completion as `(1 - ProgressScore) / ProgressRate`: assume tasks make progress at a roughly constant rate
* only launching speculative tasks on fast nodes
  * don't launch speculative tasks on nodes below `SlowNodeThreshold` of total work performed (sum of progress scores for all succeeded & in-progress tasks on the node). ~25th
* handle speculative task resource cost
  * `SpeculativeCap`: A cap on # of speculative tasks. ~10%
  * `SlowTaskThreshold`: progress rate is compared with to whether it is slow enough to speculated upon. ~25th
* LATE algorithm
  * If a node asks for a new task & fewer than `SpeculativeCap` speculative tasks running
    * Ignore the request if the node's total progress is below `SlowNodeThreshold`
    * Rank currently running tasks that are not currently being speculated by estimated time left.
    * Launching a copy of the highest-ranked task with progress rate below `SlowTaskThreshold`
  * assume map data-local, network utilization low
* Advantages
  * robust to node heterogeneity
    * relaunch only the slowest tasks, only small # of tasks
    * prioritize on how much they hurt job response time
    * cap # of speculative tasks to limit contention
  * decide where to run speculative tasks
  * focusing on estimated time left rather than progress rate
    * speculatively executes only tasks that will improve job response time rather than any slow tasks
* Estimating Finish Time
  * `(1 - ProgressScore) / ProgressRate`
  * misestimation / backfire
    * ![1571346679060](D:\OneDrive\Pictures\Typora\1571346679060.png)
    * progress rate slows down throughout its lifetime, not linearly related
    * but copy < sort + reduce and map is nearly constant



## Discussion

* increased interest from a variety of organizations in large-scale data-intensive computing, 
* decreased storage costs & availability of open-source frameworks & advent of virtualized data centers
* identify slow tasks → identify the tasks will hurt response time the most ASAP
* Make decisions early: rather than waiting to base decisions on measurement of mean & variance
* Use finishing times: not progress rates to prioritize among tasks to speculate
* Nodes are not equal: avoid assigning speculative tasks to slow nodes
* Resources are precious: Caps should be used to guard against overloading the system

















## Motivation

- Traditional Hadoop framework takes advantage of homogeneous assumption for scheduling tasks and do speculative backups. However, virtualized data center employs heterogeneous environment making it hard to distinguish bad and normal nodes and choose right node to placement tasks.

## Summary

- In this paper, the authors present a new scheduler for Hadoop called LATE (Longest Approximate Time to End). The LATE scheduler identifies the tasks that will hurt response the most by estimating the time to completion. It also prevents sending speculative tasks to slow nodes and overloading systems with speculative resource contentions. Therefore, the LATE scheduler can handle heterogeneous clusters like virtualized data center.

## Strength

- By adding caps and estimating the time left, the LATE scheduler solves the heterogeneous problem robustly without specifying special rules for heterogeneous environments. Instead it analyzes the assumptions in homogeneous Hadoop schedulers and improves the results by discarding some assumptions.

## Limitation & Solution

- The scheduler can't accurately estimate the time when different phases of computations costs monotonic increasing time. And it doesn't touch the reduce three phase fractions.
  - Use some heuristics to estimate fractions of each phases.
  - Maybe some splines to estimate the functions?
  - Static analysis for function complexity?