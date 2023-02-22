# Gem5指令集框架解析

Gem5实现了一套指令集描述语言，或者称为指令集描述框架。主要是借助ply(python版本的lex,yacc)来实现的语法定义和分析

- lex(Lexical Analyzar), 词法分析生成器
- yacc(Yet Another Compiler Compiler), 编译器代码生成器

实际上看起来，.isa的语法有点儿像python,甚至可以理解为python

## 文件结构

src/arch/isa_parser 目录下存放了与架构相关的编译器文件
build_tools 目录下有一些编译器基础文件
src/arch/arm 下面放了指令集描述源文件，不同的架构目录不同

## 编译原理

### Lex

能根据定义的正则表达，将文本中的词进行匹配，生成一个个Token实例。以isa_parser.py中举例，具体使用时需要有如下定义

首先要定义token的关键词,这相当于token类型的声明

```python
   # List of tokens.  The lex module requires this.
    tokens = reserved + (
        # identifier
        'ID',

        # integer literal
        'INTLIT',

        # string literal
        'STRLIT',

        # code literal
        'CODELIT',

        # ( ) [ ] { } < > , ; . : :: *
        'LPAREN', 'RPAREN',
        'LBRACKET', 'RBRACKET',
        'LBRACE', 'RBRACE',
        'LESS', 'GREATER', 'EQUALS',
        'COMMA', 'SEMI', 'DOT', 'COLON', 'DBLCOLON',
        'ASTERISK',

        # C preprocessor directives
        'CPPDIRECTIVE'
    )
```

除此之外，还有定义匹配规则。匹配规则有两种定义方法，字符串和函数。
函数优先级高于字符串，而且按照函数编写的优先级来定义匹配的优先级，字符串则按照匹配长度来定义优先级，长的优先
总结起来，有如下优先级规则：

- 如果用字符串方式定义，那么用于匹配的正则表达式越长则匹配优先级越高；
- 如果用函数方式定义，函数在代码中出现的位置越靠前则匹配优先级越高；
- 用函数方式定义的匹配规则优先级永远高于用字符串定义的

LPAREN是通过字符串的方式定义的，INTLIT是通过函数定义的，无论是字符串还是函数，都应该加上前缀 t_
函数还应该显式的return t

```python
# Regular expressions for token matching
t_LPAREN           = r'\('
t_RPAREN           = r'\)'
t_LBRACKET         = r'\['

def t_ID(self, t):
    r'[A-Za-z_]\w*'
    t.type = self.reserved_map.get(t.value, 'ID')
    return t

# Integer literal
def t_INTLIT(self, t):
    r'-?(0x[\da-fA-F]+)|\d+'
    try:
        t.value = int(t.value,0)
    except ValueError:
        error(t.lexer.lineno, 'Integer value "%s" too large' % t.value)
        t.value = 0
    return t
```

### yacc

