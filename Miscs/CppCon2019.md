# CppCon 2019 

(with some Meeting C++ 2019)



## Miscs

* renaming concepts from Pascal/CamelCase  to snake_case

* strict weak ordering
  * ![1569516299569](D:\OneDrive\Pictures\Typora\1569516299569.png)
  * transitivity of incomparability
  
* `string_view` is borrow-type
  * lack ownership
  * short-lived
  
* `span<T>`: mutable `array_view`
  * should span be regular? => SemiRegular
  * deep or shallow `operator==` ? => removed completely
  * const / mutability ?
  * bad, mixture of `&[T]` & `&mut [T]`
  
* Clang lifetime profile
  * `-Wlifetime`
  * `-Wdangling-gsl`
  
* `mdspan`: A Non-Owning Multidimensional Array Reference

* `mdarray`: An Owning Multidimensional Array Analog of mdspan

* SYCL Integer sum reduction

  * ![image-20191128180806671](D:\OneDrive\Pictures\Typora\image-20191128180806671.png)

  * ![image-20191128180829700](D:\OneDrive\Pictures\Typora\image-20191128180829700.png)

  * ![image-20191128180836163](D:\OneDrive\Pictures\Typora\image-20191128180836163.png)

  * ```c++
    // sequential
    int sum = 0;
    for ( int i = 0; i < M; i++ )
    	sum += input[i];
    // reduction over global memory
    cgh.parallel_for<class reduce>(
        numOfItems,[=](id<1> wiID) {
    	atomic_fetch_add(accessorC[0], accessorA[wiID]);
    });
    // hierarchical reduction using local memory
    cgh.parallel_for<class reduce>(
    	nd_range<1>(numOfItems, range<1>(WGS)),
    	[=](nd_item<1> item) {
    	size_t gid = item.get_global_linear_id();
    	ushort lid = item.get_local_linear_id();
    	if (lid == 0) { // for the first work-item
    		sum[0].store(0);
    	}
    	item.barrier(access::fence_space::local_space);
    	atomic_fetch_add(sum[0], accessorA[gid]);
    	item.barrier(access::fence_space::local_space);
    	if (lid == WGS-1) {
    		int partial_sum = atomic_load(sum[0]);
    		atomic_fetch_add(accessorC[0], partial_sum);
    	}
    });
    // hierarchical reduction with vectorized memory accesses
    cgh.parallel_for<class reduce>(
    	nd_range<1>(numOfWorkItems, range<1>(WGS)),
    	[=](cl::sycl::nd_item<1> item) {
    	vec<int,n> vi;
    	size_t gid = item.get_global_linear_id();
    	ushort lid = item.get_local_linear_id();
    	vi.load(gid, accessorA.get_pointer());
    	int r = vi.s0() + vi.s1() + … + vi.sn-1;
    	if (lid == 0) sum[0].store(0);
    	item.barrier(access::fence_space::local_space);
    	atomic_fetch_add(sum[0], r);
    	…
    });
    ```

  * [[R: reduction.pdf in CUDA]]

* Fixed precision adders

  * `IIII.FFFFF`

  * ![image-20191128230251735](D:\OneDrive\Pictures\Typora\image-20191128230251735.png)

  * trade precision for reproducility

  * ```c++
    // Range is the range of numbers to be processed,
    // Tout is the type presented to the adder-agnostic world,
    // Tsum is the internal adder type
    // Exceeding the range is undefined behavior
    template< size_t Range,
    		typename Tout=double,
    		typename Tsum=
                typename	std::conditional<(sizeof(Tout)>4),int64_t,int32_t>::type>
    class fixed_precision_adder {
        // Sanity checks
        static_assert(Range>0,"Adder range can't be zero!");
        static_assert(std::is_integral<Tsum>::value,"Internal adder type must be integral!");
        static_assert(std::is_signed<Tsum>::value,"Internal adder type must be signed!");
        // The size of our internal type minus the signbit
        static constexpr int available_bits() { return 8*sizeof(Tsum)-1; }
        // The number of bits we need for the integral part of our sum
        static constexpr int bits_for_range() { return log2constexpr(Range)+1; }
        // Another important sanity check
        static_assert(bits_for_range()<=available_bits(),"Range too big for internal adder type!");
        // All input types except float are cast up to double to avoid loss of precision
        template<typename T>
        using Tbias=typename std::conditional<std::is_same<T,float>::value,float,double>::type;
        // The factor we need to multiply our input with to properly fill our internal sum
        template<typename T, typename Tret=Tbias<T>>
        static constexpr Tret bias() { return Tret(Tsum(1)<<(available_bits()-bits_for_range())); }
        // The opposite of bias()
        template<typename T, typename Tret=Tbias<T>>
        static constexpr Tret unbias() { return Tret(1)/bias<Tret>(); }
        // Apply bias and round/convert to integer of matching size
        // Order of multiplication and conversion is important
        template<typename Tval>
        Tsum convert(const Tval& val) {
            if (sizeof(Tsum)<=4)
    	        return Tsum(llrint(val*bias<Tval>()));
            else
         	   return Tsum(lrint(val*bias<Tval>()));
        }
        // The one and only piece of runtime data
        Tsum sum;
    public:
        // Constructors. Empty default constructors gives wrong results in OpenMP
        fixed_precision_adder() : sum(0) {}
        template<typename T>
        fixed_precision_adder(const T& val) : sum(convert(val)) {}
        // The actual work, add the biased integral value to the sum
        template<typename Tval>
        fixed_precision_adder& operator+=(const Tval& val) {
            sum+=convert(val);
            return *this;
        }
        // If the other one is a fixed precision adder of the same flavor, just add the sums directly
        // Could be extended for different fixed precision adders
        fixed_precision_adder& operator+=(const fixed_precision_adder& other) {
            sum+=other.sum;
            return *this;
        }
        // std::accumulate needs operator+
        template<typename Trhs>
        fixed_precision_adder operator+(const Trhs& rhs) {
    	    return fixed_precision_adder(*this)+=rhs;
        }
        // If necessary, disguise as Tout (usually float or double)
        operator Tout() const { return float(sum)*unbias<double>(); }
        // Don't disguise as anything else, unless someone asks
        template<typename T>
        explicit operator T() const { return T(sum)*unbias<T>(); }
    };
    ```

* SLX FPGA HLS Synthesizer

  * ![image-20191128231000013](D:\OneDrive\Pictures\Typora\image-20191128231000013.png)
  * ![image-20191128231007318](D:\OneDrive\Pictures\Typora\image-20191128231007318.png)
  * ![image-20191128231019477](D:\OneDrive\Pictures\Typora\image-20191128231019477.png)
  * ![image-20191128231031180](D:\OneDrive\Pictures\Typora\image-20191128231031180.png)

* Beetroot: CMake embedded language

  * ![image-20191128231343533](D:\OneDrive\Pictures\Typora\image-20191128231343533.png)
  * ![image-20191128231406295](D:\OneDrive\Pictures\Typora\image-20191128231406295.png)

* Clang based refactoring

  * clang-tidy as code refractor & parser & AST matcher
  * `MatchFinder`/`MatchResult`
  * ![image-20191130220104545](D:\OneDrive\Pictures\Typora\image-20191130220104545.png)
  * ![image-20191130220113658](D:\OneDrive\Pictures\Typora\image-20191130220113658.png)

* Everyday efficiency inplace construction

  * `std::piecewise_construct`
  * RVO/NRVO: prvalue + name of stack variable
  * `std::initializer_list`
  * ![image-20191201115107887](D:\OneDrive\Pictures\Typora\image-20191201115107887.png)
  * ![image-20191201115218062](D:\OneDrive\Pictures\Typora\image-20191201115218062.png)
  * ![image-20191201115238411](D:\OneDrive\Pictures\Typora\image-20191201115238411.png)
  * ![image-20191201115253375](D:\OneDrive\Pictures\Typora\image-20191201115253375.png)





## A Unifying Abstraction for Async in Cpp

* why `future<T>` slow?

  * ```c++
    future<int> async_algo() {
        promise<int> p;
        auto f = p.get_future();
        thread t { [p = move(p)]() mutable {
        	int answer = // compute!
    	    p.set_value(answer);
        }};
        t.detach();
        return f;
    }
    
    int main() {
        auto f = async_algo();
        auto f2 = f.then([](int i) {
        	return i + rand();
        });
        printf("%d\n", f2.get());
    }
    ```

  * overhead of value, continuation, mutex, cond var, ref count (share between `future<T>` & `promise<T>`)

  * passing in a continuation avoids some synchronization overhead (no race)

  * start async work suspended and letting the caller add the continuation before launching

* lazy future

  * composed without allocation
  * composed without synchronization
  * composed without type-erasure




## Abseil's Open Source Hashtable

* ![image-20191129192802886](D:\OneDrive\Pictures\Typora\image-20191129192802886.png)

* ![image-20191129192808455](D:\OneDrive\Pictures\Typora\image-20191129192808455.png)

* ```c++
  BitMask<uint32_t> Match(h2_t hash) const {
      auto match = _mm_set1_epi8(hash); // set to all
      return BitMask<uint32_t>(
  	    _mm_movemask_epi8(_mm_cmpeq_epi8(match, ctrl))); // compare & convert to mask
  }
  
  iterator find(const K& key, size_t hash) const {
      size_t group = H1(hash) % num_groups_;
      while (true) {
          Group g{ctrl_ + group * 16};
          for (int i : g.Match(H2(hash))) {
              if (key == slots_[group * 16 + i])
                  return iterator_at(group * 16 + i);
          }
          if (g.MatchEmpty()) return end();
          group = (group + 1) % num_groups_;
      }
  }
  
  size_t H1(size_t hash, const ctrl_t* ctrl) {
      return (hash >> 7) ^
  	    (reinterpret_cast<uintptr_t>(ctrl) >> 12);
  }
  
  size_t find_first_non_full(size_t hash) {
      while (true) {
          size_t group = hash & num_groups_;
          if (MatchEmptyOrDeleted(group)) {
  #if !defined(NDEBUG)
              if (ShouldInsertBackwards(hash, ctrl_)) {
              	return group + mask.HighestBitSet();
              }
  #endif
  	        	return group + mask.LowestBitSet();
          	}
          	++group;
          }
      }
  }
  
  void set_ctrl(size_t i, ctrl_t h) {
      assert(i < capacity_);
      ctrl_[i] = h;
      if (i < 16) ctrl_[i + 1 + capacity_] = h;
  }
  
  // [[TODO: watch the video to figure out what happens?]]
  // +10% find, -15% insert
  iterator find(const K& key, size_t hash) const {
      size_t pos = H1(hash) % capacity_;
      while (true) {
          Group g{ctrl_ + pos};
          for (int i : g.Match(H2(hash))) {
          if (key == slots_[pos + i])
  	        return iterator_at(pos + i);
          }
          if (g.MatchEmpty()) return end();
          group = (pos + 16) % capacity_;
      }
  }
  
  struct ShardedTable {
      absl::flat_hash_map<uint64, V, Identity> table;
      absl::Mutex mu;
  };
  
  // ~43K elements per shard
  // ceil(log2(43k) + 7) == 23
  std::array<ShardedTable, 32> tables;
  
  uint64 TableOffset(uint64 fprint) { return (fprint >> 20) & 31; }
  
  T Find(uint64 fprint) {
      ShardedTable& t = tables[TableOffset(fprint)];
      absl::ReaderMutexLock l(&t.mu);
      return t.table.at(fprint);
  }
  
  ```

* [[TODO: very technical content, should watch video]]

* ![image-20191203013456972](D:\OneDrive\Pictures\Typora\image-20191203013456972.png)

* ![image-20191203013509760](D:\OneDrive\Pictures\Typora\image-20191203013509760.png)

* ![image-20191203013522844](D:\OneDrive\Pictures\Typora\image-20191203013522844.png)

* ![image-20191203013630466](D:\OneDrive\Pictures\Typora\image-20191203013630466.png)

* ![image-20191203013721006](D:\OneDrive\Pictures\Typora\image-20191203013721006.png)

  



## Abusing compiler tools

* [CGO'19 paper](https://arxiv.org/abs/1807.06735)
* ![image-20191129200038767](D:\OneDrive\Pictures\Typora\image-20191129200038767.png)
* ![image-20191129200049704](D:\OneDrive\Pictures\Typora\image-20191129200049704.png)
* ![image-20191129200057336](D:\OneDrive\Pictures\Typora\image-20191129200057336.png)
* ![image-20191129200104624](D:\OneDrive\Pictures\Typora\image-20191129200104624.png)
* `-ffunction-sections`
* call frequency
* reduce # of taken branches by making hottest successors likely a fall-though
* weighted call graph
* ![image-20191129201209968](D:\OneDrive\Pictures\Typora\image-20191129201209968.png)



## Are we macro-free yet?

* ![image-20191129222557017](D:\OneDrive\Pictures\Typora\image-20191129222557017.png)

* Fighting macro

  * ![image-20191129222626176](D:\OneDrive\Pictures\Typora\image-20191129222626176.png)

* conditional compilation

  * `#if`: no guarantee that building all combinations of configurations can reveal a logic error in the conditions

    * obscure data structure
    * testing conditions without semantics

  * `constexpr if`

    * discarded statement

      * Every program shall contain exactly one definition of every non-inline function or variable that is odr-used in that program outside of a discarded statement; no diagnostic required. ([basic.def.odr]/10)
        * may have 0 definition for function/variable odr-used in discarded statements
      * If the declared return type of the function contains a placeholder type, the return type of the function is deduced from non-discarded return statements, if any, in the body of the function. ([dcl.spec.auto]/3) 
        * discarded statements do not controbute to return type deduction

    * introduce variables without macros: `config.h.in`: `constexpr bool v = @V@` (ask build systems)

    * complete type required but conditionally available

      * separate files `src/win32.cc`/`src/posix.cc`

      * build system targets

      * dependency inversion: use pimpl + type erasure

        * ```c++
          class DirStream {
          public:
              bool open(const std::string& path) { return this_->open(path); }
              bool close() { return this_->close(); }
              bool read(std::string* path) { return this_->read(path); }
          private:
              struct DirStreamInterface {…};
              template<class T>
              struct DirStreamCore final : DirStreamInterface {…};
              std::unique_ptr<DirStreamInterface> this_;
          };
          ```

        * [[Q: performance issues? virtual calling, allocation]]

* more macros to kill

  * include guard: harmless, use Modules
  * logging: `std::source_location`, `std::format`
  * metadata macros: static reflection, metaclasses (generative programming)
  * unit test frameworks

* eliminate macros which

  * interleave the program logic in any form
    * conditional code blocks, token soup
    * function-like/object-like macros substitute into expressions
  * hijack interface with implementation details
    * build system jobs
    * better design
  * 

* [[N: looks we just write build system macros instead of C++ ones...]]



## Asynchronous Programming in Modern C++

* ![image-20191129225438719](D:\OneDrive\Pictures\Typora\image-20191129225438719.png)

* HPX: The C++ Standards Library for Concurrency & Parallelism

  * ![image-20191129225510378](D:\OneDrive\Pictures\Typora\image-20191129225510378.png)

* ![image-20191129225821348](D:\OneDrive\Pictures\Typora\image-20191129225821348.png)

* ![image-20191129225829532](D:\OneDrive\Pictures\Typora\image-20191129225829532.png)

* ![image-20191129225844332](D:\OneDrive\Pictures\Typora\image-20191129225844332.png)

* Future / Recursive Parallelism

  * ```c++
    // quick sort
    template <typename RandomIter>
    void quick_sort(RandomIter first, RandomIter last)
    {
        ptrdiff_t size = last - first;
        if (size > 1) {
            RandomIter pivot = partition(first, last,
    	        [p = first[size / 2]](auto v) { return v < p; });
            quick_sort(first, pivot);
            quick_sort(pivot, last);
        }
    }
    // parallel
    template <typename RandomIter>
    void quick_sort(RandomIter first, RandomIter last)
    {
        ptrdiff_t size = last - first;
        if (size > threshold) {
            RandomIter pivot = partition(par, first, last,
            	[p = first[size / 2]](auto v) { return v < p; });
            quick_sort(first, pivot);
            quick_sort(pivot, last);
        }
        else if (size > 1) {
    	    sort(seq, first, last);
        }
    }
    // futurized
    template <typename RandomIter>
    future<void> quick_sort(RandomIter first, RandomIter last)
    {
        ptrdiff_t size = last - first;
        if (size > threshold) {
            future<RandomIter> pivot = partition(par(task), first, last,
            	[p = first[size / 2]](auto v) { return v < p; });
            return pivot.then([=](auto pf) {
                auto pivot = pf.get();
                return when_all(quick_sort(first, pivot), quick_sort(pivot, last));
            });
        }
        else if (size > 1) {
    	    sort(seq, first, last);
        }
        return make_ready_future();
    }
    // co_await
    template <typename RandomIter>
    future<void> quick_sort(RandomIter first, RandomIter last)
    {
        ptrdiff_t size = last - first;
        if (size > threshold) {
            RandomIter pivot = co_await partition(par(task), first, last,
            	[p = first[size / 2]](auto v) { return v < p; });
            co_await when_all(
            	quick_sort(first, pivot), quick_sort(pivot, last));
        }
        else if (size > 1) {
    	    sort(seq, first, last);
        }
    }
    ```

* Iterative Parallelism

  * ```c++
    // gather
    template <typename BiIter, typename Pred>
    pair<BiIter, BiIter> gather(BiIter f, BiIter l, BiIter p, Pred pred)
    {
        BiIter it1 = stable_partition(f, p, not1(pred));
        BiIter it2 = stable_partition(p, l, pred);
        return make_pair(it1, it2);
    }
    // async
    template <typename BiIter, typename Pred>
    future<pair<BiIter, BiIter>> gather_async(BiIter f, BiIter l, BiIter p, Pred pred)
    {
        future<BiIter> f1 = stable_partition(par(task), f, p, not1(pred));
        future<BiIter> f2 = stable_partition(par(task), p, l, pred);
        co_return make_pair(co_await f1, co_await f2);
    }
    ```

* Asynchronous Channels

  * bidirectional P2P (MPI) communicators

  * asynchronous in nature

  * ```c++
    // futurized 2D stencil
    // execute this for each partition concurrently
    hpx::future<void> simulate(std::size_t steps)
    {
        for (size_t t = 0; t != steps; ++t)
        {
    	    co_await perform_one_time_step(t);
        }
        co_return;
    }
    
    future<void> upper_boundary(int t); // same for other boundaries
    
    future<void> perform_one_time_step(int t)
    {
        // Update our boundaries from neighbors
        co_await when_all(upper_boundary(t), right_boundary(t),
        	lower_boundary(t), left_boundary(t));
        // Apply stencil to partition
        co_await for_loop(par(task), min + 1, max - 1,
    	    [&](size_t idx) { /* apply stencil to each inner point */ });
    }
    
    future<void> upper_boundary(int t)
    {
        // Update upper boundary from upper neighbor
        vector<double> data = co_await channel_up_from.get(t);
        // process upper ghost-zone data using received data
        for_loop(seq, 1, size(data) - 1,
    	    [&](size_t idx) { /* apply stencil to each point in data */ });
        // send new ghost zone data to upper neighbor
        co_await channel_up_to.set(std::move(data), t + 1);
    }
    ```

* Futurization

  * automatically transform code [[C: Auto-CPS??]]
  * delay direct execution in order to avoid synchronization
  * generate execution tree representing the original algorithm
  * [hpx-futurization](http://stellar.cct.lsu.edu/files/hpx-0.9.9/html/hpx/tutorial/futurization_example.html)



## Avoid misuse of contract

* narrow contract: function having preconditions
* wide contract: no preconditions
  * hard to check
  * break algorithmic complexity guarantees
    * pay the cost of check
* mask defects
* bad maintainability
* hard to extend
* defensive programming: leave the behavior undefined [[N: WTF??]]



## Back to Basics Series

* ![image-20191130205144039](D:\OneDrive\Pictures\Typora\image-20191130205144039.png)
* ![image-20191130211908103](D:\OneDrive\Pictures\Typora\image-20191130211908103.png)
* ![image-20191130211919659](D:\OneDrive\Pictures\Typora\image-20191130211919659.png)
* Vtable
  * DRY/RTB(runtime binding)/OFD(Allows Override Functions in the Derived)/MLI(multi-level inheritance)/AED(add external derived)
* CRTP
  * DRY/OFD/MLI/AED
* Visitor
  * ![image-20191130212324896](D:\OneDrive\Pictures\Typora\image-20191130212324896.png)
  * DRY/RTB/OFD [[Q: runtime binding??]]
* Compile time visitor
  * DRY/OFD
* constexpr Function
  * ![image-20191130212437007](D:\OneDrive\Pictures\Typora\image-20191130212437007.png)
* ![image-20191130212456703](D:\OneDrive\Pictures\Typora\image-20191130212456703.png)



## Catching   ⬆️  

* `std::wstring_convert`
  * poorly implemented (`std::locale`)
  * low performance
* `codecvt`/facets
  * virtual interfaces
  * no data polymorphism/data type extensions
* ![image-20191130213154163](D:\OneDrive\Pictures\Typora\image-20191130213154163.png)
* `char16/32_t` to UTF-16/32 in C++20
  * not `__STD_C_UTF16/32__` any more
* ![image-20191130213543160](D:\OneDrive\Pictures\Typora\image-20191130213543160.png)
* ![image-20191130213602064](D:\OneDrive\Pictures\Typora\image-20191130213602064.png)
* ![image-20191130213639712](D:\OneDrive\Pictures\Typora\image-20191130213639712.png)
  * But slow
  * no SIMD possibilities (compiler barrier, restartable versions)
* ![image-20191130213819084](D:\OneDrive\Pictures\Typora\image-20191130213819084.png)
* ![image-20191130213848945](D:\OneDrive\Pictures\Typora\image-20191130213848945.png)
* ![image-20191130213903257](D:\OneDrive\Pictures\Typora\image-20191130213903257.png)
* ![image-20191130213930816](D:\OneDrive\Pictures\Typora\image-20191130213930816.png)
* ![image-20191130213951266](D:\OneDrive\Pictures\Typora\image-20191130213951266.png)
* ![image-20191130214107513](D:\OneDrive\Pictures\Typora\image-20191130214107513.png)
* ![image-20191130214218920](D:\OneDrive\Pictures\Typora\image-20191130214218920.png)
* ![image-20191130214225433](D:\OneDrive\Pictures\Typora\image-20191130214225433.png)
* ![image-20191130214248760](D:\OneDrive\Pictures\Typora\image-20191130214248760.png)
* ![image-20191130214316843](D:\OneDrive\Pictures\Typora\image-20191130214316843.png)
* ![image-20191130214330681](D:\OneDrive\Pictures\Typora\image-20191130214330681.png)
* ![image-20191130214529097](D:\OneDrive\Pictures\Typora\image-20191130214529097.png)
* ![image-20191130214534104](D:\OneDrive\Pictures\Typora\image-20191130214534104.png)
* ![image-20191130214543024](D:\OneDrive\Pictures\Typora\image-20191130214543024.png)
* ![image-20191130214559425](D:\OneDrive\Pictures\Typora\image-20191130214559425.png)
* ![image-20191130214610545](D:\OneDrive\Pictures\Typora\image-20191130214610545.png)
* ![image-20191130214618616](D:\OneDrive\Pictures\Typora\image-20191130214618616.png)
* ![image-20191130214637132](D:\OneDrive\Pictures\Typora\image-20191130214637132.png)
* ![image-20191130214647313](D:\OneDrive\Pictures\Typora\image-20191130214647313.png)
* ![image-20191130214740427](D:\OneDrive\Pictures\Typora\image-20191130214740427.png)
* ![image-20191130214746025](D:\OneDrive\Pictures\Typora\image-20191130214746025.png)
* ![image-20191130214754785](D:\OneDrive\Pictures\Typora\image-20191130214754785.png)
* ![image-20191130214808074](D:\OneDrive\Pictures\Typora\image-20191130214808074.png)
* ![image-20191130214829793](D:\OneDrive\Pictures\Typora\image-20191130214829793.png)
* ![image-20191130214839753](D:\OneDrive\Pictures\Typora\image-20191130214839753.png)
* ![image-20191130214856153](D:\OneDrive\Pictures\Typora\image-20191130214856153.png)
* ![image-20191130214901258](D:\OneDrive\Pictures\Typora\image-20191130214901258.png)
* ![image-20191130214912074](D:\OneDrive\Pictures\Typora\image-20191130214912074.png)
* ![image-20191130214921298](D:\OneDrive\Pictures\Typora\image-20191130214921298.png)
* ![image-20191130214927258](D:\OneDrive\Pictures\Typora\image-20191130214927258.png)
* ![image-20191130214933403](D:\OneDrive\Pictures\Typora\image-20191130214933403.png)
* ![image-20191130214941283](D:\OneDrive\Pictures\Typora\image-20191130214941283.png)
* ![image-20191130214948725](D:\OneDrive\Pictures\Typora\image-20191130214948725.png)
* ![image-20191130214954913](D:\OneDrive\Pictures\Typora\image-20191130214954913.png)
* ![image-20191130215003105](D:\OneDrive\Pictures\Typora\image-20191130215003105.png)



## Concepts: Evolution or Revolution?

* ![image-20191130220417248](D:\OneDrive\Pictures\Typora\image-20191130220417248.png)
* `auto`: unconstrained placeholder
* concept: constrained placeholder
* Template introduction
  * ![image-20191130221534946](D:\OneDrive\Pictures\Typora\image-20191130221534946.png)
* ![image-20191130221745844](D:\OneDrive\Pictures\Typora\image-20191130221745844.png)
  * [[N: open(trait, typeclass, structural) vs. close(concept, duck typing)]]





## Concurrency in C++20 and beyond

* Cooperative cancellation

  * `std::stop_source`, `std::stop_token`

  * ![image-20191130222523535](D:\OneDrive\Pictures\Typora\image-20191130222523535.png)

  * integrate with `std::condition_variable_any`

  * ```c++
    std::mutex m;
    std::queue<Data> q;
    std::condition_variable_any cv;
    Data wait_for_data(std::stop_token st){
        std::unique_lock lock(m);
        if(!cv.wait_until(
    	    	lock,[]{return !q.empty();},st))
        	throw op_was_cancelled();
        Data res=q.front();
        q.pop_front();
        return res;
    }
    // std::stop_callback to provide customized cancellation
    Data read_file(
            std::stop_token st,
            std::filesystem::path filename ){
        auto handle=open_file(filename);
        std::stop_callback cb(
    	    st,[=]{ cancel_io(handle);});
        return read_data(handle); // blocking
    }
    ```

* New thread `std::jthread`

  * destroying `std::jthread` calls `source.request_stop()` & `thread.join()`

  * ```c++
    void thread_func(
        std::stop_token st,
        std::string arg1,int arg2){
        while(!st.stop_requested()){
    	    do_stuff(arg1,arg2);
        }
    }
    void foo(std::string s){
        std::jthread t(thread_func,s,42);
        do_stuff();
    } // destructor requests stop and joins
    ```

* New synchronization facilities

  * latch

    * single-use counter that allows threads to wait for the count to reach zero

    * ![image-20191130222902326](D:\OneDrive\Pictures\Typora\image-20191130222902326.png)

    * ```c++
      void foo(){
          unsigned const thread_count=...;
          std::latch done(thread_count);
          my_data data[thread_count];
          std::vector<std::jthread> threads;
          for(unsigned i=0;i<thread_count;++i)
              threads.push_back(std::jthread([&,i]{
                  data[i]=make_data(i);
                  done.count_down();
                  do_more_stuff();
              }));
          done.wait();
          process_data();
      }
      ```

    * ![image-20191130222952778](D:\OneDrive\Pictures\Typora\image-20191130222952778.png)

    * great for multithreaded tests

  * barrier

    * reusable barrier

    * ![image-20191130223009715](D:\OneDrive\Pictures\Typora\image-20191130223009715.png)

    * great for loop synchronization between parallel tasks

    * ```c++
      unsigned const num_threads=...;
      void finish_task();
      std::barrier<std::function<void()>> b(
      	num_threads,finish_task);
      
      void worker_thread(
      	std::stop_token st,unsigned i){
          while(!st.stop_requested()){
              do_stuff(i);
              b.arrive_and_wait();
          }
      }
      ```

  * semaphore

    * P-V operations for acquiring/release slots
    * great to build any synchronization mechanisms
    * `std::counting_semaphore<max_count>` (`using std::binary_semaphore = std::counting_semaphore<1>`)
    * blocking `sem.acquire()`, non-blocking `sem.try_acquire{_for/_until}`

* update to atomics

  * low-level waiting for atomics

    * `atomic<T>::wait`: wait for it to change
    * `atomic<T>::notify_one`/`atomic<T>::notify_all`
    * like low-level `std::condition_variable`

  * atomic smart pointers

    * `atomic<shared_ptr<T>>` & `atomic<weak_ptr<T>>`

    * ![image-20191130223430247](D:\OneDrive\Pictures\Typora\image-20191130223430247.png)

    * ```c++
      template<typename T> class stack{
          struct node{
              T value;
              shared_ptr<node> next;
              node(){} node(T&& nv):value(std::move(nv)){}
          };
          std::atomic<shared_ptr<node>> head;
      public:
          stack():head(nullptr){}
          ~stack(){ while(head.load()) pop(); }
          void push(T);
          T pop();
      };
      
      template<typename T>
      void stack<T>::push(T val){
          auto new_node=std::make_shared<node>(
          std::move(val));
          new_node->next=head.load();
          while(!head.compare_exchange_weak(
      	    new_node->next,new_node)){}
      }
      
      template<typename T>
      T stack<T>::pop(){
          auto old_head=head.load();
          while(old_head){
              if(head.compare_exchange_strong(
      	        old_head,old_head->next))
              return std::move(old_head->value);
          }
          throw std::runtime_error("Stack empty");
      }
      ```

  * `std::atomic_ref`

    * atomic operations on non-atomic objects
    * ![image-20191130223614503](D:\OneDrive\Pictures\Typora\image-20191130223614503.png)

* Coroutines

  * A coroutine is a function that can be suspended mid execution and resumed at a later time.

  * Resuming a coroutine continues from the suspension point; local variables have their values from the original call.  

  * ![image-20191130223648596](D:\OneDrive\Pictures\Typora\image-20191130223648596.png)

  * ```c++
    future<remote_data>
    async_get_data(key_type key);
    
    future<data> retrieve_data(
    				key_type key){
        auto rem_data=
    	    co_await async_get_data(key);
        co_return process(rem_data);
    }
    ```

  * no library support for coroutines

* New Concurrency Features for future standards

  * ![image-20191130223750196](D:\OneDrive\Pictures\Typora\image-20191130223750196.png)

* A synchronization wrapper for ordinary objects

  * `synchronized_value` encapsulates a mutex & a value ([[C: Rust `Arc<T>`]])

  * ![image-20191130223910851](D:\OneDrive\Pictures\Typora\image-20191130223910851.png)

  * ```c++
    synchronized_value<std::string> sv;
    synchronized_value<std::string> sv2;
    
    std:string combine_strings(){
        return apply(
            [&](std::string& s,std::string & s2){
    	        return s+s2;
            },sv,sv2);
    }
    ```

* Enhancement for `std::future`

  * Continuations

  * Waiting for all of/one of a set of futures

  * all in `std::experiemental`

  * ![image-20191130224029483](D:\OneDrive\Pictures\Typora\image-20191130224029483.png)

  * ```c++
    stdexp::future<int> find_the_answer();
    std::string process_result(
    	stdexp::future<int>);
    auto f=find_the_answer();
    auto f2=f.then(process_result);
    ```

  * ![image-20191130224055548](D:\OneDrive\Pictures\Typora\image-20191130224055548.png)

  * ![image-20191130224107275](D:\OneDrive\Pictures\Typora\image-20191130224107275.png)

  * ```c++
    auto f1=spawn_async(foo);
    auto f2=spawn_async(bar);
    auto f3=stdexp::when_any(
    	std::move(f1),std::move(f2));
    auto final_result=f3.then(
    	process_ready_result);
    do_stuff(final_result.get());
    ```

  * ![image-20191130224126256](D:\OneDrive\Pictures\Typora\image-20191130224126256.png)

  * ```c++
    auto f1=spawn_async(subtask1);
    auto f2=spawn_async(subtask2);
    auto f3=spawn_async(subtask3);
    auto results=stdexp::when_all(
        std::move(f1),std::move(f2),
        std::move(f3));
    results.then(process_all_results);
    ```

* Executors

  * An object that controls how, where and when a task is executed  
  * ![image-20191130224207499](D:\OneDrive\Pictures\Typora\image-20191130224207499.png)
  * ![image-20191130224230793](D:\OneDrive\Pictures\Typora\image-20191130224230793.png)

* Coroutine support for concurrency

  * ![image-20191130224249100](D:\OneDrive\Pictures\Typora\image-20191130224249100.png)

* Concurrent data structures

  * Concurrent Queues
  * Concurrent Hash Maps

* Safe Memory Reclamation Facilities

  * ![image-20191130224341923](D:\OneDrive\Pictures\Typora\image-20191130224341923.png)

* ![image-20191130224349420](D:\OneDrive\Pictures\Typora\image-20191130224349420.png)



## C++ at 40

* ![image-20191130225041138](D:\OneDrive\Pictures\Typora\image-20191130225041138.png)
* [[N: this slide is attached with BS personal notes!]]



## C++20 standard library beyond ranges

* ```c++
  {
      int width = 10;
      int precision = 3;
      // format like {0:10.3f}
      auto s = fmt::format("{0:{1}.{2}f}", 12.345678, width, precision);
      // s == " 12.346"
  }
  
  //annotated version
  enum class my_color {red, green, blue, orange};
  
  namespace fmt { // <- template specialiation in fmt namespace
      template <> // <- syntax for specialization
      struct formatter<my_color>: formatter<string_view> { //inherit from f
          template <typename FormatContext>
          auto format(my_color c, FormatContext &ctx) {
              string_view name = "unknown color"; // <- some default text
              switch (c) {
                  case my_color::red: name = "red"; break;
                  case my_color::green: name = "green"; break;
                  case my_color::blue: name = "blue"; break;
              } //should there be a fallthru instead?
              return formatter<string_view>::format(name, ctx);
          }
      }; //struct formatter<my_color>
  }//namespace fmt
  ```

* ![image-20191130231137997](D:\OneDrive\Pictures\Typora\image-20191130231137997.png)

* ![image-20191130231159731](D:\OneDrive\Pictures\Typora\image-20191130231159731.png)

* ```c++
  #include <syncstream> //new header
  //...
  {
      osyncstream buffered_out(cout);
      buffered_output << " the answer might be 42" << endl;
  } 	//on destruction buffered_out now calls emit()
  	//emit() flushes the buffer to cout
  {
      std::ofstream out_file("my_file");
      osyncstream buffered_out(out_file);
      std::emit_on_flush(buffered_out);
      buffered_out << "hello world" << endl; //calls emit()
  }
  
  void do_output(std::ostream& ofile ) {
  	osyncstream buf_file{ofile};
  // ...complex code that writes to file and may throw
  } //ensures buf_file is flushed to outfile
  std::ofstream out_file("my_file");
  std::thread out_thread1( &do_output, out_file );
  std::thread out_thread2( &do_output, out_file );
  ```

* ![image-20191130231311204](D:\OneDrive\Pictures\Typora\image-20191130231311204.png)

* ![image-20191130231319598](D:\OneDrive\Pictures\Typora\image-20191130231319598.png)

* ```c++
  void print_reverse(span<int> si) { //by value
      for ( auto i : std::ranges::reverse_view{si} ) {
  	    cout << i << " " ;
      }
      cout << "\n";
  }
  int main () {
      vector<int> vi = { 1, 2, 3, 4, 5 };
      print_reverse( vi ); //5 4 3 2 1
      int cai[] = { 1, 2, 3, 4, 5 };
      print_reverse ( cai ); //5 4 3 2 1
      span<int> si ( vi );
      print_reverse( si.first(2) ); //2 1
      print_reverse( si.last(2) ); //5 4
  }
  // static
  array<int, 5> ai = { 1, 2, 3, 4, 5 };
  span<int, 5> si5( ai );
  print_reverse ( si5 ); //5 4 3 2 1
  // dynamic extent
  span<int> si3( ai );
  ```

* ![image-20191130231620464](D:\OneDrive\Pictures\Typora\image-20191130231620464.png)

* ```c++
  year_month_day ymd(year(2019)/05/07);
  sys_days d( ymd );
  d += weeks(1);
  cout << ymd << "/n"; //2019-05-07
  cout << d << "/n"; //2019-05-14
  year_month_day ymd(year(2019)/100/200);
  if ( !ymd.ok() ) {
  	cout << "bad ymd\n"; //executes
  }
  const std::chrono::year_month_day ymd(2019_y/05/07);
  std::string s = std::format("the date is {:%m-%d-%Y}.\n", ymd);
  							cout << s << "\n"; //
  auto zt = std::chrono::zoned_time(...);
  std::cout << std::format(std::locale{"fi_FI"},
  				"Localized time is {:%c}\n", zt);
  ```

* ![image-20191130231655710](D:\OneDrive\Pictures\Typora\image-20191130231655710.png)

* ![image-20191130231807565](D:\OneDrive\Pictures\Typora\image-20191130231807565.png)

* ```c++
  //shared_ptr to a default-initialized double[1024]
  //where each element has an indeterminate value
  shared_ptr<double[]> p = make_shared_default_init<double[]>(1024);
  ```

* ![image-20191130231831789](D:\OneDrive\Pictures\Typora\image-20191130231831789.png)

* ```c++
  void f(source_location a = source_location::current()) {
      // values in b refer to the line below
      source_location b = source_location::current();
      // ...
  }
  // f’s first argument corresponds to this line of code
  f();
  // f’s first argument gets the same values as c, above
  source_location c = source_location::current();
  f(c);
  
  struct s {
      source_location contruct_loc = source_location::current();
      int other_member;
      // values of construct_loc refer to the location of the calling func
      s(source_location loc = source_location::current())
      : construct_loc(loc)
      {}
      // values of construct_loc refer to this location
      s(int i) :
      other_member( i )
      {}
      // values of construct_loc refer to this location
      s(double)
      {}
  };
  ```

* ![image-20191130231908317](D:\OneDrive\Pictures\Typora\image-20191130231908317.png)

* ![image-20191130231914573](D:\OneDrive\Pictures\Typora\image-20191130231914573.png)

* ![image-20191130231928758](D:\OneDrive\Pictures\Typora\image-20191130231928758.png)





## De-fragmenting C++: Making exceptions & RTTI more affordable & usable

* ![image-20191130232333470](D:\OneDrive\Pictures\Typora\image-20191130232333470.png)
* ![image-20191130232523365](D:\OneDrive\Pictures\Typora\image-20191130232523365.png)
* ![image-20191130232547201](D:\OneDrive\Pictures\Typora\image-20191130232547201.png)
* ![image-20191130232555903](D:\OneDrive\Pictures\Typora\image-20191130232555903.png)
* [[N: panic `!` vs `Result<T, E>`]]
* ![image-20191130232735438](D:\OneDrive\Pictures\Typora\image-20191130232735438.png)
* ![image-20191130232751883](D:\OneDrive\Pictures\Typora\image-20191130232751883.png)
* ![image-20191130232807185](D:\OneDrive\Pictures\Typora\image-20191130232807185.png)
* ![image-20191130232815775](D:\OneDrive\Pictures\Typora\image-20191130232815775.png)
* ![image-20191130232911712](D:\OneDrive\Pictures\Typora\image-20191130232911712.png)
* ![image-20191130232916304](D:\OneDrive\Pictures\Typora\image-20191130232916304.png)
* ![image-20191130232927621](D:\OneDrive\Pictures\Typora\image-20191130232927621.png)
* ![image-20191130233007705](D:\OneDrive\Pictures\Typora\image-20191130233007705.png)
* ![image-20191130233028586](D:\OneDrive\Pictures\Typora\image-20191130233028586.png)
* ![image-20191130233103814](D:\OneDrive\Pictures\Typora\image-20191130233103814.png)
* ![image-20191130233223784](D:\OneDrive\Pictures\Typora\image-20191130233223784.png)



## Destructor Case Studies

* ![image-20191201111239825](D:\OneDrive\Pictures\Typora\image-20191201111239825.png)
* ![image-20191201111335362](D:\OneDrive\Pictures\Typora\image-20191201111335362.png)



## Fixing Cpp with epochs

* ![image-20191201115656717](D:\OneDrive\Pictures\Typora\image-20191201115656717.png)
* ![image-20191201115711857](D:\OneDrive\Pictures\Typora\image-20191201115711857.png)



## Floating-Point `<charconv>`

* ![image-20191201144913788](D:\OneDrive\Pictures\Typora\image-20191201144913788.png)



## Getting Allocators out of Our Way

* ```c++
  std::size_t unique_chars(std::string_view s)
  {
      std::byte buffer[4096];
      std::pmr::monotonic_buffer_resource rsrc(buffer, sizeof buffer);
      std::pmr::set<char> uniq();
      uniq.insert(s.begin(), s.end());
      return uniq.size();
  }
  ```

* ![image-20191201165214421](D:\OneDrive\Pictures\Typora\image-20191201165214421.png)

* ![image-20191201165221118](D:\OneDrive\Pictures\Typora\image-20191201165221118.png)

* ![image-20191201165227202](D:\OneDrive\Pictures\Typora\image-20191201165227202.png)

* ![image-20191201165244514](D:\OneDrive\Pictures\Typora\image-20191201165244514.png)

* C++11 Allocators

  * ![image-20191201205247767](D:\OneDrive\Pictures\Typora\image-20191201205247767.png)
  * ![image-20191201205253455](D:\OneDrive\Pictures\Typora\image-20191201205253455.png)

* C++17 PMR

  * ![image-20191201214000594](D:\OneDrive\Pictures\Typora\image-20191201214000594.png)
  * ![image-20191201214009642](D:\OneDrive\Pictures\Typora\image-20191201214009642.png)
  * ![image-20191201214016465](D:\OneDrive\Pictures\Typora\image-20191201214016465.png)
  * runtime resource type
  * interoperability
  * ![image-20191201214050073](D:\OneDrive\Pictures\Typora\image-20191201214050073.png)
  * `std::pmr::new_delete_resource()`
    * thread-safe, delegate to heap
  * `std::pmr::unsynchronized_pool_resource()`
    * single-threaded
    * pools of similar sized objects
  * `std::pmr::monotonic_buffer_resource`
    * fast. single-threaded, contiguous buffers, no deallocate

* ![image-20191201214337154](D:\OneDrive\Pictures\Typora\image-20191201214337154.png)

* proposal: allocator aware type

* ![image-20191201214406810](D:\OneDrive\Pictures\Typora\image-20191201214406810.png)

* ![image-20191201214713458](D:\OneDrive\Pictures\Typora\image-20191201214713458.png)



## High performance graphics and text rendering on the GPU

* ![image-20191201220716780](D:\OneDrive\Pictures\Typora\image-20191201220716780.png)
* instance
  * connection between your application and the Vulkan library  
  * typically your application will only create one
  * every other Vulkan call relies on passing this instance or some data associated with this instance

* context
  * Vulkan instance is similar to an OpenGL context  
* surface
  * a term for the window region where images are rendered  
  * native window support is not handled directly in the API, implemented in platform extensions
* memory heap
  * provides storage for buffers which will be accessed by the GPU
  * every buffer must be created and managed by the user
  * memory is allocated from a memory heap
  * the buffer is then bounded to the allocated memory
  * any memory which is visible to the GPU will be in the list of all memory heaps
  * usually multiple heaps available
  * certain heaps can only be used for specific types of buffers
* vertex buffer
  * coordinates of all vertices which describes the geometry for the image being rendered
  * triangles are the most widely used shape
* uniform buffer
  * data applied to every vertex
  * transformations
* shader
  * a program which is written in a specialized language
  * OpenGL: GLSL
  * Direct3D: HLSL
  * Vulkan: GLSL/HLSL -> SPIR-V binary format
* vertex shader
  * 3D position into 2D coordinates
  * execute once per vertex
* tessellation shader
  * decompose shapes into smaller components, optional
* geometry shader
  * alters the vertex shader output, optional
* fragment shader
  * lighting & texture to calculate colors
  * execute at least once per pixel or fragment (partial pixel)
* pipeline
  * before a draw command is added to a command buffer, you must create a pipeline object which sets a whole lot of options
  * shader handles, descriptor sets, push constants, depth buffer
  * winding direction, culling options, viewport
  * stencil, scissor, blending
* command buffer
  * accumulate draw commands which are executed on the GPU at a later time
  * only way to synchronize these commands is by using a barrier
    * set semaphore, query semaphore
    * wait for pipeline stage (E.g. wait for a vertex shader to finish)
* frame buffer
  * no default buffer exists since displaying an image is optional
  * typically contains one image
  * not required if no images are displayed
* depth buffer
  * a 3D mesh has perspective and to draw it realistically some triangles must appear in front of other triangles
  * determine what part of the mesh is closer to the camera
  * misconfiguring this buffer will result in far away objects being rendered on top of closer objects
* render pass
  * added for improved performance on mobile
  * for tile based GPU support
  * a pipeline needs information about color channels, the depth buffer, possible image sampling, etc. all of this information is split into one or more render passes
  * begin command buffer, begin render pass
  * add commands for this one pass
  * end render pass, end command buffer
* swapchain
  * a set of buffers where the GPU can render
  * no default frame buffer in Vulkan
  * creating a swapchain is the only way to create an empty frame buffer
  * each frame buffer will hold a single image which is waiting to be presented on the surface
  * a single swap chain can contain many frame buffers
  * platform specific, supply through extensions which are requested when you create the Vulkan instance
* Queues
  * similar to a CPU thread, fixed number of queues on the GPU
  * each queue is intended to execute a certain kind of operation
  * a mechanism to send commands to the GPU for processing
  * graphics queue: generate an image
  * present queue: copy images to the screen
  * computation queue: run general purpose computations
  * transfer queue: copy data between CPU memory & GPU memory
* Synchronization
  * `draw_frame()` is a function you write which puts a sequence of commands in a queue
  * responsible for the following operatons
    * retrieve an inactive frame buffer from the swapchain
    * build a command buffer
    * submit the command buffer to the graphics queue
    * submit the frame buffer to the presentation queue
  * additional constraints required for operations which have dependencies
  * fence
    * synchronize work between CPU & GPU
    * status of a fence can be accessed from your program
  * semaphore
    * synchronize work occurring on the GPU
    * semaphore dependencies are set up in your program however only observed on the GPU
    * not visible to the GPU, nor can you query their status
* winding direction
  * must be specified as part of the pipeline
  * conventionally clockwise winding is used
  * direction used to determine whether a given triangle is facing the camera (front facing) / facing away (back facing)
* back face culling
  * is the process of discarding triangles which are back facing since these are not normally visible to the viewer  
  * there is no default so it must be set on or off in the pipeline  
  * triangles are "culled" early in the rendering pipeline  
  * increases efficiency by reducing the number of fragments which are processed  
* push constants
  * a way to provide a small amount of uniform data to shaders
* scissors
  * scissor test restricts drawing to the specified rectangle
  * test is always enabled & can not be turned off
* extent
  * structure containing width & height
  * define things like the size of the screen / the render area
* viewport
  * specifies a region of the frame buffer which should be refreshed, potentially complicated to determine
* ![image-20191201224443891](D:\OneDrive\Pictures\Typora\image-20191201224443891.png)
* ![image-20191201224457943](D:\OneDrive\Pictures\Typora\image-20191201224457943.png)



## How to write a heap profiler

* ![image-20191202204035534](D:\OneDrive\Pictures\Typora\image-20191202204035534.png)

* preloading

  * `LD_PRELOAD=$(readlink -f path/to/libfoo.so) some_app`

* stack unwinding

  * unwind the stack to get backtrace

  * ![image-20191202204140084](D:\OneDrive\Pictures\Typora\image-20191202204140084.png)

  * ![image-20191202204152731](D:\OneDrive\Pictures\Typora\image-20191202204152731.png)

  * ```c++
    #define UNW_LOCAL_ONLY
    #include <libunwind.h>
    
    std::vector<void*> backtrace()
    {
        const auto MAX_SIZE = 64;
        std::vector<void *> trace(MAX_SIZE);
        const auto size = unw_backtrace(trace.data(), MAX_SIZE);
        trace.resize(size);
        return trace;
    }
    ```

* symbol resolution

  * `cat /proc/$(pidof delay)/maps`
  * find sections, get offset
  * `addr2line -p -e ./delay -a offset`
  * `addr2line -p -f -e ./delay -a offset` (with function names)
  * `addr2line -p -f -C -e` with demangling
  * `addr2line -p -f -C -i -e` with inlines
  * ELF mappings
    * ![image-20191202204523561](D:\OneDrive\Pictures\Typora\image-20191202204523561.png)
    * ![image-20191202204542524](D:\OneDrive\Pictures\Typora\image-20191202204542524.png)
  * elfutils
    * `libdwfl`
    * ![image-20191202204611484](D:\OneDrive\Pictures\Typora\image-20191202204611484.png)
    * ![image-20191202204616374](D:\OneDrive\Pictures\Typora\image-20191202204616374.png)
    * ![image-20191202204621204](D:\OneDrive\Pictures\Typora\image-20191202204621204.png)
    * ![image-20191202204630084](D:\OneDrive\Pictures\Typora\image-20191202204630084.png)
    * ![image-20191202204635204](D:\OneDrive\Pictures\Typora\image-20191202204635204.png)
  * Demangling
    * `c++filt`
    * `cxxabi.h` -> `abi::__cxa_demangle`
  * inline frames
    * ![image-20191202204730557](D:\OneDrive\Pictures\Typora\image-20191202204730557.png)
    * ![image-20191202204931918](D:\OneDrive\Pictures\Typora\image-20191202204931918.png)
    * ![image-20191202204956429](D:\OneDrive\Pictures\Typora\image-20191202204956429.png)
    * ![image-20191202205010254](D:\OneDrive\Pictures\Typora\image-20191202205010254.png)
    * ![image-20191202212157895](D:\OneDrive\Pictures\Typora\image-20191202212157895.png)
  * Clang support
    * ![image-20191202212213326](D:\OneDrive\Pictures\Typora\image-20191202212213326.png)

* runtime attaching

  * ![image-20191202212411238](D:\OneDrive\Pictures\Typora\image-20191202212411238.png)
  * ![image-20191202212421462](D:\OneDrive\Pictures\Typora\image-20191202212421462.png)
  * ![image-20191202212432862](D:\OneDrive\Pictures\Typora\image-20191202212432862.png)
  * ![image-20191202212453752](D:\OneDrive\Pictures\Typora\image-20191202212453752.png)
  * ![image-20191202212504561](D:\OneDrive\Pictures\Typora\image-20191202212504561.png)
  * ![image-20191202212509062](D:\OneDrive\Pictures\Typora\image-20191202212509062.png)
  * ![image-20191202212514519](D:\OneDrive\Pictures\Typora\image-20191202212514519.png)
  * ![image-20191202212519902](D:\OneDrive\Pictures\Typora\image-20191202212519902.png)
  * ![image-20191202212525702](D:\OneDrive\Pictures\Typora\image-20191202212525702.png)
  * ![image-20191202212531985](D:\OneDrive\Pictures\Typora\image-20191202212531985.png)

* ![image-20191202212543454](D:\OneDrive\Pictures\Typora\image-20191202212543454.png)



## Linux C++ Quality & Debugging Tools - Under the covers

* ![image-20191202223728946](D:\OneDrive\Pictures\Typora\image-20191202223728946.png)
* ![image-20191202223738498](D:\OneDrive\Pictures\Typora\image-20191202223738498.png)
* ![image-20191202223743233](D:\OneDrive\Pictures\Typora\image-20191202223743233.png)
* ![image-20191202223747372](D:\OneDrive\Pictures\Typora\image-20191202223747372.png)
* SIGTRAP per syscall: on syscall entry & exit
* AX contains -38 (-ENOSYS) on entry
* ![image-20191202223909066](D:\OneDrive\Pictures\Typora\image-20191202223909066.png)
* breakpoint: `int $3/0xcc`, SIGTRAP, debug registers (db0...db7), `PTRACE_POKEUSER`



## Mostly invalid

* ![image-20191202224139946](D:\OneDrive\Pictures\Typora\image-20191202224139946.png)
* ![image-20191202224201923](D:\OneDrive\Pictures\Typora\image-20191202224201923.png)
* ![image-20191202224303523](D:\OneDrive\Pictures\Typora\image-20191202224303523.png)
* ![image-20191202224344434](D:\OneDrive\Pictures\Typora\image-20191202224344434.png)



## Non-conforming C++

* case ranges

  * ```c++
    switch (ch) {
        case '\0':
        case '0'...'9':
    }
    ```

* unnamed structure & union fields

  * ```c++
    struct vec4 {
        union {
            float array[4];
            struct {
                float x, y, z, w;
            }
        }
    }
    ```

* conditionals with omitted operands

  * ```c++
    auto read_or_default() {
        return read() ?: default_value(); // evaluate once
    }
    ```

* designated initializers

* designated array initializers

  * ```c++
    enum color {
        red,
        blue,
        ...
    };
    constexpr uint32_t color_value[] = {
        [red] = 0x0000ff,
        [green] = 0x00ff00,
        ...
    };
    int i[] = {
        [2] = 17,
        f(),
        [9 ... 20] = x,
        [4 ... 7] = 88,
        100,
    };
    ```

* flexible array member (soft array)

  * ![image-20191202225833142](D:\OneDrive\Pictures\Typora\image-20191202225833142.png)
  * ![image-20191202225922733](D:\OneDrive\Pictures\Typora\image-20191202225922733.png)
  * ![image-20191202225930869](D:\OneDrive\Pictures\Typora\image-20191202225930869.png)
  * ![image-20191202230003590](D:\OneDrive\Pictures\Typora\image-20191202230003590.png)
  * ![image-20191202230013549](D:\OneDrive\Pictures\Typora\image-20191202230013549.png)

* Labels as values / computed goto

  * ![image-20191202230134038](D:\OneDrive\Pictures\Typora\image-20191202230134038.png)
  * ![image-20191202230216046](D:\OneDrive\Pictures\Typora\image-20191202230216046.png)
  * ![image-20191202230224420](D:\OneDrive\Pictures\Typora\image-20191202230224420.png)

* ![image-20191202230246875](D:\OneDrive\Pictures\Typora\image-20191202230246875.png)

* ![image-20191202230345061](D:\OneDrive\Pictures\Typora\image-20191202230345061.png)

* ![image-20191202230425158](D:\OneDrive\Pictures\Typora\image-20191202230425158.png)

* [computed-goto-for-efficient-dispatch](https://eli.thegreenplace.net/2012/07/12/computed-goto-for-efficient-dispatch-tables)



## Pattern matching a sneak peek

* ![image-20191202232643276](D:\OneDrive\Pictures\Typora\image-20191202232643276.png)
* ![image-20191202232659117](D:\OneDrive\Pictures\Typora\image-20191202232659117.png)
* ![image-20191202232711008](D:\OneDrive\Pictures\Typora\image-20191202232711008.png)
* ![image-20191202232715077](D:\OneDrive\Pictures\Typora\image-20191202232715077.png)
* ![image-20191202232722792](D:\OneDrive\Pictures\Typora\image-20191202232722792.png)
* ![image-20191202232738269](D:\OneDrive\Pictures\Typora\image-20191202232738269.png)
* ![image-20191202232748102](D:\OneDrive\Pictures\Typora\image-20191202232748102.png)
* ![image-20191202232808933](D:\OneDrive\Pictures\Typora\image-20191202232808933.png)
* ![image-20191202232816469](D:\OneDrive\Pictures\Typora\image-20191202232816469.png)
* ![image-20191202232826599](D:\OneDrive\Pictures\Typora\image-20191202232826599.png)
* ![image-20191202232832181](D:\OneDrive\Pictures\Typora\image-20191202232832181.png)
* ![image-20191202232837150](D:\OneDrive\Pictures\Typora\image-20191202232837150.png)
* ![image-20191202232841214](D:\OneDrive\Pictures\Typora\image-20191202232841214.png)
* ![image-20191202232853917](D:\OneDrive\Pictures\Typora\image-20191202232853917.png)
* ![image-20191202232858630](D:\OneDrive\Pictures\Typora\image-20191202232858630.png)
* ![image-20191202232934534](D:\OneDrive\Pictures\Typora\image-20191202232934534.png)
* ![image-20191202232950578](D:\OneDrive\Pictures\Typora\image-20191202232950578.png)
* ![image-20191202233001864](D:\OneDrive\Pictures\Typora\image-20191202233001864.png)
* ![image-20191202233031182](D:\OneDrive\Pictures\Typora\image-20191202233031182.png)



## Practical Modules

* ![image-20191203001222570](D:\OneDrive\Pictures\Typora\image-20191203001222570.png)
* ![image-20191203001244170](D:\OneDrive\Pictures\Typora\image-20191203001244170.png)
* Modularization options
  * module importation
    * ![image-20191203003251314](D:\OneDrive\Pictures\Typora\image-20191203003251314.png)
    * `.mpp` -> `.bmi`
    * ![image-20191203002559243](D:\OneDrive\Pictures\Typora\image-20191203002559243.png)
    * ![image-20191203002611673](D:\OneDrive\Pictures\Typora\image-20191203002611673.png)
  * header importation
    * ![image-20191203003242947](D:\OneDrive\Pictures\Typora\image-20191203003242947.png)
    * ![image-20191203002525399](D:\OneDrive\Pictures\Typora\image-20191203002525399.png)
    * ![image-20191203002534674](D:\OneDrive\Pictures\Typora\image-20191203002534674.png)
  * include translation (to Header importation)
    * ![image-20191203003233733](D:\OneDrive\Pictures\Typora\image-20191203003233733.png)
    * ![image-20191203002401033](D:\OneDrive\Pictures\Typora\image-20191203002401033.png)
    * ![image-20191203002512537](D:\OneDrive\Pictures\Typora\image-20191203002512537.png)
* ![image-20191203002626163](D:\OneDrive\Pictures\Typora\image-20191203002626163.png)
* ![image-20191203002820018](D:\OneDrive\Pictures\Typora\image-20191203002820018.png)
* ![image-20191203002854763](D:\OneDrive\Pictures\Typora\image-20191203002854763.png)
* ![image-20191203002904802](D:\OneDrive\Pictures\Typora\image-20191203002904802.png)
* ![image-20191203002921860](D:\OneDrive\Pictures\Typora\image-20191203002921860.png)
* ![image-20191203002932363](D:\OneDrive\Pictures\Typora\image-20191203002932363.png)
* ![image-20191203002946307](D:\OneDrive\Pictures\Typora\image-20191203002946307.png)
* ![image-20191203003002610](D:\OneDrive\Pictures\Typora\image-20191203003002610.png)
* ![image-20191203003022698](D:\OneDrive\Pictures\Typora\image-20191203003022698.png)
* ![image-20191203003125604](D:\OneDrive\Pictures\Typora\image-20191203003125604.png)
* ![image-20191203003142113](D:\OneDrive\Pictures\Typora\image-20191203003142113.png)
* ![image-20191203003146353](D:\OneDrive\Pictures\Typora\image-20191203003146353.png)
* ![image-20191203003151186](D:\OneDrive\Pictures\Typora\image-20191203003151186.png)
* ![image-20191203003156241](D:\OneDrive\Pictures\Typora\image-20191203003156241.png)
* ![image-20191203003213907](D:\OneDrive\Pictures\Typora\image-20191203003213907.png)



## Reflections

* ![image-20191203003902162](D:\OneDrive\Pictures\Typora\image-20191203003902162.png)
* ![image-20191203003908849](D:\OneDrive\Pictures\Typora\image-20191203003908849.png)
* ![image-20191203003915273](D:\OneDrive\Pictures\Typora\image-20191203003915273.png)
* ![image-20191203003929297](D:\OneDrive\Pictures\Typora\image-20191203003929297.png)
* ![image-20191203003947744](D:\OneDrive\Pictures\Typora\image-20191203003947744.png)
* ![image-20191203003956608](D:\OneDrive\Pictures\Typora\image-20191203003956608.png)
* ![image-20191203004005457](D:\OneDrive\Pictures\Typora\image-20191203004005457.png)
* ![image-20191203004037572](D:\OneDrive\Pictures\Typora\image-20191203004037572.png)
* ![image-20191203004102240](D:\OneDrive\Pictures\Typora\image-20191203004102240.png)
* ![image-20191203004108465](D:\OneDrive\Pictures\Typora\image-20191203004108465.png)
* ![image-20191203004119345](D:\OneDrive\Pictures\Typora\image-20191203004119345.png)
* ![image-20191203004127921](D:\OneDrive\Pictures\Typora\image-20191203004127921.png)
* ![image-20191203004148433](D:\OneDrive\Pictures\Typora\image-20191203004148433.png)



## The Network TS in Practice

* ![image-20191203004837059](D:\OneDrive\Pictures\Typora\image-20191203004837059.png)
* ![image-20191203004845795](D:\OneDrive\Pictures\Typora\image-20191203004845795.png)
* ![image-20191203004850898](D:\OneDrive\Pictures\Typora\image-20191203004850898.png)
* ![image-20191203004903737](D:\OneDrive\Pictures\Typora\image-20191203004903737.png)
* ![image-20191203004912228](D:\OneDrive\Pictures\Typora\image-20191203004912228.png)
* ![image-20191203004917922](D:\OneDrive\Pictures\Typora\image-20191203004917922.png)
* ![image-20191203004923515](D:\OneDrive\Pictures\Typora\image-20191203004923515.png)
* ![image-20191203004931475](D:\OneDrive\Pictures\Typora\image-20191203004931475.png)
* ![image-20191203004935619](D:\OneDrive\Pictures\Typora\image-20191203004935619.png)
* ![image-20191203004940148](D:\OneDrive\Pictures\Typora\image-20191203004940148.png)
* ![image-20191203004948043](D:\OneDrive\Pictures\Typora\image-20191203004948043.png)
* ![image-20191203004953667](D:\OneDrive\Pictures\Typora\image-20191203004953667.png)
* ![image-20191203005007148](D:\OneDrive\Pictures\Typora\image-20191203005007148.png)
* ![image-20191203005202675](D:\OneDrive\Pictures\Typora\image-20191203005202675.png)
* ![image-20191203005207547](D:\OneDrive\Pictures\Typora\image-20191203005207547.png)
* ![image-20191203005214954](D:\OneDrive\Pictures\Typora\image-20191203005214954.png)
* ![image-20191203005228578](D:\OneDrive\Pictures\Typora\image-20191203005228578.png)
* ![image-20191203005235411](D:\OneDrive\Pictures\Typora\image-20191203005235411.png)
* ![image-20191203005245947](D:\OneDrive\Pictures\Typora\image-20191203005245947.png)
* ![image-20191203005252347](D:\OneDrive\Pictures\Typora\image-20191203005252347.png)



## Unicode: going down the rabbit hole

* Single-byte encodings
  * ASCII compatible
* Multi-byte
* Variable-length encodings
  * self-synchronizing
  * non-self-synchronizing
* ASCII: American Standard Code for Informatino Interchange
  * 7-bit all characters in logical order
  * 1963AD
* EBCDIC: extended from binary-coded decimal (BCD) interchange code
  * 8-bit, compatible with punch cards
  * 1963AD
* GB2312
  * 8-bit, bottom half is ASCII
  * variable length, multibyte-character set
  * Chinese character set
  * AD1981
* ANSI: Extended ASCII
  * Code Page 437 from DOS
  * 8-bit, bottom half is ASCII
  * top half filled with line drawing & some math symbols
  * AD1981
* DOS CP437: Extended ASCII
  * Code Page 437 from DOS
  * 8-bit, bottom half is ASCII
  * top half filled with line drawing & some math symbols
  * AD1981
* DOS CP866
  * 8-bit, bottom half is ASCII
  * top half filled with line drawing & cyrillic letters
  * AD1981
* DOS CP850
  * 8-bit, bottom half is ASCII
  * top half filled with line drawing & accent letters
  * AD1981
* Windows 1252
  * 8-bit, bottom half is ASCII
  * top half filled with text processor symbols, accented letters & other things
  * AD1985
  * newansi
* Windows 1255
  * 8-bit, bottom half is ASCII
  * top half filled with Hebrew letters
  * AD1985
* ISO 8859
  * Standardize 8-bit code pages
  * 15 defined
  * cannot mix use
  * AD1987
* GBK
  * extension of GB2312
* Unicode
  * encode graphemes rather than glyphs
  * "wide-body ASCII" stretched to 16 bits
  * AD1991
* UCS2
  * 16-bit, bottom bit is ASCII
  * no more conversions
  * byte order dependent (Byte Order Mark BOM recommended at start)
  * AD1991
* UTF-7
  * not ASCII compatible per se
  * transport Unicode across (7-bit) ASCII-only communication channels
  * AD1991
* UTF-8
  * ASCII compatible
  * temporary encoding intended
    * C-style functions with 8-bit encoding support
    * more efficient than UCS2 for ASCII
    * less efficient than UCS2 for all Eastern languages
    * variable-length
  * AD1991
* Han unification
  * 16-bit character set
  * AD1992
  * ![image-20191203011128848](D:\OneDrive\Pictures\Typora\image-20191203011128848.png)
* ![image-20191203011140994](D:\OneDrive\Pictures\Typora\image-20191203011140994.png)
* UTF-16
  * 16-bit, bottom bit is ASCII
  * surrogate pairs create characters not in UCS2
  * byte order dependent (BOM)
  * variable length
  * cannot encode code points beyond 1'114'112
  * AD1997
* UTF-32 (UCS-4)
  * 32-bit, bottom bit is ASCII
  * surrogate pair characters invalid
  * byte order dependent (BOM)
  * fixed length
  * inefficient for any text
  * may not contain code points inaccessible in UTF-16
* UTF-8
  * ASCII compatible
  * no byte order dependency
  * pretty efficient, only Asian languages are less efficient than UTF-16
  * may not contain code points inaccessible in UTF-16
* Encoding unicode
  * storing UTF-16 as UTF-8: CESU-8
  * storing UTF-16 with null bytes as UTF-8: modified UTF-8
  * UTF-EBCDIC
  * GB18030
* Mojibake: decoding different encoding
* Displaying unicode
  * most encodings
    * map each character to a glyph
    * calculate positions for each glyph
    * render glyphs at positions
  * unicode
    * combining diacritics
    * RTL language
    * complex characters
    * ligatures
  * ![image-20191203011608323](D:\OneDrive\Pictures\Typora\image-20191203011608323.png)
* Unicode abuse
  * Zalgo text
  * ![image-20191203011634226](D:\OneDrive\Pictures\Typora\image-20191203011634226.png)
  * ![image-20191203011641931](D:\OneDrive\Pictures\Typora\image-20191203011641931.png)
* C++ & Unicode
  * C++ in 1998
    * ![image-20191203011709980](D:\OneDrive\Pictures\Typora\image-20191203011709980.png)
    * ![image-20191203011713811](D:\OneDrive\Pictures\Typora\image-20191203011713811.png)
  * C++ in 2011
    * ![image-20191203011721514](D:\OneDrive\Pictures\Typora\image-20191203011721514.png)
    * ![image-20191203011727379](D:\OneDrive\Pictures\Typora\image-20191203011727379.png)
  * C++ in 2017
    * ![image-20191203011739075](D:\OneDrive\Pictures\Typora\image-20191203011739075.png)
  * C++ in 2020
    * ![image-20191203011748515](D:\OneDrive\Pictures\Typora\image-20191203011748515.png)
    * ![image-20191203011753611](D:\OneDrive\Pictures\Typora\image-20191203011753611.png)
  * ![image-20191203011807035](D:\OneDrive\Pictures\Typora\image-20191203011807035.png)
* SG16 plans
  * ![image-20191203011824204](D:\OneDrive\Pictures\Typora\image-20191203011824204.png)
  * ![image-20191203011828051](D:\OneDrive\Pictures\Typora\image-20191203011828051.png)



## Design Rationale for `<chrono>`

* ![image-20191203012916769](D:\OneDrive\Pictures\Typora\image-20191203012916769.png)
* ![image-20191203012950964](D:\OneDrive\Pictures\Typora\image-20191203012950964.png)
* ![image-20191203013002892](D:\OneDrive\Pictures\Typora\image-20191203013002892.png)
* ![image-20191203013021524](D:\OneDrive\Pictures\Typora\image-20191203013021524.png)
* ![image-20191203013102660](D:\OneDrive\Pictures\Typora\image-20191203013102660.png)
* ![image-20191203013112916](D:\OneDrive\Pictures\Typora\image-20191203013112916.png)
* ![image-20191203013123740](D:\OneDrive\Pictures\Typora\image-20191203013123740.png)
* ![image-20191203013148788](D:\OneDrive\Pictures\Typora\image-20191203013148788.png)
* ![image-20191203013218037](D:\OneDrive\Pictures\Typora\image-20191203013218037.png)
* ![image-20191203013230948](D:\OneDrive\Pictures\Typora\image-20191203013230948.png)
* ![image-20191203013240780](D:\OneDrive\Pictures\Typora\image-20191203013240780.png)
* ![image-20191203013246812](D:\OneDrive\Pictures\Typora\image-20191203013246812.png)
* ![image-20191203013253204](D:\OneDrive\Pictures\Typora\image-20191203013253204.png)
* ![image-20191203013258389](D:\OneDrive\Pictures\Typora\image-20191203013258389.png)
* 

