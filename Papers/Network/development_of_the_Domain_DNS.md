# [Development of the Domain Name System](https://www.cs.cornell.edu/people/egs/615/mockapetris.pdf)

###### Paul V. Mockapetris, Kevin J. Dunlap

---

### What is the Problem? [Good papers generally solve *a single* problem]



### Summary [Up to 3 sentences]



### Key Insights [Up to 2 insights]

* Hierarchical
* Distributed
* Cached

### Notable Design Details/Strengths [Up to 2 details/strengths]



### Limitations/Weaknesses [up to 2 weaknesses]



### Summary of Key Results [Up to 3 results]



### Open Questions [Where to go from here?]




### Self-Keypoints [Delete this when uploading!!]
* DNS provides name service for DARPA Internet
* Introduction
* + initially, DNS is hosts.txt system maintained on a host at the SRI and distributed to all hosts
* + then, hosts.txt from NCP-based original ARPANET to the IC/TCP-based Internet
* + then, RFC
* DNS Design
* + provides hosts.txt functionality
* + allow the database to be maintained in a distributed manner
* + have no obvious size lmit for names
* + interoperate across the DARPA Internet and in as many other environments
* + - buffered database information
* + provide tolerable performance
* + DNS architecture
* + - name servers
* + - - repositories of information
* + - - answer queries using whatever information they possess
* + - resolvers
* + - - interface to client program
* + - - embody the algorithms necessary to find a name server that has the information sought by the client
* + DNS namespace
* + - variable-depth tree where each node in the tree has an associated label < 256 octets
* + - labels are variable-length strings of octets < 63 octets
* + data attached to names
* + - data for each name in the DNS is organized as a set of resource records (RRs)
* + - types are meant to represent abstract resources or functions
* + DNS database distribution
* + - zones: sections of the system-wide datbase controlled by specific orgranization
* + - - organization controlling a zone is responsible for distributing current copies of the zones to multiple servers which make the zones avaiable to clients throughtout the Internet. (maintenance of the zone's data and providing redundant servers for the zone)
* + - - a complete description of a contiguous section of the total tree name space, together with some "pointer" information to other continguous zones
* + - - an organization should be able to have a domain
* + - caching
* + - - data acquired in response to a client's request can be locally stored again future requests by the same or other client
* + - - DNS resolvers and combined name server/resolver programs also cache responses for use by later queries.
* + - - TTL(time-to-liev) field attached to each RR presents the length of time that the response can be reused. (adminstrator defines TTL values for each RRas part of the zone definition)
* + - - - continuously decremented TTLs of data in caches
* Implementation
* + root server
* + berkeley
* + surprise
* + - refinement of semantics
* + - high performance
* + - negative caching
* + - - non-exist name: misspelled?
* + - - existing name, non-exist data: ask for host type
* + success
* + - variable depth hierarchy
* + - orgranizational strcturing of names
* + - datagram access
* + - additional section processing
* + - caching
* + - mail address cooperation
* + shortcomings
* + - type and class growth
* + - easy upgrading of applications
* + - distribution of control vs. distribution of expertise or responsibility
* 