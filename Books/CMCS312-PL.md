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
* 