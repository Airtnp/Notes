

# Quantum Computing

[fall2015](https://www.cs.cmu.edu/~odonnell/quantum15/)



## Intro. to Quantum Circuit Model

* > If we simply regard the particles following their natural quantum-mechanical behavior as a computer, then this “quantum computer” appears to be performing a certain computation (namely, simulating a quantum system) exponentially more efficiently than we know how to perform it with a normal, “classical” computer

* Classical Boolean Circuits

  * ![image-20200401004910636](D:\OneDrive\Pictures\Typora\image-20200401004910636.png)
  * efficiency
  * ![image-20200401004946565](D:\OneDrive\Pictures\Typora\image-20200401004946565.png)
  * ![image-20200401004959845](D:\OneDrive\Pictures\Typora\image-20200401004959845.png)
  * lines `->` wires
  * rectangles `->` gates
  * duplicate gate (`DUPE`)
    * [[N: substructural logic? weakening?]]
  * ![image-20200401005058215](D:\OneDrive\Pictures\Typora\image-20200401005058215.png)
  * ancilla bit: hardwired to 1/0
    * E.g. `NAND(DUPE(x)) = NOT`
  * Boolean `NAND` & `DUPE` gates are universal for computation
    * conversion can be efficient `size(C') = O(size(C))`

* Bra-ket notation

  * kets: `|011>`, `|0>`, `|1>`

* Reversible computation

  * `|0/1>` theoretical bits `=>` a particle or bunch of particles (hi/lo voltage on a phy. wire)

  * gates `=>` physical objects (switch or something) that manipulates the bit-representations

  * > We then would ideally like to think of the circuit as a “closed physical system”. Unfortunately, for a typical AND/OR/NOT/DUPE circuit, this is not possible
    >
    > laws of physics governing microscopic systems (both classical and quantum) are reversible with respect to time, but this is not true of most gates we would like to physically implement
    >  The AND process is not reversible: information sometimes needs to be deleted; “entropy” is lost. 
    >
    > According to the 2nd Law of Thermodynamics, a physical system consisting of a single AND gate cannot be “closed”; its operation must dissipate some energy — typically as escaping heat. 
    >
    > On the other hand, a NOT gate is theoretically “reversible”: its output can be determined from its input; no information is created or destroyed in switching |0> to a |1> or vice versa. 
    >
    > Thus, in principle, it is possible to construct a completely closed physical system implementing a NOT gate, without the need for energy dissipation

  * reversible `<=>` entropy preserve `<=>` no energy dissipating

  * reversible Boolean gate `G`: if has the same number of inputs as outputs, mapping from input strings to output strings is a bijection

  * `CNOT` gate (controlled-NOT) $\oplus$

    * ![image-20200401010707064](D:\OneDrive\Pictures\Typora\image-20200401010707064.png)
    * ![image-20200401010721300](D:\OneDrive\Pictures\Typora\image-20200401010721300.png)

  * `CCNOT` (controlled-controlled-NOT / Toffoli gate)

    * ![image-20200401010740221](D:\OneDrive\Pictures\Typora\image-20200401010740221.png)
    * the third input is negated if and only if the first two “control” input bits are both `|1>`
    * can simulate `NAND` & `DUPE`
    * ![image-20200401010922389](D:\OneDrive\Pictures\Typora\image-20200401010922389.png)
      * produce extra/unwanted bits (garbage)
      * [[Q: the construction  makes it inreversible, indicating existence of garbage?]]
    * generate `|0>` from `|1>`
      * ![image-20200401011101596](D:\OneDrive\Pictures\Typora\image-20200401011101596.png)
    * ![image-20200401011124630](D:\OneDrive\Pictures\Typora\image-20200401011124630.png)
    * ![image-20200401011153670](D:\OneDrive\Pictures\Typora\image-20200401011153670.png)

  * ![image-20200401010827828](D:\OneDrive\Pictures\Typora\image-20200401010827828.png)

  * > With “standard” circuits, the number of wires carrying a bit at any one “time” (vertical slice) may vary. However with reversible circuits, this will always equal the number of inputs+ancillas, as you can see above

  * ![image-20200401011249229](D:\OneDrive\Pictures\Typora\image-20200401011249229.png)

* Randomized computation

  * `COIN` gate `COIN-/$-`: half `|0>` and half `|1>`

  * ![image-20200401135306001](D:\OneDrive\Pictures\Typora\image-20200401135306001.png)

  * `CCOIN` (controlled `COIN`)

    * ![image-20200401135515593](D:\OneDrive\Pictures\Typora\image-20200401135515593.png)

  * ![image-20200401140905232](D:\OneDrive\Pictures\Typora\image-20200401140905232.png)

  * > As a small note, we typically imagine that we provide the inputs to a randomized circuit, and then we observe (or measure) the outputs. The probabilistic “state” of the registers at some intermediate time in the circuit’s execution reflects only the uncertainty that we, the observers, have about the registers’ values. Of course, in reality the registers always have some definite value; it’s merely that these variables are “hidden” to us. Analytically, once we observe one or more of the r-bits, the probabilistic state “collapses” to reflect the information we learned.

* Quantum computation

  * >  it is kind of like what you would get if you took randomized computation but found a way to allow the “probabilities” to be negative

  * classcial reversible computation augmented with Hadamard gate `-H-`

  * ![image-20200401141549296](D:\OneDrive\Pictures\Typora\image-20200401141549296.png)

  * ![image-20200401142437200](D:\OneDrive\Pictures\Typora\image-20200401142437200.png)

  * ![image-20200401142444527](D:\OneDrive\Pictures\Typora\image-20200401142444527.png)

  * amplitudes $\alpha, \beta, \cdots$ (possibly negative real numbers)

  * superposition

  * ![image-20200401142612721](D:\OneDrive\Pictures\Typora\image-20200401142612721.png)

  * ![image-20200401142649783](D:\OneDrive\Pictures\Typora\image-20200401142649783.png)

  * Shor algorithm: n-bit integer input, using roughly $n^2$ CCNOT & H gates, giving at least 99% the binary encoding of the prime factorization of the input integer (+ some garbage bits)

  * > As mentioned in a footnote, it is a theorem that CCNOT and Hadamard gates together are universal for quantum computation. But they are not the only gates that are allowed by the physical laws of quantum computation. In the next lecture we will see just what gates nature does allow. For now, though, we will mention that any classical reversible gate is okay, and it’s convenient to allow NOT and CNOT

  * > According to the laws of physics, in the middle of a quantum circuit’s computation, the superposition state that the n qubits are in is literally the true state they’re in in Nature. They are not secretly in one of the basic states; Nature is literally keeping track of the 2n amplitudes. (This gives you a hint of the potential computational power of quantum mechanics!)



​	

## Quantum Math Basics

* $a+bi$

* $z_1 \cdot z_2 = |z_1| \cdot |z_2| \cos(\theta_1 + \theta_2)$

* $\bar{z} = z^* = z^{\dagger} = a - bi$

* $(z_1, \cdots, z_d) \cdot (w_1, \cdots, w_d) = z_1^{\dagger}w_1 + \cdots + z_d^{\dagger} w_d$

* Quantum bits (qubit)

  * qubit: can be in linear combination of states (superpositions)

  * $\mid \psi \rangle = \alpha |0 \rangle + \beta |1 \rangle$

  * $|+\rangle = \frac{1}{\sqrt{2}} |0\rangle + \frac{1}{\sqrt{2}}|1\rangle$

  * $|-\rangle = \frac{1}{\sqrt{2}} |0\rangle - \frac{1}{\sqrt{2}}|1\rangle$

  * > complex phases are intrinsic to many quantum algorithms, like the Shor’s Algorithm for prime factorization. Complex numbers can help us gain some intuitions on those algorithms
    >
    > complex numbers are often just simpler in terms of describing unknown quantum states, and carrying out computations

  * qubit implementation: two states of an electron orbiting an atom; by 2 directions of the spin (intrnsic angular momentum) of a particle; by 2 polarization of a photon

  * ![image-20200401161428201](D:\OneDrive\Pictures\Typora\image-20200401161428201.png)

  * Multiple Qubits & Qudit System

    * ![image-20200401161624372](D:\OneDrive\Pictures\Typora\image-20200401161624372.png)
    * ![image-20200401170055227](D:\OneDrive\Pictures\Typora\image-20200401170055227.png)
    * qudit system: d-spin quantum number particles
      * can construct any qudit system using only qubits

  * Qubits - Mathematics

    * ![image-20200401171008701](D:\OneDrive\Pictures\Typora\image-20200401171008701.png)
    * $|\psi\rangle$: column vector (__ket__)
    * $\langle \psi |$: row vector dual  (__bra__) (conjugate transpose)
    * inner/dot product: $\langle x_1 | \cdot | x_2 \rangle, \langle x_1 | x_2 \rangle$
    * outer product: $|x_1\rangle \cdot \langle x_2|, |x_1 \rangle \langle x_2|$
    * $tr(|x_1 \rangle \langle x_2|) = \langle x_1 | x_2 \rangle$
    * orthonormal basis

  * Multiple Qubit System - Mathematics

    * tensor product of kets/joint state $\otimes$: $|a\rangle \otimes |b\rangle = \sum_j \sum_k \alpha_j \beta_k (|a_j\rangle \otimes |b_k\rangle) = \sum_j \sum_k \alpha_j \beta_k (|jk\rangle)$
      * not commutative
    * entangled states: not all states in the multiple-qubit system are of tensor product form (product states)
      * ![image-20200401173325925](D:\OneDrive\Pictures\Typora\image-20200401173325925.png)

* Quantum Computing

  * ![image-20200401174133849](D:\OneDrive\Pictures\Typora\image-20200401174133849.png)
  * ![image-20200401174420225](D:\OneDrive\Pictures\Typora\image-20200401174420225.png)
  * `=>` $U \in \mathbb{C}^{d \times d}$ is unitary ($U^{\dagger}U = I$)
  * The angle between two quantum states preserves under any unitary operations (inner product the same)
  * Unitary operations are invertible (reversible) and its inverse is its conjugate transpose
    * $|\psi\rangle - U - U^{\dagger} - |\psi \rangle$
  * Unitary operations are equivalent to changes of basis
    * ![image-20200401174601269](D:\OneDrive\Pictures\Typora\image-20200401174601269.png)
  * ![image-20200401174629072](D:\OneDrive\Pictures\Typora\image-20200401174629072.png)
  * Multiple Qubits System
    * Kronecker/tensor product on matrices $U \otimes V$
      * ![image-20200401174814721](D:\OneDrive\Pictures\Typora\image-20200401174814721.png)
    * $(U \otimes V)(|q_0 \rangle \otimes | q_1 \rangle) = (U | q_0\rangle) \otimes (V |q_1 \rangle)$
    * ![image-20200401175034626](D:\OneDrive\Pictures\Typora\image-20200401175034626.png)

* Measurements

  * ![image-20200402093013857](D:\OneDrive\Pictures\Typora\image-20200402093013857.png)
  * Partial Measurement
    * ![image-20200402111813111](D:\OneDrive\Pictures\Typora\image-20200402111813111.png)
    * ![image-20200402111826159](D:\OneDrive\Pictures\Typora\image-20200402111826159.png)



## The Power of Entanglement

* every quantum circuit can be thought of as a unitary matrix acting on the space of quantum states
* Copying bits
  * No-cloning theorem
    * ![image-20200403024549044](D:\OneDrive\Pictures\Typora\image-20200403024549044.png)
    * ![image-20200403024727732](D:\OneDrive\Pictures\Typora\image-20200403024727732.png)
    * failed to copy an arbitrary quantum state into 2 unentangled copies
    * there does not exist any quantum circuit which can take in an arbitrary qubit |ψ> and produce the state |ψ> ⊗ |ψ>, even when permitted to use ancillas in the input and garbage in the output
    * ![image-20200403024715036](D:\OneDrive\Pictures\Typora\image-20200403024715036.png)
    * ![image-20200403025209293](D:\OneDrive\Pictures\Typora\image-20200403025209293.png)
    * There is no circuit which can take as input a single `p`-biased random bit (`COIN_p` gate) & return as output 2 independently distributed `p`-biased bits
  * EPR pairs
    * ![image-20200403125439652](D:\OneDrive\Pictures\Typora\image-20200403125439652.png)
    * $\frac{1}{\sqrt{2}}|00\rangle + \frac{1}{\sqrt{2}}|11\rangle$
    * ![image-20200403131102694](D:\OneDrive\Pictures\Typora\image-20200403131102694.png)
* Quantum teleportation
  * EPR pair bits can share results even physically separated (measurement)
  * ![image-20200403140405362](D:\OneDrive\Pictures\Typora\image-20200403140405362.png)
  * ![image-20200403140757741](D:\OneDrive\Pictures\Typora\image-20200403140757741.png)
  * ![image-20200403140810244](D:\OneDrive\Pictures\Typora\image-20200403140810244.png)
  * ![image-20200403140815227](D:\OneDrive\Pictures\Typora\image-20200403140815227.png)
  * EPR pair + 2 classical bits `=>` send quantum state!
    * not a violation of the no-cloning theorem since Alice no longer has a copy of the quantum state
    * not a violation of Einstein’s special/general relativity since the necessary classical bits could not have been communicated faster than the speed of light
      * ![image-20200403140950547](D:\OneDrive\Pictures\Typora\image-20200403140950547.png)
* Measuring in a different basis
  * standard/computational basis $|\psi\rangle = \alpha_0 |0\rangle + \alpha_1 |1\rangle$ in the basis of $\{|0\rangle, |1\rangle\}$
    * ![image-20200403142206499](D:\OneDrive\Pictures\Typora\image-20200403142206499.png)
    * ![image-20200403142553570](D:\OneDrive\Pictures\Typora\image-20200403142553570.png)
    * ![image-20200403142558458](D:\OneDrive\Pictures\Typora\image-20200403142558458.png)
  * orthonormal basis $\{|v\rangle, |v^{\bot}\rangle\}$: $|\psi \rangle = \beta_v | v \rangle + \beta_{v^{\bot}} | v^{\bot} \rangle$
    * ![image-20200403142605011](D:\OneDrive\Pictures\Typora\image-20200403142605011.png)
    * $\beta_v = \langle v | \psi \rangle, \beta_{v^{\bot}} = \langle v^{\bot} | \psi \rangle$
    * ![image-20200403142755170](D:\OneDrive\Pictures\Typora\image-20200403142755170.png)
  * ![image-20200403142805832](D:\OneDrive\Pictures\Typora\image-20200403142805832.png)
  * ![image-20200403175939179](D:\OneDrive\Pictures\Typora\image-20200403175939179.png)
    * ![image-20200403180008043](D:\OneDrive\Pictures\Typora\image-20200403180008043.png)
  * ![image-20200403180027011](D:\OneDrive\Pictures\Typora\image-20200403180027011.png)
* CHSH Game
  * ![image-20200403180637516](D:\OneDrive\Pictures\Typora\image-20200403180637516.png)
  * Classical strategy
    * ![image-20200403182200758](D:\OneDrive\Pictures\Typora\image-20200403182200758.png)
  * Quantum strategy
    * Alice and Bob each share a qubit of an EPR pair
    * Alice and Bob will independently decide which basis to measure their qubit in the EPR pair based on the random bit they receive
    * ![image-20200403183043580](D:\OneDrive\Pictures\Typora\image-20200403183043580.png)
    * ![image-20200403183049243](D:\OneDrive\Pictures\Typora\image-20200403183049243.png)





## Grover's Algorithm

* unstructured search `=>` database search
  * no guarantee as how the database is ordered
* ![image-20200404220911609](D:\OneDrive\Pictures\Typora\image-20200404220911609.png)
* The unstructured search problem can be solved in $O(\sqrt{N})$ using quantum computation
  * the query complexity is $\Theta(\sqrt{N})$
  * Note: if we did have a logarithmic time algorithm, we could, given $n$ variables arranged in clauses, solve the SAT problem by searching all $2^n$ possibilities in $O(\log(2^n)) = O(n)$
* Grover's algorithm: only use $O(\sqrt{N}\log(N))$ gates
  * only gets the correct answer with high probability, $>\frac{2}{3}$
  * run multiple times to reduce failure $(1/3)^n$
* Classical case
  * oracle $O_f$ that implements a function $f$, encoding information about the element of interest
  * query to the oracle to fetch results from the function
  * black-box $i-O_f-f(i)$
  * best thing: $\Theta(N)$ queries and $\Theta(N)$ running time
* Quantum case
  * assume $f(x^*) = $ is unique
  * assume the size of database is $2^N$
  * assume the data is labeled as $n$-bit Boolean strings in $\{0, 1\}^n$
  * $|x\rangle - O_f - |f(x)\rangle$
  * the oracle gate is not a valid quantum gate: not $n-n$, not unitary
    * fix \# 1: extra bit
      * ![image-20200404221852324](D:\OneDrive\Pictures\Typora\image-20200404221852324.png)
    * fix \# 2: flip the input iff. $f(x) = 1$, $O^{\pm}_f$
      * ![image-20200404221933213](D:\OneDrive\Pictures\Typora\image-20200404221933213.png)
      * send $|-\rangle$ to $f_{flip}$ `=>` $O^{\pm}_f$
* Algorithm
  * ![image-20200404222150732](D:\OneDrive\Pictures\Typora\image-20200404222150732.png)
  * exploit superposition `=>` input into uniform superposition $\sum_{x \in \{0, 1\}^n} \frac{1}{\sqrt{N}}|x\rangle$
    * by Hadamard gate on every wire ($H^{\otimes n}$)
    * ![image-20200404222615732](D:\OneDrive\Pictures\Typora\image-20200404222615732.png)
    * ![image-20200404222840101](D:\OneDrive\Pictures\Typora\image-20200404222840101.png)
  * after applying an Oracle $O^{\pm}_f$
    * ![image-20200404222911867](D:\OneDrive\Pictures\Typora\image-20200404222911867.png)
    * ![image-20200404222916396](D:\OneDrive\Pictures\Typora\image-20200404222916396.png)
  * increase amplitude of $x^*$ absolutely
    * Grover diffusion operator $D$: flip amplitude around the average $\mu$
      * ![image-20200404222946589](D:\OneDrive\Pictures\Typora\image-20200404222946589.png)
      * ![image-20200404222958363](D:\OneDrive\Pictures\Typora\image-20200404222958363.png)
      * unitary, linear, valid quantum gate
    * ![image-20200404223049895](D:\OneDrive\Pictures\Typora\image-20200404223049895.png)
  * apply oracle & Grover diffusion again
    * ![image-20200404223135491](D:\OneDrive\Pictures\Typora\image-20200404223135491.png)
    * ![image-20200404223140692](D:\OneDrive\Pictures\Typora\image-20200404223140692.png)
    * $\alpha_{x^*}$ increases by more than $\frac{1}{\sqrt{N}}$ each time $O^\pm_f \circ D$
    * after $O(\sqrt{N})$ steps, $\alpha_{x^*}$ should exceed the constant $1$ as desired
    * Note: not actually always $1/\sqrt{N}$ because the mean will be dragged to be negative
* Analysis
  * ![image-20200404223407110](D:\OneDrive\Pictures\Typora\image-20200404223407110.png)
  * ![image-20200404223427134](D:\OneDrive\Pictures\Typora\image-20200404223427134.png)
  * ![image-20200404223434635](D:\OneDrive\Pictures\Typora\image-20200404223434635.png)
  * ![image-20200404223448710](D:\OneDrive\Pictures\Typora\image-20200404223448710.png)
  * ![image-20200404223457084](D:\OneDrive\Pictures\Typora\image-20200404223457084.png)
  * ![image-20200404223759901](D:\OneDrive\Pictures\Typora\image-20200404223759901.png)
  * ![image-20200404223805244](D:\OneDrive\Pictures\Typora\image-20200404223805244.png)
* Gate complexity
  * $O(\sqrt{N}\log{N})$ bound of the \# of gates used `<=` first construct the Grover diffusion gate
  * define $Z_0$:
    * ![image-20200404223930043](D:\OneDrive\Pictures\Typora\image-20200404223930043.png)
    * unitary matrix form: $Z_0 = 2|0^n\rangle \langle 0^n| - I$
    * ![image-20200404224106470](D:\OneDrive\Pictures\Typora\image-20200404224106470.png)
    * ![image-20200404224110643](D:\OneDrive\Pictures\Typora\image-20200404224110643.png)
    * ![image-20200404224614895](D:\OneDrive\Pictures\Typora\image-20200404224614895.png)
    * [homework1](https://www.cs.cmu.edu/~odonnell/quantum15/homework/homework1.pdf)
  * $D$ by $Z_0$ and $O(n) = O(\log N)$ $H$ gates
    * ![image-20200404224140917](D:\OneDrive\Pictures\Typora\image-20200404224140917.png)
    * ![image-20200404224157907](D:\OneDrive\Pictures\Typora\image-20200404224157907.png)
    * ![image-20200404224223125](D:\OneDrive\Pictures\Typora\image-20200404224223125.png)
  * proof
    * ![image-20200404224414548](D:\OneDrive\Pictures\Typora\image-20200404224414548.png)
    * ![image-20200404224511195](D:\OneDrive\Pictures\Typora\image-20200404224511195.png)
* ![image-20200404224933835](D:\OneDrive\Pictures\Typora\image-20200404224933835.png)
* ![image-20200410221831953](D:\OneDrive\Pictures\Typora\image-20200410221831953.png)
* ![image-20200410221847701](D:\OneDrive\Pictures\Typora\image-20200410221847701.png)
* ![image-20200410221902444](D:\OneDrive\Pictures\Typora\image-20200410221902444.png)
* ![image-20200410221915813](D:\OneDrive\Pictures\Typora\image-20200410221915813.png)
* ![image-20200410222013069](D:\OneDrive\Pictures\Typora\image-20200410222013069.png)
* ![image-20200410222142477](D:\OneDrive\Pictures\Typora\image-20200410222142477.png)
* ![image-20200410222159668](D:\OneDrive\Pictures\Typora\image-20200410222159668.png)
* ![image-20200410222206171](D:\OneDrive\Pictures\Typora\image-20200410222206171.png)
* ![image-20200410222234051](D:\OneDrive\Pictures\Typora\image-20200410222234051.png)
* ![image-20200410222241844](D:\OneDrive\Pictures\Typora\image-20200410222241844.png)
* 





## Quantum Query Complexity

* function `=>` black box gate `=>` oracle $O_f = |x\rangle \otimes |b\rangle \mapsto |x\rangle \otimes |b \oplus f(x)\rangle$
* $O_f^\pm = |x\rangle \mapsto (-1)^{f(x)}|x\rangle$
* ![image-20200408112809591](D:\OneDrive\Pictures\Typora\image-20200408112809591.png)
* [Grover search with multiple satisfying inputs](https://www.cs.cmu.edu/~odonnell/quantum15/homework/homework3.pdf)



### The Query Model

* query complexity: the number of queries it makes to $f$

* simple to analyze

* prove nontrivial lower bounds

* query complexity `===` time complexity

* known interesting quantum algorithms fit in the query paradigm

  * > Shor’s factorization algorithm is really a special use-case of a general period-finding query problem.



### Example Query Problems

* $N = 2^n$ to be the number of possible inputs to the function
* Hidden Shift Problem
  * ![image-20200408113522472](D:\OneDrive\Pictures\Typora\image-20200408113522472.png)
  * [[N: Simon's problem with two functions]]
  * classical: $O(N)$/naive,  $O(\sqrt{N})$/baby-step-gaint-step attack
    * ![image-20200408113929888](D:\OneDrive\Pictures\Typora\image-20200408113929888.png)
  * quantum: $O(\log N)$
    * ![image-20200408113951857](D:\OneDrive\Pictures\Typora\image-20200408113951857.png)
    * first-two-steps are common in quantum query algorithms
    * superposition + Fourier transform
    * period-finding qualities of the Fourier transform help extract hidden patterns in $f$
* Simon's Problem
  * ![image-20200408114053090](D:\OneDrive\Pictures\Typora\image-20200408114053090.png)
  * classical: $O(\sqrt{N})$
    * ![image-20200408114118604](D:\OneDrive\Pictures\Typora\image-20200408114118604.png)
  * quantum: $O(\sqrt{N})$
    * ![image-20200408114210105](D:\OneDrive\Pictures\Typora\image-20200408114210105.png)
* Baby-step Giant-step
  * ![image-20200408114330905](D:\OneDrive\Pictures\Typora\image-20200408114330905.png)
* Period Finding
  * ![image-20200408115112337](D:\OneDrive\Pictures\Typora\image-20200408115112337.png)
  * classical: $N^{1/4}$
  * quantum : $O(\log N)$
* Deutsch-Josza
  * ![image-20200408115150704](D:\OneDrive\Pictures\Typora\image-20200408115150704.png)
  * classical: $O(\log (1/\epsilon))$ random inspecting with error $\epsilon$, or $O(N / 2)$ bits
  * quantum: $O(1)$
  * ![image-20200408115307619](D:\OneDrive\Pictures\Typora\image-20200408115307619.png)
  * ![image-20200408115427264](D:\OneDrive\Pictures\Typora\image-20200408115427264.png)
  * ![image-20200408115515159](D:\OneDrive\Pictures\Typora\image-20200408115515159.png)
  * ![image-20200408115525505](D:\OneDrive\Pictures\Typora\image-20200408115525505.png)
  * [[N: use $O_f^\pm$ eliminates the $1$ ancilla bit]]
  * [[N: $O_f \otimes H^{\otimes (n + 1)} |0\rangle^{\otimes n}|1\rangle \equiv (O_f^\pm \otimes I) (|0\rangle ^{\otimes n} \otimes |-\rangle)$]]





## Boolean Fourier Analysis & Simon's Algorithm

* Fourier transform over $\mathbb{Z}^n_2$
  * basis transformation
  * make it easy to find certain patterns in the function
  * by $H^{\otimes n}$
  * $\{\delta_y(x)\}_{y \in \{0, 1\}^n}$ with property that
    * ![image-20200408130010486](D:\OneDrive\Pictures\Typora\image-20200408130010486.png)
    * a basis for any function $g(x): \{0, 1\}^n \mapsto \mathbb{C}$
      * ![image-20200408160710986](D:\OneDrive\Pictures\Typora\image-20200408160710986.png)
    * coefficients: expansion coefficients
    * standard representation
    * column vector with $2^n$ rows
      * ![image-20200408160907303](D:\OneDrive\Pictures\Typora\image-20200408160907303.png)
* Fourier/Parity basis
  * ![image-20200408161029623](D:\OneDrive\Pictures\Typora\image-20200408161029623.png)
  * Fourier characteristic
  * parity of bits
  * Fourier basis $\{\Chi_{\sigma}\}_{\sigma \in \mathbb{F}^n_2} = (-1)^{\sigma . X}$
  * ![image-20200408161216840](D:\OneDrive\Pictures\Typora\image-20200408161216840.png)
  * Properties
    * ![image-20200408161359278](D:\OneDrive\Pictures\Typora\image-20200408161359278.png)
    * ![image-20200408161429365](D:\OneDrive\Pictures\Typora\image-20200408161429365.png)
    * ![image-20200408161557592](D:\OneDrive\Pictures\Typora\image-20200408161557592.png)
  * Change of basis
    * ![image-20200408161624663](D:\OneDrive\Pictures\Typora\image-20200408161624663.png)
    * Examples
      * ![image-20200408163011426](D:\OneDrive\Pictures\Typora\image-20200408163011426.png)
  * Implementation with Hadamard
    * ![image-20200408163030654](D:\OneDrive\Pictures\Typora\image-20200408163030654.png)
    * ![image-20200408163407262](D:\OneDrive\Pictures\Typora\image-20200408163407262.png)
    * ![image-20200408163426814](D:\OneDrive\Pictures\Typora\image-20200408163426814.png)
* Use in Quantum Algorithms
  * Deutsch-Josza algorithm
    * ![image-20200408163508559](D:\OneDrive\Pictures\Typora\image-20200408163508559.png)
    * ![image-20200408163710593](D:\OneDrive\Pictures\Typora\image-20200408163710593.png)
      * $g(X) = (-1)^{f(x)}$, convert to Fourier basis
      * see Claim 2.5
    * ![image-20200408163840686](D:\OneDrive\Pictures\Typora\image-20200408163840686.png)
  * Grover's algorithm
    * Diffusion operator
      * ![image-20200408163932470](D:\OneDrive\Pictures\Typora\image-20200408163932470.png)
    * ![image-20200408164027935](D:\OneDrive\Pictures\Typora\image-20200408164027935.png)
    * $g(X) \mapsto g'(X)$: taking an input and going to the Fourier basis, then putting a − sign in front of all states that are not 0 and then returning from the Fourier basis
    * ![image-20200408164552289](D:\OneDrive\Pictures\Typora\image-20200408164552289.png)
      * $Z$ gate
    * ![image-20200408164605869](D:\OneDrive\Pictures\Typora\image-20200408164605869.png)
    * [[N: mean ($\mu$) $\to$ Fourier basis]]
  * Simon's Problem
    * Simon `=>` period finding algorithm `=>` Shor's factorization
    * ![image-20200408164727165](D:\OneDrive\Pictures\Typora\image-20200408164727165.png)
    * ![image-20200408164816996](D:\OneDrive\Pictures\Typora\image-20200408164816996.png)
    * ![image-20200408164845638](D:\OneDrive\Pictures\Typora\image-20200408164845638.png)
    * ![image-20200408165135446](D:\OneDrive\Pictures\Typora\image-20200408165135446.png)
      * $y = f(x)$, the first $n$ qubits collapse to $|\psi\rangle_y$
    * ![image-20200408165936705](D:\OneDrive\Pictures\Typora\image-20200408165936705.png)
    * Then we need $O(n) = n - 1$ linear independent $\gamma_i$ to recover $s$
      * ![image-20200408170903166](D:\OneDrive\Pictures\Typora\image-20200408170903166.png)
      * each linearly independent $\gamma_i$ cuts down the number of possibilities for $s$ by half, after $n-1$ equations and rule out $0$ (trivial, make $f$ 1-to-1, not 2-to-1)
      * subspace $s^{\bot} := \{\gamma \mid \gamma . s = 0\} \subseteq \mathbb{F}_n^2$
        * $n-1$ dimension
        * $2^{n-1}$ distinct vectors
      * ![image-20200408171118845](D:\OneDrive\Pictures\Typora\image-20200408171118845.png)
      * ![image-20200408171130831](D:\OneDrive\Pictures\Typora\image-20200408171130831.png)
    * [Simon's problem](https://zhuanlan.zhihu.com/p/84468177)
    * [[Q: do we need to measure the lower $m$($n$?) bits to make upper collapse?]]





## Quantum Fourier Transform over $Z_N$

* ![image-20200408174107302](D:\OneDrive\Pictures\Typora\image-20200408174107302.png)

* ![image-20200408174321558](D:\OneDrive\Pictures\Typora\image-20200408174321558.png)

* $\mathbb{Z}_2^n$

  * ![image-20200408174431813](D:\OneDrive\Pictures\Typora\image-20200408174431813.png)
  * ![image-20200408174440562](D:\OneDrive\Pictures\Typora\image-20200408174440562.png)
    * expectation basis
  * basis of parity functions $\{\Chi_\gamma\}_{\gamma \in \mathbb{Z}_2^n}, \Chi_\gamma(x) = (-1)^{\gamma \cdot x}$
    * ![image-20200408174656011](D:\OneDrive\Pictures\Typora\image-20200408174656011.png)
    * $\hat{g}(\gamma)$: coefficient of $\Chi_\gamma$ in the representation of $g$
    * ![image-20200408174731219](D:\OneDrive\Pictures\Typora\image-20200408174731219.png)
    * ![image-20200408174752691](D:\OneDrive\Pictures\Typora\image-20200408174752691.png)
      * [character](https://en.wikipedia.org/wiki/Character_group)
      * ![image-20200408174836022](D:\OneDrive\Pictures\Typora\image-20200408174836022.png)
    * ![image-20200408175036655](D:\OneDrive\Pictures\Typora\image-20200408175036655.png)
    * ![image-20200408175043830](D:\OneDrive\Pictures\Typora\image-20200408175043830.png)
  * ![image-20200408175418612](D:\OneDrive\Pictures\Typora\image-20200408175418612.png)
  * Quantum FFT: $H_N$ (n gates)
  * Classical FFT (Walsh-Hadamard): $O(N\log N)$

* $\mathbb{Z}_N$

  * $\mathbb{Z}_N$ has exactly $N$ characters $\chi_\gamma(x) = \omega^{\gamma \cdot x}$ ($\omega = e^{i \frac{2\pi}{N}}$)
    * $\chi(0) = 0$
    * $\chi(x)^N = 1$ ($N$-th root of unity)
    * $\chi(1) = \omega^\gamma$
    * $\chi_\gamma(x + y) = \chi_\gamma(x)\chi_\gamma(y)$
  * properties of $\{\chi_\gamma\}_{\gamma \in \mathbb{Z}_N}$
    * ![image-20200408180922879](D:\OneDrive\Pictures\Typora\image-20200408180922879.png)
  * ![image-20200408181005182](D:\OneDrive\Pictures\Typora\image-20200408181005182.png)
  * $g(x) = \sum_{\gamma \in \mathbb{Z}_N} \hat{g}(\gamma) |\chi_\gamma \rangle$
  * $\hat{g}(\gamma) = \langle \chi_\gamma \mid g \rangle = \mathbf{E}_{x \sim \{0, 1\}^n} [\chi_\gamma(x)^* g(x)]$
  * ![image-20200408181152750](D:\OneDrive\Pictures\Typora\image-20200408181152750.png)
  * ![image-20200408181220887](D:\OneDrive\Pictures\Typora\image-20200408181220887.png)
  * how to build efficient implementation of a circuit to compute the transform?

* Implementing the Fourier transform over $\mathbb{Z}_N$

  * > A life lesson to take away: if a unitary matrix has easy-to-write-down entries, it can probably be computed using poly(n) gates

  * Quantum Fourier transform over $\mathbb{Z}_N$ can be implemented with $O(n^2)$ 1- and 2-qubit gates

    * $C(n+1, 2)$ gates
    * correct on each classical input `=>` correct on all superpositions by linearity
    * ![image-20200408182326323](D:\OneDrive\Pictures\Typora\image-20200408182326323.png)
    * the output state are unentangled
      * ![image-20200408182422691](D:\OneDrive\Pictures\Typora\image-20200408182422691.png)
    * ![image-20200408183801212](D:\OneDrive\Pictures\Typora\image-20200408183801212.png)
      * $(\omega^{-8})^(2) = 1$, so only $x_0$ matters
    * ![image-20200408183909551](D:\OneDrive\Pictures\Typora\image-20200408183909551.png)
    * ![image-20200408183915972](D:\OneDrive\Pictures\Typora\image-20200408183915972.png)
    * ![image-20200408183923507](D:\OneDrive\Pictures\Typora\image-20200408183923507.png)

  * Phase shift gate

    * ![image-20200408183951747](D:\OneDrive\Pictures\Typora\image-20200408183951747.png)

  * ![image-20200408184035386](D:\OneDrive\Pictures\Typora\image-20200408184035386.png)

    * skip a few to allow a little error



## Simon's (Period Finding) Problem over $\mathbb{Z}_N$

* ![image-20200408185314741](D:\OneDrive\Pictures\Typora\image-20200408185314741.png)
* ![image-20200408185456347](D:\OneDrive\Pictures\Typora\image-20200408185456347.png)
* ![image-20200408204518277](D:\OneDrive\Pictures\Typora\image-20200408204518277.png)
* obtain a uniform random color from the measurement
  * ![image-20200408204630366](D:\OneDrive\Pictures\Typora\image-20200408204630366.png)
* observe color $c$ `=>` collapse
  * ![image-20200408205211297](D:\OneDrive\Pictures\Typora\image-20200408205211297.png)
* powerful trick: apply the Quantum Fourier Transform over $\mathbb{Z}_N$ & measure
  * ![image-20200408205717201](D:\OneDrive\Pictures\Typora\image-20200408205717201.png)
    * $G = \mathbb{Z}_2^n$: $H_N$
    * $G = \mathbb{Z}_N$: $\mathcal{F}_N$
  * ![image-20200408214820999](D:\OneDrive\Pictures\Typora\image-20200408214820999.png)
  * `=>` $\sum_{\gamma \in G} \hat{G}(\gamma)|\gamma\rangle$
    * spectral sampling
    * $\{\hat{g}(\gamma)\}_{\gamma \in G}$: Fourier spectrum of $g$
    * the reason (*almost*) how exponential speed-ups are obtained in quantum computing
  * ![image-20200408211345357](D:\OneDrive\Pictures\Typora\image-20200408211345357.png)
  * ![image-20200408211355463](D:\OneDrive\Pictures\Typora\image-20200408211355463.png)
  * $|\hat{g}(\gamma)|^2 = s \cdot |f_c(\gamma)|^2$
  * periodic spike function `=>` fourier transform `=>` period spike function
  * $|f_c(\gamma)|^2$ is independent of $c$
  * ![image-20200408215127418](D:\OneDrive\Pictures\Typora\image-20200408215127418.png)
    * ![image-20200408215149283](D:\OneDrive\Pictures\Typora\image-20200408215149283.png)
    * ![image-20200408215154650](D:\OneDrive\Pictures\Typora\image-20200408215154650.png)
  * ![image-20200408215224426](D:\OneDrive\Pictures\Typora\image-20200408215224426.png)
    * ![image-20200408215237315](D:\OneDrive\Pictures\Typora\image-20200408215237315.png)
  * find Fourier coefficient
  * ![image-20200408215353276](D:\OneDrive\Pictures\Typora\image-20200408215353276.png)
  * ![image-20200408215517643](D:\OneDrive\Pictures\Typora\image-20200408215517643.png)
    * same $\gamma \cdot s = 0$ linear independent sets (now modulo N)
  * ![image-20200408215655519](D:\OneDrive\Pictures\Typora\image-20200408215655519.png)
* classical computation
  * ![image-20200408220232573](D:\OneDrive\Pictures\Typora\image-20200408220232573.png)
  * ![image-20200408220242260](D:\OneDrive\Pictures\Typora\image-20200408220242260.png)
  * ![image-20200408220247523](D:\OneDrive\Pictures\Typora\image-20200408220247523.png)







## Shor's Algorithm

* Period Finding Algorithm steps
  * Preparing a superposition state (tensor with $|0^n\rangle$)
    * ![image-20200409001258859](D:\OneDrive\Pictures\Typora\image-20200409001258859.png)
  * Pass the state through an oracle for $f$ and obtain data
    * ![image-20200409001313574](D:\OneDrive\Pictures\Typora\image-20200409001313574.png)
  * Measure the qubits representing $|f(x)\rangle$ and obtain a random color $c$. Collapse the overall state to a superposition of states where $|x\rangle$ is in the preimage of $c$
    * ![image-20200409001403621](D:\OneDrive\Pictures\Typora\image-20200409001403621.png)
    * The coefficients can be taken as $f_c(x)\sqrt{s/N}$ where $f_c(x) = 1$ when $f(x) = c$
  * Apply QFT on this state to obtain a quantum state where the coefficients are $\hat{f}_c(\gamma)\sqrt{s/N}$ where $\gamma$ is a multiple of $\frac{N}{s}$
    * $\hat{f}_c(\gamma)$ has a period $\frac{N}{s}$ and $\gamma$ for which $\hat{f}_c(\gamma)$ is nonzero and a multiple of $\frac{N}{s}$
  * Measure $k$ gives us a random $\gamma$ in $c\frac{N}{s}$
  * Take a constant number of samples and take the GCD of all these samples. With high probability, we will get $\frac{N}{s}$ to retrieve $s$
* Algorithm complexity
  * ![image-20200409001743958](D:\OneDrive\Pictures\Typora\image-20200409001743958.png)
  * what's wrong with factoring?
* Shor's Algorithm
  * Factoring can reduce to ($\le$) order-finding
    * ![image-20200409001822281](D:\OneDrive\Pictures\Typora\image-20200409001822281.png)
    * classical reduction
    * finding $r^2 \equiv 1 \pmod M$ and $r \not \equiv \pm 1 \pmod M$ `=>` factoring $(r-1)(r+1)$
      * GCD $M$ and $r - 1$ to get non-trivial factor $c$
      * we can do $c$ and $M/c$ prime testing efficiently
    * ![image-20200409002907941](D:\OneDrive\Pictures\Typora\image-20200409002907941.png)
  * Ordering-finding $\approx$ Period-finding
  * Identifying simple fractions
* Order finding: $A^s \equiv 1 \pmod M$ where $s \mid \varphi(M)$
  * ![image-20200409002322605](D:\OneDrive\Pictures\Typora\image-20200409002322605.png)
* Quantum Algorithm for Order-Finding
  * $N = 2^{\text{poly}(n)} >> M$
  * $f(x) = A^x \pmod M, x \in {0, 1, \cdots, N - 1}$
    * almost $s$-periodic (whether $s |N$?)
  * ![image-20200409005800155](D:\OneDrive\Pictures\Typora\image-20200409005800155.png)
  * ![image-20200409005806347](D:\OneDrive\Pictures\Typora\image-20200409005806347.png)
  * ![image-20200409005814260](D:\OneDrive\Pictures\Typora\image-20200409005814260.png)
    * ![image-20200409005947539](D:\OneDrive\Pictures\Typora\image-20200409005947539.png)
  * ![image-20200409010006204](D:\OneDrive\Pictures\Typora\image-20200409010006204.png)
    * [[Q: actually inverse QFT? the omega power should be minus if using normal QFT]]
    * different from period-finding
    * ![image-20200409011027980](D:\OneDrive\Pictures\Typora\image-20200409011027980.png)
    * ![image-20200409011109020](D:\OneDrive\Pictures\Typora\image-20200409011109020.png)
  * ![image-20200409010011420](D:\OneDrive\Pictures\Typora\image-20200409010011420.png)
    * ![image-20200409010029468](D:\OneDrive\Pictures\Typora\image-20200409010029468.png)
    * `D`: divide number, the consistent states are $0, s, 2s, \cdots, Ds$
  * ![image-20200409010601677](D:\OneDrive\Pictures\Typora\image-20200409010601677.png)
  * Continued fractions: $N/\gamma \mapsto k/s$
    * ![image-20200409010624155](D:\OneDrive\Pictures\Typora\image-20200409010624155.png)
    * ![image-20200409011758983](D:\OneDrive\Pictures\Typora\image-20200409011758983.png)
    * ![image-20200409011815748](D:\OneDrive\Pictures\Typora\image-20200409011815748.png)
    * ![image-20200409011823980](D:\OneDrive\Pictures\Typora\image-20200409011823980.png)
* ![img](D:\OneDrive\Pictures\Typora\v2-131ff33eff2a39edfa4e56415f650ecb_b.jpg)
* ![img](D:\OneDrive\Pictures\Typora\v2-8dc63945c6c947ade0beb8889f96763b_b.jpg)
* ![img](D:\OneDrive\Pictures\Typora\v2-c802fa0942aaafb55722c49dd8ad3102_b.jpg)
* ![img](D:\OneDrive\Pictures\Typora\v2-e2627ad4622f9a486d9868b57a421229_b.jpg)
* ![image-20200409015610210](D:\OneDrive\Pictures\Typora\image-20200409015610210.png)
* ![image-20200409015845186](D:\OneDrive\Pictures\Typora\image-20200409015845186.png)
* ![image-20200409015855411](D:\OneDrive\Pictures\Typora\image-20200409015855411.png)
* ![image-20200409015905363](D:\OneDrive\Pictures\Typora\image-20200409015905363.png)
* ![image-20200409015934082](D:\OneDrive\Pictures\Typora\image-20200409015934082.png)
* ![image-20200409020008053](D:\OneDrive\Pictures\Typora\image-20200409020008053.png)



## Hidden Subgroup Problem

* ![image-20200409161913954](D:\OneDrive\Pictures\Typora\image-20200409161913954.png)
* left/right cosets
* ![image-20200409163043242](D:\OneDrive\Pictures\Typora\image-20200409163043242.png)
* Simon's problem `=>` Hidden subgroup problem
  * ![image-20200409163143368](D:\OneDrive\Pictures\Typora\image-20200409163143368.png)
  * ![image-20200409163149097](D:\OneDrive\Pictures\Typora\image-20200409163149097.png)
* **Hidden Subgroup Problem (HSP)**: 
  * ![image-20200409163243345](D:\OneDrive\Pictures\Typora\image-20200409163243345.png)
  * `H` can be exponentially large `=>` generating set for the subgroup of polynomial size as stated
* ![image-20200409163430010](D:\OneDrive\Pictures\Typora\image-20200409163430010.png)
  * ![image-20200409170248184](D:\OneDrive\Pictures\Typora\image-20200409170248184.png)
* ![image-20200409163642483](D:\OneDrive\Pictures\Typora\image-20200409163642483.png)
  * ![image-20200409171750776](D:\OneDrive\Pictures\Typora\image-20200409171750776.png)
* Abelian group `=>` `polylog(|G|)` number of gates & calls to `O_f`
* non-Abelian group `=>` `polylog(|G|)` number of calls to `O_f`, but may need EXP number of gates to run successfully
* **The Standard Model**
  * ![image-20200409164028595](D:\OneDrive\Pictures\Typora\image-20200409164028595.png)
  * ![image-20200409164843347](D:\OneDrive\Pictures\Typora\image-20200409164843347.png)
* **EHK Algorithm**
  * quantum query complexity of the Hidden Subgroup Problem: `Q = poly(n)` where $n = \lceil \log_2 |G| \rceil$ for associated group `G`
  * generating `Q` cosets states using above method
  * large & **entangled** unitary transformation ($O(\log |G|)$ number of gates) `U`
    * ![image-20200409172057255](D:\OneDrive\Pictures\Typora\image-20200409172057255.png)
    * Simon & Period Finding gate is not entangled
* **Graph Isomorphism by HSP**
  * ![image-20200409172152593](D:\OneDrive\Pictures\Typora\image-20200409172152593.png)
  * ![image-20200409172258078](D:\OneDrive\Pictures\Typora\image-20200409172258078.png)
  * ![image-20200409172424953](D:\OneDrive\Pictures\Typora\image-20200409172424953.png)
  * ![image-20200409172500766](D:\OneDrive\Pictures\Typora\image-20200409172500766.png)
  * ![image-20200409172524825](D:\OneDrive\Pictures\Typora\image-20200409172524825.png)
  * ![image-20200409172536576](D:\OneDrive\Pictures\Typora\image-20200409172536576.png)
  * ![image-20200409172543967](D:\OneDrive\Pictures\Typora\image-20200409172543967.png)
  * ![image-20200409173109960](D:\OneDrive\Pictures\Typora\image-20200409173109960.png)
    * examine if exchanging nodes happen





## Quantum Query Lower Bounds Using Polynomials

* Grover's search `=>` Circuit SAT in $O(\sqrt{2^n})$ time/gates
* Simon: exponential speedup
* Birthday attack
* Element distinctness (ED): if all $f(x)$ are distinct?
  * classical: sort & scan $O(N\log N)$
  * random: $\Theta(N)$
  * quantum: $\Theta(N^{2/3})$ queries (only polynomial speedup)
* ![image-20200409175856630](D:\OneDrive\Pictures\Typora\image-20200409175856630.png)
* Search `<=>` Decision
  * ![image-20200409180223254](D:\OneDrive\Pictures\Typora\image-20200409180223254.png)
* Randomize algorithm: output more than `2/3`
* Promise problem vs Total problem: an algorithm over some subclass of all functions
  * ![image-20200409180314350](D:\OneDrive\Pictures\Typora\image-20200409180314350.png)
* ![image-20200409180544342](D:\OneDrive\Pictures\Typora\image-20200409180544342.png)
  * ![image-20200409180551310](D:\OneDrive\Pictures\Typora\image-20200409180551310.png)
  * ![image-20200409180615550](D:\OneDrive\Pictures\Typora\image-20200409180615550.png)
* How to prove lower bounds
  * ![image-20200409180736286](D:\OneDrive\Pictures\Typora\image-20200409180736286.png)
  * ![image-20200409180757277](D:\OneDrive\Pictures\Typora\image-20200409180757277.png)
  * ![image-20200409180803782](D:\OneDrive\Pictures\Typora\image-20200409180803782.png)
  * ![image-20200409181022062](D:\OneDrive\Pictures\Typora\image-20200409181022062.png)
    * ![image-20200409181358374](D:\OneDrive\Pictures\Typora\image-20200409181358374.png)
    * ![image-20200409181406350](D:\OneDrive\Pictures\Typora\image-20200409181406350.png)
    * ![image-20200409181414405](D:\OneDrive\Pictures\Typora\image-20200409181414405.png)
    * ![image-20200409181422885](D:\OneDrive\Pictures\Typora\image-20200409181422885.png)
  * ![image-20200409181431869](D:\OneDrive\Pictures\Typora\image-20200409181431869.png)
  * ![image-20200409181439829](D:\OneDrive\Pictures\Typora\image-20200409181439829.png)
  * ![image-20200409181446214](D:\OneDrive\Pictures\Typora\image-20200409181446214.png)
* Example: Grover's Total search
  * ![image-20200409181512462](D:\OneDrive\Pictures\Typora\image-20200409181512462.png)
  * ![image-20200409181524663](D:\OneDrive\Pictures\Typora\image-20200409181524663.png)
  * ![image-20200409181531846](D:\OneDrive\Pictures\Typora\image-20200409181531846.png)
  * ![image-20200409181540789](D:\OneDrive\Pictures\Typora\image-20200409181540789.png)
  * ![image-20200409181555702](D:\OneDrive\Pictures\Typora\image-20200409181555702.png)
  * ![image-20200409181601791](D:\OneDrive\Pictures\Typora\image-20200409181601791.png)





## Lower Bounds for Element-Distinctness & Collision

* ![image-20200409182347941](D:\OneDrive\Pictures\Typora\image-20200409182347941.png)
* ED: total problem
  * ![image-20200409182300653](D:\OneDrive\Pictures\Typora\image-20200409182300653.png)
* Collision problem: promise problem (either 1-to-1 or `r`-to-1 strings)
  * ![image-20200409182334454](D:\OneDrive\Pictures\Typora\image-20200409182334454.png)
* ![image-20200409182746933](D:\OneDrive\Pictures\Typora\image-20200409182746933.png)
* ![image-20200409182957124](D:\OneDrive\Pictures\Typora\image-20200409182957124.png)
* Applications
  * ![image-20200409183049231](D:\OneDrive\Pictures\Typora\image-20200409183049231.png)
  * ![image-20200409183106039](D:\OneDrive\Pictures\Typora\image-20200409183106039.png)
  * ![image-20200409183254407](D:\OneDrive\Pictures\Typora\image-20200409183254407.png)
  * ![image-20200409183321797](D:\OneDrive\Pictures\Typora\image-20200409183321797.png)
  * ![image-20200409183328221](D:\OneDrive\Pictures\Typora\image-20200409183328221.png)
* Query complexity bounds
  * ![image-20200409183412581](D:\OneDrive\Pictures\Typora\image-20200409183412581.png)
  * ![image-20200409183444547](D:\OneDrive\Pictures\Typora\image-20200409183444547.png)
    * ![image-20200409183451348](D:\OneDrive\Pictures\Typora\image-20200409183451348.png)
    * ![image-20200409183456620](D:\OneDrive\Pictures\Typora\image-20200409183456620.png)
    * ![image-20200409183504790](D:\OneDrive\Pictures\Typora\image-20200409183504790.png)
    * ![image-20200409183657461](D:\OneDrive\Pictures\Typora\image-20200409183657461.png)
    * ![image-20200409183705277](D:\OneDrive\Pictures\Typora\image-20200409183705277.png)
    * ![image-20200409183710365](D:\OneDrive\Pictures\Typora\image-20200409183710365.png)
  * ![image-20200409183826631](D:\OneDrive\Pictures\Typora\image-20200409183826631.png)
    * ![image-20200409183728213](D:\OneDrive\Pictures\Typora\image-20200409183728213.png)
      * ![image-20200409183737430](D:\OneDrive\Pictures\Typora\image-20200409183737430.png)
      * ![image-20200409183742213](D:\OneDrive\Pictures\Typora\image-20200409183742213.png)
      * ![image-20200409183747948](D:\OneDrive\Pictures\Typora\image-20200409183747948.png)
      * ![image-20200409183755205](D:\OneDrive\Pictures\Typora\image-20200409183755205.png)
      * ![image-20200409183801165](D:\OneDrive\Pictures\Typora\image-20200409183801165.png)
      * ![image-20200409183809445](D:\OneDrive\Pictures\Typora\image-20200409183809445.png)
        * ![image-20200409183816149](D:\OneDrive\Pictures\Typora\image-20200409183816149.png)
    * ![image-20200409183843623](D:\OneDrive\Pictures\Typora\image-20200409183843623.png)
    * ![image-20200409183855200](D:\OneDrive\Pictures\Typora\image-20200409183855200.png)
    * ![image-20200409183901238](D:\OneDrive\Pictures\Typora\image-20200409183901238.png)
    * ![image-20200409183911245](D:\OneDrive\Pictures\Typora\image-20200409183911245.png)



## Lower Bounds using the Adversary Method

* ![image-20200409183942989](D:\OneDrive\Pictures\Typora\image-20200409183942989.png)
* [adversary method](https://www.cs.cmu.edu/~odonnell/quantum15/lecture13.pdf)
* [[T!]]



## Reichardt's Theorem



### Definition of Span Programs

* [[T!]]
* [definition](https://www.cs.cmu.edu/~odonnell/quantum15/lecture14.pdf)



### Evaluation of Span Programs

* [[T!]]
* [evaluation](https://www.cs.cmu.edu/~odonnell/quantum15/lecture15.pdf)











[[T: complete Quantum Information Theory part (Lec 16 - Lec 22)]]

[[T: complete Quantum Complexity part (Lec 23 - Lec 26)]]



