# Rust Idioms

## \#

* `#[test]`

  * `#[should_panic]`
  * `assert_eq!`
  * `assert!`

* `#[bench]`: benchmarking

  * ```rust
    extern crate test; // exception in Rust 2018 for rustc not passing --extern test=PATH
    [bench]
    fn bench_nothing(b: &mut test::Bencher) {
    	b.iter(|| do_something());
    }
    ```

  * 

* `#[cfg(test)]`: encapsulating the test module

* `#[ignore]`: only run with `--ignore`

* `//!`: module-level documentation

* `///`: function-level documentation

* `#[derive(...)]`

  * `Copy`
  * `PartialEq`
  * `Ord`
  * `Debug`
  * `Send`
  * `Sync`



## A

* array
  * `[T; n]`
  * slice: `&[T}`
  * slicing `n..m` `n..=m`
* `Arc<T>`: atomic reference counting (thread-safe)



## B

* builder idiom
* `Box<T>`: owned pointer



## C

* `cargo`
  * `init`: start a project
  * `build`: build a project
  * `test` running tests and benchmarks
  * `search`: searching crates: 3rd-party libraries
  * `update`
  * Cargo.toml
    * `^0.58`: at least 0.58
    * `repo  = { git = "...", branch = "master", version = "1.2", optional = "true" }` (need `[features].default`)
    * 
  * Cargo.lock
* `cfg`
* `const`: compile-time
* `Cell`: internal mutability for `T: Copy`
  * multiple mutable reference
  * `fn get(&self) -> T`: copy interior value
  * `fn set(&self, T)`: replace interior value by memcpy, and drop old value (only exist if `T: Copy`)
* Closure
  * `|x: T| {}`
  * `move || {}`

* channel: `std::sync::mpsc` (multiple-producer, single consumer)
  * `channel`: asynchronous, infinite buffer
  * `sync_channel(usize)`: synchronous, bounded buffer
  * `std::select`
* compiler plugin
  * `#![feature(plugin_registrar, rustc_private)]`
  * `fn name<'cx>(&mut ExtCtxt, Span, TokenStream) -> Box<dyn MacResult + 'cx>`
  * `ExtCtxt`: extension context, control execution, like `span_err`
  * `Span`: region of cod eused internally for making error messages
  * `MacResult`: abstracted forms of Rust code. 
* `chomp`: monad pattern
  * `parse!{input; ...; ret ...}`
    * alt: `<|>`
    * concat: normal `;` (`>>=`)
  * `parse_only(rule, str)`







## D

* `Drop`: destructor
  
  * `fn drop(&mut self) -> ()`
  
* database

  * sqlite

  * postgresql

  * r2d2: connection pooling

    * ```rust
      pub trait ManageConnection: Send + Sync + 'static {
          type Connection: Send + 'static;
          type Error: Error + 'static;
          fn connect(&self) -> Result<Self::Connection, Self::Error>;
          fn is_valid(&self, conn: &mut Self::Connection) -> Result<(),
          Self::Error>;
          fn has_broken(&self, conn: &mut Self::Connection) -> bool;
      }
      ```

  * diesel

    * `#[derive(Queryable)]`
    * `#[derive(Insertable)]` + `[table_name=""]`

* Debugging

  * gdb
  * lldb





## E

* `extern crate`
  * `proc_macro`
  * `alloc` on nightly
  * `test` on nightly
* `Error`: `Debug + Display + Reflect`

  * `fn description(&self) -> &str`
  * `fn cause(&self) -> Option<&Error> { None }`
  * 







## F

* `std::ffi`
  * `CStr`: borrowed C string (`zstring`)
  * `CString`: owned string (`string`)
  * `extern { fn ...(c_char...) }`
    * `#[link(name="libname")]`
  * ruby -> ruru
  * javascript -> neon
  * 







## G

## H



## I



## J



## K

## L

* LLVM
  * `--emit=llvm-ir`
* lifetime
  * A borrow reference may out live longer than what it referred to
  * mutable reference, no multiple references
  * no mutable reference, multiple immutable references
  * more than one reference in function parameter -> specifiy lifetime
* library
  * `diesel`: data object-relational mapper
  * `serde`: general serialization/deserialization framework
    * `Serialize`/`Deserialize`
  * `rust-clippy`







## M

* `std::mem`
  * `size_of<T>()`: size of a type
  * `size_of_val(&T)`: size of a value given as a reference

* `Mutex`

  * `fn new(T)`
  * `fn lock(&self) -> LockResult<MutexGuard<T>>`
  * `type LockResult<Guard> = Result<Guard, PoisonError<Guard>>`
  * Poison error: mutex holding thread panicked
    * `unwrap()` will just propagate the panic...

* macro

  * syntactic macros

    * `macro_rules!`

    * `($fmt:expr)`: expression

      * `1, x + 1, if x==4 { 1 } else { 2 }`

    * `($arg:tt)`: token tree

      * single token or several token surrounded by any of the braces
      * `{ bar; fi x == 2 ( 3 ] ulse ) 4 {; baz } `
      * no need to make semantic sense

    * `($block: block)`: sequence of statements

      * `{ silly; things; }`

    * `meta`: meta item

      * parameters inside attributes
      * `foo(...)` in `#![foo], #[foo], #[foo(bar)], #[foo(bar="baz")]`

    * `pat`: pattern

      * left-hand of each match
      * expression + `1 | 2 | 3`, `1 ... 3`, `Some(t)`, `_`

    * `path`: qualified name

    * `ty`: type

      * no semantic checking in macro expansion phase

    * `ident`: identifier

    * `item`: item

      * top-level definitions
      * functions
      * use declarations
      * type definitions

    * `stmt`: statement

      * expression + `let x = 1`

    * `$(...)*`

    * `format_arg!`

    * `rustc -Z unstable-options --pretty expanded`: debugging macros (like `gcc -E`)

    * `trace_macros!`: globally turn macro tracing on/off

    * `log_syntax!`: compile time output argument

    * ```rust
      macro_rules! vec {
      	($elem:expr; $n:expr) => ($crate::vec::from_elem($elem, $n));
      	($($x:expr),*) => (<[_]>::into_vec(box [$($x),*])); // common comma separate
      	($($x:expr,)*) => (vec![$($x),*]) // allow trailing comma
      }
      ```

  * procedural macros (compiler plugins)

    * `syntax` -> `proc_macro`
    * function-like: `name!()`
      * `[proc_macro]` + `fn name(_item: TokenStream) -> TokenStream`
    * derive macros: `#[derive(Name)]`, `$[xxx] field`
      * `plugin_registrar` -> `[proc_macro_derive(Name), attributes(xxx)]`
      * `fn name(_item: TokenStream) -> TokenStream`
    * attribute macros: `#[name(attr)]`
      * `[proc_macro_attribute]` + `fn name(_attr: TokenStream, item: TokenStream) -> TokenStream`
      * 



## N

* `nom`
  * bit by bit / byte by bte / UTF-8 string
  * `IResult`: `Done(I, O)`, `Error(Err)`, `Incomplete(Needed)`
  * 









## O

## P

* parser
  * packrat/PEG parser
* 







## Q



## R

* `RefCell`: internal mutability by runtime locking
  * `fn borrow(&self) -> &T`
  * `fn borrow_mut(&self) -> &mut T`
* `Rc<T>`: shared pointer
  * `fn clone() -> Rc<T>`
  * `fn downgrade(&self) -> Weak<T>`: convert to weak pointer, always success
  * 





## S

* string
  * `str`
    * fixed size
    * `&str`
      * `&'static str`
      * arguments
      * view of a string
  * `String`
    * `new`, `from(&str)`, `with_capacity(usize)`, `from_utf8(Vec<u8>)`
* `static`: mutable global (must be used in side `unsafe`)
* `Send`: marker trait, safe to be sent between threads
* `Serde`
  * `#[derive(Serialize, Deserialize)]`
    * `fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error> where S: Serializer`
    * `fn deserialize<D>(deserializer: D) -> Result<Self, D::Error> where D: DeSerialize<'de>'`
  * `#[serde(rename="...")]`
  * support JSON/YAML/TOML/Msgpack/URL

## T

* trait object
  * `impl Trait`
  * `dyn Trait`

* thread

  * ```rust
    fn spawn<F, T>(f: F) -> JoinHandle<T> // jhandle in C++23?
    	where F: FnOnce() -> T,
    		F: Send + 'static,
    		T: Send + 'static
    ```

  * 





## U

* `unsafe`
  * `unsafe fn`
  * `unsafe { }`
  * `unsafe trait` + `unsafe impl`
  * dereference a raw pointer
    * null, dangling, unaligned
    * uninitialized memory
    * breaking pointer aliasing rules
    * invalid primitive values
      * dangling/null reference
      * null `fn` pointers
      * bool isn't 0 or 1
      * undefined `enum` discriminant
      * char outside the range `[0x0, 0xD7FF]` & `[0xE000, 0x10FFFF]`
      * a non-UTF8 string
  * unwind into another language
  * data race
  * call an `unsafe` function/method
  * access/modify a mutable static variable
  * implement an `unsafe` trait
  * 











## V



## W

* `Weak<T>`: weak pointer
  * `fn upgrade(&self) -> Rc<T>`: try upgrade, the `Rc<T>` may be dropped already

* Web
  * `Hyper`
    * `client`
    * `UserAgent`
  * `Rocket`
  * 



## X



## Y



## Z

