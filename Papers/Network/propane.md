# Network Configuration Synthesis with Abstract Topologies‎

**Ryan Beckett, Ratul Mahajan, Todd Millstein, Jitendra Padhye, David Walker**

---

## Summary

* This paper presents Propane/AT, a system to synthesize BGP configurations. Propane/AT takes abstract topologies, high-level specification of routing policy and fault-tolerance requirements as inputs, and generate templates for each role of the network. Abstract topologies defines the structural and role-based invariants, is the compact version of the concrete network. Routing policies specify the traffic predicates, paths and ranks using customized DSL from Propane. Propane then combines the topologies and routing policies into a product graph computed by DFA (capture the flow of routing info over the topology), checks the feasibility of fault tolerance requirements by sound static analysis (inferencing minimum number of edge-disjoint, policy-compliant paths between pairs of nodes), and generates templates from product graphs to compile to vendor-independent mBGPs. If given concrete topologies, the templates can be instantiated by replacing instances of abstract neighbors with the union of all concrete neighbors and replacing prefix template variables with separate entries for each concrete prefix provided. They also proposes a method to compile incrementally only dependent on nodes' direct neighbors. 
* This work reminds me of the website generators, generating web pages configuration templates, which will be filled using backend-provided information. To alleviate the stress of network maintainers, could we feed old configurations into the system and infer some autocomplete holes instead of using whole template engines? Moreover, could we generate the abstract topologies from analyzing the existing network, with a interactive system cooperating with maintainers (using static analysis or machine learning)?
* [NetComplete](https://www.usenix.org/conference/nsdi18/presentation/el-hassany)



## Introduction

* While they think of their network abstractly, in terms of roles, current synthesis systems operate over concrete topologies  
* Even if two devices play the same role, operators cannot specify policy in terms of this role; and even
  if specifications for the two devices are similar, there is no guarantee that the systems will generate (syntactically) similar configurations. Perhaps most importantly, if the operators want to debug or analyze system output, they will have to consider hundreds of device configurations instead of just a
  handful of role configurations  
* Brittle in network evoluation
* Propane/AT allows operators to input abstract topologies in terms of roles and their connectivity  
  * high-level specification of routing policy  (abstract roles)
  * fault-tolerance requirements of the network  
  * generates one template per role  
* 

