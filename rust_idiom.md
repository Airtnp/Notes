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
* attributes
  * `#[<name>]`: per item (inner)
  * `#![<name>]`: whole crate (outer)



## B

* builder idiom

* `Box<T>`: owned pointer

* benchmarks

  * nightly: `#[bench]`: function as benchmark test

  * `libtest` + `Bencher`

  * ```rust
    #[bench]
    fn bench_nothing_slowly(b: &mut Bencher) {
    	b.iter(|| do_nothing_slowly());
    }
    ```

  * stable: `benches/` + `criterion`

    * `[dev-dependencies] criterion = "..."`

    * ```rust
      fn fibonacci_benchmark(c: &mut Criterion) {
      	c.bench_function("fibonacci 8", |b| b.iter(|| slow_fibonacci(8)));
      } 
      criterion_group!(fib_bench, fibonacci_benchmark);
      criterion_main!(fib_bench);
      ```

    * 



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
    
    * ```toml
      # cargo_manifest_example/Cargo.toml
      # We can write comments with `#` within a manifest file
      [package]
      name = "cargo-metadata-example"
      version = "1.2.3"
      description = "An example of Cargo metadata"
      documentation = "https://docs.rs/dummy_crate"
      license = "MIT"
      readme = "README.md"
      keywords = ["example", "cargo", "mastering"]
      authors = ["Jack Daniels <jack@danie.ls>", "Iddie Ezzard <iddie@ezzy>"]
      build = "build.rs"
      edition = "2018"
      [package.metadata.settings]
      default-data-path = "/var/lib/example"
      [features]
      default=["mysql"]
      [build-dependencies]
      syntex = "^0.58"
      [dependencies]
      serde = "1.0"
      serde_json = "1.0"
      time = { git = "https://github.com/rust-lang/time", branch = "master" }
      mysql = { version = "1.2", optional = true }
      sqlite = { version = "2.5", optional = true }
      ```
    
    * description: long, free-from text
    
    * license
    
    * readme: link a file in the project
    
    * keywords: crates.io
    
    * authors
    
    * build: piece of Rust code that is compiled & run before the rest of the program is compiled
    
    * edition: 2015/2018
    
  * Cargo.lock
  
  * semantic versioning: major.minor.patch
  
  * cargo watch: cargo check -> recompile (watchman/nodemon from Node.js)
  
  * cargo edit: automatically add dependencies
  
  * cargo deb: create Debian packages
  
  * cargo outdated: show outdated crate dependencies
  
  * cargo install: `/home/user/.cargo/bin/directory`
  
  * create cargo-[cmd], set $PATH
  
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
  
* clippy: linter

* continuous integration

  * `.travis.yml`

    * ```yaml
      language: rust
      rust:
          - stable
          - beta
          - nightly
      matrix:
          allow_failures:
          	- rust: nightly
          fast_finish: true
      cache: cargo
      
      script:
      	- cargo build --verbose
      	- cargo test --verbose
      ```

  * `[![Build Status]\(http://travis-ci.org/$USERNAME/$REPO_NAME.svg?branch=...)]`

  * 







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
  
* Documentation

  * item level
    * structs/enum declarations/functions/trait constants...
    * single-line: `///`
    * multi-line: `/** ... */`
    * equiv to `#[doc="..."]`
    * `#[doc(hidden)]`: ignore generating docs
    * `#[doc(include)]`: include documentation from other files
  * module level
    * root level, `*.rs`
    * single-line: `//!`
    * multi-line: `/*! ... */`
    * `#![doc(html_logo_url = "image url")]`: add a logo to the top-left of your documentation page
    * `#![doc(html_root_url = "...")]`: set URL of the documentation page
    * `#![doc(html_playground_url = "...")]`: put a run button near the code examples
  * `cargo doc`: generate `target/doc/`
    * `--no-deps`
    * spawn a HTTP server by navigating inside the `target/doc` directory
    * `--open`: open documentation page
  * docs.rs
  * Github pages
  * external website
  * `mdbook`
  
* Dispatch

  * static dispatch: early binding
  * dynamic dispatch: vtable
  * 





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

* `impl` blocks



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
    
  * `unimplemented!()`
  
  * testing
  
    * `assert{_eq/_ne}!`
    * `debug_assert!`: only effective on debug builds





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
* rustfmt: formatter
* racer: lookup into standard libraries, code completion





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

* trait

  * marker traits: `std::marker`
    * `Copy, Send, Sync`
  * `Default`
  * `From<T>`, `Into<T>`
  * associated type traits
    * `Iterator<T>`
  * inherited traits
  * `[derive]`
    * `Debug`: printing on the console for debugging purposes
    * `PartialEq/Eq`: compare partial-ordereing/total-ordering
    * `Copy/Clone`: create copy (`Copy`) and explicit `.clone` (`Clone`)

* thread

  * ```rust
    fn spawn<F, T>(f: F) -> JoinHandle<T> // jhandle in C++23?
    	where F: FnOnce() -> T,
    		F: Send + 'static,
    		T: Send + 'static
    ```

* testing

  * unit tests: `cargo test, mod tests, #[cfg(test)]`
    * small portion of an application independently verifying behaviors, within a module
    * `rustc --test ./unit_test.rs`
    * `RUST_TEST_THREADS=N ./unit_test`
    * `#[test]`: keep function out of release compilation
    * `#[should_panic]`: `-> !`
    * `#[ignore]`: ignore test functions when running `cargo test`
      * but run individually with `--ignored`
  * integration tests: `tests/`
    * `#[test]`
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

* `Vec<T>`

  * ```rust
    pub struct Vec<T> {
        buf: RawVec<T>,
        len: usize,
    }
    ```

  * 



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

