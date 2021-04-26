# RISCV虚拟内存管理

[TOC]

虚拟内存管理的主要单元是MMU,这里对RISCV官方spec中提到的S模式虚拟内存管理做一下总结。内容依据RISCV privileged ArchitectureV1.2

RISCV的S模式使用分页机制来管理内存，可以支持Sv32,Sv39等多种分页方式，这里以Sv32举例来进行分析

## 名词解释

**PPN**(Physical Page Number)
**VPN**(Virtual Page Number)
**ASID**(Address Space Identifier)

## 设计描述

### 实现原理

RISCV使用分页机制来进行内存管理，分页机制的核心在于树形的多级页表，页表也会占用内存空间，之所以能够用占用相对少量内存空间来表示
大的内存空间，是因为页表仅描述页的基地址，对于偏移部分是直接与虚拟地址对应的。

这里需要明确如下几点：

- RISCV使用satp寄存器来保存初级页表地址及相关信息
- 页表中保存的是页表项
- M模式时MMU不可用

在SV32分页机制中，一页大小为4KB

Sv32页表项(PTE)构成:

31-20 | 19-10 | 9-8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0
|--|--|--|--|--|--|--|--|--|--|--
PPN1| PPN0 | RSW | D | A | G | U | X | W | R | V

Sv32 支持4GB虚拟地址空间，分为两级。第一级叫做巨页， 4GB被划分为1024个4MB的巨页；第二级叫做基页，每个4MB的巨页被划分为1024个4KB的基页。一个页表项由4字节(32bit)构成，则一张页表刚好被一个基页所容纳。

因此，使用1025个基页完成了4GB虚拟地址到物理地址的映射

### 转换过程

这里以Sv32为例来说明地址转换过程

**satp**(Supervisor Address Translation and Protection)
寄存器控制了分页系统方案

satp寄存器字段如下:
31 | 30 - 22 | 21 - 0
--|--|--
MODE | ASID | PPN

对于RV32来讲，satp的MODE字段只占1bit, 即只有启用Sv32和关闭两个选择；而RV64除了Sv39还有Sv48。

ASID降低上下文切换的开销,但具体机制后续了解了再补充吧

PPN为一级页表所在的物理页号

当CPU发出一个如下的虚拟地址
31 - 22 | 21 - 12 | 11 - 0
--|--|--
VPN[1] | VPN[0] | offset

CPU首先查看satp寄存器，从中获取PNN，即一级页表物理地址。
虚拟地址中的VPN[1]指示了一级页表表项的编号，每一个表项占4个字节。则该虚拟地址对应的一级页表项地址为satp.PPN × 4096 + VPN[1] × 4

为了描述方便，将一级页表项中的PPN[1]与PPN[0]合称为PPN,那么该页表项中的PPN指示了二级页表的物理地址。虚拟地址中的VPN[0]指示了二级页表项的编号，没一个表项占4字节。则该虚拟地址对应的二级页表项地址为PTE. PPN × 4096 + VPN[0] × 4

二级页表项的 PPN 字段和虚拟地址中的offset组成了最
终的该虚拟地址对应的物理地址LeafPTE.PPN × 4096 + offset

## 构建过程

## 相关指令

### 关于satp

> Volume II: RISC-V Privileged Architectures V1.12-draft
Note that writing satp does not imply any ordering constraints between page-table updates and
subsequent address translations. If the new address space’s page tables have been modified, or if an
ASID is reused, it may be necessary to execute an SFENCE.VMA instruction (see Section 4.2.1)
after writing satp
Not imposing upon implementations to flush address-translation caches upon satp writes reduces
the cost of context switches, provided a sufficiently large ASID space.

通过描述来看，指令集架构没有约束写入satp后，芯片要进行tlb_flush操作，这里建议不强制加入
tlb_flush,以加速上下文切换，需要时应该使用sfence.vma来刷新tlb

### sfence.vma

虚拟地址屏障指令

## 扩展之行为级模拟器的实现

## 多处理器的地址缓存一致性

tlb shutdown

sfence.vma 仅影响执行当前指令的 hart 的地址转换硬件。当 hart 更改了另一个 hart 正在使
用的页表时,前一个 hart 必须用处理器间中断来通知后一个 hart,他应该执行 sfence.vma
指令。这个过程通常被称为 TLB 击落

IPI核间中断
