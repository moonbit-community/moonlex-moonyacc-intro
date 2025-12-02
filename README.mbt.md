# MoonLex & MoonYacc 介绍

MoonBit 官方提供了 [lex](https://en.wikipedia.org/wiki/Lex_\(software\)) / [yacc](https://en.wikipedia.org/wiki/Yacc) 工具，用于生成词法分析器和语法分析器。

*MoonLex 和 MoonYacc 自身的 Lexer 和 Parser 最初使用手写实现，在 MoonLex 和 MoonYacc 稳定后，它们的 Lexer 和 Parser 也使用 MoonLex 和 MoonYacc 生成，实现了自举（bootstrapping）。*

*与这篇文章配套的代码仓库位于 [moonlex-moonyacc-intro](https://github.com/moonbit-community/moonlex-moonyacc-intro)。*

## 安装

在你的项目中，通过以下命令安装：

```bash
moon add --bin moonbitlang/ulex
moon add --bin moonbitlang/yacc
```

## 配置

通常我们需要在 `moon.pkg.json` 中配置 `pre-build` 字段，以便在构建时自动生成代码。

### 示例 (`lexer/moon.pkg.json`)

Lexer 通常依赖 Parser 定义的 Token 类型，因此需要 import parser 包。同时需要依赖 `moonbitlang/ulex-runtime`。

```json
{
  "pre-build": [
    {
      "command": "$mod_dir/.mooncakes/moonbitlang/ulex/moonlex $input | moonfmt > $output",
      "input": "lexer.mbtx",
      "output": "lexer.mbt"
    }
  ],
  "import": [
    "moonlex_moonyacc_intro/parser",
    "moonbitlang/ulex-runtime/lexbuf"
  ]
}
```

### 示例 (`parser/moon.pkg.json`)

```json
{
  "pre-build": [
    {
      "command": "$mod_dir/.mooncakes/moonbitlang/yacc/moonyacc $input | moonfmt > $output",
      "input": "parser.mbty",
      "output": "parser.mbt"
    }
  ]
}
```

*注意：`moonlex` 和 `moonyacc` 的可执行文件位于 `$mod_dir/.mooncakes/moonbitlang/ulex/moonlex` 和 `$mod_dir/.mooncakes/moonbitlang/yacc/moonyacc`。*

## MoonLex (Lexer Generator)

MoonLex 是一个基于 [Tagged NFA/DFA](https://laurikari.net/ville/spire2000-tnfa.pdf) 的词法分析器生成器。它接受 `.mbtx` 文件作为输入，并生成 `.mbt` 代码。

MoonLex 使用 MoonBit 语言实现，它是开源的，代码仓库位于 [moonbitlang/moonlex](https://github.com/moonbitlang/moonlex)。

### 示例 (`lexer/lexer.mbtx`)

```moonlex
{
// 头部：引入依赖
using @parser {type Token}
using @lexbuf {type StringLexbuf}

priv suberror EndOfInput
pub suberror Unrecognized (Int, Char)
}

// 你可以定义正则表达式以便在规则中复用
regex digit = ['0'-'9'];

// 规则定义有点像函数定义，但使用 rule 关键字而不是 fn 关键字
// 每个规则会生成一个对应的同名函数
// 在规则的 Pattern 中 eof 是关键字，匹配输入结束
// 在规则的 Action 中 $startpos 和 $endpos 是魔术变量，分别表示当前匹配的起始和结束位置
rule lex_token(lexbuf : StringLexbuf) -> (Token, Int, Int) raise {
  parse {
    eof => { raise EndOfInput }
    [' ' '\t']+ => { lex_token(lexbuf) }
    digit+ as t => { (NUMBER(try! @strconv.parse_int(t)), $startpos, $endpos) }
    "+" => { (PLUS, $startpos, $endpos) }
    "-" => { (MINUS, $startpos, $endpos) }
    "*" => { (STAR, $startpos, $endpos) }
    "(" => { (LPAREN, $startpos, $endpos) }
    ")" => { (RPAREN, $startpos, $endpos) }
    _ as c => { raise Unrecognized(($startpos, c)) }
  }
}

{
// 尾部：辅助函数
pub fn tokenize(input : String) -> Array[(Token, Int, Int)] raise Unrecognized {
  let lexbuf = StringLexbuf::from_string(input)
  let tokens = []
  for {
    let token = try lex_token(lexbuf) catch {
      EndOfInput => break
      Unrecognized(_) as err => raise err
      _ => panic()
    }
    tokens.push(token)
  }
  tokens
}
}
```

*实际上，`moonbitlang/ulex-runtime` 并不是必须的依赖，你也可以自行实现词法缓冲区（Lexbuf），只要它包含必要的接口即可。这里引入它是为了简化示例代码。*

*现在 MoonBit 语言已经内置了实验性 `lexmatch` 表达式功能，我们更推荐你使用 `lexmatch` 语法来实现 Lexer。*

### 词法定义文件语法

MoonLex 的词法定义文件结构如下：

1.  **头部代码**：位于文件开头，用 `{` 和 `}` 包裹。这部分代码会被直接复制到生成的 `.mbt` 文件头部。
2.  **正则定义**：使用 `regex` 关键字定义命名的正则表达式。
3.  **规则定义**：使用 `rule` 关键字定义词法分析规则。
4.  **尾部代码**：位于文件末尾，用 `{` 和 `}` 包裹。这部分代码会被直接复制到生成的 `.mbt` 文件尾部。

#### 规则定义

规则定义的格式如下：

```moonlex
rule rule_name(arg1: Type1, ...) -> ReturnType {
  parse {
    Pattern1 => { Action1 }
    Pattern2 => { Action2 }
  }
}
```

- `rule_name`: 规则名称，将生成同名的 MoonBit 函数。
- `arg`: 规则函数的参数，通常需要传入一个 Lexbuf。
- `ReturnType`: 规则函数的返回值类型。
- `parse`: 关键字，开始模式匹配块。
- `Pattern`: 正则表达式模式。
- `Action`: MoonBit 代码块，当匹配该模式时执行。
    - `$startpos`: 匹配开始时的位置。
    - `$endpos`: 匹配结束时的位置。

### 正则表达式语法

MoonLex 支持的正则表达式语法如下：

- 单个字符：如 `'a'`、`'b'`、`'1'`、`'@'` 等，支持转义字符如 `\n`、`\t`、`\\`、`'\x0D'`、`'\u3000'`
- 字符范围：如 `['0'-'9']`、`['A'-'Z' 'a'-'z' '_']`，支持负向范围如 `[^'a'-'z']`
- 字符串：如 `"hello"`、`"world"`，表示依次匹配字符串中的每个字符
- 下划线：`_`，表示匹配任意单个字符
- `eof` 关键字，表示匹配输入结束
- 零次或多次重复：`*`，表示前面的表达式重复零次或多次
- 一次或多次重复：`+`，表示前面的表达式重复一次
- 零次或一次重复：`?`，表示前面的表达式重复零次或一次
- 串联：如 `'a' 'b' 'c'`，表示依次匹配 `'a'`、`'b'`、`'c'`
- 选择：`|`，如 `'a' | 'b' | 'c'`
- 分组：使用括号 `(` 和 `)` 进行分组，以使用最高表达式优先级，如 `('a' 'b') | 'c'`
- 捕获：使用 `as` 关键字捕获匹配的子串，如 `digit+ as t`

## MoonYacc (LR(1) Parser Generator)

MoonYacc 是一个 LR(1) 的语法分析器生成器，主要借鉴了 Menhir 中的 Pager's LR(1) 算法实现。它接受 `.mbty` 文件作为输入，并生成 `.mbt` 代码。你可以安装 vscode 插件 [MoonYacc Language Support](https://marketplace.visualstudio.com/items?itemName=hackwaly.moonyacc) 来获得语法高亮支持。

MoonYacc 使用 MoonBit 语言实现，它是开源的，代码仓库位于 [moonbitlang/moonyacc](https://github.com/moonbitlang/moonyacc)。

### 示例 (`parser/parser.mbty`)

```moonyacc
// 指定位置的类型，默认是 Unit
%position<Int>
// 指定起始非终结符，这将生成一个同名的 pub 函数
%start start

// Token 可以携带数据，这里 NUMBER 携带一个 Int 类型的数据
%token<Int> NUMBER
// Token 也可以指定一个字符串作为其文本表示
%token PLUS         "+"
%token MINUS        "-"
%token STAR         "*"
%token LPAREN       "("
%token RPAREN       ")"

// 指定非终结符的类型
%type<Int> start
%type<Int> add
%type<Int> factor
%type<Int> term

%%

// 语法规则
start
  : add                     { $1 }
  ;

add
  : lhs=add "+" rhs=factor  { lhs + rhs }
  | lhs=add "-" rhs=factor  { lhs - rhs }
  | factor                  { $1 }
  ;

factor
  : lhs=factor "*" rhs=term { lhs * rhs }
  | term                    { $1 }
  ;

term
  : NUMBER                  { $1 }
  | "(" add ")"             { $2 }
  ;
```

### 语法定义文件语法

MoonYacc 的语法定义文件主要由两部分组成，中间用 `%%` 分隔：

1.  **声明部分**：定义 Token、非终结符类型、起始符号、优先级等。
2.  **规则部分**：定义语法规则和对应的语义动作。

你可以在文件开头和结尾使用 `%{` 和 `%}` 包含 MoonBit 代码，这些代码会被直接插入到生成的 Parser 代码中，通常用于引入依赖或定义辅助函数。

#### 声明部分

- `%token<Type> Name "Alias"`: 定义终结符（Token）。
    - `<Type>`: 可选，指定 Token 携带的数据类型。
    - `Name`: Token 的名称，通常大写。
    - `"Alias"`: 可选，Token 的别名，用于在错误信息中显示更友好的名称。
- `%type<Type> Name`: 定义非终结符的类型。
    - `<Type>`: 指定非终结符返回的数据类型。
    - `Name`: 非终结符的名称。
- `%start Name`: 指定起始非终结符。MoonYacc 会为每个起始非终结符生成一个公开的解析函数。
- `%position<Type>`: 指定位置信息的类型，默认为 `Unit`。
- `%left`, `%right`, `%nonassoc`: 定义 Token 的结合性和优先级。后定义的优先级更高。

#### 规则部分

规则定义的格式如下：

```text
NonTerminal
  : Pattern1 { Action1 }
  | Pattern2 { Action2 }
  ;
```

- **NonTerminal**: 非终结符的名称，必须是合法的小写开头的标识符。

- **Pattern**: 由终结符和非终结符组成的序列。
- **Action**: MoonBit 代码块，当匹配该规则时执行。代码块中最后且唯一的表达式将作为该规则的返回值。
    - `$1`, `$2`, ...: 引用 Pattern 中第 n 个符号的值（索引从 1 开始）。
    - `name=Symbol`: 可以给符号起别名，然后使用 `name` 引用其值，这比使用数字索引更清晰且不易出错。

## 结合使用

在主程序中，我们可以组合 Lexer 和 Parser 来处理输入。

### 示例 (`example_test.mbt`)

```moonbit
///|
fn calc(input : String) -> Int raise {
  // 1. 使用 Lexer 将字符串转换为 Token 数组
  let tokens = @lexer.tokenize(input)
  // 2. 使用 Parser 解析 Token 数组
  @parser.start(tokens, initial_pos=0)
}

///|
test "example" {
  inspect(calc("3 + 2 - 5"), content="0")
  inspect(calc("3 + 2 - 5 * 0"), content="5")
  inspect(calc("3 + (2 - 5) * 0"), content="3")
}
```

*MoonYacc 还支持生成 pull 模式（不再要求输入必须是一个已经解析好的 Token 数组）的 Parser，详情请参考 MoonYacc 的[手册](https://github.com/moonbitlang/moonyacc/blob/master/doc/MANUAL.md)*
