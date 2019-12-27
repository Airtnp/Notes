# Project Adam: Building an Efficient and Scalable Deep Learning Training System

**Trishul Chilimbi, Yutaka Suzue, Johnson Apacible, Karthik Kalyanaraman**

---



## Introduction

* ![image-20191106135410351](D:\OneDrive\Pictures\Typora\image-20191106135410351.png)
* ![image-20191106135430362](D:\OneDrive\Pictures\Typora\image-20191106135430362.png)
* ![image-20191106135816123](D:\OneDrive\Pictures\Typora\image-20191106135816123.png)
* ![image-20191106135831342](D:\OneDrive\Pictures\Typora\image-20191106135831342.png)



## Background

* ![image-20191106140537061](D:\OneDrive\Pictures\Typora\image-20191106140537061.png)
* Training
  * Feed-forward evaluation
    * ![image-20191106140826312](D:\OneDrive\Pictures\Typora\image-20191106140826312.png)
  * Back-propagation
    * ![image-20191106140840915](D:\OneDrive\Pictures\Typora\image-20191106140840915.png)
  * Weight updates
    * ![image-20191106140858316](D:\OneDrive\Pictures\Typora\image-20191106140858316.png)
* Distributed Deep Learning Training
  * ![image-20191106141140066](D:\OneDrive\Pictures\Typora\image-20191106141140066.png)



## Adam System Architecture

* ![image-20191106141441179](D:\OneDrive\Pictures\Typora\image-20191106141441179.png)
* Modern Training
  * multi-threaded
    * ![image-20191106143053577](D:\OneDrive\Pictures\Typora\image-20191106143053577.png)
    * ![image-20191106143106894](D:\OneDrive\Pictures\Typora\image-20191106143106894.png)
  * fast weight updates
    * no-lock, race, but can converge
  * reducing memory copies
    * pointer for local
    * asynchronous network IO for non-local
  * memory system optimizations
    * cache
  * stragglers
    * dataflow framework tracking
    * epoch-end manifests
    * 75% estimation
  * parameter server communication
    * ![image-20191106143656502](D:\OneDrive\Pictures\Typora\image-20191106143656502.png)
    * ![image-20191106143710800](D:\OneDrive\Pictures\Typora\image-20191106143710800.png)
* Global Parameter Server
  * ![image-20191106143734252](D:\OneDrive\Pictures\Typora\image-20191106143734252.png)
  * Throughput Optimizations
    * sharding
    * batch updates
    * SIMD
    * NUMA node locality
    * lock-free data structure / allocation
  * Delayed Persistence
    * write-back cache like asynchronously flushed
    * resilient nature of DL models
    * compress writes
  * Fault Tolerant Operations
    * 3 copy
    * Parameter server controller as Paxos cluster
  * Communication Isolation
    * 2 NICs for different paths 



## Motivation

* Large deep neural network is becoming popular due to state-of-the-art performance in many tasks. These models require time consuming computations and generate large amount of data for communication. We need a scalable, high performance, fault tolerant distribution solution for completing machine learning jobs.

## Summary

* In this paper, the authors present Project Adam, which is a Multi-Spert based large scale deep learning training framework. Project Adam consists of three parts, data serving machines (sharded data), model training machines (workers on local data) and a global parameter server (asynchronously shared model).  Project Adam employs many techniques, like multi-threading, lock-free data structures, NUMA-aware/cache-aware blocking/sharding, SIMD operations, batch updates, to improve the locality, throughput and reduce overhead on communications. Project Adam also implements fault tolerance by replication asynchronously.

## Strength

* Project Adam employs the resilient nature of machine learning models, to avoid synchronization and overhead lead by strong consistency (both local data race and global asynchronously update/write-back cache).
* Project Adam can send activation and error gradient instead of weight updates, to balance the computation between workers and parameter servers.

## Limitation & Solution

* Project Adam limits the computation model to weights updates.
* Project Adam has no method to limit the asynchronous nature as what Parameter Server does. Without vector clock timestamp, Project Adam can't do sequential, bounded delay updates.
  * Add vector clock timestamp?
* Project Adam doesn't specify how to elastically scale for worker/parameter server add/removal.