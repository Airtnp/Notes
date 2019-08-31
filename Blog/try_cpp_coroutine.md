# 试用 C++ Coroutine TS (C++2a)

基于 [N4775](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2018/n4775.pdf), 2018-10-07



## N4775 Working Draft 部分内容摘抄

`[intro.features]` 加入macro `__cpp_coroutines`

```c++
#ifdef __cpp_coroutines
#if __cpp_coroutines == 201806
#define IS_COROUTINE_TS_SUPPORTED
#endif
#endif
```



加入`co_await`, `co_yield`, `co_return`三个关键字



`main`函数不应该是coroutine (`[basic.start.main]`), 全局分配函数可能被`new`表达式，调用`new`函数，调用标准库函数之外的情况调用，用于间接分配协程帧 (`[basic.stc.dynamic.allocation]`)



`[expr.await]`  加入 `await`-表达式: `co_await cast-expression`

* 只能在`handler`(异常处理)之外的函数体出现, 在`for-init-statement`中的声明部分只能在`initializer`部分出现, 不能作为默认参数
* `suspension context`： `await`表达式可出现的函数上下文
* 对`await`表达式的求值
  * `p`: promise对象的左值名
  * `P`: promise对象的类型
  * `a`
    * 如果`cast`-表达式是由`yield`表达式，`initial suspend point` (初始暂停点), `final suspend point` (终止暂停点)得到的值, `a`保持原`cast`-表达式
    * 否则, 如果在`P`的类成员找到至少一个无修饰的标识符(`unqualified-id`) `await_transform`的声明, `a`变为`p.await_transform(cast-expression)`
    * 否则, `a`保持原`cast`-表达式
  * `o` 
    * 如果找到可调用的`operator co_await`的重载，则`o`是这个函数的调用
    * 否则，`o`是`a`
  * `e`
    * 如果`o`是`prvalue`，则`e`是拷贝初始化的临时对象
    * 否则，`e`是`o`求值的左值
  * `h`是`std::experimental::coroutine_handle<P>`类型的对象
  * `await-ready`是`e.await_ready()`表达式，根据上下文转换到`bool`
  * `await-suspend`是`e.await_suspend(h)`表达式，应当是类型为`void`, `bool`, `std::experimental::coroutine_handle<Z>`的`prvalue`
  * `await-resume`是`e.await_resume()`表达式
* `await`表达式和`await-resume`有相同的类型和值分类 (value category)
* `await`表达式对`await-ready`求值
  * 如果结果是`false`，协程被认为`suspend`，然后`await-suspend`表达式被求值。
    * 如果这个表达式类型为`std::experimental::coroutine_handle<Z>`，值为`s`，`s`指向的协程被`resume` (as-if 调用`s.resume()`)。这个过程可以`resume`任意多个协程，直到返回协程调用者或者`resumer`的控制流。
    * 如果这个表达式类型为`bool`，值为`false`，这个协程被`resume`
    * 如果这个表达式通过异常退出并这个异常被捕获，这个协程被`resume`，并且这个异常被立刻重新抛出。
    * 否则，控制流返回到协程调用者或者`resumer`
  * 如果结果是`true`，或者协程被`resume`，`await-resume`表达式被求值，作为`await`表达式的结果。



`[expr.yield]` 加入`yield`表达式: `co_yield assignment-expression` | `co_yield braced-init-list`

* `yield`表达式只能在函数中的`suspension`上下文出现
* `e`作为`yield`表达式的参数，`yield`表达式等价于`co_await p.yield_value(e)`



`[stmt.ranged]` 加入`for co_await (for-range-decl : for-range-init) statement`

```txt
{
    auto &&__range = for-range-initializer ;
    auto __begin = co_await_{opt} begin-expr ;
    auto __end = end-expr ;
    for ( ; __begin != __end; co_await_{opt} ++__begin ) {
        for-range-declaration = *__begin;
        statement
    }
}
```



`return`不能用于协程，`[stmt.return.coroutine]`加入`co_return`语句: `co_return expr-or-braced-init-list_{opt}`

* `co_return`语句使协程返回到调用者或者`resumer`
* `co_return`语句等价于`{ S; goto final_suspend; }`
  * 如果操作数是`brace-init-list`或者非`void`类型的表达式，`S = p.return_value(expr-or-braced-init-list)`
  * 否则，`S = { expression_{opt}; p.return_void(); }`
  * `S`应该是`void`类型的`prvalue`
* 如果`p.return_void()`是有效的表达式，协程结束等价于`co_return`，否则是未定义行为



​	`[dcl.fct.def.coroutine]` 函数成为协程，仅当其包含`co_return`语句、`await`表达式、`yield`表达式，或者范围`for`和`co_await`。协程的参数不能为`...`

* 非静态成员函数的协程: $P_1$: 隐含对象类型，$P_2, \cdots, P_n$: 函数参数类型
* 否则: $P_1 \cdots P_n$: 函数参数类型
* $p_1, \cdots, p_n$: 左值对象
* $R$: 返回类型, $F$: 函数体
* $T$: `std::experimental::coroutine_traits<R, P1, ..., Pn>`
* $P$: `T::promise_type`
* 协程等价于(as-if):

```c++
{
    P p promise-constructor-arguments ;
    co_await p.initial_suspend() ; // initial suspend point
    try { F } catch(...) { p.unhandled_exception() ; }
final_suspend:
    co_await p.final_suspend() ; // final suspend point
}
```

* `promise-constructor-arguments`
  * 如果找到`promise`构造器中可用的接受参数`(p1, ..., pn)`的构造函数, 则为`(p1, ..., pn)`
  * 否则, 为空
* 在`P`中查找未修饰的`return_void`和`return_value`标识符, 仅能存在一个
* 返回到调用者时, 返回值由`p.get_return_object()`产生, 这个调用`sequence-before` `initial_suspend`且最多调用一次
* 一个`suspend`的协程可以被调用`coroutine_handle<P>`的`resumption`成员函数所`resume`, 调用这个`resumption`成员函数的函数被称为`resumer`
* 实现可能需要额外分配空间, `coroutine state`, 被调用非数列的分配函数所分配. 首先从`P`中寻找分配函数, 不然从全局. 如果从`P`中调用, 参数列表为`std::size_t, p1, ..., pn`. 如果无法找到适合的函数, 则重新寻找参数列表为`std::size_t`的重载.
  * 释放空间函数同理
* 在`P`中查找未修饰的标识符`get_return_object_on_allocation_failure`, 如果找到, 则假设分配失败是`noexcept`, 分配失败返回`nullptr`. 失败时则由这个函数返回返回值. 这个函数必须`noexcept`.
* `coroutine state`在协程结束或者调用`std::experimental::coroutine_handle<P>::destroy`被销毁. 这个协程必须处在`suspend`状态
* 协程调用时, 所有参数都被复制(从`lvalue ref`或者`xvalue`进行`direct-initialization`). 协程中用到参数的引用都被替换成对复制的引用



`[support.coroutine]` 加入`<experimental/coroutine>`头文件

```c++
namespace std {
namespace experimental {
inline namespace coroutines_v1 {
    // 21.11.1 coroutine traits
    template <class R, class... ArgTypes>
    struct coroutine_traits;
    
    // 21.11.2 coroutine handle
    template <class Promise = void>
    struct coroutine_handle;

    // 21.11.3 noop coroutine promise
    struct noop_coroutine_promise;
    template <> struct coroutine_handle<noop_coroutine_promise>;
    // noop coroutine handle
    using noop_coroutine_handle = coroutine_handle<noop_coroutine_promise>;

    // 21.11.4 noop coroutine
    noop_coroutine_handle noop_coroutine() noexcept;
    
    // 21.11.2.6 comparison operators:
    constexpr bool operator==(coroutine_handle<> x, coroutine_handle<> y) noexcept;
    constexpr bool operator!=(coroutine_handle<> x, coroutine_handle<> y) noexcept;
    constexpr bool operator<(coroutine_handle<> x, coroutine_handle<> y) noexcept;
    constexpr bool operator>(coroutine_handle<> x, coroutine_handle<> y) noexcept;
    constexpr bool operator<=(coroutine_handle<> x, coroutine_handle<> y) noexcept;
    constexpr bool operator>=(coroutine_handle<> x, coroutine_handle<> y) noexcept;
    // 21.11.5 trivial awaitables
    struct suspend_never;
    struct suspend_always;
} // namespace coroutines_v1
} // namespace experimental

    // 21.11.2.7 hash support:
    template <class T> struct hash;
    template <class P> struct hash<experimental::coroutine_handle<P>>;
} // namespace std
```



```c++
template <...Args>
struct coroutine_traits {};

template <class R, class V = void_t<typename R::promise_type>, class... ArgTypes>
struct coroutine_traits<R, ArgTypes...> {
	using promise_type = typename R::promise_type;
};
```



```c++
template <>
struct coroutine_handle<void>
{
    // 21.11.2.1 construct/reset
    constexpr coroutine_handle() noexcept;
    constexpr coroutine_handle(nullptr_t) noexcept;
    coroutine_handle& operator=(nullptr_t) noexcept;
    
    // 21.11.2.2 export/import
    constexpr void* address() const noexcept;
    constexpr static coroutine_handle from_address(void* addr);
    
    // 21.11.2.3 observers
    constexpr explicit operator bool() const noexcept;
    bool done() const;
    
    // 21.11.2.4 resumption
    void operator()() const;
    void resume() const;
    void destroy() const;
private:
	void* ptr; // exposition only
};


template <class Promise>
struct coroutine_handle : coroutine_handle<>
{
    // 21.11.2.1 construct/reset
    using coroutine_handle<>::coroutine_handle;
    static coroutine_handle from_promise(Promise&);
    coroutine_handle& operator=(nullptr_t) noexcept;
    
    // 21.11.2.2 export/import
    constexpr static coroutine_handle from_address(void* addr);
    
    // 21.11.2.5 promise access
    Promise& promise() const;
};

template <> struct coroutine_handle<noop_coroutine_promise> : coroutine_handle<>
{
    // 21.11.2.8 noop observers
    constexpr explicit operator bool() const noexcept;
    constexpr bool done() const noexcept;
    
    // 21.11.2.9 noop resumption
    constexpr void operator()() const noexcept;
    constexpr void resume() const noexcept;
    constexpr void destroy() const noexcept;
    
    // 21.11.2.10 noop promise access
    noop_coroutine_promise& promise() const noexcept;
    
    // 21.11.2.11 noop address
    constexpr void* address() const noexcept;
private:
	coroutine_handle(unspecified );
};
```

* coroutine handle: `coroutine_handle<P>`



```c++
struct suspend_never {
    constexpr bool await_ready() const noexcept { return true; }
    constexpr void await_suspend(coroutine_handle<>) const noexcept {}
    constexpr void await_resume() const noexcept {}
};

struct suspend_always {
    constexpr bool await_ready() const noexcept { return false; }
    constexpr void await_suspend(coroutine_handle<>) const noexcept {}
    constexpr void await_resume() const noexcept {}
};
```



## 怎么用?

<del>这个设计也太侵入式了吧</del>

先列举一下可定制的点:

* `operator co_await(Args...) -> A`: 类似`P::await_transform`和`P::yield_value`
* `promise`对象
  * `P::await_transform(Args...) -> A`: [可选]用于转换`co_await`的操作数到提供`await_ready`, `await_suspend`, `await_resume`的对象 (`Awaitable`)
  * `P::yield_value(Args...) -> A`: 用于转换`co_yield`的操作数到`Awaitable`
  * `P::return_value(Args...) -> void`和`P::return_void() -> void`二选一: 用于`co_return`缓存结果, 真正结果通过`await_resume()`得到
  * `P::initial_suspend()`: 用于在初始挂起点(`initial suspend point`)转换到`Awaitable`
  * `P::final_suspend()`: 用于在最终挂起点(`final suspend point`)转换到`Awaitable`
  * `P::P(Args...)`和`P::P()`调用时二选一: `promise`对象的构造函数, 优先接收协程参数的构造器.
  * `P::unhandled_exception() -> void`: 用于处理协程中出现的异常 (TS未提到, 但是这个函数应该是`noexcept`的?)
  * `P::get_return_object() -> R`: 用于调用者的返回值
  * `P::get_return_object_on_allocation_failure() -> R`: 保证内存分配(`coroutine state`)无异常且失败时候的返回值
  * `new`, `delete`: 用于协程存储分配
* `Awaitable`对象
  * `A::await_ready() -> bool`: 用于判断协程是否执行完成
  * `A::await_suspend(coroutine_handle<P>) -> variant<void, bool, coroutine_handle<Z>>`: 
  * `A::await_resume() -> T`: 用于返回`co_await`的结果
* 协程返回对象
  * `R::promise_type`: 定义`promise`对象类型



先试着模拟一下`range(begin, end, step)`

```c++
#include <experimental/coroutine>
#include <iostream>
using namespace std::experimental;

template <class T>
struct range_generator {
    struct await_callback {
        bool await_ready() { return false; }
        coroutine_handle<> await_suspend(coroutine_handle<>) { 
            std::cout << "Suspend inner\n";
            return handle; 
        }
        void await_resume() {}
        coroutine_handle<>& handle;
    };
    struct promise_type {
        T current_value;
        coroutine_handle<> handle;
        bool has_finished = false;
        auto yield_value(T v) { current_value = v; return await_callback{handle}; }
        auto initial_suspend() { return suspend_always{}; }
        auto final_suspend() { has_finished = true; return suspend_always{}; }
        auto get_return_object() { return range_generator{*this}; }
        void unhandled_exception() noexcept {}
        void return_void() {}
    };
    using handle_type = coroutine_handle<promise_type>;
    struct normal_iterator;
    // co_await begin()
    struct await_iterator {
        handle_type& handle;
        bool await_ready() {
            return false;
        }
        coroutine_handle<promise_type> await_suspend(coroutine_handle<> h) {
            std::cout << "Suspend outer\n";
            handle.promise().handle = h;
            return handle;
        }
        normal_iterator await_resume() {
            return normal_iterator{handle, handle.promise().has_finished};
        }
    };
    // normal end()
    struct normal_iterator {
        handle_type& handle;
        normal_iterator(handle_type& p, bool is_end): handle{p}, is_end{is_end} {}
        await_iterator operator++() {
            return await_iterator{handle};
        }
        T operator*() {
            return handle.promise().current_value;
        }
        bool is_end;
        bool operator!=(const normal_iterator& rhs) {
            return handle != rhs.handle || is_end != rhs.is_end;
        }
    };
    await_iterator begin() { return await_iterator{handle}; }
    normal_iterator end() { return normal_iterator{handle, true}; }
    range_generator(promise_type& promise): handle{handle_type::from_promise(promise)} {}
    handle_type handle;
};

struct none_generator {
    struct promise_type {
        auto initial_suspend() { return suspend_never{}; }
        auto final_suspend() { return suspend_never{}; }
        auto get_return_object() { return none_generator{}; }
        void unhandled_exception() noexcept {}
        void return_void() {}
    };
};

// 当然我根本没管方向
range_generator<int> range(int begin, int end, int step) {
    for (int i = begin; i < end; i += step) {
        std::cout << "Yield: " << i << '\n';
        co_yield i;
    }
}

none_generator wtf() {
    for co_await (int i : range(0, 10, 4)) {
        std::cout << "Get: " << i << '\n';
    }
}


int main() {
    wtf();
    return 0;
}
```

输出 ([godbolt](https://godbolt.org/z/hMh51G))

```txt
Suspend outer
Yield: 0
Suspend inner
Get: 0
Suspend outer
Yield: 4
Suspend inner
Get: 4
Suspend outer
Yield: 8
Suspend inner
Get: 8
Suspend outer
```

原本以为开箱即用的协程结果还是要写这么长...把`iterator_traits`和const `iterator`等等一些东西加上大概会长一倍吧. 个人认为这个复杂度是由于几个因素:

1. stackless实现, stackful则可以存整个栈帧
2. 自由度, 可定制的点
   * 如何管理控制流? Eg. 状态机?
   * 如何管理`coroutine_handle`的生命周期? Eg. 协程池?
3. 侵入式, 好比习惯了`shared_ptr`上手用`intrusive_ptr`

如果能加入[`task<T>`](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2018/p1056r0.html) 这里的代码会更简单一点. 关于最佳实践, 我暂且蒙在鼓里.



[尝试了下阴阳谜题, 但是失败了](https://godbolt.org/z/EWpVz1)

* stackless协程只会返回到调用者, 怎么可能成功 (



## 参考资料

* [N4775](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2018/n4775.pdf)
* [协程](https://zh.cppreference.com/w/cpp/language/coroutines), 我上面瞎翻的, 看这个好点
* [c++20协程入门](https://zhuanlan.zhihu.com/p/59178345)
* [understanding-operator-co-await](https://lewissbaker.github.io/2017/11/17/understanding-operator-co-await)三篇 + [cppcoro](https://github.com/lewissbaker/cppcoro), 作者Lewis Baker是Coroutine TS主要推动者
* [Coroutine-changes-for-C++20-and-beyond](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2019/p1745r0.pdf) 没看, 但看起来很厉害的样子.jpg
* [如何实现阴阳谜题](https://www.zhihu.com/question/27683900), 然而没成功