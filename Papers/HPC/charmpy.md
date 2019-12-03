# CharmPy: A Python Parallel Programming Model  

**Juan J. Galvez, Karthik Senthil, Laxmikant V. Kale**

---



## Introduction

* CharmPy: parallel programming model & framework
  * high-level model
  * distributed migratable objects
  * Charm++: C++ runtime
    * dynamic load balancing
    * asynchronous execution model with automatically overlap of computation/communication
    * high performance
    * scalability
* Programming model requirement
  * accessibility (easy to approach, learn, use)
  * productivity
  * high-level abstraction hiding details
  * good performance
  * efficient use of resources in heterogeneous environment
  * portability
  * easy to integrate
* CharmPy achievement
  * Simple, HLL
  * Widely used Python PL
  * General-purpose
  * High perf
  * Scalable
  * overlap comm/comp
  * adaptive runtime features



## CharmPy Programming Model

* distributed migratable objects with asynchronous remote method invocation

* program → objects + interactions

* multiple distributed objects per processing elements (PE)

  * communicate with any other distributed objects via remote method invocation (message passing)

* decomposition based on objects

  * arbitrary number of objects per process can exist
  * allow for tunable fine-grained decomposition without affecting the structure of the program

* asynchronous execution model: process not block waiting for remote method to complete, runtime scheduling

  * presence of multiple objects per PE
  * hide latency, overlap communication & computation

* Chare, distributed object

  * `class MyChare(Chare):`

  * runtime initialization → charm

  * ```python
    from charmpy import *
    
    class MyChare(Chare):
        def SayHi(self, msg):
            print(msg)
            charm.exit()
    
    def main(args):
        proxy = Chare(MyChare, onPE=-1)
        proxy.SayHi('Hello')
    
    charm.start(main)
    ```

* Collections of chares

  * Arrays: collections of chares indexed by keys, with members being able to exist anywhere in the system

  * Groups: where there is one member per PE

  * ```python
    proxy = Group(ChareClass, args=[x, y, ...])
    proxy = Array(ChareClass, Index..., args=[x, y, ...])
    ```

  * a given chare class can be used to create groups or any types of array (not same in Charm++, tied at declaration time)

  * _proxy_: used for call methods of its members

    * references all of ths members of the collection
    * broadcast invocation
    * indexing by `__getitem__`

  * `thisIndex`, `thisProxy`

* Remote method invocation

  * `proxy.method(arg0, arg1, ...)`
  * entry method: method invoked on a chare as a result of a remote call
    * message passing
    * serialize arguments / pass by reference + zero payload (same address?)
    * caller must give up ownership of arguments
      * specific to CharmPy
      * but Charm++ can use `inline`
  * `future = proxy.method(args, ret=True)`
  * `future.get()`

* Message order & dependencies

  * `@when('condition')`
  * automatically buffer message at the receiver
  * deliver only when condition is met
  * [WIP]: sender side per-message condition

* Reduction

  * `self.contribute(data, reducer, target)`

  * all the chares in a collection must call this method

  * `data`: data contributed by the chare for reduction

  * `reducer`: function that is applied to the set of contributed data

  * `target`: who receives the result of the reduction (method of chare / set of chares)

    * `proxy.method`

  * empty: `data=None` or `reducer=None`

    * for synchronous?

  * ```python
    class Worker(Chare):
        def work(self, data):
            data = numpy.arrange(20)
            self.contribute(data, Reducer.sum, self.thisProxy[0].getResult)
        def getResult(self, result):
            print(result)
            charm.exit()
            
    def main(args):
        array = Array(Worker, 100)
        array.work()
        
    charm.start(main)    
    ```

  * custom reducers: `Reducer.addReducer(myFunc)`

* Chare arrays

  * `proxy = Array(ChareClass, dims, args)`
  * or sparse `proxy = Array(ChareClass, ndims=n, args)`
    * `proxy.ckInsert(index, args)`
    * `proxy.ckDoneInserting()`
  * ArrayMaps: mapping of chares to PEs is by default decided by the runtime
    * `def procNum(self, index) -> int` mapping

* Waiting for events

  * Threaded entry methods `@threaded`
    * pausing execution of the entry methods to wait for certain events
    * run in own thread
  * Wait for chare state `wait`
    * `self.wait('condition')`, like CV
    * ![image-20191101203901051](D:\OneDrive\Pictures\Typora\image-20191101203901051.png)
  * Futures: object acts as a proxy for a result that is initially unknown
    * ![image-20191101204022051](D:\OneDrive\Pictures\Typora\image-20191101204022051.png)

* Chare migration

  * migrate from 1 process to another
    * place communicating chares in the same process/host/nearby host
    * balance computational load
  * `self.migrate(toPe)`
  * serialize, migrating, message delivered
    * pickle library `__getstate__` / `__setstate__`

* Automatic load balancing

  * load of chares, calculate new assignment of chares to PEs, migration



## Use Case: Distributed Parallel Map with Concurrent Jobs

* ![image-20191101204827370](D:\OneDrive\Pictures\Typora\image-20191101204827370.png)
* ![image-20191101204838569](D:\OneDrive\Pictures\Typora\image-20191101204838569.png)
* ![image-20191101204910554](D:\OneDrive\Pictures\Typora\image-20191101204910554.png)
* ![image-20191101204927626](D:\OneDrive\Pictures\Typora\image-20191101204927626.png)
* [[Q: why so bad in programming?]]
* MPI-equivalent code (low-level)
  * asynchronous communication
  * ability to receive messages of different types from any source, at any time, deliver to multiple destinations
  * threads
* Parallelism
  * multiple processes on clusters & supercomputers
  * GIL problem? multiple processes (PEs) / external code of interpreter (MKL, OpenMP, JIT)
* Serialization
  * metadata for contiguous memory layouts
  * pickle module: UDT
* Message passing
  * MPI, Intel OFI, Cray GNI, IBM PAMI
* Reductions
  * common functions with primitive data types → Charm++ runtime
    * CharmPy → Charm++ reduction → Charmpy -compliant message → target
    * distributed fashion, topology-aware spanning trees
    * [[Q: user-defined reduction modules?]]
* Cython implementaton of CharmPy
  * C-extension modules
  * Cython + Python + Pyres → C-extension module



## Conclusion

* Python language + Charm++
* distributed migratable objects with asynchronous message-driven execution
* dynamic load balancing
* automatic overlap of comp/comm
* fault-tolerance
* shrink-expand
* power/temp optim.
* support for heterogeneous computing



![image-20191101232159690](D:\OneDrive\Pictures\Typora\image-20191101232159690.png)



![image-20191101232212622](D:\OneDrive\Pictures\Typora\image-20191101232212622.png)















## Motivation

## Summary

## Strength

## Limitation & Solution



