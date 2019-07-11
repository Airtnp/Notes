# Rust源码瞎读

基于2019/01/01的`36500deb1a`commit

希望这是个stable版本又不会太复杂... (像《Python源码分析》的Python2.6)

练习中英文写作

规定

* RFC引用: [RFC-XXXX]()
* Issue/Tracker引用: [#XXXXX]()
* [Pull request]引用: [!XXXXX]()
* 全文使用英文括号

## Update to track
* async/await
* NLL
* MIR/HIR
* miri
* const generics
* generic associated types (HKT/GAT)
* specialization
* new hashtable
* + [hashbrown](https://github.com/Amanieu/hashbrown)
* + [FxHash]
* + [SwissTable]
* parser
* + [libsyntax]
* + [rust-analyer](https://github.com/rust-analyzer/rust-analyzer)
* + [syn](https://github.com/dtolnay/syn)
+ [chalk](<https://github.com/rust-lang/chalk>)
+ cargo pipeline
+ new channel
+ parking_lot
+ crossbeam




## 参考(Reference)

* [Unstable-book](https://doc.rust-lang.org/nightly/unstable-book/)
  * 特性门(feature gate)相关
* [Rustonomicon](https://doc.rust-lang.org/stable/nomicon/)
* [Doc](https://doc.rust-lang.org/nightly/std/index.html)
* [nightly-rustc-doc](https://doc.rust-lang.org/nightly/nightly-rustc/rustc/)
* [Issues](https://github.com/rust-lang/rust/issues)
* [RFCs](https://github.com/rust-lang/rfcs/issues)
* [TRPL](https://doc.rust-lang.org/book/index.html)
* [Edition-guide](https://rust-lang-nursery.github.io/edition-guide/introduction.html)
  * 2015 vs 2018
* [Reference](https://doc.rust-lang.org/reference/introduction.html)
  * 文法相关



## 综述

`rust/src`各个文件夹的基本内容

* `bootstrap`
* `build_helper`
* `ci`
  * 给Code Integration使用
* `doc`
  * 文档， 包括(edition-guide, man, rust-by-example, rustc-guide)
* `etc`
  * gdb plugin
* `grammar`
* `jemalloc`
  * [jemalloc](https://github.com/jemalloc/jemalloc) 一种memory allocator的实现
* `liballoc`
* `libarena`
* `libcompiler_builtins`
* `libcore`
* `libfmt_macros`
* `libgraphviz`
* `liblibc`
* `libpanic_abort`
* `libpanic_unwind`
* `libprofiler_builtins`
* `librustc`
* `librustc_allocator`
* `librustc_apfloat`
* `librustc_borrowck`
* `librustc_asan`
* `librustc_codegen_llvm`
* `librustc_codegen_ssa`
* `librustc_codegen_utils`
* `librustc_cratesio_shim`
* `librustc_data_structure`
* `librustc_driver`
* `librustc_errors`
* `librustc_fs_util`
* `librustc_incremental`
* `librustc_lint`
* `librustc_llvm`
* `librustc_lsan`
* `librustc_metadata`
* `librustc_mir`
* `librustc_msan`
* `librustc_passes`
* `librustc_platform_intrinsics`
* `librustc_plugin`
* `librustc_privacy`
* `librustc_resolve`
* `librustc_save_analysis`
* `librustc_target`
* `librustc_traits`
* `librustc_typeck`
* `librustdoc`
* `libserialize`
* `libstd`
* `libsyntax`
* `libsyntax_ext`
* `libsyntax_pos`
* `libterm`
* `libtest`
* `libunwind`
* `llvm`
  * [LLVM Project](https://github.com/llvm-mirror/llvm)
* `llvm_emscripten`
  * [emscripten](https://github.com/kripken/emscripten) LLVM-to-JS
* `rt`
* `rtstartup`
* `rustc`
* `rustllvm`
* `stdsimd`
  * [SIMD RFC](https://github.com/rust-lang/rfcs/blob/master/text/2325-stable-simd.md)
* `test`
  * testcase
* `tools`