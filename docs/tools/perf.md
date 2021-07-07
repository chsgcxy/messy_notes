# linux性能统计工具使用总结

最近在优化gem5的运行速度，用到了linux的perf工具，并且生成了火焰图。
特此记录一个过程中遇到的问题，方便后续再遇到类似问题的解决。

## 步骤

### perf安装

[linux-perf文档](http://www.brendangregg.com/index.html)

上面链接包含了perf所有的介绍，包括perf的安装方法，这里使用源码安装的方式进行安装,在building章节中有源码安装的方式，
思路是通过apt来下载对应系统的内核源码，在内核源码的tools/perf目录下保存了perf的源码，make并且make install即可，需要
注意的是一般源码会安装在/usr/src/目录下，所以需要sudo权限

### perf生成record

使用 perf record命令来记录下程序的运行log，这里参考了外国友人的笔记

[外国友人的笔记](https://gist.github.com/df31787c41bd50c0fe223df07cf6eb89.git)

核心命令为

```shell
perf record --call-graph dwarf,16384 -e cpu-clock -F 997 target/release/name-of-binary <command-line-arguments>
```

当然我在使用的时候发现perf record -g target/release/name-of-binary 是可用的，其他参数还需要逐个确认

#### 权限问题

因为我编译的时候使用了sudo权限，也没有把perf权限开放给普通用户，所以这里执行的时候也要sudo。直接通过apt-get安装的perf不需要加sudo

#### 路径问题

target/release/name-of-binary 需要写绝对路径或者加./来解决

#### perf_event_paranoid问题

如果提示需要修改perf_event_paranoid，可以通过提示的方式进行永久性修改，也可以通过如下方式查看和修改

```shell
sysctl -n kernel.perf_event_paranoid
sudo sysctl -w kernel.perf_event_paranoid=-1
```

### 解析成火焰图

首先要安装 flamegraph

```shell
git clone https://github.com/brendangregg/FlameGraph
```

需要把FlameGraph中的所有pl文件加入到环境PATH中，可以把这个加入到用户目录的profile中

```shell
cd FlameGraph
echo "PATH=/path/to/FlameGraph:$PATH" >> .profile
source .profile
```

老版本还需要加入一个转换工具

[转换工具](https://github.com/Yamakaky/rust-unmangle.git)

```shell
git clone https://github.com/Yamakaky/rust-unmangle.git
cd rust-unmangle
chmod u+x rust-unmangle
echo "PATH=/path/to/rust-unmangle:$PATH" >> .profile
source .profile
```

生成火焰图

```shell
perf script | stackcollapse-perf.pl | stackcollapse-recursive.pl | c++filt | rust-unmangle | flamegraph.pl > flame.svg
```

如果遇到ERROR： No stack counts found的错误
修改当前目录下生成的perf.data的权限

```shell
sudo chown -R root:root perf.data
sudo perf script | stackcollapse-perf.pl | stackcollapse-recursive.pl | c++filt | rust-unmangle | flamegraph.pl > flame.svg
```

这样就可以根据火焰图来分析程序哪里比较耗时了

## 遇到的其他问题

### 内核符号unknow

实际上我们在分析CPU占用型软件性能时，一般也不需要内核符号，但如果想要看到，那么需要修改kptr_restrict

### app的函数行为无法记录

现象为最终生成的火焰图只有程序名，没有程序中的函数名。通过熟悉perf record的命令参数，发现-b能够解决此问题

### 符号被修改

现象为最终生成的火焰图符号被修改，通过readelf查看生成的可执行文件，发现符号本身就是被修改的，被困扰了半天之后才明白，这是c++的name mangling机制，用来解决重载问题。
实际上如果对C++理解比较多的人应该都知道这个，我半路出家还真是头一次知道。于是发现c++filt可以有效demangling这些符号，在perf script中加入c++filt即可。

## 总结

这篇记录里大多数的操作都是网上查到的，我只是记录了一下而已。而且perf这个分析方法也是同事告诉我的，
其实我只是一个实施者，但从中应该学到的是如何快速的掌握一个工具使用方法的能力。应该提高的是查资料的能力。

## perf 统计cache miss情况

```shell
perf stat -e L1-dcache-load-misses -e L1-dcache-loads -e LLC-load-misses  -e  LLC-loads -e LLC-store-misses -e LLC-stores -e dTLB-load-misses -e dTLB-loads -e dTLB-store-misses -e dTLB-stores ./randomstream
```

统计结果

```text
 Performance counter stats for './randomstream':
    14,489,916,426      L1-dcache-load-misses     #   16.83% of all L1-dcache hits    (39.98%)
    86,081,655,549      L1-dcache-loads                                               (39.99%)
     2,633,551,306      LLC-load-misses           #   40.63% of all LL-cache hits     (40.01%)
     6,482,329,778      LLC-loads                                                     (40.02%)
     1,730,604,712      LLC-store-misses                                              (20.00%)
     3,079,201,774      LLC-stores                                                    (20.00%)
       244,280,338      dTLB-load-misses          #    0.28% of all dTLB cache hits   (30.00%)
    86,066,948,345      dTLB-loads                                                    (40.00%)
     1,414,326,484      dTLB-store-misses                                             (39.99%)
    45,374,302,611      dTLB-stores                                                   (39.98%)

      19.019721004 seconds time elapsed

     282.336445000 seconds user
     818.115020000 seconds sys
```
