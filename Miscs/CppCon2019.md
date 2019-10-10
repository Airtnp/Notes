# CppCon 2019



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

* 