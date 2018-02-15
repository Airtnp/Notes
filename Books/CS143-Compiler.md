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
* 