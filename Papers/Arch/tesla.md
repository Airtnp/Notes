# Nvidia Tesla: A Unified Graphics And Computing Architecture

**Erik Lindholm, John Nickolls, Stuart Oberman, John Montrym**

---



## Introduction

* modern 3D graphics: fixed-function graphics pipeline $\to$ programmable parallel processor
* tranditional: separate programmable stages of 
  * vertex processors executing vertex shader programs
  * pixel fragment processors executing pixel shader programs
* Tesla, introduced in Nov. 2006, GeForce 8800
  * unfiy vertex & pixel processor
  * Compute Unified Device Architecture (CUDA) parallel programming model
  * unify graphcs & computing

### The Road to Unification

* GeForce 256: 1999
  * fixed-function 32-bit floating point vertex transform & lighting processor & fixed-function integer pixel-fragment pipeline
  * OpenGL, MS DX7 API
* GeFroce 3: 2001
  * 1st programmable vertex processor
  * configurable 32-bit FP fragment pipeline
  * OpenGL, DX8
* Radeon 9700, 2002
  * 24-bit FP pixel-fragment processor
  * OpenGL, DX9
* GeForce FX
  * 32-bit FP pixel-fragment processor
* vertex processor: vertices of primitives (points/lines/triangles)
  * transforming coordinates $\to$ setup unit, rasterizer $\to$ pixel-fragment, fill interior of primitives
  * setting up lighting/texture parameters $\to$ pixel-fragment processor
* vertex processor
  * low-latency
  * high-prec math ops.
  * complex ops.
  * 1st programmable
* pixel-fragment
  * high-latency
  * low-prec texture filtering
  * usually more pixels than vertices
* large triangle, vertex idle, pixel busy
* small triangle, vertex busy, pixel idle
* Tesla: vertex & pixel-fragment on same unified processor
  * dynamic load balancing of varying vertex- & pixel- processing workloads
  * permit introduction of new graphics shader stages
    * geometry shaders in DX10
  * sharing expensive units (e.g. texture units)
  * MS Direct3D DirectX 10 graphics API



## Tesla Architecture

* scalable processor array
* ![image-20200222161615896](D:\OneDrive\Pictures\Typora\image-20200222161615896.png)
* 128 streaming processor (SP) cores organized as 16 streaming multiprocessors (SM) in 8 independent processing units (texture/processor clusters, TPC)
* Workflow from top to bottom
  * host interface with system PCI-E bus
* GPU's scalable stremaing processor array (SPA): all GPU's programmable calculations
  * scalable memory: external DRAM control, fixed-function rater operation processors (ROPs, color/depth frame buffer operation)
  * interconnection network: SPA to ROPs, route texture mem. read requests from SPA to DRAM, read data from DRAM through a L2 cache back to SPA
* input assembler: collection vertex work, directed by input command stream
* vertex work distribution: distribute vertex work packets to various TPCs in the SPA
* TPC: execute vertex shader programs (+geometry shader programs)
  * output $\to$ on-chip buffers $\to$ viewport/clip/setup.raster/zcull block $\to$ pixel fragments
* pixel work distribution: distribute pixel fragments to TPCs for pixel fragmentation
  * output $\to$ interconnect network $\to$ ROP depth/color units
* compute work distribution: dispatch compute thread arrays to the TPCs
  * SPA accepts & processes work for multiple logical streams simultaneously
* multiple clock domains for GPU units/processors/DRAM/other units
  * independent power / performance optimizations



### Command Processing

* host interface unit
  * communicate with host CPU
  * respond to commands
  * fetch data from system memory
  * check command consistency
  * perform context switching
* input assembler
  * collect geometric primitives (points/lines/triangles/line strips/triangle strips)
  * fetch associated vertex input attribute data
  * peak rate of 1 primitive per clock
  * 8 scalar attributes per clock at the GPU core clock (~600MHz)
* work distribution unit
  * forward input assembler's output stream to SPA
  * round-robin scheme
    * pixel distributed based on pixel location



### Streaming Processor Array

* executes graphics shader thread programs & GPU computing programs
* provides thread control & management



### Texture/Processor Cluster

* ![image-20200222164243029](D:\OneDrive\Pictures\Typora\image-20200222164243029.png)
* 1 geometry controller
* 1 SM controller (SMC)
* 2 streaming multiprocessors (SMs)
  * 8 SP cores
* 1 texture unit
  * balance expected ratio of math operations to texture operations
  * 1 texture unit serve 2 SMs
  * can be varied
* ![image-20200222164419729](D:\OneDrive\Pictures\Typora\image-20200222164419729.png)



#### Geometry Controller

* map logically graphics vertex pipeline $\to$ recirculation on the physical SMs
  * directing all primitives & vertex attribute & topolofy flow in the TPC
* manage dedicated on-chip input/output vertex attribute storage & forward contents as required
* vertex shader processes one vertex’s attributes independently of other vertices.   
  * position space transforms 
  * color & texture coordinate generation  
* geometry shader follows the vertex shader and deals with a whole primitive and its vertices
  * edge extrusion for stencial shadow generation
  * cube map texture generation
  * output primitives $\to$ clipping/viewport transformation, rasterization into pixel fragments



#### Streaming Multiprocessor

* unified graphics and computing multiprocessor that executes vertex, geometry, and pixel-fragment shader
  programs and parallel computing programs.

* 8 streaming processor cores

  * 8 scalar multiply-add unit (MAD)
  * 1.5GHz (GeForce 8800)
  * 36 GFlops per SM

* 2 special function units (SFU)

  * transcendental functions/attribute interpolation
  * 4 FP multipliers
  * 1.5GHz (GeForce 8800)

* 1 multithreaded instruction fetch & issue unit (MT Issue)

* 1 instruction cache

* 1 read-only constant cache

* 16KB read/write shared memory

  * graphics input buffers / shared data for parallel computing
  * by low-latency interconnect network between SPs & shared-mem banks

* vertex/geometry/pixel threads have indep. IO buffers

* use TPC texture unit as 3rd execution unit

* use SMC/ROP units to implement external memory load/store/atomic accesses

* SM Multithreading

  * graphics vertex of pixel shader is a program for a single thread that describes how to process a vertex or a pixel
  * a CUDA kernel is a C program for a single thread that describes how one thread computes a result  
  * the unified SM concurrently executes different thread programs and different types of shader programs
  * hardware multithreaded (up to 768 concurrent threads)
  * each SM thread has its own thread execution state and can execute an independent code path
  * synchronize at a barrier with a single SM instruction
  * lightweight thread creation
  * zero-overhead thread scheduling
  * fast barrier synchronization support

* Single-instruction Multiple-thread (SIMT)

  * SIMT multithreaded instruction unit create/manage/schedule/execute threads in groups of 32 parallel threads (warps. from weaving, 1st parallel-thread technology)
  * Each SM manages a pool of 24 warps, total 768 threads
  * individual threads $\to$ SIMT warps of same type, start together at the same program address
    * free to branch & execute independently
  * SIMT multithreaded instruction unit selects a warp that is ready to execute and issue the next instruction to that warp's active threads at inst. issue time
  * SIMT inst. broadcast synchronously to a warp's active parallel threads; individual threads can be inactive due to independent branching/predication
  * map warp threads to SP cores, each thread executes independently
  * full efficiency if all 32 threads of a warp take the same exec. path
    * diverge by data dependent conditional branch $\to$ serially execute each branch path taken, disabling threads that are not on that path
    * when all paths complete $\to$ all threads reconverge to the original execution path
  * branch synchronization stack to manage indep. threads that diverge & converge
    * branch divergence only occurs within a warp
    * different warps executes independently
  * ![image-20200222195518136](D:\OneDrive\Pictures\Typora\image-20200222195518136.png)
  * similar to SIMD
    * SIMT: 1 inst. to multiple independent threads in parallel (not multiple data lanes), control the execution & branching behavior
      * TLP, transparent to programmer, but substantial when considering performance (like cache line size)
    * SIMD: control vec. of multiple data lanes together, expose vector width to the software
      * DLP, software managed

* SIMT warp scheduling

  * warp scheduler operates at half the 1.5-GHz processor clock rate

  * At each cycle, it selects one of the 24 warps to execute a SIMT warp instruction 

  * An issued warp instruction executes as 2 sets of 16 threads over 4 processor cycles

    * [[Q: that's why half-warp is considered when measuring coalescing/divergent branching/bank conflicts?]]

    * 8 SP, pipelined, 4 stages (cycles) $\to$ 1 warp (32 threads for 1 instruction)

      * cycle1: issue half-warp to 8 SPs, execute 8 insts. (pre Fermi, Fermi has at least 32 SPs per SM)
      * cycle2; issue half-warp to 8 SPs, execute last 8
      * cycle 3-4, execute rest 16

    * > The stream processors are pipelined, so in fact many warps are in various stages of execution at any given time. The job of the scheduler on the multiprocessor is to grab warps that are not waiting on global memory reads and stuff them into the pipeline to begin executing their next instruction. Although a multiprocessor can *complete* an entire warp instruction (with some exceptions) every 4 clock cycles, it in fact takes many more than 4 clock cycles for a given warp instruction from beginning to end.
      >
      > 
      >
      > Every modern CPU works this way, except single-threaded code is much more likely to have "pipeline hazards", where the next instruction in the thread depends on the one before it in such a way that you can't stuff it into the pipeline next. By encouraging large numbers of independent instructions (i.e., threads don't usually talk to each other), a CUDA device can keep pipelines full without all the instruction reordering fanciness (and therefore transistor cost) of a CPU.
      >
      > 
      >
      > 1. The principal usage of "half-warp" was applied to CUDA processors prior to the Fermi generation (e.g. the "Tesla" or GT200 generation, and the original G80/G92 generation). [These GPUs were architected with a SM (streaming multiprocessor -- a HW block inside the GPU) that had fewer than 32 thread processors](http://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#architecture-1-x). The definition of warp was still the same, but the actual HW execution took place in "half-warps" at a time. Actually the granular details are more complicated than this, but suffice it to say that the execution model caused memory requests to be issued according to the needs of a half-warp, i.e. 16 threads within the warp. A full warp that hit a memory transaction would thus generate a total of 2 requests for that transaction.
      >
      >    [Fermi and newer GPUs have at least 32 thread processors per SM](http://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#compute-capability-2-x). Therefore a memory transaction is immediately visible across a full warp. As a result, memory requests are issued at the per-warp level, rather than per-half-warp. However, a full memory request can only retrieve 128 bytes at a time. Therefore, for data sizes larger than 32 bits per thread per transaction, the memory controller may still break the request down into a half-warp size.
      >
      >    My view is that, especially for a beginner, it's not necessary to have a detailed understanding of half-warp. It's generally sufficient to understand that it refers to a group of 16 threads executing together and it has implications for memory requests.
      >
      >    
      >
      > 2. Shared memory for example on the [Fermi-class GPUs](http://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#shared-memory-2-x) is broken into 32 banks. On [previous GPUs](http://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#shared-memory-1-x) it was broken into 16 banks. Bank conflicts occur any time an individual bank is accessed by more than one thread in the same memory request (i.e. originating from the same code instruction). To avoid bank conflicts, basic strategies are very similar to the strategies for coalescing memory requests, eg. for global memory. On Fermi and newer GPUs, multiple threads can read the same *address* without causing a bank conflict, but in general the *definition* of a bank conflict is when multiple threads read from the same bank. For further understanding of shared memory and how to avoid bank conflicts, I would recommend the [NVIDIA webinar](https://developer.nvidia.com/gpu-computing-webinars) on [this topic](http://developer.download.nvidia.com/CUDA/training/sharedmemoryusage_july2011.mp4).
      >
      > 

      

  * scoreboard qualifies each warp for issue each cycle

  * prioritize all ready warps & selects the one with highest priority for issue

    * warp types
    * instruction type
    * fairness

* SM instructions

  * execute scalar inst. (for simplicity)
  * texture inst. remain vector-based
  * high-level graphics & computing language compiler generate IR (DX10 vector, PTX scalar inst.) $\to$ binary GPU inst. $\to$ Tesla SM scalar inst. 
  * PTX: 1-to-1 Tesla SM inst., stable target ISA for compiler, compatibility
  * virtual regs $\to$ real register
  * fold inst. when fesiable

* ISA

  * register-based inst. set (FP, INT, bit, conversion, transcendental, flow control, memory load/store, texture operations)
  * FP/INT: add, multiply, MA, min, max, compare, set preidcate, conversions
    * source operands modifiers for negation & absolute value
    * per-thread status flag, zero/neg/carry/overflow
  * Transcendental: cosine, sine, binary expoential, binary log, reciprocal, square root
  * Attribute interpolation: generation of pixel attributes
  * Bitwise operator: shift left, shift right, logical operations, move
  * Control flow: branch, call, return, trap, barrier

* Memory access instructions

  * tecture inst. fetch/filter tecture samples from mem via. texture unit
  * ROP unit write pixel-fragment output to mem.
  * memory load/store: integer byte addressing with register-plus-offset address arithmetic to facilitate conventional compiler code optimizations
  * 3 read/write memory spaces
    * local memory for per-thread, private, temporary data (external DRAM)
    * shared memory for low-latency access to data shared by cooperating threads in the same SM
    * global memory for data shared by all threads of a computing application (external DRAM)
  * barrier to communicate with each other via shared/global memory
  * memory bandwidth & reduce overhead $\to$ local/global load/store instructions coalesce invidual parallel thread accesses from the same warp into fewer memory block accesses
  * The large thread count, together with support for many outstanding load requests, helps cover load-to-use latency for local/global memory implemented in external DRAM
  * atomic memory op: INT add, min, max, logic op, swap, CAS

* Streaming processor

  * IEEE754 FP
  * round-to-neartest even as default rounding mode
  * The SP flushes denormal source operands to sign-preserved zero and flushes results that underflow the target output exponent range to sign-preserved zero after rounding  

* Special function unit

  * transcendental functions and planar attribute interpolation
  * quadratic interpolation based on enhanced minimax approximations to approximate the reciprocal, reciprocal square root, log2x, $2^x$, and sin/cos function  
  * 1 32-bit FP result per cycle
  * ![image-20200223005558830](D:\OneDrive\Pictures\Typora\image-20200223005558830.png)
  * attribute interpolation, to enable accurate interpolation of attributes such as color, depth, and texture coordinates.  
  * ![image-20200223005630319](D:\OneDrive\Pictures\Typora\image-20200223005630319.png)

* SM controller

  * control multiple SMs
  * arbitrating the shared texture unit, load/store path, I/O path
  * 3 graphics workloads simulaneously (vertex, geo-, pixel)
  * ![image-20200223005729047](D:\OneDrive\Pictures\Typora\image-20200223005729047.png)

### Texture Unit

* The texture unit processes one group of four threads (vertex, geometry, pixel, or compute) per cycle  
* Texture instruction sources are texture coordinates, and the outputs are filtered samples, typically a
  four-component (RGBA) color. 
* Texture is a separate unit external to the SM connected via the SMC. The issuing SM thread can continue execution until a data dependency stall.  
* 4 texture addr generators
* 8 filter units
* 38.4 GBilerps/s (binarylinear interpolation of 4 samples) for GeForce 8800
* Each unit supports full-speed 2:1 anisotropic filtering, as well as highdynamic-range (HDR) 16-bit and 32-bit floating-point data format filtering  
* deeply pipelined



### Rasterization

* ![image-20200223010153865](D:\OneDrive\Pictures\Typora\image-20200223010153865.png)
* ![image-20200223010201969](D:\OneDrive\Pictures\Typora\image-20200223010201969.png)
* ![image-20200223010206127](D:\OneDrive\Pictures\Typora\image-20200223010206127.png)



#### Raster operations processor

* ![image-20200223010230952](D:\OneDrive\Pictures\Typora\image-20200223010230952.png)
* ![image-20200223010237145](D:\OneDrive\Pictures\Typora\image-20200223010237145.png)
* ![image-20200223010243521](D:\OneDrive\Pictures\Typora\image-20200223010243521.png)
* ![image-20200223010252943](D:\OneDrive\Pictures\Typora\image-20200223010252943.png)
* ![image-20200223010301689](D:\OneDrive\Pictures\Typora\image-20200223010301689.png)



### Memory & Interconnect

* ![image-20200223010319330](D:\OneDrive\Pictures\Typora\image-20200223010319330.png)
* ![image-20200223010327121](D:\OneDrive\Pictures\Typora\image-20200223010327121.png)
* ![image-20200223010334279](D:\OneDrive\Pictures\Typora\image-20200223010334279.png)
* ![image-20200223010342559](D:\OneDrive\Pictures\Typora\image-20200223010342559.png)



## Parallel Computing Architecture

* extensive data parallelism—thousands of computations on independent data elements;
* modest task parallelism—groups of threads execute the same program, and different groups can run different programs;
* intensive floating-point arithmetic; latency tolerance—performance is the amount of work completed in a given time;
* streaming data flow—requires high memory bandwidth with relatively little data reuse;
* modest inter-thread synchronization and communication—graphics threads do not communicate, and parallel computing applications require limited synchronization and communication.  



### Data-parallel Problem Decomposition

* ![image-20200223011823502](D:\OneDrive\Pictures\Typora\image-20200223011823502.png)
* Parallel SMs compute result blocks
* Parallel threads compute result elements  



### Cooperative Thread Array / Thread Block



* CTA / TB in CUDA terminology
* ![image-20200223012315524](D:\OneDrive\Pictures\Typora\image-20200223012315524.png)
* CTA grids
  * ![image-20200223012353772](D:\OneDrive\Pictures\Typora\image-20200223012353772.png)
* Parallel granularity
  * ![image-20200223012634083](D:\OneDrive\Pictures\Typora\image-20200223012634083.png)
  * thread: computes result elements selected by its TID
  * CTA: computes result blocks selected by its CTA ID
  * grid: computes many result blocks, and sequential grids compute sequentially dependent application steps
  * higher: multiple GPU per GPU/cluters of multi-GPUs
* Parallel memory sharing
  * local: each executing thread has a private per-thread local memory for register spill, stack frame, and addressable temporary variables  
  * shared: each executing CTA has a per-CTA shared memory for access to data shared by threads in the same CTA
  * global: sequential grids communicate and share large data sets in global memory
  * fast barrier synchronization instruction to wait for writes to shared or global memory to complete before reading data written by other threads in the CTA  
  * relaxed memory order
    * preserves the order of reads and writes to the same address 
      * from the same issuing thread
      * from the viewpoint of CTA threads coordinating with the barrier synchronization instruction  
  * Sequentially dependent grids use a global intergrid synchronization barrier between grids to ensure global read/write ordering
    * [[Q: actually CUDA don't support it?]]
    * [question-on-inter-block-sync](https://devtalk.nvidia.com/default/topic/570147/inter-block-synchronization/)
* Transparent scaling of GPU computing
  * The key is decomposing the problem into independently computed blocks as described earlier. The GPU compute work distribution unit generates a stream of CTAs and distributes them to available
    SMs to compute each independent block. Scalable programs do not communicate among CTA blocks of the same grid; the same grid result is obtained if the CTAs execute in parallel on many cores, sequentially on one core, or partially in parallel on a few cores.



## CUDA Programming Model

* ![image-20200223014816601](D:\OneDrive\Pictures\Typora\image-20200223014816601.png)
* ![image-20200223014828317](D:\OneDrive\Pictures\Typora\image-20200223014828317.png)
* Single-Program Multiple-Data (SPMD) software model
  * but more flexible, kernel call dynamically creates a new grid with the right number of thread blocks & threads for that application step
* `__global__`: kernel entry functions
* `__device__`: global variables
* `__shared__`: shared-memory variables
* `threadIdx.{x, y, z}`: thread ID within a thread block (CTA)
* `blockIdx.{x, y, z}`: CTA ID within a grid
* `kernel<<<nBlocks, nThreads>>>(args)`
* ![image-20200223015047198](D:\OneDrive\Pictures\Typora\image-20200223015047198.png)



## Scalability & Performance

* ![image-20200223015117869](D:\OneDrive\Pictures\Typora\image-20200223015117869.png)
* NVIDIA’s Scalable Link Interconnect (SLI) enables multiple GPUs to act together as one, providing further
  scalability
* ![image-20200223015207741](D:\OneDrive\Pictures\Typora\image-20200223015207741.png)
* ![image-20200223015216645](D:\OneDrive\Pictures\Typora\image-20200223015216645.png)
* ![image-20200223015400101](D:\OneDrive\Pictures\Typora\image-20200223015400101.png)





* CS251A requirements
  * a short paragraph summarizing the problem and goal/contributions of paper
  * a short paragraph summarizing the paper’s methods and results
  * a short paragraph giving your opinion of what is good and bad about the paper.

## Summary

- This paper describes a brand new GPU architecture that unifies the traditional vertex and pixel processors and extends for generalized SIMT computing with the CUDA programming model. In the old GPUs, the vertex and pixel-fragment processors are designed for different tasks and operations. Tesla architecture solves the problem by providing a unification enabling dynamic load balancing and sharing of expensive hardware.

## Methods & Results

- Tesla architecture unifies the vertex and pixel-fragment processors by scalable processor array. The program commands are processed at the frontend (host interface, assembler, work distribution units), and all computations are done on the same multi-level processing units (Texture/Processor Clusters, Streaming Multiprocessors, Streaming Processors). All computation units are interconnected by a single PCI-Express bus. Streaming multiprocessors dispatch instructions in the single-instruction multiple thread (SIMT) fashions, combining threads into warps that execute the same instruction. Compilers can convert DX10 vector or PTX scalar instructions to Tesla SM register-based instructions, which contain FP, INT, transcendental, interpolation, bitwise, control instructions. CUDA provides an extension to C programming language for programming GPU. The global work is split into thread blocks (cooperative thread array, CTA) which is an array of concurrent threads executing the same thread program. The thread blocks are divided into threads which computing result elements selected by its TID. Meanwhile, the memory consists corresponding levels: global memory for whole grids; shared memory for each thread block residing in the SM; local memory for each executing thread for register spilling, temporary variables, execution state. The experiment shows that GeForce GPUs/Quadro workstations can give 100X speedup on modular modeling, more than 200GFlops on n-body problems and real-time 3D magnetic resonance imaging.

## Personal Opinions

- For me, this is a solid paper providing so many details on how GPU implements. However, it lacks some performance results and implementation details. For example, how do the warp dispatching and SP pipeline implement? Why does the scoreboard algorithm fit the SIMT scheme (or is it the same as CDC 6600 scoreboard?). Also, it lacks some explanation on other details, like constant cache, cache hierarchy, PTX instruction mapping, scratchpad cache, shared memory banks, etc. Furthermore, SIMT architecture might not be able to handle task-based parallelism or dynamic scheduling programs. For example, for Barnes-Hut algorithms which utilize semi-static assignments or non-uniform working sets, the simple SIMT scheme can't work well. Actually, now GPU has dynamic parallel (at least for [NVIDIA](https://devblogs.nvidia.com/introduction-cuda-dynamic-parallelism/))



