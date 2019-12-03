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

