# riscv-torture 总结

[TOC]

## 简介

老外说话有意思，把测试当做一种严刑拷打。riscv-torture使用scala编写，同时带有Makefile和链接脚本用来编译生成的测试汇编文件。为什么要使用scala呢，原因是有人用scala实现了一个名为Chisel的库，利用Chisel编译出.fir文件，再通过firrtl工具就能转换成verilog，也就是说scala能够直接转换成verilog。再说的直白一点儿就是，IC团队完全可以使用scala来设计芯片。RISCV开源社区就是这么干的！？

Rocket Chip是一个基于Chisel的开源soc生成器，还没具体去了解，目前看来无关紧要，暂且搁置。

Scala工程一般基于sbt构建，scala需要java的runtime。个人认为scala就像一个java脚本语言。

这份代码相关资料很少，代码中几乎是没有注释的，readme中也仅有很少的信息。不过坚持看几天，大部分代码都能弄清楚什么意思，这归功于自注释做的不错。软件的设计上有很多值得学习的点，整体思路很清晰，部分细节代码上个人觉得逻辑不是很清晰，有些绕，但不影响它成为一个质量较好的开源软件。

## 软件结构

riscv-torture包含三部分，每个部分相对独立，这在readme中也有提及

- generator  根据配置文件生成riscv汇编文件
- testrun 将riscv汇编文件进行编译，并在模拟器上运行
- overnight 反复的生成测试文件并在模拟器上运行

### generator

从面向对象的角度来讲，torture既然要生成汇编代码，那么最基础的抽象应该就是指令, 如果是我去做，我肯定会写一个Ins的基础类。torture也是这样做的，命名为Inst。但它为了对参数也做管理，又向下添加了一层，抽象出了operands，即指令参数，这是我所没有考虑到的。所有的operands都可以字符串化，这样就能轻松组合成文本。有人说过计算机世界的问题都可以通过增加一层来解决，以前我理解成在中间加一层，现在才发现，在最底下加也是加一层，无论在哪里加，都是加一层。对于汇编来讲，汇编指令参数的主要组成部分就是寄存器，所以，torture又对寄存器进行了抽象，随之而来的就是一系列的寄存器管理类，大概命名为pool之类，即各种各样的寄存器池。这种思想应该是来源于编译器，有时间真应该去看看编译原理。

**构成指令的元素管理**
构成指令的所有元素都继承于抽象类Operand
```plantuml
class  Operand

class Reg extends Operand {
    {field} hwreg
    {method}  def toString
}
class Imm extends Operand {
    {method}  def toString
}
class RegImm extends Operand {
    {method}  def toString
}
class Mem extends Operand {
    {method} def  toString
    {method} def dumpdata
    {method} def dumpaddrs
}
class Label extends Operand {
    {method}  toString
}
```

**寄存器管理**
我们可以看到，VRegsMaster并没有使用ScalarRegPool接口，但方法名保持了一致，这一点是不是设计上的疏忽？

```plantuml
class HWReg {
    {field} String name
    {field} Boolean readable
    {field} Boolean writable
    {method} def backup()
    {method} def restore()
    {method} static def filter_read_zero
    {method} static def filter_read_any
    {method} static def filter_write_visible
    {method} static def alloc_read
    {method} static def alloc_write
    {method} static def free_read
    {method} static def free_write
}
class HWRegPool {
    {field} ArrayBuffer[HWReg] hwregs
    {method} def backup()
    {method} def restore()
}
HWReg <-- HWRegPool

interface ScalarRegPool extends HWRegPool {
    def init_regs()
    def save_regs()
    def init_regs_data()
    def output_regs_data()
}

class FRegsPool extends HWRegPool
class VRegsPool extends HWRegPool
interface PoolsMaster extends HWRegPool {
    {method} override def backup()
    {method} override def restore()
}

class XRegsPool extends ScalarRegPool {
    override  def save_regs()
}

class FRegsMaster extends ScalarRegPool
class FRegsMaster extends PoolsMaster {
    FRegsPool s_regpool
    FRegsPool d_regpool
    override def init_regs()
    override def save_regs()
}
FRegsPool <-- FRegsMaster

class VRegsMaster extends PoolsMaster {
    VRegsPool s_regpool
    VRegsPool d_regpool
    def init_regs()
    def save_regs()
    def init_regs_data()
    def output_regs_data()
}
VRegsPool <-- VRegsMaster
```
XRegsPool、VRegsMaster 和 FRegsMaster 担任起了最终的寄存器管理工作

**流程贯穿**

关于 HWRegPool和XRegsPool、FRegsMaster以及VRegsMaster的关系已经在上面描述清楚了， HWRegAllocator 负责使用这些HWRegPool， InstSeq来负责具体的测试指令生成，最终所有的逻辑在Prog中进行贯穿。

```plantuml
class  Operand

class Reg extends Operand {
    HWReg hwreg
    var allocated
    override def toString
}

class HWRegAllocator {
    ArrayBuffer[Reg] regs
    def reg_fn()
    def reg_read_zero(hwrp: HWRegPool)
    def reg_read_any(hwrp: HWRegPool)
    def reg_write_visible(hwrp: HWRegPool)
    def reg_write_visible_consec(hwrp: HWRegPool, regs: Int)

    def allocate_regs()
    def free_regs()
}

class Inst {
    {field} String opcode
    {field} Array[Operand]  operands
    {method} override def toString
    {method} def is_branch
    {method} def is_jmp
    {method} def is_cmp
}

class InstSeq extends HWRegAllocator {
    ArrayBuffer[Inst] insts
    def next_inst()
}
Inst <-- InstSeq
Inst --> Operand

class SeqFPMem extends InstSeq
class SeqALU extends InstSeq
class SeqMem extends InstSeq
class SeqVec  extends InstSeq

class Prog {
    name_to_seq
    XRegsPool xregs
    FRegsMaster fregs
    VRegsMaster vregs
    def seqs_find_active()
    def gen_seq()
    def code_body()
    def header(nseqs: Int)
    def code_header()
    def generate()
    def statistics()
}

SeqFPMem <-- Prog
SeqALU <-- Prog
SeqMem <-- Prog
SeqVec <-- Prog

Prog --> XRegsPool
Prog --> FRegsMaster
Prog --> VRegsMaster
```

Prog的generate方法负责组织一切生产资料产生测试汇编代码。同时，torture认为代码的正文分为代码块和数据块，每个块也大概是一个三段体结构，具体如下

- header 文件头，包含文件说明等
- code_header 代码段头，包含寄存器初始化等
- code_body 测试代码主体，包含了测试指令
- code_footer 代码段末尾，这里可以选择重复执行测试代码主体N次，以测试稳定性，循环完成后，把用到的寄存器全都dump到指定的地址上去
- data_header 标明数据段起始
- data_input 存放了寄存器初始化数据
- data_output 寄存器最终dump到这里，同时还涵盖了一块测试memory
- data_footer 结束

一种InstSeq包含了同类的指令，指令包含在insts的容器中，一条InstSeq包含了至少一条Inst。Prog根据配置文件，生成N条InstSeq，然后遍历所有InstSeq。每次遍历按顺序从每个InstSeq中取一条Inst, 以保证每一个InstSeq的指令顺序。但多个InstSeq的顺序是交错的，随机的。被挑选出来的Inst存放在ProgSeg的容器中，最后变成字符串加入到code_body中。

值得一提的是，torture可以动态的进行寄存器管理，即建立了寄存器动态申请与释放机制。这个机制使得Inst与具体的寄存器分离，在InstSeq中定义Inst，但不申请寄存器，在组建ProgSeg的时候再去动态的申请寄存器，这样能够保证测试的充分性，理论上能够保证多条InstSeq不会相互干扰（只要你把所有用到的寄存器都加入到寄存器管理中）。

## 后记

对于testrun 和 overnight 不做具体介绍，比较简单。testrun中实现了模拟器管理，并且testrun会根据参数决定申请generator实例，overnight会申请testrun实例和generator实例。
