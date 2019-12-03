# [Foreshadow: Extracting the Keys to the Intel SGX Kingdom with Transient Out-of-Order Execution](https://foreshadowattack.eu/foreshadow.pdf)

###### Jo Van Bulck, Marina Minkin, Ofir Weisse, Daniel Genkin, Baris Kasikci, Frank Piessens, Mark Silberstein, Thomas F. Wenisch, Yuval Yarom, and Raoul Strackx

---

### What is the Problem? [Good papers generally solve *a single* problem]

* Intel Software Guard eXtensions (SGX) is believed to provide hardware-enforced confidentiality and integrity guarantees. However, the authors present a practical software-only microarchitectural attack on SGX.

### Summary [Up to 3 sentences]

* In this paper, the authors present the Foreshadow attack which uses a speculative execution bug in recent Intel x86 precessors to reliably leak plaintext enclave secrets from CPU cache.

### Key Insights [Up to 2 insights]

* A delicate race condition in the CPU's access control logic can allow an attacker to use the results of unauthorized memory accesses in transient out-of-order instructions before they are rolled back.
* The enclave secrets (plaintext) reside in L1 data cache.

### Notable Design Details/Strengths [Up to 2 details/strengths]

* The attack, together with Spectre and Meltdown, is focusing on the microarchtecture of Intel x86 CPU instead of software-level exploits.
* Since deferencing unauthorized enclave memory will only apply abort page semantics and return dummy value, Foreshadow takes advantage of `mprotect` to clear the present bit in corresponding page table and lead to a page fault.

### Limitations/Weaknesses [up to 2 weaknesses]

* The attack relies on that accessing the enclave pages first checks the present bit and incurs a page fault while page is not present before the abort page semantics.
* The attack critically relies on secrets broiught into the L1 cache during the enclaved execution.

### Summary of Key Results [Up to 3 results]

* In this paper, the authors present Foreshadow attack which breaks the confidentiality and integrity provided by Intel SGX.

### Open Questions [Where to go from here?]

* Will AMD TrustZone have similar side channel attacks?
* Will the ultimate solution for covering side channel attacks on OoO execution and prefetching be a new CPU architecture?
