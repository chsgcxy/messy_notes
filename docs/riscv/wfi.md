# wfi遇到的问题

[TOC]

今天将riscv-torture生成的code运行在spike上，我在code中加入了wfi指令，发现sike在运行时会exception，开启spike的日志功能，发现在执行wfi指令时会报非法指令的trap

```shell
riscv-torture$ spike -l --ddr-size=0xc0000000 --isa=RV32IMAFDCV +signature=output/test.spike.sig output/test
......
core   0: 0x0000000000000508 (0x10500073) wfi
core   0: exception trap_illegal_instruction, epc 0x0000000000000508
core   0:           tval 0x0000000000000000
......
```

如上就是遇到的问题，接下来是我要描述我的实际解决过程，这是一个十分蠢的解决过程，自己回想起来都不忍直视，为了中合这个不忍直视的解决过程，我会在最后再给出一个我认为比较更靠谱的解决过程（臆想的解决过程）

## 不忍直视的解决过程

为什么要添加wfi指令呢，因为wfi指令是我们自己实现的一个模拟器平台的退出条件，发起wfi指令，模拟器将会退出，不然模拟器将无法退出。

我使用riscv-cmodel_test是能够正常执行wfi指令的，因为我去查看了cmodel-test生成的code，里面确实包含了wfi指令，并且在spike上运行的时候不会报异常。

这个时候顺理成章的想到比对riscv-torture和cmodel-test生成的代码，看有哪些不一样的地方，因为我初步判断，与spike应该关系不大，spike明显能够处理wfi指令

通过比对，发现两者code在初始化控制状态寄存器mstatus时，初始化的有些差异

其中cmodel-test实现如下

```S
li t0, MSTATUS_FS | MSTATUS_XS
csrs mstatus, t0
```

riscv-torture实现如下

```S
li a0, (MSTATUS_VS & (MSTATUS_VS >> 1)) |
        (MSTATUS_FS & (MSTATUS_FS >> 1));
csrs mstatus, a0;
```

不管三七二十一，先copy成一样的试试，结果然并卵......
 此时才想到要去手册里面看一下，到底这点儿差异是怎么回事，查看文档，了解mstatus指令，文档中描述如下

```text
The FS[1:0] read/write field and the XS[1:0] read-only field are used to reduce the cost of context
save and restore by setting and tracking the current state of the floating-point unit and any other
user-mode extensions respectively. The FS field encodes the status of the floating-point unit,
including the CSR fcsr and floating-point data registers f0–f31, while the XS field encodes the
status of additional user-mode extensions and associated state. These fields can be checked by a
context switch routine to quickly determine whether a state save or restore is required
```

这个与浮点扩展和其他扩展有关，似乎也没wfi什么事儿，但与此同时，突发奇想，如果不是与扩展有关，那是不是与特权模式有关呢，这个mstatus里面的MPP不正是模式控制吗

管他呢，先试一把，于是我把代码改成了这样

```S
li a0, MSTATUS_FS | MSTATUS_XS | MSTATUS_MPP;
csrs mstatus, a0;
```

瞎猫碰上了死耗子，竟然不再报异常了，问题解决了......

## 真相的转折点

如果真的就这么结束了，那我真的是蠢到家了，幸亏又是随机的进行了进一步的思考

cmodel-test生成的代码似乎没有设置机器模式吧，搜索了整个cmodel-test生成的代码，确实没有配置机器模式。这就奇怪了，同样是没有配置，riscv-torture生成的代码wfi怎么就是非法指令呢？

再去看文档，搜索MPP相关内容

```text
M-mode is used for low-level access to a hardware platform
and is the first mode entered at reset

The machine level has the highest privileges and is the only mandatory privilege level for a RISC-V
hardware platform. Code run in machine-mode (M-mode) is usually inherently trusted, as it has
low-level access to the machine implementation. M-mode can be used to manage secure execution
environments on RISC-V. User-mode (U-mode) and supervisor-mode (S-mode) are intended for
conventional application and operating system usage respectively.

通过将 mstatus.MPP 设置为 U(如图 10.5 所示,编码为 0),然后执行 mret 指令,软件可以
从 M 模式进入 U 模式

mret
ExceptionReturn(Machine)
机器模式异常返回(Machine-mode Exception Return). R-type, RV32I and RV64I 特权架构
从机器模式异常处理程序返回。将 pc 设置为 CSRs[mepc], 将特权级设置成
CSRs[mstatus].MPP, CSRs[mstatus].MIE 置成 CSRs[mstatus].MPIE, 并且将
CSRs[mstatus].MPIE 为 1;并且,如果支持用户模式,则将 CSR [mstatus].MPP 设置为 0
```

恍然大悟, cpu上电复位的时候就是机器模式，我们做必要的初始化之后，使用mret退出机器模式，进入到其他的模式，以从模式上保证系统的安全，当系统发生异常时，cpu切换到机器模式或者特权模式，处理异常，处理完成后切换回原来的模式

因此很有可能riscv-torture使用mret进入了U-mode, 查看代码，确实如此，在初始化完复位向量之后，调用了mret退出了机器模式

```S
csrw mepc, t0;
csrr a0, mhartid;
mret;
```

所以猜想wfi只能在机器模式下调用，非机器模式下就会抛异常？必须得找出来证据才行，不然问题还是不彻底（智商终于重新占领了高地......）

为什么不去看一下spike代码呢，按照不靠谱的套路，先搜一下trap打印的地方

```shell
riscv-tools/riscv-isa-sim$ grep ", epc " * -nR
riscv/processor.cc:263:    fprintf(stderr, "core %3d: exception %s, epc 0x%016" PRIx64 "\n",
```

```cpp
void processor_t::take_trap(trap_t& t, reg_t epc)
{
  if (debug) {
    fprintf(stderr, "core %3d: exception %s, epc 0x%016" PRIx64 "\n",
            id, t.name(), epc);
    if (t.has_tval())
      fprintf(stderr, "core %3d:           tval 0x%016" PRIx64 "\n", id,
          t.get_tval());
  }
```

得有地方发trap才行, 搜索take_trap打印的地方，如下省略了step函数中的一些逻辑，留下的方便来理解

```cpp
void processor_t::step(size_t n)
{
    ......
    while (n > 0) {
        ......
        try
        {
            ......
            pc = execute_insn(this, pc, fetch);
            ......
        }
        catch(trap_t& t)
        {
            take_trap(t, pc);
            ......
        }
        ......
    }
    ......
}
```

猜想trap 应该是通过throw发出来的， 因为使用catch接住了trap， 这时突然想起来，spike每个指令都有一个单独的文件来是实现其逻辑

```cpp
require_privilege(get_field(STATE.mstatus, MSTATUS_TW) ? PRV_M : PRV_S);
wfi();

// 定义的地方
#define require(x) if (unlikely(!(x))) throw trap_illegal_instruction(0)
#define require_privilege(p) require(STATE.prv >= (p))
```

原来是这样，终于清晰一些了

## 真相

spike实现的wfi指令，在执行之前会判断mstatus寄存器的TW位，似乎通过这个判断出了当前CPU的权限模式？这肯定是RISCV规定了，继续看手册

```text
The TW (Timeout Wait) bit supports intercepting the WFI instruction (see Section 3.2.3). When
TW=0, the WFI instruction is permitted in S-mode. When TW=1, if WFI is executed in S-
mode, and it does not complete within an implementation-specific, bounded time limit, the WFI
instruction causes an illegal instruction trap. The time limit may always be 0, in which case WFI
always causes an illegal instruction trap in S-mode when TW=1. TW is hard-wired to 0 when
S-mode is not supported.

3.2.3
Wait for Interrupt
The Wait for Interrupt instruction (WFI) provides a hint to the implementation that the current
hart can be stalled until an interrupt might need servicing. Execution of the WFI instruction
can also be used to inform the hardware platform that suitable interrupts should preferentially
be routed to this hart. WFI is available in all of the supported S and M privilege modes, and
optionally available to U-mode for implementations that support U-mode interrupts.

wfi
while (noInterruptPending) idle
等待中断(Wait for Interrupt). R-type, RV32I and RV64I 特权指令。
如果没有待处理的中断,则使处理器处于空闲状态。
```

看完了之后又糊涂了，难道是英文不好？？？

## 臆想的解决过程

### 臆想的解决过程一

先在spike中进行定位，如果能够顺利定位到在wfi指令中进行的判断，那么就一定会去看手册，这时候就了解到整个wfi指令的描述，自然就知道应该工作在机器模式，然后再去分析为什么cmodel-test生成的代码wfi不会触发trap， 进而了解到mret的问题，整个问题解决

### 臆想的解决过程二

直接去看手册，了解到wfi是特权指令，再去分析cmodel-test和riscv-torture生成代码上的差别，进而了解到mret,然后又会奇怪spike是如何判断的，再去看spike代码，了解spike的处理流程，整个问题解决

### 总结

在cpu架构方面仍有太多的东西需要去了解，尤其是现在用到的RISCV。跟踪代码，定位问题仍然是一个靠运气的状态，还是应该不断的训练，积累经验，总结出定位问题的一般方法。值得肯定的是已经开始能够习惯性的运用调试手段来辅助定位问题，比如在spike异常的时候，能够以日志模式和debug模式进行调试。
