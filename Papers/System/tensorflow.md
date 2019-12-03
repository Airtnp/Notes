# [TensorFlow: A system for large-scale machine learning](https://www.usenix.org/system/files/conference/osdi16/osdi16-abadi.pdf)

###### Martin Abadi, Paul Barham et al.

---

### What is the Problem? [Good papers generally solve *a single* problem]

* In recent years, machine learning has driven advances in many different fields and there are invention of more sophisticated machine learning models, availability of large datasets for tackling problems and developement of software platforms that enables the easy use of large amount of computational resources for training models on large datasets. Previous systems like DistBelief need global parameter server and lack of flexibility to define new layers, refining the training algorithms and defining new traning algorithms. 

### Summary [Up to 3 sentences]

* In this paper, the authors present TensorFlow, which is a machine learning system that operates at large scale and in heterogeneous environments. Tensorflow uses dataflow graphs to represent computation, shared state and operations that mutate the state.

### Key Insights [Up to 2 insights]

* Tensorflow is designed to support computation across multiple machines in a cluster or single machine with multiple computational devices including multicore CPUs, GPUs, custom-designed ASIC known as TPU (Tensor Processing Units)
* Unlike traditional dataflow systems in which graph vertices represent functional computation on immutable data, TensorFlow allows vertices to represent computations that own or update mutable state and unifies the computation and state management in a single programming model by representing individual functional operators, mutable states and updating operations as nodes in the dataflow graph.

### Notable Design Details/Strengths [Up to 2 details/strengths]

* A typical TensorFlow application has two distinct phases: first phase defines the program as symbolic dataflow graphs with placeholders for input data and variables; second phase executes an optimized version of the program on the set of available device. The deferred execution allows TensorFlow to optimize the execution by using global information about the computation.
* TensorFlow defines a common abstraction for devices, including issuing a kernel for execution, allocating memory for inputs and outputs, transferring buffers to and from host memory, and specific implementations on functional operators.

### Limitations/Weaknesses [up to 2 weaknesses]

* TensorFlow may have lower performance compared to some special hand-optimized operations and algorithms.
* TensorFlow is not able to do automatic optimization (including automatic placement, kernel fusion, memory management, scheduling) to achieve excellent performance without experts

### Summary of Key Results [Up to 3 results]

* TensorFlow is able to achieve high performance for single-machine and high throughput in clusters for asynchronous and synchronous training.

### Open Questions [Where to go from here?]

* The dataflow graph might be similar (duality?) to control flow graph, can we use highly-developed compiler techiniques (like using LLVM) to optimize them?

