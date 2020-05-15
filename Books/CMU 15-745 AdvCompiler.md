# Advanced Compiler

[spring19](http://www.cs.cmu.edu/afs/cs/academic/class/15745-s19/www/lectures/L1-Intro.pdf)





## Introduction

* ![image-20200429141341497](D:\OneDrive\Pictures\Typora\image-20200429141341497.png)
  * [[N: contextual refinement? lol]]
* Ingredients
  * Formulate optimization problem
    * Identify opportunities of optimization
      * applicable across many programs
      * affect key parts of the program (loops/recursions) 
      * amenable to “efficient enough” algorithm
  * Representation
    * Must abstract essential details relevant to optimization
  * Analysis
    * Detect when it is desirable and safe to apply transformation
  * Code Transformation
  * Evaluation
* 3-addr IR
  * `A := B op C`
* basic block: a sequence of 3-addr statements
  * only the first statement can be reached from outside the block (no branches into middle of block)
  * all the statements are executed consecutively if the first one is (no branches out or halts except perhaps at end of block)
  * maximal:  cannot be made larger without violating the conditions
  * local scope
  * split by call dest./src.
    * Identify the leader of each basic block
      * First instruction
      * Any target of a jump
      * Any instruction immediately following a jump
    * Basic block starts at leader & ends at instruction immediately before a leader (or the last instruction)
* flow graphs
  * basic block nodes
  * edges: `Bi -> Bj` iff. `Bj` can follow `Bi` immediately in some execution
* optimizations
  * algorithm
  * algebraic: `B + 0 => B`
  * local: within a basic block/across inst.
    * local common subexpression elimination
    * local constant folding or elimination
    * dead code elimination
  * global/intraprocedural: within a flow graph/across basic block
    * global versions of local optimizations
    * loop optimizations
      * reduce code to be executed in each iteration (loop hoisting)
      * code motion
        * a computation is done within a loop and result of the computation is the same as long as we keep going around the loop
        * move the computation outside the loop
      * induction variable elimination
        * Loop indices are induction variables (counting iterations)
        * Linear functions of the loop indices are also induction variables (for accessing arrays)
        * strength reduction: replace multiplication by additions
        * elimination of loop index: replace termination by tests on other induction variables
    * control structures
      * cost hoisting: eliminates copies of identical code on parallel paths in a flow graph to reduce code size
  * interprocedural: within a program/across procedures (flow graphs)
* machine dependent optimizations
  * register allocation
  * instruction scheduling
  * memory hierarchy optimizations



## LLVM Compiler

* The LLVM Compiler Infrastructure
  * Provides reusable components for building compilers
  * Reduce the time/cost to build a new compiler
  * Build different kinds of compilers
  * There are also JITs, trace-based optimizers, etc.
* The LLVM Compiler Framework
  * End-to-end compilers using the LLVM infrastructure
  * Support for C and C++ is robust and aggressive
  * Java, Scheme and others are in development
  * Emit C code or native code for x86, SPARC, PowerPC
* LLVM Intermediate Form: virtual instruction set
  * language/target-independent
  * IR & external (persistent) presentation
* ![image-20200429142830407](D:\OneDrive\Pictures\Typora\image-20200429142830407.png)
* ![image-20200429143418201](D:\OneDrive\Pictures\Typora\image-20200429143418201.png)
* Link-Time Optimization
  * ![image-20200429143453246](D:\OneDrive\Pictures\Typora\image-20200429143453246.png)
* LLVM instruction set
  * low-level & target-indep. semantics
    * RISC-like 3-addr code
    * infinite virtual reg. set in SSA form
    * simple, low-level control flow constructs
    * load/store inst. with typed-pointers
  * high-level information exposed in the code
    * Explicit dataflow through SSA form
    * Explicit control-flow graph
    * Explicit language-independent type-information
    * Explicit typed pointer arithmetic
    * Preserves array subscript and structure indexing
* Lowering
  * rich type sys `->` simple types
    * primitives: label/void/float/integer (arbitrary bitwidth)
    * derived: pointer/array/structure/function (union `->` cast)
  * implicit/abstract types `->` explict/concrete
  * `T& -> T*, Complex -> {float, float}, {int x:4; z:2} -> {i32}`
* ![image-20200429143839703](D:\OneDrive\Pictures\Typora\image-20200429143839703.png)
  * instruction `<->` value (SSA form + 3-addr IR so it makes sense)
  * ![image-20200429144619519](D:\OneDrive\Pictures\Typora\image-20200429144619519.png)
* LLVM Program Structure
  * Module contains `Functions` and `GlobalVariables`
    * Module is a unit of analysis, compilation, and optimization
  * Function contains `BasicBlocks` and `Arguments`
    * Functions roughly correspond to functions in C
  * BasicBlock contains a list of `Instructions`
    * Each block ends in a control flow instruction • 
  * Instruction is an opcode + vector of operands
    * All operands have types
    * Resulting instruction is typed
* ![image-20200429144742919](D:\OneDrive\Pictures\Typora\image-20200429144742919.png)
* LLVM Pass Manager
  * compiler is organized as a series of passes (analysis/transformation)
  * passes have different constraints
  * Pass types
    * BasicBlockPass: iterate over basic blocks, in no particular order
    * CallGraphSCCPass: iterate over SCC’s (strong-connected component), in bottom-up call graph order
    * FunctionPass: iterate over functions, in no particular order
    * LoopPass: iterate over loops, in reverse nested order
    * ModulePass: general interprocedural pass over a program
    * RegionPass: iterate over single-entry/exit regions, in reverse nested order
* LLVM Tools
  * llvm-dis: Convert from .bc (IR binary) to .ll (human-readable IR text)
  * llvm-as: Convert from .ll (human-readable IR text) to .bc (IR binary)
  * opt: LLVM optimizer
    * Invoke arbitrary sequence of passes
      * Completely control PassManager from command line
      * Supports loading passes as plugins from *.so files
        * `opt -load foo.so -pass1 -pass2 -pass3 x.bc -o y.bc`
      * Passes “register” themselves: When you write a pass, you must write the registration
  * llc: LLVM static compiler
  * lli: LLVM bitcode interpreter
  * llvm-link: LLVM bitcode linker
  * llvm-ar: LLVM archiver
  * bugpoint - automatic test case reduction tool
  * llvm-extract - extract a function from an LLVM module
  * llvm-bcanalyzer - LLVM bitcode analyzer
  * FileCheck - Flexible pattern matching file verifier
  * tblgen - Target Description To C++ Code Generator



## Local Optimizations

* Common subexpression elimination

  * array expression
  * field access in records
  * access to parameters

* Parse Tree `->` Expression DAG (dependency)

  * problems
    * assignment statements
    * value of variable depends on TIME (interpretation of inst. in order of execution, keep dynamic state information)
  * fix
    * build graph in order of execution
    * attach variable name to latest value
  * key/variable `->` value mapping across time

* value number

  * ![image-20200429212627271](D:\OneDrive\Pictures\Typora\image-20200429212627271.png)

  * CSE `->` same value number

  * each value has its own "number"

  * [[N: like refcnt sharing value]]

  * ```text
    Data structure:
        VALUES = Table of
            expression /* [OP, valnum1, valnum2] */
            var /* name of variable currently holding expr */
    For each instruction (dst = src1 OP src2) in execution order
        valnum1=var2value(src1); valnum2=var2value(src2)
        IF [OP, valnum1, valnum2] is in VALUES
        	v = the index of expression
        	Replace instruction with: dst = VALUES[v].var
        ELSE
    	    Add
        		expression = [OP, valnum1, valnum2]
        		var = tv
        	to VALUES
        	v = index of new entry; tv is new temporary for v
        	Replace instruction with: tv = VALUES[valnum1].var OP VALUES[valnum2].var
        							dst = tv
        set_var2value (dst, v)
    ```

  * intiial values: values at beginning of the basic block

  * impl: lazy/eager initialization

  * hash tables

  * also works for constant folding: add a field to the `VALUES` table indicating when an expr. is a constant and what its value is

* Assign to temporary then copying to destination: increase opportunity to eliminate common subexpression

* Where is a variable defined or used?

  * Loop-invariant code motion
    * Are B, C, and D only defined outside the loop?
    * Other definitions of A inside the loop?
    * Uses of A inside the loop?
  * Copy propagation
    * For a given use of X: 
      * Are all reaching definitions of X copies from same variable: e.g., X = Y
      * Where Y is not redefined since that copy?
    * If so, substitute use of X with use of Y

* Definition-Use (DU) Chains

  * for a given definition of a variable X, what are all of its uses?

* Use-Definition (UD) Chains

  * for a given use of a variable X, what are all of the reaching definitions of X?

* Expensive: $O(NM)$ for `N` defs & `M` uses

  * limit each variable to 1 definition site
  * `=>` SSA

* Static single assignment (SSA):  an IR where every variable is assigned a value at most once in the program text

  * For each basic block, visit each instruction in program order: 
    * LHS: assign to a fresh version of the variable
    * RHS: use the most recent version of each variable
    * $\Phi$ function to join: merges multiple definitions along multiple control paths into a single definition (for all live variables)





## LLVM Details

* Strings: `StringRef`

  * no `char*`: `\0` terminate is bad for byte strings
  * no `std::string`: performance issues
  * `StringRef::str -> std::string`

* Output

  * `outs()/errs()/null() << string`
  * instruction `Instruction* I; I->dump()`
  * basic block `BasicBlock* BB; BB->dump()`

* Data Structures

  * ```
    BitVector
    DenseMap, DenseSet
    ImmutableList, ImmutableMap, ImmutableSet
    IntervalMap, IndexedMap
    MapVector, SetVector
    PriorityQueue, ScopedHashTable
    SmallBitVector, SmallPtrSet, SmallSet, SmallString, SmallVector
    SparseBitVector, SparseSet, 
    StringMap, StringRef, StringSet, 
    Triple, TinyPtrVector, PackedVector, FoldingSet, UniqueVector, ValueMap
    ```

  * better performance through specialization

* ![image-20200429220257052](D:\OneDrive\Pictures\Typora\image-20200429220257052.png)

* Casting & Type Introspection

  * Given `Value* v`, use `isa<Argument>(v)` (is `v` an instance of the `Argument` class)
  * `Argument* v = cast<Argument>(v)`
    * Causes assertion failure if you are wrong
  * `Argument* v = dyn_cast<Argument>(v)`
    * Cast v to an Argument if it is an argument, otherwise return NULL. 
    * Combines both isa and cast in one command
  * ![image-20200429220540063](D:\OneDrive\Pictures\Typora\image-20200429220540063.png)

* Iterators

  * `Module::iterator`

    * Modules are the large units of analysis
    * Iterates through the functions in the module

  * `Function::iterator`

    * Iterates through a function's basic blocks

  * `BasicBlock::iterator`

    * Iterates through the instructions in a basic block

  * `Value::use_iterator`

    * Iterates through uses of a value
    * instructions are treated as values

  * `User::op_iterator`

    * Iterates over the operands of an instruction (the “user” is the instruction)
    * Prefer to use convenient accessors defined by many instruction classes

  * ```c++
    // iterate through every inst. in a function
    for (Function::iterator FI = func->begin(); FI != func->end(); ++FI) {
        for (BasicBlock::iterator BBI = FI->begin(); BBI != FI->end(); ++BBI) {
    	    outs() << “Instruction: ” << *BBI << “\n”;
        }
    }
    // use InstIterator
    #include “llvm/IR/InstIterator.h”
    for (inst_iterator I = inst_begin(F), E = inst_end(F); I != E; ++I) {
    	outs() << *I << “\n”;
    }
    
    Function &Func = ...
    for (BasicBlock &BB : Func)
    	errs() << "Basic block (name=" << BB.getName() << ") has
    		" << BB.size() << " instructions.\n";
    // Finding a Basic Block’s predecessors/successors
    #include "llvm/Support/CFG.h"
    BasicBlock *BB = ...;
    for (pred_iterator PI = pred_begin(BB); PI != pred_end(BB); ++PI) {
        BasicBlock *pred = *PI;
        // ...
    }
    // Common code pattern
    for (Function::iterator FI = func->begin(); FI != func->end(); ++FI) {
        for (BasicBlock::iterator BBI = FI->begin(); BBI != FI->end(); ++BBI) {
            Instruction * I = BBI;
            if (CallInst * CI = dyn_cast<CallInst>(I)) {
    	        outs() << “I’m a Call Instruction!\n”;
            }
            if (UnaryInstruction * UI = dyn_cast<UnaryInstruction>(I)) {
         	   outs() << “I’m a Unary Instruction!\n”;
            }
            if (CastInstruction * CI = dyn_cast<CastInstruction>(I)) {
            	outs() << “I’m a Cast Instruction!\n”;
            }
            …
        }
    }
    // Visitor pattern
    class MyVisitor : public InstVisitor<MyVisitor> {
        void visitCallInst(CallInst &CI) {
    	    outs() << “I’m a Call Instruction!\n”;
        }
        void visitUnaryInstruction(UnaryInstruction &UI) {
        	outs() << “I’m a Unary Instruction!\n”;
        }
        void visitCastInst(CastInst &CI) {
        	outs() << “I’m a Cast Instruction!\n”;
        }
        void visitBinaryOperator(BinaryOperator &I) {
            switch (I.getOpcode()) {
            	case Instruction::Mul:
            		outs() << “I’m a multiplication Instruction!\n”;
            }
        }
    }
    ```

* Changing the LLVM IR

  * `eraseFromParent()`: Remove from basic block, drop all references, delete
  * `removeFromParent()`: Remove from basic block, use if you will re-attach the inst., does not drop ref. (or clear the use list).
  * `moveBefore/insertBefore/insertAfter`
  * `replaceInstWithValue/replaceInstWithInst`

* Correctness

  * module invariant
    * Types of binary operator parameters are the same
    * Terminator instructions only at the end of BasicBlocks
    * Functions are called with correct argument types
    * Instructions belong to Basic blocks
    * Entry node has no predecessor
  * opt automatically runs a pass (-verify) to check module invariants

* LLVM `PassManager`

  * Given a set of passes, the PassManager tries to __optimize the execution time__ of the set of passes

    * Share information between passes
    * Pipeline execution of passes

  * PassManager must understand how passes interact

    * Passes may require information from other passes
    * Passes may require transformations applied by other passes
    * Passes may invalidate information or transformations applied by other passes

  * `getAnalysisUsage()`: define how a pass interacts with other passes

    * `getAnalysisUsage(AnalysisUsage& AU)` for PassX

      * `AU.addRequired<PassY>()`: a PassY must be executed first
      * `AU.addPreserved<PassY>()`: a PassY is still preserved by running PassX
      * `AU.setPreservesAll()`: a PassX preserves all previous passes
      * `AU.setPreservesCFG()`: a PassX might make changes, but not to the CFG

    * ```c++
      void getAnalysisUsage(AnalysisUsage &AU) const override {
          AU.setPreservesCFG();
          AU.addRequired<DominatorTreeWrapperPass>();
          AU.addRequired<AliasAnalysis>();
          AU.addRequired<MemoryDependenceAnalysis>();
          AU.addPreserved<AliasAnalysis>();
          AU.addPreserved<DominatorTreeWrapperPass>();
          AU.addPreserved<MemoryDependenceAnalysis>();
      }
      ```

* LLVM Passes

  * `mem2reg`: memory to register
  * `loops`: `llvm/Analysis/LoopInfo.h`
    * The basic blocks in a loop
    * Headers and pre-headers
    * Exit and exiting blocks
    * Back edges
    * “Canonical induction variable”
    * Loop Count
  * `simplifycfg`: basic cleanup
    * Removes unnecessary basic blocks by merging unconditional branches if the second block has only one predecessor
    * Removes basic blocks with no predecessors
    * Eliminates phi nodes for basic blocks with a single predecessor
    * Removes unreachable blocks
    * ![image-20200429222817671](D:\OneDrive\Pictures\Typora\image-20200429222817671.png)
  * `scalar-evolution`: Scalar evolution
    * Tracks changes to variables through nested loops
  * `targetdata`: Target Data
    * Gives information about data layout on the target machine
    * Useful for generalizing target-specific optimizations
  * `basicaa/aa-eval/scev-aa`: alias analysis
    * Several different passes give information about aliases
    * If you know that different names refer to different locations, you have more freedom to reorder code, etc.
  * `dce/adce`: liveness-based dead code elimination
    * Assumes code is dead unless proven otherwise
  * `globaldce`: dead global elimination
    * Deletes all globals that are not live
  * `sccp`: sparse conditional constant propagation
    * Aggressively search for constants
  * `licm`: loop invariant code motion
    * Move code out of loops where possible
  * `indvars`: canonicalize induction variables
    * All loops start from zero and step by one
  * `loop-simplify`: canonicalize loops
    * Put loop structures in standard form





## Data Flow Analysis

* Local analysis (e.g. value numbering)

  * analyze effect of each instruction
  * compose effects of instructions to derive information from beginning of basic block to each instruction

* Data flow analysis

  * analyze effect of each basic block
  * compose effects of basic blocks to derive information at basic block boundaries
  * from basic block boundaries, apply local technique to generate information on instructions
  * flow-sensitive: sensitive to the control flow in a function
  * introprocedural analysis
  * examples
    * constant propagation
    * common subexpression elimination
    * dead code elimination

* Static program vs Dynamic execution

  * finite program vs. infinite many possible execution paths

* Effects

  * statement effects
    * __Use__ source variables
    * __Kill__ old definition
    * __Define__ a new definition
  * basic block effects `<=` composing effects of statements
    * A locally exposed use in a b.b. is a use of a data item that is not preceded in the b.b. by a definition of the data item.
    * Any definition of a data item in the b.b. kills all other definitions of the same data item
    * A locally available definition = last definition of data item in b.b
    * ![image-20200429230337708](D:\OneDrive\Pictures\Typora\image-20200429230337708.png)

* Reaching definitions

  * every assignment is a definition

  * a __defininiton__ `d` __reaches__ a point `p` if there exists path from the point immediately following `d` to `p` such that `d` is not killed along that path

  * forwarding analysis

    * ![image-20200429233019458](D:\OneDrive\Pictures\Typora\image-20200429233019458.png)
    * ![image-20200429233032034](D:\OneDrive\Pictures\Typora\image-20200429233032034.png)
    * ![image-20200429233046746](D:\OneDrive\Pictures\Typora\image-20200429233046746.png)
    * ![image-20200429233111066](D:\OneDrive\Pictures\Typora\image-20200429233111066.png)
    * ![image-20200429233133595](D:\OneDrive\Pictures\Typora\image-20200429233133595.png)
    * ![image-20200429233148720](D:\OneDrive\Pictures\Typora\image-20200429233148720.png)
    * fixed-point: for cyclic

  * iterative alg.

    * ```text
      input: control flow graph CFG = (N, E, Entry, Exit)
      // Boundary condition
      out[Entry] = {}
      
      // Initialization for iterative algorithm
      For each basic block B other than Entry
      	out[B] = {}
      
      // iterate
      While (changes to any out[] occur) {
          For each basic block B other than Entry {
              in[B] = U(out[p]), for all predecessors p of B
              out[B] = fB(in[B]) // out[B]=gen[B] U(in[B]-kill[B])
      	}
      ```

  * worklist alg.

    * ```text
      input: control flow graph CFG = (N, E, Entry, Exit)
      // Initialize
      out[Entry] = {} // could set out[Entry] to special def
      
      // if reaching then undefined use
      For all nodes i
      	out[i] = {} // could optimize by out[i]=gen[i]
      ChangedNodes = N
      
      // iterate
      While ChangedNodes ≠ {} {
          Remove i from ChangedNodes
          in[i] = U(out[p]), for all predecessors p of i
          oldout = out[i]
          out[i] = fi(in[i]) // out[i]=gen[i] U(in[i]-kill[i])
          if (oldout ≠ out[i]) {
              for all successors s of i
              add s to ChangedNodes
          }
      }
      ```

    * [[R: CS232 Notes]]

* Live variables

  * backward analysis

  * ![image-20200429233655524](D:\OneDrive\Pictures\Typora\image-20200429233655524.png)

  * ![image-20200429233703888](D:\OneDrive\Pictures\Typora\image-20200429233703888.png)

  * ```text
    // Iterative Algorithm.
    input: control flow graph CFG = (N, E, Entry, Exit)
    
    // Boundary condition
    in[Exit] = {}
    
    // Initialization for iterative algorithm
    For each basic block B other than Exit
    	in[B] = {}
    
    // iterate
    While (changes to any in[] occur) {
        For each basic block B other than Exit {
            out[B] = U(in[s]), for all successors s of B
            in[B] = fB(out[B]) // in[B]=Use[B] U(out[B]-Def[B])
        }
    ```

* ![image-20200429233800338](D:\OneDrive\Pictures\Typora\image-20200429233800338.png)

* Key questions

  * correctness?
  * precision?
  * convergence? will it terminate?
  * speed?



## Foundations of Data Flow Analysis

* Reaching definition

  * A definition d reaches a point p if 
    * there exists a path from the point immediately following d to p such that d is not killed (overwritten) along that path. 
  * A basic block b can 
    * generate new definitions: Gen[b]: set of definitions in b that reach end of b
    * propagate incoming definitions: in[b] - Kill[b]: where Kill[b]= set of defs killed by defs in b
  * forward analysis
    * transfer function for block b: `out[b] = Gen[b] U (in[b] - Kill[b])`
  * meet operator
    * `in[b] = out[p1] U out[p2] U ... U out[pn]` where `pi` are all predecessors of `b`

* A unified framework

  * dataflow problem formalization
    * domain of values: `V`
    * meet operator: `V ^ V -> V`, initial value
    * a set of transfer functions: `V -> V`
    * [[N: lattice fixpoint traversal]]
  * to answer the problem of correctness/precision/convergence/speed
  * to reuse code

* Semi-lattice

  * set of values
  * meet operator
    * commutative
    * idempotent
    * associative
    * a top element $\top$ (zero element) 
    * defines a partial ordering on values
      * `x <= y` iff. `x ^ y = x` (transitive/anti-symmetric/reflexivitive)
      * ![image-20200430160334518](D:\OneDrive\Pictures\Typora\image-20200430160334518.png)
    * for semi-lattice, bottom is not necessary
  * top, bottom ($x \wedge \top = x, x \wedge \bot = \bot$)
  * finite descending chain?
    * height: The height of a lattice is the largest number of > relations that will fit in a descending chain. 
    * infinite lattice can have a finite descending chain (e.g. constant folding)
    * ![image-20200430174212284](D:\OneDrive\Pictures\Typora\image-20200430174212284.png)

* Transfer function

  * function of each basic block $f: V \to V$
    * has an identity function $\forall x, f(x) = x$
    * closed under composition
  * monotone
    * $x \leq y \Rightarrow f(x) \leq f(y)$ or $f(x \wedge y) \leq f(x) \wedge f(y)$
      *  a “smaller or equal” input to the same function will always give a “smaller or equal” output
      * merge input, then apply f is small than or equal to apply the transfer function individually and then merge the result11
  * distributive?
    * $f(x \wedge y) = f(x) \wedge f(y)$
      * merge input, then apply f is equal to apply the transfer function individually then merge result

* Algorithm

  * Let $f_1, \cdots, f_m \in F$ where $f_i$ is the transfer function for node $i$

    * $f_p$: the path through nodes (identity if empty path)

  * perfect data flow answer

    * for each node $n$: $\wedge f_{p_i}(T)$ for all possibly executed path $p_i$ in the program reaching $n$
    * ![image-20200430221424339](D:\OneDrive\Pictures\Typora\image-20200430221424339.png)
    * undecidable to determining all possibly executed paths

  * Meet-Over-Paths (MOP)

    * for each node $n$: $MOP(n) = \wedge f_{p_i}(T)$ for all path $p_i$ in data flow graph reaching $n$
    * MOP `<=` Perfect-Solution (include un-executed paths)

  * Fixed point solution (FP)

  * iterative alg for forward/backward analysis

    * `out[b]` to $\top$ for all `b`
    * if framework is monotone, algorithm converges, then it computes maximum fixed point (MFP)
      * MFP is the largest of all solutions to equations (in any other solution, the values of IN[b] and OUT[b] are ≤ the corresponding values of the MFP)
      * FP `<=` MFP `<=` MOP `<=` Perfect-solution

  * correctness

    * ![image-20200430225435204](D:\OneDrive\Pictures\Typora\image-20200430225435204.png)

  * precision

    * ![image-20200430225525593](D:\OneDrive\Pictures\Typora\image-20200430225525593.png)

  * convergence

    * Data flow framework (monotone) converges if there is a finite descending chain
    * ![image-20200430231630359](D:\OneDrive\Pictures\Typora\image-20200430231630359.png)

  * speed: depends on the order of node visits

    * visit order: rPostOrder

    * ```text
      // DFS
      main() {
          count = 1;
      	Visit(root);
      }
      Visit(n) {
          for each successor s that has not been visited
          	Visit(s);
          PostOrder(n) = count;
          count = count+1;
      }
      
      // reverse order
      For each node i
      	rPostOrder(i)= NumNodes - PostOrder(i)
      ```

    * If cycles do not add information (e.g.: if a defn d in node 𝑛1 reaches a node 𝑛𝑘 along a path that contains a cycle (i.e., a repeated node), then the cycle can be removed to form a shorter path from 𝑛1 to 𝑛𝑘 such that d reaches 𝑛𝑘. )

      * information can flow in one pass down nodes of increasing order number
      * passes determined by number of back edges in the path (essentially the nesting depth)
      * Number of iterations = number of back edges in any acyclic path + 2
        * (2 are necessary even for acyclic CFGs)
        * (2 not 1 since need a last pass where nothing changed)

    * depth of the graph: corresponds to depth of intervals for “reducible” graphs

      * real programs: ~2.75 average



## Global Common Subexpression Elimination/Constant Folding/Propagation

* available expression analysis
  * availability of expression `E` at point `P`: along every path to `P` in the flow graph, `E` must be evaluated at least once + no variables in `E` re-defined after the last evaluation
  * `E` may have different values on different paths
  * Domain: a bitvector with a bit for each "textually unique" expression in the program
  * Forward
  * Lattice elemnts: all bit vectors of given length
  * Meet operator: elementwise-min (commutative/idempotent/associative)
  * Partial ordering
  * Top: `(1, 1, ..., 1)`
  * Bottom: `(0, 0, ..., 0)`
  * Boundary condition: entry/exit node `out[entry] = (0, ..., 0)`
  * Transfer function
    * `out[b] = gen[b] U (in[b] - kill[b])`
    * initialize `out[b] = T` for all interior `b`
    * ![image-20200501192427660](D:\OneDrive\Pictures\Typora\image-20200501192427660.png)
* eliminating CSE
  * Value Numbering (within basic block): eliminate local CSE
  * Available expressions (across basic block): provides the set of expr. available at the start of a block
  * CSE is available expr `=>` transformation
    * soln 1: copy the expr. to a new variable at each evaluation reaching the redundant use
      * ![image-20200501192713093](D:\OneDrive\Pictures\Typora\image-20200501192713093.png)
    * commutative operations (`x + y` and `y + x`)
      * sort the operands
    * future improvements
      * Expressions with more than two operands
      * Textually different expressions may be equivalent (E.g. after copy propagation)
      * Use multiple passes of GCSE combined with copy propagation
* ![image-20200501193225603](D:\OneDrive\Pictures\Typora\image-20200501193225603.png)
  * [[Q: efficiency? bitvector searching? variable matching?]]
* Constant Propagation/Folding
  * At every basic block boundary, for each variable `v`
    * determine if `v` is a constant, and if so, what is the value
  * Infinite domain (unless bound the number of bits), finite height, 1 lattice per variable
    * ![image-20200501193529027](D:\OneDrive\Pictures\Typora\image-20200501193529027.png)
  * ![image-20200501193635023](D:\OneDrive\Pictures\Typora\image-20200501193635023.png)
  * Transfer function
    * `IN[b, x]/OUT[b, x]`: information for variable `x` at entry & exit of basic block `b`
    * for all `x`, `OUT[entry, x] = UNDEF`
    * Non-assignment instructions: `OUT[b, x] = IN[b, x]`
    * assignment instructions
      * ![image-20200501194554342](D:\OneDrive\Pictures\Typora\image-20200501194554342.png)
      * [[N: for calling instructions...]]
    * not distributive
      * ![image-20200501194700314](D:\OneDrive\Pictures\Typora\image-20200501194700314.png)
      * `f3(f1(T) ^ f2(T)) < f3(f1(T)) ^ f3(f2(T))`
  * infinite semi-lattice
  * cycle can add information
  * abstract execution
  * non-distributive





## Induction Variable Optimizations

* Loop in (CFG) graph-theoretic terms, independent of PL constructs, uniform treatment for all loops (do, while, for, goto's)
  * single entry point
  * edges must form at least a cycle
  * can nest
  * ![image-20200501195445761](D:\OneDrive\Pictures\Typora\image-20200501195445761.png)
* Dominance
  * x strictly dominates w (x `sdom` w) iff impossible to reach w without passing through x first
  * x dominates w (x `dom` w) iff x `sdom` w OR x `=` w
* Natural Loops
  * single entry-point/header: dominate all nodes in that loop
  * back edge: an arc `t -> h` whose head `h` dominates its tail `t` (must be part of at least once loop)
  * natural loop of a back edge `t -> h`: the smalleste set of nodes that includes `t` and `h` and has no predecessors outside the set, except for the predecessors of the header `h`
  * ![image-20200501200622625](D:\OneDrive\Pictures\Typora\image-20200501200622625.png)
* Find Natural Loops
  * Find the dominator relations in a flow graph
    * ![image-20200501200809801](D:\OneDrive\Pictures\Typora\image-20200501200809801.png)
    * ![image-20200501200756285](D:\OneDrive\Pictures\Typora\image-20200501200756285.png)
    * Speed: With `rPostorder`, most flow graphs (reducible flow graphs) converge in 1 pass
    * ![image-20200501200919733](D:\OneDrive\Pictures\Typora\image-20200501200919733.png)
  * Identify the back edges
    * Depth-first spanning tree: Edges traversed in a depth-first search of the flow graph form a depth-first spanning tree
      * [[N: DFS-spanning tree/BFS-spanning tree]]
      * ![image-20200501201122970](D:\OneDrive\Pictures\Typora\image-20200501201122970.png)
    * Categorizing edges in graph
      * Advancing edges (`A`): from ancestor to proper descendant
      * Cross edges (`C`): from right to left
      * Retreating edges (`R`): from descendant to ancestor (not necessarily proper)
      * [[N: proper: not same as the original node]]
      * ![image-20200501212459389](D:\OneDrive\Pictures\Typora\image-20200501212459389.png)
      * ![image-20200501202342301](D:\OneDrive\Pictures\Typora\image-20200501202342301.png)
    * Perform a DFS
    * For each retreating edge `t -> h`, check if `h` is in `t`'s dominator list
      * Most programs have reducible flow graphs: retreating edges `=` back edges
      * [[Q: how to identify retreating but not back edge? Check dominator list]]
      * ![image-20200501202445360](D:\OneDrive\Pictures\Typora\image-20200501202445360.png)
      * ![image-20200501202610840](D:\OneDrive\Pictures\Typora\image-20200501202610840.png)
      * [natural-loop](http://web.cs.iastate.edu/~weile/cs513x/4.ControlFlowAnalysis.pdf)
  * Find the natural loop associated with the back edge
    * ![image-20200501203046527](D:\OneDrive\Pictures\Typora\image-20200501203046527.png)
    * For each back edge `t -> h`
      * delete `h` from the flow graph
      * find those nodes that can reach `t` (those nodes + `h` form the natural loop of `t -> h`)
* Inner Loops
  * two loops don't have the same header `->` disjoint / one is entirely contained (nested within) the other
  * two loops share the same header `->` combine and treat as one loop
    * ![image-20200501203413479](D:\OneDrive\Pictures\Typora\image-20200501203413479.png)
* Preheader
  * Optimizations often emit code that is to be executed once before the loop
  * Solution: Create a preheader basic block for every loop
  * ![image-20200501203621078](D:\OneDrive\Pictures\Typora\image-20200501203621078.png)
* Induction variable
  * basic induction variable: a variable X whose only definitions within the loop are assignments of the form `X = X + c/X = X - c`
    * `c` is either a constant of a loop-invariant variable (e.g. `i`)
    * detected by scanning loop
  * induction variable
    * a basic induction variable, or
    * a variable defined once within the loop, whose value is a linear function of some basic induction variable at the time of the definition `A = c1 * B + c2`
  * family of a basic induction variable `B`: the set of induction variables `A` such that each time `A` is assigned in the loop, the value of `A` is a linear function of `B`.
    * ![image-20200501205418569](D:\OneDrive\Pictures\Typora\image-20200501205418569.png)
    * ![image-20200501205424575](D:\OneDrive\Pictures\Typora\image-20200501205424575.png)
      * [[Q: if both operands in the same family of one IV and `cL = cR`?]]
    * ![image-20200501205748550](D:\OneDrive\Pictures\Typora\image-20200501205748550.png)
    * ![image-20200501212152980](D:\OneDrive\Pictures\Typora\image-20200501212152980.png)
    * Conditions
      * A has a single assignment in the loop L of the form A = B\*c, c\*B, B+c, etc
      * A is in family of B if D = c1* B + c2 for basic induction variable B and
        * Rule 1: A has a single assignment in the loop L of the form A = D*c, D+c, etc
        * Rule 2: No definition of D outside L reaches the assignment to A
        * Rule 3: Every path between the lone point of assignment to D in L and the assignment to A has the same sequence (possibly empty) of definitions of B
* Optimizations
  * Strength reduction
    * `A` is an induction variable in family of basic induction variable `B` (i.e., `A = c1 *B + c2`) 
      * create new variable `A'`
      * initialize in preheader `A' = c1 * B + c2`
      * track value of `B`: add after `B + x`, `A' = A' + x * c1`
      * replace assignment to `A`: `A = ...` with `A = A'`
    * ![image-20200501204534675](D:\OneDrive\Pictures\Typora\image-20200501204534675.png)
    * For each induction variable `A`:
      * variable `A'` holds expression `c1 * B + c2` at all times
      * replace definition of `A` with `A = A'` only when executed
  * Optimizing non-basic induction variables
    * copy propagation
    * dead code elimination
  * Optimizing basic induction variables
    * eliminate basic induction variables used only for calculating other induction variables and loop tests
      * Select an induction variable `A` in the family of `B`, preferably with simple constants (`A = c1 * B + c2`)
      * Replace a comparison such as `if B > X goto L1` `=>` `if (A' > c1 * X + c2) goto L1`
      * If `B` is live at any exit from the loop, recompute it from `A'` (`B = (A' - c2) / c1`)
    * ![image-20200501204736960](D:\OneDrive\Pictures\Typora\image-20200501204736960.png)



## Loop Invariant Computation & Code Motion

* loop-invariant computation: a computation whose value does not change as long as control stays within the loop
  * operands are defined outside loop or invariant themselves
* code motion: to move a statement within a loop to the preheader of the loop
  * not all loop invariant instructions can be moved to preheader
* ![image-20200501222646145](D:\OneDrive\Pictures\Typora\image-20200501222646145.png)
* Detecting Loop Invariant Computation
  * compute reaching definitions
  * mark Invariant if all the definitions of `B` and `C` that reach a statement `A = B + C` are outside the loop (include constant `B`/`C`)
  * repeat mark Invariant if
    * all reaching definitions of B/C are outside the loop / there is exactly one reaching definition for B/C and it is from a loop-invariant statement inside the loop
    * until no changes to the set of loop-invariant statements occur
  * ![image-20200501223941420](D:\OneDrive\Pictures\Typora\image-20200501223941420.png)
* Conditions for Code Motion
  * Correctness: Movement does not change semantics of program
  * Performance: Code is not slowed down
    * ![image-20200501224148367](D:\OneDrive\Pictures\Typora\image-20200501224148367.png)
  * ![image-20200501225629824](D:\OneDrive\Pictures\Typora\image-20200501225629824.png)
* Code Motion Algorithm
  * Given: a set of nodes in a loop
  * Compute reaching definitions
  * Compute loop invariant computation
  * Compute dominators
  * Find the exits of the loop (i.e. nodes with successor outside loop)
  * Candidate statement for code motion
    * loop invariant
    * in blocks that dominate all the exits of the loop
      * Gamble on: relax this constraint if destination not live after loop & can compute in preheader w/o causing an exception
      * ![image-20200501230105246](D:\OneDrive\Pictures\Typora\image-20200501230105246.png)
    * assign to variable not assigned to elsewhere in the loop
    * in blocks that dominate all blocks in the loop that use the variable assigned
  * Perform a depth-first search of the blocks
    * Move the candidate to the preheader if all the invariant operations it depends upon have been moved
  * ![image-20200501225913071](D:\OneDrive\Pictures\Typora\image-20200501225913071.png)
  * Landing pads: ensure preheader executes only if enter loop
    * ![image-20200501230136917](D:\OneDrive\Pictures\Typora\image-20200501230136917.png)
* Partial Redundancy
  * ![image-20200501230619454](D:\OneDrive\Pictures\Typora\image-20200501230619454.png)
  * ![image-20200501230629518](D:\OneDrive\Pictures\Typora\image-20200501230629518.png)
  * ![image-20200501230649070](D:\OneDrive\Pictures\Typora\image-20200501230649070.png)
  * Occurrence of expression `E` at `P` is __partially redundant__ if `E` is __partially available__ there `E` is evaluated along at least one path to `P`, with no operands redefined since.
  * Partially redundant expression can be eliminated if we can __insert__ computations to make it __fully redundant__
    * Remaining copies can be eliminated through copy propagation or more complex analysis of partially redundant assignments
  * Loop invariant expression is partially redundant
    * ![image-20200501230918132](D:\OneDrive\Pictures\Typora\image-20200501230918132.png)
* Partial Redundancy Elimination (PRE)
  * subsumes global CSE (fully redundancy) / loop invariant code motion (partial redundancy for loops)
  * ![image-20200501231015422](D:\OneDrive\Pictures\Typora\image-20200501231015422.png)
  * safety: never introduce a new expression along any path
    * Insertion could introduce exception, change program behavior.
    * If we can add a new basic block, can insert safely in most cases. 
    * Solution: insert expression only where it is __anticipated__, i.e., its value computed at point p will be used along ALL subsequent paths
  * performance: never increase the \# of computations on any path
    * Under simple model, guarantees program won’t get worse.
    * Reality: might increase register lifetimes, add copies, lose
  * [PRE](http://www.cs.cmu.edu/afs/cs/academic/class/15745-s12/public/lectures/L10-PRE-1up.pdf)





## Lazy Code Motion

* Full redundancy `=>` cut set in a graph
  * cut set: nodes that separate entry from `p`
  * each node in a cut set contains the same calculation
  * `a, b` not redefined
  * ![image-20200506114919712](D:\OneDrive\Pictures\Typora\image-20200506114919712.png)
* Partial redundancy `=>` complete a cut set
  * add operations to create a cut set
  * anticipated: if the expression value will be used along all subsequent paths
  * `a, b` are not redefined, no branches that lead to exit without use
* Preparing the flow graph
  * critical edges
    * source basic block has multiple successors
    * destination basic block has multiple predecessors
  * modify the flow graph
    * Add a basic block for every edge that leads to a basic block with multiple predecessors (not just on critical edges) (safety)
      * ![image-20200506131809723](D:\OneDrive\Pictures\Typora\image-20200506131809723.png)
    * To keep algorithm simple: consider each statement as its own basic block and restrict placement of instructions to the beginning of a basic block 
* Lazy Code Motion
  * First calculates the “earliest” set of blocks for insertion
    * this maximizes redundancy elimination
    * but may also result in long register lifetimes – 
  * Then it calculates the “latest” set of blocks for insertion
    * achieving the same amount of redundancy elimination as “earliest”
    * but hopefully reducing the lifetime of the register holding the value of the expression
  * Pass 1: Anticipated Expressions
    * Backward pass: Anticipated (very busy) expressions
    * `Anticipated[b]`: set of expressions anticipated at the entry of `b`
      * An expression is __anticipated__ if its value computed at point p will be used along ALL subsequent paths
    * ![image-20200506132809289](D:\OneDrive\Pictures\Typora\image-20200506132809289.png)
    * First approximation
      * place operations at the frontier of anticipation (boundary between not anticipated and anticipated)
      * ![image-20200506134109442](D:\OneDrive\Pictures\Typora\image-20200506134109442.png)
      * ![image-20200506143445360](D:\OneDrive\Pictures\Typora\image-20200506143445360.png)
      * ![image-20200506143451727](D:\OneDrive\Pictures\Typora\image-20200506143451727.png)
      * ![image-20200506143607518](D:\OneDrive\Pictures\Typora\image-20200506143607518.png)
      * anticipation may oscillate
  * Pass 2: Available Expressions (Place As Early As Possible)
    * `e` __will be available__ at `p` if `e` has been “anticipated but not subsequently killed” on all paths reaching `p`
    * ![image-20200506153807745](D:\OneDrive\Pictures\Typora\image-20200506153807745.png)
    * `earliest(b)`: set of expressions added to block `b` under early placement
      * calculated from results of first 2 passes
      * place expression at the earliest point __anticipated__ and not already __available__
      * `earliest(b) = anticipated[b].in - available[b].in`
      * ![image-20200506193105419](D:\OneDrive\Pictures\Typora\image-20200506193105419.png)
      * maximize redundancy elimination
      * placed as early as possible
      * register lifetime pressure?
  * Pass 3: Postponable Expressions
    * delay creating redundancy to reduce register pressure
    * ![image-20200506194105295](D:\OneDrive\Pictures\Typora\image-20200506194105295.png)
    * An expression `e` is __postponable__ at a program point `p` if all paths leading to `p` have seen earliest placement of `e` but not a subsequent one
      * ![image-20200506194157714](D:\OneDrive\Pictures\Typora\image-20200506194157714.png)
      * ![image-20200506194639411](D:\OneDrive\Pictures\Typora\image-20200506194639411.png)
    * `latest[b]`: frontier at the end of "postponable" cut set
      * ![image-20200506195528673](D:\OneDrive\Pictures\Typora\image-20200506195528673.png)
      * OK to place expression: earliest or postponable
      * need to place at `b` if
        * used in `b`, or
        * not OK to place in one of its successors
      * Works because of pre-processing step (an empty block was introduced to an edge if the destination has multiple predecessors)
        * if b has a successor that cannot accept postponement, b has only one successor
        * ![image-20200506195754283](D:\OneDrive\Pictures\Typora\image-20200506195754283.png)
          * this doesn't exist
      * ![image-20200506195915483](D:\OneDrive\Pictures\Typora\image-20200506195915483.png)
  * Pass 4: Used Expressions
    * ![image-20200506230445510](D:\OneDrive\Pictures\Typora\image-20200506230445510.png)
    * eliminate temporary variable assignments unused beyond current block
    * `Used.out[b]`: set of used (live) expressions at exit of `b`
    * ![image-20200506230547479](D:\OneDrive\Pictures\Typora\image-20200506230547479.png)
  * Code Transformation
    * ![image-20200506230958389](D:\OneDrive\Pictures\Typora\image-20200506230958389.png)
    * ![image-20200506231019015](D:\OneDrive\Pictures\Typora\image-20200506231019015.png)
* 4 Passes
  * Safety: Cannot introduce operations not executed originally
    * Pass 1 (backward): Anticipation: range of code motion
    * Placing operations at the frontier of anticipation gets most of the redundancy
  * Squeezing the last drop of redundancy: An anticipation frontier may cover a subsequent frontier
    * Pass 2 (forward): Availability
    * Earliest: anticipated, but not yet available
  * Push the cut set out -- as late as possible: To minimize register lifetimes
    * Pass 3 (forward): Postponability: move it down provided it does not create redundancy
    * Latest: where it is used or the frontier of postponability 
  * Cleaning up
    * Pass 4 (backward): Remove unneeded temporary assignments
  * Finds many forms of redundancy in one unified framework





## Static Single Assignment (SSA)

* When/Where to insert $\Phi$

  * insert a $\Phi$ function for variable `v` in block `Z` iff.
    * `v` was defined more than once before
    * There exists nonempty path `P_xz` from `X` to `Z` and `P_yz` from `Y` to `Z` , s.t. `Z` is the first node common to the 2 paths
      * nonempty: at least one edge
      * one of `X` or `Y` can be `Z`
        * $v  = \Phi(...)$ is also a definition
    * ![image-20200507165551134](D:\OneDrive\Pictures\Typora\image-20200507165551134.png)
    * ![image-20200507165555444](D:\OneDrive\Pictures\Typora\image-20200507165555444.png)
  * Entry block contains an implicit def of all vars

* Dominance Frontier

  * ![image-20200507170337670](D:\OneDrive\Pictures\Typora\image-20200507170337670.png)

  * ![image-20200507170827219](D:\OneDrive\Pictures\Typora\image-20200507170827219.png)

  * ![image-20200507170837107](D:\OneDrive\Pictures\Typora\image-20200507170837107.png)

  * ![image-20200507171922428](D:\OneDrive\Pictures\Typora\image-20200507171922428.png)

  * definition of `v` in block `Z`, then nodes in `DF(Z)` need a $\Phi(...)$ for `v`

    * exists path not `sdom`

  * ```text
    compute-DF(n)
        S = {}
        foreach node c in succ[n]
    	    if !(n sdom c)
        		S = S U { c } // e.g., node c on previous slide
        foreach child a of n in the Dominance Tree
        	compute-DF(a)
        	foreach x in DF[a]
        		if !(n dom x)
        			S = S U { x }
        			// e.g., node x on previous slide
        DF[n] = S
    ```

* Use Dominance Frontier to Place $\Phi()$

  * Gather all the `defsites` of every variable
  * Then, for every variable
    * `foreach defsite`
      * `foreach node in DominanceFrontier(defsite)`
        * if we haven't put $\Phi()$ in the node, then put one in
        * if this node didn’t define the variable before, then add this node to the `defsites `(because $\Phi$ counts as def)
  * This essentially computes the Iterated Dominance Frontier on the fly
    * inserting the minimal number of $\Phi()$ necessary
  * ![image-20200507214104307](D:\OneDrive\Pictures\Typora\image-20200507214104307.png)

* Renaming Variables

  * Walk the dominance tree, renaming variables as you go
  * Replace uses with more recent renamed definition
  * Use the closest def. such that def. is above the use in the Dominance Tree
  * ![image-20200508104830948](D:\OneDrive\Pictures\Typora\image-20200508104830948.png)

* ![image-20200508105905111](D:\OneDrive\Pictures\Typora\image-20200508105905111.png)

* ![image-20200508105930897](D:\OneDrive\Pictures\Typora\image-20200508105930897.png)

* Constant propagation with SSA

  * `v <- c`: replace all uses of `v` with `c`
  * `v <- phi(c, c, c)`: same constant, replace all uses of `v` with `c`
  * ![image-20200508110043383](D:\OneDrive\Pictures\Typora\image-20200508110043383.png)

* Conditional constant propagation

  * ![image-20200508110119009](D:\OneDrive\Pictures\Typora\image-20200508110119009.png)
  * keeps track of
    * blocks: assume unexecuted until proven otherwise
    * variables: assume not executed (only with proof of assignments of non-constant value do we assume not constant)
  * lattice
    * ![image-20200508110243631](D:\OneDrive\Pictures\Typora\image-20200508110243631.png)
  * ![image-20200508110317711](D:\OneDrive\Pictures\Typora\image-20200508110317711.png)





## Register Allocation & Spilling

* Allocation of variables (pseudo-registers) to hardware registers
* Useful for other optimizations
  * e.g. CSE assumes old values are kept in register
* Two pseudo-registers (i.e., program variables) __interfere__ if at some point in the program they cannot both occupy the same register. 
  * nodes: pseudo-registers
  * edge: interference
* n-colorable: every node in the graph can be colored with one of the `n` colors such that two adjacent nodes do not have the same color
  * assign a node to a register (color) such that no two adjacent nodes are assigned same registers (colors)
  * NPC, for `n >= 2`
* Build an interference graph
  * Eliminate interference in a variable’s “dead” zones.
  * Increase flexibility in allocation
  * live range: consists of a definition and all the points in a program (e.g. end of an instruction) in which that definition is live
    * live variables & reaching definitions
    * two overlapping live ranges for the same variable must be merged
  * ![image-20200509164516541](D:\OneDrive\Pictures\Typora\image-20200509164516541.png)\
  * Merging live ranges (webs)
    * Merging definitions into equivalence classes
      * Start by putting each definition in a different equivalence class
      * Then, for each point in a program: if
        * (i) variable is live, and 
        * (ii) there are multiple reaching definitions for the variable
        * then: merge the equivalence classes of all such definitions into one equivalence class (similar to phi function)
    * Note: no need to implement a Phi function (in assembly)
      * Phi functions and SSA variable renaming simply turn into merged live ranges
      * ![image-20200509175719173](D:\OneDrive\Pictures\Typora\image-20200509175719173.png)
  * Two distinct live ranges may interfere if they overlap at some point in the program
    * At each point in the program: enter an edge for every pair of live ranges at that point
    * optimization: check for interference only at the start of each live range
    * ![image-20200509180707551](D:\OneDrive\Pictures\Typora\image-20200509180707551.png)
* Coloring
  * a node with degree `< n`: can always color it sucessfully, given its neighbors' colors
  * degree `= n`: if `>= 2` neighbors share same color
  * `> n`: maybe, not always
  * Coloring Heuristic
    * iterate until stuck or done
      * pick any node with degree `< n`, push `v` on register allocation stack
      * remove the node and its edges from the graph
    * if done: reverse process & add colors
    * ![image-20200509180901153](D:\OneDrive\Pictures\Typora\image-20200509180901153.png)
  * Coloring + Register Assignment
    * Apply coloring heuristic
    * Assign registers
      * while stack not empty
        * pop `v` from stack
        * reinsert `v` & its edges into the graph
        * assign `v` a color that differs from all its neighbors
* Extending Coloring
  * A pseudo-register is
    * Colored successfully: allocated a hardware register
    * Not colored: left in memory
  * Objective function
    * Cost of an uncolored node:
      * proportional to number of uses/definitions (dynamically)
        * CISC: direct memory operation
        * RISC: load data from memory, must compute `RHS` in a register then store
        * even if spilled to mem., needs a reg. at time of use/definition
      * estimate by its loop nesting
    * Objective: minimize sum of cost of uncolored nodes
  * Heuristics
    * Benefit of spilling a pseudo-register:
      * increases colorability of pseudo-registers it interferes with
      * can approximate by its degree in interference graph
    * Greedy heuristic
      * spill the pseudo-register with lowest cost-to-benefit ratio, whenever spilling is necessary
  * Chaitin: Coloring & Spilling
    * ![image-20200509181859838](D:\OneDrive\Pictures\Typora\image-20200509181859838.png)
    * ![image-20200509182128807](D:\OneDrive\Pictures\Typora\image-20200509182128807.png)
  * Spilling
    * ![image-20200509181916966](D:\OneDrive\Pictures\Typora\image-20200509181916966.png)
    * Prioritize the coloring
      * ![image-20200509182145645](D:\OneDrive\Pictures\Typora\image-20200509182145645.png)
    * Problem: all or nothing
      * Why not try to keep a pseudo-register in a hardware register part of the time
  * Splitting Live Ranges (reverse coalescing)
    * Instead of choosing variables to spill, choose live ranges to split
    * Split pseudo-registers into live ranges to make interference graph easier to color
      * Eliminate interference in a variable’s “dead” zones
        * Cost: Memory loads and stores: Load and store at boundaries of regions with no activity
        * Initially: # active live ranges at a program point can be > # registers
      * Increase flexibility in allocation: can allocate same variable to different registers
        * Cost: Register operations: a register copy between regions of different assignments
        *  \# active live ranges cannot be > # registers
      * ![image-20200509182251984](D:\OneDrive\Pictures\Typora\image-20200509182251984.png)
      * [[Q: is this still chordal?]]
* ![image-20200509182523430](D:\OneDrive\Pictures\Typora\image-20200509182523430.png)
* ![image-20200509182552271](D:\OneDrive\Pictures\Typora\image-20200509182552271.png)
* [[N: Chordal assignment? Linear scan? pre-coloring? aliasing?]]



## Pointer Analysis

* alias: reference the same memory location

* Decide for every pair of pointers at every program point:

  * do they point to the same memory location?
  * undecidable (Landi, 1992)
  * Correctness: report all pairs of pointers which do/may alias
  * Ambiguous: two pointers which may or may not alias
  * Accuracy/Precision: how few pairs of pointers are reported while remaining correct
    * i.e., reduce ambiguity to improve accuracy

* Uses of Pointer Analysis

  * Basic compiler optimizations
    * register allocation, CSE, dead code elimination, live variables
    * instruction scheduling, loop invariant code motion, redundant load/store elimination 
  * Parallelization
    * instruction-level parallelism – thread-level parallelism
  * Behavioral synthesis
    * automatically converting C-code into gates
  * Error detection and program understanding
    * memory leaks, wild pointers, security holes

* Challenges of Pointer Analysis

  * Complexity: huge in space and time 
    * compare every pointer with every other pointer 
    * at every program point
    * potentially considering all program paths to that point 
  * Scalability vs accuracy trade-off 
    * different analyses motivated for different purposes 
    * many useful algorithms (adds to confusion) \
  * Coding corner cases 
    * pointer arithmetic (*p++), casting, function pointers, long-jumps 
  * Whole program? 
    * most analysis algorithms require the entire program 
    * library code? optimizing at link-time only?

* PA Design Options

  * Representation

    * ```c
      a = &b;
      b = &c;
      b = &d;
      e = b;
      ```

    * Track aliases

      * more precise, less efficient
      * ![image-20200509194910218](D:\OneDrive\Pictures\Typora\image-20200509194910218.png)

    * Track points-to information

      * less precise, more efficient
      * ![image-20200509194952289](D:\OneDrive\Pictures\Typora\image-20200509194952289.png)

  * Heap Modeling

    * Heap merged: no heap modeling
    * Allocation site (any call to `malloc/calloc`)
      * Consider each to be a unique location
      * Doesn’t differentiate between multiple objects allocated by the same allocation site
    * Shape analysis
      * Recognize linked lists, trees, DAGs, etc.

  * Aggregate Modeling

    * Array
      * individual locations
      * single location
      * first element separate from others
    * Structures
      * individual locations (field sensitive)
      * single location

  * Flow Sensitivity

    * Flow insensitive
      * The order of statements doesn’t matter
      * Result of analysis is the same regardless of statement order
      * Uses a single global state to store results as they are computed
      * Fast, but not very accurate
      * [[N: each expression only has one `SymVar`]]
    * Flow sensitive
      * The order of the statements matter
      * Need a control flow graph
      * Must store results for each program point
      * Improves accuracy
      * [[N: each expression copies per stmt/program point]]
    * Path sensitive
      * Each path in a control flow graph is considered
      * If-then-else implies mutually exclusive paths
      * [[N: two if-edge are considered without extra edge]]
    * ![image-20200509195335962](D:\OneDrive\Pictures\Typora\image-20200509195335962.png)

  * Context Sensitivity Options

    * Context insensitive/sensitive (interprocedural analysis)
      * whether to consider different calling contexts
    * ![image-20200509195629443](D:\OneDrive\Pictures\Typora\image-20200509195629443.png)

* Pointer Alias Analysis Algorithms

  * > • “Program Analysis and Specialization for the C Programming Language”, Andersen, Technical Report, 1994
    >
    >  • “Context-sensitive interprocedural points-to analysis in the presence of function pointers”, Emami et al., PLDI 1994 
    >
    > • “Points-to analysis in almost linear time”, Steensgaard, POPL 1996 
    >
    > • “Which pointer analysis should I use?”, Hind et al., ISSTA 2000 
    >
    > • “Pointer analysis: haven't we solved this problem yet?”, Hind, PASTE 2001 
    >
    > • … 
    >
    > • “Introspective analysis: context-sensitivity, across the board”, Smaragdakis et al., PLDI 2014 
    >
    > • “Sparse flow-sensitive pointer analysis for multithreaded programs”, Sui et al., CGO 2016 
    >
    > • “Symbolic range analysis of pointers”, Paisante et al., CGO 2016

* Address Taken

  * Basic, fast, ultra-conservative algorithm
    * flow-insensitive, context-insensitive
    * often used in production compilers
  * Generate the set of all variables whose addresses are assigned to another variable.
  * Assume that any pointer can potentially point to any variable in that set
  * Complexity: `O(n)` - linear in size of program
  * Accuracy: very imprecise
  * ![image-20200509195815466](D:\OneDrive\Pictures\Typora\image-20200509195815466.png)

* Andersen's Algorithm

  * Flow-insensitive, context-insensitive, iterative
  * Representation
    * one points-to graph for entire program
    * each node represents exactly one location
  * For each statement, build the points-to graph
    * ![image-20200509200144136](D:\OneDrive\Pictures\Typora\image-20200509200144136.png)
  * Iterate until graph no longer changes
  * Complexity: worst case `O(n^3)`
  * ![image-20200509200217994](D:\OneDrive\Pictures\Typora\image-20200509200217994.png)

* Steensgaard's Algorithm

  * Flow-insensitive, context-insensitive
  * Representation
    * a compact points-to graph for entire program
      * each node can represent multiple locations
      * but can only point to one other node
        * i.e. every node has a fan-out of 1 or 0
  * Union-find data structure implements fan-out
    * “union-ing” while finding eliminates need to iterate
  * Complexity: worst case nearly `O(n)`
    * each union-find operation takes nearly `O(1)` time ($O(\alpha)$)
  * Precision: less precise than Andersen's
  * bad for OO languages
  * ![image-20200509200542341](D:\OneDrive\Pictures\Typora\image-20200509200542341.png)

* Precise analysis (flow sensitive)

  * ![image-20200509200620585](D:\OneDrive\Pictures\Typora\image-20200509200620585.png)
  * more precise? path-sensitive, context-sensitive

* Pointer Analysis Using BDDs

  * > • “Cloning-based context-sensitive pointer alias analysis using binary decision diagrams”, Whaley and Lam, PLDI 2004 
    >
    > • “Symbolic pointer analysis revisited”, Zhu and Calman, PDLI 2004 
    >
    > • “Points-to analysis using BDDs”, Berndl et al, PDLI 2003

  * ![image-20200509200706135](D:\OneDrive\Pictures\Typora\image-20200509200706135.png)

  * Use a BDD to represent transfer function

    * encode procedure as a function of its calling context
    * compact and efficient representation

  * Perform context-sensitive, inter-procedural analysis

    * similar to dataflow analysis
    * but across the procedure call graph

  * Gives accurate results and scales up to large programs

* Probabilistic Pointer Analysis

  * > • “A Probabilistic Pointer Analysis for Speculative Optimizations”, DaSilva and Steffan, ASPLOS 2006 
    >
    > • “Compiler support for speculative multithreading architecture with probabilistic points-to analysis”, Shen et al., PPoPP 2003 
    >
    > • “Speculative Alias Analysis for Executable Code”, Fernandez and Espasa, PACT 2002 
    >
    > • “A General Compiler Framework for Speculative Optimizations Using Data Speculative Code Motion”, Dai et al., CGO 2005 
    >
    > • “Speculative register promotion using Advanced Load Address Table (ALAT)”, Lin et al., CGO 2003

* Speculate `Maybe` Cases

  * ![image-20200509202455879](D:\OneDrive\Pictures\Typora\image-20200509202455879.png)
  * Implement a potentially unsafe optimization: Verify and Recover if necessary
  * ![image-20200509202214244](D:\OneDrive\Pictures\Typora\image-20200509202214244.png)
  * Data Speculation Optimizations
    * EPIC Instruction sets
      * Support for speculative load/store instructions (e.g., Itanium)
    * Speculative compiler optimizations
      * Dead store elimination, redundancy elimination, copy propagation, strength reduction, register promotion
    * Thread-level speculation (TLS)
      * Hardware and compiler support for speculative parallel threads
    * Transactional programming
      * Hardware and software support for speculative parallel transactions
  * Quantify `Maybe`: Estimate the potential benefit for speculating
    * ![image-20200509202433980](D:\OneDrive\Pictures\Typora\image-20200509202433980.png)
    * ![image-20200509202509591](D:\OneDrive\Pictures\Typora\image-20200509202509591.png)
  * Probabilistic Pointer Analysis Research Objectives
    * Accurate points-to probability information
      * at every static pointer dereference
    * Scalable analysis
      * Goal: entire SPEC integer benchmark suite
    * Understand scalability/accuracy tradeoff 
      * through flexible static memory model
    * Fixed
      * Bottom Up / Top Down Approach
      * Linear transfer functions (for scalability)
      * One-level context and flow sensitive
    * Flexible
      * Edge profiling (or static prediction)
      * Safe (or unsafe) 
      * Field sensitive (or field insensitive)
  * ![image-20200509202634383](D:\OneDrive\Pictures\Typora\image-20200509202634383.png)
  * ![image-20200509202643382](D:\OneDrive\Pictures\Typora\image-20200509202643382.png)



## Dynamic Code Optimization

* > John Whaley, “Partial Method Compilation Using Dynamic Profile Information”, OOPSLA’01
  >
  > Stadler et al., “Partial Escape Analysis and Scalar Replacement for Java,” CGO'14

* Beyond Static Compilation

  * Profile-based Compiler: high-level `->` binary, static
    * Use dynamic/runtime information collected in profiling passes
  * Interpreter: high-level, emulate, dynamic
  * Dynamic compilation / code optimization: high-level -> binary, dynamic
    * [[N: Catalyst, JIT]]
    * interpreter/compiler hybrid
    * supports cross-module optimization
    * can specialize program using runtime information
      * without separate profiling passes

* Dynamic Profiling Can Improve Compile-time Optimizations

  * Understanding common dynamic behaviors may help guide optimizations 
    * e.g., control flow, data dependences, input values
    * ![image-20200509203848004](D:\OneDrive\Pictures\Typora\image-20200509203848004.png)
  * Profile-based compile-time optimizations
    * e.g., speculative scheduling, cache optimizations, code specialization
  * ![image-20200509203927332](D:\OneDrive\Pictures\Typora\image-20200509203927332.png)
  * [[N: AutoFDO, gcc PGO]]
  * Collecting control-flow profiles is relatively inexpensive
    * profiling data dependences, data values, etc., is more costly
  * Limitations of this approach? 
    * e.g., need to get typical inputs
  * Instrumenting Executable Binaries
    * ![image-20200509204105853](D:\OneDrive\Pictures\Typora\image-20200509204105853.png)
    * The compiler could insert it directly 
    * A binary instrumentation tool could modify the executable directly – that way, we don’t need to modify the compiler – compilers that target the same architecture (e.g., x86) can use the same tool
  * Binary Instrumentation/Optimization Tools
    * Unlike typical compilation, the input is a binary (not source code)
    * One option: static binary-to-binary rewriting
      * ![image-20200509204206495](D:\OneDrive\Pictures\Typora\image-20200509204206495.png)
    * Challenges with static approach
      * what about dynamically-linked shared libraries? 
      * if our goal is optimization, are we likely to make the code faster? 
        * a compiler already tried its best, and it had source code (we don’t)
      * if we are adding instrumentation code, what about time/space overheads?
        * instrumented code might be slow & bloated if we aren’t careful
      * optimization may be needed just to keep these overheads under control

* (Pure) Interpreter

  * ```c++
    while (stillExecuting) {
        inst = readInst(PC);
        instInfo = decodeInst(inst);
        switch (instInfo.opType) {
        	case binaryArithmetic: …
        	case memoryLoad: …
    	    …
        }
        PC = nextPC(PC,instInfo);
    }
    
    ```

  * easy to change the way to execute code on-the-fly

  * runtime overhead

* Combination

  * the flexibility of an interpreter (analyzing and changing code dynamically)
  * the performance of direct hardware execution
  * increase the granularity of interpretation
    * instructions `->` chunks of code (e.g. procedures, basic blocks)
  * dynamically compile chunks `->` directly-executed optimized code (native)
    * store these compiled chunks in a software code cache
    * jump in and out of these cached chunks when appropriate
    * these cached code chunks can be updated
  * invest more time optimizing code chunks that are hot/important
    * easy to instrument the code, since already rewriting it
    * must balance (dynamic) compilation time with likely benefits

* Dynamic Compiler (JIT)

  * ```c++
    while (stillExecuting) {
        if (!codeCompiledAlready(PC)) {
    	    compileChunkAndInsertInCache(PC);
        }
        jumpIntoCodeCache(PC);
        // compiled chunk returns here when finished
        PC = getNextPC(…);
    }
    
    ```

  * JVM, dynamic binary instrumentation tools (Valgrind, PIN, Dynamo Rio), hardware virtualization (full emulation)

  * ![image-20200509222444916](D:\OneDrive\Pictures\Typora\image-20200509222444916.png)

* Dynamic Compilation / Code Optimization

  * Dynamic Compilation Policy
    * ![image-20200509222603600](D:\OneDrive\Pictures\Typora\image-20200509222603600.png)
    * ![image-20200509222613968](D:\OneDrive\Pictures\Typora\image-20200509222613968.png)
    * ![image-20200509222618047](D:\OneDrive\Pictures\Typora\image-20200509222618047.png)
  * Latency vs. Throughput
    * ![image-20200509222804807](D:\OneDrive\Pictures\Typora\image-20200509222804807.png)
  * Multi-Stage Dynamic Compilation System
    * ![image-20200509222833296](D:\OneDrive\Pictures\Typora\image-20200509222833296.png)
  * Granularity of Compilation
    * methods can be large, especially after inlining
      * Cutting/avoiding inlining too much hurts performance considerably
    * compilation time is proportional to the amount of code being compiled
      * many optimizations are not linear
    * Even “hot” methods typically contain some code that is rarely/never executed
    * Optimizing hot "code paths", not entire methods
      * Optimize only the most frequently executed code paths within a method
      * Track execution counts of basic blocks in Stages 1 & 2
      * Any basic block executing in Stage 2 is considered to be not rare
    * Beneficial secondary effect of improving optimization opportunities on the common paths
    * No need to profile any basic block executing in Stage 3: already fully optimized

* Dynamic Code Transformation

  * Partial Method Compilation
    * Based on profile data, determine the set of rare blocks
      * Use code coverage information from the first compiled version
      * ![image-20200509223604276](D:\OneDrive\Pictures\Typora\image-20200509223604276.png)
    * Perform live variable analysis
      * Determine the set of live variables at rare block entry points
    * Redirect the control flow edges that targeted rare blocks and remove the rare blocks
      * ![image-20200509224007479](D:\OneDrive\Pictures\Typora\image-20200509224007479.png)
    * Perform compilation normally
      * Analyses treat the interpreter transfer point as an unanalyzable method call
    * Record a map for each interpreter transfer point
      * In code generation, generate a map that specifies the location, in registers or memory, of each of the live variables
      * Maps are typically < 100 bytes
      * Used to reconstruct the interpreter state
      * ![image-20200509224049503](D:\OneDrive\Pictures\Typora\image-20200509224049503.png)
  * Partial Dead Code Elimination
    * Move computation that is only live on a rare path into the rare block, saving computation in the common case
    * ![image-20200509224124770](D:\OneDrive\Pictures\Typora\image-20200509224124770.png)
  * Partial Escape Analysis
    * Escape analysis finds objects that do not escape a method or a thread
      * Captured” by method:
        * can be allocated on the stack or in registers, avoiding heap allocation
        * scalar replacement: replace the object’s fields with local variables
      * “Captured” by thread:
        * can avoid synchronization operations
      * All Java objects are normally heap allocated, so this is a big win
    * Stack allocate objects that don’t escape in the common (i.e., non-rare) blocks
    * Eliminate synchronization on objects that don’t escape the common blocks
    * If a branch to a rare block is taken:
      * Copy stack-allocated objects to the heap and update pointers
      * Reapply eliminated synchronizations
      * ![image-20200509224249302](D:\OneDrive\Pictures\Typora\image-20200509224249302.png)
  * ![image-20200509224341175](D:\OneDrive\Pictures\Typora\image-20200509224341175.png)
  * Dynamic Optimizations in HotSpot JVM
    * ![image-20200509224400519](D:\OneDrive\Pictures\Typora\image-20200509224400519.png)
    * ![image-20200509224415654](D:\OneDrive\Pictures\Typora\image-20200509224415654.png)





## Memory Hierarchy Optimizations

* Types of Objects to Consider
  * Scalars
    * Locals/Globals/Procedure arguments
  * Structures & Pointers
    * within a node / across nodes
  * Arrays
    * usually accessed within loop nests
    * start of array + relative position within array
* Iteration Space & Loop Transformation
  * ![image-20200511154306312](D:\OneDrive\Pictures\Typora\image-20200511154306312.png)
  * Types of Data Reuse/Locality
    * Spatial
    * Temporal (Group)
    * Temporal (Self)
    * ![image-20200511154601658](D:\OneDrive\Pictures\Typora\image-20200511154601658.png)
* Optimizing the Cache Behavior of Array Accesses
  * when do cache misses occur?
    * use “locality analysis”
  * can we change the order of the iterations (or possibly data layout) to produce better behavior?
    * evaluate the cost of various alternatives
  * does the new ordering/layout still produce correct results?
    * use “dependence analysis”
* [[R: Check CS133 for some loop transformations & discussing]]
* Locality Analysis
  * Reuse: accessing a location that has been accessed in the past
  * Locality: accessing a location that is now found in the cache
  * Find data reuse (“reuse analysis”)
    * if caches were infinitely large, we would be finished
    * Map `n` loop indices into `d` array indices via array indexing function
      * ![image-20200512104102833](D:\OneDrive\Pictures\Typora\image-20200512104102833.png)
      * ![image-20200512104123756](D:\OneDrive\Pictures\Typora\image-20200512104123756.png)
      * Affine Array Indexes: the index for each dimension of the array is an affine expression of surrounding loop variables and symbolic constants
        * $c_0 + c_1 x_1 + \cdots + c_n x_n$
    * Temporal Reuse
      * $H i_1 + c = H i_2 + c \Rightarrow H(i_1 - i_2) = 0$
  * Determine “localized iteration space”
    * set of inner loops where the data accessed by an iteration is expected to fit within the cache
    * Localized if accesses less data than effective cache size
    * ![image-20200512111105078](D:\OneDrive\Pictures\Typora\image-20200512111105078.png)
  * Find data locality
    * reuse `/\` localized iteration space `=>` locality



## Array Dependence Analysis & Parallelization

* Data Dependence
  * $S_i$ precedes $S_j$ in execution
  * Flow/True dependence: `Si` computes a data value that `Sj` uses, $S_i \delta^t S_j$, RAW
  * Anti dependence: `Si` computes a data value that `Sj` overwrites, $S_i\delta^a S_j$, WAR
  * Output dependence: `Si` computes a data value that `Sj` overwrites, $S_i \delta^o S_j$, WAW
  * Input dependence: `Si` uses a data value that `Sj` also uses, $S_i \delta^i S_j$, RAR
* Data Dependence Graph
  * `G=(V, E)`, where `V` represent statements in the program & directed edge `E` represent dependence relations
  * ![image-20200512113023621](D:\OneDrive\Pictures\Typora\image-20200512113023621.png)
  * source, sink
  * dependence distance: number of iterations between source and sink
  * dependence direction
  * loop-independent/loop-carried
  * ![image-20200512113728459](D:\OneDrive\Pictures\Typora\image-20200512113728459.png)
  * ![image-20200512113746715](D:\OneDrive\Pictures\Typora\image-20200512113746715.png)
  * ![image-20200512113821580](D:\OneDrive\Pictures\Typora\image-20200512113821580.png)
  * ![image-20200512113834172](D:\OneDrive\Pictures\Typora\image-20200512113834172.png)
* Dependence Testing
  * ![image-20200512115410537](D:\OneDrive\Pictures\Typora\image-20200512115410537.png)
  * ![image-20200512120903129](D:\OneDrive\Pictures\Typora\image-20200512120903129.png)
  * ![image-20200512120906735](D:\OneDrive\Pictures\Typora\image-20200512120906735.png)
  * dependence testing `<=>` integer linear programming (ILP) of 2d variables & `m + d` constraints
  * dependence tester: determines if there exists 2 iteration vectors `k` and `j` that satisfies these constraints
    * dependence distance vector $\vec{j} - \vec{k}$
    * dependence direction vector `sign(j - k)`
    * NP-complete
    * exact: A dependence test that reports dependence only when there is dependence
    * conservative
* Dependence Testers
  * Lamport's Test
    * Lamport’s Test is used when there is a single index variable in the subscript expressions, and when the coefficients of the index variable in both expressions are the same
    * $A(\cdots, b \cdot i + c_1, \cdots) = \cdots$
    * $\cdots = A(\cdots, b \cdot i + c_2, \cdots)$
    * ![image-20200512193624812](D:\OneDrive\Pictures\Typora\image-20200512193624812.png)
    * ![image-20200512194232055](D:\OneDrive\Pictures\Typora\image-20200512194232055.png)
  * GCD Test
    * $\sum_{i=1}^n a_i x_i = c$ where $a_i$ and $c$ are integers
    * an integer solution exists iff. `gcd(a1, ..., an) | c`
    * ignore loop bounds
    * gives no information on distance/direction of dependence
    * often `gcd(a1, ..., an) = 1`, false dependencies
    * ![image-20200512194443636](D:\OneDrive\Pictures\Typora\image-20200512194443636.png)
  * Banerjee&#39;s Inequalities
  * Generalized GCD Test
  * Power Test
  * I-Test
  * Omega Test
  * Delta Test
  * Stanford Test
  * Complications
    * unknown loop bounds `i = 1, N`
    * triangular loop bounds `i = 1, N; j = 1, i - 1`
    * user variables: `a[i] = a[i + k]`
    * privatization
* Loop Parallelization
  * A dependence is said to be carried by a loop if the loop is the outermost loop whose removal eliminates the dependence. If a dependence is not carried by the loop, it is loop-independent.
  * The iterations of a loop may be executed in parallel with one another if and only if no dependences  are carried by the loop
  * outer loop parallelism: fork/join
  * inner loop parallelism: SIMD/vectorization
* Loop Interchange
  * When is loop interchange legal?
    * when the “interchanged” dependences remain lexicographically positive!
  * ![image-20200512195902279](D:\OneDrive\Pictures\Typora\image-20200512195902279.png)
  * ![image-20200512195910693](D:\OneDrive\Pictures\Typora\image-20200512195910693.png)
  * ![image-20200512200105311](D:\OneDrive\Pictures\Typora\image-20200512200105311.png)
  * ![image-20200512200115975](D:\OneDrive\Pictures\Typora\image-20200512200115975.png)
* [Loop Transformation](https://www.cs.colostate.edu/~mstrout/CS553/slides/lecture19.pdf)
* [A Data Locality Optimizing Algorithm](https://dl.acm.org/doi/pdf/10.1145/989393.989437)





## Distinctness Analysis

* High-Level Program Optimizations are Difficult

  * Modern multicore archtecture
  * Human refactors by understanding high-level invariants & semantics
    * (Data Structure API) Key-value map insertions are commutative when accessing two different keys. 
      * human: `map.put(k, v)`
      * compiler: `int h = key.x * 8931 + key.y`
    * (Program invariant) `Item.analyze()` accesses only `this`.
    * (Program invariant) No element appears in `list` more than once

* Solution: DSL?

  * DSLs separate algorithm and implementation!
  *  not always applicable
    * Legacy code: already exists (rewrite costs effort + risk)
    * Mixed applications: multiple kernels (DSL integration?)
    * DSLs with limitations: a program may not map cleanly onto DSL

* General Language + Analysis

  * ![image-20200512201451198](D:\OneDrive\Pictures\Typora\image-20200512201451198.png)

* First-Class Data Structures

  * provide compiler intrinsics for key-value maps and lists so that analyses can reason directly about these data structures

  * provide key-value maps as new language-level object type

    * ```prolog
      // Map Store
      MapPointsTo(mapobj, keyobj, pointee) :-
          MapStore(map, key, value),
          VarPointsTo(map, mapobj),
          VarPointsTo(key, keyobj),
          VarPointsTo(value, pointee).
      // Map Load
      VarPointsTo(dest, pointee) :-
          MapLoad(dest, map, key),
          VarPointsTo(map, mapobj),
          VarPointsTo(key, keyobj),
          MapPointsTo(mapobj, keyobj, pointee).
      // Store
      FieldPointsTo(obj, field, pointee) :-
          Store(ptr, field, value),
          VarPointsTo(ptr, obj),
          VarPointsTo(value, pointee).
      // Load
      VarPointsTo(dest, pointee) :-
          Load(dest, ptr, field),
          VarPointsTo(ptr, obj),
          FieldPointsTo(obj, field, pointee).
      ```

    * ```text
      map := mapnew
      value := mapget map, key
      		 mapput map, key, value
      value := mapremove map, key
      flag := mapprobe map, key
      len := maplength map
      key := equivclass userkey
      it := mapkeyiter map
      flag := iterhasnext it
      value := iternext it
      ```

  * ![image-20200512203911612](D:\OneDrive\Pictures\Typora\image-20200512203911612.png)

* Semantic Models: Explicit Library Semantics

  * replace portions of program as analyzed with simpler logic
    * Modify callgraph during analysis: resolve to “model override” methods
  * Models are conservative
    * May have additional side-effects: overapproximate accessed-memory footprint
    * May return additional or “unknown” values

* Distinctness Analysis

  * Standard parallelizability analyses understand arrays with affine indexing functions

  * Alias analysis for loop parallelization?

  * annotate points-to edges to indicate additional non-aliasing

    * A variable is distinct with respect to a loop if its value in iteration i does not alias its value in iteration j, within a single loop instance
    * ![image-20200512205058461](D:\OneDrive\Pictures\Typora\image-20200512205058461.png)
    * distinct heap?
      * A field on a heap abstraction is distinct if, for each object instance in this abstraction, the field has a different pointer value
      * ![image-20200512205049191](D:\OneDrive\Pictures\Typora\image-20200512205049191.png)

  * infer heap-field distinctness

    * A field on a heap abstraction is distinct if:
      * For every loop around the one store statement to the field,
        * The stored value is distinct w.r.t. this loop, OR
        * The stored-to pointer is constant w.r.t. this loop.

  * use heap-field distinctness

    * A load result is distinct w.r.t. a loop if:
      * The loaded-from pointer is distinct w.r.t. this loop, AND
      * The heap field on all loaded-from abstractions are distinct, AND
      * No two loaded-from abstractions have intersecting points-to sets

  * Map distinctness

    * Key-Value Maps have two possible types of distinctness for a given (Map, Key, Value) 3-tuple of abstractions

      * Global map distinctness: no two keys in any two maps point to same value
      * Within-map distinctness: no two keys in a single map point to same value

    * derive the inverted (not-distinct) forms from the more intuitive positive-polarity versions with help of DeMorgan’s Law:

      * A field is not distinct if 
        * (i) more than one store writes to it, or 
        * (ii) for any store, for any loop in context, stored value is not-distinct and pointer is not-constant
      * A load result is not distinct if 
        * (i) it reads from abstractions with overlapping field points-to sets, or 
        * (ii) the field is not-distinct on any pointed-to abstraction, or 
        * (iii) the pointer is not-distinct.

    * ```prolog
      NotDistinct(var, loop) :-
          Assign(instruction, var, from),
          NotDistinct(from, loop),
          LoopInContext(instruction, loop).
      NotConstant(var, loop) :-
          Assign(instruction, var, from),
          NotConstant(from, loop),
          LoopInContext(instruction, loop).
      FieldNotDistinct(obj, field) :-
          Store(instruction1, ptr1, value),
          VarPointsTo(ptr1, obj),
          Store(instruction2, ptr2, value),
          VarPointsTo(ptr2, obj),
          instruction1 != instruction2.
      FieldNotDistinct(obj, field) :-
          Store(instruction, ptr, value),
          LoopInContext(instruction, loop),
          VarNotDistinct(value, loop),
          VarNotConstant(ptr, loop).
      VarNotDistinct(dest, loop) :-
          Load(inst, ptr, field, dest),
          VarPointsTo(ptr, obj),
          FieldNotDistinct(obj, field),
          LoopInContext(inst, loop).
      VarNotDistinct(dest, loop) :-
          Load(inst, ptr, field, dest),
          VarNotDistinct(ptr, loop).
      // Map Store
      MapNotDistinct(mapobj, keyobj), MapNotDistinctWithinMap(mapobj, keyobj) :-
          MapStore(inst1, map1, key1, dest1),
          VarPointsTo(map1, mapobj),
          VarPointsTo(key1, keyobj),
          MapStore(inst2, map2, key2, dest2),
          VarPointsTo(map2, mapobj),
          VarPointsTo(key2, keyobj),
          inst1 != inst2.
      MapNotDistinct(mapobj, keyobj) :-
          MapStore(inst, map, key, dest),
          VarPointsTo(map, mapobj),
          VarPointsTo(key, keyobj),
          VarNotDistinct(dest, loop),
          (VarNotConstant(map, loop); VarNotConstant(key, loop)).
      MapNotDistinctWithinMap(mapobj, keyobj) :-
          MapStore(inst, map, key, dest),
          VarPointsTo(map, mapobj),
          VarPointsTo(key, keyobj),
          VarNotDistinct(dest, loop),
          VarNotConstant(key, loop).
      // Map Load
      VarNotDistinct(dest, loop) :-
          MapLoad(inst, map, key, dest),
          VarPointsTo(map, mapobj),
          VarPointsTo(key, keyobj),
          MapNotDistinct(mapobj, keyobj),
          MapNotDistinctWithinMap(mapobj, keyobj),
          LoopInContext(inst, loop).
      VarNotDistinct(dest, loop) :-
          MapLoad(inst, map, key, dest),
          VarPointsTo(map, mapobj),
          VarPointsTo(key, keyobj),
          // may still be distinct within map
          MapNotDistinct(mapobj, keyobj),
      	(VarNotConstant(map, loop); VarNotDistinct(key, loop)).
      VarNotDistinct(dest, loop) :-
          MapLoad(inst, map, key, dest),
          VarNotDistinct(map, loop),
          VarNotDistinct(key, loop).
      ```

  * ![image-20200512205600545](D:\OneDrive\Pictures\Typora\image-20200512205600545.png)

  * Side-Effect Analysis for Parallelization

    * ![image-20200512205744844](D:\OneDrive\Pictures\Typora\image-20200512205744844.png)
    * For each written-to location (`abstraction.field` or `map[key]`): 
      * Every written-to pointer to this location is distinct w.r.t. Loop
      * All of the written-to pointers (if > 1) alias each other (same distinct object)
    * See thesis for: must-alias analysis; map/list side-effects + commutativity; locking

* Systematically Leveraging Dynamic Checks

  * insert minimal set of checks while maximizing parallelized loops
  * extend static-analysis rules in a systematic way
    * Step 1. Compute possible distinctness
    * Step 2. Evaluate parallelization; choose actually-needed dynamic possibilities
    * Step 3. Propagate needed distinctness backward to choose check sites
  * ![image-20200512210038522](D:\OneDrive\Pictures\Typora\image-20200512210038522.png)

* Dynamic Heap-Distinctness Checks

  * maintain a non-distinct bit on pointer fields with checks
    * Update on store if containing loop has had a failed check
    * Check on load and serialize on failure (as for variable checks)
  * ![image-20200512210208387](D:\OneDrive\Pictures\Typora\image-20200512210208387.png)

* Data-structure-aware analysis framework

  * First-class primitives for key-value maps and lists

* DAEDALUS: New loop-centric, simple alias analysis using distinctness

  * Analyzes cross-loop-iteration and on-heap pointer aliasing

* ICARUS: Hybrid dynamic-static analysis approach to improve precision

  * Systematic method of deriving hybrid analysis from static analysis rules
  * Execution techniques to enable loop parallelization with dynamic checks

* ![image-20200512210334099](D:\OneDrive\Pictures\Typora\image-20200512210334099.png)



## Region-Based Analysis

* Exploit the structure of block-structured programs in data flow
  * better understanding of data flow
  * faster for harder analyses
  * useful for analyses related to structure, e.g. global scheduling
* Use of structure in induction variables, loop invariant
  * motivated by nature of the problem
  * can we use structure for speed?
* Iterative algorithm for data flow
  * alternative algorithm
* Reducibility
  * all retreating edges of DFS Tree are back edges (`t->h`, h dominates t)
  * reducible graphs converge quickly
  * new algorithm exploits & requires reducibility
* A __region__ in a flow graph is a set of nodes with a __header__ that __dominates__ all other nodes in a region
  * ![image-20200512214505614](D:\OneDrive\Pictures\Typora\image-20200512214505614.png)
* Region-Based Analysis
  * Transfer function $F_{R, B}$: summarize effect from beginning of region `R` to end of basic block `B`
  * Recursively - until the program is one region
    * construct a larger region `R` from smaller regions 
    * construct `F(R,B)` from transfer functions for smaller regions
  * `P`: the region for the entire program
  * `v`: initial value at entry node
    * `out[B] = F(P, B)(v)`
    * `in[B] = /\B' out[B']` where `B'` is a predecessor of `B`
* Algorithm
  * Operations on transfer functions
    * Composition
      * ![image-20200512225912294](D:\OneDrive\Pictures\Typora\image-20200512225912294.png)
    * Meet
      * ![image-20200512225923057](D:\OneDrive\Pictures\Typora\image-20200512225923057.png)
    * Closure
      * ![image-20200512225939449](D:\OneDrive\Pictures\Typora\image-20200512225939449.png)
  * Structure of Nested Regions
    * T1-T2 rules (Hecht & Ullman) for Flow Graphs
      * T1: Remove a loop
        * If `n` is a node with a loop, i.e. an edge `n->n`, delete that edge (all such edges for n)
      * T2: Remove a vertex w/unique predecessor
        * If there is a node `n` that has a unique predecessor, `m`, then `m` may consume `n` by deleting `n` and making all successors of `n` be successors of `m`
    * reduced graph
      * vertex: a subgraph of original graph (a region)
      * edge: edge in original graph
    * limit flow graph: result of exhaustive application of T1 & T2
      * independent of order of application
      * reducible flow graph: limit flow graph has a single vertex
  * Transfer functions (How to construct transfer functions that correspond to the larger regions?)
    * For T2 Rule
      * ![image-20200512231112118](D:\OneDrive\Pictures\Typora\image-20200512231112118.png)
      * $F_{R, B}$: summarizes the effects from beginning of `R` to end of `B`
      * $F_{R, in(H_2)}$: summarizes the effects from beginning of `R` to beginning of `H2`
        * Unchanged for blocks `B` in region `R1`
        * $F_{R, in(H_2)} = \wedge_p F_{R, P}$ where `p` is a predecessor block of `H2`
        * For blocks `B` in region `R2`: $F_{R, B} = F_{R2, B} \circ F_{R, in(H_2)}$
    * For T1 Rule
      * ![image-20200512231543977](D:\OneDrive\Pictures\Typora\image-20200512231543977.png)
      * the header of `R1` (i.e. `H`) is also the header of `R`
      * already know how to get from `H` to `B` for every block `B` in `R1` : i.e. `F(R1,B)`
        * the last step in getting from the new `R` to `B` (composition)
      *  need to get from `R` to the input of `H`, including back edges
        * involves both meet (`/\`) and closure (`*`) operations
      * Transfer Function $F_{R, B}$
        * $F_{R, in(H)} = (\wedge_p F_{R_1, P})^*$ where `p` is a predecessor block of `H` in `R`
        * $F_{R, B} = F_{R1, B} \circ F_{R, in(H)}$
* ![image-20200512232255222](D:\OneDrive\Pictures\Typora\image-20200512232255222.png)
* ![image-20200512232339277](D:\OneDrive\Pictures\Typora\image-20200512232339277.png)
* Complexity of Algorithm
* Optimization
  * $m$: \# of edges, $n$: \# of nodes
  * compute $F_{R, B}$ for every region `B` is in is expensive
  * interested in the entire region; need to compute  only $F_{E, B}$ for every `B`
    * many common subexpressions
    * $m$ functions calculated
  * need to compute $F_{R, in(R')}$ where `R'` represents the region whose header is subsumed
    * $n$ functions calculated
  * total number of $F_{R, B}$ calculated: $(m + n)$
    * Practical algorithm: `O(m log n)`  (data structure keeps header relationship)
    * Complexity: $O(m\alpha(m,n))$, $\alpha$ is inverse Ackermann function
* Reducibility
  * ![image-20200512234124039](D:\OneDrive\Pictures\Typora\image-20200512234124039.png)
  * If no T1, T2 is applicable before graph is reduced to single node, then split node (make `k` copies of node, one per predecessor) and continue
  * worst case: exponential
  * Most graphs (including GOTO programs) are reducible
    * [[N: that's why Dijkstra says GOTO is bad...]]
* Comparison with Iterative Data Flow Analysis
  * Applicability
    * Definitions of F* can make technique more powerful than iterative algorithms
    * Backward flow: reverse graph is not typically reducible.
      * Requires more effort to adapt to backward flow than iterative algorithm
    * More important for inter-procedural optimization, optimizations related to loop nesting structure
  * Speed
    * Irreducible graphs
      * Iterative algorithm can process irreducible parts uniformly
      * Serious “irreducibility” can be slow with region-based analysis
    * Reducible graphs & Cycles do not add information (common, e.g. reaching definition, cycle can be removed to form a shorter path from `n1` to `nk` such that `d` reaches `nk`)
      * Iterative: `(depth + 2)` passes, `O(m*depth)` steps
      * depth is 2.75 average, independent of code length
      * Region-based analysis: Theoretically almost linear, typically `O(m log n)` steps
    * Reducible graph & Cycles add information* (e.g. constant propagation)
      * Iterative takes longer to converge
      * Region-based analysis remains the same





## Instruction Scheduling

* Goal

  * Assume that the remaining instructions are all essential
  * execute the instructions in parallel

* Hardware Support for Parallel Execution

  * Pipelining
    * break instruction into stages that can be overlapped
  * Superscalar Processing
    * multiple (independent) instructions can proceed simultaneously through the same pipeline stages
  * Multicore

* Constraints on Scheduling

  * Hardware Resources
    * Processors have finite resources, and there are often constraints on how these resources can be used.
      * finite issue width
      * limited FUs per inst. type
      * limited pipelining within a given functional unit
  * Data Dependences
    * renaming -> WAW/WAR
    * ambiguous data dependences are very common in practice
      * difficult to solve even with pointer analysis
    * Multi-cycle execution latencies
      * non-trivial critical path lengths through code
  * Control Dependences
    * impractical to schedule for all possible paths
    * recovery costs can be non-trivial if you are wrong

* List Scheduling

  * most common technique for scheduling instructions within a basic block

  * > “An Experimental Evaluation of List Scheduling", Keith D. Cooper, Philip J. Schielke, and Devika Subramanian. Rice University, Dept of Computer Science Tech. Rep. 98-326, 1998. 
    >
    > “Despite the importance of scheduling, we know quite little about the behavior of list scheduling—the most widely used technique for instruction scheduling [1, 3].”

  * Input: 

    * Data Precedence Graph (DPG)
      * ![image-20200513142723189](D:\OneDrive\Pictures\Typora\image-20200513142723189.png)
    * Machine Parameters (FUs, Latencies, Pipelining)

  * Output

    * Scheduled Code

  * Maintain a list of instructions that are ready to execute

    * data dependence constraints would be preserved
    * machine resources are available

  * Moving cycle-by-cycle through the schedule template

    * choose instructions from the list & schedule them
    * update the list for the next cycle

  * widely used for instruction scheduling on in-order processors

    * only within a basic block
    * Modern out-of-order processors perform their own dynamic scheduling
      * List scheduling can be used to feed the dynamic scheduler in a good order

  * Priorities

    * can be arbitrarily sophisticated
      * filling branch delay slots in early RISC processors
    * true dependency
      * latency-weighted depth in the DPG
      * ![image-20200513141358402](D:\OneDrive\Pictures\Typora\image-20200513141358402.png)
    * anti-dependency
      * ![image-20200513141428658](D:\OneDrive\Pictures\Typora\image-20200513141428658.png)

  * ![image-20200513141446973](D:\OneDrive\Pictures\Typora\image-20200513141446973.png)

    * Breaking ties arbitrarily may not be the best approach

* Backward List Scheduling

  * reverse the direction of all edges in the DPG
  * schedule the finish times of each operation
    * start times must still be used to ensure Functional Unit availability
  * ![image-20200513141550363](D:\OneDrive\Pictures\Typora\image-20200513141550363.png)
  * clusters operations near the end (vs. the beginning)
  * may be either better or worse than forward scheduling

* ![image-20200513141633963](D:\OneDrive\Pictures\Typora\image-20200513141633963.png)

* ![image-20200513144046495](D:\OneDrive\Pictures\Typora\image-20200513144046495.png)

* [Scheduling](https://www.inf.ed.ac.uk/teaching/courses/copt/lecture-6.pdf)





## Global Scheduling

* Control equivalence

  * Two operations `o1` and `o2` are control equivalent if `o1` is executed if and only if `o2` is executed. (also for blocks)

* Control dependence

  * An op `o2` is control dependent on op `o1` if the execution of `o2` depends on the outcome of `o1` .

* Speculation

  * An operation `o` is speculatively executed if it is executed before all the operations it depends on (control-wise) have been executed. 
  * Requirements to execute operation speculatively?
    * No side-effects, does not raise an exception
    * Does not violate data dependences

* Code Motion

  * Goal: Shorten execution time probabilistically
    * based on estimated frequency of control path
  * Moving instructions up
    * Move instruction to a cut set (from entry)
    * Speculation: even when not anticipated
  * Moving instructions down
    * Move instruction to a cut set (from exit)
    * May execute extra instruction
    * Can duplicate code

* General Purpose Applications

  * Lots of data dependences
  * Key performance factor: memory latencies
  * Move memory fetches up
    * Speculative memory fetches can be expensive
  * Control-intensive: get execution profile
    * Static estimation
      * Innermost loops are frequently executed
        * back edges are likely to be taken
      * Edges that branch to exit and exception routines are not likely to be taken
    * Dynamic profiling
      * Instrument code and measure using representative data

* A Basic Global Scheduling Algorithm

  * Schedule innermost loops first
  * Only upward code motion, to either:
    * a “control-equivalent” block (non-speculative), or
    * a control-equivalent block of a dominating predecessor (speculative, 1 branch)
  * No creation of copies

* Program Representation

  * A procedure is represented as a hierarchy of loop regions
    * The entire control flow graph is a region
    * Each natural loop (single entry with back edge to it) in the flow graph is a region
    * Natural loops are hierarchically nested
  * Schedule regions from inner to outer
    * treat inner loop as a black box unit: can schedule around it but not into it
    * ignore all the loop back edges → get an acyclic graph

* `NonSpeculative(B)`: all blocks that are control equivalent to `B` and dominated by `B`

* `Speculative(B)`: all blocks `B'` not control equivalent to `B` such that

  * `B'` is a successor of at least one block `B’’` that is control equivalent to `B`, and
  * `B’` is dominated by `B’’`

* ![image-20200513151551614](D:\OneDrive\Pictures\Typora\image-20200513151551614.png)

* ```text
  Basic Algorithm:
  
  Compute data dependences;
  For each region R in the hierarchy of loop regions from inner to outer {
      For each basic block B of R in prioritized topological order {
          CandInsts = ready instructions in NonSpeculative(B)  Speculative(B);
          For (t = 1, 2, ... until all instructions from B are scheduled) { // schedule time slots in order
              For (n in CandInst in priority order) { // may or may not be from B
                  if (ok to move n to B && n has no resource conflicts at time t) {
                      S(n) = < B, t > ; // instruction n is mapped to basic block B and time slot t
                      Update resource commitments;
                      Update data dependences; // what could have changed?
              	}
          	}
          	Update CandInsts; // scheduled insts will often make new insts ready
          }
      }
  }
  // Priority functions: Non-speculative before speculative, and otherwise use same priority as in list scheduling
  // Ok to move: Don’t speculatively move a store instruction, don’t move a procedure call, etc
  ```

* If a variable is live at a program point, then we cannot move a speculative definition to the variable above that program point

* ![image-20200513160547483](D:\OneDrive\Pictures\Typora\image-20200513160547483.png)

* Extension

  * In region-based scheduling, loop iteration boundary limits code motion: operations from one iteration cannot overlap with those from another
  * Prepass before scheduling: loop unrolling
  * Especially important to move operation up loop back edges





## Software Pipelining & Prefetching

* ![image-20200513160635455](D:\OneDrive\Pictures\Typora\image-20200513160635455.png)
  * Numerical Code
    * Software pipelining is useful for machines with a lot of pipelining and instruction level parallelism
    * Compact code
    * Limits to parallelism: dependences, critical resource
* Loop unrolling
  * ![image-20200513194936050](D:\OneDrive\Pictures\Typora\image-20200513194936050.png)
* Software Pipelined
  * ![image-20200513194954067](D:\OneDrive\Pictures\Typora\image-20200513194954067.png)
  * Unlike unrolling, software pipelining can give optimal result with small code size blowup
  * Locally compacted code may not be globally optimal
  * DOALL: Can fill arbitrarily long pipelines with infinitely many iterations
* NPC
* Lower bound of initiation interval (II)
  * for all resource `i`, 
    * number of units required by one iteration: `ni` 
    * number of units in system: `Ri`
  * resource constraints $\max_i \lceil \frac{n_i}{R_i} \rceil$
* Scheduling Constraints
  * Resources
    * `RT`: resource reservation table for single iteration
    * `RT_s` : modulo resource reservation table (steady state)
      * $RT_s[i] = \sum_{t \mid (t \bmod T = i)}RT[t]$
    * ![image-20200513231930188](D:\OneDrive\Pictures\Typora\image-20200513231930188.png)
  * Precedence
    * `S(n)`: schedule for `n` with respect to the beginning of the schedule
    * ![image-20200513231907001](D:\OneDrive\Pictures\Typora\image-20200513231907001.png)
    * edge $<\delta, d>$: <iteration difference, delay>
      * $\delta \cdot T + S(n_2) - S(n_1) \geq d$
* Minimum Initiation Interval
  * For all cycle `c`
  * $T = \max_c \text{CycleLength}(c) / \text{IterationDifference}(c)$
  * ![image-20200513234107319](D:\OneDrive\Pictures\Typora\image-20200513234107319.png)
* Software Pipelining Acyclic Dependence Graphs
  * Find lower bound of initiation interval: `T0`
    * based on resource constraints
  * For `T = T0 , T0+1, ...` until all nodes are scheduled
    * For each node `n` in topological order
      * `s0 = ` earliest `n` can be scheduled
      * for each `s = s0, s0+1, ..., s0+T-1`
        * if `NodeScheduled(n, s)`, break
      * if `n` cannot be scheduled, break 
  * `NodeScheduled(n, s)`: check resources of `n` at `s` in modulo resource reservation table
  * Can always meet the lower bound if: 
    * every operation uses only 1 resource, and 
    * no cyclic dependences in the loop
  * Cyclic graphs
    * ![image-20200513235645316](D:\OneDrive\Pictures\Typora\image-20200513235645316.png)
  * ![image-20200513235707704](D:\OneDrive\Pictures\Typora\image-20200513235707704.png)
* Software Pipelining with Modulo Variable Expansion
  * Normally, every iteration uses the same set of registers
    * introduces artificial anti-dependences for software pipelining
  * Modulo variable expansion algorithm
    * schedule each iteration ignoring artificial constraints on registers
    * calculate life times of registers
    * degree of unrolling `= max_r (lifetime_r /T)`
    * unroll the steady state of software pipelined loop to use different registers
  * Code generation
    * generate one pipelined loop with only one exit (at beginning of steady state)
    * generate one unpipelined loop to handle the rest
    * code generation is the messiest part of the algorithm
* Software Prefetching
  * ![image-20200514000416688](D:\OneDrive\Pictures\Typora\image-20200514000416688.png)
  * overlap memory accesses with computation and other accesses
  * tolerate latency
  * Types of Prefetching
    * Cache Blocks: 
      * +: no instruction overhead 
      * −: best only for unit-stride accesses
    * Nonblocking Loads:
      * +: no added instructions 
      * −: limited ability to move back before use
    * Hardware-Controlled Prefetching:
      * +: no instruction overhead 
      * −: limited to constant-strides and by branch prediction
    * Software-Controlled Prefetching: 
      * +: minimal hardware support and broader coverage 
      * −: software sophistication and overhead
  * possible only if addresses can be determined ahead of time 
  * coverage factor: fraction of misses that are prefetched 
    * maximize coverage factor
  * unnecessary if data is already in the cache 
    * minimize unnecessary prefetches
  * effective if data is in the cache when later referenced
    * maximize effectiveness
    * minimize overhead per prefetch
  * Analysis: what to prefetch / Locality Analysis
    * ![image-20200514001016361](D:\OneDrive\Pictures\Typora\image-20200514001016361.png)
    * ![image-20200514001033142](D:\OneDrive\Pictures\Typora\image-20200514001033142.png)
    * both dense and indirect references
    * difficult to predict whether indirections hit or miss
  * Scheduling: when/how to issue prefetches
    * Loop splitting
      * Decompose loops to isolate cache miss instances
        * cheaper than inserting IF(Prefetch Predicate) statements
      * ![image-20200514001113290](D:\OneDrive\Pictures\Typora\image-20200514001113290.png)
      * Loop peeling: split any problematic first (or last) few iterations from the loop & perform them outside of the loop body
      * Apply transformations recursively for nested loops
      * Suppress transformations when loops become too large (avoid code explosion)
    * Software pipelining
      * ![image-20200514001159164](D:\OneDrive\Pictures\Typora\image-20200514001159164.png)
      * ![image-20200514001244789](D:\OneDrive\Pictures\Typora\image-20200514001244789.png)
    * when/how to issue prefetches
      * modification of software pipelining algorithm
        * ![image-20200514001324699](D:\OneDrive\Pictures\Typora\image-20200514001324699.png)





## Locality Analysis & Prefetching

* Temporal reuse
  * ![image-20200514113616851](D:\OneDrive\Pictures\Typora\image-20200514113616851.png)
  * `=>` nullspace of `H`
* Spatial reuse
  * assume two array elements share the same cache line iff they differ only in the last dimension
    * row major order
    * a row is made up of many cache lines...
  * replace last row of `H` with zeros, creating `Hs`
  * `=>` nullspace of `Hs`
  * ![image-20200514123709512](D:\OneDrive\Pictures\Typora\image-20200514123709512.png)
* Group reuse
  * Limit the analysis to consider only accesses with same `H`
    * i.e., index expressions that differ only in their constant terms
  * Determine when access same location (temporal) or same row (spatial)
  * Only the “leading reference” suffers the bulk of the cache misses
* Localized Iteration Space
  * Localized if accesses less data than effective cache size
  * ![image-20200514144658929](D:\OneDrive\Pictures\Typora\image-20200514144658929.png)
  * ![image-20200514144704733](D:\OneDrive\Pictures\Typora\image-20200514144704733.png)
* Prefetching for Pointer-Based Structures
  * linked lists, trees, graphs
  * Automatic compiler-based prefetching for pointer-based data structures
  * ![image-20200514211754807](D:\OneDrive\Pictures\Typora\image-20200514211754807.png)
  * Pointer-chasing problem: any scheme which follows the pointer chain is limited to a rate of 1/L
    * `n[i]` needs to know `&n[i+d]`  without referencing the `d-1` intermediate nodes
  * Greedy prefetching
    * use existing pointer(s) in `n[i]` to approximate `&n[i+d]`
    * Prefetch all neighboring nodes
      * hopefully, we will visit other neighbors later
    * ![image-20200514212122934](D:\OneDrive\Pictures\Typora\image-20200514212122934.png)
      * [[Q: need to understand the data structure semantics?]]
    * Reasonably effective in practice
    * little control over the prefetching distance
    * most widely applicable algorithm
  * History-Pointer prefetching
    * add new pointer(s) in `n[i]` to approximate `&n[i+d]`
      * history-pointers are obtained from some recent traversal
    * Trade space & time for better control over prefetching distances
    * ![image-20200514212224321](D:\OneDrive\Pictures\Typora\image-20200514212224321.png)
  * Data-Linearization prefetching
    * compute `&n[i+d]` directly from `&n[i]` (no ptr deref)
    * Map nodes close in the traversal to contiguous memory
    * ![image-20200514212241913](D:\OneDrive\Pictures\Typora\image-20200514212241913.png)
  * ![image-20200514212252288](D:\OneDrive\Pictures\Typora\image-20200514212252288.png)





## Register Allocation: Coalescing

* When copy propagation fails
  * Use of copy target has multiple (conflicting) reaching definitions
  * Copy target still live even after some successful copy propagations
  * ![image-20200514213513088](D:\OneDrive\Pictures\Typora\image-20200514213513088.png)
  * copy instructions may still exist at the time register allocation is performed
* Coalescing: treat the copy source and target as the same node in the interference graph
  * It is legal to coalesce `X` and `Y` for a `Y = X` copy instruction if (conservative)
    * the live ranges of `X` and `Y` do not overlap
  * coalescing can
    * save a copy instruction
    * but cause significant spilling overhead if we can no longer color the graph
  * coalesce unless it would make a colorable graph non-colorable
    * predicting colorability is tricky
      * it depends on the shape of the graph, NP-hard
  * augment the interference graph
    * Coalescing candidates are represented by a new type of interference graph edge:
      * dotted lines: coalescing candidates
        * try to assign vertices the same color
      * solid lines: interference (i.e., live ranges overlap)
        * vertices must be assigned different colors
  * To ensure that coalescing does not cause spilling:
    * check that the degree < N invariant is still locally preserved after coalescing
      * • if so, then coalescing won’t cause the graph to become non-colorable
* Simple & Safe Coalescing Algorithm
  * We can safely coalesce nodes X and Y with a coalescing edge if `(|X| + |Y|) < N`
    *  `|X| =` degree of node X counting only interference (not coalescing) edges
  * ![image-20200514215220747](D:\OneDrive\Pictures\Typora\image-20200514215220747.png)
  * `X`, `Y` share neighbors?
  * Spilling only occurs if there is no node with degree `< N` to push on the stack
  * When would coalescing cause the stack pushing (aka “simplification”) to get stuck?
    * coalesced node must have a degree `>= N`
      * otherwise, it can be pushed on the stack, and we are not stuck
    * AND it must have at least `N` neighbors that each have a degree `>= N`
      * otherwise, all neighbors with degree `< N` can be pushed before this node
        * reducing this node’s degree below `N` (and therefore we aren’t stuck)
* Brigg's Algorithm
  * Nodes `X` and `Y` (with a coalescing edge) can be coalesced if:
    * (number of neighbors of X/Y with degree `>= N`) `< N`
      * all other neighbors can be pushed on the stack before this node
      * and then its degree is `< N`, so then it can be pushed
  * ![image-20200514215609696](D:\OneDrive\Pictures\Typora\image-20200514215609696.png)
* George's Algorithm
  * coalescing makes coloring no worse than given `X`
  * ![image-20200514215658716](D:\OneDrive\Pictures\Typora\image-20200514215658716.png)
  * Coalescing `X` and `Y` does no harm if:
    * foreach neighbor `T` of `Y`, either:
      * degree of `T` is `< N` (Brigg-like)
      * `T` interferes with `X` (no change compared with coloring `X`)



## Domain-Specific Languages

* Design Guidelines for Domain Specific Languages
  * Language Purpose 
    * Identify language uses early 
    * Ask questions 
    * Make your language consistent
  * Language Realization
    * Decide carefully whether to use graphical or textual realization
    * Compose existing languages where possible
    * Reuse existing language definitions
    * Reuse existing type systems
  * Language Content
    * Reflect only the necessary domain concepts
    * Keep it simple
    * Avoid unnecessary generality
    * Limit the number of language elements
    * Avoid conceptual redundancy
    * Avoid inefficient language elements
  * Concrete Syntax
    * Adopt existing notations domain experts use
    * Use descriptive notations
    * Make elements distinguishable
    * Use syntactic sugar appropriately
    * Permit comments
    * Provide organizational structures for models
    * Balance compactness and comprehensibility
    * Use the same style everywhere
    * Identify usage conventions
  * Abstract Syntax
    * Align abstract and concrete syntax
    * Prefer layout which does not affect translation from concrete to abstract syntax
    * Enable modularity
    * Introduce interfaces
* DSLs: Compiler vs Library
  * optimizations / abstraction removed / generate code for hardware / full-program analysis
* ![image-20200514220221252](D:\OneDrive\Pictures\Typora\image-20200514220221252.png)
* ![image-20200514220240789](D:\OneDrive\Pictures\Typora\image-20200514220240789.png)
* ![image-20200514220258043](D:\OneDrive\Pictures\Typora\image-20200514220258043.png)
* ![image-20200514220312437](D:\OneDrive\Pictures\Typora\image-20200514220312437.png)
* ![image-20200514220337378](D:\OneDrive\Pictures\Typora\image-20200514220337378.png)
* ![image-20200514220404883](D:\OneDrive\Pictures\Typora\image-20200514220404883.png)





## Thread-Level Speculation

* Detect data dependence violations

  * extend invalidation-based cache coherence

* Buffer speculative modifications

  * use the caches as speculative buffers

* ![image-20200514221509102](D:\OneDrive\Pictures\Typora\image-20200514221509102.png)

* > “Compiler Optimization of Scalar Value Communication Between Speculative Threads”, by Antonia Zhai, Christopher B. Colohan, J. Gregory Steffan and Todd C. Mowry. ASPLOS 2002 Carnegie Mellon ASPLOS, 2002.

* ![image-20200514221601805](D:\OneDrive\Pictures\Typora\image-20200514221601805.png)
* ![image-20200514221705218](D:\OneDrive\Pictures\Typora\image-20200514221705218.png)
* ![image-20200514221715688](D:\OneDrive\Pictures\Typora\image-20200514221715688.png)
* ![image-20200514221806337](D:\OneDrive\Pictures\Typora\image-20200514221806337.png)
* ![image-20200514221815768](D:\OneDrive\Pictures\Typora\image-20200514221815768.png)
* ![image-20200514221835225](D:\OneDrive\Pictures\Typora\image-20200514221835225.png)
* ![image-20200514221914452](D:\OneDrive\Pictures\Typora\image-20200514221914452.png)
* ![image-20200514221951984](D:\OneDrive\Pictures\Typora\image-20200514221951984.png)
* ![image-20200514222007169](D:\OneDrive\Pictures\Typora\image-20200514222007169.png)
* ![image-20200514222014416](D:\OneDrive\Pictures\Typora\image-20200514222014416.png)
* [TLS](http://www.cs.cmu.edu/afs/cs/academic/class/15745-s14/public/lectures/L29b-TLS-Optimization-1up.pdf)