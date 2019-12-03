# [Dandelion: a Compiler and Runtime for Heterogeneous Systems](https://www.cl.cam.ac.uk/~ey204/teaching/ACS/R212_2015_2016/papers/rossback_sosp_2013.pdf)

###### Christopher J. Rossbach, Yuan Yu, Jon Currey, Jean-Philippe Martin, and Dennis Fetterly

---

### What is the Problem? [Good papers generally solve *a single* problem]

* Computer system increasingly rely on heterogeneity to achieve greater performance, scalability and energy efficiency. However, programming heterogeneous systems remains challenging because of multiple execution contexts with different programming abstraction and runtimes.

### Summary [Up to 3 sentences]

* In this paper, the authors present Dandelion, a system designed for writing data-parallel applications for hererogeneous systems. At the programming language level, Dandelion uses LINQ and develops a new general purpose cross compiler framework based on .NET on multiple back-ends. At the runtime level, Dandelion adopts the dataflow execution model with several execution engines and asynchronous communication channels managed by Dandelion.

### Key Insights [Up to 2 insights]

* At the programming language level, language integration approach is the most attractive abstraction.
* At the runtime level, architectural heterogeneity demands the system's multiple execution contexts interoperator and compose seamlessly.

### Notable Design Details/Strengths [Up to 2 details/strengths]

* Dandelion embeds a rich set of data-parallel operators using the LINQ language integration framework, which provides a single unified programming frond-end for programmers in C# or F#.
* Dandelion has three layers of runtime: cluster execution engine (Dryad/Moxie) assigns dataflow vertices to available machines and distributes code and graphs; machine execution engines executes its own dataflow graph, managing IO and execution threas; CPU/GPUs runs the dataflow vertices via dataflow engine (PTask).
* To deal with GPU limitations on dynamic allocation and variable-length records, Dandelion does static analysis and collects metadata to try to avoid it and falls back to execute on the CPU.

### Limitations/Weaknesses [up to 2 weaknesses]

* All user-defined functions invoked by LINQ operators must be side-effect free.
* Low-level GPU runtimes have limited support for dynamic memory allocation, so Dandelion doesn't kernelize functions containing dynamic memory allocation and execution only happens on CPUs.

### Summary of Key Results [Up to 3 results]

* Dandelion is able to reach higher performance on a single machine over sequential CPU with different versions of Dandelion including parallel CPU, GPU enabled and GPU enabled with memory allocation hints Dandelion.
* Dandelion is able to reach higher performance on distributed machines over sequential CPU and DyradLINQ with support of GPUs or parallel CPUs.

### Open Questions [Where to go from here?]

* The paper doesn't talk about the heterogenity systems on FPGAs and ASICs. How to apply dataflow engine on special purpose integrated circuits?
* Why LINQ is used commonly here? Can we purpose a better programming language model?
