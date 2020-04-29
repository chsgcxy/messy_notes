# LA指令的理解

[TOC]

以前也写过不少la指令的代码，但是都是似懂非懂，糊里糊涂的成功了，今天偶然的机会关注了一下la指令

## 起因

起因是我需要写一个测试case,测试一个自定义矩阵运算指令，需要提供三个矩阵基地址作为指令参数，即类似mm_add rd, r1, r2 这样的操作，将r1和r2指向的矩阵求和写入rd指向的地址

于是我是这样实现的

```S
la x23, l1start+3576
la x4, l1start+2580
la x19, l1start+336
add.mm (x23), (x4), (x19)
```

在链接脚本中定义了符号l1start

```lds
.data : { *(.data) }
l1start = 0xC0000000;
```

这个时候就开始思维混乱了，按照C的逻辑，l1start = 0xC0000000岂不是说l1start值为0xC0000000， 那l1start这个符号的地址是？？？难道我这样写不对吗？？？？

## 经过

首先，根据指令集手册，la是伪指令

```text
la
rd, symbol
x[rd] = &symbol
地址加载 (Load Address). 伪指令(Pseudoinstruction), RV32I and RV64I.
将 symbol 的地址加载到 x[rd]中。当编译位置无关的代码时,它会被扩展为对全局偏移量表
(Global Offset Table)的加载。对于 RV32I,等同于执行 auipc rd, offsetHi,然后是 lw rd,
offsetLo(rd);对于 RV64I,则等同于 auipc rd, offsetHi 和 ld rd, offsetLo(rd)。如果 offset 过大,
开始的算加载地址的指令会变成两条,先是 auipc rd, offsetHi 然后是 addi rd, rd, offsetLo。

auipc rd, immediate
x[rd] = pc + sext(immediate[31:12] << 12)
PC 加立即数 (Add Upper Immediate to PC). U-type, RV32I and RV64I.
把符号位扩展的 20 位(左移 12 位)立即数加到 pc 上,结果写入 x[rd]。
```

使用spike的debug模式具体看一下这个段代码的执行(这里面仍有疑问，我用的是riscv32-unknown-elf-gcc编译的，并没有按照手册中描述的RV32I编译成auipc和lw, 而是编译成了RV64I的auipc和addi, gcc先不看了，有时间再去看吧......)

```text
core   0: 0x00000000000002c4 (0xc0001b97) auipc   s7, 0xc0001
: reg 0 s7
0xffffffffc00012c4
core   0: 0x00000000000002c8 (0xb34b8b93) addi    s7, s7, -1228
core   0: 0x00000000000002cc (0xc0000217) auipc   tp, 0xc0000
core   0: 0x00000000000002d0 (0x74820213) addi    tp, tp, 1864
core   0: 0x00000000000002d4 (0xc0000997) auipc   s3, 0xc0000
core   0: 0x00000000000002d8 (0xe7c98993) addi    s3, s3, -388
core   0: 0x00000000000002dc (0x23326bfb) add.mm s7, tp, s3
```

从中可以看出在执行auipc指令时，0xc0001 左移12位加上当前pc值0x2c4， 得出来0xc00012c4, 而我链接脚本中的l1start = 0xC0000000确实被编译成了地址，也就是说la x23, l1start 实际上就是把0xc0000000加载到寄存器x23中

去链接脚本文档中找一下有没有相关描述，在gnu官网的ld部分中，找到了一些描述

```text
3.5 Assigning Values to Symbols
You may assign a value to a symbol in a linker script. This will define the symbol and place it into the symbol table with a global scope.

You may assign to a symbol using any of the C assignment operators:

The first case will define symbol to the value of expression. In the other cases, symbol must already be defined, and the value will be adjusted accordingly.

floating_point = 0;
SECTIONS
{
  .text :
    {
      *(.text)
      _etext = .;
    }
  _bdata = (. + 3) & ~ 3;
  .data : { *(.data) }
}
In this example, the symbol ‘floating_point’ will be defined as zero. The symbol ‘_etext’ will be defined as the address following the last ‘.text’ input section. The symbol ‘_bdata’ will be defined as the address following the ‘.text’ output section aligned upward to a 4 byte boundary.
```

这样看来，当我们写l1start = 0xC0000000;的时候，实际上是定义了l1start这个符号的地址为0xC0000000

## 高潮

此时已经明白了，但突然又想到了之前写的另一段代码按照现在的理解似乎有问题，代码如下

```S
la x1, 327690
csrw xxxxx, x1
```

那327690算什么，算符号还是算数值？经过la x1, 327690之后x1中是什么值？

再去debug一下

```text
: until pc 0 108
:
core   0: 0x0000000000000108 (0x00a08093) addi    ra, ra, 10
:
core   0: 0x000000000000010c (0x40009073) csrw    xxxxx, ra
: reg 0 ra
0x000000000005000a
```

hex(327690) 就是 '0x5000a'， 编译器竟然把la指令翻译成了addi, 把我的错误纠正了......

## 尾声

看来对于伪指令，还是得看编译器的实现是怎样的，有时候也不能完全按照文档，因为总有人不按文档，也总有不完善的文档。
