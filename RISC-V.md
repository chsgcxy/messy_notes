# RISC-V

[TOC]

## 基础知识点

- riscv 的核心是 RV32I基础ISA, 是永久不会改变的
- riscv 是模块化的，它的模块化体现在可选的标准扩展，riscv编译器需要知道当前硬件包含的扩展，把代表扩展的字母加到指令集名称之后作为指示例如:RV32IMFD.这样就可以很高效，不需要支持浮点就不支持，不需要支持向量就不支持，达到定制化的目的，不会像增量ISA那样所有的指令都是必选的，不要都不行
- riscv不提供特殊的堆栈指令，即没有push和pop
- riscv选择小端字节序(高字节高地址，低字节低地址)

## ABI

ABI是指寄存器的二进制接口名称，比如说RV32I, 寄存器X0 ABI接口名为zero, X1寄存器ABI接口名为RA，ABI是人为规定了寄存器应该如何使用，编译器和线性汇编都应该遵守的接口约定

## 汇编器(例如gnu的gas)

汇编器的作用不仅仅是从处理器能够理解的指令产生目标代码,还能翻译一些扩展指令,这些指令对汇编程序员或者编译器的编写者来说通常很有用。这类指令在巧妙配置常规指令的基础上实现,称为伪指令Intrinsic Function

大多数的 RISC-V 伪指令依赖于 x0

汇编指示符：是汇编器的命令,具有告诉汇编器代码和数据的位置、指定程序中使用的特定代码和数据常量等作用

- .text:进入代码段
- .align 2:后续代码按4字节对齐
- .globl main:声明全局符号“main”
- .section .rodata:进入只读数据段
- .balign 4:数据段按 4 字节对齐
- .string “”:创建空字符结尾的字符串

riscv汇编器指令及汇编手册请参考[riscv-asm.md](https://github.com/riscv/riscv-asm-manual.git)

## 汇编代码举例

对riscv reader 中的hello world示例再做一次补充

c 代码如下

```c
#include <stdio.h>
int main()
{
    printf("Hello, %s\n", "world");
    return 0;
}
```

对应汇编代码如下，该汇编和文档中的有些出入，该汇编是通过gcc编译出来的汇编

```armasm
    .file   "test.c"
    .option nopic  #nopic是什么意思?暂时还没有查到
    .text          #代码段起始
    #进入只读数据段，下面存放了只读数据，如果
    #下面没有只读数据，则仍认为是代码段，这是和直接使用.rodata的区别
    .section    .rodata
    .align  2
.LC0:
    .string "world"
    .align  2
.LC1:
    .string "Hello, %s\n"
    .text
    .align  1 #为什么这里会是2字节对齐而不是4字节对齐？
    .globl  main
    .type   main, @function
main:
    addi    sp,sp,-16 #开辟16字节栈空间
    sw  ra,12(sp) #先进行一次返回地址压栈，做为整个程序返回地址的保留
    sw  s0,8(sp)  #保存寄存器0压栈
    addi    s0,sp,16 # s0保存了栈顶
    lui a5,%hi(.LC0)
    addi    a1,a5,%lo(.LC0)
    lui a5,%hi(.LC1)
    addi    a0,a5,%lo(.LC1)
    call    printf
    li  a5,0
    mv  a0,a5
    lw  ra,12(sp)
    lw  s0,8(sp)
    addi    sp,sp,16
    jr  ra
    .size   main, .-main
    .ident  "GCC: (GNU) 8.3.0"
```

## Intrinsic-Function

> 大多数的函数是在库中，Intrinsic Function却内嵌在编译器中。Intrinsic Function作为内联函数，直接在调用的地方插入代码，即避免了函数调用的额外开销，又能够使用比较高效的机器指令对该函数进行优化。优化器（Optimizer）内置的一些Intrinsic Function行为信息，可以对Intrinsic进行一些不适用于内联汇编的优化，所以通常来说Intrinsic Function要比等效的内联汇编（inline assembly）代码快。优化器能够根据不同的上下文环境对Intrinsic Function进行调整，例如：以不同的指令展开Intrinsic Function，将buffer存放在合适的寄存器等

转载自[SSE指令集学习：Compiler Intrinsic](https://www.cnblogs.com/wangguchangqing/p/5466301.html)
