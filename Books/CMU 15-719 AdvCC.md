# Advanced Cloud Computing

[spring2019](http://www.cs.cmu.edu/~15719/old/spring2019/syllabus.html)



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





## Elasticity

* Load Balancing Approaches
  * DNS load balancing
    * have one IP address per server machine
    * have DNS reorder the list for each client asking for translation of name
    * expect each client to try IP addresses in list order
    * PLUS: out of band of actual TCP/HTTP requests 
      * can distribute arbitrary bandwidth (not limited by bandwidth of a router) 
    * MINUS: takes a long time to change
      * Tells client a binding of a name to an IP (list), which makes dynamic changing of the binding hard, or at least up to the client
      * [[Q: DNS routing change, is that hard?]]
  * Having Router distribute TCP connection open packets
    * have one IP address for entire web service, which goes to a “load balancing” router 
    * Have that router spread SYN packets sent to web server among different server machine 
      * Recall: client opens TCP connection by sending SYN packet 
    * PLUS: router doesn’t have to think too much 
    * MINUS: decision is for the entire life of the connection which may be too long to do good balancing
  * Having Router distribute individual requests embedded in connections
    * Again have one IP address for entire web service, going to router 
    * Have router be endpoint for TCP connection and interpret the bytes 
      * Thus, it can make routing decisions for specific requests 
    * PLUS: most dynamic approach 
    * MINUS: requires the most processing in the router
* Horizontal scaling (scale-out)
  * adding more (usually identical) instances
  * most use of elasticity is done this way
* Vertical scaling (scale-up)
  * resizing the resources allocated to an existing instance
  * IaaS OS accept & utilize more resources on the fly?
    * More network bandwidth is probably easy 
    * More memory is harder but possible (eg. VM ballooning) 
    * Changing cores is even harder
  * PaaS container might hide resource representation
    * E.g. could provide more MapReduce slots in same machine
* Elasticity Controller Capability
  * Monitoring
    * request/resource usage/load pattern
  * Triggering
    * conditions/thresholds
    * schedule
    * complex formula
  * Actions
    * launch single instances/identical instances/modify existing instances
    * Execute sequence of launches or modifications according to a dependency graph or workflow
    * Execute programs that implement a more abstract action (launch and configure multi-tier service)
* Two-tier services
  * ![image-20200618194013873](D:\OneDrive\Pictures\Typora\image-20200618194013873.png)
  * Built-in elastic load balancing and scheduled actions for containers 
    * Most invoked servers have to complete in less than 60 seconds
  * Built in persistent key-value store (datastore) & non-persistent memcache for simple database tier
* Scaling the virtual network
  * router-based load balancing
  * split the flows
    * OpenFlow
    * load balancing the load balancers
* Load Balancer parallelization
  * CloudWatch
  * AutoScaling, AWS Elastic Load Balancer
  * ![image-20200620135837279](D:\OneDrive\Pictures\Typora\image-20200620135837279.png)
* Scalable Relational DB?
  * ElasTraS
    * ![image-20200620140131945](D:\OneDrive\Pictures\Typora\image-20200620140131945.png)
  * Separate Data at rest from ongoing or recent access & mutation
    * Data at rest is stored in (non-elastic) distributed pay-for-use storage (HDFS)
    * Recent access & mutation servers are elastic (called Owning Transaction Managers, OTM)
  * Database can be partitioned but all transactions restricted to one partition
    * Distributed transactions usually block on locks and bottleneck performance scaling
    * Eliminate distributed transactions by rule – each transaction can touch only data from one partition
      * but want dynamic repartitioning
      * establish a lot of mini-partitions allowing each OTM to manage many
    * ElasTraS data model expresses this as the tree rooted at each row of the primary table
      * All transactions restricted to the tree beneath one row in the root table
      * ![image-20200620140848098](D:\OneDrive\Pictures\Typora\image-20200620140848098.png)
  * Elastic controller is also fault-tolerance manager
    * Servers can shutdown (flush to storage) or start up when controller re-assigns partitions 
    * For the controller itself, reliability provided by replication (Zookeeper)
  * Migrating OTMs with minimal pause
    * push completed work to shared storage to reduce OTM state
    * “fuzzy migrate” of OTM state between servers
    * stop processing requests for final part of migration
    * ![image-20200620140935000](D:\OneDrive\Pictures\Typora\image-20200620140935000.png)
* AWS Auto-Scaling Policies
* [ElaTraS](https://cs.ucsb.edu/sites/default/files/docs/reports/2010-04.pdf)
* ![image-20200620141105212](D:\OneDrive\Pictures\Typora\image-20200620141105212.png)
* ![image-20200620141129256](D:\OneDrive\Pictures\Typora\image-20200620141129256.png)
* ![image-20200620141136735](D:\OneDrive\Pictures\Typora\image-20200620141136735.png)
* ![image-20200620141140952](D:\OneDrive\Pictures\Typora\image-20200620141140952.png)
* ![image-20200620141147679](D:\OneDrive\Pictures\Typora\image-20200620141147679.png)
* Elastic ("Serverless") VM
  * ![image-20200620141209286](D:\OneDrive\Pictures\Typora\image-20200620141209286.png)



## Building a Carnegie Mellon Cloud

* initial CMU cloud
  * ![image-20200620142420823](D:\OneDrive\Pictures\Typora\image-20200620142420823.png)
* Provisioner
  * input
    * computer cores
    * memory
    * storage
      * persistent storage
    * network, special hardware?
    * AWS creates bins (m1.large, ...)
    * elastic IP addresses
    * failure domains & auto-scaling
  * output
    * assignment of users to machines
      * Matching: requested resources ↔ available machines
      * Bin-packing problem: satisfy max possible user requests
        * NP-hard solving, NP-complete solution existing
        * heuristics/assumptions
    * migrating existing users
      * For efficiency: allocate more reliable resources 
      * For capacity: fit more people in the cloud 
      * Cost-benefit problem: migraIon can increase job runImes!
* Scheduler
  * Prioritization
  * Oversubscription
  * Workload constraints
* Encapsulation
  * isolate co-located user processes
    * software/OS
    * avoid env. configuration changes
    * performance interference
    * files/data private
* Virtualization
  * multiplex single physical resource among multiple software-based resources
    * OS `->` virtual machines
    * Network `->` VLANs
    * Disk `->` virtual disks
  * don't solve perf. interference
* Fault tolerance
  * hardware/software failures
  * [Jeff's SE advice on dist. sys](https://static.googleusercontent.com/media/research.google.com/zh-TW//people/jeff/stanford-295-talk.pdf)
  * Storage
    * replication (within/across data centers)
    * RAID
    * ![image-20200620144013522](D:\OneDrive\Pictures\Typora\image-20200620144013522.png)
  * critical infrastructure & services
    * state-machine replication
    * checkpointing
    * logging
    * state-free software design?
* Provide services as building blocks
  * Storage services: scalable, fault tolerant data stores 
    * E.g., key-value stores, file systems, databases
  * Tools: Programming models and frameworks
    * E.g., analytics, HPC clusters, training AI models
  * Automation: Reactive systems and elastic scaling
    * E.g., monitoring and tracking, load balancers
  * ![image-20200620144515028](D:\OneDrive\Pictures\Typora\image-20200620144515028.png)
* Programming frameworks
  * MapReduce, DryadLINQ, Spark
  * Built as distributed software
    * Have their own scheduler
    * Have their own fault tolerance mechanisms
* Elastic scaling
  * Observed load for a service is variable
  * Traditional solution: provision for peak
  * • The Elastic scaling approach 
  * Cloud monitors load 
  * Adds application instances as necessary
* Monitoring and diagnosis
  * Cloud monitors user applicaAons 
    * Provides alerts when thresholds crossed
    * Ganglia, AWS CloudWatch
  * Cloud provides tracing libraries
    * Analyzes traces for problem root causes
    * Dapper
* ![image-20200620144712850](D:\OneDrive\Pictures\Typora\image-20200620144712850.png)
* OpenNebula
  * Private / hybrid IaaS cloud
  * OpenNebula is a VI manager used to deploy and manage VMs. Haizea is a resource (lease) manager and scheduling backend
    * ![image-20200620144806712](D:\OneDrive\Pictures\Typora\image-20200620144806712.png)
  * A VI management solution with a flexible and open architecture for building private/hybrid clouds
  * ![image-20200620144814439](D:\OneDrive\Pictures\Typora\image-20200620144814439.png)
  * OpenNebula core: orchestrates use of driver plugins
    * Virtualization drivers: Functions for setting up, starting, stopping VMs, etc. 
    * Network drivers: Functions for assigning network addresses 
    * Storage drivers: Functions for attaching network storage resources 
    * External cloud drivers: Functions for putting VMs on an external cloud (e.g., EC2)
  * Scheduler: decides which VMs get which physical resources
* OpenStack
  * resource provisioning
    * HW arch./memory capacity/storage capacity/network conn./geo-location
    * resource avail./application perf profiling/software service requirements
  * IaaS Cloud
    * deploy a private cloud
    * offer an IAAS public cloud services
  * Cloud spectrum
    * IaaS (dynamically provision VMs, Storage, networking) `->` SaaS (flexible access to hosted services)
  * ![image-20200620160122277](D:\OneDrive\Pictures\Typora\image-20200620160122277.png)
* OpenStack
  * Controls pools of compute, storage, and networking resources in a datacenter.
  * Managed through a dashboard that gives 
    * administrators control 
    * users ability to provision resources through a web interface
  * ![image-20200620160447014](D:\OneDrive\Pictures\Typora\image-20200620160447014.png)
  * Open philosophy
  * Open source cloud computing framework that uses computing and storage infrastructure to provide a platform to offer cloud services on standard hardware.
    * Offer a common open-source framework and a community
    * Offers compatibility with Amazon Web Services
  * Provides management infrastructure for existing underlying technologies
    * E.g., manages usual QEMU/KVM or Xen hypervisor, LXC, Docker, Linux bridge and VXLAN networking, etc
  * OpenStack services
    * All services authenticate through a common Identity service
    * Individual services interact with each other through public APIs, except where privileged administrator commands are necessary
    * Provides a modular architecture to reuse existing infrastructure to manage various types of resources
    * ![image-20200620160606613](D:\OneDrive\Pictures\Typora\image-20200620160606613.png)
  * ![image-20200620160619871](D:\OneDrive\Pictures\Typora\image-20200620160619871.png)
  * ![image-20200620160630031](D:\OneDrive\Pictures\Typora\image-20200620160630031.png)
  * APIs
    * All OpenStack services have at least one API process 
      * Listens for API requests, preprocesses them and passes them on to other parts of the service. 
    * For communication between the processes of one service 
      * An advanced message queuing protocol (AMQP) message broker is used. 
    * Users can access OpenStack via 
      * the web-based user interface implemented by the dashboard 
      * command-line clients 
      * issuing API requests through tools, browser plug-ins or curl 
    * For applications, several SDKs are available. 
    * All access methods issue REST API calls to the various OpenStack services.
    * ![image-20200620160724657](D:\OneDrive\Pictures\Typora\image-20200620160724657.png)
    * ![image-20200620160731904](D:\OneDrive\Pictures\Typora\image-20200620160731904.png)
    * ![image-20200620160827728](D:\OneDrive\Pictures\Typora\image-20200620160827728.png)
* ![image-20200620160839830](D:\OneDrive\Pictures\Typora\image-20200620160839830.png)
* Keystone – OpenStack Identity
  * Provides authentication and authorization for other OpenStack services and users
  * Provides a catalog of endpoints for all OpenStack services (service discovery)
  * Central to most OpenStack operations, hence the name
  * ![image-20200620160921794](D:\OneDrive\Pictures\Typora\image-20200620160921794.png)
* Nova – OpenStack Compute
  * Use nova to host and manage cloud computing systems.
  * Main modules are implemented in Python (as are most components)
  * OpenStack Compute, nova, interacts with
    * OpenStack Identity for authentication;
    * OpenStack Image service for disk and server images; and
    * OpenStack dashboard for the user and administrative interface.
  * can scale horizontally on standard hardware, and download images to launch instances.
  * ![image-20200620161012557](D:\OneDrive\Pictures\Typora\image-20200620161012557.png)
* Ceilometer - OpenStack Telemetry
  * Polls metering data related to OpenStack services. 
  * Collects event and metering data by monitoring notifications sent from services. 
  * Publishes collected data to various targets including data stores and message queues. 
  * Creates alarms when collected data breaks defined rules.
  * ![image-20200620161050170](D:\OneDrive\Pictures\Typora\image-20200620161050170.png)
* Storage
  * ![image-20200620161102327](D:\OneDrive\Pictures\Typora\image-20200620161102327.png)
* Horizon – OpenStack Dashboard
  * A modular Django web application that provides a graphical interface to OpenStack services.
* OpenStack vs. AWS
  * ![image-20200620161129084](D:\OneDrive\Pictures\Typora\image-20200620161129084.png)
* ![image-20200620161148800](D:\OneDrive\Pictures\Typora\image-20200620161148800.png)
* Web Application
  * ![image-20200620161206398](D:\OneDrive\Pictures\Typora\image-20200620161206398.png)
* Big Data Analytics
  * ![image-20200620161228319](D:\OneDrive\Pictures\Typora\image-20200620161228319.png)
* eCommerce
  * ![image-20200620161238592](D:\OneDrive\Pictures\Typora\image-20200620161238592.png)



## Encapsulation

* Instance properties
  * security isolation
  * performance isolation
  * portability
  * software flexibility
* Infrastructure properties
  * reliability
  * scalability
  * ease of management
  * tool/component availability
* `=>` encapsulation
  *  Specification of an “image”  
    * What will run within the container  
    * E.g., application binaries, data files, filesystem images, disk images
  * Specification of resources needed  
    * Hardware resources, such as CPU, memory, devices  
    * Networking configuration  
    * Other dependencies
* encapsulation options
  * bare metal: Give users entire machines
    * Pro: Good isolation, Software freedom, Best performance  
    * Con: Limits allocation granularity, Software management tricky (drivers, debugging OS)
    * Application + Lib + OS + HW
  * process: Users are allocated traditional OS processes
    * Pro: Well-understood, Good performance, Debugging “easy”  
    * Con: Performance isolation poor, Security questionable, Software freedom poor
    * Application
  * container: Traditional OS hosts process containers, where each container looks like an “empty” OS
    * Pro: Decent software freedom, Good performance  
    * Con: Possible security problems
    * Application + Library/fs/etc
  * virtual machines: Users get a software container that acts like a physical machine
    * Pro: Decent isolation properties, Good software freedom  
    * Con: Performance overhead, Imperfect performance isolation
    * Application + Library/fs/etc + OS
  * ![image-20200621164919705](D:\OneDrive\Pictures\Typora\image-20200621164919705.png)
* Containers
  * Linux: Need OS-based protection and namespaces to limit power of “guest” application
    * Leverage layered file system to enable easy composition of images (e.g. OverlayFS)
  * ![image-20200621165006476](D:\OneDrive\Pictures\Typora\image-20200621165006476.png)
  * Namespaces: restrict what can a container see
    * Provide process level isolation of global resources  
    * Processes have illusion they are the only processes in the system
    * Examples
      * MNT: mount points, file systems (what files, dir are visible)?  
      * PID: what other processes are visible?  
      * NET: NICs, routing  
      * Users: what uid, gid are visible?  
      * `chroot`: change root directory 
  * `cgroups` resource allocation
    * Set upper bounds (limits) on resources that can be used  
    * Fair sharing of certain resources
    * Examples
      * cpu: weighted proportional share of CPU for a group  
      * cpuset: cores that a group can access  
      * block io: weighted proportional block IO access  
      * memory: max memory limit for a group
* Virtual machines
  * ![image-20200621165227144](D:\OneDrive\Pictures\Typora\image-20200621165227144.png)
  * Fidelity  
    * Software operation identical when virtualized/not 
  * Isolation  
    * A guest may not directly affect VMM or other guests  
  * Performance  
    * Providing fidelity and isolation must not yield unacceptable performance  
    * Implies that most operations must execute natively
  * Advantages
    * Compatibility  
      * Run software A on system B (e.g. VMM translates IDE to SCSI)  
      * Rapid deployment (e.g. scale out on EC2)  
    * Consolidation  
      * Multiple VMs may run on same host  
    * State capture  
      * Suspension of running VM  
      * Migration  
      * Checkpointing/replication  
    * Observability  
      * Record/replay for debugging/forensics  
      * Fault-tolerance
  * Techniques
    * Privileged instructions
      * Instructions that write privileged state  
        * Including privileged instructions that silently fail (e.g. `popf`)  
      * Instructions that read privileged state  
        * Including non-privileged instructions that reveal privileged state (e.g. `pushf`)
      * Non-CPU devices must be treated carefully as well  
        * e.g. a VM must not be allowed to cause a DMA into memory not belonging to that VM
      * Trap-and-emulate  
        * Sensitive operations executed in the VM trap to VMM for handling  
        * The VMM emulates the behavior of the operation  
        * Includes modern HW virtualization such as VT-x  
      * Static software re-writing/“paravirtualization”  
        * Avoid issuing sensitive operations in the VM by re-writing guest OS to leverage VMM “hypercalls”  
        * Better performance by sacrificing transparency  
      * Dynamic software re-writing  
        * VMM transparently re-writes portions of the guest’s privileged code– coalescing traps  
        * Extensively used in PC VMMs prior to HW virtualization maturity  
        * Good performance, but VMM may be complex
      * x86 HW Virtualization
        * Intel introduced VT-x in 2005 
        * Essentially, trap-and-emulate with new “non-root” privilege levels (Option 3) 
        * Redefined behavior of some sensitive operations in non-root mode 
        * Interrupts are typically delivered to VMM (and vectored to guests as needed)
        * A VM Control Structure (VMCS) defines CPU operation
          * Guest-state area. Processor state is saved into the guest-state area on VM exits and loaded from there on VM entries.  
          * Host-state area. Processor state is loaded from the host-state area on VM exits.  
          * VM-execution control fields. These fields control processor behavior in VMX non- root operation. They determine in part the causes of VM exits.  
          * VM-exit control fields. These fields control VM exits.  
          * VM-entry control fields. These fields control VM entries.  
          * VM-exit information fields. These fields receive information on VM exits and describe the cause and the nature of VM exits. They are read-only.
    * Memory
      * Guest OSes manage “guest physical (GP)” memory  
        * Mapping “guest virtual (GV)” `->` “guest physical” memory
      * VMM manages “host physical (HP)” memory  
        * Mapping “guest physical” `->` “host physical”
        * SW: Shadow page tables  
          * HW: Extended page tables (EPT)
    * Devices
      * Emulation
      * Mapping: Give control to a particular guest  
        * May require hardware support (e.g. VT-d)  
      * Partitioning: e.g. disk drive partitions  
      * Guest enhancements: provide special VM `->` VMM calls  
      * Virtualization-enhanced devices: e.g. NICs with VMDq
  * Issues
    * Multiple VMs may be handled through either partitioning or time-slicing.
    * Time-slicing is required if the number of virtual cores exceeds the number of physical cores.  
    * When the VMs are multiprocessor, gang- scheduling the virtual cores may improve performance.
  * Bare metal vs. Hosted
    * ![image-20200621170216962](D:\OneDrive\Pictures\Typora\image-20200621170216962.png)
  * Isolation
    * network interference can be reduced  
      * All traffic can be intercepted by VMM  
      * The VMM can create virtual networks– routing, VLANs
    * Some unexpected hardware vulnerabilities have been identified
      * RowHammer:Yoongu Kim, et al. 2014. Flipping bits in memory without accessing them: an experimental study of DRAM disturbance errors. ISCA '14.  
        * Repeatedly accessing DRAM rows may corrupt adjacent DRAM rows– even if they belong to other VMs/containers  
      * Meltdown/Spectre: https://meltdownattack.com/  
        * Speculative execution in processors may expose containers/VMs to sidechannel attacks
  * Recursive Virtualization
  * State Capture
    * Capturing the state of a running VM implies all architectural state  
      * Processor state: registers (incl. general purpose, privileged, EIP), hidden state  
      * Device state: config, buffers, transactions in flight, etc  
      * Memory state: config, contents  
      * Disk image
    * Live Migration
      * VM encapsulation enables migration of running software  
        * Useful in data center for load balancing, upgrades, etc  
        * Not new, just “easier” (see process migration)
      * Metric: machine “downtime”  
        * Success if less than typical network hiccups (TCP timeout)
      * Challenge: a lot of memory to move
      * Strategy: pre-transfer the memory pages
        * Then, check for additional dirty pages, wash, rinse, repeat  
        * When \# dirty pages < threshold, send remaining, jump
* Software contracts: software layers provide clean interfaces



## Programming Models & Frameworks I

*  ![image-20200621173650431](D:\OneDrive\Pictures\Typora\image-20200621173650431.png)
* Service, Platform, or Infrastructure as a Service 
  * SaaS: service is a complete application (client-server computing) 
    * Not usually a programming abstraction 
  * PaaS: high-level (language) programming model for cloud computer 
    * Turing complete but resource management hidden 
  * IaaS: low-level (language) computing model for cloud computer 
    * Basic hardware model with all (virtual) resources exposed
* Collection-oriented languages
  *  J. M. Sipelstein and G. E. Blelloch, CMU-CS-90-127, 1990
  *  “data-parallel”: specify op on element; apply to each in collection 
    * Analogy to SIMD operation: single instruction on multiple data
  * Specify an operation on the collection as a whole
    * Union/intersection 
    * Permute/sort 
    * Filter/select/map 
    * Reduce-reorderable: ADD(1,7,2) = (1+7)+2 = (2+1)+7 = 10 
    * Reduce-reordered: CONCAT(“the”, “lazy”, “fox”) = “the lazy fox”
* HPC approach
  * Bulk Synchronous Processing (BSP)
  * Defined “Weak Scaling” for N processors 
    * Strong scaling: same problem finishes N times faster 
    * Weak scaling: N times bigger problem finishes at same time 
    * Important scaling factor: set problem size to match total available memory
  * Message Passing Interface (MPI) (e.g. MPICH)
    * Launch N threads with library routines for everything you need: 
      * Naming, addressing, membership, messaging, synchronization (barriers), transforms, physics modules, math libraries, etc
  * Resource allocators and schedulers space-share jobs on physical cluster
  * Fault tolerance by checkpoint/restart requiring programmer save/restore 
    * Proto-elasticity: kill N-node job and reschedule a past checkpoint on M nodes
* Grid Computing
  * commodity servers
  * Frameworks were less specialized, easier to use (and less efficient!)
  * For funding reasons grid emphasized geographical sharing
    * Enabling collaboration between multiple institutions
    * So authentication, authorization, single-sign-on, parallel-ftp
    * Heterogeneous workflow (run job A on machine B, job C on machine D)
  * • Basic model: jobs selected from batch queue, take over cluster
* ![image-20200621185507314](D:\OneDrive\Pictures\Typora\image-20200621185507314.png)
* [[R: CS239A paper notes]]
* MapReduce
  * Parallelism
    * Break down jobs into distributed independent tasks to exploit parallelism 
  * Scheduling 
    * Consider data-locality and variations in overall system workloads for scheduling 
  * Fault Tolerance 
    * Transparently tolerate data and task failures
  * Hadoop
  * Process
    * Read a large input data set 
    * Process the input data in chunks independently (e.g., filter) 
    * Shuffle and Sort intermediate data 
    * Aggregate or summarize intermediate data independently 
    * Write the result
  * assumes a tree style network topology
  * ![image-20200621190008987](D:\OneDrive\Pictures\Typora\image-20200621190008987.png)
  * ![image-20200621190031246](D:\OneDrive\Pictures\Typora\image-20200621190031246.png)
  * Job Scheduling
    * [[C: check CS239A for advanced scheduling]]
  * [[T: add some details]]
* DryadLINQ
  * Goal: Simplify writing data-parallel code 
    * Added compiler support for imperative and declarative ops on data 
    * Extends the MapReduce model by collectively optimizing workflows
  * Data flows between processes
    * Graph abstraction: Expressions on data represent workflow between processes
      * Vertices are programs (possibly different with each vertex)
      * Edges are data channels (pipe-like)
      * Requires programs to have no side-effects (no changes to shared state)
      * ![image-20200621190229138](D:\OneDrive\Pictures\Typora\image-20200621190229138.png)
  * Rewrite execution plan to execute faster 
    * Knows how to partition sets (hash, range and round robin) over nodes
    * Doesn’t always know what processes do, but accepts hints from users
    * Can auto-pipeline, remove redundant partitions, reorder partitions, etc
  * Inspired by database query optimizations
  * ![image-20200621190202379](D:\OneDrive\Pictures\Typora\image-20200621190202379.png)
* Spark
  * Optimize MR for iterative apps
  * more general (dryad-like graphs of work), more interactive (Scala interpreter), more efficient (in-memory)
  * RDDs: abstraction for parallel, fault-tolerant computation
    * Splits a set into partitions for workers to parallelize operation
    * Fault-tolerance through lineage graphs showing how to recompute data
  * Store invocation (code and args) with inputs as a closure
    * Treated as “future” contract: compute now/later at system’s choice (lazy)
    * If code inputs already at node X, “args” is faster to send than results
      * Futures can be used as compression on wire and in replica nodes
  * Replication/FT: ship and cache RDDs on other nodes
* TensorFlow/GraphLab



## Storage in the Cloud I

* 