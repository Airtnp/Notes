# [End-To-End Arguments in System Design](http://web.mit.edu/Saltzer/www/publications/endtoend/endtoend.pdf)

###### J.H. Saltzer, D.P. Reed and D.D. Clark

---

### What is the Problem? [Good papers generally solve *a single* problem]

* Some functions can completely and correctly implemented only with the knowledge and help of the application at the end points of the system. Providing functions at low levels can be redundant or valueless compared to the cost.

### Summary [Up to 3 sentences]

* The author proposes the end-to-end argument that if the function can only be implemented correctly and completely with assistance of end points, then the function should not be implemented at low level of systems. The author discusses many senarios using end-to-end design including reliable file transfer, delivery acknowledgements, data encryption, duplicate suppression, guaranteed FIFO delivery and transaction. The author also argues about the performance, identification and history of end-to-end applications.

### Key Insights [Up to 2 insights]

* End-to-end design provides a rationale for moving functions upward to layers which are more closed to the application.
* End-to-end design can reduce the complexity of communication subsystem.

### Notable Design Details/Strengths [Up to 2 details/strengths]

* End-to-end design can introduce large overhead if the network has low level of reliability. However, the performance tradeoff is complex. Functions implemented in low level systems can impact other applications or can't be implemented efficiently.
* To identify the end points of system, one should needs careful analysis of system. Force a voice communicating system, it's completely different levels to apply end-to-end principle according to level of required delay (it's like soft/hard deadline of realtime system?)
* easy implementation
* easy upgradation
* endpoint flexibility
* low-level more stable

### Limitations/Weaknesses [up to 2 weaknesses]

* If the network is not reliable, end-to-end design can cause expontentially increase in expected time to transmit.
* For realtime systems like voice transmission, it's unacceptable to use end-to-end design since it needed a constant rate of voice data instead of storaging packets and checksum.
* Need implicit trust on endpoints
* No explictly defined endpoints
* Lack of quantitative analysis

### Summary of Key Results [Up to 3 results]

* End-to-end design can lead to simpler design in some fields of data communication systems including reliable file transfer, delivery acknowledgements, data encryption, duplicate suppression, guaranteed FIFO delivery and transaction.
* End-to-end argument is a accumulated idea which had applied to many previous researches including encryption, data update protocols, error control and so on. It can be viewed as part of a set of rational principles for organizing layered systems.

### Open Questions [Where to go from here?]

* End-to-end argument can be discussed at some layered system in detail, like OSI layers, operating system layers (like user - kernel, user - hardware?)
* The overhead of end-to-end design in different layered systems.
* What's about some network strongly linked to internal nodes, like Tor?
* How to reason about end-to-end in a principle way?
* Given current low-level sophitiscation, is end-to-end relevant?
* How do you take advantage of low-level innovation?
* To what other domains, end-to-end is appliable?
* Any examples that end-to-end fails?

#### Congestion control
* Is congestion control amenable to an end-to-end implementation? (network is in charge of congestion)
* 


### Self-Keypoints
* low-level functions are redundant
* low-level functions are costly
* low-level functions are mainly a performance optimization