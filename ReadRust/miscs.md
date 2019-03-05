## grammar

并不是真正的rust parser, 仅为了证明rust LALR gammar可行性, 从这个repo [rust-grammar](https://github.com/bleibig/rust-grammar) 拷贝而来 (last commit in 2017). 新的canonical grammar group [WG-grammar](https://github.com/rust-lang-nursery/wg-grammar), [#30942](https://github.com/rust-lang/rust/issues/30942)



### lexer.l

parser的词法部分，包含各种keyword, symbol

* `ident [a-zA-Z\x80-\xff_][a-zA-Z0-9\x80-\xff_]*` identifier 可用非0-9开头的Extend ASCII (`\w`, `_`, `\x80-\xff`)。实际不支持Non-ASCII identifier [#28979](https://github.com/rust-lang/rust/issues/28979)

![funny-snake-case](D:\OneDrive\Pictures\Typora\D%5COneDrive%5CPictures%5CTypora%5C1547128715211.png)

* 第一行的话省略BOM (`\xef\xbb\xbf`)，否则报错
* 单独的`_`作为特殊的`UNDERSCORE` 来解析
* 保留的keyword [reserved-keyword](https://doc.rust-lang.org/book/appendix-01-keywords.html#keywords-reserved-for-future-use)
  * doc不全，保留的keyword还有 `alignof`, `offsetof`, `proc`
* shebang或是inner attribute都是以`#!`开头，故一起处理
  * pound `#` 后实际可能跟attribute, shebang, raw string
* 各种string literal的处理
  * `'` : char 或 lifetime
  * `"` : str
  * `b"`: byte str
  * `br"`: raw byte str without hash
  * `br#`: ...
  * [tokens](https://doc.rust-lang.org/beta/reference/tokens.html)
  * ![string-literals](D:\OneDrive\Pictures\Typora\D%5COneDrive%5CPictures%5CTypora%5C1547136868162.png)



### parser-lalr-main.c + parser-lalr.y + tokens.h

LALR语法+flex/bison解析rust



### raw-string-literal-ambiguity.md

解释了Rust不属于CFG(context-free grammar)的一个原因： raw string literals. raw string literal 的文法如下

```
R -> 'r' S
S -> '"' B '"'
S -> '#' S '#'
B -> . B
B -> ε
```

引理1： (CFG ∩ Regular language) ∈ CFG

引理2： [pumping lemma](https://en.wikipedia.org/wiki/Pumping_lemma_for_context-free_languages)/[泵引理](https://zh.wikipedia.org/wiki/%E6%B3%B5%E5%BC%95%E7%90%86)

raw string grammar ∩ (`r#+""#*"#+`) = `{r#^n""#^m"#^n | m < n}`, 而这个文法，用pumping lemma可得非CFG, 故原文法非CFG，具体细节见原文档