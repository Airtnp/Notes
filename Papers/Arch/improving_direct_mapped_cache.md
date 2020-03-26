# Improving Direct-Mapped Cache Performance by the Addition of a Small Fully-Associative Cache and Prefetch Buffers  

**Norman P. Jouppi**

---



## Introduction

### Abstract

* Miss caching: small fully-associative cache between cache and refill path.
  * misses in the cache hit in the miss cache have only 1 cycle miss penalty
  * small miss cache of 2-5 entries are shown to be very effective in removing mapping conflicts misses in first-level direct-mapped caches
* Victim caching: improvement to miss caching, load small fully-associative cache with the victim of a miss and not the requested line
  * small victim caches of 1-5 entries are more effective at removing conflict misses than miss caching
* Stream buffers: prefetch cache lines starting at a cache miss address
  * data placed in the buffer, not in the cache
  * effective in removing capacity & compulsory cache misses, and I-cache conflict misses
  * more effective than prefetch techniques at using next slower level in the memory hierarchy when it is pipelined
  * multi-way stream buffers: useful for prefetching along multiple interwined data reference streams



### Intro

* cycle time decreases faster than main memory access time
* CPI also decreases
* $\to$ cache miss is expensive
* ![image-20200118171732385](D:\OneDrive\Pictures\Typora\image-20200118171732385.png)



## Baseline Design

* ![image-20200118171748190](D:\OneDrive\Pictures\Typora\image-20200118171748190.png)
* cycle time 3-8x longer than issue rate -> fast on-chip clock (superpipelineing)/issue many insts. (superscalar/VLIW)/higher speed tech. (GaAs vs. BiCMOS/FinFET)
* higher-speed tech. result in smaller on-chip caches (E.g. CMOS vs. GaAs/bipolar)
  * [[Q: why?]]
* First-level cache direct-mapped: fastest effective access time
* 1st miss is primary, 2nd level small amount due to large L2 cache
* ![image-20200118224636568](D:\OneDrive\Pictures\Typora\image-20200118224636568.png)



## Reducing Conflict Misses: Miss Caching & Victim Caching

* 3C miss
  * conflict: misses that would not occur if the cache was fully-associative and had LRU replacement 
    * direct-mapped will have more due to lack of associativity
      * 20-40% of all
  * compulsory: misses required in any cache organization because they are the first references to an instruction or piece of data  
  * capcacity: when the cache size is not sufficient to hold data between references
  * coherence: misses that occur as a result of invalidation to preserve multiprocessor cache consistency
* ![image-20200118230048590](D:\OneDrive\Pictures\Typora\image-20200118230048590.png)

### Miss Caching

* between L1 cache & access port to the L2 cache

  * ![image-20200118230359278](D:\OneDrive\Pictures\Typora\image-20200118230359278.png)

* small, fully-associative, 2-5 cache lines

* [[N: direct-mapped L1 + small fully-associative cache]]

* [[N: difference from victim cache: request miss line vs. poped line]]

* miss in both $\to$ load to both

* miss in L1 + found in MC? $\to$ L1 load on-chip from MC

* ![image-20200118231425996](D:\OneDrive\Pictures\Typora\image-20200118231425996.png)

* Many more data conflict misses are removed by the miss cache than instruction conflict misses  

  * >  Instruction conflicts tend to be widely spaced because the instructions within one procedure will not conflict with each other as long as the procedure size is less than the cache size, which is almost always the case. Instruction conflict misses are most likely when another procedure is called. The target procedure may map anywhere with respect to the calling procedure, possibly resulting in a large overlap  

  * > Data conflicts, on the other hand, can be quite closely spaced. Consider the case where two character strings are being compared. If the points of comparison of the two strings happen to  map to the same line, alternating references to different strings will always miss in the cache. In this case a miss cache of only two entries would remove all of the conflict misses  

* ![image-20200118232229668](D:\OneDrive\Pictures\Typora\image-20200118232229668.png)
* ![image-20200118232524242](D:\OneDrive\Pictures\Typora\image-20200118232524242.png)
* the higher the percentage of misses due to conflicts, the more effective the miss cache is at eliminating them  



### Victim Caching

* When a miss occurs, data is loaded into both the miss cache and the direct-mapped cache. In a sense, this duplication of data wastes storage space in the miss cache. The number of duplicate items in the miss cache can range from **one (in the case where all items in the miss cache map to the same line in the direct-mapped cache)** to **all of the entries (in the case where a series of misses occur which do not hit in the miss cache)**. 
* small, fully-associative cache, victim lines from directed-mapped cache
* ![image-20200118233106988](D:\OneDrive\Pictures\Typora\image-20200118233106988.png)
* no data line appears in both
* swap on L1 miss + VC hit
* benefit (w.r.t. miss caching) depends on the amount of duplicate in the miss cache
* ![image-20200118234429874](D:\OneDrive\Pictures\Typora\image-20200118234429874.png)
* ![image-20200118234451186](D:\OneDrive\Pictures\Typora\image-20200118234451186.png)
* ![image-20200118234504331](D:\OneDrive\Pictures\Typora\image-20200118234504331.png)

### Effect of Direct-Mapped Cache Size on Victim Cache Performance

* ![image-20200118234747827](D:\OneDrive\Pictures\Typora\image-20200118234747827.png)
* direct-mapped cache $\uparrow$ 
  * victime cache $\downarrow$
  * percentage eof conflict misses $\downarrow$ 
    * percentage of these misses removed by the victim cache decreases



### Effect of Line Size on Victim Cache Performance

* ![image-20200118235218129](D:\OneDrive\Pictures\Typora\image-20200118235218129.png)
* ![image-20200118235243561](D:\OneDrive\Pictures\Typora\image-20200118235243561.png)



### Victim Caches & Second-Level Caches

* Can VC serve as L2 cache?
* VC violates inclusion properties...
* L1 VC can also reduce L2 conflict misses
* L2 + VC?



### Miss Caches, Victim Caches & Error Correction

* MC yields enhancement & fault tolerance
  * If parity is kept on all instruction and data cache bytes, and the data cache is write-though, then cache parity errors can be handled as misses
  * If the refill path bypasses the cache, then this scheme can also allow chips with hard errors to be used
  * Thus, as long as the number of defects was small enough to be handled by the miss cache, chips with hard defects could be used in production systems  
* VC is not useful for correction of misses due to parity errors
  * victim corrupted by the parity error and not worth saving
* VC is helpful for error-correction with change
  * When a cache miss is caused by a parity error, the victim cache is loaded with the incoming (miss) data  and not the victim
  * Thus it acts like a victim cache for normal misses and a miss cache for parity misses  



## Reducing Capacity & Compulsory Misses

* prefetching / longer cache line size (can't be arbitrarily long)



### Reducing Capacity & Compulsory Misses with Long Lines

* ![image-20200119134200106](D:\OneDrive\Pictures\Typora\image-20200119134200106.png)
* ![image-20200119134353670](D:\OneDrive\Pictures\Typora\image-20200119134353670.png)
* D-cache perf. peaks at a modest line size, decreases for further increase in line size
  * differences in spatial locality between instruction & data references
* ![image-20200119144730473](D:\OneDrive\Pictures\Typora\image-20200119144730473.png)
* ![image-20200119144830402](D:\OneDrive\Pictures\Typora\image-20200119144830402.png)
* MC allows taking better advantage of longer cache line sizes
* ![image-20200119144945937](D:\OneDrive\Pictures\Typora\image-20200119144945937.png)
* ![image-20200119144950232](D:\OneDrive\Pictures\Typora\image-20200119144950232.png)



### Reducing Capacity & Complusory Misses with Prefetch Techniques

* Prefetch on miss: always next line
  * cut number of misses for a purely sequential reference stream in half
* Tagged prefetch
  * each block has a tag bit assiciated with it
  * prefetched? tag bit = 0
  * used? tag bit = 1
  * 0 -> 1 transition: successor block is prefetched
  * reduce \# of misses in a purely sequential reference stream too zero, if fetching is fast enough
    * impossible since large latency
* ![image-20200119181616051](D:\OneDrive\Pictures\Typora\image-20200119181616051.png)



### Stream Buffers

* prefetch before a tag transition taking place
* ![image-20200119182654338](D:\OneDrive\Pictures\Typora\image-20200119182654338.png)
* ![image-20200119182724649](D:\OneDrive\Pictures\Typora\image-20200119182724649.png)
* ![image-20200119182754258](D:\OneDrive\Pictures\Typora\image-20200119182754258.png)
* ![image-20200119183630666](D:\OneDrive\Pictures\Typora\image-20200119183630666.png)
* ![image-20200119195618333](D:\OneDrive\Pictures\Typora\image-20200119195618333.png)
* ![image-20200119195623477](D:\OneDrive\Pictures\Typora\image-20200119195623477.png)



### Multi-Way Stream Buffers

* interleaved streams of data from different sources  
* four stream buffers in parallel
* When a miss occurs in the data cache that does not hit in any stream buffer, the stream buffer hit least recently is cleared (i.e., LRU replacement) and it is started fetching at the miss address  
* ![image-20200119201939659](D:\OneDrive\Pictures\Typora\image-20200119201939659.png)
* ![image-20200119201951076](D:\OneDrive\Pictures\Typora\image-20200119201951076.png)



### Quasi-Sequential Stream Buffers

* previous: 1 addr comparator for the stream buffer
  * even if the requested line in stream buffer, not in the first location, then miss & flush
  * place comparator at each location in the stream buffer
    * good for quasi-sequential reference pattern
* ![image-20200119210503439](D:\OneDrive\Pictures\Typora\image-20200119210503439.png)
* good for 4-entry one, bad for multi-way since lots of comparators..



### Stream Buffer Performance vs. Cache Size

* ![image-20200119210848311](D:\OneDrive\Pictures\Typora\image-20200119210848311.png)
* The instruction stream buffers have remarkably constant performance over a wide range of cache sizes. The data stream buffer performance generally improves as the cache size increases  



### Stream Buffer Performance vs. Line Size

* ![image-20200119212804758](D:\OneDrive\Pictures\Typora\image-20200119212804758.png)

### Comparsion to Classical Prefetch Performance

* ![image-20200119215503707](D:\OneDrive\Pictures\Typora\image-20200119215503707.png)
* ![image-20200119215534294](D:\OneDrive\Pictures\Typora\image-20200119215534294.png)



### Combining Long Lines & Stream Buffers

* ![image-20200119235149086](D:\OneDrive\Pictures\Typora\image-20200119235149086.png)
* ![image-20200119235154964](D:\OneDrive\Pictures\Typora\image-20200119235154964.png)
* ![image-20200120000143659](D:\OneDrive\Pictures\Typora\image-20200120000143659.png)



## Conclusion

* > Small miss caches (e.g., 2 to 5 entries) have been shown to be effective in reducing data cache conflict misses for direct-mapped caches in range of 1K to 8K bytes. They effectively remove tight conflicts where misses alternate between several addresses that map to the same line in the cache. Miss caches are increasingly beneficial as line sizes increase and the percentage of conflict misses increases. In general it appears that as the percentage of conflict misses increases, the percent of these misses removable by a miss cache also increases, resulting in an even steeper slope for the performance improvement possible by using miss caches.
  >
  > Victim caches are an improvement to miss caching that saves the victim of the cache miss instead of the target in a small associative cache. Victim caches are even more effective at removing conflict misses than miss caches.
  >
  > Stream buffers prefetch cache lines after a missed cache line. They store the line until it is requested by a cache miss (if ever) to avoid unnecessary pollution of the cache. They are particularly useful at reducing the number of capacity and compulsory misses. They can take full advantage of the memory bandwidth available in pipelined memory systems for sequential references, unlike previously discussed prefetch techniques such as tagged prefetch or prefetch on miss. Stream buffers can also tolerate longer memory system latencies since they prefetch data much in advance of other prefetch techniques (even prefetch always). Stream buffers can also compensate for instruction conflict misses, since these tend to be relatively sequential in nature as well.
  >
  > Multi-way stream buffers are a set of stream buffers that can prefetch down several streams concurrently. In this study the starting prefetch address is replaced over all stream buffers in LRU order. Multi-way stream buffers are useful for data references that contain interleaved accesses to several different large data structures, such as in array operations. However, since the prefetching is of sequential lines, only unit stride or near unit stride (2 or 3) access patterns benefit.  

* > The performance improvements due to victim caches and due to stream buffers are relatively orthogonal for data references. Victim caches work well where references alternate between two locations that map to the same line in the cache. They do not prefetch data but only do a better job of keeping data fetched available for use. Stream buffers, however, achieve performance improvements by prefetching data. They do not remove conflict misses unless the conflicts are widely spaced in time, and the cache miss reference stream consists of many sequential accesses. These are precisely the conflict misses not handled well by a victim cache due to its relatively small capacity. Over the set of six benchmarks, on average only 2.5% of 4KB direct-mapped data cache misses that hit in a four-entry victim cache also hit in a four-way stream buffer for ccom, met, yacc, grr, and liver. In contrast, linpack, due to its sequential data access patterns, has 50% of the hits in the victim cache also hit in a four-way stream buffer. However only 4% of linpack’s cache misses hit in the victim cache (it benefits least from victim caching among the six benchmarks), so this is still not a significant amount of overlap between stream buffers and victim caching.  

* ![image-20200120000732916](D:\OneDrive\Pictures\Typora\image-20200120000732916.png)
* ![image-20200120003159730](D:\OneDrive\Pictures\Typora\image-20200120003159730.png)
* ![image-20200120003204884](D:\OneDrive\Pictures\Typora\image-20200120003204884.png)
* ![image-20200120003213473](D:\OneDrive\Pictures\Typora\image-20200120003213473.png)
* 







* CS251A requirements
  * a short paragraph summarizing the problem and goal/contributions of paper
  * a short paragraph summarizing the paper’s methods and results
  * a short paragraph giving your opinion of what is good and bad about the paper.

##  Summary

- Since in the paper's decade, the cycle time had been decreasing much faster than main memory access time and average CPI also decreased, which made cache miss at a high cost. To reduce the cache misses and mitigate the miss costs, this paper investigated two main techniques (miss cache/victim cache and stream buffer/longer cache line) for reducing conflict misses and compulsory/capacity misses respectively on direct-mapped L1 caches.

## Methods & Results

- To reduce conflict misses, the author proposed two methods: miss cache and victim cache. Miss cache is an on-chip, small (2-5 entries), fully-associative cache. If both L1 cache and miss cache misses, they both load data from the next level cache. If only L1 cache misses, it will try to fetch data from the on-chip miss cache. The cache lines are duplicated in both L1 cache and miss cache, which is a waste of space. Therefore, the author proposed victim caching, which only contains the thrown cache lines from L1 cache and swaps back on L1 cache miss and victim cache found. Miss cache can serve as a parity checking component allowing hard errors and victim cache can be used for error correction with some modifications. As for capacity and compulsory misses, apart from having longer cache lines, this paper presents a technique called stream buffer (either 1-way or multi-way). Stream buffer will prefetch elements in stride immediately when a miss happens. Also, if the accesses are quasi-sequential (like A, A + 2, ...), a quasi-sequential stream buffer is able to handle this situation by placing comparators at each location in the stream buffer. The author simulated the techniques on a traditional design with six test programs. For each technique, the author carefully considered different variations of the designs (I/D-cache, number of entries, different kinds of misses, cache line sizes, ways of buffers) and interactions between other system parameters (L1 cache size, L2 cache size). The result shows that miss caches and victim caches are increasingly beneficial as line sizes increase and the percentage of conflict misses increases. Also, (multi-way) stream buffers are useful for sequential and interleaved data references and fully take advantage of memory bandwidth.

## Personal Opinions

- For me, it's a very solid paper (46 pages!). The authors very carefully considered most of the possible combinations of parameters and provided extremely convincing proofs on performance improvements and suggestions on parameter selections. I believe victim caching and stream buffers are widely applied in modern pipelines (e.g., AMD L3 victim cache). One further improvement can be done is evaluating these techniques in a wider space: with L2, L3 cache aside, or serving as L2/L3 cache alone; with non-LRU replacement policy; considering non-sequential prefetching (like correlation-based, or even ML?); and considering the cost in hardware (area, power).

