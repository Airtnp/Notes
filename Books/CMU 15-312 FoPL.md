# Foundations of Programming Languages

[fall2019](https://www.cs.cmu.edu/~rwh/courses/ppl/index.html) recitations/supplements + [fall2004](https://www.cs.cmu.edu/~fp/courses/15312-f04/)



## Church's $\lambda$ Calculus

* $\lambda$-terms
  * variable $x$
  * application $ap(M_1, M_2)$
  * abstraction $\lambda(x.M)$
* everything definable as certain functions
* self-referential in application & abstraction $\to$ inductive definition!
  * collections of rules for 1+ judgements/assertations
  * $M tm$: $M$ is a $\lambda$-term
    * ![image-20191209223428877](D:\OneDrive\Pictures\Typora\image-20191209223428877.png)
* binding & scope
  * free vs. bound
    * ![image-20191209224139135](D:\OneDrive\Pictures\Typora\image-20191209224139135.png)
* substitution
  * `subst(M, x, N, P)`: $P$ is the result of substituting $M$ for free $x$'s in $N$ ($[M/x]N = P$)
  * ![image-20191209224258878](D:\OneDrive\Pictures\Typora\image-20191209224258878.png)
  * ![image-20191209224305607](D:\OneDrive\Pictures\Typora\image-20191209224305607.png)
* $\alpha$-equivalence ($M \equiv_{\alpha} M'$)
  * ![image-20191209230352495](D:\OneDrive\Pictures\Typora\image-20191209230352495.png)
  * $[M]_{\alpha}$: equivalent class of $M$ under $\alpha$-equivalence
  * ![image-20191209230932919](D:\OneDrive\Pictures\Typora\image-20191209230932919.png)
  * structural induction $\to$ $\alpha$-equivalence classes of terms
    * predicate $\mathcal{P}(M)$
    * ![image-20191209231753118](D:\OneDrive\Pictures\Typora\image-20191209231753118.png)
* $\beta$-equivalence: calculation
  * $M \equiv_\beta M'$
  * equivalence relation: reflexive, symmetric, transitive
  * congruence: equals may be replaced by equals to get equals (??)
  * encodes computation by simplification of the application of an abstraction to an argument
  * ![image-20191209232412694](D:\OneDrive\Pictures\Typora\image-20191209232412694.png)
  * SKI
    * ![image-20191209232430929](D:\OneDrive\Pictures\Typora\image-20191209232430929.png)
    * $I$: identity
    * $K$: konstant functions
    * $S$: distributor (sends argument to both $x$ & $y$)
  * $M \succ_\beta M'$ (reduction)
* Church's Law
  * ![image-20191209235339916](D:\OneDrive\Pictures\Typora\image-20191209235339916.png)
  * $case(0, M_0, M_1) \equiv_\beta M_0$
  * $case(succ(M), M_0, M_1) \equiv_\beta M_1 M$
  * $add = λx.λy. case(y, x, λz. succ(add x z))$
  * $Y = λ f. (λx. f (x\ x)) (λx. f(x\ x))$
* Normalization
  * $\beta$-reduction $(λx. M) N \to [N/x]M$
  * $\beta$-normal form: cannot reduce further
  * Church-Rosser Theorem: a term has at most one $\beta$-normal form
  * head reduction $M \mapsto_\beta M'$: at outermost level of a term
    * ![image-20191210000250703](D:\OneDrive\Pictures\Typora\image-20191210000250703.png)
  * $M \text{ norm } N$
    * ![image-20191210000327207](D:\OneDrive\Pictures\Typora\image-20191210000327207.png)
  * ![image-20191210000348334](D:\OneDrive\Pictures\Typora\image-20191210000348334.png)

* relative size
  * ![image-20191210000641765](D:\OneDrive\Pictures\Typora\image-20191210000641765.png)
* hypothetical judgement
  * $J_1, \cdots, J_n \vdash J$: $J$ follows from assumptions
  * environment $\eta: x_i \Downarrow v_i$
  * ![image-20191210105839377](D:\OneDrive\Pictures\Typora\image-20191210105839377.png)





## De Bruijn Representation

* nameless representation
* $λx.λy.x \Rightarrow λ.λ.2$
* ![image-20191210111510737](D:\OneDrive\Pictures\Typora\image-20191210111510737.png)
* substitution
  * ![image-20191210110413560](D:\OneDrive\Pictures\Typora\image-20191210110413560.png)
  * ![image-20191210110419576](D:\OneDrive\Pictures\Typora\image-20191210110419576.png)
  * ![image-20191210111218512](D:\OneDrive\Pictures\Typora\image-20191210111218512.png)
* ![image-20191210111300200](D:\OneDrive\Pictures\Typora\image-20191210111300200.png)







## Type Safety

* ![image-20191210111604984](D:\OneDrive\Pictures\Typora\image-20191210111604984.png)
* ![image-20191210111612960](D:\OneDrive\Pictures\Typora\image-20191210111612960.png)
* ![image-20191210112036633](D:\OneDrive\Pictures\Typora\image-20191210112036633.png)
* small-step semantics (structural operational semantics)
  * step-by-step
  * ![image-20191210112522376](D:\OneDrive\Pictures\Typora\image-20191210112522376.png)
* call-by-value vs call-by-name
  * ![image-20191210112918400](D:\OneDrive\Pictures\Typora\image-20191210112918400.png)
  * ![image-20191210112926135](D:\OneDrive\Pictures\Typora\image-20191210112926135.png)
* errors
  * ![image-20191210113211273](D:\OneDrive\Pictures\Typora\image-20191210113211273.png)
* unit, product, sum types
* environment based semantics
  * $\eta$: environment
  * $<<\eta; fn>>$: closure
  * $\eta : \Gamma$: bindings of variables to values in $\eta$ match the context $\Gamma$



## Abstract Machine

* ![image-20191210122113616](D:\OneDrive\Pictures\Typora\image-20191210122113616.png)
* transition judgement $s \mapsto_c s'$
* initial state $• > e$, final state $• < v$
* $k > e \mapsto_c \cdots \mapsto_c k < v$
* ![image-20191210122535655](D:\OneDrive\Pictures\Typora\image-20191210122535655.png)
* ![image-20191211202800755](D:\OneDrive\Pictures\Typora\image-20191211202800755.png)
* ![image-20191211202816219](D:\OneDrive\Pictures\Typora\image-20191211202816219.png)



## Continuations

* new form of state $k \ll fail$
  * propagating an exception upwards in the control stack $k$, looking for a handler/stopping at the empty stack
  * ![image-20191211204324155](D:\OneDrive\Pictures\Typora\image-20191211204324155.png)
  * ![image-20191211204328499](D:\OneDrive\Pictures\Typora\image-20191211204328499.png)
  * ![image-20191211204333483](D:\OneDrive\Pictures\Typora\image-20191211204333483.png)
* `callcc x => e`: capture the stack (= continuation) $k$ in effect at the time the `callcc` is executed & substitutes `cont(k)` for `x` in `e`
* `throw e1 to e2`: time travel. transfer control to $k$ by throwing a value $v$ to $k$ with `throw v to cont(k)`
* ![image-20191211234330332](D:\OneDrive\Pictures\Typora\image-20191211234330332.png)
* ![image-20191211234335677](D:\OneDrive\Pictures\Typora\image-20191211234335677.png)
* ![image-20191211234344607](D:\OneDrive\Pictures\Typora\image-20191211234344607.png)
* ![image-20191211234358807](D:\OneDrive\Pictures\Typora\image-20191211234358807.png)
  * the type $\sigma$: don't appear in the conclusion
* callcc & 排中律 & pierce law



## Polymorphism

* intrinsic form: each function having a unique type
  * instantiation $e[\tau]$
  * $\lambda$-abstraction
    * ![image-20191213000848051](D:\OneDrive\Pictures\Typora\image-20191213000848051.png)
  * 
* 
* ![image-20191213171713282](D:\OneDrive\Pictures\Typora\image-20191213171713282.png)
* ![image-20191213171724340](D:\OneDrive\Pictures\Typora\image-20191213171724340.png)
* ![image-20191213171753204](D:\OneDrive\Pictures\Typora\image-20191213171753204.png)
* ![image-20191213171759611](D:\OneDrive\Pictures\Typora\image-20191213171759611.png)
* extrinsic form: expression to have multiple types (principal type that subsumes all other types)
  * ![image-20191213171845828](D:\OneDrive\Pictures\Typora\image-20191213171845828.png)



## Data abstraction

* ```ocaml
  signature QUEUE = sig
      type q
      val empty : q
      val enq : int * q -> q
      val deq : q -> q * int (* may raise Empty *)
  end;
  
  structure Q :> QUEUE = struct
      type q = int list
      val empty = nil
      fun enq (x,l) = x::l
      fun deq l = deq’ (rev l)
      and deq’ (y::k) = (rev k, y)
      	| deq’ (nil) = raise Empty
  end;
  ```

* existential types $\exists t.\tau$

  * E.g. $\exists q.q \times (int \times q \to q) \times (q \to q \times int)$
  * $pack(\sigma, e)$: implement
  * ![image-20191213230945685](D:\OneDrive\Pictures\Typora\image-20191213230945685.png)
  * ![image-20191213230949861](D:\OneDrive\Pictures\Typora\image-20191213230949861.png)



## Recursive types

* $Nat \simeq 1 + Nat$ or $Nat = \mu t. 1 + t$
* $\tau \simeq \sigma$: isomorphic
* ![image-20191213231657782](D:\OneDrive\Pictures\Typora\image-20191213231657782.png)



## Subtyping

* subtyping principle: If $\tau \le \sigma$ then wherever a value of type $\sigma$ is required, we can se a value of type $\tau$ instead
* Subset Interpretation: If $\tau \le \sigma$ then every value of types $\tau$ is also a value of type $\sigma$
* Coercion Interpretation: If $\tau \le \sigma$ then every value of type $\tau$ can be converted (coerced) to a value of type $\sigma$ in a unique way
* subsume, reflective, transitive
* contravariance: sink, function return value
* covariance: source, function argument
* invariant: mutable reference, array
  * ![image-20191214000814571](D:\OneDrive\Pictures\Typora\image-20191214000814571.png)
  * both position in the constructor



## Bidirectional Type Checking

* [nlab](https://ncatlab.org/nlab/show/bidirectional+typechecking)
* [zhihu](https://www.zhihu.com/question/352507775)

* type judgement process
  * Assume each input constituent of the conclusion is known
  * Show that each input constituent of the premise is known, and each output constituent of the premise is still free (unknown).
  * Assume that each output constituent of the premise is known
  * Show that each output constituent of the conclusion is known
* input $+$, output $-$
* $e$ synthesizes $\tau$: $\Gamma^+ \vdash e^+ \uparrow \tau^-$
* $e$ checks against $\tau$: $\Gamma^+ \vdash e^+ \downarrow \tau^+$
* $\tau$ is a subtype of $\sigma$: $\tau^+ \sqsubseteq \sigma^+$
* constructor: propagate type information downward into term
  * $e^+ \downarrow \tau^+$
* destructor: propagating information upward
* ![image-20191214214017239](D:\OneDrive\Pictures\Typora\image-20191214214017239.png)
* ![image-20191214214026326](D:\OneDrive\Pictures\Typora\image-20191214214026326.png)





## Side effects

* Storing Type $\Lambda ::= \cdot | \Lambda, l:r$, Stores $M ::= \cdot | M, l = v$
* ![image-20191214215002988](D:\OneDrive\Pictures\Typora\image-20191214215002988.png)
* Monadic expressions: $\Gamma \vdash m \div \tau$
* ![image-20191214215106901](D:\OneDrive\Pictures\Typora\image-20191214215106901.png)
* ![image-20191214215435124](D:\OneDrive\Pictures\Typora\image-20191214215435124.png)
* Garbage collector
  * tracing collection
    * ![image-20191214222024449](D:\OneDrive\Pictures\Typora\image-20191214222024449.png)
  * copying collection
  * mark-n-sweep collection
  * reference counting





## Records & Variants

* labelled records
  * ![image-20191214220248034](D:\OneDrive\Pictures\Typora\image-20191214220248034.png)
* depth + width + permutation subtyping (row polymorphism?)
  * ![image-20191214220413290](D:\OneDrive\Pictures\Typora\image-20191214220413290.png)
* variant
  * ![image-20191214220422386](D:\OneDrive\Pictures\Typora\image-20191214220422386.png)
  * ![image-20191214220452690](D:\OneDrive\Pictures\Typora\image-20191214220452690.png)
* Note two width subtyping is reversed (variant vs record)
* [row-polymorphism-isn't-subtyping](https://brianmckenna.org/blog/row_polymorphism_isnt_subtyping)
* [row-polymorphism-vs-subtyping](https://cs.stackexchange.com/questions/53998/what-are-the-major-differences-between-row-polymorphism-and-subtyping)
  * propagating $\rho$ information



## The Curry-Howard Isomorphism

* introduction rule
  * ![image-20191214222756087](D:\OneDrive\Pictures\Typora\image-20191214222756087.png)
* elimination rule
  * ![image-20191214222804464](D:\OneDrive\Pictures\Typora\image-20191214222804464.png)
* ![image-20191214222836568](D:\OneDrive\Pictures\Typora\image-20191214222836568.png)
* implication
  * introduction rule ![image-20191214223117463](D:\OneDrive\Pictures\Typora\image-20191214223117463.png)
  * elimination rule ![image-20191214223156019](D:\OneDrive\Pictures\Typora\image-20191214223156019.png)
* truth $\top$: no elimination rule
* falsehood $\bot$: no introduction rule
* ![image-20191214223353208](D:\OneDrive\Pictures\Typora\image-20191214223353208.png)
* $A \vee \neg A \ true$ is not provable for an arbitrary $A$
* intuitionistic logic: if allow arbitrary instances of the axiom schema of excluded middle (XM)
  * ![image-20191214223514023](D:\OneDrive\Pictures\Typora\image-20191214223514023.png)
* proof term $M$
  * $M : A$,  $M$ is a proof of $A$
  * ![image-20191214224104302](D:\OneDrive\Pictures\Typora\image-20191214224104302.png)
* CH-iso
  * propositions-as-types: Propositions of logic corresponds to types of a programming language
  * proofs-as-programs: proofs in logic corresponds to expressions in a programming language
  * proof-checking-as-type-checking: verifying the correctness of a proof corresponds to type-checking its corresponding expressions
* ![image-20191214224410919](C:\Users\xiaol\OneDrive\ASemesters\FA2019\CS131\image-20191214224410919.png)
* ![image-20191214224430086](D:\OneDrive\Pictures\Typora\image-20191214224430086.png)
* ![image-20191214224449390](D:\OneDrive\Pictures\Typora\image-20191214224449390.png)
* computation: proof reduction by imposing a particular strategy of reduction
* local soundness: elimination rules are not too strong
  * ![image-20191214224912709](D:\OneDrive\Pictures\Typora\image-20191214224912709.png)
* local completeness: elimination rules are strong enough to recover all the information that has been put into a proposition
  * ![image-20191214224849894](D:\OneDrive\Pictures\Typora\image-20191214224849894.png)



## Program Equivalence

* observational equivalence: behavior identical
* ![image-20191214225436278](D:\OneDrive\Pictures\Typora\image-20191214225436278.png)
* sequential process expressions
  * $P ::= A | \alpha_i P_i  + \cdots$
  * $\alpha$: observable actions, consist either of names $a$ (eventually denoting an input action) & co-name $\bar a$ (eventually denoting an output action)
  * process identifier $A =^{def} P_A$
* strong simulation
  * $S$: relation on the states of a process or between several processes
  * ![image-20191214225829636](D:\OneDrive\Pictures\Typora\image-20191214225829636.png)
* strong bisimulation



## Concurrent Process

* process composition $P_1 | P_2$
* synchronization: internal action/silent action $\tau$
* name hiding (abstraction) $\text{new } b. P$ (locally bound name)
  * $\alpha$-conversion
* ![image-20191214230312980](D:\OneDrive\Pictures\Typora\image-20191214230312980.png)
* ![image-20191214230322324](D:\OneDrive\Pictures\Typora\image-20191214230322324.png)
* ![image-20191214230503228](D:\OneDrive\Pictures\Typora\image-20191214230503228.png)
  * category??
* weak simulation
  * ![image-20191214230528685](D:\OneDrive\Pictures\Typora\image-20191214230528685.png)
  * ![image-20191214230540500](D:\OneDrive\Pictures\Typora\image-20191214230540500.png)
* $\pi$-calculus
* ![image-20191214230628388](D:\OneDrive\Pictures\Typora\image-20191214230628388.png)
* ![image-20191214230846452](D:\OneDrive\Pictures\Typora\image-20191214230846452.png)
* channels
  * ![image-20191214231154716](D:\OneDrive\Pictures\Typora\image-20191214231154716.png)
  * ![image-20191214231207860](D:\OneDrive\Pictures\Typora\image-20191214231207860.png)
  * ![image-20191214231214491](D:\OneDrive\Pictures\Typora\image-20191214231214491.png)
  * ![image-20191214231221243](D:\OneDrive\Pictures\Typora\image-20191214231221243.png)
  * ![image-20191214231240651](D:\OneDrive\Pictures\Typora\image-20191214231240651.png)
  * ![image-20191214231247044](D:\OneDrive\Pictures\Typora\image-20191214231247044.png)



## Dependent Types

* 





## Inference, Induction

* Judgement: an assertion about a property of an ast / relationship between ast's
  * ![image-20191214231432826](D:\OneDrive\Pictures\Typora\image-20191214231432826.png)
* Inference rules
  * premises: a set of judgement above
  * conclusion: a single judgement below
  * ![image-20191214231510194](D:\OneDrive\Pictures\Typora\image-20191214231510194.png)
  * axiom: no premises



## Binding, Semantics & Safety

* binder: $x.e$
* abstract binding tree (abt)
* unicity of typing theorem
  * $\forall \Gamma, e$, at most one $\tau$ that $\Gamma \vdash e : \tau$
* ![image-20191214232236403](D:\OneDrive\Pictures\Typora\image-20191214232236403.png)
* statics: system of rules that govern the meaning of the language at expression-level before the expression is evaluated
* dynamics: evaluation, transitions until values
* ![image-20191214233154824](D:\OneDrive\Pictures\Typora\image-20191214233154824.png)
* type safety: progress & preservation
  * ![image-20191214233210896](D:\OneDrive\Pictures\Typora\image-20191214233210896.png)



## Godel's System T

* ![image-20191214233346477](D:\OneDrive\Pictures\Typora\image-20191214233346477.png)
* ![image-20191215123536462](D:\OneDrive\Pictures\Typora\image-20191215123536462.png)
  * ![image-20191215124209004](D:\OneDrive\Pictures\Typora\image-20191215124209004.png)
* Every well-typed expression $e$ in System T terminates $\to$ not Turing-complete
  * $\cdot \vdash e : \tau \Rightarrow e \longmapsto^* v$
  * definable function, iff exists an expression $e: \text{nat} \to \text{nat}$ in T that $\forall n \in \mathbb{N}, e(\bar n) \mapsto^* \overline{f(n)}$
    * encode every expression in T as natural numbers  $\lceil e \rceil$ as numeral expressions in T
    * curry products in the domain of mathematical functions
  * function `eval`: $\mathbb{N}^2 \to \mathbb{N}$
    * $eval(\lceil e \rceil, m) = n$ iff $e(\bar m) \mapsto^* \bar n$
  * ![image-20191215151858213](D:\OneDrive\Pictures\Typora\image-20191215151858213.png)
* Ackermann
  * ![image-20191215151943836](D:\OneDrive\Pictures\Typora\image-20191215151943836.png)
  * ![image-20191215152022851](D:\OneDrive\Pictures\Typora\image-20191215152022851.png)





## Products, Sums & Generic Programming

* products: $\tau_1 \times \tau_2$
* ![image-20191215154110898](D:\OneDrive\Pictures\Typora\image-20191215154110898.png)
* sums: $\tau_1 + \tau_2$
* ![image-20191215154151697](D:\OneDrive\Pictures\Typora\image-20191215154151697.png)
* ![image-20191215154202633](D:\OneDrive\Pictures\Typora\image-20191215154202633.png)
* recursor
  * ![image-20191215154438841](D:\OneDrive\Pictures\Typora\image-20191215154438841.png)
* dynamic dispatch
  * dispatch matrix: ![image-20191215154708224](D:\OneDrive\Pictures\Typora\image-20191215154708224.png)
    * type: ![image-20191215154728296](D:\OneDrive\Pictures\Typora\image-20191215154728296.png)
  * class-based view: ![image-20191215154805840](D:\OneDrive\Pictures\Typora\image-20191215154805840.png)
  * method-based view: ![image-20191215154817065](D:\OneDrive\Pictures\Typora\image-20191215154817065.png)
  * ![image-20191215155227705](D:\OneDrive\Pictures\Typora\image-20191215155227705.png)
  * OOP vs. ADT
* generic programming
  * polynomial type operator / abstractor $t.\tau$ $t \text{ type }    \vdash \tau \text{ type }$
  * ![image-20191215165132754](D:\OneDrive\Pictures\Typora\image-20191215165132754.png)



## Inductive & Coinductive Types

* inductive type $\mu(t.\tau)$: the least type contains $t.\tau$

  * ![image-20191215165057385](D:\OneDrive\Pictures\Typora\image-20191215165057385.png)
  * ![image-20191215165103056](D:\OneDrive\Pictures\Typora\image-20191215165103056.png)
  * ![image-20191215165109986](D:\OneDrive\Pictures\Typora\image-20191215165109986.png)
  * ![image-20191215220926913](D:\OneDrive\Pictures\Typora\image-20191215220926913.png)
  * ![image-20191216001031849](D:\OneDrive\Pictures\Typora\image-20191216001031849.png)
  * ![image-20191215235920881](D:\OneDrive\Pictures\Typora\image-20191215235920881.png)

* Coinductive types: $\upsilon(t.\tau)$

  * ![image-20191216000434626](D:\OneDrive\Pictures\Typora\image-20191216000434626.png)
  * ![image-20191216000756571](D:\OneDrive\Pictures\Typora\image-20191216000756571.png)
  * ![image-20191216000802378](D:\OneDrive\Pictures\Typora\image-20191216000802378.png)
  * ![image-20191216000857116](D:\OneDrive\Pictures\Typora\image-20191216000857116.png)
  * ![image-20191216000904322](D:\OneDrive\Pictures\Typora\image-20191216000904322.png)

* [PFPL-notes](https://scturtle.me/posts/2015-12-22-pfpl.html)

  * ![image-20191216001334161](D:\OneDrive\Pictures\Typora\image-20191216001334161.png)
  * ![image-20191216001339020](D:\OneDrive\Pictures\Typora\image-20191216001339020.png)

* [inductive-vs.-coinductive](https://www.zhihu.com/question/60184579)

* [coinduction](https://www.zhihu.com/question/28159220)

* duality

  * ![image-20191216001823377](D:\OneDrive\Pictures\Typora\image-20191216001823377.png)

* `conat`

  * ![image-20191216001917625](D:\OneDrive\Pictures\Typora\image-20191216001917625.png)

* System F (parametric polymorphism)

  * ![image-20191216001959186](D:\OneDrive\Pictures\Typora\image-20191216001959186.png)
  * type context $\Delta$. judgement $\Delta \vdash \tau$ type, $\Delta, \Gamma \vdash e : \tau$
  * unit type: ![image-20191216002221848](D:\OneDrive\Pictures\Typora\image-20191216002221848.png)
  * void type: ![image-20191216002231216](D:\OneDrive\Pictures\Typora\image-20191216002231216.png)
  * `+` type: ![image-20191216002315856](D:\OneDrive\Pictures\Typora\image-20191216002315856.png)
  * `x` type: ![image-20191216002333072](D:\OneDrive\Pictures\Typora\image-20191216002333072.png)
  * ![image-20191216003852046](D:\OneDrive\Pictures\Typora\image-20191216003852046.png)
  * primitive datatypes are definable within System F

* [System F](https://www.cs.rice.edu/~javaplt/411/11-fall/Readings/IntroToSystemF.pdf)

  * ![image-20191216004458370](D:\OneDrive\Pictures\Typora\image-20191216004458370.png)
  * ![image-20191216004505053](D:\OneDrive\Pictures\Typora\image-20191216004505053.png)
  * ![image-20191216004608957](D:\OneDrive\Pictures\Typora\image-20191216004608957.png)
  * ![image-20191216004624495](D:\OneDrive\Pictures\Typora\image-20191216004624495.png)

* Church Encoding

  * ![image-20191216183835048](D:\OneDrive\Pictures\Typora\image-20191216183835048.png)
  * ![image-20191216192524129](D:\OneDrive\Pictures\Typora\image-20191216192524129.png)
  * ![image-20191216192529001](D:\OneDrive\Pictures\Typora\image-20191216192529001.png)

* Existential Types in System FE

  * ![image-20191216192549976](D:\OneDrive\Pictures\Typora\image-20191216192549976.png)
  * ![image-20191216212340375](D:\OneDrive\Pictures\Typora\image-20191216212340375.png)
  * `pack`: implementation type + record
  * ![image-20191216232311826](D:\OneDrive\Pictures\Typora\image-20191216232311826.png)
  * ![image-20191216232316558](D:\OneDrive\Pictures\Typora\image-20191216232316558.png)
  * `impl Trait`

* Bisimulation: compare 2 implementations of an abstract type, if equivalent

  * dispatch matrix $e_{DM}$
    * ![image-20191217145447248](D:\OneDrive\Pictures\Typora\image-20191217145447248.png)
  * ![image-20191217145507335](D:\OneDrive\Pictures\Typora\image-20191217145507335.png)

  

  ## PCF-By-Value

  * PCF is partial in that a well-typed program need not terminate
  * non-termination, by-name vs by-value
  * laziness: unevaluated computations as if values, range includes computations  (by-name)
    * three booleans
    * `fix{t}(x.e)` at any type
  * eager: variables to range only over values of their type (by-value)
    * two booleans
  * ![image-20191217160404654](D:\OneDrive\Pictures\Typora\image-20191217160404654.png)
  * ![image-20191217160413208](D:\OneDrive\Pictures\Typora\image-20191217160413208.png)
  * ![image-20191217161026047](D:\OneDrive\Pictures\Typora\image-20191217161026047.png)
  * computation: ![image-20191217162520916](D:\OneDrive\Pictures\Typora\image-20191217162520916.png)
  * MPCF: modal PCF
  * modal type $\text{comp}(\tau)$: values are encapsulated computations of the form $\text{comp}(e)$ in which $e$ is an unevaluated computation
  * elimination form $\text{bnd}(e_1;x.e_2)$: evaluates the encapsulated computation $e_1$, then passes its value to the computation $e_2$
  * $let(e_1;x_1.e_2) \triangleq bnd(comp(e_1); x_1.e_2)$
  * ![image-20191217163731293](D:\OneDrive\Pictures\Typora\image-20191217163731293.png)



## Partiality & Recursive Types

* total: no infinite loop / divergent programs, no general recursion
* partial: possibility of divergence
* System PCF
* ![image-20191217170531721](D:\OneDrive\Pictures\Typora\image-20191217170531721.png)
* $\text{fix } x : \tau \text{ is } e \to $ `val rec x : t = e` (self-reference)
* ![image-20191217170922769](D:\OneDrive\Pictures\Typora\image-20191217170922769.png)
* ![image-20191217171009848](D:\OneDrive\Pictures\Typora\image-20191217171009848.png)
* ![image-20191217171138312](D:\OneDrive\Pictures\Typora\image-20191217171138312.png)
* diverge expressions: $\bot \triangleq \text{ fix } x : \tau \text{ is } x$
* System FPC: recursive types
  * ![image-20191217210515963](D:\OneDrive\Pictures\Typora\image-20191217210515963.png)
  * not exactly the same as `fold`/`unfold` from inductive/coinductive types
  * ![image-20191217210545910](D:\OneDrive\Pictures\Typora\image-20191217210545910.png)
  * ![image-20191217210550213](D:\OneDrive\Pictures\Typora\image-20191217210550213.png)
  * eager FPC $\to$ inductive types
  * lazy FPC $\to$ coinductive types
  * reify self-reference
    * ![image-20191217210938573](D:\OneDrive\Pictures\Typora\image-20191217210938573.png)
    * $self(\tau) \triangleq rec(t.t \to \tau)$
    * ![image-20191217211013287](D:\OneDrive\Pictures\Typora\image-20191217211013287.png)
    * ![image-20191217211059766](D:\OneDrive\Pictures\Typora\image-20191217211059766.png)
* Origin of partiality
  * ![image-20191217211206286](D:\OneDrive\Pictures\Typora\image-20191217211206286.png)



## By-name/By-value PCF, Dynamic & Unityped Languages

* ![image-20191217211434782](D:\OneDrive\Pictures\Typora\image-20191217211434782.png)
* ![image-20191217211513948](D:\OneDrive\Pictures\Typora\image-20191217211513948.png)
* Untyped languages: UTLC / Dynamic PCF (DPCF)
* untyped = unityped
  * type of every expression in UTLC is $rec\{t.t \to t\}$
  * ![image-20191217211639124](D:\OneDrive\Pictures\Typora\image-20191217211639124.png)
* DPCF
  * ![image-20191217211653319](D:\OneDrive\Pictures\Typora\image-20191217211653319.png)
* Hybrid PCF (HPCF)
  * ![image-20191217211725077](D:\OneDrive\Pictures\Typora\image-20191217211725077.png)
  * ![image-20191217211739477](D:\OneDrive\Pictures\Typora\image-20191217211739477.png)
  * ![image-20191217211756107](D:\OneDrive\Pictures\Typora\image-20191217211756107.png)
  * ![image-20191217211800741](D:\OneDrive\Pictures\Typora\image-20191217211800741.png)
  * ![image-20191217211806261](D:\OneDrive\Pictures\Typora\image-20191217211806261.png)



## Exceptions

* ![image-20191217212457364](D:\OneDrive\Pictures\Typora\image-20191217212457364.png)
* ![image-20191217212504477](D:\OneDrive\Pictures\Typora\image-20191217212504477.png)
* ![image-20191217220150417](D:\OneDrive\Pictures\Typora\image-20191217220150417.png)
* `exn`: type `clsfd` of dynamically classified values
* ![image-20191217220159010](D:\OneDrive\Pictures\Typora\image-20191217220159010.png)
* ![image-20191217220446752](D:\OneDrive\Pictures\Typora\image-20191217220446752.png)
* ![image-20191217220334601](D:\OneDrive\Pictures\Typora\image-20191217220334601.png)
* control aspect: return value (normal continuation) / raising an exception (exceptional continuation)
  * by-name problem?
* data aspect: type of value to be raised when an exception is to be signaled.
* ![image-20191217220758281](D:\OneDrive\Pictures\Typora\image-20191217220758281.png)
* $comp\{\tau\}$: a suspended computation, either evaluate to a value of type $\tau$, or trigger an exception
* ![image-20191217220936616](D:\OneDrive\Pictures\Typora\image-20191217220936616.png)
* control flow
  * structural dynamics: well-formed statics, transitions rules in dynamics
  * local forms of control: if-then-else, function calls, recursive functions $\longmapsto$
  * nonlocal control flow: exceptional control flow, continuations, nonlocal jumps (`setjmp`, `longjmp`)
  * control stack: **K** machine
    * stacks $k ::= \epsilon \mid k; f$
    * $k \rhd e$: evaluation computation $e$ on the stack $k$
    * $k \lhd v$: returning the value $v$ from the stack $k$
    * $k \blacktriangleleft e$: passing the exception value $e$ to stack $k$
    * transition judgment $\longmapsto$
    * ![image-20191217221921092](D:\OneDrive\Pictures\Typora\image-20191217221921092.png)
    * $K \bot \tau$: stack $K$ accepts an value of type $\tau$
      * ![image-20191217222033103](D:\OneDrive\Pictures\Typora\image-20191217222033103.png)
      * ![image-20191217222039495](D:\OneDrive\Pictures\Typora\image-20191217222039495.png)
* exceptions vs errors
  * ![image-20191217222234638](D:\OneDrive\Pictures\Typora\image-20191217222234638.png)

* [stack machine by-name & by-value](http://www.cs.cmu.edu/~rwh/pfpl/supplements/stacks.pdf)





## Continuations

* ![image-20191217231624393](D:\OneDrive\Pictures\Typora\image-20191217231624393.png)
* ![image-20191217231630737](D:\OneDrive\Pictures\Typora\image-20191217231630737.png)
  * ![image-20191218150116559](D:\OneDrive\Pictures\Typora\image-20191218150116559.png)
* Law of the Excluded Middle
* ![image-20191217231755015](D:\OneDrive\Pictures\Typora\image-20191217231755015.png)
* value of type $\tau$ or $cont(\tau)$
* ![image-20191217233447697](D:\OneDrive\Pictures\Typora\image-20191217233447697.png)
* ![image-20191217233457584](D:\OneDrive\Pictures\Typora\image-20191217233457584.png)
* ![image-20191217234636565](D:\OneDrive\Pictures\Typora\image-20191217234636565.png)
* -> Pierce's Law



## Parallelism

* fork-join parallelism: static `par e1 = e2, x1 = x2 in e` & dynamics evaluating `e1, e2` in parallel
* Modal PCF (MPCF)
  * ![image-20191218134838220](D:\OneDrive\Pictures\Typora\image-20191218134838220.png)
  * ![image-20191218134846776](D:\OneDrive\Pictures\Typora\image-20191218134846776.png)
  * $e \Downarrow^c v$: defined for closed computation $e$, closed values $v$, cost graphs $c$
* How to express simultaneous dependency of one computation on several prior computations whose relative evaluation order is unconstrained
  * Lazy product type: encapsulate 2 unevaluated computations
  * parallel bind: elimination, evaluates both computations, bind a variable to the eager pair of their values
  * ![image-20191218135125233](D:\OneDrive\Pictures\Typora\image-20191218135125233.png)
  * ![image-20191218135130791](D:\OneDrive\Pictures\Typora\image-20191218135130791.png)
  * lazy product type -> lazy pair: sequence generator
  * eager product types -> eager pair: sequence whose length/value dynamically
  * ![image-20191218141459981](D:\OneDrive\Pictures\Typora\image-20191218141459981.png)
* KPCF
  * ![image-20191218141927221](D:\OneDrive\Pictures\Typora\image-20191218141927221.png)
  * ![image-20191218141848774](D:\OneDrive\Pictures\Typora\image-20191218141848774.png)
* CH-iso logical negation
  * ![image-20191218142626804](D:\OneDrive\Pictures\Typora\image-20191218142626804.png)
  * [[Q: why??]]
  * ![image-20191218143451908](D:\OneDrive\Pictures\Typora\image-20191218143451908.png)
  * [haskell-CH-iso](https://en.wikibooks.org/wiki/Haskell/The_Curry–Howard_isomorphism)
* [equivalence-arising-from-CH-iso](https://stackoverflow.com/questions/2969140/what-are-the-most-interesting-equivalences-arising-from-the-curry-howard-isomorp)
* PPCF (lazy-product + multi-ary bind)
  * ![image-20191218150159592](D:\OneDrive\Pictures\Typora\image-20191218150159592.png)
  * ![image-20191218150209715](D:\OneDrive\Pictures\Typora\image-20191218150209715.png)
  * ![image-20191218150706752](D:\OneDrive\Pictures\Typora\image-20191218150706752.png)
  * ![image-20191218150712624](D:\OneDrive\Pictures\Typora\image-20191218150712624.png)
* Modal Parallel PCF (MPPCF)
  * modal separation between expressions & values (Haskell Monad)
  * ![image-20191218151322903](D:\OneDrive\Pictures\Typora\image-20191218151322903.png)
  * ![image-20191218153151376](D:\OneDrive\Pictures\Typora\image-20191218153151376.png)
  * ![image-20191218153157960](D:\OneDrive\Pictures\Typora\image-20191218153157960.png)
  * ![image-20191218153211373](D:\OneDrive\Pictures\Typora\image-20191218153211373.png)



## Automata & Concurrency

* ![image-20191218153256611](D:\OneDrive\Pictures\Typora\image-20191218153256611.png)
* ![image-20191218153302941](D:\OneDrive\Pictures\Typora\image-20191218153302941.png)
* language of an automata $\mathcal{L}(A)$: the set of words $s_0 \overset{w}{\mapsto} A$
* [[T: can't understand]]





## Dynamic Classification

* `clsfd`: classified (like `exn` & `exception` keyword in SML)
* ![image-20191218161314958](D:\OneDrive\Pictures\Typora\image-20191218161314958.png)
* ![image-20191218161342321](D:\OneDrive\Pictures\Typora\image-20191218161342321.png)
* ![image-20191218161352161](D:\OneDrive\Pictures\Typora\image-20191218161352161.png)





## Concurrency

* ![image-20191218161424007](D:\OneDrive\Pictures\Typora\image-20191218161424007.png)
* Concurrent Algol
  * ![image-20191218161440550](D:\OneDrive\Pictures\Typora\image-20191218161440550.png)
  * ![image-20191218161619872](D:\OneDrive\Pictures\Typora\image-20191218161619872.png)
  * ![image-20191218161631030](D:\OneDrive\Pictures\Typora\image-20191218161631030.png)
* ![image-20191218161652408](D:\OneDrive\Pictures\Typora\image-20191218161652408.png)
* ![image-20191218161657409](D:\OneDrive\Pictures\Typora\image-20191218161657409.png)
* ![image-20191218161703873](D:\OneDrive\Pictures\Typora\image-20191218161703873.png)
* ![image-20191218161708863](D:\OneDrive\Pictures\Typora\image-20191218161708863.png)
* ![image-20191218161714696](D:\OneDrive\Pictures\Typora\image-20191218161714696.png)
* ![image-20191218161719776](D:\OneDrive\Pictures\Typora\image-20191218161719776.png)
* ![image-20191218161725247](D:\OneDrive\Pictures\Typora\image-20191218161725247.png)
* ![image-20191218161731387](D:\OneDrive\Pictures\Typora\image-20191218161731387.png)
* ![image-20191218161735871](D:\OneDrive\Pictures\Typora\image-20191218161735871.png)



