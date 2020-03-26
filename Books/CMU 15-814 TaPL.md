# Types and Programming Languages

[fall2019](https://www.cs.cmu.edu/~fp/courses/15814-f19/schedule.html)



## Lambda Calculus

* ![image-20191227161501029](D:\OneDrive\Pictures\Typora\image-20191227161501029.png)

* $\mapsto^n_\beta$: reduction in $n$ steps

* $\mapsto_\beta^*$: reduction in arbitrary number of steps

  * reflexive & transitive closure of $\mapsto_\beta$

* $true = \lambda x. \lambda y. x$

* $false = \lambda x.\lambda y.y$

* $not = \lambda b. b\ false\ true$

* $not' = \lambda b.\lambda x.\lambda y. b y x$

* ```haskell
  true = \x -> \y -> x
  false = \x -> \y -> y
  -- not != not', both normal
  not = \b -> b false true
  not' = \b -> \x -> \y -> b y x
  
  xor = \b -> \c -> b (not c) c
  ```

* computing with particular data representations in the $\lambda$-calculus is not extensional

  * extensional equality: $f = g \Leftrightarrow (\forall x. f x = g x)$
  * intensional equality: $\alpha$-convertible + eta-conversion
  * [undecidability of extensional equality](https://www.zhihu.com/question/25484990)
  * [non-extensionablity](https://plato.stanford.edu/entries/lambda-calculus/#Non-Extensionality)

* ```haskell
  zero = \s -> \z -> z
  succ = \n -> \s -> \z -> s (n s z)
  plus = \n -> \k -> n succ k
  times = \n -> \k -> n (plus k) zero
  exp = \b -> \e -> e (times b) (succ zero)
  ```



## Recursion

* schema of iteration 

  * $\overline{n}\ g\ c = g (\cdots (g\ c))$
  * $f\ 0 = c$
  * $f\ (n + 1) = g\ (f\ n)$
  * defined in $\lambda$-calculus as church numeral $f = \lambda n. n\ g\ c$

* $\eta$-conversion: weak form of an extensionality principle

* schema of primitive recursion

  * $f\ 0 = c$

  * $f\ (n+1) = h\ n\ (f\ n)$

  * $f'\ n = \langle n, f\ n\rangle$

  * ```haskell
    -- with n, predecessor defiend
    pred_c = 0
    pred_h = \x -> \y -> x
    
    
    -- apply the continuation k to the components of its first argument (which should be a pair)
    letpair (e1, e2) k = k e1 e2
    
    f' 0 = (0, c) -- (0, f 0)
    -- not valid haskell pattern (should be succ n)
    f' (n + 1) = letpair (f' n) (\x -> \r -> (x + 1, h x r)) -- (n + 1, f (n + 1))
    f' = \n -> n (\r -> r (\x -> \y -> pair (succ x) (h x y))) (pair zero c)
    
    f n = letpair (f' n) (\x -> \r -> r)
    f = \n -> f' n (\x -> \y -> y)
    
    pair = \x -> \y -> \g -> g x y
    fst = \p -> p true
    snd = \p -> p false
    
    pred' = \n -> n (\r -> r (\x -> \y -> (succ x) x)) (pair zero zero)
    pred = \n -> pred' n (\x -> \y -> y)
    ```

* general recursion

  * $h = h\ f$

  * ```haskell
    h = \g -> \a -> b -> if (a == b) then a
    							 else if (a > b) then g (a - b) b else g (b - a) b
    -- don't compile, infinite type
    y = \f -> (\x -> f (x x)) (\x -> f (x x))
    ```

* ![image-20191228130652182](D:\OneDrive\Pictures\Typora\image-20191228130652182.png)

* ![image-20191228130700256](D:\OneDrive\Pictures\Typora\image-20191228130700256.png)

* ![image-20191228130705361](D:\OneDrive\Pictures\Typora\image-20191228130705361.png)

* ![image-20191228130714539](D:\OneDrive\Pictures\Typora\image-20191228130714539.png)



## Simple Types

* Type variables $\alpha$

* Types $\tau ::= \tau_1 \to \tau_2 \mid \alpha$

* Typing context $\Gamma ::= x_1 : \tau_1, \cdots, x_n : \tau_n$

* Typing judgement $\Gamma \vdash e : \tau$

* $\to$: right associative

*  ```haskell
  true :: a -> b -> a
  false :: a -> b -> b
   ```

* ![image-20191228150018043](D:\OneDrive\Pictures\Typora\image-20191228150018043.png)

* Characterizing Booleans

  * Representation of Booleans
    * If $\cdot \vdash e : \alpha \to (\alpha \to \alpha)$ then $e =_\beta true$ or $e =_\beta false$
    * or $e$ is a normal form
  * Termination
    * If $\Gamma \vdash e : \tau$ then $e \mapsto_\beta^* e'$ for a normal form $e'$
  * Subject reduction
    * If $\Gamma \vdash e : \tau$ and $e \longmapsto_\beta e'$ then $\Gamma \vdash e' : \tau$

* Normal form

  * congruence rules: reduction of a subterm
    * ![image-20191228153211178](D:\OneDrive\Pictures\Typora\image-20191228153211178.png)
  * normal form
    * ![image-20191228153218279](D:\OneDrive\Pictures\Typora\image-20191228153218279.png)



## Representation Theorem

* Theorem: irreducible expressions are normal forms

* Normal form $\lambda x_1. \cdots \lambda x_n. ((x\ e_1) \cdots e_k)$: abstraction will not enable any reduction

* Neutral form $((x\ e_1) \cdots e_k)$: applying neutral form to argument will not enable any reduction

  * ```haskell
    data WithBound a = Var | Other a
    
    data Normal a
      = Neutral (Neutral a)
      | Abstract (Normal (WithBound a))
    
    data Neutral a
      = Variable a
      | Apply (Neutral a) (Normal a)
    ```

  * ![image-20191228163828522](D:\OneDrive\Pictures\Typora\image-20191228163828522.png)

* ![image-20191228161739723](D:\OneDrive\Pictures\Typora\image-20191228161739723.png)

* ![image-20191228161750003](D:\OneDrive\Pictures\Typora\image-20191228161750003.png)

* ![image-20191228162902195](D:\OneDrive\Pictures\Typora\image-20191228162902195.png)

  * [[C: bidirectional type checking/checked against vs. inference|synthesize]]
  * ![image-20191228202306434](D:\OneDrive\Pictures\Typora\image-20191228202306434.png)



## Subject Reduction

* $\Omega = (\lambda x. x\ x) (\lambda x. x\ x)$
  * no normal form, reduce to itself
* type inference: construct the skeleton of a type derivation, collects constraints on the unknown types, solve them to find a most general solution
  * unification algorihtm
  * global informaton
  * undecidable / impractical with language extensions
  * local: bidirectional type-checking.
    * type errors are specific
    * programmers supply types
    * robust under language extensions
* subject reduction
  * If $\Gamma \vdash e : \tau$ and $e \longmapsto e'$ then $\Gamma \vdash e' : \tau$
* ![image-20191228212916594](D:\OneDrive\Pictures\Typora\image-20191228212916594.png)
* ![image-20191228212922434](D:\OneDrive\Pictures\Typora\image-20191228212922434.png)



## From $\lambda$-calculus to Programming Languages

* Problems
  * Too abstract: cannot express algorithms / ideas in code because the high level of abstraction prevents us from doing so
    * data like natural numbers -> complexity issues
    * side effects
  * Observability of functions: normal forms can be functions. need to inspect the structure of functions. expect to be opaque
    * data as functions
    * unobservable as machine code
  * Generality of typing: STLC can't express fixed points, very restrictive
* statics: typing rules for computations
  * ![image-20191229134005763](D:\OneDrive\Pictures\Typora\image-20191229134005763.png)
* dynamics: deterministic, call-by-name, call-by-value
  * ![image-20191229134019176](D:\OneDrive\Pictures\Typora\image-20191229134019176.png)
  * determinacy by requiring certain subexpressions to be values
  * force call-by-value by force subexpressions to be values
* Booleans as a primitive type (instead of function)
  * ![image-20191229134153222](D:\OneDrive\Pictures\Typora\image-20191229134153222.png)
  * ![image-20191229134208406](D:\OneDrive\Pictures\Typora\image-20191229134208406.png)
* Type Preservation
  * ![image-20191229143151753](D:\OneDrive\Pictures\Typora\image-20191229143151753.png)
* Progress
  * ![image-20191229143219497](D:\OneDrive\Pictures\Typora\image-20191229143219497.png)
  * ![image-20191229143240919](D:\OneDrive\Pictures\Typora\image-20191229143240919.png)



## Products

* $\langle e_1, e_2 \rangle : \tau_1 \times \tau_2$

* ![image-20191229143417465](D:\OneDrive\Pictures\Typora\image-20191229143417465.png)

* ![image-20191229143434376](D:\OneDrive\Pictures\Typora\image-20191229143434376.png)

* ![image-20191229143443202](D:\OneDrive\Pictures\Typora\image-20191229143443202.png)

* ![image-20191229143448531](D:\OneDrive\Pictures\Typora\image-20191229143448531.png)

* Destructing pairs: `case`

  * ![image-20191229143523946](D:\OneDrive\Pictures\Typora\image-20191229143523946.png)
  * ![image-20191229143531512](D:\OneDrive\Pictures\Typora\image-20191229143531512.png)
  * `fst = \p. case p (<x, y> => x) : (a, b) -> a`
  * `snd = \p. case p (<x, y> => y) : (a, b) -> b`

* ![image-20191229143641087](D:\OneDrive\Pictures\Typora\image-20191229143641087.png)

* ![image-20191229143647857](D:\OneDrive\Pictures\Typora\image-20191229143647857.png)

* Currying

  * isomorphic types: $\tau \cong \sigma$

    * $(\tau \times \sigma) \to \rho \cong \tau \to (\sigma \to \rho)$

  * ```haskell
    -- uncurry
    forth :: ((a, b) -> c) -> (a -> (b -> c))
    forth = \f -> \x -> \y -> f (x, y)
    -- curry
    back :: (a -> (b -> c)) -> ((a, b) -> c)
    back = \g -> \p -> g (fst p) (snd p)
    ```

  * `back . forth` = identity => isomorphic

* Unit type: $\langle \rangle$, $\tau \cong \tau \times 1$

  * ![image-20191229143959312](D:\OneDrive\Pictures\Typora\image-20191229143959312.png)

* ![image-20191229144531754](D:\OneDrive\Pictures\Typora\image-20191229144531754.png)



## Sums

* choices on the nature of programming languages
  * Precision of Types: from `true/false` to precise types
    * $\to$ dependent types
  * Expressiveness of Types: what kinds of sound programs the type systems can accept
  * Computational Mechanism: value-oriented, to mutate stores, I/O, exception raising, concurrency
  * Level of Dynamics: range of different operational specifications at different levels of abstraction
    * data in memory allocation?
    * function compilatioon>
  * Equality & Reasoning: formalization, satisfy specifications
* disjoint sums $\Gamma, e : \tau_1 \vdash l \cdot e, \Gamma, e : \tau_2 \vdash r \cdot e : \tau_1 + \tau_2$
  * ![image-20191229190822591](D:\OneDrive\Pictures\Typora\image-20191229190822591.png)
  * ![image-20191229190828730](D:\OneDrive\Pictures\Typora\image-20191229190828730.png)
  * ![image-20191229190839493](D:\OneDrive\Pictures\Typora\image-20191229190839493.png)
* Boolean types
  * $bool \overset{\Delta}{=} 1 + 1, true = l \cdot \langle \rangle, false = r \cdot \langle \rangle$
  * $if\ e_0\ e_ 1\ e_2 = \text{case}\ e_0 (l \cdot x_1 \Rightarrow e_1 \mid r \cdot x_2 \Rightarrow e_2)$
  * `'a option = 'a + 1`
  * `nat = 1 + nat`
* Empty type $(), 0 + \tau \cong \tau$
  * ![image-20191229191528645](D:\OneDrive\Pictures\Typora\image-20191229191528645.png)
  * ![image-20191229191538695](D:\OneDrive\Pictures\Typora\image-20191229191538695.png)
  * canonical form: $v : 0$ then contradiction
* $\sum_{l \in L} (l : \tau_l)$
  * ![image-20191229201004332](D:\OneDrive\Pictures\Typora\image-20191229201004332.png)
  * generalized constructor (allowing any label of a sum) & case expressions (branch for each label of a sum)
* ![image-20191229193328417](D:\OneDrive\Pictures\Typora\image-20191229193328417.png)
* ![image-20191229193337536](D:\OneDrive\Pictures\Typora\image-20191229193337536.png)
* ![image-20191229193348105](D:\OneDrive\Pictures\Typora\image-20191229193348105.png)





## Recursive Types

* ![image-20191229193447339](D:\OneDrive\Pictures\Typora\image-20191229193447339.png)
* (iso)resursive type: $\rho \alpha . \tau$
  * ![image-20191229193606567](D:\OneDrive\Pictures\Typora\image-20191229193606567.png)
  * $nat = \rho \alpha. 1 + \alpha$
  * $tree = \rho \alpha. 1 + (\alpha \times nat \times nat)$
  * `fold`: constructor
  * `unfold`: destructor
  * ![image-20191229193909191](D:\OneDrive\Pictures\Typora\image-20191229193909191.png)
  * ![image-20191229194635663](D:\OneDrive\Pictures\Typora\image-20191229194635663.png)
  * ![image-20191229194642734](D:\OneDrive\Pictures\Typora\image-20191229194642734.png)
  * ![image-20191229194648134](D:\OneDrive\Pictures\Typora\image-20191229194648134.png)
  * $zero = fold (l \cdot \langle \rangle) : nat$
  * $one = fold (r \cdot zero) : nat$
  * $succ = \lambda n. fold (r \cdot n) : nat \to nat$
  * $pred = \lambda n. case\ (unfold\ n) (l \cdot x_ 1\Rightarrow zero \mid r \cdot x_2 \Rightarrow x_2) : nat \to nat$
* embedded untyped lambda calculus $\to$ unityped
  * ![image-20191229200005214](D:\OneDrive\Pictures\Typora\image-20191229200005214.png)
* Fixed point expressions $fix\ f. e$
  * ![image-20191229200110916](D:\OneDrive\Pictures\Typora\image-20191229200110916.png)
  * ![image-20191229200132764](D:\OneDrive\Pictures\Typora\image-20191229200132764.png)
  * $plus = fix\ p. \lambda n. \lambda k. if\ (is\_zero\ n)\ k\ (succ\ (p\ (pred\ n) k)) : nat \to (nat \to nat)$
  * neither a constructor nor destructor of any particular type, but applicable at any type $\tau$
    * recursion is fundamental computational principle separate from any particular typing construct?
  * $fix\ f.e$ where $f$ is a expression, not a value
    * a call-by-value language sometimes limits the fixed point expression in functions `let rec f x = e`



## Elaboration

* concrete syntax: front-end, like Scheme macros

* abstracy syntax: result of parsing, back-end, compilation

* elaboration: translation mediating between specific forms of **concrete syntax** and internal representation in **abstract syntax**

* Syntactic sugar

  * ![image-20191229200730264](D:\OneDrive\Pictures\Typora\image-20191229200730264.png)

* Data Types

  * $nat \cong (zero\ : 1) + (succ\ : nat)$

  * automatically define constructors

  * simplified pattern matching

  * ```ocaml
    type nat = Zero | Succ of nat;;
    let pred n = match n with
    	| Zero -> Zero
    	| Succ n’ -> n’;;
    ```

  * ```haskell
    data Nat = Zero | Succ Nat
    
    pred :: Nat -> Nat
    pred Zero = Zero
    pred (Succ n’) = n’
    ```

  * data constructors: labels to construct values of a sum type

* Generarlizaing Sums

  * ![image-20191229201325380](D:\OneDrive\Pictures\Typora\image-20191229201325380.png)
  * unified destructors for recursive types
    * ![image-20191229201354180](D:\OneDrive\Pictures\Typora\image-20191229201354180.png)
  * ![image-20191229202224962](D:\OneDrive\Pictures\Typora\image-20191229202224962.png)
  * ![image-20191229202238179](D:\OneDrive\Pictures\Typora\image-20191229202238179.png)

* Nesting case expressions

  * ![image-20191229202304827](D:\OneDrive\Pictures\Typora\image-20191229202304827.png)

* General pattern matching

  * branches `B`
  * patterns `p`
  * ![image-20191229202405650](D:\OneDrive\Pictures\Typora\image-20191229202405650.png)
  * $\Gamma \vdash \tau \rhd B : \sigma$: match a case subject of type $\tau$ against the branches $B$, each of which must have type $\sigma$
  * ![image-20191229202536458](D:\OneDrive\Pictures\Typora\image-20191229202536458.png)
  * ![image-20191229202544138](D:\OneDrive\Pictures\Typora\image-20191229202544138.png)
  * $\Gamma ; \Phi \vdash e : \sigma$
  * $\Phi ::= \cdot \mid (p : \tau) \Phi$: ordered sequence of assumptions about patterns
  * ![image-20191229202741746](D:\OneDrive\Pictures\Typora\image-20191229202741746.png)
  * ![image-20191229202753018](D:\OneDrive\Pictures\Typora\image-20191229202753018.png)
  * examples
    * ![image-20191229203044779](D:\OneDrive\Pictures\Typora\image-20191229203044779.png)
    * ![image-20191229203106979](D:\OneDrive\Pictures\Typora\image-20191229203106979.png)

* Dynamics of Pattern Matching

  * $v = [\eta]p$: simultaneous substitution for all variables in $p$ where we write as $(v_1/x_1, \cdots, v_n/x_n)$, applying $\eta$ to $p$ yields $v$
  * ![image-20191229203303137](D:\OneDrive\Pictures\Typora\image-20191229203303137.png)
  * decidability of $v = [\eta]p$
  * ![image-20191229204504846](D:\OneDrive\Pictures\Typora\image-20191229204504846.png)
  * ![image-20191229204540704](D:\OneDrive\Pictures\Typora\image-20191229204540704.png)
  * ![image-20191229204550153](D:\OneDrive\Pictures\Typora\image-20191229204550153.png)
  * requires linear patterns & linear time in size of the values
    * e.g. `(v1, v2)` against `(x, x)`

* Preservation for Pattern Matching

  * ![image-20191229210111960](D:\OneDrive\Pictures\Typora\image-20191229210111960.png)
  * ![image-20191229212405428](D:\OneDrive\Pictures\Typora\image-20191229212405428.png)
  * ![image-20191229212424836](D:\OneDrive\Pictures\Typora\image-20191229212424836.png)

* Progress for Pattern Matching

  * terminate with $fix f.f$ or $\bot$





## Exceptions

* ![image-20191229212137213](D:\OneDrive\Pictures\Typora\image-20191229212137213.png)
* ![image-20191229212146884](D:\OneDrive\Pictures\Typora\image-20191229212146884.png)





## K Machine

* ```hask
  --- K machine as a continuation-passing interpreter
  --- Deep embedding, but using higher-order syntax
  --- 15-814, Fall 2018
  --- Frank Pfenning, Oct 25, 2018
  
  type Lab = String
  
  data E = Lam (E -> E)
         | App E E
         | Pair E E
         | CasePair E (E -> E -> E)
         | Unit
         | CaseUnit E E
         | Dot Lab E
         | CaseSum E (Lab -> E -> E)
         | Fold E
         | Unfold E
         | Fix (E -> E)
  
  instance Show E where
    show (Lam f) = "Lam -"
    show (Pair v1 v2) = "<" ++ show v1 ++ "," ++ show v2 ++ ">"
    show (Unit) = "<>"
    show (Dot l v) = "(" ++ l ++ "." ++ show v ++ ")"
    show (Fold v) = "Fold" ++ show v ++ ""
  
  eval :: E -> (E -> E) -> E
  retn :: E -> (E -> E) -> E
  
  eval (Lam f) k = retn (Lam f) k
  eval (App e1 e2) k = eval e1 (\(Lam f) -> eval e2 (\v2 -> eval (f v2) k))
  eval (Pair e1 e2) k = eval e1 (\v1 -> eval e2 (\v2 -> retn (Pair v1 v2) k))
  eval (CasePair e f) k = eval e (\(Pair v1 v2) -> eval (f v1 v2) k)
  eval (Unit) k = retn (Unit) k
  eval (CaseUnit e f) k = eval e (\(Unit) -> eval f k)
  eval (Dot l e) k = eval e (\v -> retn (Dot l v) k)
  eval (CaseSum e f) k = eval e (\(Dot l v) -> eval (f l v) k)
  eval (Fold e) k = eval e (\v -> retn (Fold v) k)
  eval (Unfold e) k = eval e (\(Fold v) -> retn v k)
  eval (Fix f) k = eval (f (Fix f)) k
  
  retn v k = k v
  
  --- bool = 1 + 1
  true_ = Dot "true" Unit
  false_ = Dot "false" Unit
  if_ e1 e2 e3 = CaseSum e1 (\i -> \v ->
                   case i of "true" -> e2
                             "false" -> e3)
  and_ = Lam (\b -> Lam (\c -> if_ b c false_))
  
  --- nat ~ (zero : 1) + (succ : nat)
  zero_ = Fold (Dot "zero" Unit)
  succ_ = Lam (\n -> Fold (Dot "succ" n))
  caseNat_ e1 e2 e3 = CaseSum (Unfold e1) (\i -> \v ->
                        case i of "zero" -> e2
                                  "succ" -> (e3 v))
  pred_ = Lam (\n -> caseNat_ n zero_ (\m -> m))
  two_ = App succ_ (App succ_ zero_)
  
  main = do print (true_)
            print (false_)
            print (eval (App (App and_ true_) false_) (\v -> v))
            print (eval two_ (\v -> v))
            print (eval (App pred_ two_) (\v -> v))
  ```

* ```haskell
  --- live coding version
  --- K machine as a continuation-passing interpreter
  --- Deep embedding, but using higher-order syntax
  --- 15-814, Fall 2019
  --- Frank Pfenning, Oct 10, 2019
  
  type Lab = String
  
  data E = Lam (E -> E)
         | App E E
         | Dot Lab E
         | CaseSum E (Lab -> E -> E)
         | Unit
         | CaseUnit E E
  
  --- show only values
  instance Show E where
    show (Lam f) = "Lam -"
    show (Dot i v) = i ++ "." ++ show v
    show (Unit) = "<>"
  
  eval :: E -> (E -> E) -> E
  retn :: E -> (E -> E) -> E
  
  eval (Lam f) k = retn (Lam f) k
  eval (App e1 e2) k = eval e1 (\(Lam f) -> eval e2 (\v2 -> eval (f v2) k))
  eval (Dot i e) k = eval e (\v -> retn (Dot i v) k)
  eval (CaseSum e b) k = eval e (\(Dot j v) -> eval (b j v) k)
  eval (Unit) k = retn (Unit) k
  eval (CaseUnit e b) k = eval e (\(Unit) -> eval b k)
  
  retn v k = k v
  
  true_ = Dot "true" Unit
  false_ = Dot "false" Unit
  
  and_ = Lam (\x -> Lam (\y -> CaseSum x (\i -> \v ->
         case i of "true" -> y
                   "false" -> false_)))
  
  --- other examples from the pure lambda-calculus
  id :: E
  id = Lam (\x -> x)
  
  tt :: E
  tt = Lam (\x -> Lam (\y -> x))
  
  ff :: E
  ff = Lam (\x -> Lam (\y -> y))
  
  main = do (print (eval (App (App and_ true_) true_) (\x -> x)))
  ```

* stacK machine 

  * stack can be seen as a continuation
  * capturing everything remains to be done after current expression has been evaluated

* $k \rhd e$: evaluate $e$ with continuation $k$ / `eval e k`

* $k \lhd e$: return value $v$ to continuation $k$ / `retn v k`

  * $\epsilon \lhd v$ iff. $e \mapsto^* v$

* initial continuation / empty stack: $\epsilon$

* Continuations $k ::= \epsilon \mid \ldots$

  * ![image-20191230163216444](D:\OneDrive\Pictures\Typora\image-20191230163216444.png)

* For any continuation $k$, expression $e$, value $v$, $k \rhd e \mapsto^* k \lhd v\ \text{iff.}\ e \mapsto^* v$

  * `((\x -> \y -> x) v1) v2`
  * ![image-20191230163727856](D:\OneDrive\Pictures\Typora\image-20191230163727856.png)

* Eager Pairs

  * ![image-20191230163935056](D:\OneDrive\Pictures\Typora\image-20191230163935056.png)

* Typing the K Machine

  * continuation as receiving a value of type $\tau$ & eventually producing the final answer for the whole program of type $sigma$: $k \div \tau \Rightarrow \sigma$
  * ![image-20191230164548880](D:\OneDrive\Pictures\Typora\image-20191230164548880.png)



## Bisimulation

* define $k(e) = e'$ as the operation of reconstituting an expression from the state $k \lhd e$ / $k \rhd e$ (ignoring $e$ is a value for the first case)
  * ![image-20191230165246452](D:\OneDrive\Pictures\Typora\image-20191230165246452.png)
* machine state $k \bowtie e$ for either $k \lhd e$ or $k \rhd e$
* weak bisimulation $R$
  * If $k \bowtie e \mapsto k' \bowtie e'$ then $k(e) \mapsto^* k'(e')$
  * If $k(e) \mapsto k'(e')$ then $k \bowtie e \mapsto^* k' \bowtie e'$
  * ![image-20191230170744460](D:\OneDrive\Pictures\Typora\image-20191230170744460.png)
  * proof in [bisimulation](https://www.cs.cmu.edu/~fp/courses/15814-f19/lectures/13-bisimulation.pdf)
  * [[C: a reduction framework?]]
  * [[C: category morphism]]



## Proposition as Types

* > The meaning of a proposition is determined by [. . . ] what counts as a verification of it - by Martin-Lof

* verification: certain kind of proof that only examines the constituents of a proposition

* system of inference rules $\leftarrow$ natural deduction

* introduction rules

* elimination rules

* judgment: an object of knowledge

  * temporal logic: "A is true at time t"
  * modal logic: "A is necessarily true"
  * PL: "program M has type $\tau$"

* evident: if we know a judgment

* hypothetical judgment

* ![image-20191230183629569](D:\OneDrive\Pictures\Typora\image-20191230183629569.png)

* natural deduction (Gentzen + Prawitz)

  * intuitionistic/constructive: explicit evidence
    * classical/boolean: every proposititon must be true/false
    * e.g. $A \vee (A \supset B)$, unprovable in intutionistic, truth in classical [[C: double nagation?]]
  * ![image-20191230185352609](D:\OneDrive\Pictures\Typora\image-20191230185352609.png)

* Proposition as Types

  * Curry-Howard Isomorphism
  * $M : A$ M is a proof term for proposition A
  * Conjunction: product
  * Truth $\top$: unit
  * Implication $A \supset B$: abstraction
  * Disjunction: sum
  * Falsehood $\bot$: empty
  * Interaction Laws
    * ![image-20191230192514292](D:\OneDrive\Pictures\Typora\image-20191230192514292.png)
  * Summary
    * ![image-20191230192531346](D:\OneDrive\Pictures\Typora\image-20191230192531346.png)

* Reduction $M \longmapsto M'$ judgement of reduction

* ![image-20191230192910766](D:\OneDrive\Pictures\Typora\image-20191230192910766.png)

* ![image-20191230192917869](D:\OneDrive\Pictures\Typora\image-20191230192917869.png)

* ![image-20191230193051592](D:\OneDrive\Pictures\Typora\image-20191230193051592.png)

* ![image-20191230193110053](D:\OneDrive\Pictures\Typora\image-20191230193110053.png)

* harmony: the elimination rules are in harmony with the introduction rules in the sense that they are neither too strong nor too weak

* Local soundness

  * > Local soundness shows that the elimination rules are not too strong: no matter how we apply elimination rules to the result of an introduction we cannot gain any new information. We demonstrate this by showing that we can find a more direct proof of the conclusion of an elimination than one that first introduces and then eliminates the connective in question. This is witnessed by a **local reduction** of the given introduction and the subsequent elimination.

* Local completeness

  * > Local completeness shows that the elimination rules are not too weak: there is always a way to apply elimination rules so that we can reconstitute a proof of the original proposition from the results by applying introduction rules. This is witnessed by a **local expansion** of an arbitrary given derivation into one that introduces the primary connective.

* ![image-20191230194045116](D:\OneDrive\Pictures\Typora\image-20191230194045116.png)

*   ![image-20191230195352204](D:\OneDrive\Pictures\Typora\image-20191230195352204.png)

* Substitution Principle

  * ![image-20191230195501970](D:\OneDrive\Pictures\Typora\image-20191230195501970.png)



## Parametric Polymorphism

* ad hoc: multiple types possessed by a given expression or function which has different implementations for different types

* parametric: a function that behaves the same at all possible types

* Universally Quantified Types: $\Lambda \alpha. \lambda x. x : \forall \alpha. \alpha \to \alpha$

  * context $\Delta ::= \alpha_1\ ty, \cdots, \alpha_n\ ty$
  * $\Delta;\Gamma \vdash e : \tau$
    * all value variables $x$ in $e$ are declared in $\Gamma$
    * all type variables $\alpha$ in $\Gamma, e, \tau$ are declared in $\Delta$
  * ![image-20191230200311549](D:\OneDrive\Pictures\Typora\image-20191230200311549.png)

* ![image-20191230201851897](D:\OneDrive\Pictures\Typora\image-20191230201851897.png)

* Hindley-Miller

* > Bidirectional type checking continues to work well, but it requires the programmer to supply a lot of types. For the fully general system, many problems (such as type inference, carefully defined) will be undecidable. Some languages such as ML have adopted a restricted form of parametric polymorphism where the quantifiers can occur only on the outside, and can only be instantiated with quantifier-free types. In that case, type inference can remain more or less what it is for the language without parametric polymorphism: we construct the skeleton of a typing derivation, solve all the equations that arise from when we fill in the holes. The most general solution will have some free variables that we then explicit quantify over.





## Parametricity

* extensional equality $e \equiv e' : \tau$ when two closed expression are equal at type $\tau$

  * Kleene equality: both diverge (no value) / both reduce to equal values
  * observable types
    * ![image-20191230202814127](D:\OneDrive\Pictures\Typora\image-20191230202814127.png)
      * circular problem: purely positive (construct purely from observable types)
  * not observable (functions, lazy pairs): extensionality
    * ![image-20191230203156230](D:\OneDrive\Pictures\Typora\image-20191230203156230.png)
      * call-by-value, quatify over values
      * don't match against the shape of $v$ and $v'$, but probe behaviors via the elimination rules
    * ![image-20191230203200198](D:\OneDrive\Pictures\Typora\image-20191230203200198.png)
    * ![image-20191230204149340](D:\OneDrive\Pictures\Typora\image-20191230204149340.png)
      * circular problem: stratify language of types (ML, Haskell)
        * prefix polymorphism (Rank1Type): type variable $\alpha$ can be instantiated only with quatifier-free types
  * insufficient for parametricity $\forall \alpha. \tau$

* logic equality $e \approx e' \in [[\tau]]$ iff. $e \mapsto^* v, e' \mapsto^* v'$ and $v \sim v' \in [\tau]$

  * $v \sim v' \in [\tau]$ if the values $v$ and $v'$ are related by $[\tau]$ (by a relation $R: \sigma \leftrightarrow \sigma'$)
  * ![image-20191230211204878](D:\OneDrive\Pictures\Typora\image-20191230211204878.png)
  * ![image-20191230211823200](D:\OneDrive\Pictures\Typora\image-20191230211823200.png)
  * $R: \sigma \leftrightarrow \sigma'$: releation, $v R v'$ if R relates $v$ and $v'$
  * ![image-20191230211909773](D:\OneDrive\Pictures\Typora\image-20191230211909773.png)
  * ![image-20191230212009681](D:\OneDrive\Pictures\Typora\image-20191230212009681.png)
  * Example
    * ![image-20191230212043881](D:\OneDrive\Pictures\Typora\image-20191230212043881.png)

* Parametricity Theorem: If $\cdot ; \cdot \vdash e : \tau$, then $e \approx e : \tau$

  * ![image-20191230212154736](D:\OneDrive\Pictures\Typora\image-20191230212154736.png)
  * [parametricity & free theorem](https://www.well-typed.com/blog/2015/05/parametricity/)

* Exploiting Parametricity

  * $f: \forall \alpha. \alpha \to \alpha$ is logically equivalent to the identity function $\Lambda \alpha. \lambda x. x \in [\forall \alpha. \alpha \to \alpha]$
    * For every pair of types $\sigma$ & $\sigma'$ and relation $R: \sigma \leftrightarrow \sigma'$, we have $f[\sigma] \approx id[\sigma'] \in [[R \to R]]$
    * by the definition of logical equivalence at $R \to R$, iff. $\forall v_0 \sim v_0' \in [R]$ we have $f[\sigma] v_0 \approx id[\sigma'] v_0' \in [[R]]$
    * by the definition of logical equivalence at $R$, iff. $v_0 R v_0'$ implies $f[\sigma] v_0 \mapsto^* w, id[\sigma'] v_0' \mapsto^* w'$ and $w R w'$
    * by the rule of evaluation, iff. $f[\sigma]v_0 \mapsto^* w_0$ and $w_0 R v_0'$ assuming $v_0 R v_0'$
    * if we can show. $f[\sigma'] v_0 \mapsto^* v_0$
    * by the parametricity theorem, using a well-chosen relation $S$, $f \sim f \in [\forall \alpha. \alpha \to \alpha]$ by parametricity
    * where $S: \sigma \leftrightarrow \sigma$ such that $v_0 S v_0$ for the specific $v_0$
    * then $f[\sigma] \approx f[\sigma] \in [[S \to S]]$ by definition of $\sim$ at polymorphic type
    * then by definition of logical equality at function type & assumption $v_0 S v_0$, $f[\sigma] v_0 \approx f[\sigma] v_0 \in [[S]]$
    * then $f[\sigma] v_0 \mapsto^* w_0$ and $w_0 S w_0$
    * by definition of $S$, $S$ only relates $v_0$ to itself, $w_0 = v_0$
    * therefore $f[\sigma]v_0 \mapsto^* v_0$
    * Q.E.D.

* Theorems for Free

  * From $f: \forall \alpha. \alpha \to \alpha$,
    * by parametricity, $f \sim f \in [\forall \alpha. \alpha \to \alpha]$
    * pick types $\tau, \tau'$, relation $R$ which is in fact a function $R: \tau \to \tau'$
      * evaluation of $R$ as closing the cooresponding relation under Kleene equality
    * then $f[\tau] \approx f[\tau'] \in [[R \to R]]$
    * for arbitrary values $v : \tau, v' : \tau'$, $v R v'$ means $R v \mapsto^* v'$
    * by definition of $\sim$ at function type, $f[\tau] v \approx f[\tau'] (R v) \in [[R]]$
    * then $R(f[\tau] v) \mapsto^* w$ and $f[\tau'](R v) \mapsto^* w$ for some value $w$
    * For any function $R: \tau \to \tau'$, $R \circ f[\tau] = f[\tau'] \circ R$
      * commutes with any function $R$
    * If $\tau$ is non-empty, we have $v_0 : \tau$, choose $\tau' = \tau, R = \lambda x. v_0$
    * then $R(f[\tau] v) \mapsto^* v_0$, $f[\tau](R v_0) \mapsto^* f[\tau] v_0$
    * therefore $f[\tau] v_0 \mapsto^*$, since $v_0$ is arbitrary, says $f$ behaves like the identity function

* [parametricity-transcript](http://www.ccs.neu.edu/home/matthias/369-s10/Transcript/parametricity.pdf)

* ```haskell
  -- ∀a. a -> a
  	f ℛ(∀a. a -> a) f
  -- parametricity
  iff  forall A, A', a :: A ⇔ A'.
         f@A ℛ(a -> a) f@A'
  -- definition for function types
  iff  forall A, A', a :: A ⇔ A', x :: A, x' :: A'.
         if x ℛ(a) x' then f x ℛ(a) f x'
  -- pick a⃯ :: A -> A'
       forall x, x'.
         if x ℛ(a⃯) x' then f x ℛ(a⃯) f x'
  -- x ℛ(a⃯) x' iff a⃯ x ≡ x'
  iff  forall x :: A, x' :: A'.
         if a⃯ x ≡ x' then a⃯ (f x) ≡ f x'
  -- simplify
  iff  forall x :: A,
         a⃯ (f x) ≡ f (a⃯ x)
                
  -- ∀a. a -> a -> a
       f ℛ(∀a. a -> a -> a) f
  iff  forall A, A', a :: A ⇔ A'.
         f@A ℛ(a -> a -> a) f@A'
  -- applying the rule for functions twice
  iff  forall A, A', a :: A ⇔ A', x :: A, x' :: A', y :: A, y' :: A'.
         if x ℛ(a) x', y ℛ(a) y' then f x y ℛ(a) f x' y'
       forall x :: A, x' :: A', y :: A, y' :: A'.
         if x ℛ(a⃯) x', y ℛ(a⃯) y' then f x y ℛ(a⃯) f x' y'
  -- a⃯ is a function :: A -> A'
  iff  forall x :: A, y :: A.
         if a⃯ x ≡ x' and a⃯ y ≡ y' then a⃯ (f x y) ≡ f x' y'
  -- simplify
  iff  a⃯ (f x y) = f (a⃯ x) (a⃯ y)
  
  -- ∀ab. a -> b
       f ℛ(∀ab. a -> b) f
  -- applying the rule for universal quantification, twice
  iff  forall A, A', B, B', a :: A ⇔ A', b :: B ⇔ B'.
         f@A,B ℛ(a -> b) f@A',B'
  -- applying the rule for functions
  iff  forall A, A', B, B', a :: A ⇔ A', b :: B ⇔ B', x :: A, x' :: A'.
         if x ℛ(a) x' then f x ℛ(b) f x'
  -- Picking two functions a⃯ :: A -> A' and b⃯ :: B -> B' for a and b, we get
  -- b⃯ . f = f . a⃯
  ```

* ![image-20191230235517816](D:\OneDrive\Pictures\Typora\image-20191230235517816.png)

* [Theorems for free](https://ttic.uchicago.edu/~dreyer/course/papers/wadler.pdf)



## Data Abstraction

* ![image-20191231001130008](D:\OneDrive\Pictures\Typora\image-20191231001130008.png)
* existenial type
  * ![image-20191231001846030](D:\OneDrive\Pictures\Typora\image-20191231001846030.png)
  * ![image-20191231001858548](D:\OneDrive\Pictures\Typora\image-20191231001858548.png)
* typing/static: ![image-20191231001207741](D:\OneDrive\Pictures\Typora\image-20191231001207741.png)
* pattern match: ![image-20191231001222806](D:\OneDrive\Pictures\Typora\image-20191231001222806.png)
  * ![image-20191231001727933](D:\OneDrive\Pictures\Typora\image-20191231001727933.png)
  * ![image-20191231001800413](D:\OneDrive\Pictures\Typora\image-20191231001800413.png)
  * ![image-20191231001805085](D:\OneDrive\Pictures\Typora\image-20191231001805085.png)
* operational rules ![image-20191231001817199](D:\OneDrive\Pictures\Typora\image-20191231001817199.png)
* logical equality for extensional types
  * ![image-20191231001943069](D:\OneDrive\Pictures\Typora\image-20191231001943069.png)
  * [$R: bin \leftrightarrow nat$](https://www.cs.cmu.edu/~fp/courses/15814-f19/lectures/18-independence.pdf)



## Shared Memory Concurrency

* > The main objective of this lecture is to start making the role of memory explicit in a description of the dynamics of our programming language. Towards that goal, we take several steps at the same time: 
  >
  > 		1. We introduce a translation from our source language of expressions to an intermediate language of concurrent processes that act on (shared) memory. The sequential semantics of our original language can be recovered as a particular scheduling policy for concurrent processes. 
  >   		2. We introduce a new collection of semantic objects that represent the state of processes and the shared memory they operate on. The presentation is as a substructural operational semantics [Pfe04, PS09, CS09] 
  >   		3. We introduce destination-passing style [CPWW02] as a particular style of specification for the dynamics of programming languages that seems to be particularly suitable for an explicit store.

* Representing the Store

  * cell $c_i W_i$, cell $c$ contains $W$, or the memory at address $c$ holds $W$
  * ![image-20191231144105373](D:\OneDrive\Pictures\Typora\image-20191231144105373.png)

* From Expressions to Processes

  * A process $P$ executes & writes the result of computation to a destination $d$ which is the address of a cell in the memory
    * $[[e]] d = P$: expression $e$ translates to a process $P$ that computes with destination $d$
  * $\Gamma \vdash e : \tau \Rightarrow \Gamma \vdash P :: (d : \tau)$
    * ![image-20191231144917198](D:\OneDrive\Pictures\Typora\image-20191231144917198.png)
  * `proc d P`: $P$ is executing with destination $d$
  * uninitialized cells `cell d _`

* Allocation & Spawn

  * processes: Process $P ::= x \leftarrow P; Q \mid \ldots$
    * allocates new cell in memory
    * spawn a process whose job it is to write to this cell
  * More specifically, a new destination d is created, P is spawned with destination d, and Q can read from d.
    * ![image-20191231145913108](D:\OneDrive\Pictures\Typora\image-20191231145913108.png)
    * $\mathcal{C}$: configuration, includes the representation of memory & pther processes may executing
  * ![image-20191231145948900](D:\OneDrive\Pictures\Typora\image-20191231145948900.png)

* Copying

  * $[[x]] d = d \leftarrow x$: copies contents of the cell at address $x$ to address $d$
  * ![image-20191231150052125](D:\OneDrive\Pictures\Typora\image-20191231150052125.png)
  * ![image-20191231150057965](D:\OneDrive\Pictures\Typora\image-20191231150057965.png)
  * ![image-20191231150104548](D:\OneDrive\Pictures\Typora\image-20191231150104548.png)

* Unit Type

  * ![image-20191231150116845](D:\OneDrive\Pictures\Typora\image-20191231150116845.png)
  * ![image-20191231150145549](D:\OneDrive\Pictures\Typora\image-20191231150145549.png)

* Eager Pairs

  * ![image-20191231150153133](D:\OneDrive\Pictures\Typora\image-20191231150153133.png)

* ![image-20191231150200133](D:\OneDrive\Pictures\Typora\image-20191231150200133.png)

* ![image-20191231150205292](D:\OneDrive\Pictures\Typora\image-20191231150205292.png)

* Garbage collection

  * > If there is an initial root destination d0 one can run a garbage collector over the configuration, including processes as well as cells. This is somewhat simpler than for many other languages because in the pure fragment we have presented so far, memory will be in the shape of a tree and memory is statically typed. This will have to be reconsidered in the presence of general recursion and also when mutable references are introduced in the future

* Concurrency

* Call-by-Value vs. Call-by-Need

  * > We have carefully written the rules so that a certain scheduling strategy will recover our previous call-by-value semantics. The idea is for an expression x ← P ; Q to compute P until it writes to x and terminates, and only then continue with Q.
    >
    > 
    >
    > Call-by-need would instead postpone the evaluation of P entirely until Q tries to access the value of x. At this point we go back and run P until it has written this value and then resume Q. Note that the next time x is referenced the cell x will hold a value so P is not re-executed, which is a core idea behind call-by-need.



## Negative Types

* functions $\tau \to \sigma$, lazy pairs $\tau \mathcal{\&} \sigma$, universal types $\forall \alpha.\tau$
* ![image-20191231150439858](D:\OneDrive\Pictures\Typora\image-20191231150439858.png)
* ![image-20191231150447636](D:\OneDrive\Pictures\Typora\image-20191231150447636.png)
* ![image-20191231154540990](D:\OneDrive\Pictures\Typora\image-20191231154540990.png)
* Functions
  * ![image-20191231162626600](D:\OneDrive\Pictures\Typora\image-20191231162626600.png)
  * ![image-20191231162635476](D:\OneDrive\Pictures\Typora\image-20191231162635476.png)





## Memory Safety

* ![image-20191231162738772](D:\OneDrive\Pictures\Typora\image-20191231162738772.png)
* ![image-20191231162749660](D:\OneDrive\Pictures\Typora\image-20191231162749660.png)
* ![image-20191231162754427](D:\OneDrive\Pictures\Typora\image-20191231162754427.png)
* Typing configurations
  * ![image-20191231162811194](D:\OneDrive\Pictures\Typora\image-20191231162811194.png)
* Presevation/Progress
  * [proof](https://www.cs.cmu.edu/~fp/courses/15814-f19/lectures/21-memsafety.pdf)



## Mutable Memory

* ![image-20191231162913986](D:\OneDrive\Pictures\Typora\image-20191231162913986.png)
* ![image-20191231162930937](D:\OneDrive\Pictures\Typora\image-20191231162930937.png)
* ![image-20191231163155138](D:\OneDrive\Pictures\Typora\image-20191231163155138.png)
* ![image-20191231163159506](D:\OneDrive\Pictures\Typora\image-20191231163159506.png)
* ![image-20191231163204298](D:\OneDrive\Pictures\Typora\image-20191231163204298.png)
* ![image-20191231163211388](D:\OneDrive\Pictures\Typora\image-20191231163211388.png)
* Race Conditions
* Linearity
  * linear: used exactly once
  * affine: used at most once
  * strict: used at least once
  * intensional property, consider $\lambda x. \text{ if } \text{ false } x$
* Linear Typing of Expressions
  * $\Delta \vdash e : \tau$: context of variables $\Delta$, each of which must be used once in $e$
  * Linear functions $\tau \multimap \sigma$: if its parameter is used linearly in its body
    * ![image-20191231163503120](D:\OneDrive\Pictures\Typora\image-20191231163503120.png)
    * ![image-20191231163527017](D:\OneDrive\Pictures\Typora\image-20191231163527017.png)
    * ![image-20191231163541712](D:\OneDrive\Pictures\Typora\image-20191231163541712.png)
  * Eager Linear Pairs $\tau \otimes \sigma$
    * ![image-20191231163626289](D:\OneDrive\Pictures\Typora\image-20191231163626289.png)
  * Linear Sums $\tau \oplus \sigma$
    * ![image-20191231163658930](D:\OneDrive\Pictures\Typora\image-20191231163658930.png)
    * ![image-20191231163708146](D:\OneDrive\Pictures\Typora\image-20191231163708146.png)
  * Recursion
    * `fix f. e` will duplicate `e` and `f`
    * must add a second, nonlinear context to the judgement, and populate it with recursively defeind variables
    * ![image-20191231163909889](D:\OneDrive\Pictures\Typora\image-20191231163909889.png)
* ![image-20191231163926070](D:\OneDrive\Pictures\Typora\image-20191231163926070.png)



## Linear Types

* $\Gamma ; \Delta \vdash P :: (z : \sigma)$
  * $\Gamma$: recursive variables/destinations
  * $\Delta$: linear variables/destinations
  * $z$: destinations written exactly once, read exactly once
* ![image-20191231164153962](D:\OneDrive\Pictures\Typora\image-20191231164153962.png)
* ![image-20191231164159768](D:\OneDrive\Pictures\Typora\image-20191231164159768.png)
* ![image-20191231164205577](D:\OneDrive\Pictures\Typora\image-20191231164205577.png)
* ![image-20191231164211537](D:\OneDrive\Pictures\Typora\image-20191231164211537.png)
* Eager Linear Pairs
  * ![image-20191231164248122](D:\OneDrive\Pictures\Typora\image-20191231164248122.png)
  * ![image-20191231164254145](D:\OneDrive\Pictures\Typora\image-20191231164254145.png)
* Linear Sums
  * ![image-20191231164304081](D:\OneDrive\Pictures\Typora\image-20191231164304081.png)
* Linear functions
  * ![image-20191231164314570](D:\OneDrive\Pictures\Typora\image-20191231164314570.png)
  * Recursion
    * ![image-20191231164326905](D:\OneDrive\Pictures\Typora\image-20191231164326905.png)



## Quotations

* model runtime code generation
* [quotation](http://www.cs.cmu.edu/~fp/courses/15814-f18/lectures/18-quotation.pdf)
* [[T: complete this]]



## Sequent Calculus

* [seqcalc](http://www.cs.cmu.edu/~fp/courses/15814-f18/lectures/20-seqcalc.pdf)

* > 1. Use introduction rules from the bottom up. For example, to prove A ∧ B true we reduce it to the subgoals of proving A true and B true, using ∧I 
  > 2. 2. Use elimination rules from the top down. For example, if we know A ∧ B true we may conclude A true using ∧E1.

* ![image-20191231164606862](D:\OneDrive\Pictures\Typora\image-20191231164606862.png)
* sequent: ![image-20191231164637800](D:\OneDrive\Pictures\Typora\image-20191231164637800.png)
  * right rules: decomposing the succedent $C$
    * introduction rules of natural deduction (bottom-up)
  * left rules: decompose the antecedents $A$
    * inverted elimination rules
  * ![image-20191231164728688](D:\OneDrive\Pictures\Typora\image-20191231164728688.png)
  * identity rule
    * ![image-20191231164738721](D:\OneDrive\Pictures\Typora\image-20191231164738721.png)
  * cut rule (converse of identity)
    * ![image-20191231165158616](D:\OneDrive\Pictures\Typora\image-20191231165158616.png)
    * introducing the lemma $A$ into a proof of $C$
    * redundant
    * [cut elimination](https://www.zhihu.com/question/54408615/answer/888472666)
* ![image-20191231165111600](D:\OneDrive\Pictures\Typora\image-20191231165111600.png)
* ![image-20191231165116609](D:\OneDrive\Pictures\Typora\image-20191231165116609.png)
* ![image-20191231165131689](D:\OneDrive\Pictures\Typora\image-20191231165131689.png)
* Soundness of the Sequent Calculus
  * whenever $\Gamma \Vdash A$ in sequent calculus then $\Gamma \vdash A$ in natural deduction
  * ![image-20191231165347724](D:\OneDrive\Pictures\Typora\image-20191231165347724.png)
* Completeness of the Sequent Calculus
  * inverse
  * ![image-20191231165709733](D:\OneDrive\Pictures\Typora\image-20191231165709733.png)
* Cut Elimination
  * prove the consistency of logic as captured in natural deduction
  * can sequent calculus enough to show we cannot prove a contradiction
  * ![image-20191231165848367](D:\OneDrive\Pictures\Typora\image-20191231165848367.png)
  * there cannot be a proof of $\cdot \Vdash \bot$
  * ![image-20191231165923647](D:\OneDrive\Pictures\Typora\image-20191231165923647.png)
  * immediately implies consistency by inversion: there is no rule with a conclusion matching $\cdot \Vdash \bot$
  * [cut elimination](http://www.cs.cmu.edu/~fp/courses/15317-f17/lectures/10-cutelim.pdf)



## Session Types

* [session types](http://www.cs.cmu.edu/~fp/courses/15814-f18/lectures/22-sessions.pdf)
* ![image-20191231170449996](D:\OneDrive\Pictures\Typora\image-20191231170449996.png)
* ![image-20191231170504744](D:\OneDrive\Pictures\Typora\image-20191231170504744.png)
* [[T: complete this]]