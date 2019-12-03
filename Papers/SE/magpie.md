# [Using Magpie for request extraction and workload modelling](https://www.usenix.org/legacy/event/osdi04/tech/full_papers/barham/barham.pdf)

###### Paul Barham, Austin Donnelly, Rebecca Isaacs and Richard Mortier

---

### What is the Problem? [Good papers generally solve *a single* problem]

* Tools to understand complex system behavior are essential for many performance analysis and debugging tasks, yet few exist and there are many open research problems in their developement.

### Summary [Up to 3 sentences]

* In this paper, the authors present Magpie, which is an ubobtrusive and application-agnostic method of extracting the resource consumption and control path of individual requests and a mechanism for constructing a concise model of the application workload. They also show a validation of the accuracy of the extracted workload models using synthetic data and evaluation of performance against realistic workloads.

### Key Insights [Up to 2 insights]

* Workload of a system is comprised of different types of request that take various paths, exercise different set of components and consume differing amounts of system resources.
* Instrumentation framework must support accurate accounting of resource usage between instrumentation points to enable multiple requests sharing a single resource to be distinguished.

### Notable Design Details/Strengths [Up to 2 details/strengths]

* Eschewing a requirement for global identifier can avoid the problems associated with guaranteeing unique identifier allocation, need for complication ad-hoc state management or API modification to manage the identifiers, and can ensure the instrumentation is kept independent of the request.
* To support accurate accounting of resource usage between instrumentation points, it's required to have high precision timestamps since attribution of events to requests relies on properly ordered events.
* Request parser utilizes event schema and temporal joins to associate events.

### Limitations/Weaknesses [up to 2 weaknesses]

* The request parser can only process trace events in the delivered order and no way for it to seek ahead the trace log.
* The request parser needs a request schema for applications which must be written by system experts.

### Summary of Key Results [Up to 3 results]

* Magpie event tracing and parsing only have slight influence on server throughput, namely low overhead event tracing and parsing.
* Magpie successfully extract individual requests and construct representative workload models from e-commerce systems.

### Open Questions [Where to go from here?]

* Can we get rid of the request schema, namely generic request extraction scheme?

