# Efficient Implementation of the Smalltalk-80 System

**L.Peter Deutsch, Allan M. Schiffman**

---



## Introduction

* Smalltalk-80 (trademark of the Xerox Corporation)

  * dynamic storage allocation
  * full upward funargs ([funarg problem](https://en.wikipedia.org/wiki/Funarg_problem)) / closures
  * universally polymorphic procedures
  * interactive execution with incremental compilation
  * implementation portability

* optimizing techniques: represent certain runtime state (code/data) in more than 1 form, convert between forms when needed

* virtual machine/v-machine: bytecode, or interpret-like arch (like Pascal P-system)

* runtime state (procedure activations) visible to the programmers as data objects

  * like Spaghetti stack

  * > A [SpaghettiStack](https://wiki.c2.com/?SpaghettiStack) is a stack structure in which the frames that are pushed onto the stack are not destroyed when they are popped. Instead, they persist indefinitely, and continue to refer to the parent frames. They can be re-visited and popped again.

* generic data types through message-passing & dynamic typing

  * procedure (method), a message sent to a data object (receiver),, which selects the method to be executed
  * method address at runtime
  * lexical point? only message name (selector) is known
  * inheritance complication

* information hiding: make procedure calls to access state (Pascal compile a direct access to a field of a record)

* conform to v-machine specification, but suitable for conventional hardware

* dynamic change of representation: same information is represented in 1+ (structurally different) way during its lifetime

  * converted transparently between representations as needed for efficient use at any moment
  * caching
  * dynamically translate v-code (v-machine ISA) into code on hardware without interpretation (n-code)
    * cached, re-generated rather than paged
  * procedure activation recrods (contexts) in machine-oriented form / form of Smalltalk-80 data objects
  * different caches to speep up polymorphic search required
  * represent reference count information efficiently



## Code Translation

* v-code: avoid multiple (1 per target machine) code-generation phases of the compiler
* v0machine attractive in reducing the cost of re-hosting



### Performance Issues

* rehost: emulate the v-machine on the target hardware
  * microcode / software
* performance penalty
  * processors have specialized hardware for fetching, decoding, dispatching own native instruction
    * not available to programmer
    * not useful to v-machine interpreter in its time consuming operations of instruction fetching, decoding, dispatching
    * [[R: like SIMD? -march=native?]]
  * v-machine architecture may be substantially different from underlying hardware
    * [[R: C is not the low level PL and your computer is not PDP-11]]
    * stack-oriented architecture for convenience in code generation
    * but most available hardware machines execute register-oriented code
      * [[C: LuaJIT, register-based VM]]
  * basic operations of v-machine may be relatively expensive to implement
* v-code $\to$ n-code?
  * [threaded-code](https://www.complang.tuwien.ac.at/forth/threaded-code.html): v-code consists of an actual sequence of subroutine calls on runtime routines
    * [[C: GCC labels as values]]
    * reduce overhead for fetching & dispatching
  * naive translation: macro-expansion
* translation-time: an opportunity for peephole optimization / mapping stack references to registers



### Dynamic Translation

* v-code: compact, n-code about 5 times space as v-code
  * stress on virtual memory if paged n-code
  * judge caching, translating at runtime
* if n-code not exists, call faults and translator takes control
  * [[N: not like JIT?]]



### Mapping State at Runtime

* system must maintain a mapping of n-machines tate to v-machine state
  * v-code available for inspection
  * [[Q: self-modifying code?]]
* smalltalk-80: only code that can access an object of a given  class directly is the code that implements messages sent to that class
  * so the code directly access the parts of an object requiring mapping is the code associated with that object's class
  * special n-code that calls a subroutine to ensure that object is represented ina form where accesses to its named parts are meaningful
* return address (PC) in an activation record
  * v-PC vs. n-PC
  * consult/compute a table associated with the procedure that gives the n- vs. v-PC
  * reduce size of mapping tables, since PC only accessed when an activation is suspended (procedure call / interrupt|process-switch)
  * choose a restricted but sufficient set of allowable interrupt points, only store for those points
    * interrupts are only allowed at & PC map entires are only stored for, all procedure calls & backward branches (must be allowed inside loops)
* [[N: If exposing VM state, how to map it is a problem... Check LuaJIT & PyPy]]



### Multiple Representation of Contexts

* block contexts (functionals, closures, funargs)
* contexts are standard data objects (heap allocation, reference counting)
  * but performance penalty: conventional machines are adapted for calling sequences creating stacks
  * and most of them are just as stack (80%)
    * candidates for stack-frame representation
* stack allocation avoids some overhead
* also solve ref cnt issues
* hardware subroutine instructions directly
* different types of context representations
  * volatile: stack frame, no reference counting
  * stable: context in a format compliant with the VM specs (as data items)
* hybrid: stack frame + header information
  * volatile $\to$ hybrid: when a pointer generated to it
    * fill the slots in the frame cooresponding to the header fields
    * pseudo-object: `DummyContext`
    * return address copied to another slot in the frame
      * replace with the address of clean-up routine that stabilizes the context on return
  * messages $\to$ hybrid: fails, a routine is called to convert $\to$ stable form
    * n-PC $\to$ v-PC
    * pointers to hybrid $\to$ refer to stable (indirection table for all objects)
    * failed message re-send to stable form
* execution, stable $\to$ hybrid: reconstitued on stack as hybrid
  * v-PC $\to$ n-PC: code caching



### In-line Caching of Method Addresses

* method cache: hash table of popular method addresses indexed by the pair
* dynamic locality: receiver often the same class as the receiver at the same point when the code is last executed
* n-code: send unlinked (as a call to the method-lookup routine with the selector as an in-line argument)
  * method-lookup routine links the call by finding the receiver class, storing it in-line at the call point, doing method lookup
  * place in-line with a call instruction, overwriting the former call to the lookup routine
  * re-execute call
  * [[N: like PLT/GOT]]
  * invalidate if n-code discarded from memory
    * scanning: bad
    * cannot produce page faults
    * no searching is required, since PC mapping tables contain address of calls in the n-code
      * go through the mapping tables
      * overwrite the call instructions to which the entries point
      * [[Q: elaborate this?]]
* special selectors, like `+`
  * in-line code for common case
  * class check for small integers, native code, overflow check
  * if any fails, send code exeuted



## Conclusion

* inspire JIT
  * modest increase in memory ([[N: hmm, I guess not an issue anymore]])
  * without special hardware (microcode, tagged memory, gc co-processor [[N: Lisp machine, Java machine]])
  * excellent performance
* 















## Motivation

## Summary

## Strength

## Limitation & Solution



