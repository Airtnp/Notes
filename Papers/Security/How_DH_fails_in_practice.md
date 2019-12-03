# [How Diffie-Hellman Fails in Practice](https://weakdh.org/imperfect-forward-secrecy-ccs15.pdf)

###### David Adrian, Karthikeyan Bhargavan, Zakir Durumeric, Pierrick Gaudry, Matthew Green, J. Alex Halderman, Nadia Heninger, Drew Springall, Emmanuel Thomé, Luke Valenta, Benjamin VanderSloot, Eric Wustrow, Santiago Zanella-Béguelin, and Paul Zimmermann

---

### What is the Problem? [Good papers generally solve *a single* problem]

* The popularly used Diffie-Hellman key exchange mechanism is less secure than widely believed.

### Summary [Up to 3 sentences]

* In this paper, the authors present Logjam, a novel flaw in TLS that lets a man-in-the-middle downgrade connections to 512-bit length key "export-grade" Diffie-Hellman and use number field sieve discrete log algorithm and precomputation on a specified 512-bit group to compute arbitrary discrete logs quickly.

### Key Insights [Up to 2 insights]

* An adversay who performs a large precomputation for a prime p (number field sieve discrete log algorithm) can quickly calculate arbitrary discrete logs in that group, amortizing the cost over all targets that share this parameter.
* For both normal and export-grade Diffie-Hellman, the vast majority of servers use a handful of common prime groups.

### Notable Design Details/Strengths [Up to 2 details/strengths]

* The comply with 90s-era U.S. export restriction on cryptography, SSL 3.0 and TLS 1.0 supported reduced-strength DHE_EXPORT ciphersuites that were restricted to primes no longer than 512 bits.
* 8.4% of Alexa Top 1M HTTPS domains allow DHE_EXPORT, of which 92.3% use one of the two most popular primes. 

### Limitations/Weaknesses [up to 2 weaknesses]

* The attack requires that the server allows DHE_EXPORT and uses precomputed primes.
* The attack requires browsers which allow 512-bit prime key in DHE handshakes.

### Summary of Key Results [Up to 3 results]

* The authors present a MITM TLS flaw Logjam using weakness of "export-grade" Diffie-Hellman and common browsers.
* By using number field sieve algorithm, an attacker can perform a single precomputation that depends only on the group and then computes individual logs in that group in a lower cost.
* By estimation the core time of using NFS, the authors believe that computation up to 1024-bit DH key exchange is feasible given nation-state resources and NSA may have already done that.

### Open Questions [Where to go from here?]

* Can we find another flaws which originate in the lack of communication between scholars in different fields (crypto and system)?
*  Can we find another flaws which originate in some historical reasons (90s-era ban on exporting algorithm)?
*  Can we find another flaws which originate in the improvement on calculation power?