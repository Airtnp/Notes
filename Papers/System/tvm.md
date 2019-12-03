# TVM: An Automated End-to-End Optimizing Compiler for Deep Learning  

**Tianqi Chen, Thierry Moreau, Ziheng Jiang et al.**

---

[[T: Relay paper]]

## Introduction

* machine learning on wide diversity of hardware devices
* TVM: graph-level, operator-level optimizations providing performance portability to deep learning workloads across diverse hardware back-ends
* ![image-20191106233935558](D:\OneDrive\Pictures\Typora\image-20191106233935558.png)
* ![image-20191106235014203](D:\OneDrive\Pictures\Typora\image-20191106235014203.png)
* computation graph → graph-level optimization → (hardware specific optimization) → operator-level optimization → hardware back-ends
* high-level specification → TVM → hardware backends
* ![image-20191107001558009](D:\OneDrive\Pictures\Typora\image-20191107001558009.png)
* ![image-20191107001811281](D:\OneDrive\Pictures\Typora\image-20191107001811281.png)
* Tensor expression langauge
  * build operators
  * provide program transformation primitives
  * ![image-20191107001854353](D:\OneDrive\Pictures\Typora\image-20191107001854353.png)
  * of valid programs for a given operator declaration
* Automated program optimization framework
  * ML-based cost model
* Graph rewriter
  * on top of automatic code generator
* ![image-20191107002014545](D:\OneDrive\Pictures\Typora\image-20191107002014545.png)



## Overview

* ![image-20191107002159537](D:\OneDrive\Pictures\Typora\image-20191107002159537.png)
* ![image-20191107002228841](D:\OneDrive\Pictures\Typora\image-20191107002228841.png)



## Optimizing Computational Graphs

* ![image-20191107002321424](D:\OneDrive\Pictures\Typora\image-20191107002321424.png)
* high-level vs low-level IR => intermediate data items are large, multi-dimensional tensors
* nodes: operation on tensors or program inputs
* edges: data dependencies between operations
* graph-level optimization
  * operator fusion: fuse multiple small operations together
    * ![image-20191107002633393](D:\OneDrive\Pictures\Typora\image-20191107002633393.png)
    * ![image-20191107002711937](D:\OneDrive\Pictures\Typora\image-20191107002711937.png)
  * constant-folding: pre-compute graph parts statically
  * static memory planning pass: pre-allocate memory to hold intermediate tensor
  * data layout transformation: internal data layouts into back-end-friendly forms
    * ![image-20191107002739177](D:\OneDrive\Pictures\Typora\image-20191107002739177.png)



## Generating Tensor Operations

* ![image-20191107002824713](D:\OneDrive\Pictures\Typora\image-20191107002824713.png)
* Tensor Expression & Schedule Space
  * ![image-20191107002913745](D:\OneDrive\Pictures\Typora\image-20191107002913745.png)
  * ![image-20191107003051593](D:\OneDrive\Pictures\Typora\image-20191107003051593.png)
  * ![image-20191107003103968](D:\OneDrive\Pictures\Typora\image-20191107003103968.png)
  * ![image-20191107003124377](D:\OneDrive\Pictures\Typora\image-20191107003124377.png)
  * ![image-20191107003154706](D:\OneDrive\Pictures\Typora\image-20191107003154706.png)
* Nested Parallelism with Cooperation
  * ![image-20191107003414250](D:\OneDrive\Pictures\Typora\image-20191107003414250.png)
  * ![image-20191107003420497](D:\OneDrive\Pictures\Typora\image-20191107003420497.png)
  * ![image-20191107003500033](D:\OneDrive\Pictures\Typora\image-20191107003500033.png)
  * ![image-20191107003508992](D:\OneDrive\Pictures\Typora\image-20191107003508992.png)
  * _memory score_: shared memory
    * automatic scope inference → compute stages as thread-local
    * shared task must compute dependencies of all working threads in the group
    * memory synchronization barrier isnerted as shared loaded data visible
    * tag special memory buffers, create special lowering rules when targeting specialized DL accelerators
* Tensorization
  * ![image-20191107005357737](D:\OneDrive\Pictures\Typora\image-20191107005357737.png)
  * Separating target hardware intrinsics from schedule with a mechanism for tensor-intrinsic declaration
    * ![image-20191107005509921](D:\OneDrive\Pictures\Typora\image-20191107005509921.png)
  * `tensorize` schedule primitive
    * replace unit of computation to cooresponding intrinsics
  * ![image-20191107005640041](D:\OneDrive\Pictures\Typora\image-20191107005640041.png)
* Explicit Memory Latency Hiding
  * ![image-20191107005709272](D:\OneDrive\Pictures\Typora\image-20191107005709272.png)
  * ![image-20191107005806633](D:\OneDrive\Pictures\Typora\image-20191107005806633.png)
  * ![image-20191107005857505](D:\OneDrive\Pictures\Typora\image-20191107005857505.png)
  * correct execution
  * virtual threading scheduling primitives
  * automatically lower program to a single instruction-stream with low-level explicit synchronization
  * ![image-20191107011115099](D:\OneDrive\Pictures\Typora\image-20191107011115099.png)
  * Hardware Evaluation of Latency Hiding
    * ![image-20191107014107401](D:\OneDrive\Pictures\Typora\image-20191107014107401.png)



## Automating Opimization

* ![image-20191107015525409](D:\OneDrive\Pictures\Typora\image-20191107015525409.png)
* ![image-20191107015602751](D:\OneDrive\Pictures\Typora\image-20191107015602751.png)
* Schedule Space Specification
  * ![image-20191107015621430](D:\OneDrive\Pictures\Typora\image-20191107015621430.png)
* ML-Based Cost Model
  * ![image-20191107015650175](D:\OneDrive\Pictures\Typora\image-20191107015650175.png)
  * ![image-20191107015734847](D:\OneDrive\Pictures\Typora\image-20191107015734847.png)
  * ![image-20191107015821350](D:\OneDrive\Pictures\Typora\image-20191107015821350.png)
  * ![image-20191107015936638](D:\OneDrive\Pictures\Typora\image-20191107015936638.png)
  * [[Q: how to update the hyperparameter & objective function in-place?]]
  * XGBoost gradient tree boosting model
    * memory access count
    * reuse ratio of each memory buffer at each loop level
    * one-hot encoding of loop annotations (vectorize, unroll, parallel)
  * TreeRNN model to summarize AST
  * ![image-20191107020339006](D:\OneDrive\Pictures\Typora\image-20191107020339006.png)
* Schedule Exploration
  * ![image-20191107020506703](D:\OneDrive\Pictures\Typora\image-20191107020506703.png)
  * ![image-20191107020900263](D:\OneDrive\Pictures\Typora\image-20191107020900263.png)
* Distributed Device Pool & RPC
  * ![image-20191107020918768](D:\OneDrive\Pictures\Typora\image-20191107020918768.png)
  * ![image-20191107020927414](D:\OneDrive\Pictures\Typora\image-20191107020927414.png)





## Conclusion

* End-to-end compilation stack
* Diverse set of hardware backends
* automated optimization









 ![img](D:\OneDrive\Pictures\Typora\1_nas0ZYQERStvXDUVV_JYsw.png) 





## Motivation

* There is a growing demands to deploy deep learning models onto diverse set of hardware backends (CPU, GPU, FPGA, ASIC). The backends diverge in memory organization, compute functional units, execution flows. Meanwhile, the existing DL frameworks rely on computation graph model intermeidate representation to implement optimizations such as auto differentiation and dynamic memory management. The graph-level optimizations are often too high-leve to handle hardware backend-specific operator-level transformations. For operator-level libraries, it requires significant work for tuning and porting across hardware devices. There is a gap between graph representation/optimization and operator calling/optimizations.

## Summary

* In this paper, the authors present TVM, an end-to-end deep learning compilation stack. TVM solves fundamental optimization challenges for deep learning across a diverse set of hardware backends by graph rewriting, graph optimization and automated optimizations. TVM can load computation graph models from various DL frameworks, then does high-level computational graph optimziations including operator fusion, constant folding, static memory planning and data layout transformation. The generated code is by generating tensor operators, optimizing schedules and lowering schedule to low level intrinsics. The operators are extensible for different hardware backends by a mechanism to introduce hardware intrinsics and `tensorize` schedule primtives. TVM will automatically analyze the data dependencies and memory scope to infer thread-local stages, synchronization points and explicit low-level synchronizations primitives in DAE accelerators. To find optimal operator implementations in the rich set of schedule primitives (including schedule transformations, like loop tiling, data caching), TVM builds an automated scheduler optimizer with a scheduler explorer proposing promising new configurationa nd a ML-based cost model predicting performances for given configurations. The scheduler explorer does a parallel simulated anneling algorithms for generating configurations. The ML-based cost model is written as a gradient tree boosting model which gets updated for each training epoch for collecting performance counters.

## Strength

* TVM builds a library for standard deep learning operators (TOPI) bridging different deep learning frameworks. TVM also provides a tensor operator description language for extending operations to diverse hardware backends.
* TVM not only optimizes at the computational graph level for opreator fusions, graph rewriting, but also automatically optimizes at tensor operator IR level and schedule level. 
* The automated optimization solves the general challenge of heterogeneity between hardware backends, including reducing communication (cache, bandwidth, disks, NUMA) and improve computations (SIMD, balancing instructions, CPU ILP parameters [E,g, number of issues, number of FP ports]).

## Limitation & Solution

* TVM doesn't touch the programming languages, or the DL framework level of deep learning model representation (control flow-level). To incorporate the actions like checkpointing, looping, whole program analysis (like quantization), TVM needs to expand its compilation stack to control flow, or programming languages, which can further eliminate the inefficiency of the Python interpreter.
  * [Relay](https://arxiv.org/pdf/1810.00952.pdf) is a new IR for ML frameworks, which employs partial evalutation, higher-order automatic differentiation, tensor type system and many functional programming optimizations on its lambda calculus-like IR representing the control flow of ML applications.

* Why gradient boosting tree model acts better? Can TVM use a even better schedule prediction by other machine learning / traditional models? Is the current performance counters enough to represent the workloads?
  * Need careful inspection on parameter solving space.
* How to quickly port new hardware to TVM? Do we have a easier way to map hardware intrinsics to TVM tensor operator description language?
* The paper doesn't talk much about the detail of tensor schedule transformations, like loop tiling and caching.
  * Maybe it's common sense in the compiler field.
* Will the automated optimization by directly running models on hardware incur large cost?
* How can we interpret the automated selected configurations?