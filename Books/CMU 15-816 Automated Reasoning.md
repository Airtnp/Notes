# Automated Reaonsing

[fall2019](http://www.cs.cmu.edu/~mheule/15816-f19/schedule.html)

[[N: The second half term is a research project...]]



## Introduction

* encode `->` automated reasoning `->` decode
* Satisfiability (SAT) problem: Can a Boolean formula be satisfied?
* Pythagorean Triples Problem
  * if it is possible to color each of the positive integers either red or blue, so that no Pythagorean triple of integers *a*, *b*, *c*, satisfying $\displaystyle a^{2}+b^{2}=c^{2}$ are all the same color
  * [wiki](https://en.wikipedia.org/wiki/Boolean_Pythagorean_triples_problem)
  * Best lower bound: a bi-coloring of [1, 7664] s.t. there is no monochromatic Pythagorean Triple 
    * [Cooper & Overstreet 2015].
  * ![image-20200711224115919](D:\OneDrive\Pictures\Typora\image-20200711224115919.png)
  * Mayer Heule: largest math proof ever (4 CPU yrs, 200 TBs, 2 days on cluster)
* Terminology
  * Variable: boolean variable
  * Literal: $x_i$ or $\bar{x}_i$
  * Clause: disjunction of literals
    * Can be falsified with only one assignment to its literals: All literals assigned to false
    * One special clause - the empty clause (denoted by ⊥) - which is always falsified
  * Formula: conjunction of clauses
    * satisfiable if $\exists$ assignment satisfying all clauses
    * CNF form
    * Any propositional formula can be efficiently transformed into CNF [Tseitin'70]
  * Assignments: mapping of values to variables
    * $\varphi \circ \mathcal{F} \to \mathcal{F}_{\text{reduced}}$
      * all satisfied clauses removed
      * all falsified literals removed
    * satisfying assignment `<->` reduce `F` is empty
    * falsifying assignment `<->` reduce `F` contains $\bot$
    * partial vs. full
* Resolution/$\bowtie$
  * ![image-20200711224758917](D:\OneDrive\Pictures\Typora\image-20200711224758917.png)
  * Adding (non-redundant) resolvents until fixpoint, is a complete proof procedure. It produces the empty clause if and only if the formula is unsatisfiable
* Tautology
  * A clause C is a tautology if it contains for some variable x, both the literals x and $\bar x$
* Basic Solving Techniques
  * Unit propagation
    * A unit clause is a clause of size 1
    * ![image-20200711230058151](D:\OneDrive\Pictures\Typora\image-20200711230058151.png)
  * DPLL (David Putnam Logemann Loveland, DP60, DLL62)
    * Recursive procedure that in each recursive call: 
      * Simplifies the formula (using unit propagation)
      * Splits the formula into two subformulas
        * Variable selection heuristics (which variable to split on)
        * Direction heuristics (which subformula to explore first)
  * Decision
    * Decision variables
      * Variable selection heuristics and direction heuristics
      * Play a crucial role in performance
  * Implication
    * Implied variables
      * Assigned by reasoning (e.g. unit propagation)
      * Maximizing the number of implied variables is an important aspect of look-ahead SAT solvers
  * Clauses `<->` Assignments
    * A clause C represents a set of falsified assignments, i.e. those assignments that falsify all literals in C
    * A falsifying assignment ϕ for a given formula represents a set of clauses that follow from the formula
      * For instance with all decision variables
      * Important feature of conflict-driven SAT solvers
* Solvers
  * Conflict-driven
    * search for short refutation, complete
    * examples: lingeling, glucose, CaDiCaL
  * Look-ahead
    * extensive inference, complete
    * examples: march, OKsolver, kcnfs
  * Local search
    * local optimizations, incomplete
    * examples: probSAT, UnitWalk, Dimetheus
* ![image-20200711230422134](D:\OneDrive\Pictures\Typora\image-20200711230422134.png)
* Applications
  * ![image-20200711230434494](D:\OneDrive\Pictures\Typora\image-20200711230434494.png)
  * ![image-20200711230438990](D:\OneDrive\Pictures\Typora\image-20200711230438990.png)
* Random `k`-SAT
  * All clauses have length k
  * Variables have the same probability to occur
  * Each literal is negated with probability of 50%
  * Density is ratio Clauses to Variables



## Applications for Automated Reasoning

* Equivalence checking
  * hw/sw optimization
  * sw `->` FPGA conversion ([[R: HLS]])
  * Encoding
    * represent procedures as Boolean variables
      * ![image-20200712194609691](D:\OneDrive\Pictures\Typora\image-20200712194609691.png)
    * compile code into CNF
      * `compile(if x then y else z) ≡ (x ∨ y) ∧ (x ∨ z)`
    * check equivalence of Boolean formula
      * is the Boolean formula `compile(original) <=/=> compile(optimized)` satisfiable?
      * Miter: a circuit that tests whether there exists an input for both circuits such that the output differs
        * ![image-20200712201928555](D:\OneDrive\Pictures\Typora\image-20200712201928555.png)
* Bounded model checking
  * hw/sw verification
  * Given a property `p`: Is there a state reachable in `k` steps, which satisfies $\bar{p}$
  * ![image-20200712205628041](D:\OneDrive\Pictures\Typora\image-20200712205628041.png)
  * Encoding
    * reachable states: $I(S_0) \wedge T(S_0, S_1) \wedge \cdots \wedge T(S_{k-1}, S_k)$
    * property `p` fails in one of the `k` steps by: $\bar{P}(S_0) \vee \bar{P}(S_1) \vee \cdots \vee \bar{P}(S_k)$
    * safety property `p` is valid up to step `k` iff. $\mathcal{F}(k)$ is unsatisfiable
      * $\mathcal{F}(k) = I(S_0) \wedge \bigwedge_{i=0}^{k-1} T(S_i, S_{i + 1}) \wedge \bigvee_{i=0}^k \bar{P}(S_i)$
    * Example: 2-bit counter
      * ![image-20200712210128553](D:\OneDrive\Pictures\Typora\image-20200712210128553.png)
* Graph problems & Symmetry breaking
  * ![image-20200712210636600](D:\OneDrive\Pictures\Typora\image-20200712210636600.png)
  * Ramsey numbers & unavoidable subgraphs
    * A connected undirected graph `G` is an **unavoidable subgraph** of clique `K` of order `n` if **any red/blue edge-coloring** of the edges of `K` contains `G` either in red or in blue.
    * Ramsey Number `R(k)`: What is the smallest n such that any graph with n vertices has either a clique or a co-clique of size k? (`R(3)=6, R(4)=18, 43 <= R(5) <= 49`)
    * ![image-20200712213821625](D:\OneDrive\Pictures\Typora\image-20200712213821625.png)
    * Symmetry-breaking predicate
      * ![image-20200712213843975](D:\OneDrive\Pictures\Typora\image-20200712213843975.png)
  * CNF `->` clause-literal graph `->` detect symmetry `->` add symmetry-breaking predicates
* Arithmetic operations
  * encoding arithmetic operations `->` electronic circuits
    * ![image-20200712214025760](D:\OneDrive\Pictures\Typora\image-20200712214025760.png)
    * ![image-20200712214031656](D:\OneDrive\Pictures\Typora\image-20200712214031656.png)
  * factorization
    * Is 27 a prime?
    * ![image-20200712214139983](D:\OneDrive\Pictures\Typora\image-20200712214139983.png)
  * term rewriting
    * Given a set of rewriting rules, will rewriting always terminate?
    * Strongest rewriting solvers use SAT (e.g. AProVE)
    * ![image-20200712214209417](D:\OneDrive\Pictures\Typora\image-20200712214209417.png)
  * Collatz rewriting
    * ![image-20200712214232831](D:\OneDrive\Pictures\Typora\image-20200712214232831.png)



## Representations for Automated Reasoning

* At least one: `(x1 ∨ x2 ∨ · · · ∨ xn)`
* Exclusive or: odd number of `xi` is assigned to true
  * direct encoding: $\bigwedge_{\text{even} \#\neg}\limits (\bar{x}_1 \vee \bar{x}_2 \vee \cdots \vee \bar{x}_n)$
  * compact: $\textit{XOR}(x_1, x_2, y) \wedge \textit{XOR}(\bar{y}, x_3, \cdots, x_n)$
    * increase the number of variables but decreases the number of clauses
* At most one
  * direct encoding, `n(n-1)/2` clauses: $\bigwedge_{1 \leq i < j \leq n} (\bar{x}_i \vee \bar{x}_j)$
  * splitting the constraints if $n \leq 4$: $\textit{AtMostOne}(x_1, x_2, x_3, y) \wedge\textit{AtMostOne}(\bar{y}, x_4, \cdots, x_n)$ 
    * $3n-6$ clauses, $(n - 3) / 2$ new variables
  * equisatisfiable: ϕ1 is satisfiable iff ϕ2 is satisfiable.
    * ![image-20200715001014814](D:\OneDrive\Pictures\Typora\image-20200715001014814.png)
    * $\neg \varphi_1 \wedge \varphi_2$ is unsatisfiable
    * $\varphi_1 \wedge \neg \varphi_2$ is not unsatisfiable
    * ![image-20200715000925151](D:\OneDrive\Pictures\Typora\image-20200715000925151.png)
* Tseitin Transformation
  * In some cases, converting a formula to CNF can have an exponential explosion on the size of the formula.
    * ![image-20200715001705717](D:\OneDrive\Pictures\Typora\image-20200715001705717.png)
  * Tseitin’s transformation converts a formula ϕ into an equisatisfiable CNF formula that is linear in the size of ϕ
    * Key idea: introduce auxiliary variables to represent the output of subformulas, and constrain those variables using CNF clauses
  * ![image-20200715001748750](D:\OneDrive\Pictures\Typora\image-20200715001748750.png)
    * [[N: looks like LL(1) parsing...]]
    *  may add many redundant variables/clauses
* Boolean representation of Integers
  * Onehot encoding
    * Each number is represented by a boolean variable
    * At most one number: $\wedge_{i \ne j} \bar{x}_i \vee \bar{y}_j$
  * Unary encoding
    * Each variable $x_n$ is true iff the number is equal to or greater than n
      *  `x2 = 1` represents that the number is equal to or greater than 2
    * $x_i$ implies $x_{i + 1}$: $\wedge_{i < j} \bar{x}_i \vee x_j$
  * Binary encoding
    * Use `log(n)` auxiliary variables to represent `n` in binary
    * x0 (number 0) corresponds to the binary representation 00 $\bar{x}_0 \vee \bar{b}_0, \bar{x}_0 \vee \bar{b}_1$
  * Order encoding
    * Encode the comparison $x \leq a$ by a different Boolean variable for each integer variable
    * Useful if you want to capture the order between integers
      * $\{x \leq a, \neg (y \leq a)\}$ can be used to represent the constraint among integer variables $x \leq y$
* Linear constraints
  * ![image-20200715002336880](D:\OneDrive\Pictures\Typora\image-20200715002336880.png)
  * ![image-20200715002345462](D:\OneDrive\Pictures\Typora\image-20200715002345462.png)
  * Consistency & Arc-Consistency
    * an encoding of a constraint C such that 
      * there is a correspondence between assignments of the variables in C with Boolean assignments of the variables in the encoding
      * The encoding is consistent if whenever M is partial assignment inconsistent wrt C (i.e., cannot be extended to a solution of C), unit propagation leads to conflict
      * The encoding is arc-consistent if
        * it is consistent, and
        * unit propagation discards arc-inconsistent values (values that cannot be assigned)
      * SAT solvers are very good at unit propagation
    * ![image-20200715002612872](D:\OneDrive\Pictures\Typora\image-20200715002612872.png)
* Adder Encoding
  * ![image-20200715003052422](D:\OneDrive\Pictures\Typora\image-20200715003052422.png)
* Sinz encoding
  * Can we build an encoding that is arc-consistent and uses a linear number of variables/clauses for at-most-k constraints?
    * ![image-20200715003131407](D:\OneDrive\Pictures\Typora\image-20200715003131407.png)
    * ![image-20200715003140029](D:\OneDrive\Pictures\Typora\image-20200715003140029.png)
* Totalizer encoding
  * ![image-20200715003157405](D:\OneDrive\Pictures\Typora\image-20200715003157405.png)
  * ![image-20200715003205487](D:\OneDrive\Pictures\Typora\image-20200715003205487.png)
* Other encodings
  * Majority are based on circuits
  * Sorting Networks use $O(nlog^2 k)$ variables and clauses
  * We can also generalize to linear constraints with integer coefficients called pseudo-Boolean constraints: $a_1 x_1 + \cdots + a_n x_n \leq k$
    * generalized Sinz encoding: consider the coefficient when writing the sum constraints
    * Binary merger encoding only requires $O(n^2 log^2(n)log(w_{\max}))$ clauses and maintains arc-consistency
* Hamiltonian Cycle
  * finding a closed loop through a graph that visits each node exactly once
  * ![image-20200715003421890](D:\OneDrive\Pictures\Typora\image-20200715003421890.png)
  * The out-degree and in-degree constraints force that, for each node, in-degree and out-degree are respectively exactly one in a solution cycle
  * The connectivity constraint prohibits the formation of sub-cycles, i.e., cycles on proper subsets of n nodes.
  * Transitive relations for all possible permutations of three nodes are used to represent the connectivity constraint which results in $O(n^3)$ clauses
  * Lazy encoding
    * Every time the solver returns a solution:
      * Check if it is connected. If it is then we found a solution
      * Otherwise, add constraints to force connectivity of the current path. Ask for a new solution
    * often faster than solving one large SAT formula
* Beyond Propositional Logic
  * integers, functions, sets, lists
  * Satisfiability Modulo Theories (SMT)!
    * ![image-20200715003704024](D:\OneDrive\Pictures\Typora\image-20200715003704024.png)



## SAT & SMT Solvers in Practice

* DIMACS: SAT solver input format
  * `header`: `p cnf n m`
    * `n`: the highest variable index
    * `m`: the number of clauses
  * `clauses`: a sequence of integers ending with `0`
  * `comments`: any line starting with `c`
  * ![image-20200719235035848](D:\OneDrive\Pictures\Typora\image-20200719235035848.png)
  * solution line: starts with `s`
    * `s SATISFIABLE/UNSATISFIABLE/UNKNOWN`
    * satisfiable `=>` certificate: lines starting with `v`
      * a list of integers ending with `0`
      * e.g. `v -1 2 4 0`
    * unsatisfiable `=>` proof of unsatisfiability
* CaDiCaL/SAT4J/UBCSAT
* [SAT Competition](http://satcompetition.org/)
* Graph coloring
  * ![image-20200719235317160](D:\OneDrive\Pictures\Typora\image-20200719235317160.png)
  * ![image-20200719235325365](D:\OneDrive\Pictures\Typora\image-20200719235325365.png)
* Unsatisfiable cores
  * An unsatisfiable core of an unsatisfiable formula F is a subset of F that is unsatisfiable.
  * An minimal unsatisfiable core of an unsatisfiable formula such that the removal of any clause makes the formula satisfiable.
  * Extracting a minimal unsatisfiable core from a formula has many applications, but the computational costs could be high
    * maxSAT
    * diagnosis
    * formal verification
* Proofs
  * A proof of unsatisfiability is a certificate that a given formula is unsatisfiable
  * Various proof producing methods exists
  * Proof checking tools cannot only validate a proof but also produce additional information about the formula
    * unsatisfiable core
    * optimized proof
  * `DRAT-trim`
* `SMT-LIB`: SMT solver input format
  * Z3/CVC4/Yices/Boolector



## Conflict-Driven Clause Learning

* Overview

  * most successful arch.
  * superior on industrial benchmarks
  * brute-force?
    * addition conflict clauses
    * fast unit propagation
  * complete local search (for a refutation)?
  * SOTA CDCL solvers: CaDiCaL, Glucose, CryptoMiniSAT

* ![image-20200725210029110](D:\OneDrive\Pictures\Typora\image-20200725210029110.png)

* Implication graph

  * CDCL in a nutshell
    * Main loop combines efficient problem simplification with cheap, but effective decision heuristics; (> 90% of time)
    * Reasoning kicks in if the current state is conflicting;
      * Find the cut that led to this conflict. From the cut, find a conflicting condition.
      * Take the negation of this condition and make it a clause.
      * Add the conflict clause to the problem.
    * The current state is analyzed and turned into a constraint;
      * Non-chronological back jump to appropriate decision level, which in this case is the second highest decision level of the literals in the learned clause.
    * The constraint is added to the problem, the heuristics are updated, and the algorithm (partially) restarts.
  * Problem
    * CDCL is notoriously hard to parallelize
    * the representation impacts CDCL performance; and
    * CDCL has exponential runtime on some “simple” problems
  * ![image-20200726001311043](D:\OneDrive\Pictures\Typora\image-20200726001311043.png)
  * [CDLL-interactive](https://cse442-17f.github.io/Conflict-Driven-Clause-Learning/)
  * [CDLL-intro-translation](https://zhuanlan.zhihu.com/p/92659252)

* Learning conflict clauses

  * tri-asserting clause
  * first unique implication point
  * second unique implication point
  * ![image-20200726004511613](D:\OneDrive\Pictures\Typora\image-20200726004511613.png)

* Data-structures

  * Watch pointers
    * Only examine (get in the cache) a clause when both 
      * a watch pointer gets falsified 
      * the other one is not satisfied
    * While backjumping, just unassign variables 
    * Conflict clauses → watch pointers 
    * No detailed information available 
    * Not used for binary clauses

* Heuristics

  * Variable selection heuristics
    * aim: minimize the search space
    * plus: could compensate a bad value selection
    * Based on the occurrences in the (reduced) formula
      * examples: Jeroslow-Wang, Maximal Occurrence in clauses of Minimal Size (MOMS), look-aheads
      * not practical for CDCL solver due to watch pointers
    * Variable State Independent Decaying Sum (VSIDS)
      * original idea (zChaff): for each conflict, increase the score of involved variables by 1, half all scores each 256 conflicts [MoskewiczMZZM’01]
      * improvement (MiniSAT): for each conflict, increase the score of involved variables by δ and increase δ := 1.05δ [EenS¨orensson’03]
      * [Visualization](https://www.youtube.com/watch?v=MOjhFywLre8)
  * Value selection heuristics
    * aim: guide search towards a solution (or conflict)
    * plus: could compensate a bad variable selection, cache solutions of subproblems [PipatsrisawatDarwiche’07]
    * Based on the occurrences in the (reduced) formula
      * examples: Jeroslow-Wang, Maximal Occurrence in clauses of Minimal Size (MOMS), look-aheads
      * not practical for CDCL solver due to watch pointers
    * Based on the encoding / consequently
      * negative branching (early MiniSAT) [EenS¨orensson’03]
    * Based on the last implied value (phase-saving)
      * introduced to CDCL [PipatsrisawatDarwiche’07]
      * already used in local search [HirschKojevnikov’01]
      * ![image-20200726004944398](D:\OneDrive\Pictures\Typora\image-20200726004944398.png)
  * Restart strategies
    * aim: avoid heavy-tail behavior [GomesSelmanCrato’97]
    * plus: focus search on recent conflicts when combined with dynamic heuristics
    * Restarts in CDCL solvers:
      * Counter heavy-tail behavior [GomesSelmanCrato’97]
      * Unassign all variables but keep the (dynamic) heuristics
    * Restart strategies: [Walsh’99, LubySinclairZuckerman’93]
      * Geometrical restart: e.g. 100, 150, 225, 333, 500, 750, . . .
      * Luby sequence: e.g. 100, 100, 200, 100, 100, 200, 400, . . .
    * Rapid restarts by reusing trail: [vanderTakHeuleRamos’11]
      * Partial restart same effect as full restart
      * Optimal strategy Luby-1: 1, 1, 2, 1, 1, 2, 4, . . .
    * SAT vs UNSAT
      * The best heuristics choices depend on satisfiability: E.g.
        * Restart frequently for UNSAT instances to get conflict early
        * Restart sporadically for SAT instances to keep “progress”
      * Also, keeping learned clauses is less important on SAT instances and can actually slow down the search.
      * State-of-the-art CDCL solvers, such as CaDiCaL, have separate modes for SAT and UNSAT and they alternate between them

* Clause Management

  * Clause deletion
    * Conflict clauses can significantly slow down CDCL solvers: 
      * Conflict clauses can quickly outnumber the original clauses 
      * Conflict clauses consists of important variables
    * Clause deletion is used to reduce the overhead: 
      * When the learned clause reach a limit, remove half 
      * Increase limit after every removal (completeness)
    * Clause deletion heuristics: 
      * length of the clause 
      * relevance of the clause (when was it used in Analyze) 
      * the number of involved decision levels

* Conflict-Clause Minimization

  * Self-Subsumption
    * Use self-subsumption to shorten conflict clauses
    * ![image-20200726005346593](D:\OneDrive\Pictures\Typora\image-20200726005346593.png)
    * Use implication chains to further minimization
  * ![image-20200726005411876](D:\OneDrive\Pictures\Typora\image-20200726005411876.png)
  * first unique implication point
  * last unique implication point
  * reduced conflict clause
  * minimized conflict clause

* Recent Advances

  * Winner 2017: Clause vivification during search [LuoLiXiaoMany´aL¨u’17]
  * Winner 2018: Chronological backtracking [NadelRyvchin’18]
  * Winner 2019: Multiple learnt clauses per conflict [KochemazovZaikinKondratievSemenov’19]

  * Key contributions to CDCL solvers: 
    * concept of conflict clauses (grasp) [Marques-SilvaSakallah’96] 
    * restart strategies [GomesSC’97,LubySZ’93] 
    * 2-watch pointers and VSIDS (zChaff) [MoskewiczMZZM’01] 
    * efficient implementation (Minisat) [EenS¨orensson’03] 
    * phase-saving (Rsat) [PipatsrisawatDarwiche’07] 
    * conflict-clause minimization [S¨orenssonBiere’09] 
    * SAT vs UNSAT [Oh’15]



## Preprocessing Techniques

* ![image-20200726160948668](D:\OneDrive\Pictures\Typora\image-20200726160948668.png)

* A clause is redundant with respect to a formula if adding it to the formula preserves satisfiability

  * For unsatisfiable formulas, all clauses can be added, including the empty clause $\bot$

* A clause is redundant with respect to a formula if removing it from the formula preserves unsatisfiability

  * For satisfiable formulas, all clauses can be removed.

* How to check redundancy in polynomial time?

* Ideally find redundant clauses in linear time

* Tautologies: A clause C is a tautology if its contains two complementary literals x and $\bar{x}$.

* Subsumption: Clause C subsumes clause D if and only if C ⊂ D

  * ![image-20200726191357660](D:\OneDrive\Pictures\Typora\image-20200726191357660.png)

  * ![image-20200726191419738](D:\OneDrive\Pictures\Typora\image-20200726191419738.png)

  * Implementation

    * Forward Subsumption

      * ```
        for each clause C in formula F do
        	if C is subsumed by a clause D in F \ C then
        		remove C from F
        ```

    * Backward Subsumption

      * ```
        for each clause C in formula F do
        	remove all clauses D in F that are subsumed by C
        	(pick a literal x in C
        	remove all clauses D in Fx that are subsumed by C)
        ```

* Variable Elimination

  * Resolution
    * ![image-20200726201857850](D:\OneDrive\Pictures\Typora\image-20200726201857850.png)
  * Variable elimination (VE) [DavisPutnam’60]
    * ![image-20200726202039916](D:\OneDrive\Pictures\Typora\image-20200726202039916.png)
    * Proof procedure
      * VE is a complete proof procedure. Applying VE until fixpoint results in either the empty formula (satisfiable) or empty clause (unsatisfiable)
  * ![image-20200726202706344](D:\OneDrive\Pictures\Typora\image-20200726202706344.png)
  * VE by substitution [EenBiere07]
    * Detect gates (or definitions) `x = GATE(a1, . . . , an)` in the formula and use them to reduce the number of added clauses
    * ![image-20200726202837200](D:\OneDrive\Pictures\Typora\image-20200726202837200.png)
    * ![image-20200726220544141](D:\OneDrive\Pictures\Typora\image-20200726220544141.png)

* Bounded Variable Addition

  * Given a CNF formula `F`, can we construct a (semi-)logically equivalent `F'` by introducing a new variable `x ∈/ VAR(F)` such that `|F'| < |F|`?
  * Reverse of Variable Elimination
  * ![image-20200727213426218](D:\OneDrive\Pictures\Typora\image-20200727213426218.png)
  * Factoring out subclauses
    * ![image-20200727213631261](D:\OneDrive\Pictures\Typora\image-20200727213631261.png)
    * Not compatible with VE, which would eliminate x immediately
    * ![image-20200727213700410](D:\OneDrive\Pictures\Typora\image-20200727213700410.png)
    * Example: AtMostOneZero
      * ![image-20200727213924705](D:\OneDrive\Pictures\Typora\image-20200727213924705.png)
      * ![image-20200727214050848](D:\OneDrive\Pictures\Typora\image-20200727214050848.png)
      * ![image-20200727214055712](D:\OneDrive\Pictures\Typora\image-20200727214055712.png)
      * ![image-20200727214100200](D:\OneDrive\Pictures\Typora\image-20200727214100200.png)

* Blocked Clause Elimination

  * A literal `x` in a clause `C` of a CNF `F` blocks `C` w.r.t. `F` if for every clause $D \in F_{\bar{x}}$, the resolvent $(C \backslash \{x\}) \cup (D \backslash \{\bar{x}\})$ obtained from resolving `C` and `D` on `I` is a tautology
  * With respect to a fixed CNF and its clauses we have: A clause is blocked if it contains a literal that blocks it.
  * ![image-20200727215714659](D:\OneDrive\Pictures\Typora\image-20200727215714659.png)
  * 

