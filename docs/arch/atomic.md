# 原子操作

在宝华的《atomic实现原理》一文中提及了atomic(原子操作)的实现方式(其实他还是想说cache相关的东西), 但文中提到了几种通常的atomic实现方式

- 一种是bus lock，锁住总线，不让其他CPU进行内存操作，但这种方式破坏性比较大
- 一种是Cacheline Lock，借助多核cache一致性MESI协议

在看文章的时候，我想到了riscv的指令集扩展中，有atomic扩展，即原子操作指令扩展。那么就有了如下疑问

- RISCV指令集的A扩展是什么？目的是解决什么问题？目前处于什么开发状态？
- linux内核中对于RISCV的原子操作支持目前是什么样的？涉及到A扩展吗?

## RISCV的A扩展

> The standard atomic-instruction extension, named “A”, contains instructions that atomically read-modify-write memory to support synchronization between multiple RISC-V harts running in the same memory space.

很显然，RISCV的A扩展正是为了实现原子操作而设计的

> The two forms of atomic instruction provided are load-reserved/store-conditional instructions and atomic fetch-and-op memory instructions.

A扩展提供了两种形式的原子操作指令，一种load-reserved/store-conditional， 另一种fetch-and-op memory instructions

### load-reserved/store-conditional

提供了LR.W/D 和 SC.W/D两组指令

>如果aq位和rl位都被置为1,则原子性存储器操作是顺序一致性 的(sequentially consistent),在同样的RISC-V线程中,在任何前面的存储器操
作完成之前,或者在任何后续的存储器操作完成之后,它们都是不可见的(cannot be observed to happen before any earlier memory operations or after any later memory operations in the same RISC-V thread),只能被任何其他按照同样全局顺序的线程看到,它们也全部使用了顺
序一致性原子性存储器操作,对同一个地址域(can only be observed by any other thread in the same global order of all sequentially consistent atomic memory operations to the same address domain.)

