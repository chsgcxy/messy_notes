# GEM5 设计与实现分析

[TOC]

官网：http://www.gem5.org
学习指导：http://www.gem5.org/documentation/learning_gem5/introduction

## 分析点

- 单元的设计思路
- 如何解决寄存器冲突
- 流水线的实现方式
- 时钟如何统一
- 多核设计
- 总线，端口的抽象
- debug如何支持
- 地址映射的处理方法

## 简介

gem5是一个模块化的计算机架构模拟器,最初用于计算机架构探索，以及微处理器架构探索，当然在研究行业，教学行业也有推广。但总体来讲，gem5是偏向于学术的一款模块化模拟器平台。

gem5目前还在发展，支持的CPU类型有：Alpha, ARM, MIPS, Power, SPARC, RISC-V 以及 64 bit x86。本文主要侧重的是RISC-V架构。对于RISC-V, 目前gem5主线还不支持vector扩展，但amf扩展都已经支持。

### 工作方式

gem5是一个模块化的模拟器平台。它提供了一系列的组件，比如CPU，cache，ddr，各种总线，即你在一个普通CPU上能够看到的部分，它都有对应的实现。你可以通过一系列配置脚本（python脚本）将这些组件组合在一起，组装成一个SOC系统，即生成了一个特定的模拟器。

```plantuml
(gem5源码) as source
(特定架构的gem5应用程序) as target
(python配置脚本) as config
source --> target: 特定平台编译(ARM, x86, RISC-V, ...)
config --> target: 配置输入，用于组合各个组件并启动模拟器
(运行于模拟器的elf可执行文件) as bin
bin --> config: 作为脚本参数，被解析后写入memory中
```

如上图所示，gem5源码编译之后，生成了特定平台的gem5模拟器，具体哪个平台，以及模拟器支持的调试等级可以在编译时指定。gem5接受一个python脚本，在python脚本中, 描述了我们要创建的特定的CPU系统是由哪些组件构成，即实例化了gem5模拟器中特定的类，并且规定了这些类的特定参数（比如内存的大小，读取延时等等）。同时也描述了这些组件是如何连接在一起。当这些都描述清楚之后，python脚本中应该主动调用模拟器的启动接口以启动模拟器。

显而易见，gem5依赖python库。gem5支持的python脚本版本为python2，不支持python3。

### 关于编译

gem5使用Scons来组织编译，Scons类似于make。
Scons需要使用名为SConstruct的文件来组织编译, Scons还提供了一系列的API，用于在SConstruct中方便的定制构建规则。
我们可以认为，Scons是make的升级版，它能更简单，更容易的实现make实现的功能，Scons使用Python脚本来组织构建,有良好的跨平台性。

## memory & port

所有内存对象都是通过port连接起来的，port实现了三种不同的内存模式

- atomic
- timing
- functional

timing模式是唯一一个能产生正确的仿真结果的模式; atomic模式是一个快速仿真模式; functional模式是一个debug模式，支持从host端读入内存数据

port包含master ports 和 slave ports两种，port传递的是packets,

## Python与C++的参数传递

gem5官网Documentation的作者认为，gem5的python接口的亮点在于能够向C++传递参数。（tvm也能够实现C++与Python的数据互传，这一点我觉得可以对比着分析两者的实现）

### 添加参数的方法

1. 在src的.py文件中添加python参数的定义，这个参数可以在config文件中赋值
2. 在src的.cc文件中，在类中添加参数字段
3. 在src的.cc文件中，在类的构造函数中添加参数字段的赋值，参数由python传入
4. 在config文件中添加必要的参数赋值

## 添加简单SimObject

1. 在src目录中添加demo.py, demo.cc, demo.hh
2. 在demo.py中添加Demo类
3. 在demo.hh中添加Demo类
4. 在demo.cc中添加Demo类构造函数，必要方法，构造函数需要有默认参数DemoParams
5. 在src目录下的Sconscript中添加文件编译和必要的debug flag
6. 在config文件中使用新添加的Demo实例

## 添加event

1. 添加EventFunctionWrapper类型的event字段到Demo类中
2. 添加processEvent 方法用来做event回调函数
3. 在构造函数中，初始化event为processEvent
4. 创建startup方法，在该方法中添加event的schedule，用于在启动时触发event
