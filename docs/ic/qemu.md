# QEMU

QEMU is a generic and open source machine emulator and virtualizer

显然，QEMU有两个用途

- 作为性能非常不错的模拟器，看起来这对于SOC开发的场景，在调试整套系统软件时是一个不错的选择
- 作为虚拟机，qemu包含了虚拟化的一套内容，可以配合KVM来实现，这部分内容暂时不太了解

本文只针对QEMU作为模拟器的场景, 有些技术内容翻译自官方文档[https://qemu-project.gitlab.io/qemu/]

## 整体实现

QEMU采取了动态转换机制，会将target代码翻译成名为TCG的IR，IR又会翻译成host代码，代码按照
TranslationBlock分块进行转换和执行。舍得舍得，有舍必有得，有得必有舍。速度提升了，可调试性就下降了。
QEMU跟一般模拟器相比，调试起来更麻烦，没法轻松分析指令行为，比如说想单步运行，实时查看寄存器状态，
交互式的调试，这种QEMU做不到，它为的还是更快。

从模拟器的角度来看，我们主要关注QEMU的如下几个方面是如何实现的。

- 各个部分代码功能。了解代码层次结构划分
- 整体流程。从顶层来看，整体的流程。了解QEMU大概是如何工作的。
- 指令执行过程。包含反汇编过程，了解这个过程，从中找到一些调试手段。
- 对于各个被模拟的设备的管理
- host调试手段
- target调试手段

至于其涉及的虚拟化部分，这部分太大，暂时也对此没有什么了解，后续若在工作中需要用到再去研究，毕竟目前这不是我感兴趣的点。

除此之外，在编程语言方面，我也有疑惑。既然QEMU费尽心机，把C语言尽可能做的像C++, 那么为什么不干脆使用C++呢？

## 代码结构

先来从整个目录的角度来分析一下各部分代码的功能。整体代码结构如下

目录 | 功能
---|---
bsd-user | 支持BSD系统，通过这一层，可以直接运行BSD应用程序
linux-user | 支持linux系统，通过这一层，可以直接运行linux应用
hw | 实现了对各种外设的模拟
QOM | QEMU的对象管理，用面向对象的思想实现了一套QEMU管理对象的抽象和封装，各个被模拟的模块都是一个QOM子类
softmmu |
target |

我们可以看到，主目录有audio目录，在hw目录下面，也有audio目录，这两个目录的功能分别是什么？

## 设备管理之QOM

可以作为学习面向对象原理的材料，把一个不支持面向对象的C语言，封装成支持面向对象的C语言，这种封装和使用方法，值得学习，通过学习，应该会对面向对象有更深的理解。（当然，这真的有意义吗？ c++ 或者python它不香吗？）

在qemu的docs/devel/qom.rst中，包含了难得的对QOM的介绍。QEMU Object Model 提供了一个框架，基于这个框架，使用者可以把自己添加类型做注册和实例化。

TypeInfo 和 TypeImpl

```c
struct TypeInfo
{
    const char *name;
    const char *parent;

    size_t instance_size;
    size_t instance_align;
    void (*instance_init)(Object *obj);
    void (*instance_post_init)(Object *obj);
    void (*instance_finalize)(Object *obj);

    bool abstract;
    size_t class_size;

    void (*class_init)(ObjectClass *klass, void *data);
    void (*class_base_init)(ObjectClass *klass, void *data);
    void *class_data;

    InterfaceInfo *interfaces;
};

struct TypeImpl
{
    const char *name;

    size_t class_size;

    size_t instance_size;
    size_t instance_align;

    void (*class_init)(ObjectClass *klass, void *data);
    void (*class_base_init)(ObjectClass *klass, void *data);

    void *class_data;

    void (*instance_init)(Object *obj);
    void (*instance_post_init)(Object *obj);
    void (*instance_finalize)(Object *obj);

    bool abstract;

    const char *parent;
    TypeImpl *parent_type;

    ObjectClass *class;

    int num_interfaces;
    InterfaceImpl interfaces[MAX_INTERFACES];
};
```


这两者定义基本相同，但

以RISCV CPU来举例说明

```c
static const TypeInfo riscv_cpu_type_infos[] = {
    {
        .name = TYPE_RISCV_CPU,
        .parent = TYPE_CPU,
        .instance_size = sizeof(RISCVCPU),
        .instance_align = __alignof__(RISCVCPU),
        .instance_init = riscv_cpu_init,
        .abstract = true,
        .class_size = sizeof(RISCVCPUClass),
        .class_init = riscv_cpu_class_init,
    },
    DEFINE_CPU(TYPE_RISCV_CPU_ANY,              riscv_any_cpu_init),
    DEFINE_CPU(TYPE_RISCV_CPU_BASE64,           rv64_base_cpu_init),
    DEFINE_CPU(TYPE_RISCV_CPU_SIFIVE_E51,       rv64_sifive_e_cpu_init),
    DEFINE_CPU(TYPE_RISCV_CPU_SIFIVE_U54,       rv64_sifive_u_cpu_init),
};

DEFINE_TYPES(riscv_cpu_type_infos)
```


## 调试方法

ctrl + A / X 退出

ctrl + A / C 监控模式

-D log文件

-d 调试模块开关

## 代码细节

```c
// cpu线程
tcg_cpu_thread_fn() //tcg
    cpu_exec_step_atomic()
        tb_gen_code()
        cpu_tb_exec()

/* 生成(gen)过程 */

tb_gen_code()
    gen_intermediate_code()
    trace_translate_block()
    tcg_gen_code()

gen_intermediate_code() //arch
    translator_loop(TranslatorOps *ops) //tcg
        ops->translate_insn() : riscv_tr_translate_insn()

riscv_tr_translate_insn()
    decode_opc()
        decode_insn32() // 自动生成，在编译阶段生成的<decode-insn32.c.inc>
            trans_xxxx() //insn_trans目录下的各个trans_xxx_c.inc文件
                tcg_gen_xxxx()
                gen_xxxx()

gen_helper_xxxx()
    tcg_gen_callN(helper_xxxx(), .....)


gen_helper_tlb_flush()



/* 执行过程 */



```


