# QEMU

QEMU is a generic and open source machine emulator and virtualizer

显然，QEMU有两个用途

- 作为性能非常不错的模拟器，看起来这对于SOC开发的场景，在调试整套系统软件时是一个不错的选择
- 作为虚拟机，qemu包含了虚拟化的一套内容，可以配合KVM来实现，这部分内容暂时不太了解

本文只针对QEMU作为模拟器的场景

## 整体实现

QEMU采取了动态转换机制，会将target代码翻译成名为TCG的IR，IR又会翻译成host代码，代码按照
TranslationBlock分块进行转换和执行。

## 代码结构

整体代码结构如下

目录 | 功能
---|---
accel | 加速相关，为了追求运行速度，增加的一些特性，比如KVM,XEN。TCG也在这个目录下，TCG中的很多东西要分发到target下面
audio | 音频相关，这个和hw下面的那个audio有啥区别？
bsd-user |
linux-user |
disas |
hw |
softmmu |
target |
tcg |




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


