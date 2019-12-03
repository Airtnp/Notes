# [AutoFDO: Automatic Feedback-Directed Optimization for Warehouse-Scale Applications](https://storage.googleapis.com/pub-tools-public-publication-data/pdf/45290.pdf)

###### Dehao Chen, David Xinliang Li, Tipp Moseley

---

### What is the Problem? [Good papers generally solve *a single* problem]

* The datacenter applications can't take advantage of traditional FDO (feedback-directed optimization) since they have varying performance critical sections, are difficulty to save the logs and can't afford the overhead of instructmented binaries.

### Summary [Up to 3 sentences]

* The author presents AutoFDO, which does feedback-directed optimization on optimized binaries across datacenter binaries. The purpose of AutoFDO is to support iterative compilation, tolerance for stale profile.

### Key Insights [Up to 2 insights]

* For datacenter binaries, the performance critical sections are changing rapidly.
* For datacenter binaries, AutoFDO needs to support iterative compilation and stale profile between releases.

### Notable Design Details/Strengths [Up to 2 details/strengths]

* Use extended source location `(function name, source line offset to function start, discriminator)` to record source-level profile so that a change of one function (recompile, ABI) can't break the the rest profile data.
* AutoFDO considers proved-to-be inlined indirect call, thus there is no back and forth inlining on one specific indirect call in iterative compilations.

### Limitations/Weaknesses [up to 2 weaknesses]

* Since AutoFDO does feedback-directed optimization on optimized binaries, it introduced unrecoverable destructive changes to original source and lead to incorrect annotations.
* If a user needs stable performance, the feedback-directed profiling can lead to cascading overload of the service.

### Summary of Key Results [Up to 3 results]

* AutoFDO archieves 85% performance as good as with instrumentation with support to iterative compilations, tolerence of stale profile data and scaling.
* Comparing FDO and AutoFDO results show that imprecise profiles from real workloads can work as good as precise profiles.

### Open Questions [Where to go from here?]

* Can we record the compiler optimizing process to get precise profiling data from imprecise ones? Is compiler optimization revertable?
* wrong binary, and worse and worse on likely bad branch
* fast-changing binary
