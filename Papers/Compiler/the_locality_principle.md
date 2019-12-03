# [The Locality Principle](http://denninginstitute.com/pjd/PUBS/CACMcols/cacmJul05.pdf)

###### Peter J. Denning

---

### What is the Problem? [Good papers generally solve *a single* problem]

* The performance of virtual memory is sensitive to choice of replacement algorithm, the way compilers grouped code onto pages and thrashing in multiprogramming.

### Summary [Up to 3 sentences]

* In this journal, the author summarizes the history of development of the idea of locality. The locality principle was needed when virtual memory was invented and cache was used to accerlate, which caused thrashing in multiprogramming. The principle of locality and concepts of working set, temporal and spatial locality were then discovered and adopted as an interpretation of thrashing and consideration of design.

### Key Insights [Up to 2 insights]

* Thrashing was the collapse of system throughput triggered by making the multiprogramming too high (memory was filled with working sets).
* The locality behavior of programs was produced by temporal clustering (looping and executing within modules with private data) and spatial clustering (grouped data such as arrays, sequences, modules)

### Notable Design Details/Strengths [Up to 2 details/strengths]

* The author defined locality as a distrance from a processor to an object x at time t (D(x, t)). Object x should be in the locality set if D(x, t) <= T. The distanced defined here can be based on temporal distance, spatial distance or cost.
* A working set is defined as the set of ages used during a fixed-length sampling window in the immediate past. The working set sequence can be a measureable approximation of locality sequence.

### Limitations/Weaknesses [up to 2 weaknesses]

* For modern multicore architecture, locality can't explain the multiprogramming problems like false cache-line sharing or cache-line ping-poing.
* Security-related. Assume the locality (speculative execution)

### Summary of Key Results [Up to 3 results]

* Thrashing was triggered by making the multiprogramming too high with memory filled with working sets. It can be solved by setting a working set policy.
* The locality principle, that programs accesses behave like temporal clustered and spatial clustered.

### Open Questions [Where to go from here?]

* What's the relationship between locality principle and the human cognitive and coordinative behavior?
* How compilers and CPUs take advantage of the locality principle?
* Will functional programming, quantum computer still have the locality?
* Compiler knows the architecture/hardware detail? cache?