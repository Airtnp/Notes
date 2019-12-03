# [KLEE: Unassisted and Automatic Generation of High-Coverage Tests for Complex Systems Programs](https://llvm.org/pubs/2008-12-OSDI-KLEE.pdf)

###### Cristian Cadar, Daniel Dunbar, Dawson Engler

---

### What is the Problem? [Good papers generally solve *a single* problem]

* Many classes of errors are difficult ot find without executing a piece of code. However, with symbolic execution, it's doubtful whether symbolic execution can achieve high coverage on real applications since there are two concerns: (i) exponential number of paths; (2) interaction with surrounding environment.

### Summary [Up to 3 sentences]

* In this paper, the authors present KLEE, which a symbolic execution tool for general applications and automatically generating high-coverage testcases.

### Key Insights [Up to 2 insights]

* Real applications have high complexity with non-obvious input parsing code, tricky boundary conditions and hard-to-follow control flow.
* Real applications have environment dependencies. Its code is controlled by environmental input.

### Notable Design Details/Strengths [Up to 2 details/strengths]

* For pointer aliasing problem, KLEE clones the current state N times to make pointer refer to N objects and constrains pointer in each state to be within bounds.
* KLEE uses several techniques for query optimization: expression rewriting, implied value concretization, constraint set simplification, constraint independence, counter-example cache

### Limitations/Weaknesses [up to 2 weaknesses]

* KLEE only checks for low-level errors and violations of user-level asserts, while developers' tests can validate the application output matches the expected output.

### Summary of Key Results [Up to 3 results]

* KLEE is able to generate higher line coverage with few test cases than developer test cases.
* KLEE is able to find unique bugs in COREUTILS, MINIX,  and BUSYBOX tools.

### Open Questions

* How to address the path explosion problem in symbolic execution?