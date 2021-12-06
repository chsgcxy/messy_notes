# rocket chip分析

[https://github.com/chipsalliance/rocket-chip](https://github.com/chipsalliance/rocket-chip)

> Rocket Chip is a design generator, capable of producing many design instances from a single high-level source

rocket chip项目不仅实现了rocket chip的SOC，还可以作为函数库来使用,准确来讲，Rocket Chip是一个开源的SOC可综合RTL生成器。内部实现了基于RISCV架构的顺序Core(Rocket)和乱序Core(BOOM)。目前Rocket Chip已经 taped out 11次，稳定性得到了肯定。

通过github的README可以轻松找到Rocket的相关文档说明

## repo结构

随着模块化的发展，Rocket Chip的许多组件库成为了独立的repo, Rocket Chip采用git submodules来包含这些模块的可信版本

### 顶层目录结构

```text
├── bootrom    启动romcode
├── build.sbt  构建脚本
├── emulator   用于存放verilator生成的模拟器，其中的Makefile提供了生成方法
├── hardfloat  浮点单元submodule
├── macros
├── project    sbt编译运行专用目录
├── regression 回归测试脚本,使用scala test的测试脚本
├── scripts    一些有用的小工具
├── src        生成器存放目录
├── target     sbt专用目录
├── torture    riscv-torture随机指令测试框架
└── vsim       Synopsys VCS simulations are compiled and run， 需要VCS环境
```

### 生成器目录结构

```text
.
├── amba                    包含ahb,apb,axi4等AMBA总线协议
├── aop
├── aspects
├── devices                 包含了debug模块以及一些物理设备
├── diplomacy
├── diplomaticobjectmodel
├── examples
├── formal
├── groundtest
├── interrupts
├── jtag                    JTAG 总线接口
├── linting
├── package.scala
├── prci
├── regmapper
├── rocket                   Rocket Core的生成器，包含alu btb ...等的生成器实现
├── scie
├── stage
├── subsystem
├── system                   配置文件(组装文件)
├── tile                     组件，FPU, ROCC等组件
├── tilelink                 TileLink协议以及适配器和协议转换器
├── transforms
├── unittest                 可综合的硬件测试框架
└── util                     大量的可复用的小模块
```

## 环境搭建

```shell
git clone https://github.com/ucb-bar/rocket-chip.git
cd rocket-chip
export ROCKETCHIP=`pwd`
git submodule update --init --recursive
export RISCV=/path/to/install/riscv/toolchain #riscv工具链安装目录
```

rocket-tools 是软件集合，可以选择自己单独搭建也可以选择直接使用这个repo,由于我的本地已经有riscv-tools,直接使用其中的riscv-tests生成的测试case也能进行emulator的测试

编译C++模拟器,生成的默认的elf为：emulator-freechips.rocketchip.system-freechips.rocketchip.system.DefaultConfig

```shell
cd emulator
make -jN
```

编译VCS模拟器，由于没有vcs环境，暂时无法生成

```shell
cd vsim
make -jN
```

生成verilog,默认的verilog为：freechips.rocketchip.system.DefaultConfig.v

```shell
cd vsim
make verilog
```

## Rocket Core

