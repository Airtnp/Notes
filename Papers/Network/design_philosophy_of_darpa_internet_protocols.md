# [Design Philosophy of DARPA Internet Protocols](http://ccr.sigcomm.org/archive/1995/jan95/ccr-9501-clark.pdf)

###### David D. Clark

---

### What is the Problem? [Good papers generally solve *a single* problem]



### Summary [Up to 3 sentences]



### Key Insights [Up to 2 insights]



### Notable Design Details/Strengths [Up to 2 details/strengths]



### Limitations/Weaknesses [up to 2 weaknesses]



### Summary of Key Results [Up to 3 results]



### Open Questions [Where to go from here?]




### Self-Keypoints [Delete this when uploading!!]
* Internet architecture
* fundamental goal
* + develop an effective technique for multiplexed utilization of existing interconnected networks (eg. ARPANET - ARPA)
* + unified system? high performance/integration, less practical
* + multiplexing => packet switching (instead of circuit switching - phone)
* + gateway: packet switchs, store and forward packets
* + a packet switched communications facility in which a number of distinguishable networks are connected together using packet communications processors called gateways which implement a store and forward algorithm
* second-level goal
* + Internet communication must continue despite loss of network or gateways
* + - because of a military context (hostile environment)
* + - less concern of detailed accounting of resouces
* + The Internet must support multiple types of communication service
* + The Internet architecture must accommodate a variety of networks
* + The Internet architecture must permit distributed management of its resources
* + - fault-tolerance
* + The Internet architecture must be cost effective
* + The Internet architecture must permit host attachment with a low level of effort
* + The resources used in the internet architecture must be accountable
* + - quantification/measurement
* + in order of importance
* survivability
* + At transport layer, no facility to communicate when synchronization between sender and receiver is lost. Assumption that synchronizaiton never lost unless no physical path (total partition failure). Internet should mask any transient failure. 
* + Must protect state information of on-going conversation (# of packets transmitted, # of packet acknowledged, # of outstanding flow control permissions)
* + end-to-end/fate-sharing (no need for robust replicate for saving state in internal nodes)
* + - gateways have no essential state information (stateless packet switches)
* + - most trust is placed in host machine (sequencing, acknowledgement of data)
* types of service
* + at transport level, support a variety of types of service (speed, latency, reliability, delay, bandwidth)
* + bi-directional reliable delivery of data (virtual circuit): remote login, file transfer => TCP
* + TCP (reliable sequenced data stream)
* + UDP (datagram service): not all services need TCP
* + IP (basic building block): separate from TCP
* + don't assume underlying network supporting multiple types of serices => multiple types of services (TCP/UDP) from basic datagram building blocks (IP)
* variety of networks
* + long haul nets (ARPANET, X.25)
* + local area nets (Ethernet/ringnet)
* + broadcast satellite nets (DARPA Atlantic Satellite Network, DARPA Experimental Wideband Satellite Net)
* + packet radio networks (DARPA packet radio network, British packet radio net)
* + variety of serial links
* + other ad hoc facilities (intercomputer busses, HASP in IBM)
* + basic assumption: network can transport a packet or datagram
* + not assumption
* + - reliable/secured delivery
* + - netowrk level broadcast/multicast
* + - priority ranking of transmitted packet
* + - support for multiple type of service
* + - internal knowledge of failture
* + - speeds/delays
* Other goals
* + permitting distributed management of Internet
* + - what about internal gateways?
* + - two-tiered routing algorithm for gateways from different administrations to exchange routing tables (without enough trust)
* + - private routing algorithms
* + - lack of sufficient tools for distributed managemnt of resources in the context of multiple administrations
* + cost effective compared to tailored architecture
* + - long headers (compared to small bytes of data)
* + inefficiency for retransmission of lost packets
* + - end-to-end design => repeat traffic
* + cost of attaching a host
* + - implementing the network utilities
* + - poor implementations (heart-bleed?)
* + accountability
* Architecture and Implementation
* IP/Datagrams
* + datagrams as entity transported
* + eliminate the need for connection state within imtermediate switching nodes
* + basic building block
* + minimum network service assumption
* TCP
* + regulate the delivery of bytes, not packets (while UDP is for packets[datagrams])
* + - permit the insertion of control information into the sequence space of the bytes
* + - permit TCP packet to be broken up into smaller packets if necessary to fit through a net with a small packet size => moved to IP layer
* + - permit a number of small packets to be gathered together (if retransmission is needed)
* + - limit of throughput
* + end flag (data up to this point is 1 or 1+ complete application level elements)
* + - EOL (End of Letter)
* + - PSH (push flag)
* narrow IP interface hurts innovation at the IP level
* hiding power (DPDK - user-level network interface (reduce memory copy))