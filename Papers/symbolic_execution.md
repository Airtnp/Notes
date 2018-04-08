# Symbolic Execution

* [klee-on-maze](https://feliam.wordpress.com/2010/10/07/the-symbolic-maze/)

## KLEE: Unassisted and Automatic Generation of High-Coverage Tests for Complex Systems Programs
* LLVM assembly (LLVM bitcode)
* state: representation of a symbolic process
* conditional branches => boolean expression => constraint solver
* + clone if both accessible
* + error => negation => generate testcases + terminate this state
* + load/store => boundary check => flat array
* + - every memory object => distinct STP array (flat address space)
* memory management
* + pointer aliasing
* + - When a dereferenced pointer p  can refer to N objects, KLEE clones the current state N times. In each state it constrains p to be within bounds of its respective object and then performs the appropriate read or write operation.
* + - copy-on-write at object level
* + heap as immutable map, portions of the heap structure itself can also be shared amongst multiple states. heap structure can be cloned in constant time
* + contrats to EXE (native OS process per state)
* query optimization (optimizing NP-hard)
* + expression rewriting
* + - as in compilers, arithmetic simplification
* + constraint set simplification
* + - rewriting previous constraints when new equality constraints are added to the constraint set. In this example, substituting the value for x into the first constraint simplifies it to true, which KLEE eliminates.
* + implied value concretization
* + - constraint: (x + 1 == 10) => concrete x = 9
* + counter-example cache
* + -  The counter-example cache maps sets of constraints to counter-examples (i.e., variable assignments), along with a special sentinel used when a set of constraints has no solution.   This mapping is stored in a custom data structure — derived from the UBTree structure of Hoffmann and Hoehler [28] — which allows efficient searching for cache entries for both subsets and supersets of a constraint set.
