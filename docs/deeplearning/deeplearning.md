# deeplearning

[TOC]

## FP16

一个fp16数据占据两个字节，1位符号位，5位指数位，10位有效精度

- 符号位
  - 0：正数
  - 1：负数
- 指数位：与15的偏差
  - max_e=11110-01111=15
  - min_e=00001-01111=-14
  - 00000和11111有其他意义
- 数值计算公式为：${(-1)}^{signbit}\times2^{e-15}\times(1+\sum_{i=1}^{10}(b_{10-i}\times2^{-i}))$
- 最大值：$0 11110 1111111111={(-1)}^0\times2^{30-15}\times(1+1-2^{-10})=65504$
- 最小值：$0 00001 0000000000=2^{(-14)}=6.10 \times10^{(-5)}$

## 卷积

实际上是对应数据相乘然后求和，可以理解为加权求和

## 数据归一化

归一化（标准化）可以定义为：把你需要处理的数据经过处理后（通过某种算法）限制在你需要的一定范围内。
首先归一化是为了后面数据处理的方便，其次是保证模型运行时收敛加快，归一化并不是约束到0~1之间

## 深度学习框架

框架 | 前端 | 后端 | 硬件
---|---|---|---
tensorflow | XLA | LLVM | GPU / ARM / X86
tensorflow/Caffe2/PyTorch/MXNet | Poplar | POPLAR GRAPH COMPILER | IPU
tensorflow/ONNX/CoreML | TVM(NNVM) | cuda/LLVM/Metal/OpenCL |
tensorflow/MxNet/ONNX | NGraph | IA Transformer/NNP |

## LLVM

### 什么是LLVM

参考自[LLVM官网](https://llvm.org/)

> The LLVM Project is a collection of modular and reusable compiler and toolchain technologies. Despite its name, LLVM has little to do with traditional virtual machines. The name "LLVM" itself is not an acronym; it is the full name of the project.

LLVM是一种模块化和可重用的编译器和工具链技术。LLVM的名字其实和low level virtual machines没有一毛钱的关系，它只是一个项目名称而已(老外真任性，起个名字也不告诉我们为啥)

> LLVM provides some unique capabilities, and is known for some of its great tools (e.g., the Clang compiler 2 , a C/C++/Objective-C compiler which provides a number of benefits over the GCC compiler), the main thing that sets LLVM apart from other compilers is its internal architecture.

LLVM有很多特性，它的内部架构使它与众不同

> Beyond the composition of the compiler itself, the communities surrounding popular language implementations were usually strongly polarized: an implementation usually provided either a traditional static compiler like GCC, Free Pascal, and FreeBASIC, or it provided a runtime compiler in the form of an interpreter or Just-In-Time (JIT) compiler. It was very uncommon to see language implementation that supported both, and if they did, there was usually very little sharing of code.

关于主流语言的实现的讨论通常比较分化，一个语言的实现要么提供一个像GCC,FreePascal,FreeBASIC一样的static compiler(静态编译器,完全编译完成之后再去执行)，要么以解释器或者JIT(Just-In-Time)编译器的形式提供一个runtime compiler(运行时编译器)。很少能看到一种这两者都支持的语言实现，即使有，他们通常也只有非常少的代码复用

> Finally LLVM has also been used to create a
broad variety of new products, perhaps the best known of which is the OpenCL GPU programming language and
runtime.

可以参考，人工智能芯片的编译器完全可以借助LLVM

### JIT编译器和解释器

JIT编译器和解释器还是有区别的，JIT是即时编译，实质是还是编译，那么流程上仍然是

```c
中间代码->[编译]->可执行二进制->[执行]->结果
```

但是解释执行流程上是

```c
中间代码->[解释]->结果
```

> 说JIT比解释快，其实说的是“执行编译后的代码”比“解释器解释执行”要快，并不是说“编译”这个动作比“解释”这个动作快。然而这JIT编译再怎么快，至少也比解释执行一次略慢一些，而要得到最后的执行结果还得再经过一个“执行编译后的代码”的过程。所以，对“只执行一次”的代码而言，解释执行其实总是比JIT编译执行要快。怎么算是“只执行一次的代码”呢？粗略说，下面两个条件同时满足时就是严格的“只执行一次”只被调用一次，例如类的初始化器（class initializer，< clinit >()V）没有循环对只执行一次的代码做JIT编译再执行，可以说是得不偿失。对只执行少量次数的代码，JIT编译带来的执行速度的提升也未必能抵消掉最初编译带来的开销。只有对频繁执行的代码，JIT编译才能保证有正面的收益。
作者：RednaxelaFX
链接：https://www.zhihu.com/question/37389356/answer/73820511
来源：知乎
著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。

### 传统静态编译器

## 计算图

计算图

## 图优化

tvm的算子优化包括operator fusion, pruning, layout transformation, and memory management，这个一个高层次的优化，与后端没有关系，对于operator fusion很好理解，一些可以合并的操作可以提前合并，但是所谓的layout transformation和memory management是什么意思呢？在tvm中，relay来做图优化

## tensor优化

对于tensor优化，tensor即张量，是各个算子所要操作的矩阵，基于tensor的优化也就是说矩阵运算的优化。举个例子矩阵加法，如果在x86上那么充分利用cache会有很大的效率提升，如果在AI芯片上，那么很有可能支持矩阵加法的操作，可以直接转换为芯片的矩阵加法操作,在TVM中tvm来做tensor的优化

## 深度学习(神经网络)编译器

类似于代码编译器，我们需要一套软件栈来衔接前端(Frontend)各种不同的深度学习框架（tensorflow,Caffe,MXNet...）,然后映射到后端各种不同的计算硬件平台上,并在此过程中进行各种不同层面的优化措施。这就是神经网络编译器或者工具链所要解决的问题

### XLA

XLA

### LSTM

参考[LSTM详解](https://blog.csdn.net/zhangbaoanhadoop/article/details/81952284)
