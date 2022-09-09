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
 
 
 
---

## decode
 
![decode struct](../imgs/gem5_o3cpu/struct_decode.png)
 
### squash
 
#### 分支预测错误引起的squash
 
decode stage 会判断非条件跳转指令是否分支预测错误。

如果发现非条件跳转指令分支预测错误，那么会在当拍执行squash操作，假设decode宽度是4，跳转指令是第三条，那么前三条指令都能正常decode，并且发送到rename，此时decode转入squashing的状态，清除掉skidbuffer中的所有指令。

如果下一个cycle没有收到squash信号或者stall信号，decode将再次转为running状态。

```
 // 当前cycle fetch到了 b 0x1570 指令，并且给通过分支预测器获取了不跳转的分支信息，下一条指令地址为 0x1d4
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

 // 下一个cycle， decode解析出来的指令跳转地址为0x1570，因此产生squash信号
 668500: system.cpu.decode: [tid:0] Processing instruction [sn:126] with PC (0x1cc=>0x1d0).(0=>1)
 668500: system.cpu.decode: [tid:0] [sn:126] Squashing due to incorrect branch prediction detected at decode.
 668500: system.cpu.decode: [tid:0] [sn:126] Updating predictions: Wrong predicted target: (0x1d0=>0x1d4).(0=>1)    PredPC: (0x1570=>0x1574).(0=>1)

 // 由于是8条指令中的第一条指令出现了分支预测错误，因此没人任何指令能够传给rename
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

msr 指令
```
 388500: system.cpu.fetch: [tid:0] Instruction is:   msr   sp_el0, x0
 388500: system.cpu.fetch: [tid:0] Fetch queue entry created (1/32).
 388500: system.cpu.decoder: Decode: Decoded msr instruction: 0x4d51c4100
 388500: global: DynInst: [sn:34] Instruction created. Instcount for system.cpu = 2
 388500: system.cpu.fetch: [tid:0] Instruction PC (0x84=>0x88).(0=>1) created [sn:34].
```

因为 fetch -> decode 的延迟为3，decode -> rename 延迟为2， 所以5个cycle ((391000-388500)/500=5)之后，rename收到msr指令
```
 391000: system.cpu.rename: [tid:0] Processing instruction [sn:34] with PC (0x84=>0x88).(0=>1).
 391000: system.cpu.rename: Serialize before instruction encountered.
```

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