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
  * Removal of an arbitrary blocked clause preserves satisfiability
  * BCE: While there is a blocked clause C in a CNF F, remove C from F.
    * ![image-20200728000112607](D:\OneDrive\Pictures\Typora\image-20200728000112607.png)
    * BCE is confluent, i.e., has a unique fixpoint
      * Blocked clauses stay blocked w.r.t. removal
    * BCE very effective on circuits [J¨arvisaloBiereHeule’10]
      * BCE converts the Tseitin encoding to Plaisted Greenbaum 
      * BCE simulates Pure literal elimination, Cone of influence, etc.
      * ![image-20200728000156989](D:\OneDrive\Pictures\Typora\image-20200728000156989.png)
    * Solution reconstruction
      * ![image-20200728000209660](D:\OneDrive\Pictures\Typora\image-20200728000209660.png)

* Hyper Binary Resolution

  * ![image-20200802170009201](D:\OneDrive\Pictures\Typora\image-20200802170009201.png)
  * combines multiple resolution steps into one 
  * uses one n-ary clauses and multiple binary clauses 
  * special case _hyper unary resolution_ where x = x
  * Hyper Binary Resolution (HBR): Apply the hyper binary resolution rule until fixpoint
    * ![image-20200802172744293](D:\OneDrive\Pictures\Typora\image-20200802172744293.png)
    * ![image-20200802172750785](D:\OneDrive\Pictures\Typora\image-20200802172750785.png)
  * Non-transitive Hyper Binary Resolution (NHBR)
    * ![image-20200802172802968](D:\OneDrive\Pictures\Typora\image-20200802172802968.png)
    * Space Complexity of NHBR: Quadratic
      * Question regarding complexity [Biere 2009] 
        * Are there formulas where the transitively reduced hyper binary resolution closure is quadratic in size w.r.t. to the size of the original? 
        * where size = #clauses or size = #literals or size = #variables
      * Yes!
        * ![image-20200802172840862](D:\OneDrive\Pictures\Typora\image-20200802172840862.png)

* Unhiding Redundancy

  * Redundant clauses:
    * Removal of C ∈ F preserves unsatisfiability of F
    * Assign all x ∈ C to false and check for a conflict in F \ {C}
  * Redundant literals:
    * Removal of x ∈ C preserves satisfiability of F
    * Assign all x 0 ∈ C \ {x} to false and check for a conflict in F
  * Redundancy elimination during pre- and in-processing
    * Distillation [JinSomenzi2005] 
    * ReVivAl [PietteHamadiSa¨ıs2008] 
    * Unhiding [HeuleJ¨arvisaloBiere2011]
  * Unhide: Binary implication graph (BIG)
    * unhide: use the binary clauses to detect redundant clauses and literals
    * ![image-20200802174010333](D:\OneDrive\Pictures\Typora\image-20200802174010333.png)
    * transitive reduction (TRD): remove shortcuts in the binary implication graph
      * ![image-20200802174029325](D:\OneDrive\Pictures\Typora\image-20200802174029325.png)
    * Hidden tautology elimination (HTE): HTE removes clauses that are subsumed by an implication in BIG
      * ![image-20200802174049605](D:\OneDrive\Pictures\Typora\image-20200802174049605.png)
      * ![image-20200802174055789](D:\OneDrive\Pictures\Typora\image-20200802174055789.png)
    * Hidden literal elimination (HLE):  HLE removes literal using the implication in BIG
      * ![image-20200802174152461](D:\OneDrive\Pictures\Typora\image-20200802174152461.png)

* Many pre- or in-processing techniques in SAT solvers:

  * (Self-)Subsumption 
  * Variable Elimination 
  * Blocked Clause Elimination 
  * Hyper Binary Resolution 
  * Bounded Variable Addition 
  * Equivalent Literal Substitution 
  * Failed Literal Elimination 
  * Autarky Reasoning
  * Propagation Redundant Clauses [CADE’17]



## Proof Systems & Proof Complexity

* Certifying Satisfiability and Unsatisfiability
  * Certifying satisfiability of a formula is easy
    * Just consider a satisfying assignment
    * We can easily check that the assignment is satisfying: Just check for every clause if it has a satisfied literal
  * Certifying unsatisfiability is not so easy [[N: easy for DNF]]
    * Checking whether every assignment falsifies the formula is costly. • More compact certificates of unsatisfiability are desirable
      * [[N: exponential explosion, quantum unsatisfiablity checking?]]
  * In general, a proof is a string that certifies the unsatisfiability of a formula
    * Proofs are efficiently (usually polynomial-time) checkable, but can be of exponential size with respect to a formula.
  * Resolution Proofs
    * A resolution proof is a sequence C1, . . . , Cm of clauses
    * Every clause is either contained in the formula or derived from two earlier clauses via the resolution rule
    * Cm is the empty clause (containing no literals), denoted by ⊥
    * There exists a resolution proof for every unsatisfiable formula.
    * ![image-20200802180925791](D:\OneDrive\Pictures\Typora\image-20200802180925791.png)
    * [[N: structural derivation as op semantics?]]
  * Clausal Proofs
    * Reduce the size of the proof by only storing added clauses
    * Checking whether additions preserve satisfiability should be efficient
    * Clauses whose addition preserves satisfiability are called redundant.
      * Idea: Allow only the addition of clauses that fulfill an efficiently checkable redundancy criterion
  * Reverse Unit Propagation
    * Unit propagation (UP) satisfies unit clauses by assigning their literal to true (until fixpoint or a conflict).
    * Let F be a formula, C a clause, and α the smallest assignment that falsifies C. C is implied by F via UP (denoted by $F \vdash_1 C$) if UP on $F \mid_\alpha$ results in a conflict.
    * ![image-20200802183218204](D:\OneDrive\Pictures\Typora\image-20200802183218204.png)
* Beyond Resolution
  * Pure Literal rule [Davis and Putnam 1960; Davis, Logemann and Loveland 1962]
    * ![image-20200802183312440](D:\OneDrive\Pictures\Typora\image-20200802183312440.png)
  * Extended Resolution(ER) [Tseitin 1966]
    * Can be considered the first interference-based proof system
    * Is very powerful: No known lower bounds
    * ![image-20200802183341315](D:\OneDrive\Pictures\Typora\image-20200802183341315.png)
  * Pigeon Hole Formulas
    * ![image-20200802185150002](D:\OneDrive\Pictures\Typora\image-20200802185150002.png)
  * Traditional Proofs vs. Interference-Based Proofs
    * In traditional proof systems, everything that is inferred, is logically implied by the premises.
    * Inference rules reason about the presence of facts.
    * Different approach: Allow not only implied conclusions
      * Require only that the addition of facts preserves satisfiability.
      * Reason also about the absence of facts
      * `=>` interference-based proof systems
  * Blocked Clauses [Kullmann 1999]
    * ![image-20200802185352286](D:\OneDrive\Pictures\Typora\image-20200802185352286.png)
    * Adding or removing a blocked clause preserves satisfiability
    * The Blocked Clause proof system (BC) combines the resolution rule with the addition of blocked clauses.
      * BC generalizes ER [Kullmann 1999]
      * ![image-20200802185414918](D:\OneDrive\Pictures\Typora\image-20200802185414918.png)
      * Blocked clause elimination used in preprocessing and inprocessing 
        * Simulates many circuit optimization techniques 
        * Removes redundant Pythagorean Triples
  * DRAT: An Interference-Based Proof System
    * RAT: resolution asymmetric tautology
    * DRAT allows the addition of RATs (defined below) to a formula
      * It can be efficiently checked if a clause is a RAT. 
      * RATs are not necessarily implied by the formula.
      * But RATs are redundant: their addition preserves satisfiability
    * DRAT also allows clause deletion
      * Initially introduced to check proofs more efficiently
      * Clause deletion may introduce clause addition options (interference)
    * ![image-20200802185540792](D:\OneDrive\Pictures\Typora\image-20200802185540792.png)
  * ![image-20200802185552304](D:\OneDrive\Pictures\Typora\image-20200802185552304.png)
* Propagation Redundancy
  * Strong proof systems allow addition of many redundant clauses.
  * All Redundant Clauses `=>` RAT `=>` Resolvents
  * Are stronger redundancy notions still efficiently checkable?
  * Propagation-redundant (PR) clauses
    * strictly generalize SPR clauses
  * Set-propagation-redundant (SPR) clauses
    * strictly generalize RATs
  * Literal-propagation-redundant (LPR) clauses
    * coincide with RAT
  * ![image-20200802191236649](D:\OneDrive\Pictures\Typora\image-20200802191236649.png)
  * The new proof systems can give short proofs of formulas that are considered hard.
  * We have short SPR and PR proofs for the well-known pigeon hole formulas (linear in the size of the input)
    * Pigeon hole formulas have only exponential-size resolution proofs.
    * If the addition of new variables via definitions is allowed, there are polynomial-size proofs
  * [[N: similar to inference tractability?]]
  * Satisfaction-Driven Clause Learning (SDCL) is a new solving paradigm that finds proofs in the PR proof system [HKB ’17]
  * Redundancy as an Implication
    * ![image-20200802191433722](D:\OneDrive\Pictures\Typora\image-20200802191433722.png)
  * Checking Redundancy Using Unit Propagation
    * ![image-20200802191452493](D:\OneDrive\Pictures\Typora\image-20200802191452493.png)
  * Hand-crafted PR Proofs of Pigeon Hole Formulas
    * The proofs consist only of binary and unit clauses. 
    * Only original variables appear in the proof. 
    * All proofs are linear in the size of the formula. 
    * ➥ The PR proofs are smaller than Cook’s ER proofs. 
    * All resolution proofs of these formulas are exponential in size.
* Satisfaction-Driven Clause Learning
  * Prune Less Satisfiable Branches by Adding redundant clauses
  * A clause prunes all branches that falsify the clause
  * ![image-20200802191859080](D:\OneDrive\Pictures\Typora\image-20200802191859080.png)
  * Determining whether a clause C is SET or PR w.r.t. a formula F is an NP-complete problem. 
  * How to find SET and PR clauses? Encode it in SAT!
  * Given a formula F and a clause C. Let α denote the smallest assignment that falsifies C. The positive reduct of F and α is a formula which is satisfiable if and only if C is SET w.r.t. F.
    * easy to solve
  * Key Idea: While solving a formula F, check whether the positive reduct of F and the current assignment α is satisfiable. In that case, prune the branch α.
* Autarkies
  * A non-empty assignment α is an autarky for formula F if every clause C ∈ F that is touched by α is also satisfied by α. 
  * A pure literal and a satisfying assignment are autarkies.
  * ![image-20200802192005303](D:\OneDrive\Pictures\Typora\image-20200802192005303.png)
  * ![image-20200802192014719](D:\OneDrive\Pictures\Typora\image-20200802192014719.png)
  * Conditional Autarky
    * ![image-20200802192032229](D:\OneDrive\Pictures\Typora\image-20200802192032229.png)
  * ![image-20200802192043981](D:\OneDrive\Pictures\Typora\image-20200802192043981.png)
  * ![image-20200802192052577](D:\OneDrive\Pictures\Typora\image-20200802192052577.png)
* Challenges
  * Theoretical
    * ![image-20200802192119831](D:\OneDrive\Pictures\Typora\image-20200802192119831.png)
  * Practical
    * ![image-20200802192126342](D:\OneDrive\Pictures\Typora\image-20200802192126342.png)



## Local Search & Lookahead Techniques

* DPLL (Davis Putnam Logemann Loveland [DP60,DLL62])
  * Recursive procedure that in each recursive call: 
    * Simplifies the formula (using unit propagation) 
    * Splits the formula into two sub-formulas 
      * Variable selection heuristics (which variable to split on) 
      * Direction heuristics (which sub-formula to explore first)
  * Look-ahead: DPLL with selection of (effective) decision variables by look-aheads on variables
    * Assign a variable to a truth value 
    * Simplify the formula 
    * Measure the reduction 
    * Learn if possible 
    * Backtrack
    * Properties
      * Very expensive 
      * Effective compared to cheap heuristics 
      * Detection of failed literals (and more) 
      * Strong on random k-SAT formulae 
      * Examples: march, OKsolver, kcnfs
    * Reduction Heuristics
      * Number of satisfied clauses 
      * Number of implied variables 
      * New (reduced, not satisfied) clauses
        * Smaller clauses more important
        * Weights based on occurring
    * ![image-20200807001500973](D:\OneDrive\Pictures\Typora\image-20200807001500973.png)
    * ![image-20200807001506511](D:\OneDrive\Pictures\Typora\image-20200807001506511.png)
* Look-ahead Learning
  * Look-ahead solvers do not perform global learning, in contrast to conflict-driven clause learning (CDCL) solvers
  * learn locally
    * Learn small (typically unit or binary) clauses that are valid for the current node and lower in the DPLL tree
    * Locally learnt clauses have to be removed during backtracking
  * failed literal
    * A literal `l` is called a failed literal if the look-ahead on `l = 1` results in a conflict
      * failed literal `l` is forced to false followed by unit propagation
      * if both `x` and ` x'` are failed literals, then backtrack
    * Failed literals can be generalized by double lookahead: assign two literals and learn a binary clause in case of a conflict
  * Hyper Binary Resolution [Bacchus 2002]
    * ![image-20200906211313882](D:\OneDrive\Pictures\Typora\image-20200906211313882.png)
  * St˚almarck’s Method
    * ![image-20200906211338874](D:\OneDrive\Pictures\Typora\image-20200906211338874.png)
* Autarky Reasoning
  * An autarky is a partial assignment that satisfies all clauses that are “touched” by the assignment
    * a pure literal is an autarky 
    * each satisfying assignment is an autarky 
    * the remaining formula is satisfiability equivalent to the original formula
  * An 1-autarky is a partial assignment that satisfies all touched clauses except one
  * Lookahead techniques can solve 2-SAT formulae in polynomial time. Each lookahead on l results:
    * in an autarky: forcing l to be true
    * in a conflict: forcing l to be false
* Tree-based Look-ahead
  * ![image-20200906211620094](D:\OneDrive\Pictures\Typora\image-20200906211620094.png)

## Maximum Satisfiability

* Software Package Upgradeability Problem
  * dependencies
    * ![image-20200906231525238](D:\OneDrive\Pictures\Typora\image-20200906231525238.png)
  * conflicts
    * ![image-20200906231532197](D:\OneDrive\Pictures\Typora\image-20200906231532197.png)
  * installing all packages
    * ![image-20200906231541204](D:\OneDrive\Pictures\Typora\image-20200906231541204.png)
  * ![image-20200906231722823](D:\OneDrive\Pictures\Typora\image-20200906231722823.png)
  * ![image-20200906231836789](D:\OneDrive\Pictures\Typora\image-20200906231836789.png)
* Maximum Satisfiability
  * Maximum Satisfiability (MaxSAT) 
    * Clauses in the formula are either soft or hard 
    * Hard clauses: must be satisfied (e.g. conflicts, dependencies)
    * Soft clauses: desirable to be satisfied (e.g. package installation)
  * Goal: Maximize number of satisfied soft clauses
  * ![image-20200906232028525](D:\OneDrive\Pictures\Typora\image-20200906232028525.png)
  * Upper bound search on the number of unsatisfied soft clauses
    *  ![image-20200906232041341](D:\OneDrive\Pictures\Typora\image-20200906232041341.png)
    * ![image-20200906232046397](D:\OneDrive\Pictures\Typora\image-20200906232046397.png)
    * ![image-20200906232051407](D:\OneDrive\Pictures\Typora\image-20200906232051407.png)
    * ![image-20200906232103989](D:\OneDrive\Pictures\Typora\image-20200906232103989.png)
  * Linear Search Algorithms SAT-UNSAT
    * ![image-20200906232125237](D:\OneDrive\Pictures\Typora\image-20200906232125237.png)
    * ![image-20200906232223381](D:\OneDrive\Pictures\Typora\image-20200906232223381.png)
    * ![image-20200906232234268](D:\OneDrive\Pictures\Typora\image-20200906232234268.png)
  * Lower bound search on the number of unsatisfied soft clauses
    * ![image-20200906232154686](D:\OneDrive\Pictures\Typora\image-20200906232154686.png)
  * Unsatisfiability-based Algorithms
    * ![image-20200906232258095](D:\OneDrive\Pictures\Typora\image-20200906232258095.png)
    * ![image-20200906232305293](D:\OneDrive\Pictures\Typora\image-20200906232305293.png)
    * ![image-20200906232343340](D:\OneDrive\Pictures\Typora\image-20200906232343340.png)
    * ![image-20200906232350805](D:\OneDrive\Pictures\Typora\image-20200906232350805.png)
    * Challenges
      * Unsatisfiable cores found by the SAT solver are not minimal
        * ![image-20200906232420343](D:\OneDrive\Pictures\Typora\image-20200906232420343.png)
      * Minimizing unsatisfiable cores is computationally hard
  * Partitioning in MaxSAT:
    * Use the structure of the problem to guide the search
    * ![image-20200906232433373](D:\OneDrive\Pictures\Typora\image-20200906232433373.png)
    * ![image-20200906232445943](D:\OneDrive\Pictures\Typora\image-20200906232445943.png)
    * How to Partition Soft Clauses?
      * Graph representation of the MaxSAT formula
        * Vertices: Variables 
        * Edges: Between variables that appear in the same clause
      * There are many ways to represent MaxSAT as a graph:
        * Clause-Variable Incidence Graph (CVIG) 
        * Variable Incidence Graph (VIG) 
        * Hypergraph 
        * Resolution Graph
  * Resolution-based Graphs
    * ![image-20200906232541497](D:\OneDrive\Pictures\Typora\image-20200906232541497.png)
    * Vertices: Represent each clause in the graph 
    * Edges: There is an edge between two vertices if you can apply the resolution rule between the corresponding clauses
    * ![image-20200906232559822](D:\OneDrive\Pictures\Typora\image-20200906232559822.png)
  * MaxSAT solvers
    * SAT4J / RC2 / MaxHS / Open-WBO
  * Standard Solver Input Format: DIMACS WCNF
    * ![image-20200906232636140](D:\OneDrive\Pictures\Typora\image-20200906232636140.png)



## Reasoning with Quantified Boolean Formulas

* Quantified Boolean formulas (QBF): formulas of propositional logic + quantifiers
* SAT vs. QSAT
  * NP-complete vs. PSPACE-complete
  * ![image-20200907203704924](D:\OneDrive\Pictures\Typora\image-20200907203704924.png)
  * ![image-20200907203906967](D:\OneDrive\Pictures\Typora\image-20200907203906967.png)
  * ![image-20200907214030197](D:\OneDrive\Pictures\Typora\image-20200907214030197.png)
  * QSAT is the prototypical problem for PSPACE.
  * QBFs are suitable as host language for the encoding of many application problems like
    * verification
    * AI
    * knowledge representation
    * game solving
  * QBF allow more succinct encodings then SAT
    * ![image-20200907214357171](D:\OneDrive\Pictures\Typora\image-20200907214357171.png)
* Language of QBF
  * ![image-20200907215445754](D:\OneDrive\Pictures\Typora\image-20200907215445754.png)
  * ![image-20200907215451250](D:\OneDrive\Pictures\Typora\image-20200907215451250.png)
  * ![image-20200907215509426](D:\OneDrive\Pictures\Typora\image-20200907215509426.png)
* Prenex Conjunctive Normal Form (PCNF)
  * ![image-20200907215537137](D:\OneDrive\Pictures\Typora\image-20200907215537137.png)
  * ![image-20200907215559588](D:\OneDrive\Pictures\Typora\image-20200907215559588.png)
* Semantics of QBFs
  * ![image-20200907215655841](D:\OneDrive\Pictures\Typora\image-20200907215655841.png)
  * ![image-20200907215708106](D:\OneDrive\Pictures\Typora\image-20200907215708106.png)
  * ![image-20200907215713618](D:\OneDrive\Pictures\Typora\image-20200907215713618.png)
  * ![image-20200907215719506](D:\OneDrive\Pictures\Typora\image-20200907215719506.png)
* Unit Clause
  * ![image-20200907215727182](D:\OneDrive\Pictures\Typora\image-20200907215727182.png)
  * Unit Literal Elimination
    * ![image-20200907215748657](D:\OneDrive\Pictures\Typora\image-20200907215748657.png)
* Pure Literals
  * ![image-20200907215800738](D:\OneDrive\Pictures\Typora\image-20200907215800738.png)
  * Pure Literal Elimination
    * ![image-20200907215812619](D:\OneDrive\Pictures\Typora\image-20200907215812619.png)
* [[R: Check CS267A WMC]]
* Universal Reduction (UR)
  * ![image-20200907215837146](D:\OneDrive\Pictures\Typora\image-20200907215837146.png)
  * ![image-20200907215843855](D:\OneDrive\Pictures\Typora\image-20200907215843855.png)
* Q-Resolution: propositional resolution + universal reduction.
  * ![image-20200907215915610](D:\OneDrive\Pictures\Typora\image-20200907215915610.png)
  * ![image-20200907215923482](D:\OneDrive\Pictures\Typora\image-20200907215923482.png)
* Quantified Blocked Clause
  * ![image-20200907215940955](D:\OneDrive\Pictures\Typora\image-20200907215940955.png)



## Verifying Automated Reasoning Results

* Certifying Satisfiability and Unsatisfiability
  * ![image-20200907220151641](D:\OneDrive\Pictures\Typora\image-20200907220151641.png)
* What Is a Proof in SAT?
  * ![image-20200907220203523](D:\OneDrive\Pictures\Typora\image-20200907220203523.png)
* Motivation for Validating Proofs of Unsatisfiability
  * ![image-20200907220215799](D:\OneDrive\Pictures\Typora\image-20200907220215799.png)
  * Chip makers use SAT to check the correctness of their designs. Equivalence checking involves comparing a specification with an implementation or an optimized with a non-optimized circuit
* ![image-20200907222821541](D:\OneDrive\Pictures\Typora\image-20200907222821541.png)
* ![image-20200907222829279](D:\OneDrive\Pictures\Typora\image-20200907222829279.png)
* ![image-20200907222839072](D:\OneDrive\Pictures\Typora\image-20200907222839072.png)
* ![image-20200907222854548](D:\OneDrive\Pictures\Typora\image-20200907222854548.png)
* ![image-20200907222902776](D:\OneDrive\Pictures\Typora\image-20200907222902776.png)
* ![image-20200907222907744](D:\OneDrive\Pictures\Typora\image-20200907222907744.png)
* ![image-20200907222916915](D:\OneDrive\Pictures\Typora\image-20200907222916915.png)
* DRAT (Deletion Resolution Asymmetric Tautology)
  * ![image-20200907222930824](D:\OneDrive\Pictures\Typora\image-20200907222930824.png)
* ![image-20200907222940976](D:\OneDrive\Pictures\Typora\image-20200907222940976.png)
* ![image-20200907222955408](D:\OneDrive\Pictures\Typora\image-20200907222955408.png)
* ![image-20200907222959992](D:\OneDrive\Pictures\Typora\image-20200907222959992.png)
* ![image-20200907223005542](D:\OneDrive\Pictures\Typora\image-20200907223005542.png)
* ![image-20200907223013009](D:\OneDrive\Pictures\Typora\image-20200907223013009.png)
* ![image-20200907223017284](D:\OneDrive\Pictures\Typora\image-20200907223017284.png)
* ![image-20200907223021680](D:\OneDrive\Pictures\Typora\image-20200907223021680.png)
* Certified Checking: Tool Chain
  * ![image-20200907223038455](D:\OneDrive\Pictures\Typora\image-20200907223038455.png)
  * ![image-20200907223045171](D:\OneDrive\Pictures\Typora\image-20200907223045171.png)
  * ![image-20200907223049672](D:\OneDrive\Pictures\Typora\image-20200907223049672.png)
  * ![image-20200907223054016](D:\OneDrive\Pictures\Typora\image-20200907223054016.png)
* ![image-20200907223118376](D:\OneDrive\Pictures\Typora\image-20200907223118376.png)



