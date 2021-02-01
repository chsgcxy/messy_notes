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

因为我编译的时候使用了sudo权限，也没有把perf权限开放给普通用户，所以这里执行的时候也要sudo

#### 路径问题

target/release/name-of-binary 需要写绝对路径，相对路径会导致问题，或者需要把程序export到PATH中，当然这个方法我没试过

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

## 总结

这篇记录里大多数的操作都是网上查到的，我只是记录了一下而已。而且perf这个分析方法也是同事告诉我的，
其实我只是一个实施者，但从中应该学到的是如何快速的掌握一个工具使用方法的能力。应该提高的是查资料的能力。
