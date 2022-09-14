# O3CPU 代码分析
 
## 运行说明
 
### build Gem5
 
can use a **-j** param to enable compile in parallel

```shell
scons build/ARM/gem5.debug -j4
```

## run Gem5

```shell
chlxy@LAPTOP-SMLPH2RJ:~/workspace/gem5$ ./build/ARM/gem5.debug --debug-flags=Exec configs/example/fs.py --cpu-type=ArmO3CPU --caches --machine-type=VExpress_GEM5_V2 -n1 --bare-metal --kernel ../tests/aarch64/dhrystone/dhrystone.elf
```

## stop Gem5

dhrystone will write a **EOT** to inform system to stop at the end of the test

```c++ 
#define TUBE_ADDRESS ((volatile uint32_t *) 0x13000000u)

static void benchmark_finish()
{​​
  char  p[] = "** TEST PASSED OK **\n";
  char* c   = p;
  while (*c)
  {​​​​​​​​​
    *TUBE_ADDRESS = *c;
    c++;
  }​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​
  *TUBE_ADDRESS = 0x4;
}
```

so, we set **UART0.pio=0x13000000**, and enable EOT

```python
Pl011(pio_addr=0x13000000,
      interrupt=ArmSPI(num=37), end_on_eot=True)
```

we use **VExpress_GEM5_V2** platform for our soc structure, you can find memorymap and other information in file src/dev/arm/RealView.py
 
## fetch
 
![fetch struct](../imgs/gem5_o3cpu/struct_fetch.png)

### fetch a cache line and not hit

没有开启mmu，因此当拍就能得到物理地址，然后查cache是否命中
```
1000: system.cpu.fetch: [tid:0] Attempting to translate and read instruction, starting at PC (0=>0x4).(0=>1).
1000: system.cpu.fetch: [tid:0] Fetching cache line 0 for addr 0
```

cache未命中，向下一级缓存取指令，在43000个tick，cache miss的数据回填，再过3个cycle,数据被直接放在fetchbuffer中。
```
43000: system.cpu.icache: recvTimingResp: Handling response ReadResp [0:f] (s) IF UC
44500: system.cpu.icache_port: Fetch unit received timing
```

### macroOp

macroOp fetch过程有如下特点：

- 不支持跨cacheLine
- 不支持fetchbuffer拼接
- 当拍处理完fetchbuffer，可以直接发起新的cache请求
- 存在一个microOp的缓存

![fetch macroOp](../imgs/gem5_o3cpu/fetch_macroOp.png)

从指令流log中可以看到macro指令 stp被拆分成了三条micro指令
```
2457000: system.cpu: A0 T0 : 0x6220 @_malloc_r+640    :   adrp   x1, #73728        : IntAlu :  D=0x0000000000018000  FetchSeq=1364  CPSeq=902  flags=(IsInteger)
2457000: system.cpu: A0 T0 : 0x6224 @_malloc_r+644    : stp                       
2457000: system.cpu: A0 T0 : 0x6224 @_malloc_r+644. 0 :   addxi_uop   ureg0, sp, #80 : IntAlu :  D=0x0000000000014f30  FetchSeq=1365  CPSeq=903  flags=(IsInteger|IsMicroop|IsDelayedCommit|IsFirstMicroop)
2457000: system.cpu: A0 T0 : 0x6224 @_malloc_r+644. 1 :   strxi_uop   x27, [ureg0] : MemWrite :  D=0x0000000000000000 A=0x14f30  FetchSeq=1366  CPSeq=904  flags=(IsInteger|IsStore|IsMicroop|IsDelayedCommit)
2457500: system.cpu: A0 T0 : 0x6224 @_malloc_r+644. 2 :   strxi_uop   x28, [ureg0, #8] : MemWrite :  D=0x0000000000000000 A=0x14f38  FetchSeq=1367  CPSeq=905  flags=(IsInteger|IsStore|IsMicroop|IsLastMicroop)
2457500: system.cpu: A0 T0 : 0x6228 @_malloc_r+648    :   adrp   x27, #61440       : IntAlu :  D=0x0000000000015000  FetchSeq=1368  CPSeq=906  flags=(IsInteger)
2457500: system.cpu: A0 T0 : 0x622c @_malloc_r+652    :   ldr   x1, [x1, #2432]    : MemRead :  D=0x0000000000000000 A=0x18980  FetchSeq=1369  CPSeq=907  flags=(IsInteger|IsLoad)
2458000: system.cpu: A0 T0 : 0x6230 @_malloc_r+656    :   movz   x3, #4127, #0     : IntAlu :  D=0x000000000000101f  FetchSeq=1370  CPSeq=908  flags=(IsInteger)
2458000: system.cpu: A0 T0 : 0x6234 @_malloc_r+660    :   ldr   x2, [x27, #3936]   : MemRead :  D=0xffffffffffffffff A=0x15f60  FetchSeq=1371  CPSeq=909  flags=(IsInteger|IsLoad)
```

执行log中,可以看到在2457000个tick时，fetch一共处理了三条指令，adrp和stp的前两条micro指令
```
2457000: system.cpu.fetch: [tid:0] Instruction PC (0x6220=>0x6224).(0=>1) created [sn:1364].
2457000: system.cpu.fetch: [tid:0] Instruction is:   adrp   x1, #73728

2457000: system.cpu.decoder: Decode: Decoded stp instruction: 0x4a90573fb
2457000: system.cpu.fetch: [tid:0] Instruction PC (0x6224=>0x6228).(0=>1) created [sn:1365].
2457000: system.cpu.fetch: [tid:0] Instruction is:   addxi_uop   ureg0, sp, #80

2457000: system.cpu.fetch: [tid:0] Instruction PC (0x6224=>0x6228).(1=>2) created [sn:1366].
2457000: system.cpu.fetch: [tid:0] Instruction is:   strxi_uop   x27, [ureg0]

2457000: system.cpu.fetch: [tid:0] Done fetching, reached fetch bandwidth for this cycle.

2457000: system.cpu.fetch: [tid:0] [sn:1364] Sending instruction to decode from fetch queue. Fetch queue size: 3.
2457000: system.cpu.fetch: [tid:0] [sn:1365] Sending instruction to decode from fetch queue. Fetch queue size: 2.
2457000: system.cpu.fetch: [tid:0] [sn:1366] Sending instruction to decode from fetch queue. Fetch queue size: 1.
```

在下一个cycle,除了stp剩余的一条指令，还可以处理额外的两条指令
```
2457500: system.cpu.fetch: [tid:0] Instruction PC (0x6224=>0x6228).(2=>3) created [sn:1367].
2457500: system.cpu.fetch: [tid:0] Instruction is:   strxi_uop   x28, [ureg0, #8]

2457500: system.cpu.fetch: [tid:0] Instruction PC (0x6228=>0x622c).(0=>1) created [sn:1368].
2457500: system.cpu.fetch: [tid:0] Instruction is:   adrp   x27, #61440

2457500: system.cpu.fetch: [tid:0] Instruction PC (0x622c=>0x6230).(0=>1) created [sn:1369].
2457500: system.cpu.fetch: [tid:0] Instruction is:   ldr   x1, [x1, #2432]

2457500: system.cpu.fetch: [tid:0] Done fetching, reached fetch bandwidth for this cycle.
```

### 分支预测

如果分支预测跳转，就会结束当前fetch操作，分支指令之前的指令可以继续进入fetchQueue。同时可以直接发起新的cache请求

```
2600000: system.cpu.fetch: [tid:0] Instruction PC (0x1514=>0x1518).(0=>1) created [sn:1413].
2600000: system.cpu.fetch: [tid:0] Instruction is:   ret   

2600000: system.cpu.fetch: [tid:0] [sn:1413] Branch at PC 0x1514 predicted to be taken to (0x6260=>0x6264).(0=>1)

2600000: system.cpu.fetch: [tid:0] Done fetching, predicted branch instruction encountered.

2600000: system.cpu.fetch: [tid:0] Issuing a pipelined I-cache access, starting at PC (0x6260=>0x6264).(0=>1).
2600000: system.cpu.fetch: [tid:0] Fetching cache line 0x6260 for addr 0x6260

2600000: system.cpu.fetch: [tid:0] [sn:1412] Sending instruction to decode from fetch queue. Fetch queue size: 2.
2600000: system.cpu.fetch: [tid:0] [sn:1413] Sending instruction to decode from fetch queue. Fetch queue size: 1.
```

### quiesce 类指令的处理

quiesce类指令：

- wfe
- wfet(Gem5 不支持)
- wfi
- wfit(Gem5 不支持)

以wfi指令举例
```
1376000: system.cpu.fetch: [tid:0] Instruction PC (0x1c4=>0x1c8).(0=>1) created [sn:119].
1376000: system.cpu.fetch: [tid:0] Instruction is:   wfi   

1376000: system.cpu.fetch: Quiesce instruction encountered, halting fetch!

// 下一拍，fetch 开始处于pending的状态
1376500: system.cpu.fetch: There are no more threads available to fetch from.
1376500: system.cpu.fetch: [tid:0] Fetch is waiting for a pending quiesce instruction!

// 在这个例子中，wfi指令处于分支错误的路径上，最终执行squash恢复了运行
1380000: system.cpu.commit: [tid:0] Squashing due to branch mispred PC:0x1c0 [sn:118]
1380000: system.cpu.commit: [tid:0] Redirecting to PC (0x1cc=>0x1d0).(0=>1)

1380500: system.cpu.fetch: [tid:0] Squashing instructions due to squash from commit.
1380500: system.cpu.fetch: [tid:0] Squash from commit.

1381000: system.cpu.fetch: [tid:0] Done squashing, switching to running.
1381000: system.cpu.fetch: Running stage.
```

### squash

squash 主要执行如下操作

- 将PC设置为Commit stage 返回的PC
- 复位与fetch buffer相关的reg
- 如果有进行中的icache请求，标记请求无效
- 如果有进行中的itlb请求，标记请求无效
- 如果有进行中的icache retry请求，标记请求无效
- 清空fetchQueue

### stall

来自于decode的stall不会影响fetch将指令存入fetchQueue，会stall从fetchQueue向decode发送指令。

---

## decode
 
![decode struct](../imgs/gem5_o3cpu/struct_decode.png)
 
### squash
 
#### 分支预测错误引起的squash
 
decode stage 会判断非条件跳转指令是否分支预测错误。

如果发现非条件跳转指令分支预测错误，那么会在当拍执行squash操作，假设decode宽度是4，跳转指令是第三条，那么前三条指令都能正常decode，并且发送到rename，此时decode转入squashing的状态，清除掉skidbuffer中的所有指令。

如果下一个cycle没有收到squash信号或者stall信号，decode将再次转为running状态。

当前cycle fetch到了 b 0x1570 指令，并且给通过分支预测器获取了不跳转的分支信息，下一条指令地址为 0x1d4
```
668000: system.cpu.fetch: [tid:0] Instruction PC (0x1cc=>0x1d0).(0=>1) created [sn:126].
668000: system.cpu.fetch: [tid:0] Instruction is:   b   0x1570
668000: system.cpu.fetch: [tid:0] [sn:126] Branch at PC 0x1cc predicted to be not taken
668000: system.cpu.fetch: [tid:0] [sn:126] Branch at PC 0x1cc predicted to go to (0x1d0=>0x1d4).(0=>1)

// 126 ~ 133 的指令被传入到fetchqueue
668000: system.cpu.fetch: [tid:0] [sn:126] Sending instruction to decode from fetch queue. Fetch queue size: 8.
668000: system.cpu.fetch: [tid:0] [sn:127] Sending instruction to decode from fetch queue. Fetch queue size: 7.
668000: system.cpu.fetch: [tid:0] [sn:128] Sending instruction to decode from fetch queue. Fetch queue size: 6.
668000: system.cpu.fetch: [tid:0] [sn:129] Sending instruction to decode from fetch queue. Fetch queue size: 5.
668000: system.cpu.fetch: [tid:0] [sn:130] Sending instruction to decode from fetch queue. Fetch queue size: 4.
668000: system.cpu.fetch: [tid:0] [sn:131] Sending instruction to decode from fetch queue. Fetch queue size: 3.
668000: system.cpu.fetch: [tid:0] [sn:132] Sending instruction to decode from fetch queue. Fetch queue size: 2.
668000: system.cpu.fetch: [tid:0] [sn:133] Sending instruction to decode from fetch queue. Fetch queue size: 1.
```

下一个cycle， decode解析出来的指令跳转地址为0x1570，因此产生squash信号
由于是8条指令中的第一条指令出现了分支预测错误，因此没有任何指令能够传给rename
```
668500: system.cpu.decode: [tid:0] Processing instruction [sn:126] with PC (0x1cc=>0x1d0).(0=>1)
668500: system.cpu.decode: [tid:0] [sn:126] Squashing due to incorrect branch prediction detected at decode.
668500: system.cpu.decode: [tid:0] [sn:126] Updating predictions: Wrong predicted target: (0x1d0=>0x1d4).(0=>1)    PredPC: (0x1570=>0x1574).(0=>1)

668500: system.cpu.rename: [tid:0] Not blocked, so attempting to run stage.
668500: system.cpu.rename: [tid:0] Nothing to do, breaking out early.
```

decode需要通知fetch进行squash操作,同时将fetch与decode之间锁存的指令也清除掉。同时，如果decode当前处于blocked或者unblocking状态，需要通知fetch此状态解除。

#### squash 代码逻辑

fetch.cc
添加指令到全局指令列表
```
    // Add instruction to the CPU's list of instructions.
    instruction->setInstListIt(cpu->addInst(instruction));
```

decode.cc
在squash时，给要squash的指令添加 squashed 标记
```
    // Squash instructions up until this one
    cpu->removeInstsUntil(squash_seq_num, tid);
```

在decode指令时，如果标记了squashed， 直接跳过
```
if (inst->isSquashed()) {​​​​​​​​
            DPRINTF(Decode, "[tid:%i] Instruction %i with PC %s is "
                    "squashed, skipping.\n",
                    tid, inst->seqNum, inst->pcState());
            ++stats.squashedInsts;
            --insts_available;
            continue;
        }​​​​​​​​
```

所以，flash 中间过程的指令没有额外的耗费cycle
 
#### 来自于commit的squash
 
- 如果decode处于block或者unbloking状态，通知fetch该状态已解除。因为会刷掉skidbuffer
- 清除掉skidbuffer，和来自于fetch的指令
 
fetch 到 decode之间on the fly的指令在fetch的squash处理中完成
 
fetch.cc
```
    // Tell the CPU to remove any instructions that are not in the ROB.
    cpu->removeInstsNotInROB(tid);
```

### stall
 
- 如果rename block, 会发送stall信号给decode, decode收到stall信号，转为block状态，当拍不执行任何decode操作。并且会将stall信号传递给fetch。
- rename解除block后，decode进入unblocking状态，从skidbuffer中取指令，skidbuffer空了之后，转入running状态
 
### unblocking
 
- 如果收到rename发送的解除stall信号，rename进入unblocking状态，从skidbuffer中取指令进行decode。
- 当skidbuffer中没有指令时，发送解除stall信号给fetch stage

---

## Rename

![rename struct](../imgs/gem5_o3cpu/struct_rename.png)

### squash
 
Rename stage 会响应来自于commit stage的squash信号，接收到squashing信号时，Rename进行如下操作
 
- 如果当前rename处于blocked或者unblocking的状态，发送unblock信号给decode stage
- 如果当前rename处于serializeStall状态，检查squash的指令是不是更older,如果是，清除掉serialize状态，发送unblock信号给decode；如果不是，保留serializeStall标记,下一拍恢复serializeStall
- 清除掉来自于decode的指令
- 清除掉skidbuffer中的指令
- 一次性恢复RAT(从时序行为上来看仍然是ROB walk的形式)
 
### stall
 
rename stall 的源比较多，有如下几个
 
- REW stage block(dispatch)
- no free ROB entries
- no free LSU entries
- no free IQ entries
- no free Phy Regs in freelist
- serializeStall

当发生stall时，rename stage有如下行为
 
- 将decode传入的指令存入skidbuffer
- 如果当前不在blocked或unblocking状态，向decode发送stall信号
- 如果不处于serializeStall 状态，标记自己为blocked状态
 
### unblocking
 
如果收到了dispatch 发送的解除stall信号，rename可能进入unblocking状态，从skidbuffer中取指令进行rename操作。当skidbuffer中没有指令时，发送解除stall信号给decode stage
 
### serilizeBefore

serializeBefore makes the instruction wait in rename until the ROB is empty.

serializeBefore类指令：

- mrs

msr指令引起serializeBefore， msr指令id为34
```
 388500: system.cpu.fetch: [tid:0] Instruction is:   msr   sp_el0, x0
 388500: system.cpu.fetch: [tid:0] Fetch queue entry created (1/32).
 388500: system.cpu.decoder: Decode: Decoded msr instruction: 0x4d51c4100
 388500: global: DynInst: [sn:34] Instruction created. Instcount for system.cpu = 2
 388500: system.cpu.fetch: [tid:0] Instruction PC (0x84=>0x88).(0=>1) created [sn:34].
```

因为 fetch -> decode 的延迟为3，decode -> rename 延迟为2， 所以5个cycle ((391000-388500)/500=5)之后，rename收到msr指令
判断指令携带IsSerializeBefore 标记，不对该指令进行具体的rename操作，转为SerializeStall状态。剩余的指令存入skidbuffer。
```
 391000: system.cpu.rename: [tid:0] Processing instruction [sn:34] with PC (0x84=>0x88).(0=>1).
 391000: system.cpu.rename: Serialize before instruction encountered.
 391000: system.cpu.rename: [tid:0] Blocking.
 391000: system.cpu.rename: [tid:0] Inserting [sn:35] PC: (0x88=>0x8c).(0=>1) into Rename skidBuffer
```

下一拍，rename保持serializeStall状态，并且将stall状态反压给decode
```
 391500: system.cpu.rename: [tid:0] 1 instructions not yet in ROB
 391500: system.cpu.rename: [tid:0] Stall: Serialize stall and ROB is not empty.
 391500: system.cpu.rename: [tid:0] Blocking.
 391500: system.cpu.rename: [tid:0] Inserting [sn:36] PC: (0x8c=>0x90).(0=>1) into Rename skidBuffer
```

下一拍，decode 收到stall信号，这个stall信号会反压给fetch。rename仍然处于stall状态，因为还有一条指令on the fly
```
 392000: system.cpu.decode: [tid:0] Stall fom Rename stage detected.
 392000: system.cpu.decode: [tid:0] Blocking.
 392000: system.cpu.rename: [tid:0] 1 instructions not yet in ROB
 392000: system.cpu.rename: [tid:0] Stall: Serialize stall and ROB is not empty.
 392000: system.cpu.rename: [tid:0] Blocking.
```

33号指令在四个cycle之后retire了
```
 394000: system.cpu.commit: [tid:0] [sn:33] Committing instruction with PC (0x80=>0x84).(0=>1)
 394000: system.cpu.rob: [tid:0] Retiring head instruction, instruction PC (0x80=>0x84).(0=>1), [sn:33]
```

下一个cycle,rename检测到
```
 394500: system.cpu.rename: [tid:0] Done with serialize stall, switching to unblocking.
 394500: system.cpu.rename: [tid:0] Trying to unblock.
 394500: system.cpu.rename: [tid:0] Processing instruction [34] with PC (0x84=>0x88).(0=>1).
```

### serilizeAfter

serilizeAfter类指令：

- rfe(return from exception) only arch32 support?
- svc(supervisor call to EL1)
- hvc(supervisor call to EL2)
- smc(secure monitor call to EL3)
- hlt(halt)
- eret(exception return)
- msr(move to system registers)
- wfe(wait for exception)
- wfi(wait for interrupt)
- mcr( arch32 only?)
- setend(arch32 only?)
- dsb(Data Synchronization Barrier)
- cps(change pe status) arch32 only?
- brk(breakpoint)

---

## dispatch

![iew struct](../imgs/gem5_o3cpu/struct_iew.png)


--- 

## Issue

---

## execute

---

## writeback

---

## commit

![commit struct](../imgs/gem5_o3cpu/struct_commit.png)

### 分支预测引起的squash


sn:1639 是一条b.eq指令
```
3021500: system.cpu.fetch: [tid:0] Instruction PC (0x6008=>0x600c).(0=>1) created [sn:1639].
3021500: system.cpu.fetch: [tid:0] Instruction is:   b.eq   0x61ec
3021500: system.cpu.fetch: [tid:0] Fetch queue entry created (3/32).
3021500: system.cpu.fetch: [tid:0] [sn:1639] Branch at PC 0x6008 predicted to be not taken
3021500: system.cpu.fetch: [tid:0] [sn:1639] Branch at PC 0x6008 predicted to go to (0x600c=>0x6010).(0=>1)
```

执行时发现分支预测错误(cycle0)
```
3027500: system.cpu.iew: [tid:0] [sn:1639] Execute: Branch mispredict detected.
3027500: system.cpu.iew: [tid:0] [sn:1639] Predicted target was PC: (0x600c=>0x6010).(0=>1)
3027500: system.cpu.iew: [tid:0] [sn:1639] Execute: Redirecting fetch to PC: (0x6008=>0x61ec).(0=>1)
```

下一个cycle(cycle1)，commit响应分支预测错误，发起squash操作,squash宽度为8，因此只能squash到1641号指令
```
3028000: system.cpu.commit: [tid:0] Squashing due to branch mispred PC:0x6008 [sn:1639]
3028000: system.cpu.commit: [tid:0] Redirecting to PC (0x61ec=>0x61f0).(0=>1)
3028000: system.cpu.rob: Starting to squash within the ROB.
3028000: system.cpu.rob: [tid:0] Squashing instructions until [sn:1639].
3028000: system.cpu.rob: [tid:0] Squashing instruction PC (0x6038=>0x603c).(0=>1), seq num 1653.
3028000: system.cpu.rob: [tid:0] Squashing instruction PC (0x6034=>0x6038).(0=>1), seq num 1652.
3028000: system.cpu.rob: [tid:0] Squashing instruction PC (0x6030=>0x6034).(0=>1), seq num 1651.
3028000: system.cpu.rob: [tid:0] Squashing instruction PC (0x602c=>0x6030).(0=>1), seq num 1650.
3028000: system.cpu.rob: [tid:0] Squashing instruction PC (0x6028=>0x602c).(0=>1), seq num 1649.
3028000: system.cpu.rob: [tid:0] Squashing instruction PC (0x6024=>0x6028).(0=>1), seq num 1648.
3028000: system.cpu.rob: [tid:0] Squashing instruction PC (0x6020=>0x6024).(2=>3), seq num 1647.
3028000: system.cpu.rob: [tid:0] Squashing instruction PC (0x6020=>0x6024).(1=>2), seq num 1646.
```

下一个cycle(cycle2)，rename stage收到squash信号，利用 history buffer 恢复 RAT, 一拍内完成恢复
```
3028500: system.cpu.rename: [tid:0] Squashing instructions due to squash from commit.
3028500: system.cpu.rename: [tid:0] [squash sn:1639] Squashing instructions.
3028500: system.cpu.rename: [tid:0] Removing history entry with sequence number 1657 (archReg: 0, newPhysReg: 27, prevPhysReg: 14).
3028500: system.cpu.rename: [tid:0] Removing history entry with sequence number 1656 (archReg: 3, newPhysReg: 31, prevPhysReg: 80).
3028500: system.cpu.rename: [tid:0] Removing history entry with sequence number 1655 (archReg: 0, newPhysReg: 14, prevPhysReg: 112).
3028500: system.cpu.rename: [tid:0] Removing history entry with sequence number 1654 (archReg: 2, newPhysReg: 125, prevPhysReg: 118).
3028500: system.cpu.rename: [tid:0] Removing history entry with sequence number 1653 (archReg: 0, newPhysReg: 112, prevPhysReg: 107).
3028500: system.cpu.rename: [tid:0] Removing history entry with sequence number 1652 (archReg: 1, newPhysReg: 71, prevPhysReg: 108).
3028500: system.cpu.rename: [tid:0] Removing history entry with sequence number 1651 (archReg: 2, newPhysReg: 118, prevPhysReg: 122).
3028500: system.cpu.rename: [tid:0] Removing history entry with sequence number 1649 (archReg: 1, newPhysReg: 605, prevPhysReg: 602).
3028500: system.cpu.rename: [tid:0] Removing history entry with sequence number 1649 (archReg: 2, newPhysReg: 604, prevPhysReg: 601).
3028500: system.cpu.rename: [tid:0] Removing history entry with sequence number 1649 (archReg: 0, newPhysReg: 603, prevPhysReg: 600).
3028500: system.cpu.rename: [tid:0] Removing history entry with sequence number 1649 (archReg: 0, newPhysReg: 65535, prevPhysReg: 65535).
3028500: system.cpu.rename: [tid:0] Removing history entry with sequence number 1645 (archReg: 35, newPhysReg: 117, prevPhysReg: 46).
3028500: system.cpu.rename: [tid:0] Removing history entry with sequence number 1643 (archReg: 1, newPhysReg: 602, prevPhysReg: 599).
3028500: system.cpu.rename: [tid:0] Removing history entry with sequence number 1643 (archReg: 2, newPhysReg: 601, prevPhysReg: 598).
3028500: system.cpu.rename: [tid:0] Removing history entry with sequence number 1643 (archReg: 0, newPhysReg: 600, prevPhysReg: 597).
3028500: system.cpu.rename: [tid:0] Removing history entry with sequence number 1643 (archReg: 0, newPhysReg: 65535, prevPhysReg: 65535).
3028500: system.cpu.rename: [tid:0] Removing history entry with sequence number 1642 (archReg: 3, newPhysReg: 80, prevPhysReg: 127).
3028500: system.cpu.rename: [tid:0] Removing history entry with sequence number 1641 (archReg: 1, newPhysReg: 108, prevPhysReg: 11).
3028500: system.cpu.rename: [tid:0] Removing history entry with sequence number 1640 (archReg: 1, newPhysReg: 11, prevPhysReg: 64).
```

issue stage 收到commit发来的squash信号，进入squash状态，清除queue中需要squash的指令
```
3028500: system.cpu.iew: [tid:0] Squashing all instructions.
3028500: system.cpu.iq: [tid:0] Starting to squash instructions in the IQ.
3028500: system.cpu.iq: [tid:0] Squashing until sequence number 1639!
3028500: system.cpu.iq: [tid:0] Instruction [sn:1654] PC (0x603c=>0x6040).(0=>1) squashed.
3028500: system.cpu.iq: [tid:0] Instruction [sn:1653] PC (0x6038=>0x603c).(0=>1) squashed.
3028500: system.cpu.iq: [tid:0] Instruction [sn:1651] PC (0x6030=>0x6034).(0=>1) squashed.
3028500: system.cpu.iq: [tid:0] Instruction [sn:1650] PC (0x602c=>0x6030).(0=>1) squashed.
3028500: system.cpu.iq: [tid:0] Instruction [sn:1649] PC (0x6028=>0x602c).(0=>1) squashed.
3028500: system.cpu.iq: [tid:0] Instruction [sn:1648] PC (0x6024=>0x6028).(0=>1) squashed.
3028500: system.cpu.iq: [tid:0] Instruction [sn:1647] PC (0x6020=>0x6024).(2=>3) squashed.
3028500: system.cpu.iq: [tid:0] Instruction [sn:1646] PC (0x6020=>0x6024).(1=>2) squashed.
3028500: system.cpu.iq: [tid:0] Instruction [sn:1644] PC (0x601c=>0x6020).(0=>1) squashed.
3028500: system.cpu.iq: [tid:0] Instruction [sn:1643] PC (0x6018=>0x601c).(0=>1) squashed.
3028500: system.cpu.iq: [tid:0] Instruction [sn:1642] PC (0x6014=>0x6018).(0=>1) squashed.
3028500: system.cpu.iq: [tid:0] Instruction [sn:1641] PC (0x6010=>0x6014).(0=>1) squashed.
3028500: system.cpu.iq: [tid:0] Instruction [sn:1640] PC (0x600c=>0x6010).(0=>1) squashed.
```

commit stage继续squash 指令，并且向issue 发送 robsquashing 信号
```
3028500: system.cpu.commit: [tid:0] Still Squashing, cannot commit any insts this cycle.
3028500: system.cpu.rob: [tid:0] Squashing instructions until [sn:1639].
3028500: system.cpu.rob: [tid:0] Squashing instruction PC (0x6020=>0x6024).(0=>1), seq num 1645.
3028500: system.cpu.rob: [tid:0] Squashing instruction PC (0x601c=>0x6020).(0=>1), seq num 1644.
3028500: system.cpu.rob: [tid:0] Squashing instruction PC (0x6018=>0x601c).(0=>1), seq num 1643.
3028500: system.cpu.rob: [tid:0] Squashing instruction PC (0x6014=>0x6018).(0=>1), seq num 1642.
3028500: system.cpu.rob: [tid:0] Squashing instruction PC (0x6010=>0x6014).(0=>1), seq num 1641.
3028500: system.cpu.rob: [tid:0] Squashing instruction PC (0x600c=>0x6010).(0=>1), seq num 1640.
```

下一个cycle(cycle3)，commit继续开始提交指令
```
3029000: system.cpu.commit: Trying to commit instructions in the ROB.
3029000: system.cpu.commit: Trying to commit head instruction, [tid:0] [sn:1635]
3029000: system.cpu.commit: [tid:0] [sn:1635] Committing instruction with PC (0x5ff8=>0x5ffc).(0=>1)
3029000: system.cpu.commit: [tid:0] [sn:1636] Committing instruction with PC (0x5ffc=>0x6000).(0=>1)
3029000: system.cpu.commit: [tid:0] [sn:1637] Committing instruction with PC (0x6000=>0x6004).(0=>1)
3029000: system.cpu.commit: [tid:0] [sn:1638] Committing instruction with PC (0x6004=>0x6008).(0=>1)
3029000: system.cpu.commit: [tid:0] [sn:1639] Committing instruction with PC (0x6008=>0x61ec).(0=>1)
```

dispatch 和 issue stage 因为收到commit的robsquashing信号，进入blocking(stall)状态,并且将自身的stall状态传递到rename stage
```
3029000: system.cpu.iew: [tid:0] ROB is still squashing.
3029000: system.cpu.iew: [tid:0] Removing incoming rename instructions
3029000: system.cpu.iew: [tid:0] Stall from Commit stage detected.
3029000: system.cpu.iew: [tid:0] Blocking.
```

下一个cycle(cycle4), rename接收到dispatch发送的stall信号，进入blocking状态
```
3029500: system.cpu.rename: [tid:0] Stall from IEW stage detected.
3029500: system.cpu.rename: [tid:0] Blocking.
```

dispatch 进入unblocking状态，发现skidbuffer中没有指令，转入running状态
```
3029500: system.cpu.iew: [tid:0] Done blocking, switching to unblocking.
3029500: system.cpu.iew: [tid:0] Reading instructions out of the skid buffer 0.
3029500: system.cpu.iew: [tid:0] Done unblocking.
3029500: system.cpu.iew: [tid:0] Not blocked, so attempting to run dispatch.
3029500: system.cpu.iq: Attempting to schedule ready instructions from the IQ.
3029500: system.cpu.iq: Not able to schedule any instructions.
```

下一个cycle(cycle5), decode stage 因为rename stall 的反压进入blocking状态
```
3030000: system.cpu.decode: [tid:0] Stall fom Rename stage detected.
3030000: system.cpu.decode: [tid:0] Blocking.
```

再下一个cycle(cycle6), fetch stage 收到decode的stall信号，不会从fetchqueue中将指令送给decode stage
 
 
汇总的各个stage状态如下表所示
stage |cycle0 | cycle1 | cycle2 | cycle3 | cycle4 | cycle5 | cycle6
---|---|---|---|---|---|---|---
fetch |	running	| running | squashing |	running	| running | running |running
decode | running | running | squashing | running | running | block | unblocking
rename | running |running | squashing | running | block | unblocking |	running
dispatch | running | running | squashing | block | unblocking | running | running
issue |	running | running | squashing | block | unblocking | running  |running
E & W |	branch | mispred | - | - | - | - | - | running
commit | running | squashing | squashing | running | running | running | running
 
从行为上，可以理解为分支预测错误的回滚是使用ROB walk的方式进行的，一拍能够回滚的指令个数可以由squshwidth指定
