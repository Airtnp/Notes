# ![image-20200325224049027](D:\OneDrive\Pictures\Typora\image-20200325224049027.png)Compiler Design

[fa2018](http://www.cs.cmu.edu/~janh/courses/411/18/schedule.html)



## Overview

* sequential imperative language C0
* ![image-20200320123154040](D:\OneDrive\Pictures\Typora\image-20200320123154040.png)



## Instruction Selection

* IR `->` pseudo-assembly language
* Well-formed IR tree
  * ![image-20200320123834830](D:\OneDrive\Pictures\Typora\image-20200320123834830.png)
* Abstract assembly target code
  * ![image-20200320123852301](D:\OneDrive\Pictures\Typora\image-20200320123852301.png)
  * no technical reason to distinguish between temps & registers
    * cleaner if introducing some registers in the abstract assembly: temps can be renamed without changing the outcome of the program, registers can't
    * have `r_ret` to which we move the result before execution the return instruction ret
* Maximal Munch
  * ![image-20200320124752510](D:\OneDrive\Pictures\Typora\image-20200320124752510.png)
  * ![image-20200320124946077](D:\OneDrive\Pictures\Typora\image-20200320124946077.png)
  * ![image-20200320125012853](D:\OneDrive\Pictures\Typora\image-20200320125012853.png)

* Generating better code
  * avoid redundant moves
    * completely redesign the translation algorithm
      * ![image-20200320145812141](D:\OneDrive\Pictures\Typora\image-20200320145812141.png)
    * keep the basic structure, but add special cases
      * ![image-20200320145829205](D:\OneDrive\Pictures\Typora\image-20200320145829205.png)
    * keep the translation, apply optimizations subsequently
      * constant propagation: `t <- c` replacing occurances of `t` by `c` in subsequent instructions
      * copy propagation: `t <- x` replacing occurrences of `t` by `x`
        * need to stop replcement at an assignment to either `t` or `x`
  * Static Single Assignment (SSA) Form
    * in the program text (statically) there is only one assignment to each temp, but while executing the program (dynamically) the temp may still assume many different values
  * Optimal Instruction Selection
    * On modern architectures it is very difficult to come up with realistic cost models for the time of individual instructions. Moreover, these costs are not additive due to features of modern processors such as pipelining, out-of-order execution, branch predication, hyperthreading, etc
    * optimal instruction selection is more relevant when we optimize code size, because then the size of instructions is not only unambiguous but also additive
  * x86-64 Considerations
    * 2-address instructions: one operand will function as a source as well as destination of an instruction, rather than three-address instructions
    * some operations are tied to specific registers, such as integer division, modulus, and some shift operations
    * ![image-20200320153043704](D:\OneDrive\Pictures\Typora\image-20200320153043704.png)
  * Extensions
    * interdependencies of instruction selection and register allocation
      * register allocation `<-` instruction executed (especially for x86-64 special insts.)
    * recent advanced compilers, with SSA IR, combine register allocation & code generation into a joint phase



## Register Allocation

* Chordal graph coloring based on Pereira/Palsberg
* reducing spilled temps
* ![image-20200320160820831](D:\OneDrive\Pictures\Typora\image-20200320160820831.png)
* Building the Inference Graph
  * dataflow analysis: liveness analysis
  * ![image-20200320170927206](D:\OneDrive\Pictures\Typora\image-20200320170927206.png)
  * overlapping live range `->` inference edge
    * if we have a variable-to-variable move (which frequently occurs as the result of translation or optimizations) then both variables may be live at the next line and automatically be considered interfering. Instead, it is often actually beneficial if they are assigned to the same register because this means the move becomes redundant.
* Greedy Graph Coloring
  * `K`-colorable: NP-complete for `K >= 3`
  * If 2 variables inferere: undecidable
  * 1 register for 1 temp throughout the program, but also possible to use multiple registers for 1 temp (splitting live ranges)
  * rewrite the program using a compiler phase (like translation to SSA form) & arrive at a equivalent program that needs fewer registers
  * program `P` with `K` registers, is there an equivalent program `P'` that uses only the registers (no temps / memory locations): undecidable for TM-complete language
  * $\Delta(G)$: \# of colors that is used by the algorithm to color the graph `G`
  * $N(v)$: the neighborhood of `v` (the set of all adjacent nodes)
  * ![image-20200321142155909](D:\OneDrive\Pictures\Typora\image-20200321142155909.png)
  * register coalescing
  * For any graph, there is some ordering for which the greedy algorithm produces the optimal coloring, though we certainly shouldn’t expect to easily find such an order efficiently
* Chordal Graphs
  * An undirected graph is chordal if every cycle with 4 or more nodes has a chord, that is, an edge not part of the cycle connecting two nodes on the cycle
  * ![image-20200321155357412](D:\OneDrive\Pictures\Typora\image-20200321155357412.png)
  * PP05: 95% of the programs occurring in practice have chordal interference graphs already
  * 5-length cycles: 3 colors
  * chordal graph: 2-colors
    * ![image-20200321155653691](D:\OneDrive\Pictures\Typora\image-20200321155653691.png)
  * splitting live ranges
    * allocating more temps led ot use needing fewer registers!
  * Hac07: all SSA programs are chordal
* Simplicial Elimination Ordering
  * simplicial node `v`: if its neighborhood forms a clique (all neighbors of `v` are connected to each other, hence all need different colors)
  * simplicial elimination ordering $v_1, \cdots, v_n$: if every node $v_i$ is simplicial in the subgraph $v_1, \cdots, v_n$
  * chordal graph iff. have simplicial elimination order ([non-trivial proof](http://www.cs.cmu.edu/~janh/courses/411/18/lec/03-chordal-mcs.pdf))
  * `->` optimal greedy coloring (minimal \# of colors for every subgraph that arises is the size of the largest clique)
  * maximum cardinality search: $O(|V|+|E|)$ (at most quadratic in the size of the program)
    * $wt(v)$ weight with each vertex which is initialized to `0` by the algorithm, representing how many neighbors of `v` has been chosen earlier during the search
    * $N(v)$: neighborhood of `v`
    * ![image-20200322153827709](D:\OneDrive\Pictures\Typora\image-20200322153827709.png)
    * non-chordal graph: non-simplicial ordering (still can be used in coloring phase)
    * Tarjan/Yannakakis version
      * ![image-20200322154248788](D:\OneDrive\Pictures\Typora\image-20200322154248788.png)
* Precolored Nodes
  * x86-64 (E.g. `idiv`) requires arguments to be passed in specific registers / result in specific registers
  * caller/callee registers
  * live range of fixed registers should be limited to avoid possible correctness issues & simplify register allocation
  * construct an elimination ordering as if all precolored nodes were listed first
    * This amounts to the initial weights of the ordinary vertices being set to the number of neighbors that are precolored before the maximum cardinality search algorithm starts
    * The resulting list may or may not be a simplicial elimination ordering, but we can nevertheless proceed with greedy coloring as before
* Summary
  * **Build** the interference graph. 
  * **Order** the nodes using maximum cardinality search. 
  * **Color** the graph greedily according to the elimination ordering. 
  * **Spill** if more colors are needed than registers available.
  * variants: separate spilling pass before coloring
* Optimizations
  * Coalescing: reducing code size at the expense of putting more stress on the register allocation
    * `t <- s` in the code, `s` and `t` have no conflict and can be assigned to the same register or memory location
    * merge the nodes `s` & `t` in the conflict graph by creating a new node has all the edges of `s` & `t` (remove self-assignment)
    * coloring of the interference graph becomes more difficult as the graph becomes denser
    * coalescing works well in programs that require only few registers
  * Splitting Live Ranges: dual to coalescing
    * While coalescing combines notes in the interference graphs, splitting live ranges splits a node into two. Transforming a program to SSA form can be seen as a form of splitting live ranges.
    * `t' <- t`: renaming & introducing new node



## Liveness Analysis

* A variable is live at a given program point if it will be used during the remainder of the computation, starting at this point
* liveness is undecidable if the language we are analyzing is Turing-complete
* Logicial Form
  * predicate `live(l, x)`
  * ![image-20200322161138727](D:\OneDrive\Pictures\Typora\image-20200322161138727.png)
  * ![image-20200322161420659](D:\OneDrive\Pictures\Typora\image-20200322161420659.png)
  * actually efficient
    * counting so-called prefix firing of each rule
    * bounding the size of the completed database
      * infer at most `LV` distinct facts of the form `live(l, x)` where `L` is the number of lines and `V` is the number of variables in the program
    * Binary Decision Diagrams (BDD's)
      * Avots/Carbin/Lam WACL05: scalability of global program analysis using inference rules , transliterated into so-called Datalog programs
      * Smaragdakis/Bravenboer's Doop SB10
* Loops & Conditionals
  * ![image-20200322162944395](D:\OneDrive\Pictures\Typora\image-20200322162944395.png)
  * ![image-20200322163016643](D:\OneDrive\Pictures\Typora\image-20200322163016643.png)
* Building the Interference Graph
  * live range overlap
    * ![image-20200322163128267](D:\OneDrive\Pictures\Typora\image-20200322163128267.png)
    * ![image-20200322163422116](D:\OneDrive\Pictures\Typora\image-20200322163422116.png)
    * if we write to a destination, we must mark it as interfering with all the destinations that are live-out of that instruction
    * ![image-20200322164340204](D:\OneDrive\Pictures\Typora\image-20200322164340204.png)
    * ![image-20200322164459156](D:\OneDrive\Pictures\Typora\image-20200322164459156.png)
* ![image-20200322165124014](D:\OneDrive\Pictures\Typora\image-20200322165124014.png)
* Refactoring Liveness
  * ![image-20200322165552884](D:\OneDrive\Pictures\Typora\image-20200322165552884.png)
  * `use(l, x)`: the instruction at `l` uses variable `x`
  * `def(l, x`): the instruction at `l` defines (writes to) variable `x`
  * `succ(l, l'`): the instruction executed after `l` may be `l'`
  * analyze the program `->` `use/def/succ` facts (to saturation)
    * ![image-20200322165914035](D:\OneDrive\Pictures\Typora\image-20200322165914035.png)
  * employ predicates to derive facts about liveness
    * ![image-20200322165834932](D:\OneDrive\Pictures\Typora\image-20200322165834932.png)
  * theoretical complexity no-change, still $O(L \cdot V)$
* Implementing Liveness by Line/by Variable
  * By line
    * ![image-20200322170338947](D:\OneDrive\Pictures\Typora\image-20200322170338947.png)
  * By variable
    * ![image-20200322170408466](D:\OneDrive\Pictures\Typora\image-20200322170408466.png)
    * ![image-20200322170419219](D:\OneDrive\Pictures\Typora\image-20200322170419219.png)
* Example of backward dataflow analysis



## Lexcial Analysis

* regular expression
* longest-possible-match (maximal munch/most vexing parse)
* ![image-20200322184918020](D:\OneDrive\Pictures\Typora\image-20200322184918020.png)
* ![image-20200322184937508](D:\OneDrive\Pictures\Typora\image-20200322184937508.png)
* RE $\rightsquigarrow$ NFA
  * ![image-20200322185025020](D:\OneDrive\Pictures\Typora\image-20200322185025020.png)
* NFA $\rightsquigarrow$ DFA
  * ![image-20200322185058684](D:\OneDrive\Pictures\Typora\image-20200322185058684.png)
  * ![image-20200322185110516](D:\OneDrive\Pictures\Typora\image-20200322185110516.png)
  * Parsing derivatives (algebraic parsing)
* Minimizing DFA
  * ![image-20200322185135331](D:\OneDrive\Pictures\Typora\image-20200322185135331.png)
* RE $\rightsquigarrow$ DFA
  * Brzozowski derivatives / Antimirov's partial derivatives
  * match: $w \in r$
  * ![image-20200322185247059](D:\OneDrive\Pictures\Typora\image-20200322185247059.png)
  * ![image-20200322185302740](D:\OneDrive\Pictures\Typora\image-20200322185302740.png)
  * ![image-20200322185350643](D:\OneDrive\Pictures\Typora\image-20200322185350643.png)
  * ![image-20200322185416051](D:\OneDrive\Pictures\Typora\image-20200322185416051.png)
  * $D_a(r)$ represents the remainder RE of `r` after input `a` has been read
  * ![image-20200322185542812](D:\OneDrive\Pictures\Typora\image-20200322185542812.png)
  * ![image-20200322185548635](D:\OneDrive\Pictures\Typora\image-20200322185548635.png)
* Summary
  * Specify the token types to be recognized from the input stream by a sequence of regular expressions 
  * Bear in mind that the longest possible match rule applies and the first production that matches longest takes precedence. 
  * Lexical analysis is implemented by DFA. 
  * Convert the regular expressions into NFAs (or directly into DFAs using derivatives). 
  * Join them into a master NFA that chooses between the NFAs for each regular expression by a spontaneous $\epsilon$-transition 
  * Determinize the NFA into a DFA 
  * Optional: minimize the DFA for space 
  * Implement the DFA for a recognizer. Respect the longest possible match rule by storing the last accepted token and backtracking the input to this one if the DFA run cannot otherwise complete.



## Context-Free Grammars

* language: a set of sentences
  * $L(G)$ of $G$ is the set of sentences that we can derive using the productions of $G$
* sentence: a sequence drawn from the finite set $\Sigma$ of terminal symbols ($a, b, c$, lexical tokens)
* non terminal symbols: replaced by productions ($X, Y, Z$)
* strings: sequences that can contain NT/T ($\alpha, \beta, \gamma$)
* grammar: set of productions $\alpha \to \beta$ , start NT symbol $S$
* derivations: $S \to \gamma_1 \to \cdots \to \gamma_n = w$ ($S \to^* w$)
* ![image-20200322192418340](D:\OneDrive\Pictures\Typora\image-20200322192418340.png)
* word problem: decode if $w \in L(G)$ given a string/word $w \in \Sigma^*$ and a grammar $G$ (generally undecidable)
* rightmost derivation: always replace the rightmost NT
* leftmost derivation: always replace the leftmost NT
* Ambiguity
  * ![image-20200322193245996](D:\OneDrive\Pictures\Typora\image-20200322193245996.png) $\to$ ![image-20200322193258089](D:\OneDrive\Pictures\Typora\image-20200322193258089.png)
* Parse Trees $\equiv$ Deduction Trees
  * ![image-20200322193809477](D:\OneDrive\Pictures\Typora\image-20200322193809477.png)
* CYK (Cocke-Younger-Kasami) Parsing
  * ![image-20200322194036126](D:\OneDrive\Pictures\Typora\image-20200322194036126.png)
  * ![image-20200322194108935](D:\OneDrive\Pictures\Typora\image-20200322194108935.png)
  * ![image-20200322195507589](D:\OneDrive\Pictures\Typora\image-20200322195507589.png)



## Shift-Reduce Parsing

* predictive parsing with lookahead
* Dedurive Shift-Reduce Parsing
  * ![image-20200322200456516](D:\OneDrive\Pictures\Typora\image-20200322200456516.png)
  * ![image-20200322200511133](D:\OneDrive\Pictures\Typora\image-20200322200511133.png)
  * ![image-20200323134938191](D:\OneDrive\Pictures\Typora\image-20200323134938191.png)
  * rightmost derivation only
* Predictive parsing
  * ![image-20200323135126749](D:\OneDrive\Pictures\Typora\image-20200323135126749.png)
  * parse table
  * ![image-20200323143412283](D:\OneDrive\Pictures\Typora\image-20200323143412283.png)
* Generating a Parse Table
  * LR(1): no shift-reduce/reduce-reduce conflicts
  * ![image-20200323145606742](D:\OneDrive\Pictures\Typora\image-20200323145606742.png)
* Parsing Ambiguous Grammars
  * shift/reduce conflicts
    * precedence / associativity information
    * parser generator: to shift (right-associative)
    * ![image-20200323150031643](D:\OneDrive\Pictures\Typora\image-20200323150031643.png)
  * reduce/reduce conflicts
    * parse generator: first production in the grammar
    * `if-then-else` example
* Adapting Grammars for Shift-Reduce Parsing
  * But even though a language may be describable with an LR(1) grammar, it’s not necessarily the case that every grammar for an LR(1) language can be parsed with a shift-reduce parser.
  * ![image-20200323151432669](D:\OneDrive\Pictures\Typora\image-20200323151432669.png)
  * ![image-20200323151438500](D:\OneDrive\Pictures\Typora\image-20200323151438500.png)
  * ![image-20200323151447084](D:\OneDrive\Pictures\Typora\image-20200323151447084.png)
  * ![image-20200323151455084](D:\OneDrive\Pictures\Typora\image-20200323151455084.png)



## Intermediate Representation

* SSA, quads (3-addr inst.), triples (2-addr inst.)

* surface concrete syntax $\rightsquigarrow$ elaborated abstract syntax $\rightsquigarrow$ IR Trees

* Elaboration

  * ![image-20200323205030372](D:\OneDrive\Pictures\Typora\image-20200323205030372.png)
  * ![image-20200323213736765](D:\OneDrive\Pictures\Typora\image-20200323213736765.png)

* IR Trees

  * isolate potentially effectful expressions
  * make control flow explicit in the form of conditional/unconditional branches
  * ![image-20200323213815333](D:\OneDrive\Pictures\Typora\image-20200323213815333.png)

* Translating Expressions / Statements

  * $tr(e) = \langle \check{e}, \hat{e} \rangle$ where $\check{e}$ is a sequence of commands $r$ that we need to write down to compute the effects of $e$ and $\hat{e}$ is a pure expression $p$ that we can use to compute the value of $e$ back up.
  * ![image-20200323221927339](D:\OneDrive\Pictures\Typora\image-20200323221927339.png)
  * ![image-20200323221935525](D:\OneDrive\Pictures\Typora\image-20200323221935525.png)
  * ![image-20200323221952428](D:\OneDrive\Pictures\Typora\image-20200323221952428.png)
  * ![image-20200323222003684](D:\OneDrive\Pictures\Typora\image-20200323222003684.png)
  * ![image-20200323222010492](D:\OneDrive\Pictures\Typora\image-20200323222010492.png)
  * for conditional branches (boolean expressions)
  * ![image-20200323222043250](D:\OneDrive\Pictures\Typora\image-20200323222043250.png)
  * ![image-20200323222105005](D:\OneDrive\Pictures\Typora\image-20200323222105005.png)

* Extended basic blocks

  * basic block form: single independent unit in analyses

    * constant propagation

  * extended basic block: collection of BBs with one label at the beginning & internal labels, each of which is the target of only one internal jump and no external jumps

  * > Another way of thinking about extended basic blocks as yet another intermediate language, where instead of basic blocks being sequences of commands ending in a jump, they are trees of commands that branch at conditional statements and have unconditional jumps (goto or return) as their leaves

* Ambiguity in Language Specfication

  * C standard

    * > The precedence and associativity of operators is fully specified, but the order of evaluation of expressions is, with certain exceptions, undefined, even if the subexpressions involve side effects

    * freely optimize, but not portable...

    * argument: a program whose proper execution depends on the order of evaluation is simply wrong, and the programmer should not be surprised if it breaks

      * The flaw in this argument is that dependence on evaluation order may be a very subtle property, and neither language definition nor compiler give much help in identifying such flaws in a program ([[N: diagnosis...]])

  * Therefore I strongly believe that language specifications should be entirely unambiguous. In this course, this is also important because we want to hold all compilers to the same standard of correctness. This is also why the behavior of division by 0 and division overflow, namely an exception, is fully specified. It is not acceptable for an expression such as (1/0)*0 to be “optimized” to 0. Instead, it must raise an exception. 

  * The translation to intermediate code presented here therefore must make sure that any potentially effectful expressions are indeed evaluated from left to right. Careful inspection of the translation will reveal this to be the case. On the resulting pure expressions, many valid optimizations can still be applied which would otherwise be impossible, such as commutativity, associativity, or distributivity, all of which hold for modular arithmetic.

* Translating C0 to C

  * ![image-20200323222540413](D:\OneDrive\Pictures\Typora\image-20200323222540413.png)



## Static Semantics

* verify the abstract syntax satisfying the requirements of the static semantics

* Initialization: variable must be defined before they are used

* Proper returns: functions that return a value must have an explicit return statement on every control flow path starting at the beginning of the function

* Types: the program must be well-typed

* Definition & Use

  * ![image-20200323225613268](D:\OneDrive\Pictures\Typora\image-20200323225613268.png)
  * ![image-20200323225734430](D:\OneDrive\Pictures\Typora\image-20200323225734430.png)
  * ![image-20200323230215509](D:\OneDrive\Pictures\Typora\image-20200323230215509.png)

* Liveness

  * ![image-20200323230246503](D:\OneDrive\Pictures\Typora\image-20200323230246503.png)

* Initialization

  * violation: If a variable is live at the site of its declaration
  * ![image-20200323230317934](D:\OneDrive\Pictures\Typora\image-20200323230317934.png)
  * premises `->` conclusions / conclusions `->` premises
  * ![image-20200324000341005](D:\OneDrive\Pictures\Typora\image-20200324000341005.png)

* From Judgements to Functions

  * ![image-20200324000359404](D:\OneDrive\Pictures\Typora\image-20200324000359404.png)
  * ![image-20200324000406342](D:\OneDrive\Pictures\Typora\image-20200324000406342.png)

* Maintaining Set of Variables

  * avoid multiple traversals of the same program
  * ![image-20200324000448813](D:\OneDrive\Pictures\Typora\image-20200324000448813.png)
  * ![image-20200324000457500](D:\OneDrive\Pictures\Typora\image-20200324000457500.png)
  * ![image-20200324000512301](D:\OneDrive\Pictures\Typora\image-20200324000512301.png)

* Modes of Judgements

  * ![image-20200324003904326](D:\OneDrive\Pictures\Typora\image-20200324003904326.png)

  * > In order to handle return(e), we probably should also pass in a second set of declared variables or a context. We could also avoid returning a boolean by just returning an optional set of defined variables, or raise an exception in case we disover a variable that is used but not defined. 
    >
    > Examining the rules shows that we will need to be able to add variables and to remove variables from sets, as well as compute intersections. Otherwise, the code should be relatively straightforward.

  * mode checking

    * [model checking?](https://www.zhihu.com/question/268593174)

  * ![image-20200324005134143](D:\OneDrive\Pictures\Typora\image-20200324005134143.png)

* Typing Judgements

  * ![image-20200324005155214](D:\OneDrive\Pictures\Typora\image-20200324005155214.png)

* Modes for Typing

  * ![image-20200324005408150](D:\OneDrive\Pictures\Typora\image-20200324005408150.png)
  * ![image-20200324005531710](D:\OneDrive\Pictures\Typora\image-20200324005531710.png)





## Static Single Assignment Form

* relabel variables in the code so that each variable is defined only once in the program text
* ![image-20200324164312879](D:\OneDrive\Pictures\Typora\image-20200324164312879.png)
* ![image-20200324164328858](D:\OneDrive\Pictures\Typora\image-20200324164328858.png)
* SSA & Functional Programs
  * We can notice that at this point the program above can be easily interpreted as a functional program if we read assignments as bindings and labeled jumps as function calls
  * defined once `<->` let binding
  * goto at the end `<->` tail call
* Optimization & Minimal SSA Form
  * ![image-20200324223024106](D:\OneDrive\Pictures\Typora\image-20200324223024106.png)
* $\phi$-Functions
  * ![image-20200324223218522](D:\OneDrive\Pictures\Typora\image-20200324223218522.png)
* Assembly Code Generation from SSA Form
  * actual assembly code does not allow parameterized labels
  * To recover lower level code, we need to implement labeled jumps by moves followed by plain jumps
  * ![image-20200324223915329](D:\OneDrive\Pictures\Typora\image-20200324223915329.png)
  * no longer in SSA form
* ![image-20200324223936075](D:\OneDrive\Pictures\Typora\image-20200324223936075.png)



## Calling Conventions

* assembly code specification
* machine-specific
* x86-64 Calling Conventions
  * first 6 arguments: by register
  * rest: by stack
    *  all arguments take 8 bytes of space on the stack, even if the type of argument would indicate that only 4 bytes need to be passed
  * result: `%eax`
  * fp registers: `%xmm0-7` & stack
  * IA32: stack frame/base pointer `%ebp`
  * x86-64: no longer require a frame pointer
  * ![image-20200324232104800](D:\OneDrive\Pictures\Typora\image-20200324232104800.png)
  * `%rsp` should be aligned `0 mod 16` before another function is called, may be assumed to be aligned `8 mod 16` on function entry (return adress saved by `call`)
  * red zone: area below the `%rsp`, may be used by the callee as temporary storage for data that is not needed across function calls / to build arguments to be used before a function call
    * shall not be modified by signal/interrupt handlers
    * Linux kernel code may not respect the red zone & overwrite this area
* Register Convention
  * ![image-20200324232438832](D:\OneDrive\Pictures\Typora\image-20200324232438832.png)
  * `%al` (lower 8-bit of `%rax`) contains the number of floating point arguments on the stack in a call to varargs functions
  * `%rbp` is the frame pointer for the stack frame, in an x86-like calling convention (optional for x86-64)
* Typical Calling Sequence
  * Ultimate Goal: The live range of precolored registers should be as short as possible!
  * ![image-20200324233306684](D:\OneDrive\Pictures\Typora\image-20200324233306684.png)
  * register aliasing: `%eax/%rax`
  * all argument registers and the result register are caller-save
  * if a temp `t` is live after a function call, we have to add an infererence edge connecting `t` with any of the fixed registers noted above, since the value of those registers are not preserved across a function call.
  * moving argument registers into temps & eliminate using some heuristics
* Callee-saved Registers
  * The standard approach is to save those that are needed onto the stack in the function prologue and restore them from the stack in the function epilogue, just before returning
  * maximal live ranges...  essentially live throughout the body of a function, since their value at the return instruction matters
  * simple way: listing them last among the registers to be assigned by register allocation
    * assign callee-save registers before resorting to spilling if more than available number of caller-saved registers are needed (need to save them at the beginning & restore at the end)
  * another way: let register allocation together with register coalescing do the job
    * move the contents of all the callee-saved registers into temps at the beginning of a function and then move them back at the end
    * If it turns out these temps are spilled, then they will be saved onto the stack
    * If not, they may be moved from one register to another and then back at the end
    * only works well with the right heuristics for assigning registers or using register coalescing
      * Register coalescing consults the interference graph to check if we can assign the same register for variable-to-variable moves
      * copy propogation requires care because it might extend the live range of variables, possibly undoing the care we applied to keep precolored registers contained.
    * ![image-20200324235551280](D:\OneDrive\Pictures\Typora\image-20200324235551280.png)
    * we need to be sure to spill the full 64-bit registers, while registers holding 32-bit integer values might be saved and restored (or directly used as operands) using only 32 bits
  * both way requires an additional rule: all callee-save registers should be considered live at the return instruction
    * ![image-20200324235645137](D:\OneDrive\Pictures\Typora\image-20200324235645137.png)
* Example
  * program (SSA): ![image-20200324235811393](D:\OneDrive\Pictures\Typora\image-20200324235811393.png)
  * liveness analysis: ![image-20200324235823060](D:\OneDrive\Pictures\Typora\image-20200324235823060.png)
  * precolored registers with lower level IR
    *  ![image-20200324235849868](D:\OneDrive\Pictures\Typora\image-20200324235849868.png)
    * callee-saved registers not explicit yet
  * interference graph: ![image-20200324235905412](D:\OneDrive\Pictures\Typora\image-20200324235905412.png)
    * All precolored registers implicitly interfere with each other, so we don’t include that in the interference graph
  * live-in: ![image-20200325000017754](D:\OneDrive\Pictures\Typora\image-20200325000017754.png)
  * simplicial elimination ordering: `b, e, t0, t1, t2`
  * machine register color order: `res0, arg1, ..., arg6, ler7, ler8, lee9`
  * assignment: ![image-20200325000117689](D:\OneDrive\Pictures\Typora\image-20200325000117689.png)
  * substitution: ![image-20200325000133522](D:\OneDrive\Pictures\Typora\image-20200325000133522.png)
  * optimizations: self-moves / copy-propogation
  * GNU AT&T assembly: ![image-20200325000207017](D:\OneDrive\Pictures\Typora\image-20200325000207017.png)



## Dynamic Semantics

* Static semantics: definition of valid programs
* Dynamic semantics: definition of how programs are executed
* Denotational Semantics: Abstract and elegant. (Dana Scott)
  * Each part of a program is associated with a denotation (math. object)
  * For example: a procedure is associated with a mathematical function
* Axiomatic Semantics: Strongly related to program logic. (Tony Hoare)
  * Gives meaning to phrases using logical axioms
  * The meaning is identical to the set of properties that can be proved
* Operational Semantics: Describes how programs are executed (Bob Harper)
  * Related to interpreters and abstract machines
  * Most popular and flexible form of semantics
  * many different styles
    * Natural semantics (or big-step semantics or evaluation dynamics)
    * Structural operational semantics
    * Substructural operational semantics (Frank Pfenning)
    * Abstract machine (or small-step with continuation)
      * Very general: can describe non-termination, concurrency, … 
      * Low-level and elaborate
* ![image-20200325000638553](D:\OneDrive\Pictures\Typora\image-20200325000638553.png)
* ![image-20200325001115940](D:\OneDrive\Pictures\Typora\image-20200325001115940.png)
* ![image-20200325001133027](D:\OneDrive\Pictures\Typora\image-20200325001133027.png)
* ![image-20200325001256684](D:\OneDrive\Pictures\Typora\image-20200325001256684.png)
* ![image-20200325001302905](D:\OneDrive\Pictures\Typora\image-20200325001302905.png)
* ![image-20200325001315677](D:\OneDrive\Pictures\Typora\image-20200325001315677.png)
* ![image-20200325001325314](D:\OneDrive\Pictures\Typora\image-20200325001325314.png)
* ![image-20200325001347044](D:\OneDrive\Pictures\Typora\image-20200325001347044.png)
* What needs to happen at a function call?
  * Evaluate the arguments in left-to-right order
  * Save the environment of the caller to continue the execution after the function call
  * Save the continuation of the caller
  * Execute the body of the callee in a new environment that maps the formal parameters to the argument values
  * Pass the return value the the environment of the caller
* ![image-20200325001515786](D:\OneDrive\Pictures\Typora\image-20200325001515786.png)
* ![image-20200325001547243](D:\OneDrive\Pictures\Typora\image-20200325001547243.png)
* ![image-20200325001603274](D:\OneDrive\Pictures\Typora\image-20200325001603274.png)
* ![image-20200325001634137](D:\OneDrive\Pictures\Typora\image-20200325001634137.png)
* ![image-20200325001644531](D:\OneDrive\Pictures\Typora\image-20200325001644531.png)
* ![image-20200325001651618](D:\OneDrive\Pictures\Typora\image-20200325001651618.png)
* ![image-20200325001700505](D:\OneDrive\Pictures\Typora\image-20200325001700505.png)



## Mutable

* ![image-20200325002038476](D:\OneDrive\Pictures\Typora\image-20200325002038476.png)
* ![image-20200325002309677](D:\OneDrive\Pictures\Typora\image-20200325002309677.png)
* ![image-20200325002329017](D:\OneDrive\Pictures\Typora\image-20200325002329017.png)
* ![image-20200325002356682](D:\OneDrive\Pictures\Typora\image-20200325002356682.png)
* ![image-20200325002408897](D:\OneDrive\Pictures\Typora\image-20200325002408897.png)
* ![image-20200325002419868](D:\OneDrive\Pictures\Typora\image-20200325002419868.png)
* ![image-20200325002442955](D:\OneDrive\Pictures\Typora\image-20200325002442955.png)
* ![image-20200325002452322](D:\OneDrive\Pictures\Typora\image-20200325002452322.png)
* ![image-20200325002508801](D:\OneDrive\Pictures\Typora\image-20200325002508801.png)
* ![image-20200325002516644](D:\OneDrive\Pictures\Typora\image-20200325002516644.png)
* ![image-20200325002527394](D:\OneDrive\Pictures\Typora\image-20200325002527394.png)
* ![image-20200325002537780](D:\OneDrive\Pictures\Typora\image-20200325002537780.png)
* ![image-20200325002550556](D:\OneDrive\Pictures\Typora\image-20200325002550556.png)
* ![image-20200325002605681](D:\OneDrive\Pictures\Typora\image-20200325002605681.png)
* ![image-20200325002618797](D:\OneDrive\Pictures\Typora\image-20200325002618797.png)
* ![image-20200325002708649](D:\OneDrive\Pictures\Typora\image-20200325002708649.png)



## Structs

* Arrays are represented with pointers (but cannot be dereferenced) `->` they can be compared and stored in registers
* Structs are usually also pointers but they can be dereferenced
* Structs are large types that do not fit in registers
* `struct s {T1 f1; ...; Tn fn; }`
* Local variables, function parameters, and return values must have small type
* Left- and right-hand sides of assignments must have small type
* Conditional expressions must have small type
* Equality and disequality must compare expressions of small type
* Expressions used as statements must have small type
* ![image-20200325122024807](D:\OneDrive\Pictures\Typora\image-20200325122024807.png)
* ![image-20200325122201294](D:\OneDrive\Pictures\Typora\image-20200325122201294.png)
* ![image-20200325123238242](D:\OneDrive\Pictures\Typora\image-20200325123238242.png)
* ![image-20200325123709322](D:\OneDrive\Pictures\Typora\image-20200325123709322.png)
* ![image-20200325123730010](D:\OneDrive\Pictures\Typora\image-20200325123730010.png)
* ![image-20200325124236458](D:\OneDrive\Pictures\Typora\image-20200325124236458.png)
* ![image-20200325124659346](D:\OneDrive\Pictures\Typora\image-20200325124659346.png)
* ![image-20200325124708961](D:\OneDrive\Pictures\Typora\image-20200325124708961.png)
* ![image-20200325124733849](D:\OneDrive\Pictures\Typora\image-20200325124733849.png)
* ![image-20200325124738762](D:\OneDrive\Pictures\Typora\image-20200325124738762.png)



## Dataflow Analysis

* ![image-20200325181353211](D:\OneDrive\Pictures\Typora\image-20200325181353211.png)
* Dead Code Elimination
  * variable not live at the successor line (but might have exception/side effect for this line...)
  * not precise enough because can be live but not needed (loop-example)
    * ![image-20200325203039402](D:\OneDrive\Pictures\Typora\image-20200325203039402.png)
* Neededness
  * some variables are needed because an instruction they are involved in may have an effect (necessary)
  * `nec(l, x)`: `x` is necessary at instruction `l`,
  *  $\oslash$: binary operator which may raise an exception (divsion/modulo)
  * ![image-20200325203706474](D:\OneDrive\Pictures\Typora\image-20200325203706474.png)
  * return statement / conditional branch
  * `M[x]`: exception
  * memory safe? loose the definition
  * EFLAGS register side effects: Most compiler writers don’t have the freedom to change the meaning of source language programs that they receive, and almost no compiler writers have the freedom to change the meaning of the assembly programs they generate, but you have a great deal of freedom in deciding what is or is not allowed in your intermediate languages.
  * `needed(l, x)`: if `x` s needed at `l`
  * ![image-20200325203908395](D:\OneDrive\Pictures\Typora\image-20200325203908395.png)
  * ![image-20200325203916988](D:\OneDrive\Pictures\Typora\image-20200325203916988.png)
  * We can restructure the program slightly and could unify the formulas `nec(l, x)` and `needed(l, x)`. This is mostly a matter of taste and modularity
* Reaching Definitions
  * forward dataflow analysis (constant propagation/copy propagation)
  * definition `l: x <- ...` reaches a line `l'` if there is a path of control flow from `l` to `l'` during which `x` is not redefined (SSA ensures)
  * ![image-20200325204108907](D:\OneDrive\Pictures\Typora\image-20200325204108907.png)
  * ![image-20200325204132274](D:\OneDrive\Pictures\Typora\image-20200325204132274.png)
* dataflow analysis may have to be rerun after an optimization transformed the program. Rerunning all analysis exhaustively all the time after each optimization may be time-consuming. Adapting the dataflow analysis information during optimization transformations is sometimes possible as well, but correctness is less obvious
* dataflow equations



## Optimizations of Register Allocation

* chordal graph coloring algorithm [PP05] is that it lends itself to a register coalescing approach that is independent of the actual register allocation process.
  *  it does not tell us which registers to spill in step 4, it only tells us how many registers we will need to spill
  * heuristics for deciding which colors should be spilled & which colors should be mapped to registers
    * spill the least-used color: colors that are used for fewer nodes will result in the spilling of fewer temps
      * keeping variables used frequently in inner loops in registers may be crucial for certain programs `->` introduce a weight for each node/temp that depends on the nesting depth of the loops in which the respective temp is used
    * spill the highest color assigned by the greedy algorithm: an approximation of first, easy to implement
      * recall how greedy graph coloring works: We successful select uncolored nodes and color them with the lowest color that is not used by its neighbors. As a result, there is a tendency to use lower colors more often
  * heursitics for step 2: maximum cardinality search
    * This is important if you decide to implement strategy (ii) since nodes that are picked earlier tend to have lower colors.
    * this algorithm encounters many “ties” where multiple different nodes could be chosen as the next node
* register allocation algoirthms tend to tightly integrate register allocation & register spilling, making both complicated
* ![image-20200325212522530](D:\OneDrive\Pictures\Typora\image-20200325212522530.png)
* Register Coalescing
  * greedy coalescing
    * If we have a move `u ← u`, it won’t change the meaning of the program if we delete it.
    * If two temps do not have an interference edge between them, then the two different temps could both be renamed to be the same temp without changing the meaning of the program. (This is simply what it means for two temps to not interfere!)
    * If `t` and `s` do not interfere, we can always eliminate the move `t <- s` by creating a new temp `u`, replacing both `t` and `s` with `u` everywhere in the program, and eliminatingthe move
    * ![image-20200325215151303](D:\OneDrive\Pictures\Typora\image-20200325215151303.png)
    * not optimal
  * not-before graph coloring: tend to make a chordal graph non-chordal / increase the \# of colors needed to color the graph
  * can coalesce after coloring the interference graph, but before the rewritten the program to replace temps with registers
  * variation of $c \not \in N(t) \cup N(s), c \leq c_{\max}$
    * still be beneficial if `c` is bigger than `c_max` in case `c_max` is small than the \# of available registers
    * `K`-color graph `->` `K+1` color graph
* Splitting Live Ranges
  * integrate with linear scan
  * `t ==> t' <- t`
  * make the interference graph more sparse at the cost of introducing additional move instructions



## Peephole Optimization & Common Subexpression Elimination

* Peephole optimizations: optimizations that are performed locally on a small number of instructions
  * the picture that we look at the code through a peephole and make optimization that only involve the small amount code we can see and that are indented of the rest of the program.
  * LLVM: more than 1k peephole optimizations
* optimizations: condition + code transformation
* Constant Folding
  * ![image-20200325220156410](D:\OneDrive\Pictures\Typora\image-20200325220156410.png)
  * ![image-20200325220213493](D:\OneDrive\Pictures\Typora\image-20200325220213493.png)
* Strength Reduction
  * replace expensive operation with a simpler one
  * eliminate an operation altogether, based on the laws of modular, two’s complement arithmetic
  * ![image-20200325220919627](D:\OneDrive\Pictures\Typora\image-20200325220919627.png)
  * `a * b + a * c ==> a * (b + c)`
* Null Sequences
  * it's beneficial to produce self moves `r <- r` which can be removed from the code
  * ![image-20200325221106955](D:\OneDrive\Pictures\Typora\image-20200325221106955.png)
* Common Subexpression Elimination (CSE)
  * ![image-20200325221247763](D:\OneDrive\Pictures\Typora\image-20200325221247763.png)
  * dominance: `l >= k` if `l` dominates `k` & `l > k` if `l` strictly dominates `k`
    * every control flow path from the beginning of the code to line `k` goes through line `l`
  * ![image-20200325221703467](D:\OneDrive\Pictures\Typora\image-20200325221703467.png)
  * if raising exception, we won't reach `k` (correctness preserved)
* Dominance
  * forward dataflow analysis
  * Cooper algorithm (empirically faster than traditional Lengauer-Tarjan, asymptotically faster)
* Implementing Common Subexpression Elimination
  * `l: x <- s1 . s2`
  * if `s1 . s2` already in the table, defining variable `y` at `k` replace `l` with `l : x <- y` if `k` dominates `l`, otherwise, add (expression, line, variable) to the hash table
  * dominator tree (line has a pointer to its immediate dominator) (pointer chasing)
* Termination
  * if the transformations terminate
  * Quiescence is the rewriting counterpart to saturation for inference
    * Saturation means that any inference we might apply only has conclusions that are already known
    * Quiescence means that we can no longer apply any rewrite rules
  * ![image-20200325222405483](D:\OneDrive\Pictures\Typora\image-20200325222405483.png)



## Memory Optimizations

* Constant propagation
  * ![image-20200325222728235](D:\OneDrive\Pictures\Typora\image-20200325222728235.png)
* Common Subexpression Elimination
  * ![image-20200325224050251](D:\OneDrive\Pictures\Typora\image-20200325224050251.png)
* Using the Results of Alias Analysis
  * ![image-20200325224111587](D:\OneDrive\Pictures\Typora\image-20200325224111587.png)
  * ![image-20200325224135770](D:\OneDrive\Pictures\Typora\image-20200325224135770.png)
  * ![image-20200325224141409](D:\OneDrive\Pictures\Typora\image-20200325224141409.png)
  * ![image-20200325224151699](D:\OneDrive\Pictures\Typora\image-20200325224151699.png)
  * ![image-20200325224200803](D:\OneDrive\Pictures\Typora\image-20200325224200803.png)
* Type-Based Alias Analysis
  * propagate type information from the semantic analysis to abstract assembly
  * ![image-20200325224247660](D:\OneDrive\Pictures\Typora\image-20200325224247660.png)
  * ![image-20200325224304178](D:\OneDrive\Pictures\Typora\image-20200325224304178.png)
  * ![image-20200325224319236](D:\OneDrive\Pictures\Typora\image-20200325224319236.png)
  * ![image-20200325224340315](D:\OneDrive\Pictures\Typora\image-20200325224340315.png)
  * example of abstract interpretation
* Allocation-Based Alias Analysis
  * pointers may not alias is based on their allocation point
  * if two pointers are allocated with different calls to alloc or alloc array, then they cannot be aliased
  * example of an interprocedural analysis



## Loop Optimizations

* Loop: back-edge in the CFG from a node `l` to a node `h` which dominates `l`
  * header node `h`
  * `loop(h, l)`
* Hoisting Loop-Invariant Computation
  * loop invariant: if pure expression values don't change throughout the loop (`inv(h, p)`)
  * ![image-20200325224745771](D:\OneDrive\Pictures\Typora\image-20200325224745771.png)
  * ![image-20200325224910349](D:\OneDrive\Pictures\Typora\image-20200325224910349.png)
  * hoist to loop preheader
  * if loop never execute `->` slower!
  * conditionals `->` slower!
  * ![image-20200325225002706](D:\OneDrive\Pictures\Typora\image-20200325225002706.png)
* Induction Variables
  * optimizing computation which changes by a constant amount each time around the loop
  * basic induction varaibles
  * derived induction variables: computed from basic induction variables
  * it is straightforward to generalize them to arbitrary induction variables x that are updated with `x2 ← x1 ±c` for a constant `c`, and derived variables that arise from constant multiplication with or addition to a basic induction variable
  * [example](http://www.cs.cmu.edu/~janh/courses/411/18/lec/21-loopopt-slides.pdf)



## Decompilation

* ![image-20200325225423252](D:\OneDrive\Pictures\Typora\image-20200325225423252.png)
* Disassembly
  * distinguish code from data?
  * ![image-20200325225450035](D:\OneDrive\Pictures\Typora\image-20200325225450035.png)
* Lifting & Dataflow Analysis
  * The structure of most assembly language does not lend itself well to any kind of sophisticated analysis
  * resembles a backwards form of instruction selection
    * However, decompilers cannot just tile sequences of assembly instructions with sequences of abstract instructions, as different compilers may produce radically different assembly for the same sequence of abstract instructions
    *  frequently a single abstract instruction can expand into a very long sequence of “real” instructions, many of which are optimized away by the compiler later on
  * Translate our complex x86 64 into a simpler RISC instruction set. The tools produced by Zynamics frequently take this approach
  * Translate into an exactly semantics-preserving, perhaps more complicated, instruction set, which has more cross-platform ways of performing analysis on it. This is the approach taken by CMU’s BAP research project, as well as by the Hex-Rays decompiler
  * ![image-20200325225829214](D:\OneDrive\Pictures\Typora\image-20200325225829214.png)
  * ![image-20200325225838851](D:\OneDrive\Pictures\Typora\image-20200325225838851.png)
  * ![image-20200325225847178](D:\OneDrive\Pictures\Typora\image-20200325225847178.png)
  * ![image-20200325225902028](D:\OneDrive\Pictures\Typora\image-20200325225902028.png)
  * ![image-20200325225916596](D:\OneDrive\Pictures\Typora\image-20200325225916596.png)
* Control Flow Analysis
  * with reasonable CFG & "real" variables
  * produce semantically-equivlaent C code now, but not desirable
  * `->` structured programs (`if/for/while`)
  * graph transformation (dominator nodes)
  * Structuring Loops
    * ![image-20200325230213459](D:\OneDrive\Pictures\Typora\image-20200325230213459.png)
    * ![image-20200325230223172](D:\OneDrive\Pictures\Typora\image-20200325230223172.png)
  * Structuring Ifs
    * ![image-20200325230231772](D:\OneDrive\Pictures\Typora\image-20200325230231772.png)
* Type Analysis
  * ![image-20200325230434142](D:\OneDrive\Pictures\Typora\image-20200325230434142.png)
  * ![image-20200325230442180](D:\OneDrive\Pictures\Typora\image-20200325230442180.png)
  * ![image-20200325230451644](D:\OneDrive\Pictures\Typora\image-20200325230451644.png)
* Other Issues
  * automatically detecting vulnerabilities
  * detecting and possibly collapsing aliases
  * recovering scoping information
  * extracting inlined functions
  * dealing with tail call optimizations
  * ![image-20200325230504595](D:\OneDrive\Pictures\Typora\image-20200325230504595.png)





## Garbage Collection

* Reference Counting

  * > Each heap object maintains an additional field containing the number of references to the object. The compiler must generate code that maintains this reference count correctly. When the count reaches 0, the object is deallocated, possibly triggering the reduction of other reference counts. Reference counts are hard to maintain, especially in the presence of optimizations. The other problem is that reference counting does not work well for circular data structures because reference counts in a cycle can remain positive even though the structure is unreachable. Nevertheless, reference counting appears to remain popular for scripting languages like Perl, PHP, or Python. Another use of reference counting is in part of an operating system where we know that no circularities can arise.

* Mark-and-Sweep (tracing, STW)

  * > A mark-and-sweep collector traverses the stack to find pointers into the heap and follows each of them, marking all reachable objects. It then sweeps through memory, collecting unmarked objects into a free list while leaving marked objects in place. It is usually invoked if there is not enough space for a requested allocation. Because objects are never moved once allocated, a mark-andsweep collector runs the risk of fragmented memory which can translate to poor performance. Another difficulty with a mark-and-sweep collector is that the cost of a collection is proportional to all available memory (which will be touched in the sweep phase).

* Copy Collection (tracing, STW)

  * > A copying collector also traverses the heap, starting from the so-called root pointers on the stack. Instead of marking objects it moves reachable objects from the heap to a new area called the to-space. When all reachable objects have been moved, the old heap (the from-space) and the to-space switch roles. The copying phase will compact memory, leading to good locality of reference. Moreover, the cost is only proportional to the reachable memory rather than all allocated memory. On the other hand, a copying collector typically needs to run with twice as much memory than a mark-and-sweep collector

* Allocation

  * m-n-s: free-list, doubly linked
  * copy-c: no free list, currently used half-space & `next` pointer to the end of the currently used portion of the half-space

* Finding Root Pointers

  * ![image-20200325231103468](D:\OneDrive\Pictures\Typora\image-20200325231103468.png)
  * ![image-20200325231112419](D:\OneDrive\Pictures\Typora\image-20200325231112419.png)

* Derived Pointers

  * ![image-20200325231148483](D:\OneDrive\Pictures\Typora\image-20200325231148483.png)

* Traversing the Heap

  * ![image-20200325231158092](D:\OneDrive\Pictures\Typora\image-20200325231158092.png)

* Tagless Garbage Collection

  * ![image-20200325231249691](D:\OneDrive\Pictures\Typora\image-20200325231249691.png)



## LLVM

* A collection of modular and reusable compiler and toolchain technologies
* Vikram Adve/Chris Lattner@UIUC, 2000
* Originally ‘Low Level Virtual Machine’ for research on dynamic compilation
* ![image-20200325231437892](D:\OneDrive\Pictures\Typora\image-20200325231437892.png)
* ![image-20200325231501971](D:\OneDrive\Pictures\Typora\image-20200325231501971.png)
* LLVM IR
  * ![image-20200325231523291](D:\OneDrive\Pictures\Typora\image-20200325231523291.png)
  * ![image-20200325231534084](D:\OneDrive\Pictures\Typora\image-20200325231534084.png)
  * Three address pseudo assembly
  * Reduced instruction set computing (RISC)
  * Static single assignment (SSA) form
  * Infinite register set
  * Explicit type info and typed pointer arithmetic
  * Basic blocks
  * ![image-20200325231609812](D:\OneDrive\Pictures\Typora\image-20200325231609812.png)
  * `Module` contains `Functions` and `GlobalVariables`
    * Module is unit of compilation, analysis, and optimization
  * `Function` contains `BasicBlocks` and `Arguments`
    * Functions roughly correspond to functions in C
  * `BasicBlock` contains list of `instructions`
    * Each block ends in a control flow instruction
  * `Instruction` is opcode + vector of operands
* ![image-20200325231722372](D:\OneDrive\Pictures\Typora\image-20200325231722372.png)
* ![image-20200325231741412](D:\OneDrive\Pictures\Typora\image-20200325231741412.png)
* ![image-20200325231752652](D:\OneDrive\Pictures\Typora\image-20200325231752652.png)
* ![image-20200325231802077](D:\OneDrive\Pictures\Typora\image-20200325231802077.png)
* ![image-20200325231812523](D:\OneDrive\Pictures\Typora\image-20200325231812523.png)



## Polymorphism

* Polymorphism in programming languages refers to the possibility that a function or data structure can accommodate data of different types

* ad hoc polymorphism

  * allows a function to compute differently, based on the type of the argument
  * `==/!=` operators

* parametric polymorphism

  * a function behaves uniformly across the various types
  * `void*`...
  * ![image-20200325232103667](D:\OneDrive\Pictures\Typora\image-20200325232103667.png)

* Generic Data Structures

  * monomorphise the whole program and compile multiple versions of a function
  * box polymorphic data (replace them by a reference to the actual data)

* > A general approach to interactions between ad hoc and parametric polymorphism are type classes as they are used in Haskell. In lecture, students proposed some extensions of the above so that polymorphism can be limited to type classes. Since I did not take any pictures of the blackboard at the time, these extensions are lost to posterity unless someone sends me some suggestions.

* Type Inference

* Type Conversion & Coherence

  * implicit conversion/promotion
  *  A language satisfies __coherence__ if various legal ways of inserting type conversions always leads to the same answer



## First-Class Functions

* ![image-20200325232801955](D:\OneDrive\Pictures\Typora\image-20200325232801955.png)
* ![image-20200325232809547](D:\OneDrive\Pictures\Typora\image-20200325232809547.png)
* ![image-20200325232830531](D:\OneDrive\Pictures\Typora\image-20200325232830531.png)
* ![image-20200325232914422](D:\OneDrive\Pictures\Typora\image-20200325232914422.png)
* ![image-20200325232935756](D:\OneDrive\Pictures\Typora\image-20200325232935756.png)
* ![image-20200325232947203](D:\OneDrive\Pictures\Typora\image-20200325232947203.png)
* ![image-20200325233002996](D:\OneDrive\Pictures\Typora\image-20200325233002996.png)



## Verification

* [Proving a Compiler - OPLSS2012](Proving a compiler)



## Session-Typed Concurrency

* [concur](https://www.cs.cmu.edu/~fp/courses/15411-f13/lectures/25-concur.pdf)



## Obfuscation

* enthics: Digital Rights Management Schemes (DRM)
* program data in `.text` section
* `00 00 <=> add %al, (%eax)`
* ![image-20200325233501044](D:\OneDrive\Pictures\Typora\image-20200325233501044.png)
* Anti-Analysis on IDA Pro/CMU BAP
  * confuse the function boundary
    * different compilers tend to produce vastly different function boundary code!
    * x86: small difference, `stdcall` vs. `cdecl` vs. `fastcall`
    * x86-64: significant difference Microsoft calling convention vs. System V
    * IDA uses heuristics to decide
  * confuse the stack pointer
    * IDA relies on symbolic execution which expects the stack pointer to remain at sensible values
  * faking a sequence of instructions
    * ![image-20200325233851219](D:\OneDrive\Pictures\Typora\image-20200325233851219.png)
  * `ret` after `pop` might cause IDA to believe it's end of a function
  * use `jmp *rdi`  (IDA labels it as chunk instead of normal function)
  * ![image-20200325233955836](D:\OneDrive\Pictures\Typora\image-20200325233955836.png)
* Anti-Debugging
  * abuse the fact that each program can only be debugged by one debugger
    * insert a `ptrace()` call to the program's parent attach itself
    * can be well-hidden `ptrace()`
  * Windows `IsDebugged`
  * ![image-20200325234117469](D:\OneDrive\Pictures\Typora\image-20200325234117469.png)
    * mitigating this anti-debugging technique involves writing a custom loader for the target program, and loading the structure into memory oneself. 
    * In general, understanding what the structure is entails a full static analysis of the original program, effectively defeating the entire purpose of debugging in the first place
  * forced breakpoints: `int 3`
    * Inserting int 3 in various locations in the program would cause the reverse engineer to need to manually deal with vastly more breakpoints than desired (especially in tight loops) and hence hinder his or her debugging efforts
    * text replacing to `nop`...
* Other Techniques
  * IR-level hiding (SSA)
    * add extra unnecessary control flow nodes, without losing too much in performance
    * given the basic block information, one can then reorder blocks in the binary, making reading disassembler output an exercise in scrolling (lol)
  * Packers
    * compressed/encrypted version of the binary on disk (packed) `=>` small loader stub decrypt/decompress (unpack) the rest of the binary in memory
    * can even unpack individual functions or basic blocks one at a time, and then re-pack them when they are no longer running
    * Packing is generally defeated by dumping the contents of memory at runtime, though the specific implementation of this technique can make memory dumps much harder. Packing has perhaps the highest return of any anti-reverse-engineering technique, but is itself very time-consuming to write
  * Calling conventions
    * Per-function calling conventions are the extreme of making human analysis difficult, as then the human would need to keep track of which function takes which convention
    * it requires quite a lot of information be passed around at compile time and instruction selection time to make it workable, and so is less viable than some other techniques
  * Program bugs
    * use of bugs in `objdump` & IDA
    * produce segfault for `objdump`...
* 

