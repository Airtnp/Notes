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
* 