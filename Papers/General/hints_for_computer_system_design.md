# [Hints for Computer System Design](http://web.eecs.umich.edu/~barisk/teaching/eecs582/hints.pdf)

###### Liran Xiao

---

### What is the Problem? [Good papers generally solve *a single* problem]

* Design a system is hard.

### Summary [Up to 3 sentences]

* The writer mentions some hints in functionality, speed, fault-tolerance of system to make people consider the value of the system

### Key Insights [Up to 2 insights]

* Not mentioned

### Notable Design Details/Strengths [Up to 2 details/strengths]

* Not mentioned

### Limitations/Weaknesses [up to 2 weaknesses]

* Not mentioned

### Summary of Key Results [Up to 3 results]

* Not mentioned

### Open Questions [Where to go from here?]




### Self-Keypoints [Delete this when uploading!!]
* Functionality
* + keep it simple
* + - interface: contract to deliver a certain amount of service, incurring a reasonable cost
* + - interface should capture the minimum essentials of an abstraction
* + - interface should not promise more than the implementer knows how to deliver, should not promise features needed by only a few clients
* + - seldom used interface => can sacrifice some performance
* + - generality => unexpected complexity
* + - corollary
* + - - fast, rather than general or powerful (client doesn't want the power pays more for basic function)
* + - - don't hide power. When a low level of abstraction allows something to be done quickly, higher levels should not bury this power inside something more general. The purpose of abstraction is to conceal undesirable properties.
* + - - use procedure arguments to provide flexibility in an interface. (ad-hoc polymorphism) The cleanest interface allows the client to pass a filter procedure that tests for the property.
* + - - leave it to the client. If it's cheap to pass control back and forth, interface can combine simplicity, flexibility and high performance by solving only one problem and leaving the rest to the client. (unix pipes)
* + continuity
* + - keep basic interfaces stable. interface embodies assumptions shared by parts of system
* + - keep a place to stand if you do have to change interfaces. compatibility package / world-swap debugger
* + make implementations work
* + - plan to throw one away and make something complete new
* + - keep secrets of the implementations. (secrets are assumptions about an implementation that client programs are not allowed to make)
* + - divide and conquer
* + - use a good idea again instead of generalizing it. A specialized implementation of the idea may be much more effective than a general one.
* + handling all the cases
* + - handle normal and worst cases separately as a rule (normal: fast, worst: make some progress)
* speed
* + split resources in a fixed way. (Rather than sharing, allocate dedicated resources)
* + - eg. registers and memory(cache)
* + static analysis => how to allocate resources (registers / data), find invariant
* + dynamic translation from a convenient (compact easily modified or easily displayed) representation to one that can be quickly interpreted
* + - eg. interpreting bytecode and cache (JIT? incremental compiling?)
* + - eg. instruction/data cache (address translation)
* + cache answers to expensive computations 
* + - [x, f(x)] when f(x) is functional (no side-effect?)
* + - f(x+delta) = g(x, delta, f(x)) => [fetch, addr, contents of addr]
* + - adaptively change cache size (bigger when hit rate down, smaller when hit rate increases)
* + use hints to speed up normal execution
* + - hint: like cache, may be wrong, has way to check its correctness
* + when in doubt, use brute-force. (straightforward, may have less constant factor)
* + compute in background
* + - eg. garbage collector (refcnt), email, paging (zeroing)
* + batch processing
* + - sequentially rather than incrementally
* + - simpler error recovery (like transaction?)
* + safety first (avoid disaster rather than to attain an optimum)
* + shed load to control demand, rather than allowing the system to become overloaded
* fault-tolerance
* + end-to-end (don't rely on internal nodes in a network)
* + - error recovery at the application level for reliable system
* + - requires a cheap test for success
* + - can lead to working system with severe performance defects that may not appear until system becomes operational and is placed under heavy load.
* + log-updates to record the truth (append-only, easily to duplicate/copy)
* + - functional procedure (idempotent [not depending on out states], no side-effects) with arguments as values (immediate / reference to immutable objects)
* + - versioning mutable objects
* + make actions atomic or restartable (transaction)

### Speech
* Simple
* + can be understanded (by abstraction and interfaces)
* Timely
* + good enough it's enough
* Efficient
* + for implementer
* + for client
* Adaptable
* + plan for future large scale
* + incremental update
* Dependable
* + reliable (safe)
* + available (live)
* + secure
* Yummy
* + user wants it.
* Approximate
* + good enough (not always successful), eg. Web, search engine, IP packets
* + - eventual consistency: DNS, Dynamo, file/email sync
* + loose couping: email, fedwire
* + brute force: overprovision, broadcast, scan, crash fast
* + relax: small steps converge to desired result
* + hints: trust but verify (not always true)
* Incremental
* + indirect: control name -> value mapping
* + - virtualize/shim: VMs, NAT, USB
* + - Network: source route -> IP addr -> DNS name -> service -> query
* + - Symbolic links, register rename, virtual methods, copy on write
* + iterate design actions, components
* + - redo: log, replicated state machines
* + - undo: file system snapshots, transaction abort
* + - scale: internet, cluster, I/O devices
* + extend: HTML/Ethernet
* Divide & Conquer
* + interfaces to abstractions: divide by difference eg. Platforms/Complexity/Declarative/
* + recursive: divide by structure (Part ~ Whole), eg. Quicksort, IPV6, FileSys
* + replicated: divide for redundancy in time/space: end to end(TCP)
* + concurrent: divide for performance: BitTorrent/MapReduce
* Coordinate systems and notation
* + state
* + - being: map from names -> values
* + - becoming: initial state + log of updates (good for undo, versions, recovery)
```
Example                         Being	                Becoming
Image	                        bitmap	                display list
Document 	                    sequence of characters	sequence of inserts / deletes 
Database	                    table + buffer cache	redo-undo log
Eventual consistency	        names -> values read	any subset of updates that are commutative and associative
```
* + function
* + - code: f(x)
* + - table: lookup x in a set (x, y) pairs
* + - overlay: try f_1(x), then f_2(x)...
```
Example 	                    Code	        Table	            Overlay
Main memory	                    —	            RAM	                write buffer
Database	                    —	            data on disk	    buffer cache
bin for shell cmd	            —	            /bin directory	    search path
Function of simple argument 	run the code 	precomputed results	saved old results
Database view	                run the query	materialized view	incremental updates 
```
* Write a spec
* + abstract state (eg. FileSystem: pathName -> byteArray)
* + interface actions (APIs)
* + abstraction function F from code to spec
* + show that each action PI preserves F
