# Advanced Cloud Computing

[spring2017](http://www.cs.cmu.edu/afs/cs/academic/class/15719-s17/web/syllabus.html)



## Intro

* Multi-tenant consolidation with elastic cost conservation
* Properties of cloud computing
  * Computing as a utility – always available, basics (power, water, phone) 
    * Computing is across the network, accessible by all types of devices
  * Simplified interface/management – use the right API for user needs
  * Share resources over different users/uses – statistical multiplexing
  * Economies of scale from consolidation – better amortized costs 
  * Convert capital costs to operating costs – short leases instead of buying
  * Rapid and easy variation of usage – plug in more load on-demand
    * Appearance of infinite resources – all users are small users
  * Pay only for what you use – fine grain metered usage determines the bill
  * Cost conservation: 1 unit for 1000 hours == 1000 units for 1 hour 
* Average of i.i.d. variables has a decreasing variance independent of the variables's distribution (CLT)
  * Lots of users with widely varying needs apply a considerably less variable load on a huge provider – providers can manage overprovisioning well
  * Users perceive exactly what they need all the time, if their needs are small
  * ![image-20200106103333085](D:\OneDrive\Pictures\Typora\image-20200106103333085.png)
* A (flawed) taxonmy: S(ervice)aaS, P(latform)aaS, I(nfrastructure)aaS
  * SaaS: service is a complete application (client-server computing)
    * E.g. Salesforce
  * PaaS: high level (language) programming model for cloud computer
    * Eg. Rapid prototyping languages
    * Turing complete but resource management hidden
    * E.g. Google AppEngine
  * IaaS: low level (language) computing model for cloud computer
    * Eg. Assembler as a language
    * Basic hardware model with all (virtual) resources exposed
    * E.g. Amazon AWS
* Deployment models
  * Public cloud – provider sells computing to many unrelated consumers
  * Private cloud – provider is one organization with many largely unrelated components and divisions as consumers (may also be outsourced)
  * Community cloud – providers and consumers are different organizations with strong shared concerns (federations)
  * Hybrid cloud – Multiple providers combined by same consumer
    * Eg., Better availability, overflow from private to public, load balancing to increase elasticity
* ![image-20200106104820424](D:\OneDrive\Pictures\Typora\image-20200106104820424.png)
* Actors as roles
  * Auditors should be independent of providers
  * Carriers are network providers
  * Brokers mix and match consumers to providers 
    * May “Value-add” e.g. identity mapping, quota enforcement
    * May “Mashup” different services into a new service
    * May “Arbitrage” pick the best based on value for money
* Provider support for business, resources, portability
* Client-Service evolution (SaaS)
  * RPC: simple modularity of code in 2 different failure domain
  * DCE/DCOM/CORBA client-server computing
    * set of language free services that modular code uses to
  * .NET/SOAP
    * service oriented architecture is principled modularity & interoperability
  * REST/RMI/Thrift
    * SaaS today
* Obstacles
  * privacy & security
    * regulations?
  * usility issues
    * physical utilities also on regulartion
  * high cost of networking with always remote
  * preformance unpredictability & in situ development/debugging
    * virtual resources much less tangible than physical resources
      * core locality, memory availability, network congestion, disk congestion
    * bugs appear only at scale?
      * debugging facilities best for provider, worst for consumer
    * need trusted auditor
  * software licensing - $/yr/CPU is not elastic
* Marketeering extensions (X as a Service)
  * Data as a Service (DaaS)
    * Collector & seller of useful data
    * Analytics on consumer data, eg., Aciom (www.aboutthedata.com)
  * Network as a Service
    * Value-added service improving your data network
    * Content Delivery Networks (CDN) eg. Akamai
  * Communication as a Service (CaaS)
    * A cloud based value-added switching service
    * No-hardware private VoIP switching eg., PBX/IP-Centrex
  * IT as a Service (ITaaS)
    * When the IT group in a company competes for the business of a division, instead of being mandated by corporate leadership (profit, not a cost center) 
* ![image-20200106110205371](D:\OneDrive\Pictures\Typora\image-20200106110205371.png)



## Use Cases

* Cloud-based clients (virtual desktops)
  * reduce admin/support cost & effort
    * update/patch can be applied centrally
    * eases backup/recovery tasks
    * more homogeneity
    * user-specific hardware
  * reduce fixed cost of per-user hardware
    * enables BYOD (bring your own device)
  * increase organizational security
  * users work from anywhere
  * offline problem?
  * central point of failure
  * less user customization/expressiveness
* Obama for America (OFA): re-election campaign
  * rapid data integration & predictive analysis
  * lots of replication, backups & snapshots
  * services are load balanced clusters + replicated RDS
  * ![image-20200106111544261](D:\OneDrive\Pictures\Typora\image-20200106111544261.png)
  * isolated copies for testing, staging changes
* Cycle Computing: On-demand Supercomputers
  * ![image-20200106111625786](D:\OneDrive\Pictures\Typora\image-20200106111625786.png)
  * bioinformatics
  * proteomics
  * computational chemistry
* Start-ups
* Data analytics
  * ![image-20200106112045034](D:\OneDrive\Pictures\Typora\image-20200106112045034.png)
  * ![image-20200106112057765](D:\OneDrive\Pictures\Typora\image-20200106112057765.png)
  * ![image-20200106112112474](D:\OneDrive\Pictures\Typora\image-20200106112112474.png)
* Lambda Architecture
  * ![image-20200106112131544](D:\OneDrive\Pictures\Typora\image-20200106112131544.png)
* Cloud-migration
* Enterprise clusters / private clouds
  * First step: virtualizaing machines (VM)
    * still on per-purpose dedicated clustsers
    * low utilization
    * little heterogeneity
    * delays in new deployment
  * promised benefits
    * consolidation: economic, high server utlization
    * aggregation
    * rapid deployment
  * private clouds
    * cluster infrastructure shared by many groups/purposes
    * org size
    * hybrid cloud? (overflow shifted to public cloud)
    * Google infrastructure
      * huge-scale private cloud
      * workloads are very heterogeneous & dynamic
      * resource heterogeneous & dynamic



## Building a CMU Cloud

* 