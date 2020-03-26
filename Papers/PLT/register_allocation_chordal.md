# Register Allocation via Coloring of Chordal Graphs  

**Fernando Magno Quintao Pereira, Jens Palsberg  **

---

[CMU 15-411 RegAlloc](https://www.cs.cmu.edu/~fp/courses/15411-f08/lectures/03-regalloc.pdf)





## Introduction

* optimally color a chordal graph in time linear in \# of edges.
* heuristics for spilling & coalescing
* better than iterated register coalescing with few registers
* register allocation
  * integer linear programming, worst EXPTIME (Appel & George)
  * polynomial-time heuristics (Briggs, Cooper & Torczon)
  * Iterated Register Coalescing alg. (George & Appel)
* ![image-20200129211642572](D:\OneDrive\Pictures\Typora\image-20200129211642572.png)
* observation: interference graph of real-life programs tend to be chordal graph
  * ![image-20200129212342697](D:\OneDrive\Pictures\Typora\image-20200129212342697.png)
  * the graph in Figure 2(c) is non-chordal because the cycle abcda is chordless
* Chordal graph: NP -> P, perfect
  * minimum coloring, 
  * maximum clique, 
  * maximum independent set 
  * minimum covering by cliques
  * optimal coloring
* 1-perfect graph: the chromatic number, that is, the minimum number of colors necessary to color the graph, equals the size of the largest clique
* perfect graph: 1-perfect + every induced subgraph is 1-perfect 
  * ![image-20200129215315123](D:\OneDrive\Pictures\Typora\image-20200129215315123.png)
* Brisk: strict SSA $\to$ prefect interference graphs
* Hack: strict SSA $\to$ chordal interference graphs
* strict: every path from the initial block until the use of a variable v passes through a definition of v.  
* phi-function: replaced by copying during SSA-elimination phase
* ![image-20200129213828821](D:\OneDrive\Pictures\Typora\image-20200129213828821.png)
* ![image-20200129214407845](D:\OneDrive\Pictures\Typora\image-20200129214407845.png)
* [[Q: why just not make b, c definition a block?]]



## Chordal Graphs

* $\Delta(G)$: maximum outdegree of any vertex in `G`
* $N(v)$: set of neighbors of `v`, adjacent
* clique: undirected graph $G = (V, E)$ which is a subgraph in which every 2 vertices are adjacent
* simplicial vertex: its neighborhood in `G` is a clique
* Simplicial Elimination Ordering of `G`: bijection $\sigma: V(G) \to \{1 \cdots, |V|\}$, such that every vertex $v_i$ is a simplicial vertex in the subgraph induced by $\{v_1, \cdots, v_i\}$
* ![image-20200129221737346](D:\OneDrive\Pictures\Typora\image-20200129221737346.png)
* Dirac: An undirected graph without self-loops is chordal if and only if it has a simplicial elimination ordering
*   ![image-20200129224237097](D:\OneDrive\Pictures\Typora\image-20200129224237097.png)
* ![image-20200129224246872](D:\OneDrive\Pictures\Typora\image-20200129224246872.png)
* ![image-20200129224252072](D:\OneDrive\Pictures\Typora\image-20200129224252072.png)



## Our Algorithm

* ![image-20200129224307800](D:\OneDrive\Pictures\Typora\image-20200129224307800.png)
* coloring, spilling, and coalescing, plus an optional phase called pre-spilling.  
* Coalescing must be the last stage in order to preserve the optimality of the coloring algorithm, because, after merging nodes, the resulting interference graph can be non-chordal  
* the MCS procedure to produce an ordering of the nodes, for use by the pre-spilling and coloring phases.
* ![image-20200129224441071](D:\OneDrive\Pictures\Typora\image-20200129224441071.png)
* ![image-20200129224900551](D:\OneDrive\Pictures\Typora\image-20200129224900551.png)
* ![image-20200129224920927](D:\OneDrive\Pictures\Typora\image-20200129224920927.png)
* ![image-20200129224932831](D:\OneDrive\Pictures\Typora\image-20200129224932831.png)
* ![image-20200129224942552](D:\OneDrive\Pictures\Typora\image-20200129224942552.png)
* ![image-20200129224952560](D:\OneDrive\Pictures\Typora\image-20200129224952560.png)
* ![image-20200129225000680](D:\OneDrive\Pictures\Typora\image-20200129225000680.png)
* ![image-20200129225006911](D:\OneDrive\Pictures\Typora\image-20200129225006911.png)
* ![image-20200129225011992](D:\OneDrive\Pictures\Typora\image-20200129225011992.png)
* ![image-20200129225044856](D:\OneDrive\Pictures\Typora\image-20200129225044856.png)
* ![image-20200129225051126](D:\OneDrive\Pictures\Typora\image-20200129225051126.png)
* ![image-20200129225056376](D:\OneDrive\Pictures\Typora\image-20200129225056376.png)
* ![image-20200129225104943](D:\OneDrive\Pictures\Typora\image-20200129225104943.png)
* ![image-20200129225114225](D:\OneDrive\Pictures\Typora\image-20200129225114225.png)
* ![image-20200129225126879](D:\OneDrive\Pictures\Typora\image-20200129225126879.png)
* ![image-20200129225131494](D:\OneDrive\Pictures\Typora\image-20200129225131494.png)



## Conclusion

* ![image-20200129225155655](D:\OneDrive\Pictures\Typora\image-20200129225155655.png)
* 













## Motivation

## Summary

## Strength

## Limitation & Solution



