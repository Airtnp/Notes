

# CppCon2018

## Writing Standard Library Compliant Alg

```c++
template<typename T, typename A = std::allocator<T>>
class graph_node_allocator
{
protected:
   explicit graph_node_allocator(const A& allocator);

   graph_node_allocator(const graph_node_allocator&) = delete;
   graph_node_allocator(graph_node_allocator&& src) noexcept;

   graph_node_allocator& operator=(const graph_node_allocator&) = delete;
   graph_node_allocator& operator=(graph_node_allocator&&) = delete;

   ~graph_node_allocator();
   
   A m_allocator;
   T* m_data = nullptr;
};

template<typename T, typename A>
graph_node_allocator<T, A>::graph_node_allocator(const A& allocator)
   : m_allocator(allocator)
{
   m_data = m_allocator.allocate(1);
}
template<typename T, typename A>
graph_node_allocator<T, A>::graph_node_allocator(graph_node_allocator&& src) noexcept
   : m_allocator(std::move(src.m_allocator))
   , m_data(std::exchange(src.m_data, nullptr))
{
}
template<typename T, typename A>
graph_node_allocator<T, A>::~graph_node_allocator()
{
   m_allocator.deallocate(m_data, 1);
   m_data = nullptr;
}


template<typename T, typename A = std::allocator<T>>
class graph_node : private graph_node_allocator<T, A>
{
private:
   using adjacency_list_type = std::set<size_t>;
   friend class directed_graph<T, A>;

   adjacency_list_type& get_adjacent_node_indices();
   const adjacency_list_type& get_adjacent_node_indices() const;

   // T* m_data = nullptr;
   // A m_allocator;
   adjacency_list_type m_adjacentNodeIndices;
public:
   explicit graph_node(const T& t) : graph_node<T, A>(t, A()) {}
    graph_node(const T& t, const A& allocator) : m_allocator(allocator) {
        // If m_data is properly allocated, but the constructor of T throws an exception, then the destructor of graph_node will never get called and we leak m_data.
        // Solution: allocation in base class + construction in derived class
        // m_data = m_allocator.allocate(1);
        new (this->m_data) T(t);
    }

   explicit graph_node(T&& t);
    graph_node(T&& t, const A& allocator) {
        new (this->m_data) T{std::move(t)};
    }
    
    ~graph_node() {
        if (m_data) {
            m_data->~T();
            // m_allocator.deallocate(m_data, 1);
            // m_data = nullptr;
        }
    }

   T& get() noexcept;
   const T& get() const noexcept;

   bool operator==(const graph_node& rhs) const;
   bool operator!=(const graph_node& rhs) const;

    void swap(graph_node& other_node) noexcept {
        using std::swap;
        swap(m_data, other_node.m_data);
        swap(m_adjacentNodeIndices, other_node.m_adjacentNodeIndices);
    }
};

template<typename T, typename A = std::allocator<T>>
class directed_graph
{
private:
   using nodes_container_type = std::vector<details::graph_node<T>>;

   nodes_container_type m_nodes;

    typename nodes_container_type::iterator find(const T& node_value) {
        return std::find_if(std::begin(m_nodes), std::end(m_nodes),
	      [&node_value](const auto& node) { return node.get() == node_value; });
    }
    typename nodes_container_type::const_iterator find(const T& node_value) const {
        return const_cast<directed_graph<T>*>(this)->find(node_value);
    }

    void remove_all_links_to(typename nodes_container_type::const_iterator node) {
          const size_t node_index = std::distance(std::cbegin(m_nodes), node);
          for (auto&& node : m_nodes) { // Iterate over all adjacency lists.
          auto& adjacencyIndices = node.get_adjacent_node_indices();
          // First, remove references to the to-be-deleted node.
          adjacencyIndices.erase(node_index);
          // Second, modify all remaining adjacency indices to account for the removal of a node.
          for (auto iter = std::begin(adjacencyIndices); iter != std::end(adjacencyIndices);) {
             auto index = *iter;
             if (index > node_index) {
                auto hint = iter; ++hint;
                iter = adjacencyIndices.erase(iter);
                adjacencyIndices.insert(hint, index - 1);
             } else {
                ++iter;
             }
          }
       }

    }

   std::set<T> get_adjacent_node_values(
       const typename details::graph_node<T>::adjacency_list_type& indices) const {
       std::set<T> values;
       for (auto&& index: indices) {
           values.insert(m_nodes[index].get());
       }
       return values;
   }
public:
    using allocator_type = A;
    directed_graph() noexcept(noexcept(A())) = default;
    explicit directed_graph(const A& allocator) noexcept;
    directed_graph(std::initializer_list<T> init, const A& allocator = A());
    template<typename Iter>
    directed_graph(Iter first, Iter last, const A& allocator = A());
    allocator_type get_allocator() const;
private:
    using nodes_container_type = std::vector<details::graph_node<T, A>>;
    A m_allocator;
    std::set<T, std::less<>, A> get_adjacent_node_values(
        const typename details::graph_node<T, A>::adjacency_list_type& indices) const;
public:    

    template<typename T>
    std::pair<typename directed_graph<T>::iterator, bool> directed_graph<T>::insert(
       T&& node_value)
    {
       auto iter = find(node_value);
       if (iter != std::end(m_nodes)) { // Value is already in the graph, return false.
          return std::make_pair(iterator(iter, this), false);
       }
       m_nodes.emplace_back(std::move(node_value));
       // Value successfully added to the graph, return true.
       return std::make_pair(iterator(--std::end(m_nodes), this), true);
    }
    template<typename T>
    std::pair<typename directed_graph<T>::iterator, bool> directed_graph<T>::insert(
       const T& node_value)
    {
       T copy(node_value);
       return insert(std::move(copy));
    }

    
    

    template<typename T>
    typename directed_graph<T>::iterator directed_graph<T>::erase(const_iterator pos)
    {
       if (pos.m_nodeIterator == std::end(m_nodes)) {
          return iterator(std::end(m_nodes), this);
       }
       remove_all_links_to(pos.m_nodeIterator);
       return iterator(m_nodes.erase(pos.m_nodeIterator), this);
    }


    template<typename T>
    typename directed_graph<T>::iterator directed_graph<T>::erase(
       const_iterator first, const_iterator last)
    {
       for (auto iter = first; iter != last; ++iter) {
          if (iter.m_nodeIterator != std::end(m_nodes)) {
             remove_all_links_to(iter.m_nodeIterator);
          }
       }
       return iterator(m_nodes.erase(first.m_nodeIterator, last.m_nodeIterator), this);
    }

   // Returns true if the edge was successfully created, false otherwise.
   bool insert_edge(const T& from_node_value, const T& to_node_value) {
   	   const auto from = find(from_node_value);
       const auto to = find(to_node_value);
       if (from == std::end(m_nodes) || to == std::end(m_nodes)) {
          return false;
       }

       const size_t to_index = std::distance(std::begin(m_nodes), to);
       return from->get_adjacent_node_indices().insert(to_index).second;
   }

   // Returns true of the given edge was erased, false otherwise.
    bool erase_edge(const T& from_node_value, const T& to_node_value) {
       const auto from = find(from_node_value);
       const auto to = find(to_node_value);
       if (from == std::end(m_nodes) || to == std::end(m_nodes)) {
          return false; // nothing to erase
       }

       const size_t to_index = std::distance(std::begin(m_nodes), to);
       from->get_adjacent_node_indices().erase(to_index);
       return true;
    }
   void clear() noexcept;

   // T& operator[](size_t index);
   // const T& operator[](size_t index) const;
    
    reference operator[](size_type index);
    const_reference operator[](size_type index) const;

    reference at(size_type index);
    const_reference at(size_type index) const;

    iterator begin() noexcept;
    iterator end() noexcept;

    const_iterator begin() const noexcept;
    const_iterator end() const noexcept;

    const_iterator cbegin() const noexcept;
    const_iterator cend() const noexcept;
    
    reverse_iterator rbegin() noexcept;
    reverse_iterator rend() noexcept;

    const_reverse_iterator rbegin() const noexcept;
    const_reverse_iterator rend() const noexcept;

    const_reverse_iterator crbegin() const noexcept;
    const_reverse_iterator crend() const noexcept;

    using iterator_adjacent_nodes =
       adjacent_nodes_iterator<directed_graph>;
    using const_iterator_adjacent_nodes =
       const_adjacent_nodes_iterator<directed_graph>;
    
    // Return iterators to the list of adjacent nodes for the given node.
    // Return a default constructed iterator as end iterator if the value is not found.
    iterator_adjacent_nodes begin(const T& node_value) noexcept;
    iterator_adjacent_nodes end(const T& node_value) noexcept;

    const_iterator_adjacent_nodes begin(const T& node_value) const noexcept;
    const_iterator_adjacent_nodes end(const T& node_value) const noexcept;

    const_iterator_adjacent_nodes cbegin(const T& node_value) const noexcept;
    const_iterator_adjacent_nodes cend(const T& node_value) const noexcept;
    
    using reverse_iterator_adjacent_nodes =
        std::reverse_iterator<iterator_adjacent_nodes>;
    using const_reverse_iterator_adjacent_nodes =
        std::reverse_iterator<const_iterator_adjacent_nodes>;
    
    // Return reverse iterators to the list of adjacent nodes for the given node.
    // Return a default constructed iterator as end iterator if the value is not found.
    reverse_iterator_adjacent_nodes rbegin(const T& node_value) noexcept;
    reverse_iterator_adjacent_nodes rend(const T& node_value) noexcept;

    const_reverse_iterator_adjacent_nodes rbegin(const T& node_value) const noexcept;
    const_reverse_iterator_adjacent_nodes rend(const T& node_value) const noexcept;

    const_reverse_iterator_adjacent_nodes crbegin(const T& node_value) const noexcept;
    const_reverse_iterator_adjacent_nodes crend(const T& node_value) const noexcept;

    
   // Two directed graphs are equal if they have the same nodes and edges.
   // The order in which the nodes and edges have been added does not affect equality.
    bool operator==(const directed_graph& rhs) const {
        for (auto&& node : m_nodes) {
          const auto result = rhs.find(node.get());
          if (result == std::end(rhs.m_nodes)) {
             return false;
          }
          const auto adjacent_values_lhs =
             get_adjacent_node_values(node.get_adjacent_node_indices());
          const auto adjacent_values_rhs =
             rhs.get_adjacent_node_values(result->get_adjacent_node_indices());
          if (adjacent_values_lhs != adjacent_values_rhs) {
             return false;
          }
       }
       return true;
    }
   bool operator!=(const directed_graph& rhs) const;

   void swap(directed_graph& other_graph) noexcept;
   size_t size() const noexcept;

   // Returns a set with the nodes adjacent to the given node.
   // std::set<T> get_adjacent_node_values(const T& node_value) const;
    
    template<typename T>
    typename directed_graph<T>::size_type
       directed_graph<T>::max_size() const noexcept
    {
       return m_nodes.max_size();
    }

    template<typename T>
    bool directed_graph<T>::empty() const noexcept
    {
       return m_nodes.empty();
    }

    
    using iterator = const_directed_graph_iterator<directed_graph>;
    using const_iterator = const_directed_graph_iterator<directed_graph>;
    using reverse_iterator = std::reverse_iterator<iterator>;
    using const_reverse_iterator = std::reverse_iterator<const_iterator>;

    using iterator_adjacent_nodes = adjacent_nodes_iterator<directed_graph>;
    using const_iterator_adjacent_nodes = const_adjacent_nodes_iterator<directed_graph>;
    using reverse_iterator_adjacent_nodes =
       std::reverse_iterator<iterator_adjacent_nodes>;
    using const_reverse_iterator_adjacent_nodes =
       std::reverse_iterator<const_iterator_adjacent_nodes>;
    friend class const_directed_graph_iterator<directed_graph>;
};

template<typename DirectedGraph>
class const_directed_graph_iterator
{
public:
   using value_type = typename DirectedGraph::value_type;
   using difference_type = ptrdiff_t;
   using iterator_category = std::bidirectional_iterator_tag;
   using pointer = const value_type*;
   using reference = const value_type&;
   using iterator_type =
	typename DirectedGraph::nodes_container_type::const_iterator;
    // No transfer of ownership of graph.
    const_directed_graph_iterator(iterator_type it, const DirectedGraph* graph);
    // Bidirectional iterators must supply a default constructor.
    const_directed_graph_iterator() = default;

    reference operator*() const;
    pointer operator->() const;

    const_directed_graph_iterator& operator++();
    const_directed_graph_iterator operator++(int);

    const_directed_graph_iterator& operator--();
    const_directed_graph_iterator operator--(int);

    // The following are ok as member functions because we don't
    // support comparisons of different types to this one.
    bool operator==(const const_directed_graph_iterator& rhs) const;
    bool operator!=(const const_directed_graph_iterator& rhs) const;
protected:
   friend class directed_graph<value_type>;

   iterator_type m_nodeIterator;
   const DirectedGraph* m_graph = nullptr;

   // Helper methods for operator++ and operator--
   void increment();
   void decrement();
};

template<typename DirectedGraph>
class directed_graph_iterator : public const_directed_graph_iterator<DirectedGraph>
{
public:
   using value_type = typename DirectedGraph::value_type;
   using difference_type = ptrdiff_t;
   using iterator_category = std::bidirectional_iterator_tag;
   using pointer = value_type*;
   using reference = value_type&;
   using iterator_type = typename DirectedGraph::nodes_container_type::iterator;

   directed_graph_iterator() = default;
   directed_graph_iterator(iterator_type it, const DirectedGraph* graph);

    reference operator*() {
    	// when accessing anything from the templated base class, need to use this->
        return const_cast<reference>(this->m_nodeIterator->get());
    }
   pointer operator->();
   directed_graph_iterator& operator++();
   directed_graph_iterator operator++(int);
   directed_graph_iterator& operator--();
   directed_graph_iterator operator--(int);
};

template<typename T>
void swap(directed_graph<T>& first, directed_graph<T>& second)
{
   first.swap(second);
}


template <typename T>
std::wstring to_dot(const directed_graph<T>& graph, std::wstring_view graph_name)
{
   std::wstringstream wss;
   wss << "digraph " << graph_name << " {" << std::endl;
   for (auto&& node : graph) {
      const auto b = graph.cbegin(node);
      const auto e = graph.cend(node);
      if (b == e) {
         wss << node << std::endl;
      } else {
         for (auto iter = b; iter != e; ++iter) {
            wss << node << " -> " << *iter
                << std::endl;
         }
      }
   }
   wss << "}" << std::endl;
   return wss.str();
}

```

- Use `explicit template instantiation` to find errors. 

```
// Force all code to be compiled for testing.
template class details::graph_node<string>;
template class directed_graph<string>;
```

- Naïve version -> Standard compliant container (iterator, allocator, interface)

## Woes of scope guards and unique resources

- resources
  - lifetime (acquire, use, release)
  - lifetime-managed (by OS, by runtime, by manager objects)
  - exclusive or shared
  - not releasing => error (leaking, safety, security, DoS)
  - [Pattern-oriented-software-architecture](https://www.amazon.com/Pattern-Oriented-Software-Architecture-System-Patterns/dp/0471958697)
  - ![1546459515482](C:\Users\xiaol\AppData\Roaming\Typora\typora-user-images\1546459515482.png)
- RAII 
  - acquire the resource in the constructor
  - use it through class interface
  - release the resource in the destructor
  - I/O handles: `fstream`
  - Memory: `unique_ptr`, string, containers
  - Lockable: `lock_guard`, `unique_lock`, `scoped_lock`
  - Missing: OS resource handles, own lifetime managed resources
- `unique_ptr` as generic RAII?
  - mis-proposed for resource handles that are pointer-sized
  - if opaque`HANDLE` type changes (size)
  - not work for non-trival `HANDLE` types, where copying/moving might have side-effects
  - Deleter's pointer type alias must conform to concept `NullablePointer`
  - [`unique_ptr`-for-`FILE*`](https://stackoverflow.com/questions/26360916/using-custom-deleter-with-unique-ptr)

```c++
struct Deleter
{
    //	By	defining	the	pointer	type,	we	can	delete	a	type	other	than	T*.
    //	In	other	words,	we	can	declare	unique_ptr<HANDLE,	Deleter>	instead	of
    //	unique_ptr<void,	Deleter>	which	leaks	the	HANDLE	abstraction.
    typedef HANDLE pointer;
    void operator()(HANDLE h)
    {
	    if(h	!=	INVALID_HANDLE_VALUE)
    	{
    		CloseHandle(h);
    	}
    }
};

void OpenAndWriteFile()
{
    //	Specify	a	deleter	as	a	template	argument.
    std::unique_ptr<HANDLE,	Deleter>	file(CreateFile(_T("test.txt"),
                                            GENERIC_WRITE,
                                            0,
                                            NULL,
                                            CREATE_ALWAYS,
                                            FILE_ATTRIBUTE_NORMAL,
                                            NULL));
    if(file.get()	!=	INVALID_HANDLE_VALUE)
    {
        DWORD size;
	    WriteFile(file.get(),	"Hello	World",	11,	&size,	NULL);
    }
}
```

- `scoped_resource`
- `scope_guard`
- `std::move_if_noexcept(resource)` or copy
- [unique_resource](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2014/n4189)
- ![1546460513084](C:\Users\xiaol\AppData\Roaming\Typora\typora-user-images\1546460513084.png)
  - exceptions
    - function(deleter) objects throw on copy/move
    - resource objects throw on move
    - resource objects cannot be assigned
  - if move cannot throw => move
  - if copying is needed => can throw (copy first, move rest, or copy both)
  - only if everything is organized => release old

![1546461107497](C:\Users\xiaol\AppData\Roaming\Typora\typora-user-images\1546461107497.png)

## What to expect from a next generation cpp build system

![1546461369730](C:\Users\xiaol\AppData\Roaming\Typora\typora-user-images\1546461369730.png)

- C Values
  - Performance
  - Portability
  - Simplicity
- C++ Values
  - Compatibility
  - Extensibility
  - Performance
  - Portability
  - Expressiveness (Modern C++)
  - Robustness (Modern C++)
  - Approachability (Modern C++)
- Javascript Values
  - Approachability
  - Expressiveness
  - Velocity
- Meta Build System
  - C++ Modules
  - Generated Source Code
  - Distributed Compilation/Caching
  - Compilation Database
- Native Build System
  - Full control of compilation
  - Uniform, works the same everywhere
  - No project generation step
- Build system
  - Meta vs Native => native
  - Black box (make/cmake) vs Concept of build => conceptual model of build
  - Implementation language (C++ vs. other) => implemented in c++
  - Declarative vs Scripted => Hybrid, mostly declarative, type-safe
  - Part of the dependency management toolchain 
  - Available as a library for easier IDE/tools integration 
- Current-Generation Functionality
  - I/O of source
  - wildcard patterns
  - cross-compilation
  - test/install/uninstall/dist (preparation of source distribution)/configure
  - Integrated Configuration Management
- Next-Generation Functionality
  - Importation
  - Subprojects/Amalgamations
  - Import installed
  - Scripted Testing
    - concise/portable/input generation/output analysis(regex)/parallel execution/incremental testing
  - High-Fidelity Hermetic Build
    - independent from environment/tools(compiler, linker)/options/source code sets
  - Precise change detection (avoid recompiling of ignorable changes)
  - C++ modules
  - Distributed Compilation and Caching
- Old C++ Build Model: header dependency as byproduct of compilation
- New C++ Build Model: 

![1546462167743](C:\Users\xiaol\AppData\Roaming\Typora\typora-user-images\1546462167743.png)

## What do you mean thread-safe

- thread-safe type
  - If a live object has a thread-safe type, it can't be the site of an API race
- thread-compatible type
  - If a live object has a thread-compatible type, it can't be the site of an API race if it's not being mutated 
- any type
  - If a live object has any type, it can't be the site of an API race if it's not being accessed concurrently 
- thread-hostile functions
  - cause API races at sites other than their inputs 

> A given line code is guaranteed to have no API races if it calls no thread-hostile functions, all inputs are live, and each input is
> ● not being accessed by other threads, or
> ● thread-safe, or
> ● thread-compatible and not being mutated by any thread. 



## Networking TS in practice

|              | Synchronous                                                  | Asynchronous (Proactor)                                      |
| ------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Initiation   | Function call                                                | Function call (initiating function)                          |
| Input/Output | Blocks calling thread                                        | Proceeds in background (initiating function returns immediately) |
| Completion   | Control of thread returned to caller, returned value(s) transmit result | Completion handler (callable object) invoked, parameter(s) transmit result |

```c++
struct heartbeat {
    std::net::system_timer& timer_;
    std::net::ip::tcp::socket& socket_;
    const std::byte* buffer_;
    std::size_t size_;
    void initiate();
    void operator()(std::error_code ec, std::size_t written);
};

void heartbeat::initiate() {
    async_wait_then_write(timer_, socket_, std::chrono::seconds(5),
    	std::net::buffer(buffer_, size_), std::move(*this));
}

void heartbeat::operator()(std::error_code ec, std::size_t written) {
    if (ec) throw std::system_error(ec);
    initiate();
}

const std::byte write_buffer[/* ... */];
std::net::io_context ctx;
std::net::ip::tcp::socket socket(ctx);
std::net::system_timer timer(ctx);
// ...
heartbeat{timer, socket, write_buffer,
  sizeof(write_buffer)}.initiate();

```

- Executor
  - An executor is a handle to an execution context in which code may be executed upon execution resources via execution agents
  - `dispatch` invokes a function object within the associated execution context
  - `defer` extends `dispatch` by requesting that the call not block on the completion of submitted work
  - `post` extends `defer` by making the request a requirement
  - Associated Executor
  - [Networking TS vis-à-vis Executors TS](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2018/p0958r0.htm)
  - [Networking TS](http://cplusplus.github.io/networking-ts/draft.pdf)
  - [Executors TS](https://github.com/executors/executors/blob/master/explanatory.md)
  - [Executors TS-2](https://github.com/executors/executors/blob/master/wording.md)



## The embedded device under your desk - UEFI application

- Firmware interface (compared to old BIOS)

![1546598019893](D:/OneDrive/Pictures/Typora/1546598019893.png)

- EFI Executables
  - COFF file format, subsystems 10-13
  - MS calling convention
  - UTF-16 string
  - partition type 0xEF00 on FAT32 partition
  - EFI/Boot/bootx64.efi
- EDK/GNU efilib + MSVC/MinGW gcc + C95 stdlib

```c++
x86_64-w64-mingw32-g++ \
	-mno-red-zone
	-ffreestanding -fshort-wchar \
	-nostdlib -e efi_main \
	-Wl, -dll -shared -Wl, --subsystem, 10 \
	-c main.cpp
	
#include <efi.h>
#include <efilib.h>
extern "C" [[gnu::ms_abi]]
EFI_STATUS efi_main(
IN EFI_HANDLE ImageHandle,
IN EFI_SYSTEM_TABLE *SystemTable)
{
    SystemTable->ConOut->OutputString(
    SystemTable->ConOut,
	    (CHAR16 *) L"Hello World\r\n"); // Note the missing const
}

qemu-system-x86_64 \
	-drive file=hdd.img, if=ide \
	-bios OVMF.fd
```

- EFI Protocol
  - Firmware services as GUIDs
  - OO style interface+ C function pointer
  - `EFI_STATUS(in..., inout *..., out *...)`
- [UEFI Bare Bones](https://wiki.osdev.org/UEFI_Bare_Bones)



## Surprises in object lifetime

- > An object type is a (possibly cv-qualified) type that is not a function type, not a reference type, and not cv void 

- > The lifetime of an object of type T begins when:
  > ​    (1.1) storage with the proper alignment and size for type T is obtained, and
  >
  > ​    (1.2) if the object has non-vacuous initialization, its initialization is complete, except that if the object is a union member or subobject thereof, its lifetime only begins if that union member is the initialized member in the union (11.6.1, 15.6.2), or as described in 12.3 

- > The lifetime of an object o of type T ends when:
  > ​    (1.3) if T is a class type with a non-trivial destructor (15.4), the destructor call starts, or
  >
  > ​    (1.4) the storage which the object occupies is released, or is reused by an object that is not nested within o (4.5). 

- `&` types are not objects => no lifetime (Compared to Rust?)

  - But `reference_wrapper<T>` has lifetime...

- String Literal => `'static`

- For a non-trivially destructible type, the destructor of a moved-from object must still be called 

- [Lifetime extension from temporary](https://en.cppreference.com/w/cpp/language/reference_initialization#Lifetime_of_a_temporary)

  - apply recursively to member initializers

- `std::initializer_list<T>`

  - invocations create hidden `const` arrays

- `for(auto&& v : get_vector().get_data())`: dangling reference

- C++20: for-init

- If-init statements are visible for the `else` block

- Structure-binding creates extra reference disable RVO

- An object’s lifetime has begun aʻer any constructor has completed 

  - If no delegating constructor, incomplete constructor => no destructor

- Don't name temporaries

- Consider requiring all structure-binding to be `&`

- `-Wshadow`

- Sanitizer

- `initializer_list<T>`: difference from Initializer List.

  - only for `trivial` or `literal`

```c++
#include <cstdio>
#include <vector>
struct S {
    S() { puts("S()"); }
    S(int) { puts("S(int)"); }
    S(const S &) noexcept { puts("S(const S &)"); }
    S(S &&) noexcept { puts("S(S&&)"); }
    S &operator=(const S &) { puts("operator=(const S&)"); return *this; }
    S &operator=(S &&) { puts("operator=(S&&)"); return *this; }
    ~S() { puts("~S()"); }
};

struct Holder { S s; int i };
Holder get_Holder() { return {}; } /// init Holder, S()

S get_S() {
    S s = get_Holder().s; 	/// r-value inits s, S(S&&), ~S() of moved from
	auto [s, i] = get_Holder(); /// structured bindings
    /*
    	auto e = get_Holder(); ///
        auto &s = e.s; ///
        auto &i = e.i; ///
        return s; /// RVO not applied to reference
    */
    return s; 				/// rvo applied
} 							/// ~S() from this `s

int main() {
    std::vector<S> vec;
    vec.push_back(S{1}); 	// S(int) S(&&) ~S() ~S()
    vec.emplace_back(S{1}); // S(int) S(&&) ~S() ~S()
    vec.emplace_back(1);	// S(int) ~S()
    vec.emplace_back(); 	// S() ~S()
	S s = get_S(); 			// nothing printed
} // ~S() from last `s`

std::vector<std::string> vec{"a long string of characters", "b long string of characters"}; // 5 dynamic allocation
/*
	const std::string data[2] = {..., ...} // 2 alloc
	vector: 1 alloc
	copy of string: 2 alloc
*/
```



## State Machines battlefield

- `if/else`: inlined(+), no heap(+), small memory footprint(~), hard to use(-)

- `switch/enum`: inlined(+), no heap(+), small memory footprint(+), hard to use(-)

- inheritance/state pattern: easy to extend/reuse(+), high memory footprint(~), heap dynamic allocation(-), not inlined/devirtualized(-)

- `std::variant/std::visit`: small memory footprint(+), integrates with `std::expected`/static exceptions, inlined (clang only), hard to reuse

- coroutine/loop: structured code(+), switch between async/sync(+), learning curve(~), heap (elision, devirtualizaton), implicit state(-), events requires common type(-), weird usage of infinite loop(-)

- coroutine/goto: explicit state, goto, no infinite loop

- coroutine/functions/variant: reuse, type safe

- `Boost::Statechart`: UML 1.5 features(+), dynamic allocation(-), dynamic dispatch(-), high memory usage(-)

- `Boost::MSM/EMUL`: Declarative/Expressive (UML transition)(+), Dispatch O(1) - jump table, UML-2.0 features, small memory footprint, DSL based, macro based, slow compilation times, error message

- `[Boost]::SML`: dispatch policy changes event dispatching strategy (if/else, switch, jump_table, fold-expression)

  - ```c++
    return ((
        current_state == Ns
        ? TMappings<TStates>::execute(event)
        : false
    ) or ...)
    ```

  - Declarative/Expressive

  - Customizable (compile time)

  - Inlined/Dispatch O(1)

  - Fast compilation time

  - UML-2.5 features

  - Minimal memory footprint (Enum as Compile value or Type)

  - DSL based

- State representation: boolean/enum/class/union/function/type

- Transition Table: per state/global

- Transition: implicit/explicit



## Regular types and Why do I care

* **Datum**: a finite sequence of 0s and 1s

* **Value Type**: A correspondence between a species(abstract/concrete) and a set of datums

* **Value**: a datum with its interpretation (e.g. an integer represented in 32bit 2's complement, big endian)

  * immutable

* > If a value type is uniquely represented, equality implies representational equality.
  >
  > If a value type is not ambiguous, representational equality implies equality. 

* **Object**: a representation of a concrete entity as a value in computer memory (address & length)

  * Object having a state, which is a value of some value type
  * mutable state

* **Type**: a set of values with the same interpretation function and operations on these values

* **Concept**: a collection of similar types

  * > Formal specification of concepts makes it possible to verify that template arguments satisfy the expectations of a template or function during overload resolution and template specialization (requirements).
    >
    > Each concept is a predicate, evaluated at compile time, and becomes a part of the interface of a template where it is used as a constraint. 

* `Regular` type (**Sane and Safe Cpp Classes**)
  - `EqualityComparable` (`==`, `!=`)
    - equality = equivalence relation + partial order
  - --- `SemiRegular` ---
  - `DefaultConstructible` (`T{}`)
  - `Copyable` (`T(T const&)`, `T& operator=(T const&)&`)
  - `Movable` (`T(T&&)`, `T& operator=(T&&)&`, `is_object_v`)
  - `Swappable` (`swap(T&, T&)`)
  - `Assignable` (`t1 = t2`)
  - `MoveConstructible` (`T(T&&)`)
  - ![1546811435400](D:\OneDrive\Pictures\Typora\1546811435400.png)
* STL requires `Regular` type



## Miscs

- Write SEH handler, `.pdata, .xdata` sections (**Unwinding the Stack: Exploring how C++ Exceptions work on Windows**)
- side effects
  - read a volatile object
  - write any object
  - call I/O function
  - invoking a function which does any one of the above 
- Mocking framework (**To kill  a mocking framework**)
- COM (**These aren't the com objects you're looking for**)
  - `CoInitializeEx` `CoUninitialize` (must be called at each thread once, multiple allowed) => RAII
  - `BSTR` (`WCHAR*`, `OLECHAR*`) => RAII (`_bstr_t` [COW], `_com_ptr_t`, `_variant_t`, `_com_error`)
  - `CComObject<Base>` => CRTP (ATL, WTL libraries)
  - WinRT (OO WinAPI + Metadata reflection + Lang projection) => WRL, C++/CX => C++/WinRT
- Cross-Platform (**The Salami Method**)
  - ![1546563887960](D:/OneDrive/Pictures/Typora/1546563887960.png)
- **The most valuable values**
  - Object = location + type + lifetime
  - value semantics （value: macro, object: micro)

```c++
class foo {
    std::shared_ptr<impl> impl_;
public:
    foo modified(int arg) const& {;
        auto p = impl_->clone();
        p->mutate(arg);
        return foo{p};
    }
    
    foo&& modified(int arg) && {
        if (impl_->unique()) 	// unique() is not thread safe
        	impl_->mutate(arg); // according to std::shared_ptr.
        else 					// use your own implementation
        	*this = modified(); // of reference counting
        return std::move(*this);
    }
};

class screen {
    screen_handle handle_;
    screen(const screen&) = delete;
public:
    screen&& draw(...) && {
	    do_draw(handle_, ...);
    } 
    auto draw(...) const {
        return [hdl=handle_] (context ctx) {
        	do_draw(hdl, ...);
        };
    }
};
```

- C++17 to C++11 (**Teaching Old Compilers new tricks**)
  - `clang-from-the-future`
  - `source -> build AST -> c++11 source`
  - AST visitor -> libclang
  - rewrite engine
  - template specializer
  - test suite
  - cli

- [cppinsights.io](https://cppinsights.io/)

- SD-8 (**Standard Library Compatibility Guidelines**)
  - Add new names to namespace std
  - Add new member functions to types in namespace std
  - Add new overloads to existing functions
    - function pointer/address/specialization to `std` is bad
  - Add new default arguments to functions and templates
  - Change return-types of functions in compatible ways (void to anything, numeric types in a widening fashion, etc).
  - Make changes to existing interfaces in a fashion that will be backward compatible, if those interfaces are solely used to instantiate types and invoke functions.
    - Implementation details (the primary name of a type, the implementation details for a function callable) may not be depended upon 

- C++ Core Guidelines

- CERT C++ Coding Standard

- Common Weakness Enumeration

- [Insecure-coding-examples](github.com/patricia-gallardo/insecure-coding-examples/ )

- Modern C++ Idioms

- Playback-based testing (**Save Money Testing Code the Playback-Based Way**)

  - Recording: call-stream
    - serialize/deserialize call arguments
    - unswizzles/swizzles pointers (objects)
    - lossless type conversion
  - [CppPlayer](https://github.com/WilliamClements/CppPlayer)

- Lua sol/sol2/sol3 Lib (**Scripting at the Speed of Thoughts**)

  - `lua_gettable()`, `lua_getglobal`, `lua_geti`, ...
  - `sol::stack::push, sol::stack::get<T>, sol::stack::check<T>`
  - `sol::reference` => `intrusive_ptr`, `retain_ptr`, ARC references
  - usertype
  - Abstraction Layer
    - 0: Rule of 0
    - 1: Reuse
    - 2: Proxy
  - [explicit operator T()](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2018/p1193r0.html)
    - `U = obj`, then `T` must be deduced to `U`

- Copy elision in x86 (**Return value optimization harder it looks**)

  - Large object => pass pointer on stack (`%rdi`)

  - Elide copy => direct construct on passed address

  - Can't elide

    - Can't control physical location
    - Return type different for constructing into the return slot

  - URVO: returning a temporary (prvalue) will trigger copy-elision

  - NRVO: return a local variable by name, except in the corner cases

  - Implicit move: return a local variable by name doesn't trigger copy-elision, overload resolution will still treat the name as an rvalue (`return std::move(x)` will never help and hurt disabling NRVO)

  - Plain-old-copy: fallback

  - > if the **first overload resolution** fails or was not performed, or if the type of the **first parameter of the selected constructor** is not an **rvalue reference** to the object’s type (possibly cv-qualified), overload resolution is performed again, considering the object as an lvalue.” 

  * `clang++ -Wmove` / `clang++ -Wpessimizing-move` / `-Wreturn-std-move`

  * **P1155R0**, **P0527R1**

  * ```c++
    if (AllowNRVO) {
        if (!NRVOCandidate)
    	    NRVOCandidate = getCopyElisionCandidate(ResultType, Value, CES_Default);
        if (NRVOCandidate)
        	AttemptMoveInitialization(*this, Entity, NRVOCandidate, ResultType, Value, false, Res);
        if (Res.isInvalid()) {
            auto *FakeCandidate = getCopyElisionCandidate(QualType(), Value, CES_AsIfByStdMove);
            if (FakeCandidate) {
            ExprResult FakeRes = ExprError();
            AttemptMoveInitialization(*this, Entity, FakeCandidate, ResultType, Value, true, FakeRes);
            if (!FakeRes.isInvalid()) {
                bool IsThrow = (Entity.getKind() == InitializedEntity::EK_Exception);
                Diag(Value->getExprLoc(), diag::warn_return_std_move)
                		<< Value->getSourceRange()
                		<< FakeCandidate->getDeclName() << IsThrow;
                }
            }
        }
    }
    // Either we didn't meet the criteria for treating an lvalue as an rvalue, ...
    if (Res.isInvalid())
    	Res = PerformCopyInitialization(Entity, SourceLocation(), Value);
    return Res;
    ```

- DSL

  - GLSL (**rapir prototyping of graphics shaders in modern cpp**)
  - Lua - Sol{2, 3}
  - BigInt - ctbignum (Verfied by SMT/Boogie) (**multiprecision arithmetic for crypto**)
  - CUDA - cudacpp (**Cuda kernels with cpp**)
  - WASM (**Cpp everywhere with webassembly**)
  - Regex - ctre (**compile time regular expression**)
  - semi compile-runtime map
  - Reflection by LLVM/Clang
  - Metaclass
  - 

- [Undefined Behavior Detector](https://taas.trust-in-soft.com/tsnippet/#)

- operators (**operator overloading**)

  - name

  - precedence

  - associativity

  - arity

  - fixity

  - evaluation semantics

  - > Use operator when:
    >
    > ​    you have a natural binary function that combines your types
    >
    > ​    your types obey mathematical principles (associativity, etc)
    >
    > ​    you want users to be able to manipulate expressions
    >
    > ​    you want to make complex construction easier
    >
    > ​    you want users to intuit properties of your types 
    >
    > Don't only use operator when
    >
    > ​    you can provide better perf with an n-ary function
    >
    > ​    they aren't yet ready for primetime (operator<=>) 
    >
    > Don't
    >
    > ​    break contrariety of operator== and operator!=
    >
    > ​    break associativity
    >
    > ​    be afraid to overload just one operator, if it makes sense (operator/)
    >
    > ​    overload operator&& operator|| operator, even with P0145
    >
    > ​    pick weird operators if your type is mathematical 
    >
    > Do
    >
    > ​    use conventions other than mathematical ones
    >
    > ​    consider distinguishing your types to leverage affine spaces
    >
    > ​    use operators for non-commutative operations to leverage fold expressions
    >
    > ​    use UDLs as a counterpart to operators to help with construction
    >
    > ​    provide the whole set of related operators if you provide one

- OOP vs DoD (data-oriented design) (**OOP is dead Long live DoD**)

  - ![1546912314282](D:\OneDrive\Pictures\Typora\1546912314282.png)
  - ![1546912330620](D:\OneDrive\Pictures\Typora\1546912330620.png)
  - ![1546912343199](D:\OneDrive\Pictures\Typora\1546912343199.png)
  - ![1546912354448](D:\OneDrive\Pictures\Typora\1546912354448.png)
  - ![1546912363535](D:\OneDrive\Pictures\Typora\1546912363535.png)
  - ![1546912374571](D:\OneDrive\Pictures\Typora\1546912374571.png)
  - ![1546912386848](D:\OneDrive\Pictures\Typora\1546912386848.png)

- Modern C++ API Design

  - Micro-API Design
    - parameter passing
    - method qualification (`const`, `&` `&&`, `noexcept`)
    - importance of overload sets
      - move, copy
      - skeptical about`=delete`
      - ![1546914142248](D:\OneDrive\Pictures\Typora\1546914142248.png)
    - 
  - Type Properties
    - What properties can we use to describe types
    - e.g. thread safety, comparability, order, copyable, movable, mutable
    - e.g. invariant, dependent precondition, postcondition
  - Type Families
    - What combination of type properties make useful/good type designs

- Minidump (**Minidumps gdb-compatible software controlled core dumps**)

  - kernel-driven core dumps dump everything in memory
  - faster/smaller/eliminating regions from dump
  - `MADV_DONTDUMP` not a safe call at dump time (memory allocator-ware, 4k granularity)
  - core file
    - ELF header
    - program header
    - notes
    - ![1546914700652](D:\OneDrive\Pictures\Typora\1546914700652.png)
    - per-thread state
    - signal handler
  - Detail
    - ![1546914863915](D:\OneDrive\Pictures\Typora\1546914863915.png)
    - ![1546914871523](D:\OneDrive\Pictures\Typora\1546914871523.png)
    - ![1546914878362](D:\OneDrive\Pictures\Typora\1546914878362.png)
    - ![1546914890147](D:\OneDrive\Pictures\Typora\1546914890147.png)
    - ![1546914896351](D:\OneDrive\Pictures\Typora\1546914896351.png)
    - ![1546914922500](D:\OneDrive\Pictures\Typora\1546914922500.png)
    - ![1546914931260](D:\OneDrive\Pictures\Typora\1546914931260.png)
    - ![1546914975821](D:\OneDrive\Pictures\Typora\1546914975821.png)
    - ![1546914984780](D:\OneDrive\Pictures\Typora\1546914984780.png)

- Lifetime clang profiler `-Wlifetime` (**Implementation cpp core guideline lifetime safety profile in clang**)

  - ![1546915717140](D:\OneDrive\Pictures\Typora\1546915717140.png)
  - Types -> Categories
    - Owners (`vector`, `unique_ptr`)
      - ![1546915801700](D:\OneDrive\Pictures\Typora\1546915801700.png)
    - Pointers (`int*`, `double&`, `reference_wrapper`, iterator, `string_view`)
      - ![1546915821057](D:\OneDrive\Pictures\Typora\1546915821057.png)
    - Aggregates (like PODs)
      - ![1546915828083](D:\OneDrive\Pictures\Typora\1546915828083.png)
    - Values (anything else)
  - Intra-function analysis
    - Points-to map/set
      - ![1546915846691](D:\OneDrive\Pictures\Typora\1546915846691.png)
    - Branching
    - Null tracking
  - Inter-function analysis
  - Type safety
  - `[[gsl::lifetime(a)]]` // `[[gsl::lifetime_out]]`

- ![1546916302945](D:\OneDrive\Pictures\Typora\1546916302945.png)

- Metaprogramming (**from metaprogramming tricks to elegance**)

  - `validator` (`is_invocable`, iike detector)
  - `overload_sequence` (use `is_invocable` + `tuple_index_v`)
  - `overload_set` (`using Callable::operator()...`)
  - ![1546917275595](D:\OneDrive\Pictures\Typora\1546917275595.png)
  - ![1546917286841](D:\OneDrive\Pictures\Typora\1546917286841.png)
  - ![1546917300799](D:\OneDrive\Pictures\Typora\1546917300799.png)
  - ![1546917313254](D:\OneDrive\Pictures\Typora\1546917313254.png)
  - ![1546917360195](D:\OneDrive\Pictures\Typora\1546917360195.png)
  - ![1546917429933](D:\OneDrive\Pictures\Typora\1546917429933.png)
  - ![1546917443120](D:\OneDrive\Pictures\Typora\1546917443120.png)
  - ![1546917456862](D:\OneDrive\Pictures\Typora\1546917456862.png)
  - ![1546917467591](D:\OneDrive\Pictures\Typora\1546917467591.png)

- Relocatable type (**Fancy pointer for fun and profit**)

  - serializable by writing raw bytes
  - de-serializable by reading raw bytes
  - A destination object of that type is semantically identical to its corresponding source object, regardless of the destination process and its address in the destination process
  - relocatable types: integer/floating point/standard layout containing only integer/floating point
  - non-relocatable: pointer/pointer to function/virtual function+vtable/process dependency(HANDLE, FILE*)
  - relocatable heap
    - offset addressing model
    - 2D storage model (Based 2D XL addressing model)
    - Synthetic pointer

- Declarative language (**declarative style in cpp**)

  - Expression over statements

    - > An expression is a sequence of operators and operands that specifies a computation.
      > An expression can result in a value and can cause side effects." [expr.pre] § 1 
      >
      > Value category
      >
      > Type

    - > Except as indicated, statements are executed in sequence." [stmt.stmt] § 1 
      >
      > no type checking
      >
      > value checking is manual, intrusive
      >
      > implicit constraints
      >
      > temporal reasoning is poor 

      - > expression statement
        > selection statement (if, switch)
        > iteration statement (for, while, do)
        > jump statement (break, continue, return, goto)
        > declaration statement 

    - Assignment is expression (should be statement)

  - Declarations over assignments

  - Unconditional code

    - ![1546918774367](D:\OneDrive\Pictures\Typora\1546918774367.png)
    - ![1546918787620](D:\OneDrive\Pictures\Typora\1546918787620.png)

- Cryptozoology (**C++ Bestiary**) [old one](http://videocortex.io/2017/Bestiary/#-abominable-types)

  - abominable function types

    - `using abominable  = void() const volatile &&`

    - unable to create a function with abominable type

    - ```c++
      class rectangle {
        public:
          using int_property = int() const;  // common signature for several methods
      
          int_property top;
          int_property left;
          int_property bottom;
          int_property right;
          int_property width;
          int_property height;
      
          // Remaining details elided
      };
      ```

  - Copy-on-write

    - C++11 forbids COW `string` due to iterator/pointer/reference invalidation

  - Duck Typing

  - Maximal Much

    - > When the lexical analyzer take as many characters as possible to form a valid token.
      >
      > “Otherwise, the next preprocessing token is the longest sequence of characters that could constitute a preprocessing token, even if that would cause further lexical analysis to fail.” -- [lex.pptoken] 

    - `x++y` => `x++ y` : invalid, not `x+, +y`

  - OWLS `(0, 0)` old MSVC warning supression trick

  - Phantom types (type tag)

  - Poisoning functions

    - `#pragma poison` (use => compile error)
    - identify deprecated features

  - pony princess

    - > Some Atomic compare-and-exchange operations might fail when padding bits do not participate in the value representation of the active member 

    - [example](https://stackoverflow.com/questions/48947428/atomic-variable-with-padding-compiler-bug)

  - terminator

    - `exit/abort/terminate/signal/raise`
    - ![1546919359171](D:\OneDrive\Pictures\Typora\1546919359171.png)

  - `void`: incomplete type that cannot be instantiated

    - but `T{} with T=void` is allowed
    - Unit Type

  - Voldemort types

    - > A type that cannot be named outside of the scope it’s declared in, but code outside the scope can still use this type. 

    - `auto p = A::B`

  - Zombies (moved-from state)

    - valid but unspecified
    - destructive move
    - only ops with no pre-conditions

  - Unified call syntax

    - `f(x, y) => x.f(y)`
    - break legacy code (ADL)

  - Transparent objects (accept arbitrary types and perfect forwarding)

- Concepts (**Concepts as she is spoken**)

  - ```c++
    template <class B>
    concept Body = requires(
    	istream& is,
        ostream& os,
        typename B::value_type& b,
        typename B::value_type const& cb
    ) {
    	typename B::value_type;
        B::read(is, b);
        B::write(is, cb);
    }
    ```

  - ```c++
    template <typename T>
    void foo() noexcept (boolean-expression);
    
    constexpr bool plugh = noexcept (unevaluated-expression);
    
    template <typename T>
    void foo() noexcept(noexcept(unevaluated-expression));
    
    template<class T>
    void xyzzy() requires boolean-expression;
    
    constexpr bool plugh = requires ( parameter-list ) { requirement-seq };
    template <typename T>
    concept Big = sizeof(T) >= 24;
    
    template<class T>
    void xyzzy() requires requires ( parameter-list ) { requirement-seq };
    
    onstexpr bool Fooable = requires ( parameter-list ) {
        typename type-expression ;
        { value-expression };
        { value-expression } noexcept ;
        { value-expression } -> type-or-concept ;
        requires constraint-expression ;
    };
    
    template<class T>
    concept Fooable = requires (const T ct, int i) {
        typename T::value_type;
        { ct + i };
        { ct += i } noexcept; 	// requires noexcept(ct += i);
        { ct += i } -> T&; 		// requires is_convertible_v<decltype(ct += i), T&>;
        { ct - ct } -> Integral;// requires Integral<decltype(ct - ct)>;
        { *ct } -> auto&&;		// requires !is_void_v<decltype(*ct)>;
    	{ +ct } -> auto*;		// requires is_pointer_v<remove_reference_t<decltype(+ct)>>;
    };
    
    template <class T>
    concept Semiregular = DefaultConstructible<T> &&
        CopyConstructible<T> && Destructible<T> && CopyAssignable<T> &&
    requires(T a, size_t n) {  
        requires Same<T*, decltype(&a)>;  // nested: "Same<...> evaluates to true"
        { a.~T() } noexcept;  // compound: "a.~T()" is a valid expression that doesn't throw
        requires Same<T*, decltype(new T)>; // nested: "Same<...> evaluates to true"
        requires Same<T*, decltype(new T[n])>; // nested
        { delete new T };  // compound
        { delete new T[n] }; // compound
    };
    ```

  - Terse syntax

    - `template <Regular t>`
    - `void foo(Integral auto t)`

  - linker hate return-type SFINAE (name mangling!)

- 