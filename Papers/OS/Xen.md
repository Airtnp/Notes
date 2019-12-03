# [Xen and the Art of Virtualization](https://www.cl.cam.ac.uk/research/srg/netos/papers/2003-xensosp.pdf)

###### Paul Barham, Boris Dragovic, Keir Fraser, Steven Hand, Tim Harris, Alex Ho, Rolf Neugebauer, Ian Pratt, Andrew Warfield

---

### What is the Problem? [Good papers generally solve *a single* problem]

To subdivide the ample resources of a modern computer, numerous virtualization system is designed but with limitations such as binary incompatiility, high overhead, and security problems.

### Summary [Up to 3 sentences]

* The paper presents an x86 virtual machine monitor which allows multiple commondity operating system to share conventional hardware with safe rosource managment, low overhead and complete functionality.

### Key Insights [Up to 2 insights]

* Traditional full-virtualiation needs to dynamic rewrite hosted machine code to insert intervention in order to solve the problem of x86 virtualization (not satisfying Popek Theorem) and implement shadow version of system structures which will introduce large overhead.
* Hiding resource virtualization like full-virtualization can harm correctness and performance.

### Notable Design Details/Strengths [Up to 2 details/strengths]

* Xen exists in a 64MB section at the top of every address space, thus avoiding a TLB flush when entering and leaving the hypervisor
* Guest OSes are running under ring-1 to let priviledged instructions to be validated and executed by hypervisor. They can register fast exception handler to speed up syscall.

### Limitations/Weaknesses [up to 2 weaknesses]

* Xen requires modification of operating system source code.

### Summary of Key Results [Up to 3 results]

* Xen provides a paravirtualization techinique which has high scalability, secure isolation and high performance close to native Linux. The Xen platform can serve as a convenient and high performance way to deploy services.

### Open Questions [Where to go from here?]

* The security problem. What's the vulnerability which can achieve virtualization escape.
* Is hardware-assisted virtualiation a better idea?
* Xen on ARM? embedded system? (https://www.youtube.com/watch?v=GYb-Qn3KAUM)
* What's Xen now? 
