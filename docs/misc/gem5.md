# GEM5 设计与实现分析

[TOC]

## 前言

gem5是一款可以实现时钟精确仿真的SOC模拟器。它本身的目的并不是帮助产品开发，它更偏向于教育和架构探索。
但是研究它仍然是有意义的，它的意义在于能够让你学习到一款时钟级模拟器的构建思路。

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

> gem5是一个模块化的计算机系统（computer-system）模拟器,最初用于计算机架构以及微处理器架构探索，当然在研究行业，教学行业也有推广。
但总体来讲，gem5是偏向于学术的一款模块化模拟器平台。
gem5目前还在发展，支持的CPU类型有：Alpha, ARM, MIPS, Power, SPARC, RISC-V 以及 64 bit x86。

如上是对于gem5官网描述的概括，其中最关键的应该就是模块化。gem5可以做到时钟精确，当然也可以利用它的模块化，忽略掉一些模块的latency。本文主要侧重的是RISC-V架构。对于RISC-V, 目前gem5主线还不支持vector扩展，但amf扩展都已经支持。

gem5能够模拟出一块具体的板卡，包含由各个模块组成的SOC、DDR以及部分外设的具体板卡，但它模拟的核心仍在于SOC内部。

## 理解gem5的模块化

linux系统提供了设备树，让开发者通过组合系统硬件的一系列模块，从而匹配自己的板卡。gem5也是一样的，它有很多模块都有多种实现，你可以指定具体的某一种实现来组合出你想模拟的系统。

gem5的核心内容（各个模块和机制的具体实现）使用c++编写，内部集成了python2.7解析器。这些模块实现完成之后就像linux内核中实现的一个个device，比如：cpu,cache,memory,power,process,tlb等等。python解析器会解析外部输入的配置文件（python脚本)，这个脚本就像设备树一样，描述了整个系统是如何由这些device组合起来的，并且定义了这些device的一些必不可少的参数。在系统初始化的时候，根据配置文件的描述，对相应的c++类进行实例化，这样就实现了一个具体的系统。

有些模块是通过静态编译绑定系统的，有些模块是通过解析配置脚本动态绑定的。比如ARCH相关的就是通过静态编译绑定的，在编译的时候我们需要指定要编译的ARCH，而cpu类型我们可以在
配置脚本中指定。

当然了，就像乐高玩具一样，空有一堆零件，没有图纸，也很难做出来像样的玩具（天才可能除外）。如果让我们从0开始组合这些模块，是很困难的一件事情，但好在gem5提供了一些demo的config文件，并且tests中也提供了一些config文件，我们可以模改这些文件实现自己的系统。

社区正在开发基于图形拖拽就能生成config文件的功能，这会使它的config文件写起来更直观。

## 理解gem5事件机制

gem5官网文档中已经包含了如何添加一个具体事件的详细说明。对此不再赘述，我们从设计者的角度来理解一下。

所谓的事件机制，实际上就是我们能够在事件应该被执行的时候执行该事件，并且能够动态的添加一些事件。
而且事件应该还有一个优先级的逻辑。

分析代码，首先需要一部分代码来处理事件

```c++
doSimLoop(EventQueue *eventq)
{
    while (1) {
        if (async_event && testAndClearAsyncEvent()) {
            if (async_exit) {
                async_exit = false;
                exitSimLoop("user interrupt received");
            }
        }

        Event *exit_event = eventq->serviceOne();
        if (exit_event != NULL) {
            return exit_event;
        }
    }
}
```

```c++
class EventQueue
{
  private:
    std::string objName;
    Event *head;
    Tick _curTick;

    void insert(Event *event);
    void remove(Event *event);
    void schedule(Event *event, Tick when, bool global = false);
    void deschedule(Event *event);
    void reschedule(Event *event, Tick when, bool always = false);

    Tick nextTick() const { return head->when(); }
    void setCurTick(Tick newVal) { _curTick = newVal; }
    Tick getCurTick() const { return _curTick; }
    Event *getHead() const { return head; }

    Event *serviceOne();
}
```

初始化完成，一切就绪就绪之后，就会进入doSimLoop的while循环，然后会一直从一个event队列中挑选一个event来执行


```c++
Event *
EventQueue::serviceOne()
{
    Event *event = head;

    setCurTick(event->when());
    event->process();
    event->release();

    return NULL;
}
```


gem5能够模拟一块板卡

![一个较为复杂的开发板系统框图](../imgs/developboard.png)
上图是一个较为复杂的开发板系统框图，从图中可以看到，soc通过它的外部接口连接了板上的各个外设。比如通过DDR4接口连接外部DDR,通过PCIE接口连接外部PCIE设备，通过USB接口链接4G模块等等。

gem5能够模拟出类似上图的一块板卡，包括SOC以及部分外设。但是，有两点需要注意

- gem5的核心任务还是模拟SOC内部行为，目前实现的外设比较少
- gem5的外设功能是在控制器侧做的。

假如我们要做一个模拟器，要实现SOC访问外部TMP75温度传感器的模拟。假如我们的重点是在SOC内部，那我们可能会想着去实现这个TMP75传感器，并且实现这个总线连接。

但这样存在的问题是，会让实现很复杂，同时会让工作的重心从CPU转到了外设上，已经脱离了作为一款CPU模拟器最核心的东西。这很没有性价比。gem5的实现是在控制器上做文章，比如同样要实现通过I2C访问TMP75传感器，它会直接在I2C控制器上实现TMP75传感器的功能，并且只需要设置好数据返回的latency，就完全可以实现这个过程的模拟，并且保证一定的时钟精确。（当然这个例子在gem5中没有实现）

gem5的内存系统支持DDR，同样的，gem5在DDR控制器上做文章，只需要设置DDR控制器的一些Latency参数，就可以在DDR访问的性能方面做到类似真实的DDR，而不需要真实的去模拟出来一个DDR芯片并且再设计DDR总线连接SOC和DDR芯片。

参考gem5官网的文档，大致有下面几个核心机制需要理解

- gem5是基于事件驱动模型而设计的，那么事件驱动模型是如何实现与运行的？
- 大多数模块的基类都是SimObject，gem5是如何管理这些SimObject的，这些SimObject又是如何组成系统的？
- gem5的isa实现可以理解为自创了一套语法，并且实现了isa_parser的解析器。解析器解析固定语法的ias描述文件，生成isa实现的c++代码，并参与编译。
- gem5如何实现内存系统

上述这些，都可以在gem5官网中找到蛛丝马迹。
但换一个角度，从更高的层面来看gem5。gem5是如何抽象板卡（board）, soc, cpu子系统的？
似乎这个问题在官网中并无法直接找到答案，然而这恰恰是我认为理解gem5最重要的部分。
对于上面提到的几点，我们稍后再分析。首先我们**站在gem5设计者的角度，分别从board,soc,cpu微架构三个层面来理解它的设计**

### 从board层面理解gem5



### 从soc层面理解gem5

![FE310_G000](../imgs/SOC_FE310_G0000.png)
上图是SiFive的RISCV架构FE310_G000 SOC，可以看到它有一个E31核，虚线框是核内微架构，它是一个比较简单的MCU核。
E31核通过P-Bus总线连接一些外设控制器。理论上，使用gem5可以实现一个与上图几乎一样的SOC模型。

不关注CPU内部微架构，从大的模块上来讲，我们需要实现CPU核，总线，外设控制器。并且让他们能够连接起来组成一个SOC。那么gem5是如何实现这些的呢？

![simple_system](../imgs/simple_system.svg)
上图是通过graphviz依据config.ini文件生成的一个简单系统框图，它足以说明gem5的设计思路。
system抽象了整个SOC系统，system中包含一系列的基于SimObject的模块，当然root和system本身也是一个SimObject。DerivO3CPU, membus, memctrl这三大模块都是SimObject。涉及到数据传输的模块都有port，分为master和slave两种类型，master和slave可以进行连接。从而使得模块相连。

要想将这种连接方式做的通用，就需要把port设计的通用

```c++



```



### 从cpu微架构层面理解gem5

### 事件驱动模型

### simobject

### isa定制语法

### 内存系统


### memory & port

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

## 关于编译

gem5使用Scons来组织编译，Scons类似于make。
Scons需要使用名为SConstruct的文件来组织编译, Scons还提供了一系列的API，用于在SConstruct中方便的定制构建规则。
我们可以认为，Scons是make的升级版，它能更简单，更容易的实现make实现的功能，Scons使用Python脚本来组织构建,有良好的跨平台性。
