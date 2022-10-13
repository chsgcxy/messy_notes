# ARM Training Day1

## Security

### Branch protection

#### 防止程序篡改分支目的地址
BTI 只有有BTI指令的分支才能跳转
页表中有标识需要配置

#### 防止程序篡改返回地址
PACIASP   X30的高位提供PAC code (一种加密码)
AUTIASP   判断X30高位有没有被篡改过
需要软件产生一个key

### memory tagging
发现代码本身的漏洞，减小能够被攻击的可能
通过tag是否匹配来判断是否合法,主要功能帮忙检测漏洞
memory overflow or doublefree

分配内存的时候就需要一个tag，真正的访问alloc一个逻辑tag，进行匹配
在哪里check取决于在哪里结束，可以在cache和总线

不能防止攻击，因为tag是透明的

LDG x1, [x0]


## DynamIQ Shared Unit (DSU)

结构组成：

- DynamIQ Cluster
- Debug Block

## SVE2

SVE2 是在neon上的扩展
软件在写的时候不需要SVE2的vlen_max

## MPAM(memory partitioning and monitoring)

L3 cache 可以分成多个partition
L3 miss 时，分配MPAM中配置的partition slice id

bandwidth partitioning

架构文档中说明了bandwidth partitioning
默认轮流使用，可以配置比例权重，如果实际中确实请求较多，那么会优先给比例高的core, 仲裁逻辑基于slice

## Realm

通过在SCR_EL3中添加了NSE bit, 配合NS bit来指示是哪个状态

## Power

Activity per clock

可以通过DVFS来调整

CPU 内部有 Activity Monitor, MPMM
有三个Gear能够控制Activity
DSU cluster level 支持MPMM

Cluster 如何调整Activity, 通过控制L3的bandwidth, 以slice为单位

PDP (performance Define power)

## Trace

ETE | ETM Trace

两种方式(不能同时)：
- 通过ATB总线发送出去
- TRBE可以将Trace导入DDR,受MMU管理

## Complex

Dual-Core Complex, share L2 Cache and VPU
Single-Core Complex, similar with signle core
hunter not support complex

## L3 Cache

32MB Max
1,2,4,8 slices

通过两个ring的topo, 距离每个node很近，提高bandwidth, 减少lat, 降低layout难度
slice越多，controler 越多，额外面积越多，功耗越大

one slice:

- Data RAM
- Tag RAM
- Snoop Filter
- LTDB (long time data buffer) L3 向外还没有result的transaction

可配置参数

- L3_CACHE_SIZE
- NUM_L3_SLICES

支持 CHI.E 不支持 CHI.F

可以通过寄存器配置AXI还是CHI

master port(DSU对外接口)的个数 1,2,3,4 要结合DDR的端口和核数

peripheral port, 支持256-bit | 64-bit
64-bits支持回环到ACP没有deadlock

MCN(memory controller node)

outstanding transaction:
- master port num
- LTDB size(16, 32, 48, 64)

NUM_LTDBS <= (128 * NUM_MASTER / NUM_L3_SLICES)

DSU total outstanding = L(LTDB) * S(slices)

## interrupt

GIC400 最多支持8core
GIC(generic interrupt controller)

## ACP

snoop

## atomic support

LDADD

## persistent

保证系统下电再上电之后能够看到希望保留的信息
DCCVAP 带persistent的刷cache
DCCVA

## PBHA

## system counter

进程转换(programmable incrementing Counter)

## hunter

提高性能的同时，兼顾能效比

first generation of Armv9.2

### PMU

包含了cycle counter 和 event counter, 支持快照，最多支持20个源
没办法精确到指令

### AMU

activity monitor

做maxpower控制用的
可以通过指令的方式去控制
支持7个event,其中三个可以定制

### SPE(statistical profiling extension)

更微观 micro-op, 监测执行状态， 生成64-bit采样，结果直接放到memory中

### 微架构

- 2-taken with cond branches(某些情况下只能做一条分支预测)
- 8 instruction fetch
- 32/64KB instruction cache
- 5-wide decode, dispatch
- 184 preg
- 192 insts windows
- 32/64KB data cache
- 2-load/store + 1-load per cycle
- by default dcache 32bank
- support data prefetcher
- 4-ALU
- 2-branch
- 2-vector execute pipelines
- register cache
- 9-cycle L2 cache(128/256/512KB), exclusive L1D, support ECC



