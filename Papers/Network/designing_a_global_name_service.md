# [Designing a Global Name Service](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/acrobat-15.pdf)

###### Butler W. Lampson

---

### What is the Problem? [Good papers generally solve *a single* problem]



### Summary [Up to 3 sentences]



### Key Insights [Up to 2 insights]



### Notable Design Details/Strengths [Up to 2 details/strengths]



### Limitations/Weaknesses [up to 2 weaknesses]



### Summary of Key Results [Up to 3 results]



### Open Questions [Where to go from here?]




### Self-Keypoints [Delete this when uploading!!]

* Distributed, Persistent, Transactional B-tree
* name service: maps a name for an entity into a set of labeled properties
* + large size: to handle essentially arbitrary number of names and serve an arbitrary number of administrative organizations
* + long life
* + high availability
* + fault isolation
* + tolerance of mistrust
* client level
* + The client sees a structure much like a Unix file system. There is a tree of directories, each with a unique directory identifier (DI) and a name by which it can be reached from its parent. 
* + A DR(The arcs of the tree are called directory references) is the value of the name; it consists simply of the DI for the child directory. Thus a directory can be named relative to a root by a path name called its full name (FN).
* + Access control is based on the notion of a principal, which is an entity that can be authenticated by its knowledge of some encryption key (which acts as its password).
* + Authentication is based on the use of encryption to provide a secure channel between the caller of an operation and its implementor.
* administrative level
* + find copies
* + sweep and write-back
* name space
* + fullname and name of an entity registered in that directory
* growth
* + hierarchical strcture
* + merging trees, shadowing
* restructring
* + move tree
* caching
* name service interface
