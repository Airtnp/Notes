## libsyntax

Rust的[parser](https://rust-lang.github.io/rustc-guide/the-parser.html)，包含词法分析(lexical analysis)和文法分析(syntax analysis/parsing, tokens -> AST)



### lib.rs

```rust
#![feature(crate_visibility_modifier)]
#![feature(nll)]
#![feature(rustc_attrs)]
#![feature(rustc_diagnostic_macros)]
#![feature(slice_sort_by_cached_key)]
#![feature(str_escape)]
#![feature(step_trait)]
#![feature(try_trait)]
#![feature(unicode_internals)]

#![recursion_limit="256"]
```

`#![feature(crate_visibility_modifier)]`使`crate`等价于`pub(crate)`，代表在整个crate可见。

* [#45388](https://github.com/rust-lang/rust/issues/45388) / [#53120](https://github.com/rust-lang/rust/issues/53120) / [RFC-2126](https://github.com/rust-lang/rfcs/pull/2126)
* [Visibility](https://doc.rust-lang.org/reference/visibility-and-privacy.html)



`#![feature(nll)]`代表non-lexical lifetime，这个话题比较复杂，讲的是不通过作用域分析，而通过MIR的控制流分析生命周期，建议参照以下文章:

* [RFC-2094](https://github.com/rust-lang/rfcs/pull/2094) / [#43234](https://github.com/rust-lang/rust/issues/43234)
* [Non Lexical Lifetime](https://zhuanlan.zhihu.com/p/25429005)
* [Rust >= 1.31/Edition 2018 NLL by default](https://stackoverflow.com/questions/53045978/why-can-the-rust-compiler-break-borrowing-rules-when-using-rust-1-31)
* [Introducing MIR](https://blog.rust-lang.org/2016/04/19/MIR.html)



`#![feature(rustc_attrs)]`允许使用`rustc_*`命名的feature gates。

* [#29642](https://github.com/rust-lang/rust/issues/29642) / [RFC-572](https://github.com/rust-lang/rfcs/pull/572)



`#![feature(rustc_diagnostic_macros)]`允许使用`__register_diagnostic!`/`__diagnostic_used!`/`__build_diagnostic_array!`。用途不明，仅用于编译器内部

* [**feature-gate-rustc-diagnostic-macros.rs**](https://github.com/rust-lang/rust/blob/master/src/test/ui/feature-gates/feature-gate-rustc-diagnostic-macros.rs)



`#![feature(str_escape)]`允许使用以下三个字符串转义(escape)函数

```rust
String::escape_debug(&self) -> String;
String::escape_default(&self) -> String;
String::escape_unicode(&self) -> String;
```

* `char::escape_debug(self) -> EscapeDebug`: 像Debug trait一样转义，对应可见`core::char::CharExt`代码: 

  * ```rust
    impl CharExt for char {
        fn escape_debug(self) -> EscapeDebug {
            let init_state = match self {
                '\t' => EscapeDefaultState::Backslash('t'),
                '\r' => EscapeDefaultState::Backslash('r'),
                '\n' => EscapeDefaultState::Backslash('n'),
                '\\' | '\'' | '"' => EscapeDefaultState::Backslash(self),
                c if is_printable(c) => EscapeDefaultState::Char(c),
                c => EscapeDefaultState::Unicode(c.escape_unicode()),
            };
            EscapeDebug(EscapeDefault { state: init_state })
        }
    }
    ```

* `char::escape_default(self) -> EscapeDefault`: 默认的转义

  * ```rust
    impl CharExt for char {
        #[inline]
        fn escape_default(self) -> EscapeDefault {
            let init_state = match self {
                '\t' => EscapeDefaultState::Backslash('t'),
                '\r' => EscapeDefaultState::Backslash('r'),
                '\n' => EscapeDefaultState::Backslash('n'),
                '\\' | '\'' | '"' => EscapeDefaultState::Backslash(self),
                '\x20' ... '\x7e' => EscapeDefaultState::Char(self),
                _ => EscapeDefaultState::Unicode(self.escape_unicode())
            };
            EscapeDefault { state: init_state }
        }
    }
    ```

* `char::escape_unicode(self) -> EscapeUnicode`: 转义成`\\u{NNNNNN}`

  * ```rust
    impl CharExt for char {
        #[inline]
        fn escape_unicode(self) -> EscapeUnicode {
            let c = self as u32;
    
            // or-ing 1 ensures that for c==0 the code computes that one
            // digit should be printed and (which is the same) avoids the
            // (31 - 32) underflow
            let msb = 31 - (c | 1).leading_zeros();
    
            // the index of the most significant hex digit
            let ms_hex_digit = msb / 4;
            EscapeUnicode {
                c: self,
                state: EscapeUnicodeState::Backslash,
                hex_digit_idx: ms_hex_digit as usize,
            }
        }
    }
    ```

* [#27791](https://github.com/rust-lang/rust/issues/27791)



`#![feature(step_trait)]`: 加入[Step trait](https://doc.rust-lang.org/1.26.0/std/iter/trait.Step.html)，表示双向可变长的遍历。

* [#42168](https://github.com/rust-lang/rust/issues/42168)



`#![feature(try_trait)]`: 加入[Try trait](https://doc.rust-lang.org/nightly/unstable-book/library-features/try-trait.html)，用于`?`操作符（原来的`?`操作符只能用于`Result<T, E>`。`expr?` =>

```rust
match expr {
    Ok(v) => v,
    Err(e) => return Try::from_error(From::from(e)), // 本来是 Err(e.into())
}
```

* [#42327](https://github.com/rust-lang/rust/issues/42327)
* [RFC-243](https://github.com/rust-lang/rfcs/pull/243) (加入`catch { ... }`, `?` ) / [RFC-1859](https://github.com/rust-lang/rfcs/pull/1859) (加入`Try` trait) / [RFC-2388](https://github.com/rust-lang/rfcs/pull/2388) (废弃`do catch`，加入`try { ... }`替代`catch { ... }` )
* [#31436](https://github.com/rust-lang/rust/issues/31436) 提到了`try!` -> `?`， `catch { ... }` -> `do catch { ... } ` -> `try { ... }`的变化



`#![feature(unicode_internals)]`: 用途不明，仅用于编译器内部



`#![recursion_limit="256"]` : 编译器内部使用，用于控制编译器递归深度

* [rustc::middle::recursion_limit](https://github.com/rust-lang/rust/blob/master/src/librustc/middle/recursion_limit.rs)



`#[macro_use] extern crate`: 导入外部库中所有的定义了`#[macro_export]`的宏(macro)。

* 在Rust Edition 2018中，可以直接使用`use crate_name::macro_name`导入。[macro-changes](https://rust-lang-nursery.github.io/edition-guide/rust-2018/macros/macro-changes.html)
  * [How to import all macros, derives, and procedural macros in Rust 2018 without using extern crate?](https://stackoverflow.com/questions/50999749/how-to-import-all-macros-derives-and-procedural-macros-in-rust-2018-without-us)



```rust
pub struct Globals {
    used_attrs: Lock<GrowableBitSet<AttrId>>,
    known_attrs: Lock<GrowableBitSet<AttrId>>,
    syntax_pos_globals: syntax_pos::Globals,
}

// type Lock = rustc_data_structures::sync::Lock;
// type GrowableBitSet = rustc_data_structures::bit_set::GrowableBitSet;

scoped_thread_local!(pub static GLOBALS: Globals);
```

记录全局attributes和源代码位置关系。

* `Lock<T>`这里是一个根据全局`cfg!(parallel_queries)`变化，并行则为`parking_lot::Mutex<T>`，否则则为`RefCell<T>`
  * [`Cell<T>`, `RefCell<T>`](https://doc.rust-lang.org/book/ch15-05-interior-mutability.html)提供了内部可变性(interior mutability)。
    * [内部可变性](内部可变性 - F001的文章 - 知乎
      https://zhuanlan.zhihu.com/p/22111297)
    * [Interior Mutability](https://doc.rust-lang.org/book/ch15-05-interior-mutability.html)

* `Lrc<T>`同理，选择`Arc<T>`或`Rc<T>`



`scoped_thread_local!`表示仅在一个作用域有效的线程本地变量(thread local storage)，已经被废弃(deprecated)。

* [ScopedKey](https://doc.rust-lang.org/1.7.0/std/thread/struct.ScopedKey.html) / [#27715](https://github.com/rust-lang/rust/issues/27715)
* [scoped-tls](https://docs.rs/scoped-tls/0.1.2/scoped_tls/)



### parse

#### token.rs

`#[derive(RustcEncodable, RustcDecodable)]`是编译器实现的序列化，现在应该使用`serde` crate。



```rust
#[derive(Clone, PartialEq, RustcEncodable, RustcDecodable, Hash, Debug, Copy)]
pub enum Lit {
    Byte(ast::Name),
    Char(ast::Name),
    Integer(ast::Name),
    Float(ast::Name),
    Str_(ast::Name),
    StrRaw(ast::Name, u16), /* raw str delimited by n hash symbols */
    ByteStr(ast::Name),
    ByteStrRaw(ast::Name, u16), /* raw byte str delimited by n hash symbols */
}

#[derive(Clone, RustcEncodable, RustcDecodable, PartialEq, Debug)]
pub enum Token {
    Eq,
    Lt,
    Le,
    EqEq,
    Ne,
    Ge,
    Gt,
    AndAnd,
    OrOr,
    Not,
    Tilde,
    BinOp(BinOpToken),
    BinOpEq(BinOpToken),

    At,
    Dot,
    DotDot,
    DotDotDot,
    DotDotEq,
    Comma,
    Semi,
    Colon,
    ModSep,
    RArrow,
    LArrow,
    FatArrow,
    Pound,
    Dollar,
    Question,
    SingleQuote,
    OpenDelim(DelimToken),
    CloseDelim(DelimToken),

    Literal(Lit, Option<ast::Name>),
    
    Ident(ast::Ident, /* is_raw */ bool),
    Lifetime(ast::Ident),
    
    Interpolated(Lrc<(Nonterminal, LazyTokenStream)>),
    
    DocComment(ast::Name),
    
    Whitespace,
    Comment,
    Shebang(ast::Name),

    Eof,
}
```

所有Token

* 表达式操作符(expression operator) [Operator Expression](https://doc.rust-lang.org/reference/expressions/operator-expr.html)

  * `BinOpToken`  => `BinOp` / `BinOpEq`(仅为`=`)

* 结构性操作符(structural operator)
  * `@, `.`, `...`, `;`, `:`, `&`, `$`, `?`, `::`(modsep), `@`(#), ...
  * `DelimToken`: (), {}, [], empty => `OpenDelim` / `CloseDelim`

* 字面量(literal)

  * `Lit`： byte, char, integer, float, str_, raw str, byte str, raw byte str

* 标识符(identifier)
  * `Ident`
  * `Lifetime`

* `Interpolated(Lrc<(Nonterminal, LazyTokenStream)>)`，用于宏展开

  * > An `Interpolated` token means that we have a `Nonterminal` which is often a parsed AST item. 

  * ```rust
    #[derive(Clone, RustcEncodable, RustcDecodable)]
    /// For interpolation during macro expansion.
    pub enum Nonterminal {
        NtItem(P<ast::Item>),
        NtBlock(P<ast::Block>),
        NtStmt(ast::Stmt),
        NtPat(P<ast::Pat>),
        NtExpr(P<ast::Expr>),
        NtTy(P<ast::Ty>),
        NtIdent(ast::Ident, /* is_raw */ bool),
        NtLifetime(ast::Ident),
        NtLiteral(P<ast::Expr>),
        /// Stuff inside brackets for attributes
        NtMeta(ast::MetaItem),
        NtPath(ast::Path),
        NtVis(ast::Visibility),
        NtTT(TokenTree),
        // These are not exposed to macros, but are used by quasiquote.
        NtArm(ast::Arm),
        NtImplItem(ast::ImplItem),
        NtTraitItem(ast::TraitItem),
        NtForeignItem(ast::ForeignItem),
        NtGenerics(ast::Generics),
        NtWhereClause(ast::WhereClause),
        NtArg(ast::Arg),
    }
    
    pub struct LazyTokenStream(Lock<Option<TokenStream>>);
    ```

* 文档注释(DocComment) `///`

* 空白符(Whitespace)

* 注释(Comment)

* Shebang `#!/usr/bin/rust`

* 终止符(Eof)



```rust
#[cfg(target_arch = "x86_64)]
static_assert!(MEM_SIZE_OF_STATEMENT: mem::size_of::<Token>() == 16);

// 其中rustc_data_structure::static_assert宏定义如下
#[macro_export]
#[allow_internal_unstable]
macro_rules! static_assert {
    ($name:ident: $test:expr) => {
        // Use the bool to access an array such that if the bool is false, the access
        // is out-of-bounds.
        #[allow(dead_code)]
        static $name: () = [()][!($test: bool) as usize];
    }
}
```

`rustc_data_structure::static_assert!(name: test)`做编译期检查`mem::size_of::<Token>() == 16`，为了避免`Token`过大



```rust
impl Token {
    crate fn can_begin_expr(&self) -> bool {
        match *self {
            Ident(ident, is_raw)              =>
                ident_can_begin_expr(ident, is_raw), // value name or keyword
            OpenDelim(..)                     | // tuple, array or block
            Literal(..)                       | // literal
            Not                               | // operator not
            BinOp(Minus)                      | // unary minus
            BinOp(Star)                       | // dereference
            BinOp(Or) | OrOr                  | // closure
            BinOp(And)                        | // reference
            AndAnd                            | // double reference
            // DotDotDot is no longer supported, but we need some way to display the error
            DotDot | DotDotDot | DotDotEq     | // range notation
            Lt | BinOp(Shl)                   | // associated path
            ModSep                            | // global path
            Lifetime(..)                      | // labeled loop
            Pound                             => true, // expression attributes
            Interpolated(ref nt) => match nt.0 {
                NtLiteral(..) |
                NtIdent(..)   |
                NtExpr(..)    |
                NtBlock(..)   |
                NtPath(..)    |
                NtLifetime(..) => true,
                _ => false,
            },
            _ => false,
        }
    }
}
```

可以作为表达式开头的`Token`: 

* 标识符 -> 关键字/标识符
* `(/[/{` -> 元组(tuple)， 数列(array)，块(block)
* 字面量 -> 字面量
* `!` -> `!expr`
* `-` -> 一元负 (`+`被在`is_like_plus`中单独处理)
* `*` -> 解引用
* `|` 或 `||` -> 闭包(closure, `Fn`, `FnOnce`, `FnMut`)
* `&` -> 引用
* `&&` -> 双重引用
* `..` | `..=` | `...` -> exclusive(`[a, b)`)/inclusive(`[a, b]`)/不再支持的inclusive范围(range notation)
* `<` |`<<` -> 关联路径(associated path, `<_ as T>::`)
* `::` -> 全局路径(global path)
* `'a` -> 标记循环(labeled loop)
* `#` -> 表达式attributes(expression attributes)
* Interpolated -> 递归处理以上情况



```rust
impl Token {
    crate fn can_begin_type(&self) -> bool {
        match *self {
            Ident(ident, is_raw)        =>
                ident_can_begin_type(ident, is_raw), // type name or keyword
            OpenDelim(Paren)            | // tuple
            OpenDelim(Bracket)          | // array
            Not                         | // never
            BinOp(Star)                 | // raw pointer
            BinOp(And)                  | // reference
            AndAnd                      | // double reference
            Question                    | // maybe bound in trait object
            Lifetime(..)                | // lifetime bound in trait object
            Lt | BinOp(Shl)             | // associated path
            ModSep                      => true, // global path
            Interpolated(ref nt) => match nt.0 {
                NtIdent(..) | NtTy(..) | NtPath(..) | NtLifetime(..) => true,
                _ => false,
            },
            _ => false,
        }
    }
}
```

可以作为类型起始的`Token`: 

* 标识符 -> 类型名/关键字
* `(` -> 元组类型
* `[` -> 数列类型
* `！` -> bottom/panic/never
* `*` -> 裸指针
* `&` -> 引用
* `&&` -> 双重引用
* `?` -> Trait对象中的约束(`<T: ?Sized>`)
* `'a` -> Trait对象中的生命周期约束(`<T: 'a>`)
* `::` -> 全局路径
* `Interpolated` -> 递归处理



可能为路径起始

* `::`/`<`/`<<`/路径段关键字(path segment keyword, `super | self | crate | $crate`)/非保留的标识符



可能为泛型约束起始

* 路径起始
* `‘a`/`for`/`?`/`(`



可能为字面量或布尔的起始

* 字面量/`-`/`True`/`False`/Interpolated



```rust
impl Token {
    crate fn glue(self, joint: Token) -> Option<Token> {
        Some(match self {
            Eq => match joint {
                Eq => EqEq,
                Gt => FatArrow,
                _ => return None,
            },
            Lt => match joint {
                Eq => Le,
                Lt => BinOp(Shl),
                Le => BinOpEq(Shl),
                BinOp(Minus) => LArrow,
                _ => return None,
            },
            Gt => match joint {
                Eq => Ge,
                Gt => BinOp(Shr),
                Ge => BinOpEq(Shr),
                _ => return None,
            },
            Not => match joint {
                Eq => Ne,
                _ => return None,
            },
            BinOp(op) => match joint {
                Eq => BinOpEq(op),
                BinOp(And) if op == And => AndAnd,
                BinOp(Or) if op == Or => OrOr,
                Gt if op == Minus => RArrow,
                _ => return None,
            },
            Dot => match joint {
                Dot => DotDot,
                DotDot => DotDotDot,
                _ => return None,
            },
            DotDot => match joint {
                Dot => DotDotDot,
                Eq => DotDotEq,
                _ => return None,
            },
            Colon => match joint {
                Colon => ModSep,
                _ => return None,
            },
            SingleQuote => match joint {
                Ident(ident, false) => {
                    let name = Symbol::intern(&format!("'{}", ident));
                    Lifetime(symbol::Ident {
                        name,
                        span: ident.span,
                    })
                }
                _ => return None,
            },

            Le | EqEq | Ne | Ge | AndAnd | OrOr | Tilde | BinOpEq(..) | At | DotDotDot |
            DotDotEq | Comma | Semi | ModSep | RArrow | LArrow | FatArrow | Pound | Dollar |
            Question | OpenDelim(..) | CloseDelim(..) => return None,

            Literal(..) | Ident(..) | Lifetime(..) | Interpolated(..) | DocComment(..) |
            Whitespace | Comment | Shebang(..) | Eof => return None,
        })
    }
    
    crate fn similar_tokens(&self) -> Option<Vec<Token>> {
        match *self {
            Comma => Some(vec![Dot, Lt]),
            Semi => Some(vec![Colon]),
            _ => None
        }
    }
}
```

`glue`拼接两个`Token`, `similar_tokens`返回可能被拼错的`Token` (`,`: `./<`, `;`: `:`)



```rust
impl Token {
    pub fn interpolated_to_tokenstream(&self, sess: &ParseSess, span: Span)
        -> TokenStream
    {
        let nt = match *self {
            Token::Interpolated(ref nt) => nt,
            _ => panic!("only works on interpolated tokens"),
        };

        let mut tokens = None;

        match nt.0 {
            Nonterminal::NtItem(ref item) => {
                tokens = prepend_attrs(sess, &item.attrs, item.tokens.as_ref(), span);
            }
            Nonterminal::NtTraitItem(ref item) => {
                tokens = prepend_attrs(sess, &item.attrs, item.tokens.as_ref(), span);
            }
            Nonterminal::NtImplItem(ref item) => {
                tokens = prepend_attrs(sess, &item.attrs, item.tokens.as_ref(), span);
            }
            Nonterminal::NtIdent(ident, is_raw) => {
                let token = Token::Ident(ident, is_raw);
                tokens = Some(TokenTree::Token(ident.span, token).into());
            }
            Nonterminal::NtLifetime(ident) => {
                let token = Token::Lifetime(ident);
                tokens = Some(TokenTree::Token(ident.span, token).into());
            }
            Nonterminal::NtTT(ref tt) => {
                tokens = Some(tt.clone().into());
            }
            _ => {}
        }

        let tokens_for_real = nt.1.force(|| {
            let source = pprust::token_to_string(self);
            let filename = FileName::macro_expansion_source_code(&source);
            parse_stream_from_source_str(filename, source, sess, Some(span))
        });

        if let Some(tokens) = tokens {
            if tokens.probably_equal_for_proc_macro(&tokens_for_real) {
                return tokens
            }
            info!("cached tokens found, but they're not \"probably equal\", \
                   going with stringified version");
        }
        return tokens_for_real
    }
}

fn prepend_attrs(sess: &ParseSess,
                 attrs: &[ast::Attribute],
                 tokens: Option<&tokenstream::TokenStream>,
                 span: syntax_pos::Span)
    -> Option<tokenstream::TokenStream>
{
    let tokens = tokens?;
    if attrs.len() == 0 {
        return Some(tokens.clone())
    }
    let mut builder = tokenstream::TokenStreamBuilder::new();
    for attr in attrs {
        assert_eq!(attr.style, ast::AttrStyle::Outer,
                   "inner attributes should prevent cached tokens from existing");

        let source = pprust::attr_to_string(attr);
        let macro_filename = FileName::macro_expansion_source_code(&source);
        if attr.is_sugared_doc {
            let stream = parse_stream_from_source_str(
                macro_filename,
                source,
                sess,
                Some(span),
            );
            builder.push(stream);
            continue
        }

        // synthesize # [ $path $tokens ] manually here
        let mut brackets = tokenstream::TokenStreamBuilder::new();

        // For simple paths, push the identifier directly
        if attr.path.segments.len() == 1 && attr.path.segments[0].args.is_none() {
            let ident = attr.path.segments[0].ident;
            let token = Ident(ident, ident.as_str().starts_with("r#"));
            brackets.push(tokenstream::TokenTree::Token(ident.span, token));

        // ... and for more complicated paths, fall back to a reparse hack that
        // should eventually be removed.
        } else {
            let stream = parse_stream_from_source_str(
                macro_filename,
                source,
                sess,
                Some(span),
            );
            brackets.push(stream);
        }

        brackets.push(attr.tokens.clone());

        // The span we list here for `#` and for `[ ... ]` are both wrong in
        // that it encompasses more than each token, but it hopefully is "good
        // enough" for now at least.
        builder.push(tokenstream::TokenTree::Token(attr.span, Pound));
        let delim_span = DelimSpan::from_single(attr.span);
        builder.push(tokenstream::TokenTree::Delimited(
            delim_span, DelimToken::Bracket, brackets.build().into()));
    }
    builder.push(tokens.clone());
    Some(builder.build())
}
```

#![TODO] 解释这个函数，需要`libsyntax_ext`和`librustc/hir`



#### lexer

##### mod.rs

```rust
// 带位置的Token信息
#[derive(Clone, Debug)]
pub struct TokenAndSpan {
    pub tok: token::Token,
    pub sp: Span,
}

// 这里的Span是syntax_pos::Span
// 存储代码位置，用于proc macro
#[repr(packed)]
pub struct Span(u32);

// Tag = 0, inline format.
// -------------------------------------------------------------
// | base 31:8  | len 7:1  | ctxt (currently 0 bits) | tag 0:0 |
// -------------------------------------------------------------

// Tag = 0, inline format.
// -------------------------------------------------------------
// | base 31:8  | len 7:1  | ctxt (currently 0 bits) | tag 0:0 |
// -------------------------------------------------------------

#[derive(Clone, Copy, Hash, PartialEq, Eq, Ord, PartialOrd)]
pub struct SpanData {
    pub lo: BytePos,
    pub hi: BytePos,
    pub ctxt: SyntaxContext, // 宏展开的上下文
}
```

`Span`是`SpanData`的紧凑形式。





```rust
pub struct StringReader<'a> {
    pub sess: &'a ParseSess,
    /// 下一个读取的字符的位置(`SourceMap`中的位置)
    pub next_pos: BytePos,
    /// 当前字符的位置
    pub pos: BytePos,
    /// 当前字符
    pub ch: Option<char>,
    pub source_file: Lrc<syntax_pos::SourceFile>,
    /// 终止读取的位置
    pub end_src_index: usize,
    // 缓存的下一个Token的信息
    peek_tok: token::Token,
    peek_span: Span,
    peek_span_src_raw: Span,
    // 致命错误, fatal_errs[].emit()/.buffer() -> Vec<Diagnostic>;
    fatal_errs: Vec<DiagnosticBuilder<'a>>,
    // 对源文件文本的引用，相当于`self.source_file.src.as_ref().unwrap()`
    src: Lrc<String>,
    token: token::Token,
    span: Span,
    /// 不计算`override_span`的原范围
    span_src_raw: Span,
    /// 存储OpenDelimter和位置信息的栈，用于错误信息
    open_braces: Vec<(token::DelimToken, Span)>,
    /// 存储所有配对的括号的类型和位置，仅用于错配的括号遇到EOF时候的错误处理
    matching_delim_spans: Vec<(token::DelimToken, Span, Span)>,
    /// 在生成新的位置信息时，可能用`override_span`替换之
    crate override_span: Option<Span>,
    last_unclosed_found_span: Option<Span>,
}
```

`SourceMap`追踪(track)一个crate中的所有源代码(`SourceFile`, `SourceFIleAndBytePos`, `SourceFileAndLine`)，包含文件，内存中的字符串(in memory strings ?)，宏展开都代表了`SourceMap`中以`SourceFile`形式存储的一段连续的字节。



```rust
impl<'a> StringReader<'a> {
    pub fn try_next_token(&mut self) -> Result<TokenAndSpan, ()> {
        assert!(self.fatal_errs.is_empty());
        let ret_val = TokenAndSpan {
            tok: replace(&mut self.peek_tok, token::Whitespace),
            sp: self.peek_span,
        };
        self.advance_token()?;
        self.span_src_raw = self.peek_span_src_raw;

        Ok(ret_val)
    }

    fn try_real_token(&mut self) -> Result<TokenAndSpan, ()> {
        let mut t = self.try_next_token()?;
        loop {
            match t.tok {
                token::Whitespace | token::Comment | token::Shebang(_) => {
                    t = self.try_next_token()?;
                }
                _ => break,
            }
        }

        self.token = t.tok.clone();
        self.span = t.sp;

        Ok(t)
    }
    
    /// 读取下一个`Token`并存储到`peek_*`中
    fn advance_token(&mut self) -> Result<(), ()> {
        // 如果是whitespace/shebang/comment则扫描并返回
        match self.scan_whitespace_or_comment() {
            Some(comment) => {
                self.peek_span_src_raw = comment.sp;
                self.peek_span = comment.sp;
                self.peek_tok = comment.tok;
            }
            None => {
                // 如果到达文件尾部
                if self.is_eof() {
                    self.peek_tok = token::Eof;
                    let (real, raw) = self.mk_sp_and_raw(
                        self.source_file.end_pos,
                        self.source_file.end_pos,
                    );
                    self.peek_span = real;
                    self.peek_span_src_raw = raw;
                } else { // 否则读取下一个`Token`
                    let start_bytepos = self.pos;
                    self.peek_tok = self.next_token_inner()?;
                    let (real, raw) = self.mk_sp_and_raw(start_bytepos, self.pos);
                    self.peek_span = real;
                    self.peek_span_src_raw = raw;
                };
            }
        }

        Ok(())
    }
    
    /// 读取下一个字符并存到`ch`中
    crate fn bump(&mut self) {
        let next_src_index = self.src_index(self.next_pos);
        if next_src_index < self.end_src_index {
            let next_ch = char_at(&self.src, next_src_index);
            let next_ch_len = next_ch.len_utf8();

            self.ch = Some(next_ch);
            self.pos = self.next_pos;
            self.next_pos = self.next_pos + Pos::from_usize(next_ch_len);
        } else {
            self.ch = None;
            self.pos = self.next_pos;
        }
    }
}
```

`try_next_token`从`peek_*`中读取下一个`Token`信息并向前移动扫描位置，`try_real_token`反复执行直到读取到有意义的`Token`。



```rust
impl<'a> StringReader<'a> {
    fn next_token_inner(&mut self) -> Result<token::Token, ()> {
        let c = self.ch;

        if ident_start(c) {
            let (is_ident_start, is_raw_ident) =
                match (c.unwrap(), self.nextch(), self.nextnextch()) {
                    // r# followed by an identifier starter is a raw identifier.
                    // This is an exception to the r# case below.
                    ('r', Some('#'), x) if ident_start(x) => (true, true),
                    // r as in r" or r#" is part of a raw string literal.
                    // b as in b' is part of a byte literal.
                    // They are not identifiers, and are handled further down.
                    ('r', Some('"'), _) |
                    ('r', Some('#'), _) |
                    ('b', Some('"'), _) |
                    ('b', Some('\''), _) |
                    ('b', Some('r'), Some('"')) |
                    ('b', Some('r'), Some('#')) => (false, false),
                    _ => (true, false),
                };

            if is_ident_start {
                let raw_start = self.pos;
                if is_raw_ident {
                    // Consume the 'r#' characters.
                    self.bump();
                    self.bump();
                }

                let start = self.pos;
                self.bump();

                while ident_continue(self.ch) {
                    self.bump();
                }

                return Ok(self.with_str_from(start, |string| {
                    // FIXME: perform NFKC normalization here. (Issue #2253)
                    let ident = self.mk_ident(string);

                    if is_raw_ident && (ident.is_path_segment_keyword() ||
                                        ident.name == keywords::Underscore.name()) {
                        self.fatal_span_(raw_start, self.pos,
                            &format!("`r#{}` is not currently supported.", ident.name)
                        ).raise();
                    }

                    if is_raw_ident {
                        let span = self.mk_sp(raw_start, self.pos);
                        self.sess.raw_identifier_spans.borrow_mut().push(span);
                    }

                    token::Ident(ident, is_raw_ident)
                }));
            }
        }

        if is_dec_digit(c) {
            let num = self.scan_number(c.unwrap());
            let suffix = self.scan_optional_raw_name();
            debug!("next_token_inner: scanned number {:?}, {:?}", num, suffix);
            return Ok(token::Literal(num, suffix));
        }

        match c.expect("next_token_inner called at EOF") {
            // One-byte tokens.
            ';' => {
                self.bump();
                Ok(token::Semi)
            }
            ',' => {
                self.bump();
                Ok(token::Comma)
            }
            '.' => {
                self.bump();
                if self.ch_is('.') {
                    self.bump();
                    if self.ch_is('.') {
                        self.bump();
                        Ok(token::DotDotDot)
                    } else if self.ch_is('=') {
                        self.bump();
                        Ok(token::DotDotEq)
                    } else {
                        Ok(token::DotDot)
                    }
                } else {
                    Ok(token::Dot)
                }
            }
            '(' => {
                self.bump();
                Ok(token::OpenDelim(token::Paren))
            }
            ')' => {
                self.bump();
                Ok(token::CloseDelim(token::Paren))
            }
            '{' => {
                self.bump();
                Ok(token::OpenDelim(token::Brace))
            }
            '}' => {
                self.bump();
                Ok(token::CloseDelim(token::Brace))
            }
            '[' => {
                self.bump();
                Ok(token::OpenDelim(token::Bracket))
            }
            ']' => {
                self.bump();
                Ok(token::CloseDelim(token::Bracket))
            }
            '@' => {
                self.bump();
                Ok(token::At)
            }
            '#' => {
                self.bump();
                Ok(token::Pound)
            }
            '~' => {
                self.bump();
                Ok(token::Tilde)
            }
            '?' => {
                self.bump();
                Ok(token::Question)
            }
            ':' => {
                self.bump();
                if self.ch_is(':') {
                    self.bump();
                    Ok(token::ModSep)
                } else {
                    Ok(token::Colon)
                }
            }

            '$' => {
                self.bump();
                Ok(token::Dollar)
            }

            // Multi-byte tokens.
            '=' => {
                self.bump();
                if self.ch_is('=') {
                    self.bump();
                    Ok(token::EqEq)
                } else if self.ch_is('>') {
                    self.bump();
                    Ok(token::FatArrow)
                } else {
                    Ok(token::Eq)
                }
            }
            '!' => {
                self.bump();
                if self.ch_is('=') {
                    self.bump();
                    Ok(token::Ne)
                } else {
                    Ok(token::Not)
                }
            }
            '<' => {
                self.bump();
                match self.ch.unwrap_or('\x00') {
                    '=' => {
                        self.bump();
                        Ok(token::Le)
                    }
                    '<' => {
                        Ok(self.binop(token::Shl))
                    }
                    '-' => {
                        self.bump();
                        Ok(token::LArrow)
                    }
                    _ => {
                        Ok(token::Lt)
                    }
                }
            }
            '>' => {
                self.bump();
                match self.ch.unwrap_or('\x00') {
                    '=' => {
                        self.bump();
                        Ok(token::Ge)
                    }
                    '>' => {
                        Ok(self.binop(token::Shr))
                    }
                    _ => {
                        Ok(token::Gt)
                    }
                }
            }
            '\'' => {
                // Either a character constant 'a' OR a lifetime name 'abc
                let start_with_quote = self.pos;
                self.bump();
                let start = self.pos;

                // the eof will be picked up by the final `'` check below
                let c2 = self.ch.unwrap_or('\x00');
                self.bump();

                // If the character is an ident start not followed by another single
                // quote, then this is a lifetime name:
                if ident_start(Some(c2)) && !self.ch_is('\'') {
                    while ident_continue(self.ch) {
                        self.bump();
                    }
                    // lifetimes shouldn't end with a single quote
                    // if we find one, then this is an invalid character literal
                    if self.ch_is('\'') {
                        self.fatal_span_verbose(start_with_quote, self.next_pos,
                                String::from("character literal may only contain one codepoint"))
                            .raise();

                    }

                    // Include the leading `'` in the real identifier, for macro
                    // expansion purposes. See #12512 for the gory details of why
                    // this is necessary.
                    let ident = self.with_str_from(start, |lifetime_name| {
                        self.mk_ident(&format!("'{}", lifetime_name))
                    });

                    return Ok(token::Lifetime(ident));
                }

                let valid = self.scan_char_or_byte(start, c2, /* ascii_only */ false, '\'');

                if !self.ch_is('\'') {
                    let pos = self.pos;

                    loop {
                        self.bump();
                        if self.ch_is('\'') {
                            let start = self.src_index(start);
                            let end = self.src_index(self.pos);
                            self.bump();
                            let span = self.mk_sp(start_with_quote, self.pos);
                            self.sess.span_diagnostic
                                .struct_span_err(span,
                                                 "character literal may only contain one codepoint")
                                .span_suggestion_with_applicability(
                                    span,
                                    "if you meant to write a `str` literal, use double quotes",
                                    format!("\"{}\"", &self.src[start..end]),
                                    Applicability::MachineApplicable
                                ).emit();
                            return Ok(token::Literal(token::Str_(Symbol::intern("??")), None))
                        }
                        if self.ch_is('\n') || self.is_eof() || self.ch_is('/') {
                            // Only attempt to infer single line string literals. If we encounter
                            // a slash, bail out in order to avoid nonsensical suggestion when
                            // involving comments.
                            break;
                        }
                    }

                    self.fatal_span_verbose(start_with_quote, pos,
                        String::from("character literal may only contain one codepoint")).raise();
                }

                let id = if valid {
                    self.name_from(start)
                } else {
                    Symbol::intern("0")
                };

                self.bump(); // advance ch past token
                let suffix = self.scan_optional_raw_name();

                Ok(token::Literal(token::Char(id), suffix))
            }
            'b' => {
                self.bump();
                let lit = match self.ch {
                    Some('\'') => self.scan_byte(),
                    Some('"') => self.scan_byte_string(),
                    Some('r') => self.scan_raw_byte_string(),
                    _ => unreachable!(),  // Should have been a token::Ident above.
                };
                let suffix = self.scan_optional_raw_name();

                Ok(token::Literal(lit, suffix))
            }
            '"' => {
                let start_bpos = self.pos;
                let mut valid = true;
                self.bump();

                while !self.ch_is('"') {
                    if self.is_eof() {
                        let last_bpos = self.pos;
                        self.fatal_span_(start_bpos,
                                         last_bpos,
                                         "unterminated double quote string").raise();
                    }

                    let ch_start = self.pos;
                    let ch = self.ch.unwrap();
                    self.bump();
                    valid &= self.scan_char_or_byte(ch_start, ch, /* ascii_only */ false, '"');
                }
                // adjust for the ASCII " at the start of the literal
                let id = if valid {
                    self.name_from(start_bpos + BytePos(1))
                } else {
                    Symbol::intern("??")
                };
                self.bump();
                let suffix = self.scan_optional_raw_name();

                Ok(token::Literal(token::Str_(id), suffix))
            }
            'r' => {
                let start_bpos = self.pos;
                self.bump();
                let mut hash_count: u16 = 0;
                while self.ch_is('#') {
                    if hash_count == 65535 {
                        let bpos = self.next_pos;
                        self.fatal_span_(start_bpos,
                                         bpos,
                                         "too many `#` symbols: raw strings may be \
                                         delimited by up to 65535 `#` symbols").raise();
                    }
                    self.bump();
                    hash_count += 1;
                }

                if self.is_eof() {
                    self.fail_unterminated_raw_string(start_bpos, hash_count);
                } else if !self.ch_is('"') {
                    let last_bpos = self.pos;
                    let curr_char = self.ch.unwrap();
                    self.fatal_span_char(start_bpos,
                                         last_bpos,
                                         "found invalid character; only `#` is allowed \
                                         in raw string delimitation",
                                         curr_char).raise();
                }
                self.bump();
                let content_start_bpos = self.pos;
                let mut content_end_bpos;
                let mut valid = true;
                'outer: loop {
                    if self.is_eof() {
                        self.fail_unterminated_raw_string(start_bpos, hash_count);
                    }
                    // if self.ch_is('"') {
                    // content_end_bpos = self.pos;
                    // for _ in 0..hash_count {
                    // self.bump();
                    // if !self.ch_is('#') {
                    // continue 'outer;
                    let c = self.ch.unwrap();
                    match c {
                        '"' => {
                            content_end_bpos = self.pos;
                            for _ in 0..hash_count {
                                self.bump();
                                if !self.ch_is('#') {
                                    continue 'outer;
                                }
                            }
                            break;
                        }
                        '\r' => {
                            if !self.nextch_is('\n') {
                                let last_bpos = self.pos;
                                self.err_span_(start_bpos,
                                               last_bpos,
                                               "bare CR not allowed in raw string, use \\r \
                                                instead");
                                valid = false;
                            }
                        }
                        _ => (),
                    }
                    self.bump();
                }

                self.bump();
                let id = if valid {
                    self.name_from_to(content_start_bpos, content_end_bpos)
                } else {
                    Symbol::intern("??")
                };
                let suffix = self.scan_optional_raw_name();

                Ok(token::Literal(token::StrRaw(id, hash_count), suffix))
            }
            '-' => {
                if self.nextch_is('>') {
                    self.bump();
                    self.bump();
                    Ok(token::RArrow)
                } else {
                    Ok(self.binop(token::Minus))
                }
            }
            '&' => {
                if self.nextch_is('&') {
                    self.bump();
                    self.bump();
                    Ok(token::AndAnd)
                } else {
                    Ok(self.binop(token::And))
                }
            }
            '|' => {
                match self.nextch() {
                    Some('|') => {
                        self.bump();
                        self.bump();
                        Ok(token::OrOr)
                    }
                    _ => {
                        Ok(self.binop(token::Or))
                    }
                }
            }
            '+' => {
                Ok(self.binop(token::Plus))
            }
            '*' => {
                Ok(self.binop(token::Star))
            }
            '/' => {
                Ok(self.binop(token::Slash))
            }
            '^' => {
                Ok(self.binop(token::Caret))
            }
            '%' => {
                Ok(self.binop(token::Percent))
            }
            c => {
                let last_bpos = self.pos;
                let bpos = self.next_pos;
                let mut err = self.struct_fatal_span_char(last_bpos,
                                                          bpos,
                                                          "unknown start of token",
                                                          c);
                unicode_chars::check_for_substitution(self, c, &mut err);
                self.fatal_errs.push(err);

                Err(())
            }
        }
    }
}
```

`next_token_inner`足有370行，是词法解析的主体。获取下一个`Token`。

* `<XID_start>`
  * `r#<XID_start>` -> 裸标识符(raw identifier，用于重用keyword作为标识符)。 [RFC-2151](https://github.com/rust-lang/rfcs/pull/2151)
  * `r"|r#"|b"|b'|br"|br#"`是字符串(str, raw str, byte str, byte raw str)字面量或是字节字面量(`b'`)，不应作为标识符处理。特别的，`r#_`是不支持的。
  * 裸标识符的范围会被存入`self.sess.raw_identifier_span`
  * 未完成的特性: 对标识符做[NFKC Normalization](http://www.unicode.org/reports/tr15/#Norm_Forms)
    * [#2253](https://github.com/rust-lang/rust/issues/2253)
    * [Python-#10952](https://bugs.python.org/issue10952) / [PEP-3131](https://www.python.org/dev/peps/pep-3131/)

* `[0-9]`
  * `scan_number`返回整数/浮点数字面量`Lit`，`scan_optional_raw_name`返回后缀，作为完整的`Token::Literal`
* `; | , | . | .. | ... | ..= | ( | ) | { | } | [ | ] | @ | # | ~ | ? | : | :: | = | == | => | ! | != | < | <= | <- | > >= | >> | - | -> | & | && | | | || | + | * | / | ^ | % |  ` : 遵循Maximal Munch直接判断并返回`Token`。
* `'`
  * `'<XID_start>[^']`: 必定为生命周期。存储时，带上`'`，用于与标识符在宏展开和卫生生命周期标识 (hygienic label)区分。
    * [#12512](https://github.com/rust-lang/rust/issues/12512#issuecomment-37137652)
  * 否则`scan_char_or_byte`获取一个字符，如果接着的字符是`'`则作为字符字面量。并和整数/浮点数字面量一样用`scan_optional_raw_name`解析后缀作为完整的`Token::Literal`，但字符/字符串字面量带后缀是不合法的。
  * 仅对同一行中且没遇到`/|EOF`的`‘XXX’`做提示变为字符串字面量，否则直接`FatalError`
* `b`
  * `b' | b" | br`代表`byte | byte str | byte raw str`，其余情况应当在处理标识符时已被处理，所以`unreachable()! / panic!`。属于字面量，所以同样解析后缀。
* `"` 调用`scan_char_or_byte`直到遇到`"`或EOF。是字面量所以后缀同理。
* `r`要求`'r#{n}....#{n}'`，`#`不能超过65534个。即使是裸字符串，也不允许单独的`\r`。是字面量所以后缀同理。
* `~`已经被移除不再作为递归数据结构的标识，但词法仍被保留作为按位取反的提示(不同于C，`~`并不作为按位取反，取而代之的是`!`)。
  * [RFC-59](https://github.com/rust-lang/rfcs/pull/59)
  * [~ is being removed from Rust - HN](https://news.ycombinator.com/item?id=7687351) / [~ is being removed from Rust - /r/rust](https://www.reddit.com/r/programming/comments/24kcl4/is_being_removed_from_rust/)







`Token`获取的调用链:

* `try_real_token` (检查并取得下一个有意义(非注释/空白符/Shebang)的`Token`，更新`span`和`tok`) ->
* `try_next_token` (检查并取得下一个`Token`，更新`span_src_raw`) ->
* `advance_token` (检查并获取下一个`Token` (包含`Eof`)，更新`peek_span, peek_span_src_raw, peek_tok`) ->
* `next_token_inner` (获取下一个`Token`) ->
* `bump` (获取下一个字符，更新`pos, next_pos, ch`)



`span_diagnostic`的分类

* `span_fatal` -> `FatalError` (这个类作为致命(fatal)错误的返回值)
* `span_err` -> `()`
* `span_warn` -> `()`
* `span_bug` -> `!` (直接`panic!(ExplicitBug)`，这个类作为编译器通过调用`.bug/.span_bug`崩溃的标志)
* `span_note` -> `()`
* `span_suggestion_with_applicability` -> `()`
  * `MachineApplicable | HasPlaceholders | MaybeIncorrect | Unspecified`
* `span_help` -> `()`



```rust
impl<'a> StringReader<'a> {
	fn scan_optional_raw_name(&mut self) -> Option<ast::Name> {
        if !ident_start(self.ch) {
            return None;
        }

        let start = self.pos;
        self.bump();

        while ident_continue(self.ch) {
            self.bump();
        }

        self.with_str_from(start, |string| {
            if string == "_" {
                self.sess.span_diagnostic
                    .struct_span_warn(self.mk_sp(start, self.pos),
                                      "underscore literal suffix is not allowed")
                    .warn("this was previously accepted by the compiler but is \
                          being phased out; it will become a hard error in \
                          a future release!")
                    .note("for more information, see issue #42326 \
                          <https://github.com/rust-lang/rust/issues/42326>")
                    .emit();
                None
            } else {
                Some(Symbol::intern(string))
            }
        })
    }
}
```

`scan_optional_raw_name`消耗`<XID_start><XID_continue>*`形式的标识符，仅用于解析后缀 ([suffix](https://doc.rust-lang.org/reference/tokens.html#suffixes)，`i32`， `f64`， `usize`)。

* [UAX #31](http://unicode.org/reports/tr31/) 定义了通用Unicode标识符格式和`XID_start`, `XID_continue`
* [#41723](https://github.com/rust-lang/rust/issues/41723) / [#42326](https://github.com/rust-lang/rust/issues/42326) 使`"Foo"_`和`1._`形式的字面量不合法 (仅有单下划线后缀的字面量)



```rust
impl<'a> StringReader<'a> {
    fn scan_comment(&mut self) -> Option<TokenAndSpan> {
        if let Some(c) = self.ch {
            if c.is_whitespace() {
                let msg = "called consume_any_line_comment, but there was whitespace";
                self.sess.span_diagnostic.span_err(self.mk_sp(self.pos, self.pos), msg);
            }
        }

        if self.ch_is('/') {
            match self.nextch() {
                Some('/') => {
                    self.bump();
                    self.bump();

                    // 区分行注释`//`和文档注释`///|//!`
                    let doc_comment = (self.ch_is('/') && !self.nextch_is('/')) || self.ch_is('!');
                    let start_bpos = self.pos - BytePos(2);

                    // //[^\n\r]*[\r\n|\n]
                    while !self.is_eof() {
                        match self.ch.unwrap() {
                            '\n' => break,
                            '\r' => {
                                if self.nextch_is('\n') {
                                    // CRLF
                                    break;
                                } else if doc_comment {
                                    self.err_span_(self.pos,
                                                   self.next_pos,
                                                   "bare CR not allowed in doc-comment");
                                }
                            }
                            _ => (),
                        }
                        self.bump();
                    }

                    if doc_comment {
                        self.with_str_from(start_bpos, |string| {
                            // 可能超过三个/，则不是文档注释
                            let tok = if is_doc_comment(string) {
                                token::DocComment(Symbol::intern(string))
                            } else {
                                token::Comment
                            };

                            Some(TokenAndSpan {
                                tok,
                                sp: self.mk_sp(start_bpos, self.pos),
                            })
                        })
                    } else {
                        Some(TokenAndSpan {
                            tok: token::Comment,
                            sp: self.mk_sp(start_bpos, self.pos),
                        })
                    }
                }
                Some('*') => {
                    // 块注释
                    self.bump();
                    self.bump();
                    self.scan_block_comment()
                }
                _ => None,
            }
        } else if self.ch_is('#') {
            if self.nextch_is('!') {

                // 内部特性`#![]`
                if self.nextnextch_is('[') {
                    return None;
                }

				// 如果是第一行的#! shebang
                let smap = SourceMap::new(FilePathMapping::empty());
                smap.files.borrow_mut().source_files.push(self.source_file.clone());
                let loc = smap.lookup_char_pos_adj(self.pos);
                debug!("Skipping a shebang");
                if loc.line == 1 && loc.col == CharPos(0) {
                    let start = self.pos;
                    while !self.ch_is('\n') && !self.is_eof() {
                        self.bump();
                    }
                    return Some(TokenAndSpan {
                        tok: token::Shebang(self.name_from(start)),
                        sp: self.mk_sp(start, self.pos),
                    });
                }
            }
            None
        } else {
            None
        }
    }
}
```

`scan_comment`消耗行注释`//`，文档注释`///|//!`，shebang 第一行的`#!`



```rust
impl<'a> StringReader<'a> {
    fn scan_whitespace_or_comment(&mut self) -> Option<TokenAndSpan> {
        match self.ch.unwrap_or('\0') {
            '/' | '#' => {
                let c = self.scan_comment();
                debug!("scanning a comment {:?}", c);
                c
            },
            c if is_pattern_whitespace(Some(c)) => {
                let start_bpos = self.pos;
                while is_pattern_whitespace(self.ch) {
                    self.bump();
                }
                let c = Some(TokenAndSpan {
                    tok: token::Whitespace,
                    sp: self.mk_sp(start_bpos, self.pos),
                });
                debug!("scanning whitespace: {:?}", c);
                c
            }
            _ => None,
        }
    }
}
```

`scan_whitespace_or_comment`消耗注释或空白符。

* 这里的空白符(whitespace)由[UAX #31 R3](http://unicode.org/reports/tr31/#R3) 定义。

  * ```rust
    pub const Pattern_White_Space_table: &super::SmallBoolTrie = &super::SmallBoolTrie {
        r1: &[
            0, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3
        ],
        r2: &[
            0x0000000100003e00, 0x0000000000000000, 0x0000000000000020, 0x000003000000c000
        ],
    };
    
    pub fn Pattern_White_Space(c: char) -> bool {
        Pattern_White_Space_table.lookup(c)
    }
    
    // 其中SmallBoolTrie的定义
    pub struct SmallBoolTrie {
        pub(crate) r1: &'static [u8],  // first level
        pub(crate) r2: &'static [u64],  // leaves
    }
    
    impl SmallBoolTrie {
        pub fn lookup(&self, c: char) -> bool {
            let c = c as u32;
            match self.r1.get((c >> 6) as usize) {
                Some(&child) => trie_range_leaf(c, self.r2[child as usize]),
                None => false,
            }
        }
    }
    
    fn trie_range_leaf(c: u32, bitmap_chunk: u64) -> bool {
        ((bitmap_chunk >> (c & 63)) & 1) != 0
    }
    ```

  * Rust中的`char`是[Unicode scalar value](http://www.unicode.org/glossary/#unicode_scalar_value) 类似但不同于[Unicode code point](http://www.unicode.org/glossary/#code_point)，目前是4 bytes。



```rust
impl<'a> StringReader<'a> {
    fn scan_block_comment(&mut self) -> Option<TokenAndSpan> {
        // 文档块注释: /** | /*!
        let is_doc_comment = self.ch_is('*') || self.ch_is('!');
        let start_bpos = self.pos - BytePos(2);

        let mut level: isize = 1;
        let mut has_cr = false;
        while level > 0 {
            if self.is_eof() {
                let msg = if is_doc_comment {
                    "unterminated block doc-comment"
                } else {
                    "unterminated block comment"
                };
                let last_bpos = self.pos;
                self.fatal_span_(start_bpos, last_bpos, msg).raise();
            }
            let n = self.ch.unwrap();
            match n {
                '/' if self.nextch_is('*') => {
                    level += 1;
                    self.bump();
                }
                '*' if self.nextch_is('/') => {
                    level -= 1;
                    self.bump();
                }
                '\r' => {
                    has_cr = true;
                }
                _ => (),
            }
            self.bump();
        }

        self.with_str_from(start_bpos, |string| {
			// /**/ 不应该是块文档注释
            let tok = if is_block_doc_comment(string) {
                let string = if has_cr {
                    self.translate_crlf(start_bpos,
                                        string,
                                        "bare CR not allowed in block doc-comment")
                } else {
                    string.into()
                };
                token::DocComment(Symbol::intern(&string[..]))
            } else {
                token::Comment
            };

            Some(TokenAndSpan {
                tok,
                sp: self.mk_sp(start_bpos, self.pos),
            })
        })
    }
}
```

`scan_block_comment`消耗块注释`/*`和文档块注释`/**|/*!`，块注释是嵌套的。



```rust
impl<'a> StringReader<'a> {
    fn scan_digits(&mut self, real_radix: u32, scan_radix: u32) -> usize {
        assert!(real_radix <= scan_radix);
        let mut len = 0;

        loop {
            let c = self.ch;
            if c == Some('_') {
                debug!("skipping a _");
                self.bump();
                continue;
            }
            match c.and_then(|cc| cc.to_digit(scan_radix)) {
                Some(_) => {
                    debug!("{:?} in scan_digits", c);
                    // 如果不存在于真实基底
                    if c.unwrap().to_digit(real_radix).is_none() {
                        self.err_span_(self.pos,
                                       self.next_pos,
                                       &format!("invalid digit for a base {} literal", real_radix));
                    }
                    len += 1;
                    self.bump();
                }
                _ => return len,
            }
        }
    }
    
    fn scan_number(&mut self, c: char) -> token::Lit {
        let mut base = 10;
        let start_bpos = self.pos;
        self.bump();

        let num_digits = if c == '0' {
            match self.ch.unwrap_or('\0') {
                'b' => {
                    self.bump();
                    base = 2;
                    self.scan_digits(2, 10)
                }
                'o' => {
                    self.bump();
                    base = 8;
                    self.scan_digits(8, 10)
                }
                'x' => {
                    self.bump();
                    base = 16;
                    self.scan_digits(16, 16)
                }
                '0'..='9' | '_' | '.' | 'e' | 'E' => {
                    self.scan_digits(10, 10) + 1
                }
                _ => {
                    // just a 0
                    return token::Integer(self.name_from(start_bpos));
                }
            }
        } else if c.is_digit(10) {
            self.scan_digits(10, 10) + 1
        } else {
            0
        };

        if num_digits == 0 {
            self.err_span_(start_bpos, self.pos, "no valid digits found for number");

            return token::Integer(Symbol::intern("0"));
        }

        // 可能为整数`N`，浮点数`N.N|NeN`， 范围`0..2`，整数字面量的方法/数据`12.foo()`
        if self.ch_is('.') && !self.nextch_is('.') &&
           !ident_start(self.nextch()) {
            self.bump();
            if self.ch.unwrap_or('\0').is_digit(10) {
                self.scan_digits(10, 10);
                self.scan_float_exponent();
            }
            let pos = self.pos;
            self.check_float_base(start_bpos, pos, base);

            token::Float(self.name_from(start_bpos))
        } else {
            if self.ch_is('e') || self.ch_is('E') {
                self.scan_float_exponent();
                let pos = self.pos;
                self.check_float_base(start_bpos, pos, base);
                return token::Float(self.name_from(start_bpos));
            }
            token::Integer(self.name_from(start_bpos))
        }
    }
    
    fn scan_hex_digits(&mut self, n_digits: usize, delim: char, below_0x7f_only: bool) -> bool {
        debug!("scanning {} digits until {:?}", n_digits, delim);
        let start_bpos = self.pos;
        let mut accum_int = 0;

        let mut valid = true;
        for _ in 0..n_digits {
            if self.is_eof() {
                let last_bpos = self.pos;
                self.fatal_span_(start_bpos,
                                 last_bpos,
                                 "unterminated numeric character escape").raise();
            }
            if self.ch_is(delim) {
                let last_bpos = self.pos;
                self.err_span_(start_bpos,
                               last_bpos,
                               "numeric character escape is too short");
                valid = false;
                break;
            }
            let c = self.ch.unwrap_or('\x00');
            accum_int *= 16;
            accum_int += c.to_digit(16).unwrap_or_else(|| {
                self.err_span_char(self.pos,
                                   self.next_pos,
                                   "invalid character in numeric character escape",
                                   c);

                valid = false;
                0
            });
            self.bump();
        }

        if below_0x7f_only && accum_int >= 0x80 {
            self.err_span_(start_bpos,
                           self.pos,
                           "this form of character escape may only be used with characters in \
                            the range [\\x00-\\x7f]");
            valid = false;
        }

        match char::from_u32(accum_int) {
            Some(_) => valid,
            None => {
                let last_bpos = self.pos;
                self.err_span_(start_bpos, last_bpos, "invalid numeric character escape");
                false
            }
        }
    }
    
    fn scan_char_or_byte(&mut self,
                         start: BytePos,
                         first_source_char: char,
                         ascii_only: bool,
                         delim: char)
                         -> bool
    {
        match first_source_char {
            '\\' => {
                // '\X' for some X must be a character constant:
                let escaped = self.ch;
                let escaped_pos = self.pos;
                self.bump();
                match escaped {
                    None => {}  // EOF here is an error that will be checked later.
                    Some(e) => {
                        return match e {
                            'n' | 'r' | 't' | '\\' | '\'' | '"' | '0' => true,
                            'x' => self.scan_byte_escape(delim, !ascii_only),
                            'u' => {
                                let valid = if self.ch_is('{') {
                                    self.scan_unicode_escape(delim) && !ascii_only
                                } else {
                                    let span = self.mk_sp(start, self.pos);
                                    let mut suggestion = "\\u{".to_owned();
                                    let mut err = self.sess.span_diagnostic.struct_span_err(
                                        span,
                                        "incorrect unicode escape sequence",
                                    );
                                    let mut i = 0;
                                    while let (Some(ch), true) = (self.ch, i < 6) {
                                        if ch.is_digit(16) {
                                            suggestion.push(ch);
                                            self.bump();
                                            i += 1;
                                        } else {
                                            break;
                                        }
                                    }
                                    if i != 0 {
                                        suggestion.push('}');
                                        err.span_suggestion_with_applicability(
                                            self.mk_sp(start, self.pos),
                                            "format of unicode escape sequences uses braces",
                                            suggestion,
                                            Applicability::MaybeIncorrect,
                                        );
                                    } else {
                                        err.span_help(
                                            span,
                                            "format of unicode escape sequences is `\\u{...}`",
                                        );
                                    }
                                    err.emit();
                                    false
                                };
                                if ascii_only {
                                    self.err_span_(start,
                                                   self.pos,
                                                   "unicode escape sequences cannot be used as a \
                                                    byte or in a byte string");
                                }
                                valid

                            }
                            '\n' if delim == '"' => {
                                self.consume_whitespace();
                                true
                            }
                            '\r' if delim == '"' && self.ch_is('\n') => {
                                self.consume_whitespace();
                                true
                            }
                            c => {
                                let pos = self.pos;
                                let mut err = self.struct_err_span_char(escaped_pos,
                                                                        pos,
                                                                        if ascii_only {
                                                                            "unknown byte escape"
                                                                        } else {
                                                                            "unknown character \
                                                                             escape"
                                                                        },
                                                                        c);
                                if e == '\r' {
                                    err.span_help(self.mk_sp(escaped_pos, pos),
                                                  "this is an isolated carriage return; consider \
                                                   checking your editor and version control \
                                                   settings");
                                }
                                if (e == '{' || e == '}') && !ascii_only {
                                    err.span_help(self.mk_sp(escaped_pos, pos),
                                                  "if used in a formatting string, curly braces \
                                                   are escaped with `{{` and `}}`");
                                }
                                err.emit();
                                false
                            }
                        }
                    }
                }
            }
            '\t' | '\n' | '\r' | '\'' if delim == '\'' => {
                let pos = self.pos;
                self.err_span_char(start,
                                   pos,
                                   if ascii_only {
                                       "byte constant must be escaped"
                                   } else {
                                       "character constant must be escaped"
                                   },
                                   first_source_char);
                return false;
            }
            '\r' => {
                if self.ch_is('\n') {
                    self.bump();
                    return true;
                } else {
                    self.err_span_(start,
                                   self.pos,
                                   "bare CR not allowed in string, use \\r instead");
                    return false;
                }
            }
            _ => {
                if ascii_only && first_source_char > '\x7F' {
                    let pos = self.pos;
                    self.err_span_(start,
                                   pos,
                                   "byte constant must be ASCII. Use a \\xHH escape for a \
                                    non-ASCII byte");
                    return false;
                }
            }
        }
        true
    }
    
    fn scan_unicode_escape(&mut self, delim: char) -> bool {
        self.bump(); // past the {
        let start_bpos = self.pos;
        let mut valid = true;

        if let Some('_') = self.ch {
            // disallow leading `_`
            self.err_span_(self.pos,
                           self.next_pos,
                           "invalid start of unicode escape");
            valid = false;
        }

        let count = self.scan_digits(16, 16);

        if count > 6 {
            self.err_span_(start_bpos,
                           self.pos,
                           "overlong unicode escape (must have at most 6 hex digits)");
            valid = false;
        }

        loop {
            match self.ch {
                Some('}') => {
                    if valid && count == 0 {
                        self.err_span_(start_bpos,
                                       self.pos,
                                       "empty unicode escape (must have at least 1 hex digit)");
                        valid = false;
                    }
                    self.bump(); // past the ending `}`
                    break;
                },
                Some(c) => {
                    if c == delim {
                        self.err_span_(self.pos,
                                       self.pos,
                                       "unterminated unicode escape (needed a `}`)");
                        valid = false;
                        break;
                    } else if valid {
                        self.err_span_char(start_bpos,
                                           self.pos,
                                           "invalid character in unicode escape",
                                           c);
                        valid = false;
                    }
                },
                None => {
                    self.fatal_span_(start_bpos,
                                     self.pos,
                                     "unterminated unicode escape (found EOF)").raise();
                }
            }
            self.bump();
        }

        valid
    }
    
    fn scan_float_exponent(&mut self) {
        if self.ch_is('e') || self.ch_is('E') {
            self.bump();

            if self.ch_is('-') || self.ch_is('+') {
                self.bump();
            }

            if self.scan_digits(10, 10) == 0 {
                let mut err = self.struct_span_fatal(
                    self.pos, self.next_pos,
                    "expected at least one digit in exponent"
                );
                if let Some(ch) = self.ch {
                    // check for e.g., Unicode minus '−' (Issue #49746)
                    if unicode_chars::check_for_substitution(self, ch, &mut err) {
                        self.bump();
                        self.scan_digits(10, 10);
                    }
                }
                err.emit();
            }
        }
    }
}
```

* `scan_digits`消耗数字(任意基底)和下划线。
* `scan_number`消耗整数字面量`[0-9][0-9_]*|0b|0o|0x`，浮点数字面量`N.N/N[eE]N`。
* `scan_hex_digits`消耗16进制数`[0-9A-Za-z]{n_digits}`用于转义字符。
* `scan_unicode_escape`消耗类似`\u{N_NNN_N}`的Unicode转义(`_`不能在开头，1-6位十六进制数字)。
* `scan_float_exponent`消耗`[eE][+-]?[0-9]+`形式的科学计数法指数，仅用于对浮点数，带基底必定为浮点数([FLOAT_LITERAL](https://doc.rust-lang.org/reference/tokens.html#floating-point-literals))
* `scan_byte`等于必须满足`ascii_only`和下一个字符为`'`的`scan_char_or_byte` (可参考`next_token_inner`的`'`处理)
* 同理 `scan_byte_string`和`scan_raw_byte_string`相当于`next_token_inner`中`“”`和`r#`的ASCII版本。



`scan_char_or_byte`消耗一个字节或字符，

* 开头为`\`，处理转义的字符，`\x[00-ff]+`，`\u{N{1, 6}}` (包含`_`)，字符串续行(`\\\n`)，同时对`\uNNNNNN`和`\{\}`提供建议替换为`\u{NNNNNN}`和`{{ }}`
* 开头为`\t|\n|\r|\'`，且处于`\'`中，报错，这些字符必须要转义
* `\r` 如果不接`\n`也应报错
* 如果只允许ASCII字符，则>`\x7F`报错



##### comments.rs

利用`StringReader`解析注释，仅用于`libsyntax::print::pprust`

```rust
#[derive(Clone, Copy, PartialEq, Debug)]
pub enum CommentStyle {
    /// 单起一行注释
    Isolated,
    /// 同行代码右边的注释
    Trailing,
    /// 在代码中间的注释
    Mixed,
    /// 两个空行
    BlankLine,
}

#[derive(Clone)]
pub struct Comment {
    pub style: CommentStyle,
    pub lines: Vec<String>,
    pub pos: BytePos,
}

pub fn gather_comments_and_literals(sess: &ParseSess, path: FileName, srdr: &mut dyn Read)
    -> (Vec<Comment>, Vec<Literal>)
{
    let mut src = String::new();
    srdr.read_to_string(&mut src).unwrap();
    let cm = SourceMap::new(sess.source_map().path_mapping().clone());
    let source_file = cm.new_source_file(path, src);
    let mut rdr = lexer::StringReader::new_raw(sess, source_file, None);

    let mut comments: Vec<Comment> = Vec::new();
    let mut literals: Vec<Literal> = Vec::new();
    let mut code_to_the_left = false; // Only code
    let mut anything_to_the_left = false; // Code or comments

    while !rdr.is_eof() {
        loop {
            // Eat all the whitespace and count blank lines.
            rdr.consume_non_eol_whitespace();
            if rdr.ch_is('\n') {
                if anything_to_the_left {
                    rdr.bump(); // The line is not blank, do not count.
                }
                consume_whitespace_counting_blank_lines(&mut rdr, &mut comments);
                code_to_the_left = false;
                anything_to_the_left = false;
            }
            // Eat one comment group
            if rdr.peeking_at_comment() {
                consume_comment(&mut rdr, &mut comments,
                                &mut code_to_the_left, &mut anything_to_the_left);
            } else {
                break
            }
        }

        let bstart = rdr.pos;
        rdr.next_token();
        // discard, and look ahead; we're working with internal state
        let TokenAndSpan { tok, sp } = rdr.peek();
        if tok.is_lit() {
            rdr.with_str_from(bstart, |s| {
                debug!("tok lit: {}", s);
                literals.push(Literal {
                    lit: s.to_string(),
                    pos: sp.lo(),
                });
            })
        } else {
            debug!("tok: {}", pprust::token_to_string(&tok));
        }
        code_to_the_left = true;
        anything_to_the_left = true;
    }

    (comments, literals)
}
```

`gather_comments_and_literals`读取源文件中的注释和标识符，仅在`pprust`中使用。



##### unicode_chars.rs

包含了[易混淆的Unicode字符](http://www.unicode.org/Public/security/10.0.0/confusables.txt)和ASCII字符的英文意义，用于检查误输入的提示。

```rust
crate fn check_for_substitution<'a>(reader: &StringReader<'a>,
                                  ch: char,
                                  err: &mut DiagnosticBuilder<'a>) -> bool {
    UNICODE_ARRAY
    .iter()
    .find(|&&(c, _, _)| c == ch)
    .map(|&(_, u_name, ascii_char)| {
        let span = Span::new(reader.pos, reader.next_pos, NO_EXPANSION);
        match ASCII_ARRAY.iter().find(|&&(c, _)| c == ascii_char) {
            Some(&(ascii_char, ascii_name)) => {
                let msg =
                    format!("Unicode character '{}' ({}) looks like '{}' ({}), but it is not",
                            ch, u_name, ascii_char, ascii_name);
                err.span_suggestion_with_applicability(
                    span,
                    &msg,
                    ascii_char.to_string(),
                    Applicability::MaybeIncorrect);
                true
            },
            None => {
                let msg = format!("substitution character not found for '{}'", ch);
                reader.sess.span_diagnostic.span_bug_no_panic(span, &msg);
                false
            }
        }
    }).unwrap_or(false)
}
```



##### tokentrees.rs

给`StringReader`实现解析成`TokenStream`的函数，用于`proc_macro`。用到了`StringReader::open_braces`和`StringReader::matching_delim_spans`。

```rust
fn parse_token_tree(&mut self) -> PResult<'a, TokenStream> {
        let sm = self.sess.source_map();
        match self.token {
            token::Eof => {
                let msg = "this file contains an un-closed delimiter";
                let mut err = self.sess.span_diagnostic.struct_span_err(self.span, msg);
                for &(_, sp) in &self.open_braces {
                    err.span_label(sp, "un-closed delimiter");
                }

                if let Some((delim, _)) = self.open_braces.last() {
                    if let Some((_, open_sp, close_sp)) = self.matching_delim_spans.iter()
                        .filter(|(d, open_sp, close_sp)| {

                        if let Some(close_padding) = sm.span_to_margin(*close_sp) {
                            if let Some(open_padding) = sm.span_to_margin(*open_sp) {
                                return delim == d && close_padding != open_padding;
                            }
                        }
                        false
                        }).next()  
                    {              
                        err.span_label(
                            *open_sp,
                            "this delimiter might not be properly closed...",
                        );
                        err.span_label(
                            *close_sp,
                            "...as it matches this but it has different indentation",
                        );
                    }
                }
                Err(err)
            },
            token::OpenDelim(delim) => {
                let pre_span = self.span;

                self.open_braces.push((delim, self.span));
                self.real_token();

                let tts = self.parse_token_trees_until_close_delim();

                let delim_span = DelimSpan::from_pair(pre_span, self.span);

                match self.token {
                    token::CloseDelim(d) if d == delim => {
                        let (open_brace, open_brace_span) = self.open_braces.pop().unwrap();
                        if self.open_braces.len() == 0 {
                            self.matching_delim_spans.clear();
                        } else {
                            self.matching_delim_spans.push(
                                (open_brace, open_brace_span, self.span),
                            );
                        }
                        self.real_token();
                    }
                    token::CloseDelim(other) => {
                        let token_str = token_to_string(&self.token);
                        if self.last_unclosed_found_span != Some(self.span) {
							// 同种括号只连续报错一次
                            self.last_unclosed_found_span = Some(self.span);
                            let msg = format!("incorrect close delimiter: `{}`", token_str);
                            let mut err = self.sess.span_diagnostic.struct_span_err(
                                self.span,
                                &msg,
                            );
                            err.span_label(self.span, "incorrect close delimiter");
                            
                            if let Some(&(_, sp)) = self.open_braces.last() {
                                err.span_label(sp, "un-closed delimiter");
                            };
                            if let Some(current_padding) = sm.span_to_margin(self.span) {
                                for (brace, brace_span) in &self.open_braces {
                                    if let Some(padding) = sm.span_to_margin(*brace_span) {
                                        // high likelihood of these two corresponding
                                        if current_padding == padding && brace == &other {
                                            err.span_label(
                                                *brace_span,
                                                "close delimiter possibly meant for this",
                                            );
                                        }
                                    }
                                }
                            }
                            err.emit();
                        }
                        self.open_braces.pop().unwrap();

						// 如果和之前的开括号匹配，试图恢复，`{(}`不消耗`}`在下次parse_token_tree中匹配
                        // E.g., we try to recover from:
                        // fn foo() {
                        //     bar(baz(
                        // }  // Incorrect delimiter but matches the earlier `{`
                        if !self.open_braces.iter().any(|&(b, _)| b == other) {
                            self.real_token();
                        }
                    }
                    token::Eof => {
                    },
                    _ => {}
                }

                Ok(TokenTree::Delimited(
                    delim_span,
                    delim,
                    tts.into(),
                ).into())
            },
            token::CloseDelim(_) => {
                let token_str = token_to_string(&self.token);
                let msg = format!("unexpected close delimiter: `{}`", token_str);
                let mut err = self.sess.span_diagnostic.struct_span_err(self.span, &msg);
                err.span_label(self.span, "unexpected close delimiter");
                Err(err)
            },
            _ => {
                let tt = TokenTree::Token(self.span, self.token.clone());
                let raw = self.span_src_raw;
                self.real_token();
                // 用span_src_raw来判断，而不是override_span
                let is_joint = raw.hi() == self.span_src_raw.lo() && token::is_op(&self.token);
                Ok(TokenStream::Tree(tt, if is_joint { Joint } else { NonJoint }))
            }
        }
    }
```

#![TODO] 这里的Joint的意义？



#### mod.rs

```rust
pub type PResult<'a, T> = Result<T, DiagnosticBuilder<'a>>;

/// Parsing session的信息
pub struct ParseSess {
    pub span_diagnostic: Handler,
    pub unstable_features: UnstableFeatures,
    pub config: CrateConfig,
    pub missing_fragment_specifiers: Lock<FxHashSet<Span>>,
    /// 放置裸标识符，见[parse::lexer::mod.rs]
    pub raw_identifier_spans: Lock<Vec<Span>>,
    /// 注册的诊断代码(如E\d{4})
    crate registered_diagnostics: Lock<ErrorMap>,
    /// 用来检测和报告嵌套mod
    included_mod_stack: Lock<Vec<PathBuf>>,
    source_map: Lrc<SourceMap>,
    pub buffered_lints: Lock<Vec<BufferedEarlyLint>>,
}

#[derive(Clone)]
pub struct Directory<'a> {
    pub path: Cow<'a, Path>,
    pub ownership: DirectoryOwnership,
}

#[derive(Copy, Clone)]
pub enum DirectoryOwnership {
    Owned {
        // None if `mod.rs`, `Some("foo")` if we're in `foo.rs`
        relative: Option<ast::Ident>,
    },
    UnownedViaBlock,
    UnownedViaMod(bool /* legacy warnings? */),
}
```

`PRResult<'a, T>`作为Parser的Result类型。`ParseSess`收集一次`Parsing session`中的信息。



`parse_<thing>_from_<source>` 从 `source`中解析`thing`

* `thing`: crate/表达式(expr)/item/语句(statement)/tokenstream/attribute
* `source`: 文件(file)/源代码(source_str)



```rust
// 返回转义字符的非转义版本和消耗的字符数
fn char_lit(lit: &str, diag: Option<(Span, &Handler)>) -> (char, isize) {
    use std::char;

    // Handle non-escaped chars first.
    if lit.as_bytes()[0] != b'\\' {
        // If the first byte isn't '\\' it might part of a multi-byte char, so
        // get the char with chars().
        let c = lit.chars().next().unwrap();
        return (c, 1);
    }

    // Handle escaped chars.
    match lit.as_bytes()[1] as char {
        '"' => ('"', 2),
        'n' => ('\n', 2),
        'r' => ('\r', 2),
        't' => ('\t', 2),
        '\\' => ('\\', 2),
        '\'' => ('\'', 2),
        '0' => ('\0', 2),
        'x' => {
            let v = u32::from_str_radix(&lit[2..4], 16).unwrap();
            let c = char::from_u32(v).unwrap();
            (c, 4)
        }
        'u' => {
            assert_eq!(lit.as_bytes()[2], b'{');
            let idx = lit.find('}').unwrap();

            // All digits and '_' are ascii, so treat each byte as a char.
            let mut v: u32 = 0;
            for c in lit[3..idx].bytes() {
                let c = char::from(c);
                if c != '_' {
                    let x = c.to_digit(16).unwrap();
                    v = v.checked_mul(16).unwrap().checked_add(x).unwrap();
                }
            }
            let c = char::from_u32(v).unwrap_or_else(|| {
                if let Some((span, diag)) = diag {
                    let mut diag = diag.struct_span_err(span, "invalid unicode character escape");
                    if v > 0x10FFFF {
                        diag.help("unicode escape must be at most 10FFFF").emit();
                    } else {
                        diag.help("unicode escape must not be a surrogate").emit();
                    }
                }
                '\u{FFFD}'
            });
            (c, (idx + 1) as isize)
        }
        _ => panic!("lexer should have rejected a bad character escape {}", lit)
    }
}

fn byte_lit(lit: &str) -> (u8, usize) {
    let err = |i| format!("lexer accepted invalid byte literal {} step {}", lit, i);

    if lit.len() == 1 {
        (lit.as_bytes()[0], 1)
    } else {
        assert_eq!(lit.as_bytes()[0], b'\\', "{}", err(0));
        let b = match lit.as_bytes()[1] {
            b'"' => b'"',
            b'n' => b'\n',
            b'r' => b'\r',
            b't' => b'\t',
            b'\\' => b'\\',
            b'\'' => b'\'',
            b'0' => b'\0',
            _ => {
                match u64::from_str_radix(&lit[2..4], 16).ok() {
                    Some(c) =>
                        if c > 0xFF {
                            panic!(err(2))
                        } else {
                            return (c as u8, 4)
                        },
                    None => panic!(err(3))
                }
            }
        };
        (b, 2)
    }
}

// 返回非转义的字符串，省略字符串续行后的空白符
pub fn str_lit(lit: &str, diag: Option<(Span, &Handler)>) -> String {
    debug!("str_lit: given {}", lit.escape_default());
    let mut res = String::with_capacity(lit.len());

    let error = |i| format!("lexer should have rejected {} at {}", lit, i);

    /// 消耗直到出现非空白符
    fn eat<'a>(it: &mut iter::Peekable<str::CharIndices<'a>>) {
        loop {
            match it.peek().map(|x| x.1) {
                Some(' ') | Some('\n') | Some('\r') | Some('\t') => {
                    it.next();
                },
                _ => { break; }
            }
        }
    }

    let mut chars = lit.char_indices().peekable();
    while let Some((i, c)) = chars.next() {
        match c {
            '\\' => {
                let ch = chars.peek().unwrap_or_else(|| {
                    panic!("{}", error(i))
                }).1;

                if ch == '\n' {
                    eat(&mut chars);
                } else if ch == '\r' {
                    chars.next();
                    let ch = chars.peek().unwrap_or_else(|| {
                        panic!("{}", error(i))
                    }).1;

                    if ch != '\n' {
                        panic!("lexer accepted bare CR");
                    }
                    eat(&mut chars);
                } else {
                    // otherwise, a normal escape
                    let (c, n) = char_lit(&lit[i..], diag);
                    for _ in 0..n - 1 { // we don't need to move past the first \
                        chars.next();
                    }
                    res.push(c);
                }
            },
            '\r' => {
                let ch = chars.peek().unwrap_or_else(|| {
                    panic!("{}", error(i))
                }).1;

                if ch != '\n' {
                    panic!("lexer accepted bare CR");
                }
                chars.next();
                res.push('\n');
            }
            c => res.push(c),
        }
    }

    res.shrink_to_fit(); // probably not going to do anything, unless there was an escape.
    debug!("parse_str_lit: returning {}", res);
    res
}

fn byte_str_lit(lit: &str) -> Lrc<Vec<u8>> {
    let mut res = Vec::with_capacity(lit.len());

    let error = |i| panic!("lexer should have rejected {} at {}", lit, i);

    fn eat<I: Iterator<Item=(usize, u8)>>(it: &mut iter::Peekable<I>) {
        loop {
            match it.peek().map(|x| x.1) {
                Some(b' ') | Some(b'\n') | Some(b'\r') | Some(b'\t') => {
                    it.next();
                },
                _ => { break; }
            }
        }
    }

    let mut chars = lit.bytes().enumerate().peekable();
    loop {
        match chars.next() {
            Some((i, b'\\')) => {
                match chars.peek().unwrap_or_else(|| error(i)).1 {
                    b'\n' => eat(&mut chars),
                    b'\r' => {
                        chars.next();
                        if chars.peek().unwrap_or_else(|| error(i)).1 != b'\n' {
                            panic!("lexer accepted bare CR");
                        }
                        eat(&mut chars);
                    }
                    _ => {
                        let (c, n) = byte_lit(&lit[i..]);
                        for _ in 0..n - 1 {
                            chars.next();
                        }
                        res.push(c);
                    }
                }
            },
            Some((i, b'\r')) => {
                if chars.peek().unwrap_or_else(|| error(i)).1 != b'\n' {
                    panic!("lexer accepted bare CR");
                }
                chars.next();
                res.push(b'\n');
            }
            Some((_, c)) => res.push(c),
            None => break,
        }
    }

    Lrc::new(res)
}

// 裸字符串的非转义版本只会将CRLF变为LF
fn raw_str_lit(lit: &str) -> String {
    debug!("raw_str_lit: given {}", lit.escape_default());
    let mut res = String::with_capacity(lit.len());

    let mut chars = lit.chars().peekable();
    while let Some(c) = chars.next() {
        if c == '\r' {
            if *chars.peek().unwrap() != '\n' {
                panic!("lexer accepted bare CR");
            }
            chars.next();
            res.push('\n');
        } else {
            res.push(c);
        }
    }

    res.shrink_to_fit();
    res
}

fn filtered_float_lit(data: Symbol, suffix: Option<Symbol>, diag: Option<(Span, &Handler)>)
                      -> Option<ast::LitKind> {
    debug!("filtered_float_lit: {}, {:?}", data, suffix);
    let suffix = match suffix {
        Some(suffix) => suffix,
        None => return Some(ast::LitKind::FloatUnsuffixed(data)),
    };

    Some(match &*suffix.as_str() {
        "f32" => ast::LitKind::Float(data, ast::FloatTy::F32),
        "f64" => ast::LitKind::Float(data, ast::FloatTy::F64),
        suf => {
            err!(diag, |span, diag| {
                if suf.len() >= 2 && looks_like_width_suffix(&['f'], suf) {
                    // if it looks like a width, lets try to be helpful.
                    let msg = format!("invalid width `{}` for float literal", &suf[1..]);
                    diag.struct_span_err(span, &msg).help("valid widths are 32 and 64").emit()
                } else {
                    let msg = format!("invalid suffix `{}` for float literal", suf);
                    diag.struct_span_err(span, &msg)
                        .help("valid suffixes are `f32` and `f64`")
                        .emit();
                }
            });

            ast::LitKind::FloatUnsuffixed(data)
        }
    })
}
fn float_lit(s: &str, suffix: Option<Symbol>, diag: Option<(Span, &Handler)>)
                 -> Option<ast::LitKind> {
    debug!("float_lit: {:?}, {:?}", s, suffix);
    // 仅在必要时去除下划线
    let s2;
    let s = if s.chars().any(|c| c == '_') {
        s2 = s.chars().filter(|&c| c != '_').collect::<String>();
        &s2
    } else {
        s
    };

    filtered_float_lit(Symbol::intern(s), suffix, diag)
}

fn integer_lit(s: &str, suffix: Option<Symbol>, diag: Option<(Span, &Handler)>)
                   -> Option<ast::LitKind> {
    // 仅当含有_时重新创建字符串
    let s2;
    let mut s = if s.chars().any(|c| c == '_') {
        s2 = s.chars().filter(|&c| c != '_').collect::<String>();
        &s2
    } else {
        s
    };

    debug!("integer_lit: {}, {:?}", s, suffix);

    let mut base = 10;
    let orig = s;
    let mut ty = ast::LitIntType::Unsuffixed;

    if s.starts_with('0') && s.len() > 1 {
        match s.as_bytes()[1] {
            b'x' => base = 16,
            b'o' => base = 8,
            b'b' => base = 2,
            _ => { }
        }
    }

    // 1f64， 2f32被处理为float 
    if let Some(suf) = suffix {
        if looks_like_width_suffix(&['f'], &suf.as_str()) {
            let err = match base {
                16 => Some("hexadecimal float literal is not supported"),
                8 => Some("octal float literal is not supported"),
                2 => Some("binary float literal is not supported"),
                _ => None,
            };
            if let Some(err) = err {
                err!(diag, |span, diag| diag.span_err(span, err));
            }
            return filtered_float_lit(Symbol::intern(s), Some(suf), diag)
        }
    }

    if base != 10 {
        s = &s[2..];
    }

    if let Some(suf) = suffix {
        if suf.as_str().is_empty() {
            err!(diag, |span, diag| diag.span_bug(span, "found empty literal suffix in Some"));
        }
        ty = match &*suf.as_str() {
            "isize" => ast::LitIntType::Signed(ast::IntTy::Isize),
            "i8"  => ast::LitIntType::Signed(ast::IntTy::I8),
            "i16" => ast::LitIntType::Signed(ast::IntTy::I16),
            "i32" => ast::LitIntType::Signed(ast::IntTy::I32),
            "i64" => ast::LitIntType::Signed(ast::IntTy::I64),
            "i128" => ast::LitIntType::Signed(ast::IntTy::I128),
            "usize" => ast::LitIntType::Unsigned(ast::UintTy::Usize),
            "u8"  => ast::LitIntType::Unsigned(ast::UintTy::U8),
            "u16" => ast::LitIntType::Unsigned(ast::UintTy::U16),
            "u32" => ast::LitIntType::Unsigned(ast::UintTy::U32),
            "u64" => ast::LitIntType::Unsigned(ast::UintTy::U64),
            "u128" => ast::LitIntType::Unsigned(ast::UintTy::U128),
            suf => {
                // i<digits> and u<digits> look like widths, so lets
                // give an error message along those lines
                err!(diag, |span, diag| {
                    if looks_like_width_suffix(&['i', 'u'], suf) {
                        let msg = format!("invalid width `{}` for integer literal", &suf[1..]);
                        diag.struct_span_err(span, &msg)
                            .help("valid widths are 8, 16, 32, 64 and 128")
                            .emit();
                    } else {
                        let msg = format!("invalid suffix `{}` for numeric literal", suf);
                        diag.struct_span_err(span, &msg)
                            .help("the suffix must be one of the integral types \
                                   (`u32`, `isize`, etc)")
                            .emit();
                    }
                });

                ty
            }
        }
    }

    debug!("integer_lit: the type is {:?}, base {:?}, the new string is {:?}, the original \
           string was {:?}, the original suffix was {:?}", ty, base, s, orig, suffix);

    Some(match u128::from_str_radix(s, base) {
        Ok(r) => ast::LitKind::Int(r, ty),
        Err(_) => {
			// <10的基底在lexer中用10做基底解析(scan_digits)并报错,
            // 所以对小于10基底的无法表示错误，如`0b10201`不再报错.
            let already_errored = base < 10 &&
                s.chars().any(|c| c.to_digit(10).map_or(false, |d| d >= base));

            if !already_errored {
                err!(diag, |span, diag| diag.span_err(span, "int literal is too large"));
            }
            ast::LitKind::Int(0, ty)
        }
    })
}
```

因为`StringReader`生成`Token`的时候仅将字符串(`with_str_from`）放入`token::Literal`，需要对字面量进行进一步处理，从`String`处理成`ast::LitKind`。

* `char_lit`: 还原转义字符
* `byte_lit`: 类似`char_lit`，只能是ASCII
* `str_lit`: 还原转义字符串和CRLF -> LF
* `byte_str_lit`： 类似`str_lit`
* `raw_str_lit`： 不做处理，除了CRLF -> LF
* `float_lit` (去除下划线) -> `filtered_float_lit`: 根据后缀分类成不同的`ast::LitKind::Float`
* `integer_lit`: 去除下划线，检查是否溢出`u128`，后缀，基底
  * 提到了一个#FIXME [#2252](https://github.com/rust-lang/rust/issues/2252): 在parser阶段检查浮点数溢出(实际上还有带后缀的整型超过`u128`范围的检查)，移到下一个阶段(ast)进行 (#![CHECK])



```rust
crate fn lit_token(lit: token::Lit, suf: Option<Symbol>, diag: Option<(Span, &Handler)>)
                 -> (bool /* 后缀合法? */, Option<ast::LitKind>) {
    use ast::LitKind;

    match lit {
       token::Byte(i) => (true, Some(LitKind::Byte(byte_lit(&i.as_str()).0))),
       token::Char(i) => (true, Some(LitKind::Char(char_lit(&i.as_str(), diag).0))),

        // 实际上Integer Float后缀合法，在_lit里处理
        token::Integer(s) => (false, integer_lit(&s.as_str(), suf, diag)),
        token::Float(s) => (false, float_lit(&s.as_str(), suf, diag)),

        token::Str_(mut sym) => {
            // 对无需重新生成的不带转义字符的字符串，直接复用
            let s = &sym.as_str();
            if s.as_bytes().iter().any(|&c| c == b'\\' || c == b'\r') {
                sym = Symbol::intern(&str_lit(s, diag));
            }
            (true, Some(LitKind::Str(sym, ast::StrStyle::Cooked)))
        }
        token::StrRaw(mut sym, n) => {
            let s = &sym.as_str();
            if s.contains('\r') {
                sym = Symbol::intern(&raw_str_lit(s));
            }
            (true, Some(LitKind::Str(sym, ast::StrStyle::Raw(n))))
        }
        token::ByteStr(i) => {
            (true, Some(LitKind::ByteStr(byte_str_lit(&i.as_str()))))
        }
        token::ByteStrRaw(i, _) => {
            (true, Some(LitKind::ByteStr(Lrc::new(i.to_string().into_bytes()))))
        }
    }
}
```

`lit_token`将`token::Lit`变为`ast::LitKind`



```rust
pub struct SeqSep {
    pub sep: Option<token::Token>,
    pub trailing_sep_allowed: bool,
}
```

序列的分隔符，并标注是否允许结尾(trailing)为这个分隔符

* 仅用于`，`



#### classify.rs

```rust
pub fn expr_requires_semi_to_be_stmt(e: &ast::Expr) -> bool {
    match e.node {
        ast::ExprKind::If(..) |
        ast::ExprKind::IfLet(..) |
        ast::ExprKind::Match(..) |
        ast::ExprKind::Block(..) |
        ast::ExprKind::While(..) |
        ast::ExprKind::WhileLet(..) |
        ast::ExprKind::Loop(..) |
        ast::ExprKind::ForLoop(..) |
        ast::ExprKind::TryBlock(..) => false,
        _ => true,
    }
}

pub fn stmt_ends_with_semi(stmt: &ast::StmtKind) -> bool {
    match *stmt {
        ast::StmtKind::Local(_) => true,
        ast::StmtKind::Expr(ref e) => expr_requires_semi_to_be_stmt(e),
        ast::StmtKind::Item(_) |
        ast::StmtKind::Semi(..) |
        ast::StmtKind::Mac(..) => false,
    }
}
```

区别是否需要由`;`结尾的语句和表达式。



#### parser.rs

语法(syntax)分析部分。



```rust
#[derive(Debug)]
/// 类型别名(type alias)或关联类型(associated type)是实体类型还是存在(Existential)类型
pub enum AliasKind {
    Weak(P<Ty>),
    Existential(GenericBounds),
}
```

这里的存在类型的语法类似

```rust
existential type Type: Debug;

trait Iterator {
    type Item;
    // ..
}

impl<I: Clone + Iterator<Item: Clone>> Clone for Peekable<I> {
    // ..
}
```

* [RFC-2071](https://github.com/rust-lang/rfcs/pull/2071)
* [RFC-2089](https://github.com/rust-lang/rfcs/pull/2289)



```rust
// 用到了[bitflags](https://docs.rs/bitflags/1.0.4/bitflags/)这个库，生成bitmask
bitflags! {
    struct Restrictions: u8 {
        const STMT_EXPR         = 1 << 0;
        const NO_STRUCT_LITERAL = 1 << 1;
    }
}

type ItemInfo = (Ident, ItemKind, Option<Vec<Attribute>>);

/// 如何解析路径(path)
#[derive(Copy, Clone, PartialEq)]
pub enum PathStyle {
    /// 在一些上下文中，特别是表达式，泛型参数是有歧义的。`segment < ...`
    /// 可能被解释为比较，`segment (`可能被解释为调用，在这些上下文中
    /// 优先非路径解析。
    /// 例子: `x<y>` - 比较, `x::<y>` - 无歧义的路径。
    Expr,
    /// 其他上下文中，特别是类型，路径解析是没有歧义的。
    /// 例子: `x<y>` - 无歧义的路径，带有消歧义的路径仍被接受.
    /// `x::<Y>` - 无歧义的路径。
    Type,
    /// 不允许泛型参数的路径的上下文，在导入(imports)，
   	/// 可见性(visibility)，属性(attributes)中使用
    /// 可以用Expr替代，但是需要进一步检查不存在泛型参数，且避免奇异的提示
    Mod,
}

#[derive(Clone, Copy, PartialEq, Debug)]
enum SemiColonMode {
    Break,
    Ignore,
}

#[derive(Clone, Copy, PartialEq, Debug)]
enum BlockMode {
    Break,
    Ignore,
}

#[derive(Debug, Clone, Copy, PartialEq)]
enum PrevTokenKind {
    DocComment,
    Comma,
    Plus,
    Interpolated,
    Eof,
    Ident,
    Other,
}

// QPath: 用在rustc::hir，表示Optionally `Self`-qualified value/type path or associated extension
trait RecoverQPath: Sized {
    const PATH_STYLE: PathStyle = PathStyle::Expr;
    fn to_ty(&self) -> Option<P<Ty>>;
    fn to_recovered(&self, qself: Option<QSelf>, path: ast::Path) -> Self;
    fn to_string(&self) -> String;
}

// [rustc::hir::QPath](https://manishearth.github.io/rust-internals-docs/rustc/hir/enum.QPath.html)
pub enum QPath {
    // 定义的路径，例: `Clone::clone`，`<Vec<T> as Clone>::clone`
    Resolved(Option<P<Ty>>, P<Path>),
    // 类型相关的路径，例: `<T>::Item`
    TypeRelative(P<Ty>, P<PathSegment>),
}

#[derive(Clone)]
pub struct Parser<'a> {
    pub sess: &'a ParseSess,
    /// 当前Token
    pub token: token::Token,
    /// 当前Token的范围
    pub span: Span,
    /// 之前Token的范围:
    meta_var_span: Option<Span>,
    pub prev_span: Span,
    /// 之前Token的种类
    prev_token_kind: PrevTokenKind,
    restrictions: Restrictions,
    /// 用于解决导入外部文件的路径
    crate directory: Directory<'a>,
    /// 是否解析其他文件的子模块，[!42071]
    pub recurse_into_file_modules: bool,
    /// 根模块的名字，在解析子模块的时候不变，但子parser可能会改变
    pub root_module_name: Option<String>,
    crate expected_tokens: Vec<TokenType>,
    token_cursor: TokenCursor,
    desugar_doc_comments: bool,
    /// 是否解析被`#[cfg(not(Module))]`排除的模块
    pub cfg_mods: bool,
}

#[derive(Clone)]
struct TokenCursor {
    frame: TokenCursorFrame,
    stack: Vec<TokenCursorFrame>,
}

#[derive(Clone)]
struct TokenCursorFrame {
    delim: token::DelimToken,
    span: DelimSpan,
    open_delim: bool,
    tree_cursor: tokenstream::Cursor,
    close_delim: bool,
    last_token: LastToken,
}

/// 用于`TokenCursorFrame`中追踪消耗掉的`Token`
/// Collecting: 把所有消耗的存在`Vec`中
/// Was: 仅记录最后的`Token`。当开始记录`Token`时，这个`Token`会是第一个`Token`
#[derive(Clone)]
enum LastToken {
    Collecting(Vec<TokenStream>),
    Was(Option<TokenStream>),
}
```







### attr.rs [WIP]

处理attributes和元对象(meta items)。



```rust
#[derive(Debug)]
enum InnerAttributeParsePolicy<'a> {
    Permitted,
    NotPermitted { reason: &'a str },
}
```

控制parser是否允许一个`InnerAttribute`

* inner: 以`#!`开头，对包裹这个attribute的对象起效

* outer: 以`#`开头，对跟随这个attribute的对象起效

* ```rust
  #[allow(non_camel_case_types)]
  type int8_t = i8;
  
  fn some_unused_variables() {
    #![allow(unused_variables)]
    let x = ();
    let y = ();
    let z = ();
  }
  ```

* [Attributes](<https://doc.rust-lang.org/reference/attributes.html>)



```rust
impl<'a> Parser<'a> {
    /// 在对象之前出现的Attribute
    crate fn parse_outer_attributes(&mut self) -> PResult<'a, Vec<ast::Attribute>> {
        let mut attrs: Vec<ast::Attribute> = Vec::new();
        let mut just_parsed_doc_comment = false;
        loop {
            match self.token {
                token::Pound => {
                	// 不允许紧跟文档字符串的inner attr
                    let inner_error_reason = if just_parsed_doc_comment {
                        "an inner attribute is not permitted following an outer doc comment"
                    // 不允许紧跟outer attr的inner attr
                    } else if !attrs.is_empty() {
                        "an inner attribute is not permitted following an outer attribute"
                    } else {
                        DEFAULT_UNEXPECTED_INNER_ATTR_ERR_MSG
                    };
                    let inner_parse_policy =
                        InnerAttributeParsePolicy::NotPermitted { reason: inner_error_reason };
                    attrs.push(self.parse_attribute_with_inner_parse_policy(inner_parse_policy)?);
                    just_parsed_doc_comment = false;
                }
                token::DocComment(s) => {
                    let attr = attr::mk_sugared_doc_attr(attr::mk_attr_id(), s, self.span);
                    if attr.style != ast::AttrStyle::Outer {
                        let mut err = self.fatal("expected outer doc comment");
                        err.note("inner doc comments like this (starting with \
                                  `//!` or `/*!`) can only appear before items");
                        return Err(err);
                    }
                    attrs.push(attr);
                    self.bump();
                    just_parsed_doc_comment = true;
                }
                _ => break,
            }
        }
        Ok(attrs)
    }
}
```

* 不允许紧跟文档字符串的inner attr
* 不允许紧跟outer attr的inner attr
* 不允许写在对象外的inner doc string (`//!`, `//*`)
  * 这里的报错信息错了(?)
* 



