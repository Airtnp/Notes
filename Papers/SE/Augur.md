# [Augur: Internet-Wide Detection of Connectivity Disruptions](https://www.youtube.com/watch?v=_rlPKcvzGx4)

###### Paul Pearcey, Roya Ensafix, Frank Liy, Nick Feamster, Vern Paxson

---

### What is the Problem? [Good papers generally solve *a single* problem]

* How can we detect whether pairs of hosts around the world can talk to each other?

### Summary [Up to 3 sentences]

* In this paper, the authors introduce Augur, which is a method and accompanying system that utilizes TCP/IP side channels to measure reachability between Internet locations without directly controlling a measurement vantage point at either location.

### Key Insights [Up to 2 insights]

* When sending IP packets, each generated packets contains a 16-bit IP identifier (IP ID), where many hosts use a single global counter to increment the IP ID value for all packets.
* The connection status of a site and a reflector can be figured out by TCP/IP side channels (called Spooky scan).

### Notable Design Details/Strengths [Up to 2 details/strengths]

* The difference in two IPID value from the reflector can represent the connection status of site and reflector from not blocked, inbound blocking and outbound blocking.
* The authors use statistical detection to determine the disruption.

### Limitations/Weaknesses [up to 2 weaknesses]

* The reflectors need to be Internet infrastructure (ethical reason) and must generate TCP RSP packets when receiving SYN-ACKs for unsolicited connections. The most important assumption is that the reflector must have a shared, monotonically incrementing IP ID.
* The sites need to have SYN-ACK retransmission, no IP address anycast, no ingress filtering and no stateful firewalls or network-specific blocking.

### Summary of Key Results [Up to 3 results]

* The authors use 2050 reflectors over 2134 sites during 17 days and do aggregate analysis of connection disription on sites. They list the top sites experiencing inbound blocking and outbound blocking.

### Open Questions [Where to go from here?]

* The idea of using a side channel is interesting. Can this idea apply in other fields?
