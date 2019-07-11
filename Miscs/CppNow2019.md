# CppNow 2019

## A Multithreaded, Transaction-Based, Read/Write Locking Strategy for Containers 
* multi-threaded container

  * read-only: no locking
  * read >> write: RW lock (`std::shared_mutex`)
  * write >> read: related changes...
    * sharding: Divide the set of elements into individual shards such that the members of each element’s related group are also in the shard.
      * good performance
      * complex, only if data is amendable to sharding
    * per-container mutex
      * easy
      * not scale
    * per-element mutex
      * deadlocking!
    * strict timestamp ordering (STO)

* STO

  * Timestamp

    * monotonically increasing value
    * $TSV_1 < TSV_2$, Transaction 1 is older than transaction 2

  * younger transactions always wait

  * older transactions never wait, rollback and try again

  * serializable, deadlock-free

  * ![1560734785861](D:\OneDrive\Pictures\Typora\1560734785861.png)

  * ![1560734879396](D:\OneDrive\Pictures\Typora\1560734879396.png)

  * ![1560735002408](D:\OneDrive\Pictures\Typora\1560735002408.png)

  * ```c++
    class stopwatch
    {
        public:
            ~stopwatch() = default;
            stopwatch();
            stopwatch(stopwatch&&) = default;
            stopwatch(stopwatch const&) = default;
            stopwatch& operator =(stopwatch&&) = default;
            stopwatch& operator =(stopwatch const&) = default;
            template<class T> T seconds_elapsed() const;
            template<class T> T milliseconds_elapsed() const;
            void start();
            void stop();
        private:
    	    ...
    };
    
    class lockable_item
    {
    	public:
            lockable_item();
            item_id_type id() const noexcept;
            tsv_type last_tsv() const noexcept;
        private:
            friend class transaction;
            using atomic_tx_pointer = std::atomic<transaction*>;
            using atomic_item_id = std::atomic<item_id_type>;
            atomic_tx_pointer mp_owning_tx; //- Pointer to transaction object that owns this object
            tsv_type m_last_tsv; //- Timestamp of last owner
            item_id_type m_item_id; //- For debugging/tracking/logging
            static atomic_item_id sm_item_id_generator;
    };
    
    class transaction
    {
        public:
            ~transaction();
            transaction(int log_level, FILE* fp=nullptr);
            tx_id_type id() const noexcept;
            tsv_type tsv() const noexcept;
            void begin();
            void commit();
            void rollback();
            bool acquire(lockable_item& item);
        private:
            using item_ptr_list = std::vector<lockable_item*>;
            using mutex = std::mutex;
            using tx_lock = std::unique_lock<std::mutex>;
            using cond_var = std::condition_variable;
            using atomic_tsv = std::atomic<tsv_type>;
            using atomic_tx_id = std::atomic<tx_id_type>;
            tx_id_type m_tx_id;
            tsv_type m_tx_tsv;
            item_ptr_list m_item_ptrs;
            mutex m_mutex;
            cond_var m_cond;
            FILE* m_fp;
            int m_log_level;
            static atomic_tsv sm_tsv_generator;
            static atomic_tx_id sm_tx_id_generator;
    	
        	void log_begin() const;
            void log_commit() const;
            void log_rollback() const;
            void log_acquisition_success(lockable_item const& item) const;
            void log_acquisition_failure(lockable_item const& item) const;
            void log_acquisition_same(lockable_item const& item) const;
            void log_acquisition_waiting(lockable_item const& item, transaction* p_curr_tx) const;
            ...
               
    };
    
    bool
    transaction::acquire(lockable_item& item)
    {
        while (true)
        {
            transaction* p_curr_tx = nullptr;
            if (item.mp_owning_tx.compare_exchange_strong(p_curr_tx, this))
            {
    	        m_item_ptrs.push_back(&item);
                if (m_tx_tsv > item.m_last_tsv)
                {
                    log_acquisition_success(item);
                    item.m_last_tsv = m_tx_tsv;
                    return true;
                }
    			else
                {
                    log_acquisition_failure(item);
                    return false;
                }
            }
    		else
            {
                if (p_curr_tx == this)
                {
                    log_acquisition_same(item);
                    return true;
                }
                else
                {
                    log_acquisition_waiting(item, p_curr_tx);
                    tx_lock lock(p_curr_tx->m_mutex);
                    while (item.mp_owning_tx.load() == p_curr_tx)
                    {
                        if (p_curr_tx->m_tx_tsv > m_tx_tsv)
                        {
                            log_acquisition_failure(item);
                            return false;
                        }
                        p_curr_tx->m_cond.wait(lock);
                    }
                }
            }
    ```

  * ![1560735295024](D:\OneDrive\Pictures\Typora\1560735295024.png)

* [StrictTO](<https://users.cs.fiu.edu/~prabakar/database/cmaps/mod_04/StrictTO.pdf>)

* [Concurrency with Timestamp](<http://www.cs.ucy.ac.cy/~dzeina/courses/epl446/lectures/16.pdf>)



## Beyond C++17

* Constraints and concepts
  * ![1560904352089](D:\OneDrive\Pictures\Typora\1560904352089.png)
  * ![1560904816905](D:\OneDrive\Pictures\Typora\1560904816905.png)
  * ![1560904866544](D:\OneDrive\Pictures\Typora\1560904866544.png)
  * ![1560904891041](D:\OneDrive\Pictures\Typora\1560904891041.png)
  * ![1560904923281](D:\OneDrive\Pictures\Typora\1560904923281.png)
  * ![1560904941694](D:\OneDrive\Pictures\Typora\1560904941694.png)
  * ![1560904989555](D:\OneDrive\Pictures\Typora\1560904989555.png)
  * ![1560905002606](D:\OneDrive\Pictures\Typora\1560905002606.png)
  * ![1560905012916](D:\OneDrive\Pictures\Typora\1560905012916.png)
  * ![1560905022597](D:\OneDrive\Pictures\Typora\1560905022597.png)
  * ![1560905031222](D:\OneDrive\Pictures\Typora\1560905031222.png)
  * ![1560905041897](D:\OneDrive\Pictures\Typora\1560905041897.png)
* Consistent comparison
  * ![1560904412467](D:\OneDrive\Pictures\Typora\1560904412467.png)
  * ![1560904443438](D:\OneDrive\Pictures\Typora\1560904443438.png)
  * ![1560905250196](D:\OneDrive\Pictures\Typora\1560905250196.png)
  * ![1560905266374](D:\OneDrive\Pictures\Typora\1560905266374.png)
  * ![1560905316635](D:\OneDrive\Pictures\Typora\1560905316635.png)
  * ![1560905328058](D:\OneDrive\Pictures\Typora\1560905328058.png)
  * ![1560905765623](D:\OneDrive\Pictures\Typora\1560905765623.png)
  * ![1560905806971](D:\OneDrive\Pictures\Typora\1560905806971.png)
* Extending `<chrono>`
  * ![1560904730934](D:\OneDrive\Pictures\Typora\1560904730934.png)
  * ![1560904744725](D:\OneDrive\Pictures\Typora\1560904744725.png)
* `<span>`
  * ![1560904767484](D:\OneDrive\Pictures\Typora\1560904767484.png)
  * remove comparison => `Regular`
  * ![1560909431712](D:\OneDrive\Pictures\Typora\1560909431712.png)
* `<ranges>`
  * ![1560905071252](D:\OneDrive\Pictures\Typora\1560905071252.png)
  * ![1560905081968](D:\OneDrive\Pictures\Typora\1560905081968.png)
  * ![1560905094021](D:\OneDrive\Pictures\Typora\1560905094021.png)
  * ![1560905108338](D:\OneDrive\Pictures\Typora\1560905108338.png)
  * ![1560905119749](D:\OneDrive\Pictures\Typora\1560905119749.png)
  * ![1560905128962](D:\OneDrive\Pictures\Typora\1560905128962.png)
  * ![1560905143501](D:\OneDrive\Pictures\Typora\1560905143501.png)
  * ![1560905161003](D:\OneDrive\Pictures\Typora\1560905161003.png)
  * ![1560905169624](D:\OneDrive\Pictures\Typora\1560905169624.png)
  * ![1560905179160](D:\OneDrive\Pictures\Typora\1560905179160.png)
* Contract
  * ![1560905831914](D:\OneDrive\Pictures\Typora\1560905831914.png)
  * ![1560905907787](D:\OneDrive\Pictures\Typora\1560905907787.png)
  * ![1560905918306](D:\OneDrive\Pictures\Typora\1560905918306.png)
  * ![1560905935011](D:\OneDrive\Pictures\Typora\1560905935011.png)
  * ![1560905952500](D:\OneDrive\Pictures\Typora\1560905952500.png)
  * ![1560905983264](D:\OneDrive\Pictures\Typora\1560905983264.png)
  * ![1560906000083](D:\OneDrive\Pictures\Typora\1560906000083.png)
  * ![1560906030022](D:\OneDrive\Pictures\Typora\1560906030022.png)
  * ![1560906036290](D:\OneDrive\Pictures\Typora\1560906036290.png)
  * ![1560906051055](D:\OneDrive\Pictures\Typora\1560906051055.png)
  * ![1560906085216](D:\OneDrive\Pictures\Typora\1560906085216.png)
  * ![1560906113169](D:\OneDrive\Pictures\Typora\1560906113169.png)
  * ![1560906130420](D:\OneDrive\Pictures\Typora\1560906130420.png)
  * ![1560906148255](D:\OneDrive\Pictures\Typora\1560906148255.png)
  * ![1560906183286](D:\OneDrive\Pictures\Typora\1560906183286.png)
* Module
  * ![1560906209820](D:\OneDrive\Pictures\Typora\1560906209820.png)
  * ![1560906226363](D:\OneDrive\Pictures\Typora\1560906226363.png)
  * ![1560906397247](D:\OneDrive\Pictures\Typora\1560906397247.png)
  * ![1560906413996](D:\OneDrive\Pictures\Typora\1560906413996.png)
  * ![1560906446808](D:\OneDrive\Pictures\Typora\1560906446808.png)
  * ![1560906486306](D:\OneDrive\Pictures\Typora\1560906486306.png)
  * ![1560906511350](D:\OneDrive\Pictures\Typora\1560906511350.png)
  * ![1560906544472](D:\OneDrive\Pictures\Typora\1560906544472.png)
  * ![1560906598606](D:\OneDrive\Pictures\Typora\1560906598606.png)
  * ![1560906615803](D:\OneDrive\Pictures\Typora\1560906615803.png)
  * ![1560906640907](D:\OneDrive\Pictures\Typora\1560906640907.png)
  * ![1560906696002](D:\OneDrive\Pictures\Typora\1560906696002.png)
  * ![1560906749545](D:\OneDrive\Pictures\Typora\1560906749545.png)
  * ![1560906761703](D:\OneDrive\Pictures\Typora\1560906761703.png)
  * ![1560906786681](D:\OneDrive\Pictures\Typora\1560906786681.png)
* Coroutine
  * ![1560906817486](D:\OneDrive\Pictures\Typora\1560906817486.png)
  * ![1560906840816](D:\OneDrive\Pictures\Typora\1560906840816.png)
  * ![1560906852839](D:\OneDrive\Pictures\Typora\1560906852839.png)
  * ![1560906867587](D:\OneDrive\Pictures\Typora\1560906867587.png)
  * ![1560906874990](D:\OneDrive\Pictures\Typora\1560906874990.png)
  * ![1560906900798](D:\OneDrive\Pictures\Typora\1560906900798.png)
  * ![1560907032912](D:\OneDrive\Pictures\Typora\1560907032912.png)
  * ![1560907044143](D:\OneDrive\Pictures\Typora\1560907044143.png)
* Class type as non-type template parameter
  * ![1560907223550](D:\OneDrive\Pictures\Typora\1560907223550.png)
  * ![1560907239968](D:\OneDrive\Pictures\Typora\1560907239968.png)
  * ![1560907270602](D:\OneDrive\Pictures\Typora\1560907270602.png)
* User-defined aggregate-init
  * ![1560907349403](D:\OneDrive\Pictures\Typora\1560907349403.png)
  * ![1560907460161](D:\OneDrive\Pictures\Typora\1560907460161.png)
  * ![1560907472776](D:\OneDrive\Pictures\Typora\1560907472776.png)
* Constexpr
  * virtual function
    * ![1560907505661](D:\OneDrive\Pictures\Typora\1560907505661.png)
  * union
    * ![1560907534075](D:\OneDrive\Pictures\Typora\1560907534075.png)
  * try-catch
    * ![1560907550182](D:\OneDrive\Pictures\Typora\1560907550182.png)
  * polymorphic
    * ![1560907591369](D:\OneDrive\Pictures\Typora\1560907591369.png)
  * `pointer_traits<T>`
    * ![1560907648339](D:\OneDrive\Pictures\Typora\1560907648339.png)
    * [why allocator can be `constexpr`](<http://open-std.org/JTC1/SC22/WG21/docs/papers/2018/p0784r1.html>)
  * other standard lib
    * ![1560907705744](D:\OneDrive\Pictures\Typora\1560907705744.png)
    * ![1560907717841](D:\OneDrive\Pictures\Typora\1560907717841.png)
    * ![1560907731588](D:\OneDrive\Pictures\Typora\1560907731588.png)
  * `consteval`
    * ![1560908038600](D:\OneDrive\Pictures\Typora\1560908038600.png)
* `explicit(bool)`
  * ![1560908097067](D:\OneDrive\Pictures\Typora\1560908097067.png)
* Required 2's complement
  * ![1560908123849](D:\OneDrive\Pictures\Typora\1560908123849.png)
  * ![1560908132378](D:\OneDrive\Pictures\Typora\1560908132378.png)
* `char8_t`
  * ![1560908160564](D:\OneDrive\Pictures\Typora\1560908160564.png)
  * ![1560908184058](D:\OneDrive\Pictures\Typora\1560908184058.png)
  * ![1560908198321](D:\OneDrive\Pictures\Typora\1560908198321.png)
  * ![1560908208585](D:\OneDrive\Pictures\Typora\1560908208585.png)
  * ![1560908217661](D:\OneDrive\Pictures\Typora\1560908217661.png)
  * ![1560908256229](D:\OneDrive\Pictures\Typora\1560908256229.png)
  * ![1560908276773](D:\OneDrive\Pictures\Typora\1560908276773.png)
* Nested inline namespaces
  * ![1560908322061](D:\OneDrive\Pictures\Typora\1560908322061.png)
* Extend structure-binding
  * ![1560909190107](D:\OneDrive\Pictures\Typora\1560909190107.png)
  * ![1560909196393](D:\OneDrive\Pictures\Typora\1560909196393.png)
* Deprecate `[=]` for `this`
* `ssize_t`
  * ![1560909505931](D:\OneDrive\Pictures\Typora\1560909505931.png)
  * ![1560909515271](D:\OneDrive\Pictures\Typora\1560909515271.png)
* Add `contains`
  * ![1560909557348](D:\OneDrive\Pictures\Typora\1560909557348.png)
* Hash
  * Heterogeneous lookup
    * ![1560909596336](D:\OneDrive\Pictures\Typora\1560909596336.png)
  * Pre-calculated hash
    * ![1560909675520](D:\OneDrive\Pictures\Typora\1560909675520.png)
* Consistent container erasure
* `std::execution::unsequenced_policy`
* `shift_left` / `shift_right`
* `remove` returns number of removed
* Integral power-of-2 functions
* Bit-casting
  * ![1560910000087](D:\OneDrive\Pictures\Typora\1560910000087.png)
* `atomic_compare_exchange_strong`: memory representation -> value representation (no padding)
* `atomic_ref<T>`
  * ![1560910113247](D:\OneDrive\Pictures\Typora\1560910113247.png)
* Fix default constructors
* Sane variant constructor
  * ![1560910192925](D:\OneDrive\Pictures\Typora\1560910192925.png)
* `visit<R>`
  * ![1560910254210](D:\OneDrive\Pictures\Typora\1560910254210.png)
* `assume_aligned`
  * ![1560910285048](D:\OneDrive\Pictures\Typora\1560910285048.png)
  * ![1560910303056](D:\OneDrive\Pictures\Typora\1560910303056.png)
  * ![1560910315134](D:\OneDrive\Pictures\Typora\1560910315134.png)
* smart pointer default initialization
* `operator>>(basic_istream&, CharT*) ` replaced by boundary array
* `bind_front`
  * ![1560910413724](D:\OneDrive\Pictures\Typora\1560910413724.png)
* `uses_allocator<T, Alloc>`
  * ![1560910608245](D:\OneDrive\Pictures\Typora\1560910608245.png)
  * ![1560910642323](D:\OneDrive\Pictures\Typora\1560910642323.png)
  * ![1560910654351](D:\OneDrive\Pictures\Typora\1560910654351.png)
  * ![1560910667616](D:\OneDrive\Pictures\Typora\1560910667616.png)
* `polymorphic_allocator<>`
  * ![1560910741560](D:\OneDrive\Pictures\Typora\1560910741560.png)
* interpolation for numbers and pointers (`midpoint`, `lerp`)



## Better CTAD for Cpp20

* deduction candidate overload set
  * from constructor
    * primary template only
  * from deduction guides
  * the default candidate
    * `C()`, `C(C)`
  * the copy deduction candidate
* Add new
  * for aggregates
  * for alias templates
    * substitute back partial type
  * for inherited constructors
  * from incomplete template argument list? no, breaking change



## The Cpp Reflection TS

* `type_traits`, Boost.FunctionTypes
* `reflexpr(<syntax>)`
  * evaluates to a unnamed type
  * ![1561127525024](D:\OneDrive\Pictures\Typora\1561127525024.png)
  * ![1561127674849](D:\OneDrive\Pictures\Typora\1561127674849.png)
  * ![1561127685106](D:\OneDrive\Pictures\Typora\1561127685106.png)
  * ![1561127696042](D:\OneDrive\Pictures\Typora\1561127696042.png)
  * ![1561127712452](D:\OneDrive\Pictures\Typora\1561127712452.png)
  * ![1561127741288](D:\OneDrive\Pictures\Typora\1561127741288.png)
  * ![1561127747302](D:\OneDrive\Pictures\Typora\1561127747302.png)
  * ![1561127797490](D:\OneDrive\Pictures\Typora\1561127797490.png)
  * Why not metaclass...



## An Alternative Smart Pointer Hierarchy

* ![1561129143157](D:\OneDrive\Pictures\Typora\1561129143157.png)
* ![1561129187929](D:\OneDrive\Pictures\Typora\1561129187929.png)
* ![1561129195422](D:\OneDrive\Pictures\Typora\1561129195422.png)
* ![1561129203592](D:\OneDrive\Pictures\Typora\1561129203592.png)
* ![1561129210896](D:\OneDrive\Pictures\Typora\1561129210896.png)
* ![1561129234337](D:\OneDrive\Pictures\Typora\1561129234337.png)
* ![1561129250434](D:\OneDrive\Pictures\Typora\1561129250434.png)
* ![1561129265871](D:\OneDrive\Pictures\Typora\1561129265871.png)
* Windows-like Rust-style resource management?
* `delete_ptr<T>`
* `owned<T>`
* ![1561129531879](D:\OneDrive\Pictures\Typora\1561129531879.png)



## The ABI Challenge

* ![1561135209463](D:\OneDrive\Pictures\Typora\1561135209463.png)
* ![1561135218196](D:\OneDrive\Pictures\Typora\1561135218196.png)
* ![1561135228758](D:\OneDrive\Pictures\Typora\1561135228758.png)
* ![1561135286520](D:\OneDrive\Pictures\Typora\1561135286520.png)
* ![1561135388408](D:\OneDrive\Pictures\Typora\1561135388408.png)



## Trivially Relocatable

* ![1561135605874](D:\OneDrive\Pictures\Typora\1561135605874.png)
* ![1561135726760](D:\OneDrive\Pictures\Typora\1561135726760.png)
* ![1561135869753](D:\OneDrive\Pictures\Typora\1561135869753.png)
* ![1561135884293](D:\OneDrive\Pictures\Typora\1561135884293.png)
* ![1561135906612](D:\OneDrive\Pictures\Typora\1561135906612.png)
* ![1561135963992](D:\OneDrive\Pictures\Typora\1561135963992.png)
* move-destroy -> `memcpy`
* ![1561136188440](D:\OneDrive\Pictures\Typora\1561136188440.png)
* ![1561136273700](D:\OneDrive\Pictures\Typora\1561136273700.png)
* ![1561136282010](D:\OneDrive\Pictures\Typora\1561136282010.png)
* ![1561136295719](D:\OneDrive\Pictures\Typora\1561136295719.png)
* ![1561136319694](D:\OneDrive\Pictures\Typora\1561136319694.png)
* ![1561136473534](D:\OneDrive\Pictures\Typora\1561136473534.png)
* ![1561136487814](D:\OneDrive\Pictures\Typora\1561136487814.png)
* ![1561136535190](D:\OneDrive\Pictures\Typora\1561136535190.png)
* ![1561136592631](D:\OneDrive\Pictures\Typora\1561136592631.png)
* ![1561136622792](D:\OneDrive\Pictures\Typora\1561136622792.png)
* ![1561136638234](D:\OneDrive\Pictures\Typora\1561136638234.png)
* ![1561136678409](D:\OneDrive\Pictures\Typora\1561136678409.png)
* ![1561136697633](D:\OneDrive\Pictures\Typora\1561136697633.png)
* ![1561136720955](D:\OneDrive\Pictures\Typora\1561136720955.png)



## Compile Time Regular Expression with Deterministic Finite Automaton

- store ast in compile-time: type-based expression
  - expression templates
  - tuple-like empty types
- parsing with LL(1)
  - ![1561111946988](D:\OneDrive\Pictures\Typora\1561111946988.png)
  - stack -> typelist
  - LL(1) Table -> function deduction
  - input string -> `fixed_string`
  - semantic action
- matching with DFA
  - ![1561112389236](D:\OneDrive\Pictures\Typora\1561112389236.png)
  - states -> `int`
  - symbols -> `char32_t`
  - transition functions -> `set<tuple<int, int, char32_t>>`
  - start state -> `int(0)`
  - final states -> `set<int>`
- ![1561112609535](D:\OneDrive\Pictures\Typora\1561112609535.png)
- ![1561112677784](D:\OneDrive\Pictures\Typora\1561112677784.png)
- Note: very detailed implementation of CTRE. Worth reading for advanced TMP.



## Generic binary tree why grow your own

- Compressed sparse row graph
- ![1561124812385](D:\OneDrive\Pictures\Typora\1561124812385.png)
- ![1561124825835](D:\OneDrive\Pictures\Typora\1561124825835.png)
- `BifurcateCoodinate`
- ![1561124935294](D:\OneDrive\Pictures\Typora\1561124935294.png)
- ![1561124961162](D:\OneDrive\Pictures\Typora\1561124961162.png)
- ![1561124973029](D:\OneDrive\Pictures\Typora\1561124973029.png)
- binary tree as a graph
- [implementation](<https://github.com/boostorg/graph/pull/139>)



## Parametric Expression A Proposed Language Feature

- crazy idea...

- ```c++
  // Specialize storage for non-empty types
  template <typename K, typename V>
  struct ebo<K, V, false> {
      constexpr ebo() : data_() { }
      template <typename T>
      explicit constexpr ebo(T&& t)
  	    : data_(static_cast<T&&>(t))
      { }
      
      V data_;
      // this gets instantiated for every K, V
      using get(using this self) = return (self.data_);
  };
  
  using init_tuple(using tup) {
      std::tuple xs = tup;
      return xs;
  }
  
  using make_tuples(using ...tups)
  	= std::tuple{init_tuple(tups)...};
  
  struct guard {
      using operator&&(this self, using [] LAZY_X) {
      if (!self.is_stopped) {
          decltype(auto) x = LAZY_X();
          std::cout << x << '\n';
          if (std::string_view(x) == std::string_view("stop"))
  	        self.is_stopped = true;
          }
          return self;
      }
      bool is_stopped = false;
  };
  int main() {
      auto g = guard{} && "pass1"
      && "pass2"
      && "pass3"
      && "stop"
      && "this is not printed";
  }
  
  template <typename X>
  decltype(auto) id(X&& x)
  	noexcept(noexcept(std::forward<X>(x)))
  	-> decltype(std::forward<X>(x)) {
  	return std::forward<X>(x);
  }
  
  using id(using x) = x;
  
  using constexpr_if(constexpr auto cond,
                      using auto x,
                      using auto y) =
  	constexpr_if_<cond>::apply(x, y);
  
  auto x = constexpr_if(true, int{42}, std::make_unique<int>(42));
  
  using to_pack(...x)~ = x; // tilde operator for pack expansion
  ```

- [d1221](https://github.com/ricejasonf/parametric_expressions/blob/master/d1221.md)

- [p0847-deducing `this`](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2019/p0847r2.html)

- [lazy-forwarding](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2018/p0927r0.pdf)



## Higher-order functions and `function_ref`

* HoF implementations![1561125994282](D:\OneDrive\Pictures\Typora\1561125994282.png)![1561126002556](D:\OneDrive\Pictures\Typora\1561126002556.png)![1561126052214](D:\OneDrive\Pictures\Typora\1561126052214.png)![1561126098982](D:\OneDrive\Pictures\Typora\1561126098982.png)![1561126152871](D:\OneDrive\Pictures\Typora\1561126152871.png)![1561126436550](D:\OneDrive\Pictures\Typora\1561126436550.png)



## Pattern Matching Me If You Can

- form
  - Statement form
  - Expression form
  - Declaration form (de-structure)
- pattern
  - wildcard
  - identifier
  - literal
  - ^primary-expression
    - `^within`
  - parenthesized
  - structure-binding
    - designator
  - alternative 
    - `<type> pattern` / `<constant-expression> pattern` / `<auto> pattern` / `<Concept> pattern`
    - any types
    - variant types
    - polymorphic types
  - binding (`identifier @ pattern`)
  - dereference pattern (`*pattern`)
  - Extractor pattern (`constant-expression !/? pattern`)
    - ![1561135094839](D:\OneDrive\Pictures\Typora\1561135094839.png)



## Exceptions Demystified

- `throw`
  - ![1561136894101](D:\OneDrive\Pictures\Typora\1561136894101.png)
- ![1561136924533](D:\OneDrive\Pictures\Typora\1561136924533.png)
- ![1561136945137](D:\OneDrive\Pictures\Typora\1561136945137.png)
- ![1561136956663](D:\OneDrive\Pictures\Typora\1561136956663.png)
- ![1561136971400](D:\OneDrive\Pictures\Typora\1561136971400.png)
- ![1561136980033](D:\OneDrive\Pictures\Typora\1561136980033.png)
- ![1561136989809](D:\OneDrive\Pictures\Typora\1561136989809.png)
- ![1561137003247](D:\OneDrive\Pictures\Typora\1561137003247.png)
- ![1561137009545](D:\OneDrive\Pictures\Typora\1561137009545.png)
- ![1561137059983](D:\OneDrive\Pictures\Typora\1561137059983.png)
- Deterministic Exceptions
  - ![1561137092426](D:\OneDrive\Pictures\Typora\1561137092426.png)
  - ![1561137101478](D:\OneDrive\Pictures\Typora\1561137101478.png)
  - ![1561137108524](D:\OneDrive\Pictures\Typora\1561137108524.png)
  - ![1561137117286](D:\OneDrive\Pictures\Typora\1561137117286.png)
  - ![1561137123396](D:\OneDrive\Pictures\Typora\1561137123396.png)
- ![1561137134621](D:\OneDrive\Pictures\Typora\1561137134621.png)



## The Rough Road Towards Upgrading to Cpp Modules

* ![1561137549591](D:\OneDrive\Pictures\Typora\1561137549591.png)
* ![1561137637751](D:\OneDrive\Pictures\Typora\1561137637751.png)
* ![1561137656111](D:\OneDrive\Pictures\Typora\1561137656111.png)
* ![1561137740901](D:\OneDrive\Pictures\Typora\1561137740901.png)
* ![1561137784200](D:\OneDrive\Pictures\Typora\1561137784200.png)
* ![1561137827394](D:\OneDrive\Pictures\Typora\1561137827394.png)
  * ![1561137848743](D:\OneDrive\Pictures\Typora\1561137848743.png)
  * ![1561137888730](D:\OneDrive\Pictures\Typora\1561137888730.png)
  * 
* 













## Miscs

* Dependency Injection a 25 dollar Term for a 5 cent Concept
  * flexible / scalable / testable
  * KISS / STUPID / SOLID 
    * Single Responsibility Principle
    * constructor injection
* Linear Algebra for the Standard Cpp Library
  - detailed implementation of different linear types
* Audio in standard cpp (potential new lib, SG13)
* A Performance Analysis of a Simple Trading System
  * ![1561128049181](D:\OneDrive\Pictures\Typora\1561128049181.png)
  * ![1561128160817](D:\OneDrive\Pictures\Typora\1561128160817.png)
  * ![1561128217469](D:\OneDrive\Pictures\Typora\1561128217469.png)
  * ![1561128303516](D:\OneDrive\Pictures\Typora\1561128303516.png)
  * ![1561128333817](D:\OneDrive\Pictures\Typora\1561128333817.png)
* `out_ptr_t<Smart, Pointer, Args...>` / `inout_ptr_t<Smart, Pointer, Args...>`
  * temporary gain resources from smart pointer to C-API
  * ![1561138811818](D:\OneDrive\Pictures\Typora\1561138811818.png)
  * `CComPtr`, `retain_ptr`, `ComPtrRef`
* `index_sequence` unpacking
  * ![1561139072423](D:\OneDrive\Pictures\Typora\1561139072423.png)
  * ![1561139088075](D:\OneDrive\Pictures\Typora\1561139088075.png)
  * ![1561139044863](D:\OneDrive\Pictures\Typora\1561139044863.png)
  * ![1561139098737](D:\OneDrive\Pictures\Typora\1561139098737.png)
  * ![1561139132991](D:\OneDrive\Pictures\Typora\1561139132991.png)
  * ![1561139143253](D:\OneDrive\Pictures\Typora\1561139143253.png)
  * ![1561139151729](D:\OneDrive\Pictures\Typora\1561139151729.png)
* Rule of DesDeMovA
  * ![1561139218343](D:\OneDrive\Pictures\Typora\1561139218343.png)
* Template Template
  * ![1561139332427](D:\OneDrive\Pictures\Typora\1561139332427.png)
  * ![1561139342064](D:\OneDrive\Pictures\Typora\1561139342064.png)
  * ![1561139353817](D:\OneDrive\Pictures\Typora\1561139353817.png)
  * 

