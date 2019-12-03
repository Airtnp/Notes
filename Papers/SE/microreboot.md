# [Microreboot – A Technique for Cheap Recovery](https://www.usenix.org/legacy/event/osdi04/tech/full_papers/candea/candea.pdf)

###### George Candea, Shinichi Kawamoto, Yuichi Fujiki, Greg Friedman, Armando Fox

---

### What is the Problem? [Good papers generally solve *a single* problem]

* Rebooting can be expensive, causing nontrivial service disruption or downtime even when clusters and failover are employed.

### Summary [Up to 3 sentences]

* The authors provides a new fine-grained technique called microrebooting which utilize the separation of process recovery from data recovery. The authors then build a microrebootable prototype in J2EE and evaluate the prototype by client emulator and resource manager.

### Key Insights [Up to 2 insights]

* A significant fraction of software failures in large-scale systems are solved by rebooting with the exact failure causes unknown.
* The crash-only design approach needs fine-grained decoupling components, state segregation, retryable requests and leased resources.

### Notable Design Details/Strengths [Up to 2 details/strengths]

* Microrebootable systems should be partitioned into fine-grain, well isolated components which minimizes the dependency between themselves.
* Microrebootable system need to have self-contained microcheckpoint-able requests.
* Efficient microrebootable system requires a nearly constant-time resource reclamiation.

### Limitations/Weaknesses [up to 2 weaknesses]

* Microrebooting is safe only if the application is crash-only, namely programs that can be safely crashed in whole or by parts and recover quickly every time.
* Microreboot cannot handle interaction with external resources and non-atomic updates on shared state.

### Summary of Key Results [Up to 3 results]

* Microreboots is effective in recovering from the majority of failure modes seen in today's production J2EE systems.
* Comparing to full recovery, microreboots recover faster, reduce functional disruption and reduce lost work.
* Microreboots preserve cluster load dynamics.

### Open Questions [Where to go from here?]

* How can microreboot to be designed in other platforms or frameworks?
* Can non-crash-only programs utilize microreboot?
