# 使用llvm-symbolizer查找符号

https://llvm.org/docs/CommandGuide/llvm-symbolizer.html

llvm-symbolizer可以用来根据PC值查找到对应的函数和该函数所在文件

## 意义

记录这个的意义在于，它从侧面印证了一个很久以来的感悟：

善于使用既有工具解决遇到的问题是一种能力。虽然之前没有像使用gcc一样去频繁使用llvm，
但面对“需要根据当前PC值知道目前所执行的函数信息”这个问题的时候，首先想到的应该就是
从工具链中寻找对应的解决方案。

当然，使用工具的能力也需要一定的知识储备，比如正是因为之前研究过elf文件格式，研究过内核加载ko模块的详细流程，
频繁的使用工具链对目标文件做一系列转换，才能深入的理解工具链中的一些工具，才能举一反三的想到去工具链中找到
解决方案。

## 举一反三

很显然，gcc里面肯定也有类似工具，通过名字观察addr2line很像，
查看说明，显然是类似的工具

```shell
riscv32-unknown-elf-addr2line -h
Usage: riscv32-unknown-elf-addr2line [option(s)] [addr(s)]
 Convert addresses into line number/file name pairs.
 If no addresses are specified on the command line, they will be read from stdin
 The options are:
  @<file>                Read options from <file>
  -a --addresses         Show addresses
  -b --target=<bfdname>  Set the binary file format
  -e --exe=<executable>  Set the input file name (default is a.out)
  -i --inlines           Unwind inlined functions
  -j --section=<name>    Read section-relative offsets instead of addresses
  -p --pretty-print      Make the output easier to read for humans
  -s --basenames         Strip directory names
  -f --functions         Show function names
  -C --demangle[=style]  Demangle function names
  -R --recurse-limit     Enable a limit on recursion whilst demangling.  [Default]
  -r --no-recurse-limit  Disable a limit on recursion whilst demangling
  -h --help              Display this information
  -v --version           Display the program's version
```

尝试分析一下

```shell
chsgcxy@chsgcxy-TM1703:~/workspace$ riscv32-unknown-elf-addr2line -e verification/bert.out -f 0x9532
_ZN7stc_dnn7bert_op25embeddings_postproc_slaveILi8ELi8EEEvv
/data/workspace/gem5/gem5/verification/stc-dnn/test/bert/../../include/ops/bert/bert_forward.h:6726
```

显然需要demangling c++的符号，再次尝试

```shell
chsgcxy@chsgcxy-TM1703:~/workspace$ riscv32-unknown-elf-addr2line -e verification/bert.out -f 0x9532 | c++filt 
void stc_dnn::bert_op::embeddings_postproc_slave<8, 8>()
/data/workspace/gem5/gem5/verification/stc-dnn/test/bert/../../include/ops/bert/bert_forward.h:6726
```

成功了，对比一下llvm工具的输出结果

```shell
chsgcxy@chsgcxy-TM1703:~/workspace$ llvm-symbolizer --obj=verification/bert.out 0x9532
void stc_dnn::bert_op::embeddings_postproc_slave<8, 8>()
/data/workspace/gem5/gem5/verification/stc-dnn/test/bert/../../include/ops/bert/bert_forward.h:6726:49
```
