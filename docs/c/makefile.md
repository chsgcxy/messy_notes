# makefile语法

## 基本写法

> 需要注意的是， 每一行commands在一个单独的shell进程中，这些shell之间没有任何继承关系

```makefile
<target> : <prerequisites> 
[tab]  <commands>
```

比如下面的例子的运行结果为：MY_PATH=[]

```makefile
mytarget:
    export MY_PATH=aaabbbccc
    echo "MY_PATH=[$$MY_PATH]"
```

下面的例子的运行结果为：MY_PATH=[aaabbbccc]

```makefile
mytarget:
    export MY_PATH=aaabbbccc; \
    echo "MY_PATH=[$$MY_PATH]"
```

思考一下， 为什么要写成$$MY_PATH, $(MY_PATH) 能打印出来吗？这里可以参考如下文章的解释，实质上makefile会先去解释第一个$,而shell会去解释第二个$,如果只有一个$, make 会因为找不到变量MY_PATH而终止，因为MY_PATH是定义在shell中的。

https://blog.csdn.net/darennet/article/details/8185881

## 基本语法

### 直接式变量赋值与递归式变量赋值

```makefile
# 递归式变量赋值,make会将整个makefile展开后，再决定变量的值
algo = gzip.o lzma.o

# 直接式变量赋值，变量的值决定于它在makefile中的位置
algo := gzip.o lzma.o
```

举个例子就能说明区别

```makefile
_algo = gzip
algo := $(_algo)
_algo = lzma

test:
        @echo "algo=$(algo)"
```

输出应该为gzip,也就是说在定义的时候就展开了

```makefile
_algo = gzip
algo = $(_algo)
_algo = lzma

test:
        @echo "algo=$(algo)"
```

输出应该为lzma,将整个makefile展开后才确定了_algo的值，进而确定了algo的值

### 打印回显

```makefile
# 正常情况下make 会打印每一条命令然后再执行，使用@可以阻止回显
    echo "hello world!"
    @echo "hello world!"
```

### 其他赋值

> 只有在变量未被赋值时才赋值

```makefile
# 条件赋值
algo ?= lzma

# 增量式赋值
algo += gzip
```

### 使用函数

```makefile
return = $(functionname arg1, arg2, arg3...)
```

### 扩展通配符wildcard

```makefile
# * 表示任意一个或多个字符
# ? 表示任意一个字符
# [...]  [abc] 表示abc中任意一个字符匹配， [^abc]表示除abc意外的字符
# [0-9] 表示0~9任意一个数字
algo = $(wildcard *.c)

test:
        @echo "algo=$(algo)"
```

假如在Makefile所在的目录下有lzma.c, gzip.c, bzip2.c, xz.c, lzo.c 那么algo会打印出所有的这些.c文件名称

### 匹配替代通配符patsubst

```makefile
# % 为模式字符
algo = $(patsubst %.c,%.o,$(wildcard *.c))
test:
        @echo "algo = $(algo)"
```

### 去除路径notdir

```makefile
OBJS = /usr/opt/bin/algo.c
algo = $(notdir $(OBJS))

test:
        @echo "algo = $(algo)"
```

运行结果

```makefile
root@chlxy:# make
algo = algo.c
```

### 字符串替换subst

```makefile
string_old = AAAAABBBBBCCCCC
string_new = $(subst A,a,$(string_old))

test:
        @echo "new string is $(string_new)"
```

运行结果,其中需要注意，如果在上述A,a,后面加空格再加$(string_new)会导致输出中带有空格

```makefile
root@chlxy:# make
new string is aaaaaBBBBBCCCCC
```

### 过滤函数filter

```makefile
string_old = AAAAA.c BBBBB.o CCCCC.s
string_new = $(filter %.o, $(string_old))

test:
        @echo "new string is $(string_new)"
```

运行结果

```shell
root@chlxy:# make
new string is BBBBB.o
```

### 循环函数 foreach

```makefile
algos = lzma gzip lzo lz4 xz
algofiles = $(foreach algo, $(algos), $(algo).c)

test:
        @echo "$(algofiles)"
```

运行结果

```shell
root@chlxy:# make
 lzma.c  gzip.c  lzo.c  lz4.c  xz.c
```

### 显式运行shell

```makefile
algos = $(shell ls)

test:
        @echo "$(algos)"
```

运行结果

```shell
root@chlxy:# make
bzip2.c gzip.c lz4.c lzma.c lzo.c Makefile xz.c
```

### 运行控制 error 与 warning

```makefile
ifndef ARCH
$(error should define ARCH...)
endif

ifndef PLAT
$(warning forget define PLAT ?)
endif

test:
        @echo "this is a test"
```

运行结果

```shell
root@chlxy:# make
Makefile:3: *** should define ARCH...。 停止。
root@chlxy:# make ARCH=arm
Makefile:7: forget define PLAT ?
this is a test
root@chlxy:# make ARCH=arm PLAT=yes
this is a test
```

### 其他函数

```text
# 函数太多，具体使用方法就不再一一举例了

# 将字符串升序排列，并去掉重复单词
sort

# 取单词函数
word

# 取字符串函数
wordlist

# 统计字符串中单词数目
words

# 取字符串的第一个单词，lastword同理取最后一个单词
firstword

# 取目录，包含指定文件的路径目录
dir

# 取前缀函数
basename

# 实现用户自定义函数的引用，$(call function arg1,arg2,...)
call
```

### 条件判断

```makefile
# ifeq ifneq ifdef ifndef

ifeq ($(ARCH), arm)
        MY_ARCH = ARCH_ARM
else ifeq ($(ARCH), arm64)
        MY_ARCH = ARCH_ARM_64
else
        MY_ARCH = unknown
endif

ifdef PLAT
        MY_PLAT = nxp
else
        MY_PLAT = unknown
endif

test:
        @echo "MY_ARCH = $(MY_ARCH) MY_PLAT=$(MY_PLAT)"
```

运行结果

```shell
root@chlxy:# make ARCH=arm
MY_ARCH = ARCH_ARM MY_PLAT=unknown
root@chlxy:# make ARCH=arm PLAT=yes
MY_ARCH = ARCH_ARM MY_PLAT=nxp
root@chlxy:# make ARCH=arm64
MY_ARCH = ARCH_ARM_64 MY_PLAT=unknown
```
