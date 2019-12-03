# [Exokernel: An Operating System Architecture for Application-Level Resource Management](https://pdos.csail.mit.edu/6.828/2016/readings/engler95exokernel.pdf)

###### Dawson R. Engler, M. Frans Kaashoek, and James O’Toole Jr.

---

### What is the Problem? [Good papers generally solve *a single* problem]

* The fixed high-level abstraction made by traditional operating system hurts application performance, hides information and limits the functionality and flexibility.

### Summary [Up to 3 sentences]

* In this paper, the authors present a new architecture of operating system, exokernel, which separates hardware resource protection and management. The exokernel protects the access to physical resources and exposes secure binding to application-level library operating system. The authors design a real exokernel Aegis and a library operating system ExOS, and measure the performance compared to a typical monolithic UNIX operating system, Ultrix.

### Key Insights [Up to 2 insights]

* Traditional operating system limits the performance, flexibility and functionality of application by fixed the interface and implementation of operating system.
* Exokernel can provide sufficient functionality for application and high performance with limited primitives. Since applications know better about the domain-specific requirement (like data access pattern), they can create specially tailored library operating systems.

### Notable Design Details/Strengths [Up to 2 details/strengths]

* Exokernel uses three techniques for separating physical resources protection from management, secure bindings, visible revocation and abort protocol. Thus, exokernel can tracking ownership of resources, ensuring protection by guarding all resource usage or binding points and revoking access to resources.
* Exokernel employs some principles including securely exposing hardware, exposing allocation, names and revocation. By these principles, Exokernel can provides multiple co-existing library operating system the maximum degree of control.

### Limitations/Weaknesses [up to 2 weaknesses]

* There is no standard for designing Exokernel for different hardware platforms. And if the interface for different Exokernel differs a lot, The operating system needs to do much specialization for different exokernel, which will lead to inefficient generalization or difficult code maintaining for exponential different versions.

### Summary of Key Results [Up to 3 results]

* Exokernel can be made more efficient with limited number of simple primitives than traditional monolithic UNIX operating system. 
* Traditional abstraction, such as virtual memory, interprocess communication, can be implemented efficiently at application level, where they can be easily extended, specialized or replaced.
* Applications can create special-purpose implementation of abstraction with good performance as library operating system.

### Open Questions [Where to go from here?]

* Is Exokernel kind like HAL layer in Windows? What's the different between Windows subsystem and library operating system?
* Can exokernel have the market preference in near future?
* Can we trust the exokernel enough? Side-channel attacks can bypass the exokernel and LibOS doesn't check that.