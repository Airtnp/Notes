# CMCS312 Type System and Programming Languages

## Grammar
* BNF
* Induction defintion
* + depth
* + size
* + structural
* Inference Rules
* Concrete Syntax

## Operational Semantics
* Operational Semantics
* + Big Step
* + - ⇓
```
           t1 ⇓ true             t2 ⇓ v2
-----      ------------------------------
v ⇓ v      if t1 then t2 else t3 ⇓ v2
```
* + Small Step
* + - →
```

----------------------------
if true then t2 else t3 → t2


-----------------------------
if false then t2 else t3 → t3

t1 → t1'
----------------------------------------------
if t1 then t2 else t3 → if t1' then t2 else t3
```
* + Normal form
* + - no evaluation rule applies to that term
* + - no reduction rule
* + - Stuck: normal form but not a value
* + Multi-Step Evaluation
```
t → t'                t →∗ t' t' →∗ t''
-------     ------    ----------------
t →∗ t'     t →∗ t         t →∗ t''
```

## Lambda Calculus
* inductive definition
* + x ∈ V => x ∈ T
* + t1 ∈ T, t2 ∈ T => t1 t2 ∈ T (application associates to left)
* + x ∈ V, t ∈ T => \x.t ∈ T (abstraction associates to right)
* + t1 t2 t3 => (t1 t2) t3
* + \x.x y => \x.(x, y)
* Inference defintion
```
x ∈ V
-----
x ∈ T

t1 ∈ T t2 ∈ T
--------------
t1 t2 ∈ T

x ∈ V t ∈ T
------------
\x.t ∈ T
```
* BNF definition
* + `t ::= x | t1t2 | \x.t`
* Bound/Free variable
* + x ∈ V => FV(x) = {x}
* + t1, t2 ∈ T => FV(t1 t2) = FV(t1) + FV(t2)
* + t ∈ T, x ∈ V => FV(\x.t) => FV(t) - {x}
* Substitution
* + `[x -> t']t / [t'/x]t`
* Alpha-conversion
* + `t1 =α t2`
* + `λx.x =α λy.y`
* + `λx.λy.λz.x y z =α λz.λy.λx.z y x`
* + `λx.t =α λy.[y/x]t if y !∈ FV(t)`
* Beta-reduction
* + not reflexive
* + not symmetric
* + not transitive
* + `(λx.t1) t2 →β [t2/x]t1` (single-step)
* + `t →∗β t` (multi-step)
* + `t =β t` (equivalence, ref/sym/trans)
> Definition. We write M =β M′ if M can be transformed into M′ by zero or more reduction steps and/or inverse reduction steps. Formally, =β is defined to be the reflexive symmetric transitive closure of →β, i.e., the smallest equivalence relation containing →β.
* multiple arguements
* Church boolean
* + `T = \x -> \y -> x`
* + `F = \x -> \y -> y`
* + `If = \x -> \y1 -> \y2 -> x y1 y2`
* + `Not = \x -> \y -> \z -> x z y`
* + `And = \x1 -> \x2 -> x1 x2 F`
* + `Or = \x1 -> \x2 -> x1 T x2`
* + `Pair = \x1 -> \x2 -> \y -> y x1 x2`
* + `Fst = \p -> p (\x -> \y -> x) = \p -> p T`
* + `Snd = \p -> p (\x -> \y -> y) = \p -> p F`
* Church Numeral
* + `N = \s -> \z -> s (N-1 s z)`
* + `0 = \s -> \z -> z`
* + `IsZero = \n -> n (\x F) T`
* + `Succ = \n -> \s -> \z -> n s (s z)`
* + `Pred = \n -> \s -> \z -> n (\g h -> h (g s)) (\u -> z) (\u -> u)`
* + `Plus = \m -> \n -> \s -> \z -> m s (n s z) = (n Succ m) s z`
* + `Subt = \m -> \n -> \s -> \z -> (n Pred m) s z`
* + `Time = \m -> \n -> m (Plus n) 0 = \m -> \n -> \s -> \z -> m (\l -> \s -> \z -> n s (l s z)) 0`
* + `Expo = \m -> \n -> n (Time m) 1 = \m -> \n -> \s -> \z -> (\f' -> m n f') s z`
* Recursion
* + `Omega = (\x -> x x) (\x -> x x)`
* + `Y = λf. (λx. f (x x)) (λx. f (x x))`
* + `Y g =β g (Y g)`, but `Y g not ->*β g (Y g)`
* + Call-by-name, ok. Call-by-value (calculate parameter first), diverged.
* + [求值策略](https://zh.wikipedia.org/wiki/%E6%B1%82%E5%80%BC%E7%AD%96%E7%95%A5#%E4%BC%A0%E5%90%8D%E8%B0%83%E7%94%A8)
* + `Z = λf. (λx. f (λy. x x y))(λx. f (λy. x x y))` (Also called Theta)
* + `Z g v ->* β g (Z g) v ->*β g (g (Z g)) v`
* + suspends evaluation of the fix point operator until it is applied by g.
> Y f is (beta) reduce to, but does not (beta) equivalent to f (Y f), nor the other way round. On the other hand, \Theta f does (beta) reduce to f (\Theta f). Note that \Theta \equiv Y (S I).
* + [LC-Intro-I](https://zhuanlan.zhihu.com/p/25559133)
> 例如，在Standard ML中Y组合子的传值调用变体有类型∀a.∀b.((a→b)→(a→b))→(a→b)，而传名调用变体有类型∀a.(a→a)→a。传名调用（正规）变体在应用于传值调用的语言的时候将永远循环下去 -- 所有应用Y(f)展开为f(Y(f))。按传值调用语言的要求，到f的参数将接着展开，生成f(f(Y(f)))。这个过程永远重复下去（直到系统耗尽内存），而不会实际上求值f的主体。
> Y组合子的可以在传值调用的应用序求值中使用的变体，由普通Y组合子的部分的η-展开给出Z
```javascript
U = g => g(g) // recursion is strict, must curry
Y = g => g( () => Y(g) ) // we made the recursion 'lazy'
Z = g => v => g(Z(g))(v) // explicit currying makes it 'lazy'
```
* de Bruijn Indices
* + AST (with symbol) => Graph (connect bound variable - free variable) => de Bruijn graph
* + `dB(Γ, x) = Γx` (smallest index in this context)
* + `dB(Γ, \x.t) = \x. dB((Γ, x), t)`
* + `dB(t1 t2) = dB(t1) dB(t2)`
* + [ref](https://acemerlin.github.io/posts/%E8%AE%A1%E7%AE%97%E7%9A%84%E6%9C%AC%E8%B4%A8/2017-04-10-introduction-to-computation-part-2/)
* + Shift
* + `[↑d, c]`, c means context
```
[↑d, c](i) = i                        if i < c
[↑d, c](i) = i + d                    if i ≥ c
[↑d, c](λ.t) = λ. [↑d, c+1](t)
[↑d, c](t1 t2) = ([↑d, c](t1)) ([↑d, c](t2))

-- [↑d, c]t
termShift d t = walk 0 t where
    walk :: Int -> Term -> Term
    walk c t' = case t' of
        TmVar i n   -> if i >= c then TmVar (i + d) (n + d) else TmVar i (n + d)
        TmAbs s t1  -> TmAbs s $ walk (c + 1) t1
        TmApp t1 t2 -> TmApp (walk c t1) (walk c t2)
```
* + Substitution
```
[t/j]i = t                          if i = j
[t/j]i = i                          if i not = j
[t/j]λ.t0 = λ.[[↑1, 0](t)/j + 1] t0
[t/j]t1 t2 = [t/j] t1 [t/j] t2

-- [j -> s]t
termSubst j s t = walk 0 t where
    walk c t' = case t' of
        TmVar i n   -> if i == (j + c) then termShift c s else TmVar i n
        TmAbs s t1  -> TmAbs s $ walk (c + 1) t1
        TmApp t1 t2 -> TmApp (walk c t1) (walk c t2)

-- beta reduction
-- (\x -> t) v => [↑-1, 0]([0 -> [↑1, 0](v)](t))
-- (\x. y x z) (\x. x) => (\.1 0 2)(\. 0) => 0 (\. 0) 1 (not 1 (\. 0) 2)
termSubstTop s t = 
    termShift (-1) (termSubst 0 (termShift 1 s) t)
```
* Call-by-value / Call-by-name
* + Operational semantics
* STLC
* + Value `v ::= T | F | \x.t`
* + Term `t ::= v | if t then t else t | t t`
* + Context `Γ ::= ∅ | Γ, x : τ`
* + Type `τ ::= bool | τ1 -> τ2`

## Type Safety
* + progress
* + - `t:τ => t ∈ v | t -> t'`
* + - should be proved by every term:type
* + preservation
* + - `Γ |- t:τ & t -> t' => Γ |- t':τ`
* + - should be proved by every term:type
* + substituion
* + - `Γ, x:τ1 |- t:τ2 & Γ |- t1:τ1 => Γ |- [t1/x]t:τ2`
* + inversion
* + canonical forms
* + permutation
* + weakening

## Curry-Howard Isomorphism
* phase distinction
* + static phase (typing rules)
* + dynamic phase (evaluating)
* constructive logics
* + P V /P = T not hold
* propositions = types
* + `P => Q = P -> Q`
* + `P ∧ Q => P x Q`
* + proof of proposition P = terms of type P
* + proposition P is provable = type P is inhabited by some term
* different logic => different type system
* + linear logic => linear type system
* STLC
```
Types       τ ::= unit | nat | τ1 → τ2
Numbers     n ::= 0 | 1 | ...
Prim op’s   o ::= + | − | ×
Values      v ::= ? | n | λx : τ.t
Terms       t ::= x | v | o(t, t) | t t
Context     Γ ::= ∅ | Γ, x : τ
```
* + type rules
* + - unit/naturals/variables/prim. ops/lambda/app

## Extension
* let binding
* + `t ::= ... | let x : τ1 = t in t end`
* + eval rules
* + - substitution(preservation)/progress
* + type inference rules
* + - application rule
* + `let x:τ1 = t1 in t2` = `(\x:τ1. t2) t1`
* + elaboration function
* + - external language (with extra defs) => internal language (original)
* + - `η : te |→ ti`
* + - `Γ |-e te : τ` if and only if `Γ |-i (η(te)) : τ`
* + - `t1e ->e t2e` if and only if `η(te1) ->i η(te2)`
```
η(v) = v
η(t1 t2) = η(t1) η(t2)
η(let x : τ = t1 in t2 end) = (λx : τ1.η(t1)) (η(t2))
```
* pair & product
* + `τ ::= ... | τ × τ`
* + `t ::= ... | <t, t> | first(t) | second(t)`
* + typing rules
* + - pair/project-1/project-2
* + evalutaion rules (call-by-value, only have t->t' => o(t) -> o(t'))
* + - substitute-1/-2/-first/-second/first/second
* heterogeneous & sum
* + `τ ::= ... | τ1 + τ2`
* + `v ::= inl_{τ1+τ2}(v) | inr_{τ1+τ2}(t)`
* + `t ::= inl_{τ1+τ2}(t) | inr_{τ1+τ2}(t) | (case t1 of inl(x) ⇒ t2 | inr(x) ⇒ t3)`
* + typing rules
* + - sum/case
* + evaluation rules
* + - substitute-inl/-inr/-case/application
* recursion
* + `fix f(x) : τ is t end`
* + `t ::= ... | fix f(x) : τ1 → τ2 is t end`
* + `v ::= ... | fix f(x) : τ1 → τ2 is t end`
```
Γ, f : τ1 → τ2, x : τ1 |- t : τ2
---------------------------------
Γ |- fix f(x) : τ1 → τ2 is t end : τ1 → τ
```
* + evaluation rule
* + - substitute/[v/fix...]t


## Reference
* reference
* + create `r = ref v` (can be a pointer)
* + deference `!r`
* + assignmnet `r := v` (return unit)
* + type `τ ref`
* + deallocate `dealloc r`
* + `τ ::= unit | τ → τ | ref τ`
* + `v ::= * | fix f(x : τ1) : τ2 is t end | l`
* + `t ::= v | x | t t | ref t |!t | t := t`
* + store (memory context)
* + - `σ : L → v`
* + - `Λ : L → τ`
* + typing rules
* + evaluation rules
* + make aliasing and side-effect, so optimization down (restrict pointer)
* + recursion via backpatching
```
(* a non-terminating function on naturals, nat -> nat *)
fun loop (x:nat) : nat = loop x
(* create a reference to this function *)
val r = ref loop
fun fact n = if n = 0 then 1
else n * ((!r) (n-1))
val _ = r := fact
```
* + array
```
(* A nat array is a function from a given index to a nat *)
type natArray = ref (nat -> nat)
(* returns a function that returns 0 for each index *)
fun new (): natArray = ref (fn n:nat. 0)
(* the lookup function takes and array and an index and applies the array to the index *)
lookup a i = (!a) i
update a i v =
    let val oldArray = !a
        fun newArray n = if n = i then v
                        else oldArray n
```

## Polymorphism
* System F/Polymorphic Typed lambda-calculus/Second order lambda calculus
* `τ ::= α | τ1 → τ2 | ∀α.τ`
* expression `e ::= x | λx : τ1.e | e1 e2 | Λα.e | e[τ]`
* static type variable context
* + `∆ = α1 type, α2 type, α3 type, ...`
* + `∆ |- τ` indicates `τ` is a well-defined type under context `∆`
* + `∆; Γ |- e : τ` indicates `e` has type `τ` under context `∆` (finite set of type variable : type) and `Γ` (finite set of expressions : type)
```
id = Λα.λx : α.x
```
* dynamic call-by-value small-step
* + `v ::= λx : τ1.e | Λα.e`
* Church Encoding
* + [ref](https://www.zhihu.com/question/39930042)
* + `τ = ∀α.(ctor1 type → α) → (ctor2 type → α) → α`
* + `t = Λα.(ctor) → α`
```
unit    ≡ ∀α.α → α
        ≡ Λα.∀x : α.x
bool    ≡ ∀α.α → α → α
true    ≡ Λα.∀x : α.∀y : α.x
false   ≡ Λα.∀x : α.∀y : α.y
if e0 then e1 else e2 ≡ e0[τ]e1e2

τ1 + τ2 ≡ ∀α.(τ1 → α) → (τ2 → α) → α
inle    ≡ Λα.λfl : τ1 → α.λfr : τ2 → α.fl(e)
inre    ≡ Λα.λfl : τ1 → α.λfr : τ2 → α.fr(e)
case e of inlx:τ1 ⇒ e1 : τ | inry:τ2 ⇒ e2 : τ ≡ e[τ](λx : τ1.e1)(λy : τ2.e2)

τ1 × τ2  ≡ ∀α.(τ1 → τ2 → α) → α
<e1, e2> ≡ Λα.λp : τ1 → τ2 → α.p e1 e2
fst(e)   ≡ e[τ1] (λx : τ1 : λy : τ2.x)
snd(e)   ≡ e[τ2] (λx : τ1 : λy : τ2.y)

```

```haskell
-- Polymorphism
    -- In general, the context now associates each free variable with a type scheme, not just a type.
    -- \Gamma |- t : S | C
    -- (\sigma, T) ==> \sigma satisfy C and \sigma S = T
    -- unificaiton
    -- principle types
    -- let polymorphism
    -- 1. We use the constraint typing rules to calculate a type S1 and a set C1 of associated constraints for the right-hand side t1.
    -- 2. We use unification to find a most general solution σ to the constraints C1 and apply σ to S1 (and Γ) to obtain t1’s principal type T1.
    -- 3. We generalize any variables remaining in T1. If X1. . .Xn are the remaining variables, we write ∀X1...Xn.T1 for the principal type scheme of t1
    -- 4. We extend the context to record the type scheme ∀X1...Xn.T1 for the bound variable x, and start typechecking the body t2. In general, the context now associates each free variable with a type scheme, not just a type.
    -- 5. Each time we encounter an occurrence of x in t2, we look up its type scheme ∀X1...Xn.T1. We now generate fresh type variables Y1...Yn and use them to instantiate the type scheme, yielding [X1 , Y1, ..., Xn , Yn]T1, which we use as the type of x.

-- System F
    -- \lambda X.t t[T] type abstraction
    -- Universal type
    -- Existential type
        -- {*S, t} as {\exists X, {t : X}} S satisfy X
        -- {\exists X, T} === \forall Y. (\forall X. T -> Y) -> Y
        -- {*S, t} as {\exists X, T} === \lambda Y. \lambda f : (\forall X. T -> Y). f[S] t
        -- let {X, x} = t1 in t2 === t1 [T2] (\lambda X. \lambda x : T11. t2)
        -- counterADT = {*Nat, {new = 1, get = \i:Nat i, inc = \i:Nat, succ(i)}}
            -- counterADT : {\exists Counter, {new:Counter, get:Counter->Nat}, ...}
            -- let {Counter, counter} = counterADT in ....
            -- Counter is ADT, counterADT is OOP

-- System F_{<:}
    -- \lambda X <: T. t
    -- \forall X <: T. T
    -- \Gamma, X <: T

-- System F_{\omega}
    -- X: Kind
    -- \lambda X::K.T
    -- \Gamma, X::K
    -- * / K -> K
    -- \forall X :: K. T ===>(K == *) \forall X . T
    -- |\exists X :: K, T| ===>(K == *) |\exists X, T|

-- Lambda Cube
    -- ref: https://cs.stackexchange.com/questions/49189/what-terms-type-systems-exclude/49381#49381
    -- ref: https://cstheory.stackexchange.com/questions/36054/how-do-you-get-the-calculus-of-constructions-from-the-other-points-in-the-lambda/36058#36058
    -- ref: https://stackoverflow.com/questions/21219773/are-ghcs-type-famlies-an-example-of-system-f-omega
    -- terms depend on terms (normal functional programming) \x -> x
    -- terms depend on types (polymorphism) Head : [X] -> X
    -- types depend on types (type operator / type families) List<T> : X -> [X] K1 -> K2 (and can direct operator it, like <template<typename ...> typename>)
    -- types depend on terms (dependent types) Array<U, N> : N -> U^N

    -- λ→ (Simply-typed lambda calculus)
        k ::= ∗
        A ::= p | A → B
        e ::= x | λx:A.e | e e
    -- λω_ (STLC + higher-kinded type operators)
        k ::= ∗ | k → k
        A ::= a | p | A → B | λa:k.A | A B
        e ::= x | λx:A.e | e e
    -- λ2 (System F: STLC + poly)
        k ::= ∗
        A ::= a | p | A → B  | ∀a:k. A 
        e ::= x | λx:A.e | e e | Λa:k. e | e [A]
        -- can represent \x. x x
    -- λω (System F-omega: STLC + poly(parametric) + type operator)
        k ::= ∗ | k → k 
        A ::= a | p | A → B  | ∀a:k. A | λa:k.A | A B
        e ::= x | λx:A.e | e e | Λa:k. e | e [A]
    -- λP (LF: STLC + dependent type)
        -- Πx:A. B(x) (arugment in return type)
        k ::= ∗ | Πx:A. k 
        A ::= a | p | Πx:A. B | Λx:A.B | A [e]
        e ::= x | λx:A.e | e e
    -- λP2 (no special name: + dt + poly)
        k ::= ∗ | Πx:A. k 
        A ::= a | p | Πx:A. B | ∀a:k.A | Λx:A.B | A [e]
        e ::= x | λx:A.e | e e | Λa:k. e | e [A]
    -- λPω_ (no special name: + dt + type operator)
        k ::= ∗ | Πx:A. k | Πa:k. k'
        A ::= a | p | Πx:A. B | Λx:A.B | A [e] | λa:k.A | A B 
        e ::= x | λx:A.e | e e 
    -- λPω (the Calculus of Constructions: all)
        k ::= ∗ | Πx:A. k | Πa:k. k'
        A ::= a | p | Πx:A. B | ∀a:k.A | Λx:A.B | A [e] | λa:k.A | A B 
        e ::= x | λx:A.e | e e | Λa:k. e | e [A]

    -- what's not include is subtyping (X <: Y)
    -- HM is part of System F

-- System F^{\omega}_{<:}
```

## Existential Type
* Universal type
* + `∀α.τ`
* + if you have any type `σ` (i.e., for all types `σ`), then the expression e must have that type, i.e., `τ[σ/α]`.
* + Operationally, we think of an expression of universal type as a suspended computation Λα.e that when applied to any type σ would give us an expression that is customized for that type
* impredicative polymorphism / quantification
* + `true[type] -> bool` and `false[type] -> bool`
* + unbound type
```
τ := ∀α.α → α
e : τ => e[τ] : (α → α)[τ/α] => (∀α.α → α) -> (∀α.α → α)
```
* predicative polymorphism
* + expression e of type `∀α.τ` to be applied only un-quantified types, or types that are quantifier-free
* prenex polymorphism
* + For the sake of type inference, languages like ML only permit an even more restricted form of polymorphism, called prenex polymorphism that allows quantifiers to occur only at the outermost level of a type.
* + `Mono τ ::= α ::= τ1 → τ2`
* + `Poly σ ::= τ | ∀α.σ`
* Existential type
* + `∃α.τ`
* + there exists some type `σ` such that `e : τ[σ/α]`.
* + Operationally, you can think of `e` this as a pair that consists of a witness type `σ` (that is hidden by `α` in the existential type `∃α.τ`), and an expressions `e1` of type `τ[σ/α]`
* + `pack σ with e as ∃α.τ`
* + - instantiation of existential type `e : τ[σ/α]`
* + `unpack e1 as α, x in e2`
* + - unpack type match
```
pack nat with {a = 5, f : λx : nat.succ(x)} : ∃α.{a : nat, f : nat → nat}
                                            : ∃α{a : α, f : α → α}
                                            : ∃α{a : α, f : α → nat}

pack nat with 0 as ∃α.α : ∃α.α
pack bool with true as ∃α.α : ∃α.α
pack bool with {a = true, f = λx : bool.1} as ∃α.{a : α, f : α → nat}
```
* + `e ::= ... | pack σ with e as ∃α.τ | unpack e1 as α, x in e2`
```
let counterADT =
    pack {int, { new = 0, get = λi:int. i, inc = λi:int. i + 1 } }
    as ∃Counter. { new : Counter, get : Counter → int, inc : Counter → Counter }
in ...

unpack {C, c} = counterADT in
    let y = c.new in
        c.get (c.inc (c.inc y))

COUNTER = ∃counter. {c : counter, get : counter → nat, inc : counter → counter}
cntr1 = pack nat with {c = 0, get = λx : nat.x, inc = λx : nat.x + 1} as COUNTER
unpack cntr1 as α, x in x.get (x.inc x.c)
unpack cntr1 as α, x in
    let add3 = λc : α. x.inc (x.inc (x.inc c)) in
        x.get (add3 x.c)
```
* existential as universial
```
∃α.τ                    ≡ ∀β. (∀α. τ → β) → β
pack σ, e as ∃α. τ      ≡ Λβ. λc:(∀α.τ → β). c[σ] e
unpack e as α, x in ec  ≡ e [τc] (Λα. λx:τ. ec)
```


## Parametricity
* representation independence
* + the behavior of the client does not depend on the particular representation of an existential type
* equivalence
* + godel's T
* + expression context
```
Program Contexts C ::= succ C | λx.C | C1 e2 | e1 C2 |
                       rec C { zero ⇒ e0 | succ x with y ⇒ e1}
                       rec e { zero ⇒ C0 | succ x with y ⇒ e1} |
                       rec e { zero ⇒ e0 | succ x with y ⇒ C1}
|- C : (Γ |> τ) ~> (Γ' |> τ')
if Γ |- e : τ then Γ' |- C[e] : τ'.
Γ' |- C : (Γ |> τ) ~> τ'.
```
* + observational(contextual) equivalence
* + - `Γ |- e1 ∼obs e2 : τ` 
* + - `=def ∀C. |- C : (Γ |> τ) ~> nat ⇒ C[e1] →∗ z` if and only if `C[e2] →∗ z`
* + congruence
* + - If `Γ |- e1 ∼obs e2 : τ` and `C : (Γ |> τ) ~> (Γ' |> τ')` then `Γ' |- C[e1] ∼obs C[e2] : τ'`
* + logical equivalence
* + - `e ∼ e' : τ`
* + - closed term def
```
e ∼ s' : nat if and only if
e →∗ z and e' →∗ z or e →∗ succ e1 and e' →∗ succ e1' and e1 ∼ e1' : nat

e ∼ e' : τ1 → τ2 if and only if
∀e1, e1. e1 ∼ e1' : τ1 ⇒ e e1 ∼ e' e1' : τ2
```
* + - separate value def
```
v ≈ v0 : nat if and only if
v = v0 = zero or v = succ v1 ∧ v0 = succ v10 ∧ v1 ≈ v10 : nat.

λx : τ1.e ≈ λx : τ1.e' : τ1 → τ2 if and only if
∀v1, v1' .v1 ≈ v1' : τ1 ⇒ e[v1/x] ∼ e'[v1' /x] : τ2
```
* + - substituion def
```
γ ≈ γ' : Γ 
    =def dom(γ) = dom(γ') = dom(Γ) ∧
    ∀x ∈ dom(Γ). γ(x) ≈ γ'(x) : Γ(x)
```
* + - open terms def
```
Γ |- e ∼ e' : τ 
    =def ∀γ, γ'.γ ≈ γ' : Γ ⇒ γ(e) ∼ γ(e') : τ
```
* + fundamential property (Reynold's Abstraction Theorem)
* + - reflexive
* + soundness
* + - logical <=> observational
* + free theorem
* + - If `e : ∀α.α → α` and `v : τ`, then `e[τ] v →∗ v`.
* + - [free-for-fmap](https://www.schoolofhaskell.com/user/edwardk/snippets/fmap)
```
R : σ ↔ σ' iff ∀(v, v') ∈ R. |- v : σ ∧ |- v' : σ'

v ≈ v' : α | η                             iff η(α) = (τ, τ', R) ∧ (v, v') ∈ R
Λα. e ≈ Λα. e' : ∀α. τ | η                 iff ∀σ, σ', R. R : σ ↔ σ' ⇒ e[σ/α] ∼ e'[σ'/α] : τ | η[α |→ (σ, σ', R)]
λx:η1(τ1). e ≈ λx:η2(τ1). e' : τ1 → τ2 | η iff ∀v, v'. v ≈ v' : τ1 | η ⇒ e[v/x] ∼ e'[v'/x] : τ2 | η

∆; Γ |- e ∼ e :' τ                         iff ∀η, γ, γ'. η |= ∆ ∧ γ ≈ γ' : Γ | η ⇒ γ(η1(e)) ∼ γ'(η2(e')) : τ | η
```
* [ref](https://www.well-typed.com/blog/2015/05/parametricity/)
* [ref-2](https://www.well-typed.com/blog/2015/08/parametricity-part2/)