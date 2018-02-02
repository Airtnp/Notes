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