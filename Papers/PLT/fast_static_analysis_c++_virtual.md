# Fast Static Analysis of C++ Virtual Function Calls

**David F. Bacon, Peter F. Sweeney**

---



## Introduction

* resolving virtual function calls
  * reduce compiled code size (virtual calls must include all assembly)
  * reduce program complexity (expose user a large space of object types and functions)
* compare 3 fast static analysis algorithms for resolving virtual function calls & evaluate ability to solve the problems



## Static Analysis

* Unique Name (UN)

* Class Hierarchy Analysis (CHA)

* Rapid Type Analysis (RTA)

* ```c++
  class A {
      public:
      	virtual int foo() { return 1; }
  };
  class B : public A {
      public:
      	virtual int foo() { return 2; }
      	virtual int foo(int i) { return i + 1; }
  };
  int main() {
      B* p = new B;
      int result1 = p->foo(1);
      int result2 = p->foo();
      A* q = p;
      int result3 = q->foo();
  }
  ```



### Unique Name

* optimize at link time, confine to object file information
* 1 implementation of particular virtual function anywhere in the program
  * by comparing the mangled name of C++ functions in the object files
  * replaced with a direct call
* don't require access to source code
* optimize virtual calls in library code
* inhibits inlining (since on link-time & object code)
* can resolve `result` because only 1 virtual function calls to `foo$int`



### Class Hierarchy Analysis

* no derivied of `B`, can solve `result2` & `resutl1`
* static information, ignore identically-named functions
* must have complete program available (potential override)
  * but incremental compilation is possible ([[R: CHA paper]])



### Rapid Type Analysis

* starts with call graph generated by CHA, uses information about instantiated classes to further reduce the set of executable virtual functions, reducing the size of the call graph
* E.g. `result3` not resolved by CHA because the type `A*`, but no objects of type `A` is created, RTA can solve it
* sub-objects are not considered true object instantitations (like `A` part in the `B`)
* build set of possible instantiated types optimistically
  * traverse starting at `main`
  * virutal call sites initially ignored
  * construct found? any of the virtual methods of the corresponding class are also traversed
* must analyze the complete program
* flow-intensive, don't keep per-statement information



## Other Analysis

* type prediction

* flow-analysis

* ```c++
  A* q = new B;
  q = new A;
  result = q->foo();
  ```

* alias analysis



### Type Safety Issues

* CHA, RTA both rely on type safety of the programs

* ```c++
  void* x = (void*) new A;
  B* q = (B*) x;
  int case2 = q->foo();
  ```

* undefined behavior

* disable CHA/RTA when downcasting

* most powerful

* all for monomorphic calls

* but can't resolve when multiple related object types are used independently

  * disjoint polymorphism
  * like `count` and `iter` problem



## Conclusion

* RTA is highly effective for all of these purposes



















## Motivation

## Summary

## Strength

## Limitation & Solution


