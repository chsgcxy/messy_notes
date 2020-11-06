# GCC 工具及相关介绍

[TOC]

## gcc常用命令

编译目标控制

```shell
-E                       Preprocess only; do not compile, assemble or link.
-S                       Compile only; do not assemble or link.
-c                       Compile and assemble, but do not link.
-o <file>                Place the output into <file>.
```

编译单个汇编文件

汇编源码test.S

```asm
.section ".text.init"

.globl _start

_start:
la x1, data1
add x2, x1, x3
sub x1, x3, x4
mul x5, x1, x3

.section ".data"
data1: .word 0x00000001
data2: .word 0x00000002
```

链接脚本link.ld如下

```lds
OUTPUT_ARCH( "riscv" )
ENTRY(_start)

SECTIONS
{
  . = 0x00000000;
  .text.init : { *(.text.init) }
  .text : { *(.text) }
  .data : { *(.data) }
  .bss : { *(.bss) }
}
```

编译命令

```shell
riscv32-unknown-elf-gcc -march=rv32imafv -nostartfiles -T./link.ld test.S -o test
```

编译优化

```shell
-O0 不做任何优化
-O1 主要对代码的分支，表达式，常量来进行优化
-O2 加入了寄存器的使用，load和store的频率会降低
-O3 额外的启用了 -finline-functions 等高等级优化，不建议使用
-Os 在O2基础上启用空间优化，优化代码尺寸
```

编译动态链接库

```shell
#需要注意的是动态链接库的名字libtest.so中的lib是必须加的
gcc test.c -shared -fPIC -o libtest.so
```

编译静态链接库

```shell
gcc -c test.c
ar -crv libtest.a test.o
```

调试

```shell
-g 保留调试信息，会使elf中增加若干个debug段
-W 使能编译警告，后面接各种警告类型，使用-Wall可以开启所有警告
-w 关闭编译警告
```

## riscv-GAS扩展汇编指令的步骤

首先不得不说gas里面各个架构下面的代码都不太一样，本以为会像内核的设备驱动一样，能明显的看出来各个类似驱动是兄弟关系。但实际上gas下面的各个架构的代码差异还比较大，即便是定义指令的结构体也是各个架构自己定义的，具体原因不太清楚，只是扫了一眼，有时间应该再细致一些看看（大概率是以后不会再看了）

以下步骤基于riscv官方提供的工具链源码

[https://github.com/riscv/riscv-gnu-toolchain](https://github.com/riscv/riscv-gnu-toolchain)

### step1-修改opcode头文件

```c
//修改riscv-binutils/include/opcode/riscv-opc.h文件,在文件中增加对新指令的注册
// MATCH即指令编码本身
// MASK即匹配指令时需要检查的每一个bit，需要检查的置1（不管编码本身是1还是0，需要检查则置1）
// 举例
//    name  |31  26 |25 |24 20 |19 15 |14 |13 12 |11 7 |6 0
// xxxxx.xx |000001 |0  |rs2   |rs1   |0  |00    |rd   |1111011

#define MATCH_XXXXX_XX 0x5e002057
#define MASK_XXXXX_XX  0xfe00707f
DECLARE_INSN(xxxxx_xx, MATCH_XXXXX_XX, MASK_XXXXX_XX)
```

### step2-修改opcode源文件

```c
// 修改riscv-binutils/opcodes/riscv-opc.c
// 在riscv_opcodes数组中添加新指令
{"xxxxx.xx", 0, {"V", 0}, "Vd,Vt,Vs", MATCH_XXXXX_XX, MASK_XXXXX_XX, match_opcode, 0 }
```

### step3-修改参数校验函数

```c
// 修改gas/config/tc-riscv.c
// 在validate_riscv_insn中增加相关参数的校验
// riscv 在validate_riscv_insn实现了指令参数的校验
// 例如指令： vslideup.vi
// 注册参数列表为 "Vd,Vt,Vi,Vm"
// [31:26] |[25] |[24:20] |[19:15] |[14:12] |[11:7] |[6:0]
// 001110  |vm   |vs2     |imm     |011     |vd     |1010111
// 函数中遍历指令的参数列表，其中宏定义如下
// #define OP_MASK_RD     0x1f
// #define OP_SH_RD       7

// #define OP_MASK_VM     0x1
// #define OP_SH_VM       25

// #define OP_MASK_RS2    0x1f
// #define OP_SH_RS2      20

// #define OP_MASK_VI     0x1f
// #define OP_SH_VI       15

// 这样循环如下代码便能够遍历所有参数是否设置合法
    case 'V':
        switch ( c = *p++) {
        case 'd':
            USE_BITS (OP_MASK_RD, OP_SH_RD);
            break;
        case 'm':
            USE_BITS (OP_MASK_VM, OP_SH_VM);
            break;
        case 't':
            USE_BITS (OP_MASK_RS2, OP_SH_RS2);
            break;
        case 'i':
            USE_BITS (OP_MASK_VI, OP_SH_VI);
            break;
        }
        break;
```

### step4-添加指令组装处理

```c
// 修改gas/config/tc-riscv.c
// 在riscv_ip函数中增加指令组装处理
case 'i':
    if (my_getSmallExpression (imm_expr, imm_reloc, s, p)
        || imm_expr->X_op != O_constant
        || imm_expr->X_add_number < 0
        || imm_expr->X_add_number >= 32)
    {
        as_bad (_("bad value for uimm[19:15] field, "
                "value must be0...32"));
        break;
    }

    INSERT_OPERAND (VI, *ip, imm_expr->X_add_number);
    imm_expr->X_op = O_absent;
    s = expr_end;
    continue;
```

### step5-添加指令打印信息

```c
// 修改opcodes/riscv-dis.c文件
// 在该文件的print_insn_args函数中新增指令打印信息
    case 'i':
        print (info->stream, "%d", EXTRACT_OPERAND(VI, l));
        break;
```

### step6-同步修改gdb相关文件

将riscv-opc.h和riscv-opc.c的修改同步到riscv-gdb目录的对应目录下的riscv-opc.h和riscv-opc.c文件中

## strip工具

strip工具可以除去目标elf文件中的行号信息、重定位信息、调试段、注释段、文件头以及所有或部分符号表，减少elf对象文件的大小

==也有人说是处理COFF文件，这个COFF和elf到底有什么区别？具体说不好，但是感觉结构很相似，strip的help信息中描述为Removes symbols and sections from files，也没有具体说明，这里先暂且理解为处理ELF文件==

```shell
-R --remove-section=<name>    Also remove section <name> from the output
-g -S -d --strip-debug        Remove all debugging symbols & sections
```

## readelf工具

Display information about the contents of ELF format files

关于elf文件格式，可以参考之前的总结**arm-linux-kmodule-load.md**中的描述

```shell
// 查看节区头部表
-S --section-headers   Display the sections' header
// 查看文件头
-h --file-header       Display the ELF file header
```

## objcopy工具

Usage: objcopy [option(s)] in-file [out-file]
Copies a binary file, possibly transforming it in the process

objcopy可以copy文件内容到另一个文件中，过程中可以进行格式转换

### objcopy将elf转换为bin

```Makefile
# -O --output-target <bfdname>     Create an output file in format <bfdname>
# -R --remove-section <name>       Remove section <name> from the output
# -S --strip-all                   Remove all symbol and relocation information
objcopy -O binary -R .comment -S test.elf test.bin
```

### objcopy仅输出某一个节区

```Makefile
-j --only-section <name>         Only copy section <name> into the output
objcopy -O binary -j .data test.elf test.bin
```

### 指定空白区填充值

```Makefile
# --gap-fill <val>              Fill gaps between sections with <val>
objcopy -O binary --gap-fill 0xff test.elf test.bin
```