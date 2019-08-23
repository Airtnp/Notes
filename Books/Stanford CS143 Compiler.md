# Compilers

## Intro
* Compiler
* + Lexical Analysis
* + Parsing
* + Semantic Analysis
* + Optimization
* + Code Generation
* Intermediate language
* Types
* + parameterization (* -> *)
* + subtyping (inheritance)

## Lexical analysis
* Tokens
* + Identifier
* + Literal
* + Keyword
* + Whitespace
* + Operator
* Step1: Define finte set of tokens
* Step2: Describe what kind of strings belongs to each token
* Impl1: Recognize substring of tokens
* Impl2: Return value or lexeme(substring) of the token
* Input String => Lexemes => Identify Lexemes
* Left-to-right scan: need lookahead
* Regular Expression
* + epsilon (empty)
* + character
* + union (A+B / A|B / [AB])
* + - range [a-z]
* + - excluded range [^a-z]
* + concatenation (AB)
* + Iteration (A*)
* + - A+ = AA*
* + - A? = A|ε
* Finite automata
* + DFA
* + NFA
* Lexical Spec => RegExp => NFA => DFA => Tables
* Lexical Spec => RegExp
* + regexp for each lexemes
* + L(R) = L(R1) + L(R2) + ... + L(Rn)
* + Test input on L(R)
* + - pick the longest possible string in L(R)
* + - pick the first token rule applies (like if as keyword instead of identifier)
* + - error handling => a last rule matching all bad strings
* Finite Automata (implement regexp)
* + epsilon-move
* + - DFA (no epsilon-move), one transition per input per state, fast
* + - NFA (has epsilon-move), can have multiple choice
* RegExp => NFA
* + eps: eps-move
* + input alpha: alpha-move
* + AB: A-eps-B
* + A|B: E-eps-A-eps-F + E-eps-B-eps-F
* + A*: E-eps-A-eps-F + A-eps-E + E-eps-F
* NFA => DFA
* + [Thompson](https://zhuanlan.zhihu.com/p/31158595)
* + simulate NFA
* + each state of DFA = a non-empty subset of states of the NFA
* + start state = set of NFA states reachable through eps-move from NFA start state
* + S-alpha-S' iff S' is the set of NFA states reachable from any state in S aftering seeing the input alpha, considering eps-move
* + eps-closure: DFS/BFS
* + DFA can be huge => 2^N - 1 subsets
* DFA minimization
* + [Hopcroft](https://zhuanlan.zhihu.com/p/31166841)
* + Given Q. First divide to A = {End State}, N = Q \ A
* + Consider N, if character c can divide into P, Q which P -c- J1 and Q -c-J2, then repeat this procedure on P, Q individually. Otherwise, choice next character.
* + Repeat this for A
* DFA => Table
* + States:Input Symbol
* + T[i, a] = k: Si-alpha-Sk
* + Execution: Read T[i, a]

## Parsing
* Not re: a^nb^n
* Input: sequence of tokens from lexer
* Output: parse tree
* CFG (Context-free grammar)
* + natural notation for recursive structure
* + A set of terminals T
* + A set of non-terminals N
* + A start symbol S (non-terminal)
* + A set of productions
* + - X -> Y1Y2...Yn where X in N and Y in T | N | {eps}
* + Begin with S (string)
* + Replace non-terminal X to Y1...Yn
* + Repeat until no non-terminal
* flex: re
* bison: cfg
* Derivation
* + sequence of productions (S -> ... -> ...)
* + can be drawn as a tree
* + start as root
* + production as children
* + in-order traversal of leaves => original input
* + Left-most / Right-most
* Ambiguity
* + `E = E + E | E * E | (E) | id`
* + => `E = E' + E | E'`
* + => `E' = id * E' | id | (E) * E' | (E)`
* + more than one parse tree
* + rewrite
* + operator precedence
* + - precedence climbing (Shunting yard)
* + `E = if E then E | if E then E else E | Other`
* + - `if E1 if E2 then E3 else E4`
* + - `else` match the closest unmatched `then`
```
E -> MIF | UIF
MIF -> if E then MIF else MIF | ...
UIF -> if E then E | if E then MIF else UIF
```
* + precedence and associativity
```
Error kind    Example    Detected by
Lexical       $          lexer
Syntax        x*%        parser
Semantic      int x; y=x type checker
Correctness   user       user
```
* Error handling
* + report error
* + recorver from error
* + no slow-down for compilation
* + panic mode
* + - discard token until one with a clear role (synchronizing tokens) is found
* + - statement/expression terminators
* + error production
* + - specify in grammar of common mistakes
* + automatic local/global correction
* + - try token insertion/deletion
* + - exhausive search
* AST
* + grammar symbol => attributes
* + - terminal symbol (lexcial token) can be calculated by the lexer
* + production => action
* + - X->Y1...Yn
* Action => Syntax-directed translation
* + Declarative
* + - order of resolution is not specified
* + - parser figures it out
* + Imperative
* + - order of evaluation is fixed
* + - important if the actions change global state
* Dependency Graph
* + AST node => val (this value can be a ast)
* + compute all children
* + synthesized attributes (from descendents)
* + inherited attributes (from parent/siblings)
* Top-down parsing (Recursive Descent)
* + from top
* + from left to right
* + recursive descent
* + Token stream => Try rules in order => Mismatch backtrack
* + cannot backtrack since a production is successful
* + needs grammars where at most 1 production can succeed for a non-terminal
```c++
bool term(TOKEN tkn) { return *next++ == tkn; }
bool Sn() { ... } // nth production
bool S() { 
    TOKEN* current = next;
    return (next = current, S1()) || (next = current, S2()) || ... ;
} // all production
```
* + left-recursive => infinite loop
* + - `S -> Sa`
* + - elimination of left-recursion
* + - - `S -> S a | b` => `S -> b S'` | `S' -> a S' | esp`
* + - - `S -> S a1 | ... | S an | b1 | ... | bn`
* + - - => `S  -> b1 S' | ... | bn S'`
* + - - => `S' -> a1 S' | ... | an S' | esp`
* + - - What if `S -> A a | b` | `A -> S c`, then `S -> A a -> S c A`
* + - - [左递归消除](http://www.cnblogs.com/nano94/p/4020775.html)
```
Arrange all non-terminal symbol as order A1, ..., An
For i = 1 to n {
    For j = 1 to i - 1 {
        Denote Aj -> s1 | ... | sk
        Replace Ai -> Aj t to
            Ai -> s1 t | ... | sk t
        Eliminate left-recursion in Ai -> Ai a | ...
    }
}
```
* Predictive parser
* + look next few tokens
* + no backtracking
* + LL(k) (leeft-to-right-scan leftmost-derivation predict-based-on-k-tokens-of-lookahead)
* + LL(1) used often
* LL(1)
* + nonterminal left-most A
* + lookahead next input t
* + unique-production A -> a to use (or no production => error state)
* + left-factor grammar: factor out common prefixes of productions
* + [左公因式提取]()
* + parser table E[A, t]
* + - `A -> a -> t b` (t in First(A)) | `A -> a -> eps` & `S -> b A t c` (t in Follow(A))
```
First(X) = { t | X ->* t a } | { eps | X ->* eps }
First(t) = { t }
If X -> eps | (X -> A1...An & eps in First(Ai))
    eps in First(X)
If X -> A1...An a
    First(a) in First(X)

Follow(X) = { t | S ->*  b X t c }
$ in Follow(S)
For production A -> a X b
    First(b) \ { eps } in Follow(X)
For production A -> a X b while eps in First(b)
    Follow(A) in Follow(X)

For each production A -> a
    For each terminal t in First(a)
        T[A, t] = a
    If eps in First(a)
        For each t in Follow(A)
            T[A, t] = a
    If eps in First(a)
        If $ in Follow(A)
            T[A, $] = a
```
* + stack recording froniter of parse tree (top = leftmost pending terminal/non-terminal)
* Bottom-Up Parsing => LR(0)
* + reduce a string to start symbol by inverting productions
* + right-most derivation
* + split string into two substrings (stack)
```
shift: ABC|xyz => ABCx|yz (push to stack)
reduce: given A->xy, Cbxy|ijk = CbA|ijk (pop symbols and push non-terminals)
```
* + conflict
* + - shift-reduce
* + - - `X -> b.` and `Y->a.tc`
* + - reduce-reduce
* + - - `X -> b.` and `Y -> a.`
* + handle
* + - a handle is a string that can be reduced and also allows further reductions back to the start symbol
* + - only appear at top of stack, never inside
* + - rightmost nonterminal
* + - recognize handle? => SLR CFG in Unambiguous CFG in All CFG
* + For any grammar, the set of viable prefixes is a regular language
* + [SLR](http://blog.sina.com.cn/s/blog_6759b6210100wnkm.html)
* + - LR(0) Automata
* + - - Status => Item: For production X -> R, We have item X -> .R/R./Pr.Sr...
* + - - Calculate Extended grammar, add S'->S (start term)
* + - - Calculate eps-closure: A -> a.Bc, add B->.c
```
NFA for viable prefix
1.  Add a dummy production S’ → S to G
2.  The NFA states are the items of G
    –  Including the extra production
3. For item E → α.Xβ add transition
    E → α.Xβ →X E → αX.β
4. For item E → α.Xβ and production X → γ add
    E → α.Xβ →ε X → .γ
5. Every state is an accepting state
6. Start state is S’ → .S
NFA => DFA
GOTO(I, X) = Closure(U { A -> a X.b | A -> a.Xb in I})
```
* + - SLR table
```
Action[i, a] = {
    If A -> a.ab in Ii & GOTO(Ii, a) = Ij => ACTION[i, a] = j
    If A -> a. in Ii => Forall a in Follow(A) => ACTION[i, a] = reduce A->a // That's what LR(0) different from SLR
    If S' -> S. => ACTION[i, $] = accept
    Else Action[i, a] = error
}

1.  Let M be DFA for viable prefixes of G
2.  Let |x1…xn$ be initial configuration
3.  Repeat until configuration is S|$
    •  Let α|ω be current configuration
    •  Run M on current stack α
    •  If M rejects α, report parsing error
        •  Stack α is not a viable prefix
    •  If M accepts α with items I, let a be next input
        •  Shift if X → β. a γ ∈ I
        •  Reduce if X → β. ∈ I and a ∈ Follow(X)
        •  Report parsing error if neither applies

Stack: (Symbol, DFA State)

goto[i, A] = j if state_i ->A state_j
shift x
reduce x
accept
error

Let I = w$ be initial input
Let j = 0
Let DFA state 1 have item S’ → .S
Let stack = 〈 dummy, 1 〉
    repeat
        case action[top_state(stack),I[j]] of
            shift k: push 〈 I[j++], k 〉
            reduce X → A:
                pop |A| pairs,
                push 〈X, goto[top_state(stack),X]〉
            accept: halt normally
            error: halt and report error
```
* + - Normalize LR
* + LALR

## Semantics
* Identifier
* Scope
* + static scope
* + dynamic scope
* Typecheck
* Type Inference
* + `O,M,C |- e : T`
* + An expression e occurring in the body (class) of C has static type T given a variable type environment O and method signatures M
* + static type
* + - self type
```
O,M,C |- e0@T.f(e1,…,en) : T0 (static dispatch depend on e0)
```
* + - least-upper-bound
```
O[T/y] means O modified to return T on argument y
O |- if e0 then e1 else e2 fi: lub(T1,T2)
O |- case e0 of x1:T1 → e1; …; xn:Tn → en; end : lub(T1’,…,Tn’)
```
* + - static dispatch / dynamic dispatch
```
dynamic dispatch O, M |- e0.f(e1, … ,en): Tn+1 (depend on e0)
static dispatch O, M |- e0@f(e1, … ,en): Tn+1 (depend on e0 <: T)
```
* + - 
* + dynamic type
* + - new T
* + error handling
* + - Assign type Object to ill-typed expression
* + - Then every other operation can cause error
* + - Assign type bottom to ill-typed expression
* + - Every other operation on bottom return bottom
* + - `Bottom <: T`
* Inheritance
* ODR
* Diagnosis

## Runtime
* invocation
* lifetime (dynamic)
* activation tree
* activation record (AR) / frame
* + return value
* + parameter
* + pointer to previous AR
* + machine status
* + - PC/registers
* Alignment
* stack-based/register-based
* Stack Machine
* + Takes its operands from the top of the stack
* + Removes those operands from the stack
* + Computes the required operation on them
* + Pushes the result on the stack

## Code generation
* MIPS
* + RISC
* + $sp(rbp) $a0 $a1 $ra $fp(rsp)
* + lw / add / sw / addiu / li / beq / jal / jr
```
P    → D; P | D
D    → def id(ARGS) = E;
ARGS → id, ARGS | id
E    → int | id | if E1 = E2 then E3 else E4
           | E1 + E2 | E1 – E2 | id(E1,…,En)

cgen(e1 + e2) =
    cgen(e1)
    sw $a0 0($sp)
    addiu $sp $sp -4
    cgen(e2)
    lw $t1 4($sp)
    add $a0 $t1 $a0
    addiu $sp $sp 4

cgen(e1 + e2, nt) =
    cgen(e1, nt)
    sw $a0 nt($fp)
    cgen(e2, nt + 4)
    lw $t1 nt($fp)
    add $a0 $t1 $a0

cgen(if e1 = e2 then e3 else e4) =
    cgen(e1)
    sw $a0 0($sp)
    addiu $sp $sp -4
    cgen(e2)
    lw $t1 4($sp)
    addiu $sp $sp 4
    beq $a0 $t1 true_branch
    false_branch:
    cgen(e4)
    b end_if
    true_branch:
    cgen(e3)
    end_if:

cgen(f(e1,…,en)) =
    sw $fp 0($sp)
    addiu $sp $sp -4
    cgen(en)
    sw $a0 0($sp)
    addiu $sp $sp -4
    …
    cgen(e1)
    sw $a0 0($sp)
    addiu $sp $sp -4
    jal f_entry

call
...
push rbp     
mov rbp rsp (enter) / or sub rsp N
...
mov rsp rbp (leave) / or add rsp N
pop rbp
ret

cgen(def f(x1,…,xn) = e) =
    move $fp $sp
    sw $ra 0($sp)
    addiu $sp $sp -4
    cgen(e) // cgen(xi) = lw $a0 z($fp)
    lw $ra 4($sp)
    addiu $sp $sp z
    lw $fp 0($sp)
    jr $ra
```
* NT: number of temporary values
* + known in compile-time to calculate stack size
* OOP
* + object
```
Class {
    Class Tag
    Object Size
    Dispatch Ptr
    Attributes...
}
```
* + dynamic dispatch

## Semantics
* Denotational
* + program => mathematical function
* Axiomatic
* + Program behavior described via logical formulae
* + - If execution begins in state satisfying X, then it ends in state satisfying Y.
* Operational
* + Describes program evaluation via execution rules on an abstract machine
* + environment: variable => location(memory)
* + store: location => value
* + type context: name => type / location => type
* + kind context: type variable => type
* + program context
```
E, S |- Term: value, S'

so, E, S ` e1 : v1, S1
l_new = newloc(S1)
so, E[l_new/id] , S1[v1/l_new] |- e2 : v2, S2
------------------------------------------------
so, E, S |- let id : T ← e1 in e2 : v2, S2

Informal semantics of e0.f(e1,…,en)
–  Evaluate the arguments in order e1,…,en
–  Evaluate e0 to the target object
–  Let X be the dynamic type of the target object
–  Fetch from X the definition of f (with n args.)
–  Create n new locations and an environment that maps f’s formal arguments to those locations
–  Initialize the locations with the actual arguments
–  Set self to the target object and evaluate f’s body
```

## Optimization
* Where?
* + On AST
* + - Pro: Machine independent
* + - Con: Too high level
* + On assembly language
* + - Pro: Exposes optimization opportunities
* + - Con: Machine dependent
* + - Con: Must reimplement optimizations when retargetting
* + On an intermediate language
* + - Pro: Machine independent
* + - Pro: Exposes optimization opportunities
* IL => high-level assembly
* + high-level opcodes
* + unlimited registers
* + control structure
```
P → S P | ε
S → id := id op id
    | id := op id
    | id := id
    | push id
    | id := pop
    | if id relop id goto L
    | L:
    | jump L
```
* basic block: maximal sequence without non-1st label + non-last jump
* + single-entry/single-exit/straight-line
* CFG (control flow graph)
* + directed graph
* + basic blocks as nodes
* + A -> B: execution can be passed from A -> B (jump L_B / A | B)
* Optimization granularity
* + local optimizaiton: a basic block in isolation
* + global optimization: control-flow graph in isolation
* + inter-procedural optimization: across method boundaries
* + LTO
* Local optimization
* + algebraic simplification (Strength reduction)
* + - replaces complex operations by simpler ones and can be applied to this code segment, replacing the MULT by a shift left.
* + constant folding
* + - find constants in code and propagate them, collapsing constant values whenever possible.
* + flow of control
* + - eliminate unreachable basic blocks
* + - dead code elimination
* + single assignment form
* + - register occurs only once on the left-hand side of an assignment
* + common subexpression elimination
```
If
    –  Basic block is in single assignment form
    –  A definition x := is the first use of x in a block
Then
    –  When two assignments have the same rhs, they compute the same value
```
* + copy propagation
* + - rename, enabling other optimizations
* + loop optimization
* + - code motion
* + - induction variable elimination
> Code motion finds code that is loop invariant: a particular piece of code computes the same value on every iteration of the loop and, hence, may be computed once outside the loop. Induction variable elimination is a combination of transformations that reduce overhead on indexing arrays, essentially replacing array indexing with pointer accesses.
* + Peephole optimization
* + - on assembly/IL
```
i1, …, in → j1, …, jm

addiu $a $b 0 → move $a $b
addiu $a $a i, addiu $a $a j → addiu $a $a i+j
```
* Global Optimization
* + X => K: on every path to the use of X, the last assignment is X := K
* + global analysis
* + - dataflow
* + - constant
* + constant propagation (forward: input => output)
* + - never execute (bottom) (z) / constant (c) / not a constant (º)
```
z < c < º

Define
    C(s,x,in) = value of x before s
    C(s,x,out) = value of x after s

C(s, x, in) = lub { C(p, x, out) | p is a predecessor of s }

    if C(pi, x, out) = º for any i, then C(s, x, in) = º

    C(pi, x, out) = c & C(pj, x, out) = d & d <> c then C(s, x, in) = º

    if C(pi, x, out) = c or z for all i, then C(s, x, in) = c

    if C(pi, x, out) = z for all i, then C(s, x, in) = z

C(s, x, out) = z if C(s, x, in) = z

C(x := c, x, out) = c if c is a constant

C(x := f(…), x, out) = º

C(y := …, x, out) = C(y := …, x, in) if x <> y

1.  For every entry s to the program, set C(s, x, in) = º
2.  Set C(s, x, in) = C(s, x, out) = z everywhere else
3.  Repeat until all points satisfy 1-8: 
    Pick s not satisfying 1-8 and update using the appropriate rule
```
* + Liveness analysis (backward: output => input)
```
A variable x is live at statement s if
–  There exists a statement s’ that uses x
–  There is a path from s to s’
–  That path has no intervening assignment to x

L(p, x, out) = ∨ { L(s, x, in) | s a successor of p }

L(s, x, in) = true if s refers to x on the rhs

L(x := e, x, in) = false if e does not refer to x

L(s, x, in) = L(s, x, out) if s does not refer to x

1.  Let all L(…) = false initially
2.  Repeat until all statements s satisfy rules 1-4
    Pick s where one of 1-4 does not hold and update using the appropriate rule
```
> Some other optimization can refer to EECS370 book Section 2.15
* Register Allocation
* + memory hierarchy: register=>cache=>main memory=>disk
* + most program only aware of main memory + disk
* + t1,t2 share a register iff at any point most one of t1,t2 is live
```
RIG (Register Inference Graph)
    A node for each temporary
    An edge between t1 and t2 if they are live simultaneously at some point in the program

k-colorable RIG => NP-hard

k-coloring Heuristic
    –  Pick a node t with fewer than k neighbors
    –  Put t on a stack and remove it from the RIG
    –  Repeat until the graph has one node
Assign colors to nodes on the stack
    –  Start with the last node added
    –  At each step pick a color different from those assigned to already colored neighbors
What if heuristic falls (maybe unable to k-coloring)
    If optimistic coloring fails, we spill f
        Allocate a memory location for f
            Typically in the current stack frame
            Call this address fa
    Before each operation that reads f, insert
        f := load fa
    After each operation that writes f, insert
        store f, fa
    Spill temporaries with most conflicts
    Spill temporaries with few definitions and uses
    Avoid spilling in inner loops
Recompute liveness after spilling
```
* + Cache optimization
* + - nested loop (fusion, distribution, unrolling)

## Automatic Memory Management
* Linear type
* Garbage Collection
* + [Java](https://www.zhihu.com/question/35164211)
* + [Golang](https://www.zhihu.com/question/58863427)
* + Mark and Sweep
* + - reachable
* + - mark: traces reachable objects
* + - sweep: collect garbage objects
* + - object with extra mark bit
* + - Pro: objects are not moved during GC
* + - Con: Can fragment memory
* + - Auxiliary/Free List is stored in free objects themselves
```
let todo = { all roots }
while todo ≠ ∅ do
    pick v ∈ todo
    todo ← todo - { v }
    if mark(v) = 0 then (* v is unmarked yet *)
        mark(v) ← 1
        let v1,...,vn be the pointers contained in v
        todo ← todo ∪ {v1,...,vn}
    end
end

The sweep phase scans the heap looking for objects with mark bit 0
    these objects were not visited in the mark phase
    they are garbage

(* sizeof(p) is the size of block starting at p *)
p ← bottom of heap
while p < top of heap do
    if mark(p) = 1 then
        mark(p) ← 0
    else
        add block p...(p+sizeof(p)-1) to freelist
    end
    p ← p + sizeof(p)
end
```
* + Stop and Copy
* + - old space: used for allocation
* + - new space: used as a reserve for GC
* + - - copied and scanned | copied | empty
* + - must be able to know the size of object
* + - must copy any objects pointed by the stack and update pointers in the stack
* + - cheap: allocation/collection
* + - need reflection to consider whether the memory is a pointer
```
Starts when the old space is full
Copies all reachable objects from old space into new space
    garbage is left behind
    after the copy phase the new space uses less space than the old one before the collection
    as we copy an object we store in the old copy a forwarding pointer to the new copy (solving pointer reference)
After the copy the roles of the old and new spaces are reversed and the program resumes

Step 1: Copy the objects pointed to by roots and set forwarding pointers
Step 2: Follow the pointer in the next unscanned object (A)
    –  copy the pointed-to objects (just C in this case)
    –  fix the pointer in A
    –  set forwarding pointer

while scan <> alloc do
    let O be the object at scan pointer
    for each pointer p contained in O do
        find O’ that p points to
        if O’ is without a forwarding pointer
            copy O’ to new space (update alloc pointer)
            set 1st word of old O’ to point to the new copy
            change p to point to the new copy of O’
        else
            set p in O equal to the forwarding pointer
        end
    end
    increment scan pointer to the next object
end
```
* + Reference Counting
* + - Pro: easy to implement / no large pauses
* + - Con: cannot collect circular reference / slow to manipulating at each assignment
* + Generational
* + Concurrent: program | collector
* + Parallel: several collectors

## Security
* bound check
* buffer overflow(overrun)
* + stack smashing
* safety
* + language design
* + - type safety
* + - memory safety
* + - lifetime analysis
* + bug finding tools
* + - detect patterns
* + - use heuristics
* + verification
* + dynamic
* + - sandboxing
* + - code and data randomization