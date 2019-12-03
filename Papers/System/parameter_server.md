# Scaling Distributed Machine Learning with the Parameter Server

  

**Mu Li, David G. Anderson, Jun Woo Park, Alexander J. Smola et al.**

---



## Introduction

* ![image-20191106120423118](D:\OneDrive\Pictures\Typora\image-20191106120423118.png)
* ![image-20191106120435022](D:\OneDrive\Pictures\Typora\image-20191106120435022.png)
* ![image-20191106120500672](D:\OneDrive\Pictures\Typora\image-20191106120500672.png)
* ![image-20191106120523966](D:\OneDrive\Pictures\Typora\image-20191106120523966.png)
* ![image-20191106120530198](D:\OneDrive\Pictures\Typora\image-20191106120530198.png)
* ![image-20191106121352382](D:\OneDrive\Pictures\Typora\image-20191106121352382.png)



## Machine Learning

* Risk Minimization
  * ![image-20191106121507399](D:\OneDrive\Pictures\Typora\image-20191106121507399.png)
  * ![image-20191106121515366](D:\OneDrive\Pictures\Typora\image-20191106121515366.png)
  * ![image-20191106121539478](D:\OneDrive\Pictures\Typora\image-20191106121539478.png)
  * ![image-20191106121546503](D:\OneDrive\Pictures\Typora\image-20191106121546503.png)
* Generative Models
  * ![image-20191106121639501](D:\OneDrive\Pictures\Typora\image-20191106121639501.png)



## Architecture

* ![image-20191106121701966](D:\OneDrive\Pictures\Typora\image-20191106121701966.png)
* ![image-20191106121743030](D:\OneDrive\Pictures\Typora\image-20191106121743030.png)
* (K, V) Vectors
  * model shared among nodes -> set of k-v pairs
  * ![image-20191106121855054](D:\OneDrive\Pictures\Typora\image-20191106121855054.png)
* Range Push & Pull
  * ![image-20191106121925950](D:\OneDrive\Pictures\Typora\image-20191106121925950.png)
* UDF on Server
  * ![image-20191106121937853](D:\OneDrive\Pictures\Typora\image-20191106121937853.png)
* Asynchronous Tasks & Dependency
  * ![image-20191106122522151](D:\OneDrive\Pictures\Typora\image-20191106122522151.png)
  * ![image-20191106122539998](D:\OneDrive\Pictures\Typora\image-20191106122539998.png)
* Flexible Consistency
  * ![image-20191106122600854](D:\OneDrive\Pictures\Typora\image-20191106122600854.png)
  * ![image-20191106122617990](D:\OneDrive\Pictures\Typora\image-20191106122617990.png)
  * ![image-20191106122628069](D:\OneDrive\Pictures\Typora\image-20191106122628069.png)
  * can be dynamic
* User-Defined Filters
  * selectively synchronize individual (k, v) pairs, allowing fine-grained control of data consistency within a task



## Implementation

* Vector Clock
  * ![image-20191106123135493](D:\OneDrive\Pictures\Typora\image-20191106123135493.png)
  * ![image-20191106123157726](D:\OneDrive\Pictures\Typora\image-20191106123157726.png)
  * ![image-20191106123203717](D:\OneDrive\Pictures\Typora\image-20191106123203717.png)
* Messages
  * ![image-20191106123225078](D:\OneDrive\Pictures\Typora\image-20191106123225078.png)
  * key-list cache
  * Snappy compression library
* Consistent Hashing
  * ![image-20191106123307933](D:\OneDrive\Pictures\Typora\image-20191106123307933.png)
  * ![image-20191106123325325](D:\OneDrive\Pictures\Typora\image-20191106123325325.png)
* Replication Consistency
  * ![image-20191106123344373](D:\OneDrive\Pictures\Typora\image-20191106123344373.png)
  * ![image-20191106123359301](D:\OneDrive\Pictures\Typora\image-20191106123359301.png)
  * ![image-20191106123405654](D:\OneDrive\Pictures\Typora\image-20191106123405654.png)
* Server Management
  * join/departure
  * ![image-20191106123522278](D:\OneDrive\Pictures\Typora\image-20191106123522278.png)
  * ![image-20191106123536510](D:\OneDrive\Pictures\Typora\image-20191106123536510.png)
  * double message is fine due to vector clocks
* Worker Management
  * ![image-20191106123634846](D:\OneDrive\Pictures\Typora\image-20191106123634846.png)
* 

















## Motivation

* Distributed optimization and inference becomes a prerequisite for solving large scale machine learning problems. It's not easy to implement an efficient distributed parameter sharing framework. The key challenges are communication and fault tolerance. The existing systems like Graphlab, REEF, Naiad fail to scale up to industrial needs.

## Summary

* In this paper, the authors present Parameter Server, the third generation open-source implementation of a parameter server for distributed inference. Parameter Server is based on asynchronous push and pull parameters from workers to masters. The messages are denoted with vector clock timestamps as versions and key-value pairs representing feature ID and parameter values. Parameter Server reduces communications by range update, compression and caching. Parameter Server manages its masters in a consistent hashing way and replicates the data to reach fault tolerance.

## Strength

* Parameter Server's asynchronous update model relaxes the consistency but improves the throughput and scalability.
* Parameter Server can support user-defined functions, filters on server node to do extra computations, which provides a global view of the machine learning jobs.
* Parameter Server handles master/worker node elastically changing elegantly by distributed hashing rings (like Amazon dynamo).
* Parameter Server task schedulers appear in each groups, which improves the scalability

## Limitation & Solution

* Parameter Server doesn't provide a flexible programming model, only push-pull k-v pairs.
  * Limited to machine-learning like jobs.
* What if the task scheduler fails? What if the resource manager fails? The paper doesn't mention them.
  * Maintain a soft-state by pulling states from workers / masters?

