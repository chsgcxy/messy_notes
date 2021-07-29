# chisel

Hardware compiler framework and hardware design language developed at UC Berkeley

[TOC]

## 现状

- 官方实现了[Rocket Chip](https://github.com/freechipsproject/rocket-chip) 及 [BOOM](https://github.com/riscv-boom/riscv-boom) 两款 CPU
- [SiFive](https://www.sifive.com/)的芯片使用Chisel编写
- 中科院计算所的[香山处理器](https://github.com/OpenXiangShan)使用shisel编写

## 特点

- Open-Source
- Highly parameterized
- Based on Scala
- Re-usable components and libraries
- FIRRTL (Flexible Intermediate Representation for RTL)
- The ability to create generators
- Design verification support iotesters(peek, poke, expect) and testers2(fork, join)
- Can in-line verilog

从chisel官方网站名称是不是能够看出来它更像是一个硬件编译器框架？ lang让人联想到clang,进而想到llvm，FIRRTL从设计上和LLVM很像。

## 与verilog的对比

对比项 | verilog | chisel
---|---|---
HDL | 是 | HDL,非HLS [^1]
代码简洁性 | 非常啰嗦，可读性和可维护性都比较差 | 代码简洁，符合软件思维
编译检查 | 从不进行检查，编译器没有基本的逻辑判断能力 | 功能强大的错误检查和自动推断能力
是否可综合 | 可综合，具有唯一性 | 可综合,具有唯一性
重用性 | 较差的可重用性，很难拿来直接怼 | 高度的参数化支持，很容易复用
成熟度 | 非常成熟 | 仍需要较长时间的发展
模块测试难度 | 测试代码可能要比设计代码还要复杂 | 自带的tester编写方便，语法高级

[^1]: HLS 高级综合(high-level synthesis) 能自动把 C/C++ 之类的高级语言转化成 Verilog/VHDL 之类的底层硬件描述语言(RTL), 例如：vivado HLS, Intel HLS compiler, Mentor Catapult HLS, Cadence Stratus HLS, Synopsys C。据说2003年，一位博士生挑战了已经卡壳20年的HLS领域，成功把非时序的代码时序硬件化。他和老师一起创办了AutoESL，做C自动转换RTL。2011年被Xilinx收购，诞生了Xilinx Vivado HLS

## 前景

Verilog,SystemVerilog,SystemC,Chisel,HLS 谁们才是未来？

## 学习路线

[官方教程](https://mybinder.org/v2/gh/freechipsproject/chisel-bootcamp/master)
[官方网站](https://www.chisel-lang.org/)
[chisel工程模板](https://github.com/freechipsproject/chisel-template)
[API手册](https://www.chisel-lang.org/api/latest/chisel3/index.html)
[速记手册下载链接](https://github.com/freechipsproject/chisel-cheatsheet/releases/latest/download/chisel_cheatsheet.pdf)

根据官方训练营，一步步的学习，自己动手敲一敲，做一些简单测试，然后就可以在读Rocket Chip代码的同时不断的进行提高

## 环境搭建

chisel官方提供了chisel-bootcamp, 一个chisel教程。这是一个很好的参考，它为了专注于chisel本身，把环境搭建给做好了，这里建议采取：自己搭建环境 + bootcamp例程的学习方法

环境搭建要点：

- chisel依赖于sbt和scala,因此，提前搭建好scala运行环境
- chisel不需要单独进行安装，sbt能够自动获取托管依赖
- 下载一个chisel的repo模板会是非常省事的环境搭建方法

下面是shisel-template的简要目录结构，sbt要求放置文件必须按照一定的目录结构放置，很多现代构建工具都有这样类似的要求
其中：

- build.sbt :存放了绝大多数构建规则(主流用法)，主要是构建对象以及依赖的包，chisel包就在这里面进行说明
- build.sc :目前还未完全弄清
- src : 根据sbt规则，默认构建对象存放的目录就是src,src目录下必须有一个mian/scala目录，源文件放在这个目录下
- src/test : test目录，测试代码应该放在这个目录的scala子目录下，这样就可以使用iotester和tester2进行单元测试了
- test_run_dir : 运行时可能生成此目录，生成的VCD波形文件就在这个目录下，这是tester的功能
- project : sbt 使用

```text
.
├── build.sbt
├── build.sc
├── LICENSE
├── project
├── src
│   ├── main
│   │   └── scala
│   │       └── demo.scala
│   └── test
│       └── scala
│           └── BaseTest.scala
├── target
└── test_run_dir
```

## chisel语法要点

时刻注意，chisel是强类型语言，类型不匹配在编译时会报错，要熟知使用的对象的类型。
下面的语法要点是对官方教程进行了总结，但**熟悉chisel基础语法最好的方式是按照官方教程进行学习**

### 组合逻辑和时序逻辑

chisel提供了Mux,Cat,Wire等基础类型用于实现组合逻辑，提供了Reg，when, elsewhen, otherwise等来实现时序逻辑。
必须使用`:=`来对Wire和Reg进行赋值, 这里使用一个没有任何意义的ALU单元来体现chisel如何实现组合逻辑和时序逻辑

```scala
class MyAlu extends Module {
  val io = IO(new Bundle {
    val in_src1 = Input(UInt(32.W))
    val in_src2 = Input(UInt(32.W))
    val in_imm2 = Input(UInt(2.W))
    val output_add = Output(UInt(32.W))
    val output_add_expand = Output(UInt(64.W))
    val output_sub = Output(UInt(32.W))
    val output_max = Output(UInt(32.W))
    val output_ext = Output(UInt(32.W))
  })

  io.output_add := io.in_src1 + io.in_src2
  io.output_sub := io.in_src1 - io.in_src2
  io.output_add_expand := io.in_src1 +& io.in_src2
  
  val to_max = Wire(UInt(32.W))
  when (io.in_src1 < io.in_src2) {
    to_max := io.in_src2
  } .otherwise {
    to_max := io.in_src1
  }
  io.output_max := to_max
  
  val ext_reg = RegInit(UInt(32.W), 0.U)
  switch (io.in_imm2) {
    is(0.U) {
      ext_reg := io.in_src1
    }
    is(1.U) {
      ext_reg := Cat(io.in_src1(31, 1), 0.U(1.W))
    }
    is(2.U) {
      ext_reg := Cat(io.in_src1(31, 2), 0.U(2.W))
    }
    is(3.U) {
      ext_reg := Cat(io.in_src1(31, 3), 0.U(3.W))
    }
  }
  io.output_ext := ext_reg
}
```

生成的verilog代码如下

```verilog
module MyAlu(
  input         clock,
  input         reset,
  input  [31:0] io_in_src1,
  input  [31:0] io_in_src2,
  input  [1:0]  io_in_imm2,
  output [31:0] io_output_add,
  output [63:0] io_output_add_expand,
  output [31:0] io_output_sub,
  output [31:0] io_output_max,
  output [31:0] io_output_ext
);

  wire [32:0] _io_output_add_T = io_in_src1 + io_in_src2; // @[demo.scala 17:31]
  reg [31:0] ext_reg; // @[demo.scala 29:24]
  wire  _T_1 = 2'h0 == io_in_imm2; // @[Conditional.scala 37:30]
  wire  _T_2 = 2'h1 == io_in_imm2; // @[Conditional.scala 37:30]
  wire [30:0] ext_reg_hi = io_in_src1[31:1]; // @[demo.scala 35:32]
  wire [31:0] _ext_reg_T = {ext_reg_hi,1'h0}; // @[Cat.scala 30:58]
  wire  _T_3 = 2'h2 == io_in_imm2; // @[Conditional.scala 37:30]
  wire [29:0] ext_reg_hi_1 = io_in_src1[31:2]; // @[demo.scala 38:32]
  wire [31:0] _ext_reg_T_1 = {ext_reg_hi_1,2'h0}; // @[Cat.scala 30:58]
  wire  _T_4 = 2'h3 == io_in_imm2; // @[Conditional.scala 37:30]
  wire [28:0] ext_reg_hi_2 = io_in_src1[31:3]; // @[demo.scala 41:32]
  wire [31:0] _ext_reg_T_2 = {ext_reg_hi_2,3'h0}; // @[Cat.scala 30:58]
  wire [31:0] _GEN_1 = _T_4 ? _ext_reg_T_2 : ext_reg; // @[Conditional.scala 39:67 demo.scala 41:15 demo.scala 29:24]
  assign io_output_add = io_in_src1 + io_in_src2; // @[demo.scala 17:31]
  assign io_output_add_expand = {{31'd0}, _io_output_add_T}; // @[demo.scala 19:38]
  assign io_output_sub = io_in_src1 - io_in_src2; // @[demo.scala 18:31]
  assign io_output_max = io_in_src1 < io_in_src2 ? io_in_src2 : io_in_src1; // @[demo.scala 22:34 demo.scala 23:12 demo.scala 25:12]
  assign io_output_ext = ext_reg; // @[demo.scala 44:17]
  always @(posedge clock) begin
    if (reset) begin // @[demo.scala 29:24]
      ext_reg <= 32'h0; // @[demo.scala 29:24]
    end else if (_T_1) begin // @[Conditional.scala 40:58]
      ext_reg <= io_in_src1; // @[demo.scala 32:15]
    end else if (_T_2) begin // @[Conditional.scala 39:67]
      ext_reg <= _ext_reg_T; // @[demo.scala 35:15]
    end else if (_T_3) begin // @[Conditional.scala 39:67]
      ext_reg <= _ext_reg_T_1; // @[demo.scala 38:15]
    end else begin
      ext_reg <= _GEN_1;
    end
  end
endmodule
```

### tester

一个Fir数字滤波器的简单测试方法，并支持生成VCD波形

```scala
import chisel3._
import chiseltest._
import org.scalatest._
import chiseltest.experimental.TestOptionBuilder._
import chiseltest.internal.WriteVcdAnnotation

class MySpec extends FlatSpec with ChiselScalatestTester with Matchers {

    it should "get a fir" in {
    test(new My4ElementFir(0, 0, 0, 0)).withAnnotations(Seq(WriteVcdAnnotation)) { c =>
        c.io.in.poke(0.U)
        c.io.out.expect(0.U)
        c.clock.step(1)
        c.io.in.poke(4.U)
        c.io.out.expect(0.U)
        c.clock.step(1)
        c.io.in.poke(5.U)
        c.io.out.expect(0.U)
        c.clock.step(1)
        c.io.in.poke(2.U)
        c.io.out.expect(0.U)
    }
  }
}
```

chisel 支持scala的tester测试框架，同时也正在改进测试框架，名为testers2。
我们在verilog开发过程中，一些单元测试需要自己写激励文件，往往对于稍微复杂的模块，激励文件的复杂度很高，往往这部分工作有专门的RTL验证人员负责。chisel提供了一种简单的方法，适用于单元测试和系统集成测试，并尽可能使得单元测试简单方便有用

讨论：**至少在单元自测试方面，Testers提供了一个非常方便的方法来进行简单自验证。Testers2在使用chisel进行IC开发的过程中扮演着怎样的角色？Testes是否能够替代现有的测试手段？**

### 生成器

所谓的生成器就是指模块的参数化，这是chisel真正强大的地方，也是精髓所在。单看上面时序逻辑和组合逻辑的例子，你不会感觉到chisel的强大，只有在接触了生成器之后，才能真正的体会到的它的高效。这也是为什么chisel开发过程中讲究敏捷。

语法要点：

- Option
- match,case
- Implicits隐含参数，隐式转换(这种方法比较难读，不建议使用)
- 容器
- mutable.ArrayBuffer
- Vec(仅在普通Scala容器用不了的情况下使用)

举例：如下是一个简单的寄存器文件实现，可以通过参数指定读端口的数量

```scala
class RegisterFile(readPorts: Int) extends Module {
    require(readPorts >= 0)
    val io = IO(new Bundle {
        val wen   = Input(Bool())
        val waddr = Input(UInt(5.W))
        val wdata = Input(UInt(32.W))
        val raddr = Input(Vec(readPorts, UInt(5.W)))
        val rdata = Output(Vec(readPorts, UInt(32.W)))
    })

    val reg = RegInit(VecInit(Seq.fill(32)(0.U(32.W))))

    when (io.wen) {
        reg(io.waddr) := io.wdata
    }

    for (i <- 0 until readPorts) {
        when (io.raddr(i) === 0.U) {
            io.rdata(i) := 0.U
        } .otherwise {
            io.rdata(i) := reg(io.raddr(i))
        }
    }
}
```

生成的verilog如下，例化的readPorts数量为3

```verilog
module RegisterFile(
  input         clock,
  input         reset,
  input         io_wen,
  input  [4:0]  io_waddr,
  input  [31:0] io_wdata,
  input  [4:0]  io_raddr_0,
  input  [4:0]  io_raddr_1,
  input  [4:0]  io_raddr_2,
  output [31:0] io_rdata_0,
  output [31:0] io_rdata_1,
  output [31:0] io_rdata_2
);

  reg [31:0] reg_0; // @[demo.scala 165:22]
  reg [31:0] reg_1; // @[demo.scala 165:22]
  reg [31:0] reg_2; // @[demo.scala 165:22]
  reg [31:0] reg_3; // @[demo.scala 165:22]
  reg [31:0] reg_4; // @[demo.scala 165:22]
  reg [31:0] reg_5; // @[demo.scala 165:22]
  reg [31:0] reg_6; // @[demo.scala 165:22]
  reg [31:0] reg_7; // @[demo.scala 165:22]
  reg [31:0] reg_8; // @[demo.scala 165:22]
  reg [31:0] reg_9; // @[demo.scala 165:22]
  reg [31:0] reg_10; // @[demo.scala 165:22]
  reg [31:0] reg_11; // @[demo.scala 165:22]
  reg [31:0] reg_12; // @[demo.scala 165:22]
  reg [31:0] reg_13; // @[demo.scala 165:22]
  reg [31:0] reg_14; // @[demo.scala 165:22]
  reg [31:0] reg_15; // @[demo.scala 165:22]
  reg [31:0] reg_16; // @[demo.scala 165:22]
  reg [31:0] reg_17; // @[demo.scala 165:22]
  reg [31:0] reg_18; // @[demo.scala 165:22]
  reg [31:0] reg_19; // @[demo.scala 165:22]
  reg [31:0] reg_20; // @[demo.scala 165:22]
  reg [31:0] reg_21; // @[demo.scala 165:22]
  reg [31:0] reg_22; // @[demo.scala 165:22]
  reg [31:0] reg_23; // @[demo.scala 165:22]
  reg [31:0] reg_24; // @[demo.scala 165:22]
  reg [31:0] reg_25; // @[demo.scala 165:22]
  reg [31:0] reg_26; // @[demo.scala 165:22]
  reg [31:0] reg_27; // @[demo.scala 165:22]
  reg [31:0] reg_28; // @[demo.scala 165:22]
  reg [31:0] reg_29; // @[demo.scala 165:22]
  reg [31:0] reg_30; // @[demo.scala 165:22]
  reg [31:0] reg_31; // @[demo.scala 165:22]
  wire [31:0] _GEN_65 = 5'h1 == io_raddr_0 ? reg_1 : reg_0; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_66 = 5'h2 == io_raddr_0 ? reg_2 : _GEN_65; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_67 = 5'h3 == io_raddr_0 ? reg_3 : _GEN_66; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_68 = 5'h4 == io_raddr_0 ? reg_4 : _GEN_67; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_69 = 5'h5 == io_raddr_0 ? reg_5 : _GEN_68; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_70 = 5'h6 == io_raddr_0 ? reg_6 : _GEN_69; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_71 = 5'h7 == io_raddr_0 ? reg_7 : _GEN_70; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_72 = 5'h8 == io_raddr_0 ? reg_8 : _GEN_71; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_73 = 5'h9 == io_raddr_0 ? reg_9 : _GEN_72; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_74 = 5'ha == io_raddr_0 ? reg_10 : _GEN_73; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_75 = 5'hb == io_raddr_0 ? reg_11 : _GEN_74; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_76 = 5'hc == io_raddr_0 ? reg_12 : _GEN_75; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_77 = 5'hd == io_raddr_0 ? reg_13 : _GEN_76; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_78 = 5'he == io_raddr_0 ? reg_14 : _GEN_77; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_79 = 5'hf == io_raddr_0 ? reg_15 : _GEN_78; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_80 = 5'h10 == io_raddr_0 ? reg_16 : _GEN_79; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_81 = 5'h11 == io_raddr_0 ? reg_17 : _GEN_80; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_82 = 5'h12 == io_raddr_0 ? reg_18 : _GEN_81; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_83 = 5'h13 == io_raddr_0 ? reg_19 : _GEN_82; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_84 = 5'h14 == io_raddr_0 ? reg_20 : _GEN_83; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_85 = 5'h15 == io_raddr_0 ? reg_21 : _GEN_84; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_86 = 5'h16 == io_raddr_0 ? reg_22 : _GEN_85; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_87 = 5'h17 == io_raddr_0 ? reg_23 : _GEN_86; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_88 = 5'h18 == io_raddr_0 ? reg_24 : _GEN_87; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_89 = 5'h19 == io_raddr_0 ? reg_25 : _GEN_88; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_90 = 5'h1a == io_raddr_0 ? reg_26 : _GEN_89; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_91 = 5'h1b == io_raddr_0 ? reg_27 : _GEN_90; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_92 = 5'h1c == io_raddr_0 ? reg_28 : _GEN_91; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_93 = 5'h1d == io_raddr_0 ? reg_29 : _GEN_92; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_94 = 5'h1e == io_raddr_0 ? reg_30 : _GEN_93; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_95 = 5'h1f == io_raddr_0 ? reg_31 : _GEN_94; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_98 = 5'h1 == io_raddr_1 ? reg_1 : reg_0; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_99 = 5'h2 == io_raddr_1 ? reg_2 : _GEN_98; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_100 = 5'h3 == io_raddr_1 ? reg_3 : _GEN_99; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_101 = 5'h4 == io_raddr_1 ? reg_4 : _GEN_100; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_102 = 5'h5 == io_raddr_1 ? reg_5 : _GEN_101; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_103 = 5'h6 == io_raddr_1 ? reg_6 : _GEN_102; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_104 = 5'h7 == io_raddr_1 ? reg_7 : _GEN_103; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_105 = 5'h8 == io_raddr_1 ? reg_8 : _GEN_104; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_106 = 5'h9 == io_raddr_1 ? reg_9 : _GEN_105; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_107 = 5'ha == io_raddr_1 ? reg_10 : _GEN_106; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_108 = 5'hb == io_raddr_1 ? reg_11 : _GEN_107; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_109 = 5'hc == io_raddr_1 ? reg_12 : _GEN_108; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_110 = 5'hd == io_raddr_1 ? reg_13 : _GEN_109; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_111 = 5'he == io_raddr_1 ? reg_14 : _GEN_110; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_112 = 5'hf == io_raddr_1 ? reg_15 : _GEN_111; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_113 = 5'h10 == io_raddr_1 ? reg_16 : _GEN_112; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_114 = 5'h11 == io_raddr_1 ? reg_17 : _GEN_113; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_115 = 5'h12 == io_raddr_1 ? reg_18 : _GEN_114; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_116 = 5'h13 == io_raddr_1 ? reg_19 : _GEN_115; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_117 = 5'h14 == io_raddr_1 ? reg_20 : _GEN_116; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_118 = 5'h15 == io_raddr_1 ? reg_21 : _GEN_117; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_119 = 5'h16 == io_raddr_1 ? reg_22 : _GEN_118; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_120 = 5'h17 == io_raddr_1 ? reg_23 : _GEN_119; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_121 = 5'h18 == io_raddr_1 ? reg_24 : _GEN_120; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_122 = 5'h19 == io_raddr_1 ? reg_25 : _GEN_121; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_123 = 5'h1a == io_raddr_1 ? reg_26 : _GEN_122; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_124 = 5'h1b == io_raddr_1 ? reg_27 : _GEN_123; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_125 = 5'h1c == io_raddr_1 ? reg_28 : _GEN_124; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_126 = 5'h1d == io_raddr_1 ? reg_29 : _GEN_125; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_127 = 5'h1e == io_raddr_1 ? reg_30 : _GEN_126; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_128 = 5'h1f == io_raddr_1 ? reg_31 : _GEN_127; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_131 = 5'h1 == io_raddr_2 ? reg_1 : reg_0; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_132 = 5'h2 == io_raddr_2 ? reg_2 : _GEN_131; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_133 = 5'h3 == io_raddr_2 ? reg_3 : _GEN_132; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_134 = 5'h4 == io_raddr_2 ? reg_4 : _GEN_133; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_135 = 5'h5 == io_raddr_2 ? reg_5 : _GEN_134; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_136 = 5'h6 == io_raddr_2 ? reg_6 : _GEN_135; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_137 = 5'h7 == io_raddr_2 ? reg_7 : _GEN_136; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_138 = 5'h8 == io_raddr_2 ? reg_8 : _GEN_137; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_139 = 5'h9 == io_raddr_2 ? reg_9 : _GEN_138; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_140 = 5'ha == io_raddr_2 ? reg_10 : _GEN_139; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_141 = 5'hb == io_raddr_2 ? reg_11 : _GEN_140; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_142 = 5'hc == io_raddr_2 ? reg_12 : _GEN_141; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_143 = 5'hd == io_raddr_2 ? reg_13 : _GEN_142; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_144 = 5'he == io_raddr_2 ? reg_14 : _GEN_143; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_145 = 5'hf == io_raddr_2 ? reg_15 : _GEN_144; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_146 = 5'h10 == io_raddr_2 ? reg_16 : _GEN_145; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_147 = 5'h11 == io_raddr_2 ? reg_17 : _GEN_146; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_148 = 5'h12 == io_raddr_2 ? reg_18 : _GEN_147; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_149 = 5'h13 == io_raddr_2 ? reg_19 : _GEN_148; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_150 = 5'h14 == io_raddr_2 ? reg_20 : _GEN_149; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_151 = 5'h15 == io_raddr_2 ? reg_21 : _GEN_150; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_152 = 5'h16 == io_raddr_2 ? reg_22 : _GEN_151; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_153 = 5'h17 == io_raddr_2 ? reg_23 : _GEN_152; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_154 = 5'h18 == io_raddr_2 ? reg_24 : _GEN_153; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_155 = 5'h19 == io_raddr_2 ? reg_25 : _GEN_154; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_156 = 5'h1a == io_raddr_2 ? reg_26 : _GEN_155; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_157 = 5'h1b == io_raddr_2 ? reg_27 : _GEN_156; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_158 = 5'h1c == io_raddr_2 ? reg_28 : _GEN_157; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_159 = 5'h1d == io_raddr_2 ? reg_29 : _GEN_158; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_160 = 5'h1e == io_raddr_2 ? reg_30 : _GEN_159; // @[demo.scala 175:25 demo.scala 175:25]
  wire [31:0] _GEN_161 = 5'h1f == io_raddr_2 ? reg_31 : _GEN_160; // @[demo.scala 175:25 demo.scala 175:25]
  assign io_rdata_0 = io_raddr_0 == 5'h0 ? 32'h0 : _GEN_95; // @[demo.scala 172:36 demo.scala 173:25 demo.scala 175:25]
  assign io_rdata_1 = io_raddr_1 == 5'h0 ? 32'h0 : _GEN_128; // @[demo.scala 172:36 demo.scala 173:25 demo.scala 175:25]
  assign io_rdata_2 = io_raddr_2 == 5'h0 ? 32'h0 : _GEN_161; // @[demo.scala 172:36 demo.scala 173:25 demo.scala 175:25]
  always @(posedge clock) begin
    if (reset) begin // @[demo.scala 165:22]
      reg_0 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h0 == io_waddr) begin // @[demo.scala 168:23]
        reg_0 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_1 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h1 == io_waddr) begin // @[demo.scala 168:23]
        reg_1 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_2 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h2 == io_waddr) begin // @[demo.scala 168:23]
        reg_2 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_3 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h3 == io_waddr) begin // @[demo.scala 168:23]
        reg_3 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_4 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h4 == io_waddr) begin // @[demo.scala 168:23]
        reg_4 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_5 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h5 == io_waddr) begin // @[demo.scala 168:23]
        reg_5 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_6 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h6 == io_waddr) begin // @[demo.scala 168:23]
        reg_6 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_7 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h7 == io_waddr) begin // @[demo.scala 168:23]
        reg_7 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_8 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h8 == io_waddr) begin // @[demo.scala 168:23]
        reg_8 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_9 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h9 == io_waddr) begin // @[demo.scala 168:23]
        reg_9 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_10 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'ha == io_waddr) begin // @[demo.scala 168:23]
        reg_10 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_11 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'hb == io_waddr) begin // @[demo.scala 168:23]
        reg_11 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_12 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'hc == io_waddr) begin // @[demo.scala 168:23]
        reg_12 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_13 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'hd == io_waddr) begin // @[demo.scala 168:23]
        reg_13 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_14 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'he == io_waddr) begin // @[demo.scala 168:23]
        reg_14 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_15 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'hf == io_waddr) begin // @[demo.scala 168:23]
        reg_15 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_16 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h10 == io_waddr) begin // @[demo.scala 168:23]
        reg_16 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_17 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h11 == io_waddr) begin // @[demo.scala 168:23]
        reg_17 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_18 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h12 == io_waddr) begin // @[demo.scala 168:23]
        reg_18 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_19 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h13 == io_waddr) begin // @[demo.scala 168:23]
        reg_19 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_20 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h14 == io_waddr) begin // @[demo.scala 168:23]
        reg_20 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_21 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h15 == io_waddr) begin // @[demo.scala 168:23]
        reg_21 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_22 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h16 == io_waddr) begin // @[demo.scala 168:23]
        reg_22 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_23 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h17 == io_waddr) begin // @[demo.scala 168:23]
        reg_23 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_24 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h18 == io_waddr) begin // @[demo.scala 168:23]
        reg_24 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_25 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h19 == io_waddr) begin // @[demo.scala 168:23]
        reg_25 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_26 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h1a == io_waddr) begin // @[demo.scala 168:23]
        reg_26 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_27 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h1b == io_waddr) begin // @[demo.scala 168:23]
        reg_27 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_28 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h1c == io_waddr) begin // @[demo.scala 168:23]
        reg_28 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_29 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h1d == io_waddr) begin // @[demo.scala 168:23]
        reg_29 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_30 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h1e == io_waddr) begin // @[demo.scala 168:23]
        reg_30 <= io_wdata; // @[demo.scala 168:23]
      end
    end
    if (reset) begin // @[demo.scala 165:22]
      reg_31 <= 32'h0; // @[demo.scala 165:22]
    end else if (io_wen) begin // @[demo.scala 167:19]
      if (5'h1f == io_waddr) begin // @[demo.scala 168:23]
        reg_31 <= io_wdata; // @[demo.scala 168:23]
      end
    end
  end
endmodule
```
