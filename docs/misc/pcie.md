# 基于linux 的 PCI & PCIe 总线分析总结

## 前言

讲解PCI & PCIe 的书有很多，我手上就拿了一本《PCI Express 体系结构导读》的书，据说这本书基本是翻译了外文，书上虽然内容比较全面，但是书那么厚，想达到快速掌握的目的还有一定难度；网上也有很多相关博客，但是普遍很浅，内容局限又支离破碎；这就是写这篇总结的目的，从我的理解出发，对PCI & PCIe 做一个总结。

内容聚焦于下面几个方面:

- 从软件开发者角度来总结 PCI 基础知识，理清楚各种概念
- 从软件开发者角度来总结 PCIe 的基础知识，在 PCI 的基础上，并且能够与 PCI 进行对比
- 基于linux，梳理内核 PCIe 驱动框架，初始化流程
- 如何基于linux内核设备驱动框架写一个自己的PCIe驱动

## 从软件开发者角度认识 PCI 总线

### PCI总线信号定义

![在这里插入图片描述](https://img-blog.csdnimg.cn/20190202190547717.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3p1b3dhbmJpc2hl,size_16,color_FFFFFF,t_70)

### PCI总线拓扑图

![在这里插入图片描述](https://img-blog.csdnimg.cn/20190202190615989.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3p1b3dhbmJpc2hl,size_16,color_FFFFFF,t_70)

PCI是并行总线，是总线型拓扑结构，图中给出了一个比较复杂的PCI总线拓扑，借此来说明PCI总线的组成，初始化等部分

### CPU域 & DRAM域 & 存储器域 & PCI总线域

> 在描述PCI总线拓扑之前要先讲清楚图中的这几个域，其中有两个域是一定要区分清楚的，那就是存储器域与PCI总线域。域应该怎么理解呢？我理解为地址空间，PCI总线有其独立的地址空间，SOC也有其独立的地址空间，这两个地址空间不能搞混。

- CPU域
- DRAM域
- PCI总线域 - PCI设备能够直接使用的地址是PCI总线域的地址，在PCI总线事务中出现的地址也是PCI总线域的地址
- 存储器域 - 处理器能够直接使用的地址是存储器域的地址

CPU所能访问的PCI总线地址一定在存储器域中有地址映射；
PCI设备能够访问的存储器域的地址也一定在PCI总线域中具有地址映射。

### PCI总线拓扑组成

PCI总线拓扑主要由三部分构成：

- HOST主桥
- PCI总线
- PCI设备

#### HOST主桥

HOST主桥用来隔离处理器系统的存储器域与处理器系统的PCI总线域，管理PCI总线域，完成处理器与PCI设备间的数据交换。这也是我们为什么一上来就说要区分存储器域与PCI总线域了，因为HOST主桥的作用之一就是隔离这两个域。图中的拓扑带有两个HOST主桥，HOST主桥X与HOST主桥Y.

#### PCI总线

PCI总线由HOST主桥或者PCI桥管理，用来连接各类设备。图中给出了PCI总线0，1，2，3，4. HOST主桥出的总线编号号PCI总线0，在一棵PCI总线树中有多少个PCI桥（包含HOST主桥）,就有多少条PCI总线。

#### PCI设备

在PCI总线中有三类设备：PCI主设备、PCI从设备、PCI桥设备。

- PCI主设备 - 可以通过总线仲裁获得PCI总线使用权，主动向其他PCI设备或者主存储器发起读写请求；
- PCI从设备 - 只能被动的接收来自HOST主桥或者其他PCI设备的读写请求；
- PCI桥设备 - 主要是管理下游的PCI设备，并转发上下游之间的总线事务。PCI桥可以扩展PCI总线，但是不能扩展PCI总线域，比如当前系统使用的是32bit的PCI总线地址，那么这个系统的PCI总线域的地址空间就是4G,与桥的个数无关。

> 一个PCI设备既可以是主设备也可以是从设备，但同一时刻只能有一种角色。

### PCI设备的配置空间

> 上述的描述讲了PCI总线的拓扑，拓扑中每一个部分的功能。那么接下来就会有疑问：我们（CPU）是如何访问PCI设备的？
知道了PCI设备与CPU如何交互，我们才能去写驱动代码，所以这个问题要搞清楚。

CPU访问PCI设备的**配置空间**使用的是***ID寻址***方式；CPU访问PCI设备的**存储器**和**IO地址空间**采用的是***地址寻址***方式

一下子出现了这么多名词，配置空间、ID寻址、存储器地址空间、IO地址空间，一个个讲清楚就知道PCI到底是如何访问的了。

#### 猜测的为什么要有配置空间

CPU访问PCI设备是通过地址映射进行的，PCI设备内部的地址空间（PCI总线域的一部分）会通过一定方式映射到SOC能够访问到的一段地址空间中（存储器域的一部分），借助DMA来实现通信。这个地址映射关系总要有个地方记录吧；还有插入一个PCI设备，总要知道它的一些基本信息吧，比如厂家信息，版本信息......；插入的PCI设备是哪一种得有能区分的点吧。一旦遇到这种问题，大多数解决方案都是规定一个统一的格式，大家都按照这个格式来填写，而且要提供一种通用的方式能够获取到这个格式的数据，这种通用性必须能够屏蔽PCI设备间的差异。于是乎就有了配置空间这么个玩意。

#### PCI配置空间的分类

PCI设备都有独立的配置空间，分为三种类型：

- PCI Agent 使用的配置空间
- PCI桥使用的配置空间
- Cardbus桥片使用的配置空间

PCI Agent配置空间和PCI桥配置空间需要重点了解，Cardbus这个我也不知道是什么鬼。

#### PCI Agent 配置空间

![在这里插入图片描述](https://img-blog.csdnimg.cn/20190202190651186.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3p1b3dhbmJpc2hl,size_16,color_FFFFFF,t_70)

- Device ID 和 Verdor ID. 厂商分配的，只读。
- Revision ID. 记录了PCI设备的版本号，只读
- Class Code. 记录了PCI设备的分类，只读。分为base class code（把设备分为显卡、网卡、PCI桥等设备）、sub class code（进行细分）、interface（定义编程接口） 三个字段。这个寄存器可供系统软件识别当前PCI设备的分类。
- Header Type. 表示当前配置空间类型，只读。
- Cache Line Size. HOST处理器使用的Cache行长度，由系统软件设置。（对PCIe无意义）
- Subsystem ID 和 subSystem Vendor ID. 当使用Device ID 和 Vendor ID 无法区分的情况
- Expansion ROM base address. 记录了ROM程序的基地址。有些PCI设备在处理器还没有运行操作系统之前，就需要完成基本的初始化设置，PCI设备提供了一段ROM程序，处理器在初始化过程中将运行这段ROM程序，初始化这些PCI设备。
- Capabilities Pointer. 在PCI设备中，寄存器是可选的，在PCI-X和PCIe设备中必须支持。
- Interrupt Line. 系统软件对PCI设备进行配置的时候写入的，记录当前PCI设备使用的中断向量号，如果不适用8259A中断控制器，这个寄存器没有意义
- Interrupt Pin. 
- Base Address Register 0 ~ 5. 保存PCI设备使用的地址空间的基地址，保存的是该设备在PCI总线域中的地址。

> 绝大多数PCI设备将PCI配置信息存放在E2PROM中，PCI设备进行上电初始化，将E2PROM中的信息读到PCI设备的配置空间中作为初始值，这个操作由硬件完成。

#### PCI桥配置空间

![在这里插入图片描述](https://img-blog.csdnimg.cn/20190202190725373.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3p1b3dhbmJpc2hl,size_16,color_FFFFFF,t_70)

> PCI桥的配置空间在系统软件遍历PCI总线树时进行配置，系统软件不需要专门的驱动程序设置PCI桥的使用方法，PCI桥一般来讲是透明的。

PCI桥有两组BAR寄存器，如果PCI桥本身不存在私有寄存器，那么BAR寄存器可以不使用(透明桥)，初始化为0.

PCI Bridge 的配置空间相比较 PCI Agent 的配置空间，多了 Bus Number 寄存器

- Subordinate Bus Number 寄存器存放当前PCI子树中编号最大的PCI总线号
- Secondary Bus Number 存放当前PCI桥Secondary Bus使用的总线号，也是该子树中编号最小的总线号
- Primary Bus Number 存放该PCI桥上游的PCI总线号

### PCI总线树Bus号的初始化

> PCI桥的配置空间中有三个 Bus Number 寄存器，这三个寄存器是需要软件在初始化PCI总线的时候填写的，也就是PCI总线树Bus号的初始化。

系统软件在遍历当前PCI总线树时，需要首先对这些PCI总线进行编号，即初始化PCI桥的Primary、Secondary、Subordinate Bus Number 寄存器。编号时使用深度优先算法。再次强调，在一棵PCI总线树中有多少个PCI桥（包含HOST主桥）,就有多少条PCI总线。

```text
在PCI总线拓扑图中，HOST主桥X直接出的PCI总线就是PCI Bus 0

HOST主桥扫描（这个扫描具体是怎样一种动作？）PCI总线0上的设备，系统软件首先忽略这条总线上的所有PCI Agent,
HOST主桥就发现了PCI桥，命名为X1, 把这个桥出的总线定为PCI Bus 1, 将PCI桥X1的Primary Bus Number 赋为0，
因为这个桥是接在PCI总线0上的，把Secondary Bus Number 寄存器赋值为1，因为它引出的PCI总线为Bus 1;

继续扫描PCI Bus 1，又发现了一个桥，命名为PCI桥X2, 把这个桥出的总线定为PCI Bus 2, 将PCI桥X2的Primary Bus Number为1，Secondary Bus Number为2；

继续扫描PCI Bus 2，发现了新桥，命名为PCI桥X3，将这个桥出的总线定为PCI Bus 3, 将PCI桥X3的Primary Bus Number设置为2，Secondary Bus Number设置为3；

继续扫描PCI Bus 3，没有发现PCI桥，也就是说PCI总线3下面不会有新的总线了，就把PCI桥X3的Subordinate Bus Number 赋值为3，并且回退到PCI Bus 2;

继续扫描PCI Bus 2，没有发现除PCI桥X3之外的桥，把PCI桥X2的Subordinate Bus Number 也赋值为3，并回退到PCI Bus 1;

继续扫描PCI Bus 1, 没有发现除PCI桥X2之外的桥，把PCI桥X1的Subordinate Bus Number 也赋值为3，并回退到PCI Bus 0;

继续扫描PCI Bus 0, 发现了新桥，命名为PCI桥X4，将PCI桥X4的出的总线定为PCI Bus 4, 将PCI桥X4的Primary Bus Number设置为0，Secondary Bus Number设置为4；

继续扫描PCI Bus 4，没有发现新桥，把PCI桥X4的Subordinate Bus Number 赋值为4， 并回退到PCI Bus 0;

继续扫描PCI Bus 0, 没有发现新桥，结束遍历，完成Bus号分配。
```

### PCI设备配置空间的访问机制

#### ID寻址

HOST主桥通过配置读写总线事务（这是总线事务的一种，什么是总线事务？这......）访问配置空间。

配置读写总线事务通过ID号进行寻址。ID号由总线号、设备号、功能号组成。

- 总线号：在一棵PCI总线树中，有几个PCI桥就有几条PCI总线（包含HOST主桥）；总线号由系统软件决定。系统软件使用DFS(深度优先)算法扫描PCI总线树上的所有PCI总线，并进行编号。
- 设备号：由PCI设备的IDSEL信号与PCI总线地址线的连接关系确定。
- 功能号：与PCI设备的具体设计相关，一个PCI设备中最多有8个功能号，每个功能设备有自己的配置空间

HOST主桥使用寄存器号来访问PCI设备配置空间的某个寄存器。

#### 配置请求

PCI总线有两类配置请求：

- Type 00h 配置请求. 访问与HOST主桥或者PCI桥直接相连的PCI Agent或者PCI桥
- Type 01h 配置请求. 访问没有直接相连的PCI Agent 或者PCI桥

以x86处理器来讲，PCI控制器提供了CONFIG_ADDRESS寄存器和CONFIG_DATA寄存器，就是通过这两个寄存器来控制配置读写总线事务

CONFIG_ADDRESS寄存器与Type 01h配置请求的对应关系

![在这里插入图片描述](https://img-blog.csdnimg.cn/20190202190828687.png)

CONFIG_ADDRESS寄存器与Type 00h配置请求的对应关系

![在这里插入图片描述](https://img-blog.csdnimg.cn/20190202190840404.png)

> 在PCI总线中，只有PCI桥能够接收Type 01h 配置请求，Type 01h 配置请求不能直接发向最终的PCI Agent设备，而只能由PCI桥将其转换为Type 01h 请求继续发向其他PCI桥或者转换为Type 00h 配置请求发向PCI Agent 设备

在PCI总线拓扑中，加入要访问PCI设备01

```text
HOST处理器访问PCI01的配置空间，发现PCI设备01与HOST主桥直接相连，
所以将直接使用Type 00h 配置请求访问该设备的配置空间

将CONFIG_ADDRESS 寄存器的Enabled位置1，
Bus Number号置为0，并对该寄存器的Device, Function, Register Number字段赋值

当HOST处理器对CONFIG_DATA寄存器访问时，
HOST主桥将存放在CONFIG_ADDRESS寄存器中的数值转换为Type 00h配置请求，
并发送到PCI总线0

PCI01设备接收到这个Type 00h配置请求，进行交互。
```

在PCI总线拓扑中，假如要访问PCI设备31

```text
HOST处理器访问PCI设备31的配置空间，需要通过HOST主桥、PCI桥X1、X2和X3，最到达PCI31。

首先将CONFIG_ADDRESS的 Bus Number 置为3；

然后当HOST处理器对CONFIG_DATA寄存器进行读写访问时，HOST主桥将Type 01h 的配置请求发送到PCI总线0；

PCI Bus 0上的PCI桥X1接收配置请求。
PCI桥X1的Secondary Bus Number为1，Subordinate Bus Number为3， 1 < Bus Number <=3,
所以PCI桥X1接收来自PCI总线0的Type 01h配置请求，并将这个配置请求发送到PCI Bus 1；

PCI Bus 1上的PCI桥X2接收配置请求。
PCI桥X2的Secondary Bus Number为2，Subordinate Bus Number为3， 2 < Bus Number <= 3,
所以PCI桥X2接收来自PCI总线1的Type 01h配置请求, 并将这个配置请求发送到PCI Bus 2；

PCI Bus 2上的PCI桥X3接收配置请求。
PCI桥X3的Secondary Bus Number为3，Subordinate Bus Number为3，则要访问的设备就在这个桥下，
PCI桥X3将Type 01h的总线事务转换成Type 00h的总线事务，发送到PCI总线3， PCI31 接收到了请求，进行交互。
```

#### Device号的分配

PCI设备的IDSEL信号与PCI总线的AD[31:0]信号的连接关系决定了该设备在这条PCI总线的设备号。
每一个PCI设备都使用独立的IDSEL信号，其中CONFIG_ADDRESS寄存器中的Device Number 字段共有5位，可以表示32个设备，而AD[31:11]只有21位，这意味着一条PCI总线上最多能接21个设备。

### PCI 总线数据交换

存储器域与PCI总线域的映射

![在这里插入图片描述](https://img-blog.csdnimg.cn/20190202190852745.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3p1b3dhbmJpc2hl,size_16,color_FFFFFF,t_70)

PCI Agent 设备之间以及HOST 处理器和PCI Agent设备之间可以使用存储器读写和IO读写等总线事务进行数据传送送。大多数情况下， PCI桥不之间与PCI设备或者HOST主桥进行数据交换，仅仅是转发来自PCI Agent 或者 HOST 主桥的数据。

在PCI Agent 设备进行数据传送之前，系统软件需要初始化PCI Agent 设备的 BAR0 ~ BAR5寄存器，以及PCI桥的Base, Limit寄存器，系统软件使用DFS算法对PCI总线进行遍历时，完成这些寄存器的初始化，分配这些设备在PCI总线域的地址空间，然后PCI设备就可以使用PCI总线地址进行数据传输了。

PCI Agent 的BAR0 ~ 5, 以及 PCI bridge 的 Base 寄存器都是存的PCI总线地址，这些地址在处理器的存储器域有对应的映像，如果一个PCI设备的BAR空间在处理器的存储器域没有映像，处理器将不能访问PCI设备的BAR空间。

#### 处理器访问PCI设备地址空间

HOST主桥隔离了PCI总线域与存储器域。在PCI总线初始化时，会在CPU存储器域中建立PCI设备的存储器地址空间的映射，当处理器访问设备的地址空间时，首先访问该设备在存储器域中的地址空间，并且通过HOST主桥的地址空间转换为PCI总线域的地址空间，再使用PCI总线事务将数据发送到指定的PCI设备中

#### PCI设备访问存储器域的地址空间

PCI设备访问存储器域的地址空间时通过DMA完成的。处理器需要将存储器域的地址空间反向映射到PCI总线地址空间。首先访问该储存器地址空间对应的PCI总线地址空间，通过HOST主桥将这个地址空间转换为存储器地址空间，再由DDR控制器对存储器进行读写访问。

> X86处理器的HOST主桥中，存储器域的存储器地址与PCI总线域的地址相等。

### PCI设备BAR寄存器和PCI桥 Base、Limit寄存器的初始化

#### 存储器空间与IO空间

PCI桥配置空间的图中，有一些Limit 和 Base 的寄存器，这些寄存器的作用就是记录该PCI桥所管理的PCI子树的存储器地址空间或者I/O地址空间的基地址和长度。

- I/O Limit
- I/O Base
- Memory Limit
- Memory Base

现在假设如下：

- CPU的存储器域的 0xF000-0000 ~ 0xF800-0000 与 PCI总线域的0x7000-0000 ~ 0x7800-0000 是映射关系 **实际情况呢？ PCI总线域的这个起始地址是如何确定的？**
- PCI Agent 设备只使用BAR0 寄存器 **实际情况呢？一般都用几个？**
- PCI Agent 的存储器空间大小为16MB(0x100-0000)  **实际情况呢？这个空间大小是如何确定的呢？**

BAR寄存器初始化和PCI总线的Bus号分配是在同一个动作中完成的

```text
软件遍历到PCI桥X3后，没有再探测到PCI Bus 3下面有PCI桥，这时候就为PCI Bus 3 下面的PCI Agent的BAR寄存器赋值（当然就是从0x7000-0000 ~ 0x7800-0000中分配）
PCI-Agent31.BAR0 = 0x7000-0000; PCI-Agent32.BAR0 = 0x7100-0000;
为PCI桥X3的Base, Limit 寄存器赋值 PCI-BridgeX3.Memory-Base = 0x7000-0000; PCI-BridgeX3.Memory-Limit = 0x200-0000;

回退到PCI Bus 2, 发现PCI设备21， PCI-Agent21.BAR0 = 0x7200-0000;
为PCI桥X2的Base, Limit 寄存器赋值 PCI-BridgeX2.Memory-Base = 0x7000-0000; PCI-BridgeX3.Memory-Limit = 0x300-0000;

回退到PCI Bus 1, 发现PCI设备11， PCI-Agent11.BAR0 = 0x7300-0000;
为PCI桥X1的Base, Limit 寄存器赋值 PCI-BridgeX1.Memory-Base = 0x7000-0000; PCI-BridgeX3.Memory-Limit = 0x400-0000;

回退到PCI Bus 0, 发现PCI桥X4, 进入PCI Bus 4, 没有再探测到PCI Bus 4 下面有PCI桥，这时候就为PCI Bus 4 下面的PCI Agent的BAR寄存器赋值
PCI-Agent41.BAR0 = 0x7400-0000; PCI-Agent42.BAR0 = 0x7500-0000;
为PCI桥X4的Base, Limit 寄存器赋值 PCI-BridgeX4.Memory-Base = 0x7400-0000; PCI-BridgeX4.Memory-Limit = 0x200-0000;

回退到PCI Bus 0, 没有再探测到PCI Bus 0下面有PCI桥， 这时候就为PCI Bus 4 下面的PCI Agent的BAR寄存器赋值
PCI-Agent01.BAR0 = 0x7600-0000;

遍历结束
```

#### 地址译码

当一个存储器读写总线事务到达PCI总线时，在这条总线上所以的设备将进行地址译码，如果当前总线事务使用的地址在某个PCI设备的BAR空间中，该PCI设备将使能DVESEL#信号，认领总线事务。

Posted 传送方式与Non-Posted 传送方式

- Posted传送方式，数据通过PCI桥后将结束上一级总线的PCI事务，从而上一级PCI总线可以被其他PCI设备使用。
- Non-Posted 传送方式，当数据达到目标设备后，目标设备需要向主设备发出回应，当主设备收到这个回应后才能结束整个总线事务。
- 处理器向PCI设备进行读操作使用的是Non-Posted方式，写操作使用的是Posted方式
- PCI设备的DMA写使用Posted方式，DMA读使用Non-Posted方式

#### PCI设备读写主存储器

PCI设备与存储器直接进行数据交换的过程是通过DMA实现的。支持DMA传递的PCI设备可以在BAR空间中设置两个寄存器，分别保存目标地址和传送大小。
PCI设备进行DMA操作时，使用的目的地址是PCI总线域的物理地址，而不是存储器域的

#### 中断机制

PCI提供了INTA#,INTB#,INTC#,INTD#信号向处理器发出中断请求，同时也提供了MSI机制向处理器提交中断请求

#### MSI中断机制

MSI中断机制采用存储器写总线事务向处理器系统提交中断请求，其实现机制是向HOST处理器指定的一个存储器地址写指定的数据。这个存储器地址一般是中断控制器规定的某段存储器地址范围，而且数据也是事先安排好的数据，通常含有中断向量号。
MSI在PCIe上已经成为了主流，PCIe设备必须支持MSI中断机制，PCI设备不一定都支持，而且在PCI设备上不常用。

## 从软件角度认识PCIe总线

PCI总线是并行总线，同一条总线上，所有外部设备共享总线带宽，PCIe总线使用高速差分总线，并采用端到端的连接方式，在一条PCIe链路的两端只能各连接一个设备，这两个设备互为数据发送端和数据接收端。PCIe总线在设计过程中使用了一些网络通信的技术。（现在感觉高速数据有很多类似的地方，基本都涉及serdies）
