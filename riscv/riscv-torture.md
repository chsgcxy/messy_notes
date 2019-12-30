# riscv-torture 学习总结

## 简介

老外说话有意思，把测试当做一种严刑拷打。riscv-torture使用scala编写，同时带有Makefile和链接脚本用来编译生成的测试汇编文件。为什么要使用scala呢，原因是有人用scala实现了一个名为Chisel的库，利用Chisel编译出.fir文件，再通过firrtl工具就能转换成verilog。Rocket Chip就是一个基于Chisel的开源soc生成器。Scala工程一般基于sbt构建，scala需要java的runtime。个人认为scala就像一个java脚本语言。

这份代码相关资料很少，代码中几乎是没有注释的，readme中也仅有很少的信息。不过坚持看几天，大部分代码都能弄清楚什么意思，这归功于自注释做的不错。软件的设计上有很多值得学习的点，整体思路很清晰，部分细节代码上个人觉得逻辑不是很清晰，有些绕，但不影响它成为一个较好的开源软件。

## 软件结构

riscv-torture包含三部分，每个部分相对独立，这在readme中也有提及

- generator  根据配置文件生成riscv汇编文件
- testrun 将riscv汇编文件进行编译，并在模拟器上运行
- overnight 反复的生成测试文件并在模拟器上运行

### generator

从面向对象的角度来讲，torture既然要生成汇编代码，那么最基础的抽象应该就是指令, 如果是我去做，我肯定会写一个Ins的基础类。torture也是这样做的，命名为Inst。但它为了对参数也做管理，又向下添加了一层，抽象出了operands，即指令参数，这是我所没有考虑到的。所有的operands都可以字符串化，这样就能轻松组合成文本。有人说过计算机世界的问题都可以通过增加一层来解决，以前我理解成在中间加一层，现在才发现，在最底下加也是加一层，无论在哪里加，都是加一层。对于汇编来讲，汇编指令参数的主要组成部分就是寄存器，所以，torture又对寄存器进行了抽象，随之而来的就是一系列的寄存器管理类，大概命名为pool之类，即各种各样的寄存器池。这种思想应该是来源于编译器，有时间真应该去看看编译原理。

流程方面，torture抽象了一个程序类叫Prog，其中的generate方法负责组织一切生产资料产生测试汇编代码。同时，torture认为代码的正文分为代码块和数据块，每个块也大概是一个三段体结构，具体如下

- header 文件头，包含文件说明等
- code_header 代码段头，包含寄存器初始化等
- code_body 测试代码主体，包含了测试指令
- code_footer 代码段末尾，这里可以选择重复执行测试代码主体N次，以测试稳定性，循环完成后，把用到的寄存器全都dump到指定的地址上去
- data_header 标明数据段起始
- data_input 存放了寄存器初始化数据
- data_output 寄存器最终dump到这里，同时还涵盖了一块测试memory
- data_footer 结束

#### code_body生成过程

单靠对象不足以贯穿流程，torture定义了一系列的容器来贯穿整个code_body生成流程。torture使用Seq(命名为SeqXXXXX, 例如SeqVec)来组织一系列的指令，一种Seq包含了同类的指令，指令包含在insts的容器中，一条Seq包含了至少一条Inst。Prog根据配置文件，生成N条Seq，然后遍历所有Seq。每次遍历按顺序从每个Seq中取一条Inst, 以保证每一个Seq的指令顺序。但多个Seq的顺序是交错的，随机的。被挑选出来的Inst存放在ProgSeg的容器中，最后变成字符串加入到code_body中。

值得一提的是，torture可以动态的进行寄存器管理，即建立了寄存器动态申请与释放机制。这个机制使得Inst与具体的寄存器分离，在Seq中定义Inst，但不申请寄存器，在组建PorgSeg的时候再去动态的申请寄存器，这样能够保证测试的充分性，理论上能够保证多条Seq不会相互干扰（只要你把所有用到的寄存器都加入到寄存器管理中）。


## 后记

对于testrun 和 overnight 不做具体介绍，比较简单。testrun中实现了模拟器管理，并且testrun会根据参数决定申请generator实例，overnight会申请testrun实例和generator实例。
