## liballoc

[crate alloc](https://doc.rust-lang.org/alloc/index.html) 的源码，提供管理堆内存的智能指针(smart pointer)和集合(collections)。 不需要直接import `use alloc::Box`, 因为已经在`std crate` 中re-export （例外：使用`#![no_std]`）。

### benches

包含对集合类型的benchmark代码， 使用

```rust
#![feature(repr_simd)]
#![feature(slice_sort_by_cached_key)]
#![feature(test)]

extern crate rand;
extern crate rand_xorshift;
extern crate test;

use test::Bencher;

[bench]
fn foo(b: &mut Bencher);
```



[benchmark-tests](https://doc.rust-lang.org/1.5.0/book/benchmark-tests.html) 文档, `#![feature(test)]`提供测试环境并允许unstable feature。 （值得一提的是`test::black_box(T)`, 类似`benchmark::DoNotOptimize` 在[cpp-quick-bench](http://quick-bench.com/)。(?: 为什么需要`#![feature(test)]`呢？除了unstable和test library还有其他作用吗？)



[#27731](https://github.com/rust-lang/rust/issues/27731) 提供SIMD支持和`#![feature(repr_simd)]`



[#34447](https://github.com/rust-lang/rust/issues/34447) 提供在使用`sort_by_key(&mut self, mut f: F)`的时候，新建一个cache缓存所有`f(element)`用于排序（否则如下实现会多次计算key），以及`#![feature(slice_sort_by_cached_key)]`

```rust
pub fn sort_by_key(&mut self, mut f: F) {
    self.sort_by(|a, b| f(a).cmp(&f(b)))
}
```



生成测试数据一般使用

```rust
let v: Vec<_> = (0..100).map(|i| i ^ (i << 1) ^ (i >> 1)).collect();
let m: LinkedList<_> = v.iter().cloned().collect();
b.iter(||{...});
```

其中`fn collect<B>(self) -> B where B: FromIterator<Self::Item>`将一种(iterator)转换为一种集合(collection)。



`rand_xorshift`提供了快速但是密码学上不安全的的[`Xorshift`](https://doc.rust-lang.org/1.0.0/rand/struct.XorShiftRng.html)随机数生成器。



### collections

集合类型的实现，包括`B-tree`, `binary_heap`, `linked_list`, `deque`(被称为`vec_deque`)

#### btree

##### node.rs

首先是一段注释描述理想的B-Tree Node模式

```rust
// This is an attempt at an implementation following the ideal
//
// ```
// struct BTreeMap<K, V> {
//     height: usize,
//     root: Option<Box<Node<K, V, height>>>
// }
//
// struct Node<K, V, height: usize> {
//     keys: [K; 2 * B - 1],
//     vals: [V; 2 * B - 1],
//     edges: if height > 0 {
//         [Box<Node<K, V, height - 1>>; 2 * B]
//     } else { () },
//     parent: *const Node<K, V, height + 1>,
//     parent_idx: u16,
//     len: u16,
// }
// ```
//
// Since Rust doesn't actually have dependent types and polymorphic recursion,
// we make do with lots of unsafety.
```

试着翻译成C++版本

```c++
constexpr const size_t B = ...;

template <typename K, typename V>
struct BTreeMap {
    size_t height; // constexpr const static size_t height = N;
    std::optional<Node<K, V, height>*> root; // 当然并不能这么做，height不是constant expression。
    // 疑应为
    // std::optional<Node<K, V, 0>*> root;
};

template <typename K, typename V, size_t height>
struct Node {
	K keys[2 * B - 1];
	V vals[2 * B - 1];
	using edges_t = std:conditional_t<height == 0, array<unique_ptr<Node<K, V, height + 1>>, 2 * B>, EmptyBase>;
	[[no_unique_address]] edge_t edges;
	Node<K, V, height - 1> const * const parent;
	uint16_t height;
	uint16_t height_idx;
	uint16_t len;
	//...
}
```

提到缺失了`dependent type` 和`polymorphic recursion`所以这样的设计无法实现



`dependent type`: 类型(type)依赖于项(term)，比较菜的例子cpp里的`std::array`(以及非类型模板参数`non-type template parameter`)和[`printf`](如何理解 dependent type？ - 张宏波的回答 - 知乎
https://www.zhihu.com/question/29706455/answer/173720551)。可参考[Lambda Cube](https://cs.stackexchange.com/questions/19053/does-types-being-terms-imply-your-dependend-theory-is-considered-polymorphic/19054#19054)和类型论的书，比如[TAPL](https://www.cis.upenn.edu/~bcpierce/tapl/)。高级例子详见支持`dependent type`的语言，比如`Idris`, `Adga` , `Coq`

* [RFC-2000](https://github.com/rust-lang/rfcs/pull/2000) 引入类似non-type template parameter的机制，叫const generics

  * ```rust
    struct RectangularArray<T, const WIDTH: usize, const HEIGHT: usize> {
        array: [[T; WIDTH]; HEIGHT],
    }
    
    const X: usize = 7;
    
    let x: RectangularArray<i32, 2, 4>;
    let y: RectangularArray<i32, X, {2 * 2}>;
    ```

* [#53645](https://github.com/rust-lang/rust/pull/53645) const-generics tracking issue



`polymorphic recursion`: 静态语言一般都不支持直接的`recursive type`，因为会造成无限大小的类。即使对每次递归不同的类型，像C++/Rust这样的无运行时/类型装箱的语言也有限制。rust使用了被称为[`monomorphisation `](https://stackoverflow.com/questions/14189604/what-is-monomorphisation-with-context-to-c)的技术来实现参数化多态(parameterized polymorphism)。和cpp的模板(template)一样，通过编译器实例化来实现零成本抽象(zero-cost abstraction)。但这样就可能造成编译器陷入无限递归。例子：

```rust
// 简单的Peano数在类型上的实现
trait Nat {
    fn value() -> i32;
}

struct Zero {}
struct Succ<T: Nat> {
    _marker: PhantomData<T>
}

impl Nat for Zero {
    fn value() -> i32 { 0 }
}

impl<T: Nat> Nat for Succ {
    fn value() -> i32 { 1 + T::value() }
}

<Succ<Succ<Zero>> as Nat>::value() // 2

// 或者简单的完全二叉树
enum PerfectBinaryTree<T> { Tip(T), Fork(Box<PerfectBinaryTree<(T, T)>>) }

// 或者Lisp-like List
enum Nil {Nil}
struct Cons<T> { head: i32, tail: T }
```

如果实例化一个很深的递归，编译器就无法承受(在cpp中，g++允许1024层递归，clang允许900层，MSVC 500层(2015以前)或2048层，g++/clang可调节`-ftemplate-depth`)。带运行时的语言可以通过[`boxing`](https://en.wikipedia.org/wiki/Object_type_(object-oriented_programming)#Boxing)来实现(Haskell, C#, Java...)。相关讨论:

* [Applications of polymorphic recursion](https://stackoverflow.com/questions/51093198/applications-of-polymorphic-recursion)
* [Polymorphic recursion - syntax and uses?](https://stackoverflow.com/questions/40247339/polymorphic-recursion-syntax-and-uses)
* [#4287](https://github.com/rust-lang/rust/issues/4287#issuecomment-11846582)



设计目的

```rust
// A major goal of this module is to avoid complexity by treating the tree as a generic (if
// weirdly shaped) container and avoiding dealing with most of the B-Tree invariants. As such,
// this module doesn't care whether the entries are sorted, which nodes can be underfull, or
// even what underfull means. However, we do rely on a few invariants:
//
// - Trees must have uniform depth/height. This means that every path down to a leaf from a
//   given node has exactly the same length.
// - A node of length `n` has `n` keys, `n` values, and (in an internal node) `n + 1` edges.
//   This implies that even an empty internal node has at least one edge.
```

不变量：

* 树等高，从根节点(root)到任意叶节点(leaf)的路径必定长度一致
* 长度为n的节点(node)有`n`个key, value, `n+1`条边



导入和常量

```rust
use core::marker::PhantomData;
use core::mem::{self, MaybeUninit};
use core::ptr::{self, Unique, NonNull};
use core::slice;

use alloc::{Global, Alloc, Layout};
use boxed::Box;

const B: usize = 6;							
pub const MIN_LEN: usize = B - 1;			// 每个node的k-v数下确界
pub const CAPACITY: usize = 2 * B - 1;		// 每个node的k-v数上确界
```

[#53491](https://github.com/rust-lang/rust/issues/53491), [RFC-1892](https://github.com/rust-lang/rfcs/pull/1892) 废弃`core::mem::{uninitalized, zeroed}`，使用`MaybeUninit<T>`代替

* [Understanding UB with std::mem::uninitialized](https://www.reddit.com/r/rust/comments/95vxdy/understanding_ub_with_stdmemuninitialized/)

  * > Basically, calling `mem::unitialized::<T>` is instant UB unless for `T` any bit pattern is valid. This is probably easiest to understand with uninhabited types. If you have an `enum Void {}` and then have `let x = mem::unitialized::<Void>()`, compiler is free to assume that the code is unreachable, because there can't be an instance of `Void`

  * > a reference to uninitialized memory is instant undefined behavior

  * > There *probably* will be a difference between `&mut T` and `&mut T as *mut T`, where `&mut T` creates a reference, but `&mut T as *mut T` is magical and creates a pointer directly without creating a reference first (sidestepping undefined behavior).



节点定义

```rust
// Internal(Non-leaf) Node
struct BoxedNode<K, V> {
    ptr: Unique<LeafNode<K, V>>
}

#[repr(C)]
struct InternalNode<K, V> {
    data: LeafNode<K, V>,
    edges: [BoxedNode<K, V>; 2 * B],
}

// Leaf Node
#[repr(C)]
struct NodeHeader<K, V, K2 = ()> {
    parent: *const InternalNode<K, V>,
    parent_idx: MaybeUninit<u16>,
    len: u16,
    keys_start: [K2; 0],
}

#[repr(C)]
struct LeafNode<K, V> {
    parent: *const InternalNode<K, V>,
    parent_idx: MaybeUninit<u16>,
    len: u16,
    keys: MaybeUninit<[K; CAPACITY]>,
    vals: MaybeUninit<[V; CAPACITY]>,
}
```

B树，内部节点也存储Key-Value。



`BoxedNode`封装一个持有资源所有权的节点（`Either<Box<LeafNode, InternalNode>>`)，但是不暴露实际节点类型。`InternalNode`使用`#[repr(C)]`使得直接转换到`LeafNode`是可行的（无需区分这两者）



`parent: *const InternalNode<K, V>`使用`const`因为`*const T` 是协变(covariant)的(`U <: T` => `*const U <: *const T`)，而`*mut T`是不变(invariant)的，这样可以利用`InternalNoe<K, V>`的协变特性 (在Scala中就是`U[+T], U[-T]`)。此外，`node.parent.edges[node.parent_idx] === node`。

![[来源](D:\OneDrive\Pictures\Typora\D%5COneDrive%5CPictures%5CTypora%5C1547413642145.png)](D:\OneDrive\Pictures\Typora\1547413642145.png)

* [variance in rust](https://medium.com/@kennytm/variance-in-rust-964134dd5b3e)

  * > **Transform** (*V* × *W*). Combines variances where the type constructors are composed.
    >
    > **GLB** (*V* ∧ *W*), short for greatest-lower-bound, also known as meet or infimum. Combines variances where two types form a tuple.
    >
    > **Aggregates** (tuples, struct, enum, union):  GLB of all fields]

  * Rust的子类型仅在生命周期/高阶函数指针(High-ranked function pointer)/Trait Object中出现，`Top = 'static | fn (⊥) -> ()|`

    * ```rust
      // 例子 @ref: https://doc.rust-lang.org/reference/subtyping.html
      
      // Here 'a is substituted for 'static
      let subtype: &(for<'a> fn(&'a i32) -> &'a i32) = &((|x| x) as fn(&_) -> &_);
      let supertype: &(fn(&'static i32) -> &'static i32) = subtype;
      
      // This works similarly for trait objects
      let subtype: &(for<'a> Fn(&'a i32) -> &'a i32) = &|x| x;
      let supertype: &(Fn(&'static i32) -> &'static i32) = subtype;
      
      // We can also substitute one higher-ranked lifetime for another
      let subtype: &(for<'a, 'b> fn(&'a i32, &'b i32))= &((|x, y| {}) as fn(&_, &_));
      let supertype: &for<'c> fn(&'c i32, &'c i32) = subtype;
      ```

* [understanding rust lifetimes](https://medium.com/nearprotocol/understanding-rust-lifetimes-e813bcd405fa)



`NodeHeader`作为一个哨兵节点(sentinel/dummy)，用`#[repr(C)]`保证没有编译器重排来和`LeafNode`相互转换。其他方案：

* `LeafNode`包含一个`NodeHeader`: `len`和`keys`之间会有额外的padding bits
* `LeafNode <: NodeHeader`: Rust没有自定义类的(user-defined struct)中的继承(inheritance/subtyping)



一个`EMPTY_ROOT_NODE`作为一个全局占位符(placeholder)来避免分配内存

```rust
static EMPTY_ROOT_NODE: NodeHeader<(), ()> = NodeHeader {
    parent: ptr::null(),
    parent_idx: MaybeUninit::uninitialized(),
    len: 0,
    keys_start: [],
};

impl<K, V> NodeHeader<K, V> {
    fn is_shared_root(&self) -> bool {
        ptr::eq(self, &EMPTY_ROOT_NODE as *const _ as *const _)
    }
}
```

两次`as`是分别做了一次[coercion](https://doc.rust-lang.org/nomicon/coercions.html)和一次[cast](https://doc.rust-lang.org/nomicon/casts.html)

* `&NodeHeader<(), ()>` to `*const NodeHeader<(), ()>`

* `*const NodeHeader<(), ()>` to `*const NodeHeader<K, V>`

* [related-question](https://stackoverflow.com/questions/34691267/why-would-it-be-necessary-to-perform-two-casts-to-a-mutable-raw-pointer-in-a-row) [related-question-2](https://stackoverflow.com/questions/50384395/why-does-casting-from-a-reference-to-a-c-void-pointer-require-a-double-cast)

* [Does unsafe Rust have strict aliasing rules?](https://www.reddit.com/r/rust/comments/73x370/does_unsafe_rust_have_strict_aliasing_rules/)

  * > only dereferencing it requires unsafe



[#54597](https://github.com/rust-lang/rust/issues/54957) 引入了`NodeHeader`和对齐检查，因为原先的实现实际上产生了未定义行为(undefined behavior)。原实现是`LeafNode<(),()>`，这会造成`&LeafNode<(),()>`转换成`&LeafNode<K, ()>`时无法维持约定(invariant)：`&T` is dereferencable for `mem::size_of::<T>`。在传给LLVM时，`dereferencable(n)`中`n`为这个`struct`的大小。

* [生成的LLVM IR](https://play.rust-lang.org/?gist=8c9fecbcecd4896eaa7d2a97686714da&version=nightly&mode=debug&edition=2015)

  * > ```
    > %"LeafNode<i32, ()>"* noalias readonly align 8 dereferenceable(56)
    > ```



对节点的引用

```rust
pub struct Root<K, V> {
    node: BoxedNode<K, V>,
    height: usize
}

pub struct NodeRef<BorrowType, K, V, Type> {
    height: usize,
    node: NonNull<LeafNode<K, V>>,
    root: *const Root<K, V>,
    _marker: PhantomData<(BorrowType, Type)>
}

impl<'a, K: 'a, V: 'a, Type> NodeRef<marker::Immut<'a>, K, V, Type> {
    fn into_key_slice(self) -> &'a [K] {
        if mem::align_of::<K>() > mem::align_of::<LeafNode<(), ()>>() && self.is_shared_root() {
            &[]
        } else {
            assert!(mem::size_of::<NodeHeader<K, V>>() == mem::size_of::<NodeHeader<K, V, K>>());
            let header = self.as_header() as *const _ as *const NodeHeader<K, V, K>;
            let keys = unsafe { &(*header).keys_start as *const _ as *const K };
            unsafe {
                slice::from_raw_parts(keys, self.len())
            }
        }
    }
 	//...
}

pub struct Handle<Node, Type> {
    node: Node,
    idx: usize,
    _marker: PhantomData<Type>
}
```

`NodeRef::BorrowType = marker::Immut<'a> | marker::Mut<'a> | marker::Owned` (对应`as_ref(&Self)`, `as_mut(&mut Self)`和`into_ref(Self)`)

* `fn foo(Self) -> Unrelated` 得到了`self`的所有权，所以`self`的生命周期在这个函数就结束了。

* `注意：即使`BorrowType == marker::Mut<'a>` 也不会像`&mut 'a T`一样是invariant，而保持`GLB(K ∧ V)



`NodeRef::Type = Leaf | Internal | LeafOrInternal`代表节点类型(也可能是NodeHeader)



如果这个`NodeRef`指向`NodeHeader`， 直接返回`&[]`是可行的，但是这需要一次运行时判断`is_shared_root()`。注意到，仅当`K`的对齐比`LeafNode<(),()>`的对齐要大(这是一次编译期计算)，导致`keys`的相对位置(offset)位于`NodeHeader`整个结构体大小之外，一个指向`EMPTY_ROOT_NODE`的`NodeRef`的`into_key_slice`才不能直接返回从地址

```rust
&(*self.as_header() as * const _ as *const NodeHeader<K, V, K>) as *const _ as *const K
```

开始的切片，所以将编译期比较在前，进行短路减少计算代价。

* [RFC-2582](https://github.com/rust-lang/rfcs/pull/2582) 加入获取`&[mut|const] raw <place>`来代替`&mut <place> as *[mut|const] _`
* 同上，具体讨论可见[#54597](https://github.com/rust-lang/rust/issues/54957)



`Handle::Type = marker::KV | marker::Edge`代表一个对键值对/边的引用。



B-Tree支持`split/merge/steal/bulk_steal`(overflow: 优先split(只split), underflow: 优先steal，通过`can_merge`判断)



`Root` -> `NodeRef` -> `Handle` -> 操作`Handle`来插入/删除



##### search.rs

```rust
pub enum SearchResult<BorrowType, K, V, FoundType, GoDownType> {
    Found(Handle<NodeRef<BorrowType, K, V, FoundType>, marker::KV>),
    GoDown(Handle<NodeRef<BorrowType, K, V, GoDownType>, marker::Edge>)
}
```

`search_linear` (`NodeRef`同一层) -> `search_node`-> `search_tree`



##### map.rs

[alloc::collections::btree_map::BTreeMap](https://doc.rust-lang.org/alloc/collections/btree_map/struct.BTreeMap.html)

首先介绍一下B-Tree

```rust
/// B-Trees represent a fundamental compromise between cache-efficiency and actually minimizing
/// the amount of work performed in a search. In theory, a binary search tree (BST) is the optimal
/// choice for a sorted map, as a perfectly balanced BST performs the theoretical minimum amount of
/// comparisons necessary to find an element (log<sub>2</sub>n). However, in practice the way this
/// is done is *very* inefficient for modern computer architectures. In particular, every element
/// is stored in its own individually heap-allocated node. This means that every single insertion
/// triggers a heap-allocation, and every single comparison should be a cache-miss. Since these
/// are both notably expensive things to do in practice, we are forced to at very least reconsider
/// the BST strategy.
///
/// A B-Tree instead makes each node contain B-1 to 2B-1 elements in a contiguous array. By doing
/// this, we reduce the number of allocations by a factor of B, and improve cache efficiency in
/// searches. However, this does mean that searches will have to do *more* comparisons on average.
/// The precise number of comparisons depends on the node search strategy used. For optimal cache
/// efficiency, one could search the nodes linearly. For optimal comparisons, one could search
/// the node using binary search. As a compromise, one could also perform a linear search
/// that initially only checks every i<sup>th</sup> element for some choice of i.
///
/// Currently, our implementation simply performs naive linear search. This provides excellent
/// performance on *small* nodes of elements which are cheap to compare. However in the future we
/// would like to further explore choosing the optimal search strategy based on the choice of B,
/// and possibly other factors. Using linear search, searching for a random element is expected
/// to take O(B log<sub>B</sub>n) comparisons, which is generally worse than a BST. In practice,
/// however, performance is excellent.
```

B树代表了在缓存效率(cache-efficiency)和最小化搜索计算量之间一种基本的妥协。尽管完全平衡的二叉平衡树(BST)在理论中对查询操作能达到最少的比较次数($O(\log_2n)$)，但是在现在的计算机架构中，二叉平衡树是一种低效率的实现，因为所有元素都被储存在单独的堆分配的节点中。这就意味着，每次插入都会造成新的堆内存分配，并且每次比较都会造成cache-miss。

B树的每个节点存放$[B-1, 2B-1]$个元素，将分配次数减小到$1/B$，并提高了缓存效率。但这会增加搜索的比较次数。搜索的比较次数依赖于寻找节点的策略:

* 线性查找：达到最佳缓存效率 比较次数$O(B log_B(n))$
* 二分查找：达到最少比较次数



```rust
#[stable(feature = "rust1", since = "1.0.0")]
pub struct BTreeMap<K, V> {
    root: node::Root<K, V>,
    length: usize,
}

#[stable(feature = "rust1", since = "1.0.0")]
pub struct Iter<'a, K: 'a, V: 'a> {
    range: Range<'a, K, V>,
    length: usize,
}

#[stable(feature = "rust1", since = "1.0.0")]
#[derive(Debug)]
pub struct IterMut<'a, K: 'a, V: 'a> {
    range: RangeMut<'a, K, V>,
    length: usize,
}

// 手动Drop
#[stable(feature = "btree_drop", since = "1.7.0")]
unsafe impl<#[may_dangle] K, #[may_dangle] V> Drop for BTreeMap<K, V> {
    fn drop(&mut self) {
        unsafe {
            drop(ptr::read(self).into_iter());
        }
    }
}

#[stable(feature = "btree_drop", since = "1.7.0")]
impl<K, V> Drop for IntoIter<K, V> {
    fn drop(&mut self) {
        self.for_each(drop);
        unsafe {
            let leaf_node = ptr::read(&self.front).into_node();
            if leaf_node.is_shared_root() {
                return;
            }

            if let Some(first_parent) = leaf_node.deallocate_and_ascend() {
                let mut cur_node = first_parent.into_node();
                while let Some(parent) = cur_node.deallocate_and_ascend() {
                    cur_node = parent.into_node()
                }
            }
        }
    }
}

enum UnderflowResult<'a, K, V> {
    AtRoot,
    EmptyParent(NodeRef<marker::Mut<'a>, K, V, marker::Internal>),
    Merged(NodeRef<marker::Mut<'a>, K, V, marker::Internal>),
    Stole(NodeRef<marker::Mut<'a>, K, V, marker::Internal>),
}

//...
```

小于`MIN_LEN`时，首先判断(`can_merge`)能否通过重排(redistribution/stole)解决，否则进行`merge`



`#[may_dangle]` 断言(assert)在这个析构器(destructor)中这个类型的值/生命周期可能已经expired，所以在析构器中不会访问相关的值。

```rust
#![feature(dropck_eyepatch)]

struct Inspector<'a, 'b, T, U: Display>(&'a u8, &'b u8, T, U);

// 似乎还没有实现...
unsafe impl<'a, #[may_dangle] 'b, #[may_dangle] T, U: Display> Drop for Inspector<'a, 'b, T, U> {
    fn drop(&mut self) {
        println!("Inspector({}, _, _, {})", self.0, self.3);
    }
}
```

* [RFC-1327](https://github.com/rust-lang/rfcs/blob/master/text/1327-dropck-param-eyepatch.md) 提议Drop检查(`dropck_eyepatch`)
* [#34761](https://github.com/rust-lang/rust/issues/34761)



```rust
#[stable(feature = "rust1", since = "1.0.0")]
pub enum Entry<'a, K: 'a, V: 'a> {
    /// A vacant entry.
    #[stable(feature = "rust1", since = "1.0.0")]
    Vacant(#[stable(feature = "rust1", since = "1.0.0")]
           VacantEntry<'a, K, V>),

    /// An occupied entry.
    #[stable(feature = "rust1", since = "1.0.0")]
    Occupied(#[stable(feature = "rust1", since = "1.0.0")]
             OccupiedEntry<'a, K, V>),
}

impl<K, V> for BTreeMap<K, V> {
        #[stable(feature = "rust1", since = "1.0.0")]
    pub fn entry(&mut self, key: K) -> Entry<K, V> {
        // FIXME(@porglezomp) Avoid allocating if we don't insert
        self.ensure_root_is_owned();
        match search::search_tree(self.root.as_mut(), &key) {
            Found(handle) => {
                Occupied(OccupiedEntry {
                    handle,
                    length: &mut self.length,
                    _marker: PhantomData,
                })
            }
            GoDown(handle) => {
                Vacant(VacantEntry {
                    key,
                    handle,
                    length: &mut self.length,
                    _marker: PhantomData,
                })
            }
        }
    }
}
```

Entry pattern， 解决对如下代码造成的可变借用两次的问题

```rust
// @ref: https://zhuanlan.zhihu.com/p/25429005
fn process_or_default<K,V:Default>
    (map: &mut HashMap<K,V>, key: K) 
{
    match map.get_mut(&key) { // -------------+ 'lifetime
        Some(value) => process(value),     // |
        None => {                          // |
            map.insert(key, V::default()); // |
            //  ^~~~~~ ERROR.              // |
        }                                  // |
    } // <------------------------------------+
}

// Workaround，但是做了两次查找
if map.contains_key(&key) {
    *map.find_mut(&key).unwrap() += 1;
} else {
    map.insert(key, 1);
}
```

* [Non Lexical Lifetime](https://zhuanlan.zhihu.com/p/25429005)
* [Want to add to HashMap using pattern match, get borrow mutable more than once at a time](https://stackoverflow.com/questions/30851464/want-to-add-to-hashmap-using-pattern-match-get-borrow-mutable-more-than-once-at)
* [RFC-216](https://github.com/rust-lang/rfcs/blob/master/text/0216-collection-views.md) / [RFC-921](https://github.com/rust-lang/rfcs/pull/921)
* [Patterns-Entry](https://github.com/rust-unofficial/patterns/blob/master/patterns/entry.md )



##### set.rs

```rust
#[derive(Clone, Hash, PartialEq, Eq, Ord, PartialOrd)]
#[stable(feature = "rust1", since = "1.0.0")]
pub struct BTreeSet<T> {
    map: BTreeMap<T, ()>,
}

#[stable(feature = "rust1", since = "1.0.0")]
pub struct Iter<'a, T: 'a> {
    iter: Keys<'a, T, ()>,
}

#[stable(feature = "rust1", since = "1.0.0")]
#[derive(Debug)]
pub struct IntoIter<T> {
    iter: btree_map::IntoIter<T, ()>,
}

#[derive(Debug)]
#[stable(feature = "btree_range", since = "1.17.0")]
pub struct Range<'a, T: 'a> {
    iter: btree_map::Range<'a, T, ()>,
}

#[stable(feature = "rust1", since = "1.0.0")]
pub struct Difference<'a, T: 'a> {
    a: Peekable<Iter<'a, T>>,
    b: Peekable<Iter<'a, T>>,
}

#[stable(feature = "rust1", since = "1.0.0")]
pub struct SymmetricDifference<'a, T: 'a> {
    a: Peekable<Iter<'a, T>>,
    b: Peekable<Iter<'a, T>>,
}

#[stable(feature = "rust1", since = "1.0.0")]
pub struct Intersection<'a, T: 'a> {
    a: Peekable<Iter<'a, T>>,
    b: Peekable<Iter<'a, T>>,
}

#[stable(feature = "rust1", since = "1.0.0")]
pub struct Union<'a, T: 'a> {
    a: Peekable<Iter<'a, T>>,
    b: Peekable<Iter<'a, T>>,
}
```

一个`BTreeSet<T>`实际上就是`BTreeMap<T, ()>`，并实现各种操作的Trait和对应的迭代器

[alloc::collections::btree_map::BTreeSet](https://doc.rust-lang.org/alloc/collections/btree_set/struct.BTreeSet.html)



#### binary_heap.rs

用二叉堆(binary heap)实现的优先队列(priority queue)。最大堆

[alloc::collections::binary_heap::BinaryHeap](https://doc.rust-lang.org/alloc/collections/binary_heap/struct.BinaryHeap.html)

```rust
#[stable(feature = "rust1", since = "1.0.0")]
pub struct BinaryHeap<T> {
    data: Vec<T>,
}

// ...

#[stable(feature = "binary_heap_peek_mut", since = "1.12.0")]
pub struct PeekMut<'a, T: 'a + Ord> {
    heap: &'a mut BinaryHeap<T>,
    sift: bool,
}

#[stable(feature = "binary_heap_peek_mut", since = "1.12.0")]
impl<'a, T: Ord> Drop for PeekMut<'a, T> {
    fn drop(&mut self) {
        if self.sift {
            self.heap.sift_down(0);
        }
    }
}


#[stable(feature = "binary_heap_peek_mut", since = "1.12.0")]
impl<'a, T: Ord> Deref for PeekMut<'a, T> {
    type Target = T;
    fn deref(&self) -> &T {
        &self.heap.data[0]
    }
}

#[stable(feature = "binary_heap_peek_mut", since = "1.12.0")]
impl<'a, T: Ord> DerefMut for PeekMut<'a, T> {
    fn deref_mut(&mut self) -> &mut T {
        &mut self.heap.data[0]
    }
}

impl<'a, T: Ord> PeekMut<'a, T> {
    #[stable(feature = "binary_heap_peek_mut_pop", since = "1.18.0")]
    pub fn pop(mut this: PeekMut<'a, T>) -> T {
        let value = this.heap.pop().unwrap();
        this.sift = false;
        value
    }
}

// 消耗性的迭代器，Vec::Drain
#[stable(feature = "drain", since = "1.6.0")]
#[derive(Debug)]
pub struct Drain<'a, T: 'a> {
    iter: vec::Drain<'a, T>,
}

struct Hole<'a, T: 'a> {
    data: &'a mut [T],
    elt: ManuallyDrop<T>,
    pos: usize,
}

impl<T: Ord> BinaryHeap<T> {
    fn sift_up(&mut self, start: usize, pos: usize) -> usize {
        unsafe {
            let mut hole = Hole::new(&mut self.data, pos);

            while hole.pos() > start {
                let parent = (hole.pos() - 1) / 2;
                if hole.element() <= hole.get(parent) {
                    break;
                }
                hole.move_to(parent);  // 将parent数据写入当前位置，并更新
            }
            hole.pos()
        }
    }

    fn sift_down_range(&mut self, pos: usize, end: usize) {
        unsafe {
            let mut hole = Hole::new(&mut self.data, pos);
            let mut child = 2 * pos + 1;
            while child < end {
                let right = child + 1;
                if right < end && !(hole.get(child) > hole.get(right)) {
                    child = right;
                }
                if hole.element() >= hole.get(child) {
                    break;
                }
                hole.move_to(child);
                child = 2 * hole.pos() + 1;
            }
        }
    }

    fn sift_down(&mut self, pos: usize) {
        let len = self.len();
        self.sift_down_range(pos, len);
    }

    fn sift_down_to_bottom(&mut self, mut pos: usize) {
        let end = self.len();
        let start = pos;
        unsafe {
            let mut hole = Hole::new(&mut self.data, pos);
            let mut child = 2 * pos + 1;
            while child < end {
                let right = child + 1;
                if right < end && !(hole.get(child) > hole.get(right)) {
                    child = right;
                }
                hole.move_to(child);
                child = 2 * hole.pos() + 1;
            }
            pos = hole.pos;
        }
        self.sift_up(start, pos);
    }
    
    #[stable(feature = "binary_heap_append", since = "1.11.0")]
    pub fn append(&mut self, other: &mut Self) {
        if self.len() < other.len() {
            swap(self, other);
        }

        if other.is_empty() {
            return;
        }

        // 简单的log2实现 (bit-scan-reverse)
        #[inline(always)]
        fn log2_fast(x: usize) -> usize {
            8 * size_of::<usize>() - (x.leading_zeros() as usize) - 1
        }

        #[inline]
        fn better_to_rebuild(len1: usize, len2: usize) -> bool {
            2 * (len1 + len2) < len2 * log2_fast(len1)
        }

        if better_to_rebuild(self.len(), other.len()) {
            self.data.append(&mut other.data);
            self.rebuild();
        } else {
            self.extend(other.drain());
        }
    }
}

```

`PeekMut`是一个`BinaryHeap.peek_mut()`返回的引用(reference)。可修改(`Deref` ，`DerefMut`, 这时析构会向下调整堆`sift_down`)，可pop (这时不会调整堆)

[#38863](https://github.com/rust-lang/rust/issues/38863) 解释了这里是`pub fn foo(mut this)`的原因：因为`PeekMut`有`Deref` trait，它不应该有任何方法`method`，`peek_mut.pop()`会直接调用`T::foo(&self)`

* `mut id: T === id: mut T`
* [Deref-Coercion](https://doc.rust-lang.org/book/ch15-02-deref.html) `&mut PeekMut<_, _>` -> `&mut T`

```rust
use std::collections::BinaryHeap;
use std::collections::binary_heap::PeekMut;

#[derive(Ord, PartialOrd, Eq, PartialEq)]
struct Foo {}

impl Foo {
    fn pop(&mut self) -> i32 {
        1
    }
}

fn main(){
    let mut heap = BinaryHeap::new();
    heap.push(Foo{});
    {
        let mut p: PeekMut<_> = heap.peek_mut().unwrap();
        *p = Foo{};
        let v = p.pop();  // Call Foo::pop(&self)
        // let v = PeekMut::pop(p);
    }
}

```



用`Hole`结构体来代表`data`中一个无效的项(可能被`moved`或者`duplicated`)，析构时，`Hole`会将``elt`中的原内容`copy_nonoverlapping`（`memcpy`）回原数据项。这相对于`swap`减少了`move`的数量。



在`append`的时候，有两种选择 ($len_1 \geq len_2$)

* `rebuild`： $O(len_1+len_2)$次操作，最坏情况`2(len_1+len_2)`次比较
* `extend`： $O(len_2 \log_2(len_1))$次操作，最坏情况`len_2\log_2(len_1)`次比较



`ManuallyDrop`阻止编译器自动调用`T`的析构器



#### linked_list.rs

双端链表(double-linked list) [alloc::collections::linked_list::LinkedList](https://doc.rust-lang.org/alloc/collections/linked_list/struct.LinkedList.html)

```rust
#[stable(feature = "rust1", since = "1.0.0")]
pub struct LinkedList<T> {
    head: Option<NonNull<Node<T>>>,
    tail: Option<NonNull<Node<T>>>,
    len: usize,
    marker: PhantomData<Box<Node<T>>>,
}

struct Node<T> {
    next: Option<NonNull<Node<T>>>,
    prev: Option<NonNull<Node<T>>>,
    element: T,
}

#[stable(feature = "rust1", since = "1.0.0")]
pub struct Iter<'a, T: 'a> {
    head: Option<NonNull<Node<T>>>,
    tail: Option<NonNull<Node<T>>>,
    len: usize,
    marker: PhantomData<&'a Node<T>>,
}

#[stable(feature = "rust1", since = "1.0.0")]
pub struct IterMut<'a, T: 'a> {
    list: &'a mut LinkedList<T>,
    head: Option<NonNull<Node<T>>>,
    tail: Option<NonNull<Node<T>>>,
    len: usize,
}

#[unstable(feature = "drain_filter", reason = "recently added", issue = "43244")]
pub struct DrainFilter<'a, T: 'a, F: 'a>
    where F: FnMut(&mut T) -> bool,
{
    list: &'a mut LinkedList<T>,
    it: Option<NonNull<Node<T>>>,
    pred: F,
    idx: usize,
    old_len: usize,
}

// 保证LinkedList<T>/Iter<T>/IntoIter<T>中T的生命周期是协变的
#[allow(dead_code)]
fn assert_covariance() {
    fn a<'a>(x: LinkedList<&'static str>) -> LinkedList<&'a str> {
        x
    }
    fn b<'i, 'a>(x: Iter<'i, &'static str>) -> Iter<'i, &'a str> {
        x
    }
    fn c<'a>(x: IntoIter<&'static str>) -> IntoIter<&'a str> {
        x
    }
}
```



[`PhantomData`](https://doc.rust-lang.org/nomicon/phantom-data.html) 是零成本的编译器提示，用于使未绑定(unbounded)的类型、生命周期和Drop check的提示。使用`PhantomData<T>`如同持有一个`T`类型的实例。

* `PhantomData<T>`表示在析构时，一个或多个`T`的实例(instance)可能被析构，在[drop check](https://doc.rust-lang.org/nomicon/dropck.html)中被用到。

* [Why is it useful to use PhantomData to inform the compiler that a struct owns a generic if I already implement Drop?](https://stackoverflow.com/questions/42708462/why-is-it-useful-to-use-phantomdata-to-inform-the-compiler-that-a-struct-owns-a) 详细解释了`Vec<T>`中`PhantomData<T>`对编译器的作用

  * ```rust
    struct Vec<T> {
        data: *const T, // *const for variance!
        len: usize,
        cap: usize,
        _marker: marker::PhantomData<T>,
    }
    ```



[#43244](https://github.com/rust-lang/rust/issues/43244) 提供了`drain_filter(&self, F)`，即有条件的消耗性的迭代器(对Python`generator/iterator`)。



#### vec_deque.rs

双端队列(double-ended queue)，由可增长的环形缓冲(growable ring buffer/vector)实现(cpp中，是`LinkedList<[T; N]>`)。

```rust
const INITIAL_CAPACITY: usize = 7;
const MINIMUM_CAPACITY: usize = 1;
#[cfg(target_pointer_width = "16")]
const MAXIMUM_ZST_CAPACITY: usize = 1 << (16 - 1); 
#[cfg(target_pointer_width = "32")]
const MAXIMUM_ZST_CAPACITY: usize = 1 << (32 - 1); 
#[cfg(target_pointer_width = "64")]
const MAXIMUM_ZST_CAPACITY: usize = 1 << (64 - 1);
```

`MAXIMUM_ZST_CAPACITY`指的是`mem::size_of::<T> == 0`时候的容量(capacity)。



`INITIAL_CAPACITY`是`VecQueue<T>`的默认初始容量，`MINIMUM_CAPACITY`是`VecQueue<T>`的最低容量。容量一定是$2^n$留有1个空位，并且第`index`的元素位于`buf[(self.tail + index) & (cap - 1)]`。所以环形缓冲区相当于一个增长因子=2的`RawVec<T>`。



```rust
pub struct VecDeque<T> {
    tail: usize, // 第一个能读的元素
    head: usize, // 写入位置
    buf: RawVec<T>, // 一定是2^n大小
}

impl<T> VecDeque<T> {
    // wrap：折叠，指ring buffer越过end
    unsafe fn wrap_copy(&self, dst: usize, src: usize, len: usize) {
        #[allow(dead_code)]
        fn diff(a: usize, b: usize) -> usize {
            if a <= b { b - a } else { a - b }
        }
        debug_assert!(cmp::min(diff(dst, src), self.cap() - diff(dst, src)) + len <= self.cap(),
                      "wrc dst={} src={} len={} cap={}",
                      dst,
                      src,
                      len,
                      self.cap());

        if src == dst || len == 0 {
            return;
        }

        let dst_after_src = self.wrap_sub(dst, src) < len;

        let src_pre_wrap_len = self.cap() - src;
        let dst_pre_wrap_len = self.cap() - dst;
        let src_wraps = src_pre_wrap_len < len;
        let dst_wraps = dst_pre_wrap_len < len;

        match (dst_after_src, src_wraps, dst_wraps) {
            (_, false, false) => {
                // src doesn't wrap, dst doesn't wrap
                //
                //        S . . .
                // 1 [_ _ A A B B C C _]
                // 2 [_ _ A A A A B B _]
                //            D . . .
                //
                self.copy(dst, src, len);
            }
            (false, false, true) => {
                // dst before src, src doesn't wrap, dst wraps
                //
                //    S . . .
                // 1 [A A B B _ _ _ C C]
                // 2 [A A B B _ _ _ A A]
                // 3 [B B B B _ _ _ A A]
                //    . .           D .
                //
                self.copy(dst, src, dst_pre_wrap_len);
                self.copy(0, src + dst_pre_wrap_len, len - dst_pre_wrap_len);
            }
            (true, false, true) => {
                // src before dst, src doesn't wrap, dst wraps
                //
                //              S . . .
                // 1 [C C _ _ _ A A B B]
                // 2 [B B _ _ _ A A B B]
                // 3 [B B _ _ _ A A A A]
                //    . .           D .
                //
                self.copy(0, src + dst_pre_wrap_len, len - dst_pre_wrap_len);
                self.copy(dst, src, dst_pre_wrap_len);
            }
            (false, true, false) => {
                // dst before src, src wraps, dst doesn't wrap
                //
                //    . .           S .
                // 1 [C C _ _ _ A A B B]
                // 2 [C C _ _ _ B B B B]
                // 3 [C C _ _ _ B B C C]
                //              D . . .
                //
                self.copy(dst, src, src_pre_wrap_len);
                self.copy(dst + src_pre_wrap_len, 0, len - src_pre_wrap_len);
            }
            (true, true, false) => {
                // src before dst, src wraps, dst doesn't wrap
                //
                //    . .           S .
                // 1 [A A B B _ _ _ C C]
                // 2 [A A A A _ _ _ C C]
                // 3 [C C A A _ _ _ C C]
                //    D . . .
                //
                self.copy(dst + src_pre_wrap_len, 0, len - src_pre_wrap_len);
                self.copy(dst, src, src_pre_wrap_len);
            }
            (false, true, true) => {
                // dst before src, src wraps, dst wraps
                //
                //    . . .         S .
                // 1 [A B C D _ E F G H]
                // 2 [A B C D _ E G H H]
                // 3 [A B C D _ E G H A]
                // 4 [B C C D _ E G H A]
                //    . .         D . .
                //
                debug_assert!(dst_pre_wrap_len > src_pre_wrap_len);
                let delta = dst_pre_wrap_len - src_pre_wrap_len;
                self.copy(dst, src, src_pre_wrap_len);
                self.copy(dst + src_pre_wrap_len, 0, delta);
                self.copy(0, delta, len - dst_pre_wrap_len);
            }
            (true, true, true) => {
                // src before dst, src wraps, dst wraps
                //
                //    . .         S . .
                // 1 [A B C D _ E F G H]
                // 2 [A A B D _ E F G H]
                // 3 [H A B D _ E F G H]
                // 4 [H A B D _ E F F G]
                //    . . .         D .
                //
                debug_assert!(src_pre_wrap_len > dst_pre_wrap_len);
                let delta = src_pre_wrap_len - dst_pre_wrap_len;
                self.copy(delta, 0, len - src_pre_wrap_len);
                self.copy(0, self.cap() - delta, delta);
                self.copy(dst, src, dst_pre_wrap_len);
            }
        }
    }
    
    // Unsafe because it trusts old_cap.
    #[inline]
    unsafe fn handle_cap_increase(&mut self, old_cap: usize) {
        let new_cap = self.cap();

        // Move the shortest contiguous section of the ring buffer
        //    T             H
        //   [o o o o o o o . ]
        //    T             H
        // A [o o o o o o o . . . . . . . . . ]
        //        H T
        //   [o o . o o o o o ]
        //          T             H
        // B [. . . o o o o o o o . . . . . . ]
        //              H T
        //   [o o o o o . o o ]
        //              H                 T
        // C [o o o o o . . . . . . . . . o o ]

        if self.tail <= self.head {
            // A
            // Nop
        } else if self.head < old_cap - self.tail {
            // B
            self.copy_nonoverlapping(old_cap, 0, self.head);
            self.head += old_cap;
            debug_assert!(self.head > self.tail);
        } else {
            // C
            let new_tail = new_cap - (old_cap - self.tail);
            self.copy_nonoverlapping(new_tail, self.tail, old_cap - self.tail);
            self.tail = new_tail;
            debug_assert!(self.head < self.tail);
        }
        debug_assert!(self.head < self.cap());
        debug_assert!(self.tail < self.cap());
        debug_assert!(self.cap().count_ones() == 1);
    }
    
    #[unstable(feature = "shrink_to", reason = "new API", issue="56431")]
    pub fn shrink_to(&mut self, min_capacity: usize) {
        assert!(self.capacity() >= min_capacity, "Tried to shrink to a larger capacity");

        let target_cap = cmp::max(
            cmp::max(min_capacity, self.len()) + 1,
            MINIMUM_CAPACITY + 1
        ).next_power_of_two();

        if target_cap < self.cap() {
            let head_outside = self.head == 0 || self.head >= target_cap;
            if self.tail >= target_cap && head_outside {
                //                    T             H
                //   [. . . . . . . . o o o o o o o . ]
                //    T             H
                //   [o o o o o o o . ]
                unsafe {
                    self.copy_nonoverlapping(0, self.tail, self.len());
                }
                self.head = self.len();
                self.tail = 0;
            } else if self.tail != 0 && self.tail < target_cap && head_outside {
                //          T             H
                //   [. . . o o o o o o o . . . . . . ]
                //        H T
                //   [o o . o o o o o ]
                let len = self.wrap_sub(self.head, target_cap);
                unsafe {
                    self.copy_nonoverlapping(0, target_cap, len);
                }
                self.head = len;
                debug_assert!(self.head < self.tail);
            } else if self.tail >= target_cap {
                //              H                 T
                //   [o o o o o . . . . . . . . . o o ]
                //              H T
                //   [o o o o o . o o ]
                debug_assert!(self.wrap_sub(self.head, 1) < target_cap);
                let len = self.cap() - self.tail;
                let new_tail = target_cap - len;
                unsafe {
                    self.copy_nonoverlapping(new_tail, self.tail, len);
                }
                self.tail = new_tail;
                debug_assert!(self.head < self.tail);
            }

            self.buf.shrink_to_fit(target_cap);

            debug_assert!(self.head < self.cap());
            debug_assert!(self.tail < self.cap());
            debug_assert!(self.cap().count_ones() == 1);
        }
    }
    
    #[stable(feature = "deque_extras_15", since = "1.5.0")]
    pub fn insert(&mut self, index: usize, value: T) {
        assert!(index <= self.len(), "index out of bounds");
        self.grow_if_necessary();

        // Move the least number of elements in the ring buffer and insert
        // the given object
        //
        // At most len/2 - 1 elements will be moved. O(min(n, n-i))
        //
        // There are three main cases:
        //  Elements are contiguous
        //      - special case when tail is 0
        //  Elements are discontiguous and the insert is in the tail section
        //  Elements are discontiguous and the insert is in the head section
        //
        // For each of those there are two more cases:
        //  Insert is closer to tail
        //  Insert is closer to head
        //
        // Key: H - self.head
        //      T - self.tail
        //      o - Valid element
        //      I - Insertion element
        //      A - The element that should be after the insertion point
        //      M - Indicates element was moved

        let idx = self.wrap_add(self.tail, index);

        let distance_to_tail = index;
        let distance_to_head = self.len() - index;

        let contiguous = self.is_contiguous();

        match (contiguous, distance_to_tail <= distance_to_head, idx >= self.tail) {
            (true, true, _) if index == 0 => {
                // push_front
                //
                //       T
                //       I             H
                //      [A o o o o o o . . . . . . . . .]
                //
                //                       H         T
                //      [A o o o o o o o . . . . . I]
                //

                self.tail = self.wrap_sub(self.tail, 1);
            }
            (true, true, _) => {
                unsafe {
                    // contiguous, insert closer to tail:
                    //
                    //             T   I         H
                    //      [. . . o o A o o o o . . . . . .]
                    //
                    //           T               H
                    //      [. . o o I A o o o o . . . . . .]
                    //           M M
                    //
                    // contiguous, insert closer to tail and tail is 0:
                    //
                    //
                    //       T   I         H
                    //      [o o A o o o o . . . . . . . . .]
                    //
                    //                       H             T
                    //      [o I A o o o o o . . . . . . . o]
                    //       M                             M

                    let new_tail = self.wrap_sub(self.tail, 1);

                    self.copy(new_tail, self.tail, 1);
                    // Already moved the tail, so we only copy `index - 1` elements.
                    self.copy(self.tail, self.tail + 1, index - 1);

                    self.tail = new_tail;
                }
            }
            (true, false, _) => {
                unsafe {
                    //  contiguous, insert closer to head:
                    //
                    //             T       I     H
                    //      [. . . o o o o A o o . . . . . .]
                    //
                    //             T               H
                    //      [. . . o o o o I A o o . . . . .]
                    //                       M M M

                    self.copy(idx + 1, idx, self.head - idx);
                    self.head = self.wrap_add(self.head, 1);
                }
            }
            (false, true, true) => {
                unsafe {
                    // discontiguous, insert closer to tail, tail section:
                    //
                    //                   H         T   I
                    //      [o o o o o o . . . . . o o A o o]
                    //
                    //                   H       T
                    //      [o o o o o o . . . . o o I A o o]
                    //                           M M

                    self.copy(self.tail - 1, self.tail, index);
                    self.tail -= 1;
                }
            }
            (false, false, true) => {
                unsafe {
                    // discontiguous, insert closer to head, tail section:
                    //
                    //           H             T         I
                    //      [o o . . . . . . . o o o o o A o]
                    //
                    //             H           T
                    //      [o o o . . . . . . o o o o o I A]
                    //       M M M                         M

                    // copy elements up to new head
                    self.copy(1, 0, self.head);

                    // copy last element into empty spot at bottom of buffer
                    self.copy(0, self.cap() - 1, 1);

                    // move elements from idx to end forward not including ^ element
                    self.copy(idx + 1, idx, self.cap() - 1 - idx);

                    self.head += 1;
                }
            }
            (false, true, false) if idx == 0 => {
                unsafe {
                    // discontiguous, insert is closer to tail, head section,
                    // and is at index zero in the internal buffer:
                    //
                    //       I                   H     T
                    //      [A o o o o o o o o o . . . o o o]
                    //
                    //                           H   T
                    //      [A o o o o o o o o o . . o o o I]
                    //                               M M M

                    // copy elements up to new tail
                    self.copy(self.tail - 1, self.tail, self.cap() - self.tail);

                    // copy last element into empty spot at bottom of buffer
                    self.copy(self.cap() - 1, 0, 1);

                    self.tail -= 1;
                }
            }
            (false, true, false) => {
                unsafe {
                    // discontiguous, insert closer to tail, head section:
                    //
                    //             I             H     T
                    //      [o o o A o o o o o o . . . o o o]
                    //
                    //                           H   T
                    //      [o o I A o o o o o o . . o o o o]
                    //       M M                     M M M M

                    // copy elements up to new tail
                    self.copy(self.tail - 1, self.tail, self.cap() - self.tail);

                    // copy last element into empty spot at bottom of buffer
                    self.copy(self.cap() - 1, 0, 1);

                    // move elements from idx-1 to end forward not including ^ element
                    self.copy(0, 1, idx - 1);

                    self.tail -= 1;
                }
            }
            (false, false, false) => {
                unsafe {
                    // discontiguous, insert closer to head, head section:
                    //
                    //               I     H           T
                    //      [o o o o A o o . . . . . . o o o]
                    //
                    //                     H           T
                    //      [o o o o I A o o . . . . . o o o]
                    //                 M M M

                    self.copy(idx + 1, idx, self.head - idx);
                    self.head += 1;
                }
            }
        }

        // tail might've been changed so we need to recalculate
        let new_idx = self.wrap_add(self.tail, index);
        unsafe {
            self.buffer_write(new_idx, value);
        }
    }
    
    #[stable(feature = "rust1", since = "1.0.0")]
    pub fn remove(&mut self, index: usize) -> Option<T> {
        if self.is_empty() || self.len() <= index {
            return None;
        }

        // There are three main cases:
        //  Elements are contiguous
        //  Elements are discontiguous and the removal is in the tail section
        //  Elements are discontiguous and the removal is in the head section
        //      - special case when elements are technically contiguous,
        //        but self.head = 0
        //
        // For each of those there are two more cases:
        //  Insert is closer to tail
        //  Insert is closer to head
        //
        // Key: H - self.head
        //      T - self.tail
        //      o - Valid element
        //      x - Element marked for removal
        //      R - Indicates element that is being removed
        //      M - Indicates element was moved

        let idx = self.wrap_add(self.tail, index);

        let elem = unsafe { Some(self.buffer_read(idx)) };

        let distance_to_tail = index;
        let distance_to_head = self.len() - index;

        let contiguous = self.is_contiguous();

        match (contiguous, distance_to_tail <= distance_to_head, idx >= self.tail) {
            (true, true, _) => {
                unsafe {
                    // contiguous, remove closer to tail:
                    //
                    //             T   R         H
                    //      [. . . o o x o o o o . . . . . .]
                    //
                    //               T           H
                    //      [. . . . o o o o o o . . . . . .]
                    //               M M

                    self.copy(self.tail + 1, self.tail, index);
                    self.tail += 1;
                }
            }
            (true, false, _) => {
                unsafe {
                    // contiguous, remove closer to head:
                    //
                    //             T       R     H
                    //      [. . . o o o o x o o . . . . . .]
                    //
                    //             T           H
                    //      [. . . o o o o o o . . . . . . .]
                    //                     M M

                    self.copy(idx, idx + 1, self.head - idx - 1);
                    self.head -= 1;
                }
            }
            (false, true, true) => {
                unsafe {
                    // discontiguous, remove closer to tail, tail section:
                    //
                    //                   H         T   R
                    //      [o o o o o o . . . . . o o x o o]
                    //
                    //                   H           T
                    //      [o o o o o o . . . . . . o o o o]
                    //                               M M

                    self.copy(self.tail + 1, self.tail, index);
                    self.tail = self.wrap_add(self.tail, 1);
                }
            }
            (false, false, false) => {
                unsafe {
                    // discontiguous, remove closer to head, head section:
                    //
                    //               R     H           T
                    //      [o o o o x o o . . . . . . o o o]
                    //
                    //                   H             T
                    //      [o o o o o o . . . . . . . o o o]
                    //               M M

                    self.copy(idx, idx + 1, self.head - idx - 1);
                    self.head -= 1;
                }
            }
            (false, false, true) => {
                unsafe {
                    // discontiguous, remove closer to head, tail section:
                    //
                    //             H           T         R
                    //      [o o o . . . . . . o o o o o x o]
                    //
                    //           H             T
                    //      [o o . . . . . . . o o o o o o o]
                    //       M M                         M M
                    //
                    // or quasi-discontiguous, remove next to head, tail section:
                    //
                    //       H                 T         R
                    //      [. . . . . . . . . o o o o o x o]
                    //
                    //                         T           H
                    //      [. . . . . . . . . o o o o o o .]
                    //                                   M

                    // draw in elements in the tail section
                    self.copy(idx, idx + 1, self.cap() - idx - 1);

                    // Prevents underflow.
                    if self.head != 0 {
                        // copy first element into empty spot
                        self.copy(self.cap() - 1, 0, 1);

                        // move elements in the head section backwards
                        self.copy(0, 1, self.head - 1);
                    }

                    self.head = self.wrap_sub(self.head, 1);
                }
            }
            (false, true, false) => {
                unsafe {
                    // discontiguous, remove closer to tail, head section:
                    //
                    //           R               H     T
                    //      [o o x o o o o o o o . . . o o o]
                    //
                    //                           H       T
                    //      [o o o o o o o o o o . . . . o o]
                    //       M M M                       M M

                    // draw in elements up to idx
                    self.copy(1, 0, idx);

                    // copy last element into empty spot
                    self.copy(0, self.cap() - 1, 1);

                    // move elements from tail to end forward, excluding the last one
                    self.copy(self.tail + 1, self.tail, self.cap() - self.tail - 1);

                    self.tail = self.wrap_add(self.tail, 1);
                }
            }
        }

        return elem;
    }
}
```

注意到在增长和减少容量(shrink)时候，`head`/`tail`的位置不同会导致多种情况。

* 原缓冲区是否连续
* 保持`tail`或`head`的位置和对应的代价

* [#56431](https://github.com/rust-lang/rust/issues/56431) 加入了`shrink_to(&mut self, usize)`



连续(`is_contiguous`)的条件: `self.tail <= self.head`



注意到在插入(`insert`)/删除(`remove`)的时候，分类讨论

* 原数据是否连续
* 插入位置离`head`和`tail`的远近
* 存在于`[head|empty|tail]`中哪个部分



[#56686](https://github.com/rust-lang/rust/issues/56686) 加入了`VecDeque::rotate_{left|right}(&mut self, usize)`的支持



```rust
impl<T> for VecDeque<T> {
	#[inline]
    #[stable(feature = "drain", since = "1.6.0")]
    pub fn drain<R>(&mut self, range: R) -> Drain<T>
        where R: RangeBounds<usize>
    {
        let len = self.len();
        let start = match range.start_bound() {
            Included(&n) => n,
            Excluded(&n) => n + 1,
            Unbounded    => 0,
        };
        let end = match range.end_bound() {
            Included(&n) => n + 1,
            Excluded(&n) => n,
            Unbounded    => len,
        };
        assert!(start <= end, "drain lower bound was too large");
        assert!(end <= len, "drain upper bound was too large");

        // T = self.tail; H = self.head; t = drain_tail; h = drain_head
        //        T   t   h   H
        // [. . . o o x x o o . . .]
        //
        let drain_tail = self.wrap_add(self.tail, start);
        let drain_head = self.wrap_add(self.tail, end);
        let head = self.head;

        self.head = drain_tail;

        Drain {
            deque: NonNull::from(&mut *self),
            after_tail: drain_head,
            after_head: head,
            iter: Iter {
                tail: drain_tail,
                head: drain_head,
                ring: unsafe { self.buffer_as_slice() },
            },
        }
    }
}

#[stable(feature = "drain", since = "1.6.0")]
pub struct Drain<'a, T: 'a> {
    after_tail: usize,
    after_head: usize,
    iter: Iter<'a, T>,
    deque: NonNull<VecDeque<T>>,
}

#[stable(feature = "drain", since = "1.6.0")]
impl<'a, T: 'a> Drop for Drain<'a, T> {
    fn drop(&mut self) {
        self.for_each(drop);

        let source_deque = unsafe { self.deque.as_mut() };

        // T = source_deque_tail; H = source_deque_head; t = drain_tail; h = drain_head
        //
        //        T   t   h   H
        // [. . . o o x x o o . . .]
        //
        let orig_tail = source_deque.tail;
        let drain_tail = source_deque.head;
        let drain_head = self.after_tail;
        let orig_head = self.after_head;

        let tail_len = count(orig_tail, drain_tail, source_deque.cap());
        let head_len = count(drain_head, orig_head, source_deque.cap());

        // Restore the original head value
        source_deque.head = orig_head;

        match (tail_len, head_len) {
            (0, 0) => {
                source_deque.head = 0;
                source_deque.tail = 0;
            }
            (0, _) => {
                source_deque.tail = drain_head;
            }
            (_, 0) => {
                source_deque.head = drain_tail;
            }
            _ => unsafe {
                if tail_len <= head_len {
                    source_deque.tail = source_deque.wrap_sub(drain_head, tail_len);
                    source_deque.wrap_copy(source_deque.tail, orig_tail, tail_len);
                } else {
                    source_deque.head = source_deque.wrap_add(drain_tail, head_len);
                    source_deque.wrap_copy(drain_tail, drain_head, head_len);
                }
            },
        }
    }
}
```

这里的`drain`可实现对一个`RangeBound`的提取。`drain(range)`将原`VecDeque<T>`分割成`self.tail -> drain.tail`|`drain.tail -> drain.head`|`drain.head -> self.head`。

- [RFC-1257](https://github.com/rust-lang/rfcs/pull/1257)



在`drain`的时候，`NonNull<VecDeque<T>>`作为一个可变借用(mutable borrow, `*mut T`)禁止其他借用(borrow)。在`Drain<T>`构造后析构前，无视后两段元素，当`Drain<T>`析构时，重新计算`head`， `tail`, 和相关元素。



```rust
trait RingSlices: Sized {
    fn slice(self, from: usize, to: usize) -> Self;
    fn split_at(self, i: usize) -> (Self, Self);

    fn ring_slices(buf: Self, head: usize, tail: usize) -> (Self, Self) {
        let contiguous = tail <= head;
        if contiguous {
            let (empty, buf) = buf.split_at(0);
            (buf.slice(tail, head), empty)
        } else {
            let (mid, right) = buf.split_at(tail);
            let (left, _) = mid.split_at(head);
            (right, left)
        }
    }
}

#[stable(feature = "rust1", since = "1.0.0")]
pub struct Iter<'a, T: 'a> {
    ring: &'a [T],
    tail: usize,
    head: usize,
}

#[stable(feature = "rust1", since = "1.0.0")]
pub struct IterMut<'a, T: 'a> {
    ring: &'a mut [T],
    tail: usize,
    head: usize,
}

#[derive(Clone)]
#[stable(feature = "rust1", since = "1.0.0")]
pub struct IntoIter<T> {
    inner: VecDeque<T>,
}
```

`RingSlices`是描述环形缓冲区切片的trait。



```rust
macro_rules! __impl_slice_eq1 {
    ($Lhs: ty, $Rhs: ty) => {
        __impl_slice_eq1! { $Lhs, $Rhs, Sized }
    };
    ($Lhs: ty, $Rhs: ty, $Bound: ident) => {
        #[stable(feature = "vec_deque_partial_eq_slice", since = "1.17.0")]
        impl<'a, 'b, A: $Bound, B> PartialEq<$Rhs> for $Lhs where A: PartialEq<B> {
            fn eq(&self, other: &$Rhs) -> bool {
                if self.len() != other.len() {
                    return false;
                }
                let (sa, sb) = self.as_slices();
                let (oa, ob) = other[..].split_at(sa.len());
                sa == oa && sb == ob
            }
        }
    }
}

__impl_slice_eq1! { VecDeque<A>, Vec<B> }
__impl_slice_eq1! { VecDeque<A>, &'b [B] }
__impl_slice_eq1! { VecDeque<A>, &'b mut [B] }

macro_rules! array_impls {
    ($($N: expr)+) => {
        $(
            __impl_slice_eq1! { VecDeque<A>, [B; $N] }
            __impl_slice_eq1! { VecDeque<A>, &'b [B; $N] }
            __impl_slice_eq1! { VecDeque<A>, &'b mut [B; $N] }
        )+
    }
}

array_impls! {
     0  1  2  3  4  5  6  7  8  9
    10 11 12 13 14 15 16 17 18 19
    20 21 22 23 24 25 26 27 28 29
    30 31 32
}
```

用宏定义实现了`VecDeque<T>`对0-32长度的`[T; B]`的切片的`eq`函数。



```rust
#[stable(feature = "vecdeque_vec_conversions", since = "1.10.0")]
impl<T> From<VecDeque<T>> for Vec<T> {
    fn from(other: VecDeque<T>) -> Self {
        unsafe {
            let buf = other.buf.ptr();
            let len = other.len();
            let tail = other.tail;
            let head = other.head;
            let cap = other.cap();

			// 连续，则从tail开始移动到buffer首位
            if other.is_contiguous() {
                ptr::copy(buf.add(tail), buf, len);
            } else {
                if (tail - head) >= cmp::min(cap - tail, head) {
                    // There is enough free space in the centre for the shortest block so we can
                    // do this in at most three copy moves.
                    if (cap - tail) > head {
                        // right hand block is the long one; move that enough for the left
                        ptr::copy(buf.add(tail),
                                  buf.add(tail - head),
                                  cap - tail);
                        // copy left in the end
                        ptr::copy(buf, buf.add(cap - head), head);
                        // shift the new thing to the start
                        ptr::copy(buf.add(tail - head), buf, len);
                    } else {
                        // left hand block is the long one, we can do it in two!
                        ptr::copy(buf, buf.add(cap - tail), head);
                        ptr::copy(buf.add(tail), buf, cap - tail);
                    }
                } else {
                    // Need to use N swaps to move the ring
                    // We can use the space at the end of the ring as a temp store

                    let mut left_edge: usize = 0;
                    let mut right_edge: usize = tail;

                    // The general problem looks like this
                    // GHIJKLM...ABCDEF - before any swaps
                    // ABCDEFM...GHIJKL - after 1 pass of swaps
                    // ABCDEFGHIJM...KL - swap until the left edge reaches the temp store
                    //                  - then restart the algorithm with a new (smaller) store
                    // Sometimes the temp store is reached when the right edge is at the end
                    // of the buffer - this means we've hit the right order with fewer swaps!
                    // E.g
                    // EF..ABCD
                    // ABCDEF.. - after four only swaps we've finished

                    while left_edge < len && right_edge != cap {
                        let mut right_offset = 0;
                        for i in left_edge..right_edge {
                            right_offset = (i - left_edge) % (cap - right_edge);
                            let src: isize = (right_edge + right_offset) as isize;
                            ptr::swap(buf.add(i), buf.offset(src));
                        }
                        let n_ops = right_edge - left_edge;
                        left_edge += n_ops;
                        right_edge += right_offset + 1;

                    }
                }

            }
            let out = Vec::from_raw_parts(buf, len, cap);
            mem::forget(other);
            out
        }
    }
}
```

实现了将`VecDeque<T>`转变为`Vec<T>`的过程，为了复用`buf: RawVec<T>`，分类讨论：

* 原环形缓存连续，则直接从`tail`开始复制到到队首。
* 不连续，如果空间足够放下`[head section|empty|tail section]`中`head section`和`tail section`中较长的一块，则可以用三次`copy/move`解决。
* 不连续，也不够放下，用保留的队尾作为临时储存，做最多N次`swap`。
  * 每次小循环或`tail`达到`RawVec`结束位置，或拷贝位置达到队尾(temp store)。每次小循环结束重新设置`swap`起点。



```rust
impl<T> for VecDeque<T> {
	#[inline]
    #[stable(feature = "append", since = "1.4.0")]
    pub fn append(&mut self, other: &mut Self) {
        // naive impl
        self.extend(other.drain(..));
    }
}

#[cfg(test)]
mod tests {
    use test;
    use super::VecDeque;
    #[test]
    fn issue_53529() {
        use boxed::Box;

        let mut dst = VecDeque::new();
        dst.push_front(Box::new(1));
        dst.push_front(Box::new(2));
        assert_eq!(*dst.pop_back().unwrap(), 1);

        let mut src = VecDeque::new();
        src.push_front(Box::new(2));
        dst.append(&mut src);
        for a in dst {
            assert_eq!(*a, 2);
        }
    }
}
```

[#52553](https://github.com/rust-lang/rust/pull/52553) 试图实现一个非平凡的`append`实现，但是造成了[#53529](https://github.com/rust-lang/rust/issues/53529)的段错误(segmentation fault)，[#53564](https://github.com/rust-lang/rust/pull/53564)重新优化，但[#54477](https://github.com/rust-lang/rust/issues/54477)发现这个改进在测试集(regression test)上失败所以在1.30版本中又改回了平凡实现(naive impl)。

* [Rust Secure Code Working Group](https://github.com/rust-secure-code/wg)
* [另一个VecDeque的bug，混淆了capacity() (=cap() - 1)和cap()](https://github.com/rust-lang/rust/issues/44800#issuecomment-331684024)
  * [CVE-2018-1000657](https://cve.mitre.org/cgi-bin/cvename.cgi?name=%20CVE-2018-1000657)



### alloc.rs [WIP]

#![TODO]