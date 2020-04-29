# numpy 使用softfloat的方法

[TOC]

## 简述

numpy本身没有softfloat数据类型，但是numpy本身是一个类型无关的库，就像Eigen库一样，本身能够做到与数据类型无关（不得不说面向对象语言真好！！！），那么我们使用numpy结合softfloat库就能做到softfloat数据的矩阵运算

## softfloat

目前softfloat只有一个标准实现版本，即为Berkeley SoftFloat， 这是符合IEEE标准的一个softfloat库，Eigen库中包含了某一版本的softfloat. 这个库本身用C语言实现，符合ISO/ANSI C标准

官方网站[http://www.jhauser.us/arithmetic/SoftFloat.html](http://www.jhauser.us/arithmetic/SoftFloat.html)

github仓库[https://github.com/ucb-bar/berkeley-softfloat-3](https://github.com/ucb-bar/berkeley-softfloat-3)

## python接口的softfloat

目前有两个比较容易搜索到的python接口的softfloat库

- [sfpy](https://pypi.org/project/sfpy/)
- [softfloat](https://pypi.org/project/softfloat/)

这两个好坏不论（其实是没去细看）, 都可以使用，我安装的是sfpy，只是因为它的版本号看起来比softfloat大一些

## 代码展示

下面的代码展示了如何结合numpy完成softfloat16的矩阵点乘运算

```python
>>> m1_array = np.arange(12)
>>> m1_array = m1_array / 10
>>> m1_array = [sfpy.Float16(i) for i in m1_array]
>>> m1_array = np.array(m1_array).reshape(3,4)
>>> m1_array
array([[Float16(0.0), Float16(0.0999755859375), Float16(0.199951171875),
        Float16(0.300048828125)],
       [Float16(0.39990234375), Float16(0.5), Float16(0.60009765625),
        Float16(0.7001953125)],
       [Float16(0.7998046875), Float16(0.89990234375), Float16(1.0),
        Float16(1.099609375)]], dtype=object)
>>> m2_array = np.arange(20)
>>> m2_array = m2_array / 100
>>> m2_array = [sfpy.Float16(i) for i in m2_array]
>>> m2_array = np.array(m2_array).reshape(4,5)
>>> m2_array
array([[Float16(0.0), Float16(0.01000213623046875),
        Float16(0.0200042724609375), Float16(0.029998779296875),
        Float16(0.040008544921875)],
       [Float16(0.04998779296875), Float16(0.05999755859375),
        Float16(0.07000732421875), Float16(0.08001708984375),
        Float16(0.09002685546875)],
       [Float16(0.0999755859375), Float16(0.1099853515625),
        Float16(0.1199951171875), Float16(0.1300048828125),
        Float16(0.1400146484375)],
       [Float16(0.1500244140625), Float16(0.1600341796875),
        Float16(0.1700439453125), Float16(0.1800537109375),
        Float16(0.18994140625)]], dtype=object)
>>> res = np.dot(m1_array, m2_array)
array([[Float16(0.07000732421875), Float16(0.07598876953125),
        Float16(0.08203125), Float16(0.0880126953125),
        Float16(0.093994140625)],
       [Float16(0.18994140625), Float16(0.2120361328125),
        Float16(0.234130859375), Float16(0.256103515625),
        Float16(0.278076171875)],
       [Float16(0.31005859375), Float16(0.34814453125),
        Float16(0.385986328125), Float16(0.424072265625),
        Float16(0.4619140625)]], dtype=object)

>>> res_str = [hex(i.bits) for i in res.flatten()]
>>> res_str
['0x2c7b', '0x2cdd', '0x2d40', '0x2da2', '0x2e04', '0x3214', '0x32c9', '0x337e', '0x3419', '0x3473', '0x34f6', '0x3592', '0x362d', '0x36c9', '0x3764']

```

## 小实验

我们知道，numpy本身提供了np.float16数据类型，它内部的计算实际上还是float32,那么我们这么写确定是使用softfloat库中的float16进行计算的吗？

为了说明这个问题，我们自己写个小程序测试一下

写一个我们自定义的fp16,这个类似于sfpy中的封装方式,保存成 myfp.py

```python
class MyFp16():
    def __init__(self, val):
        self.val = val

    def __mul__(self, other):
        print("call mul......")
        return MyFp16(self.val * other.val)

    def __add__(self, other):
        print("call add......")
        return MyFp16(self.val + other.val)
```

采用命令行直接进行测试

```python
>>> import myfp as mp
>>> import numpy as np
>>> a=np.arange(5)
>>> a = a /10
>>> a = [mp.MyFp16(i) for i in a]
>>> np.array(a)
array([<myfp.MyFp16 object at 0x7fc4cb756390>,
       <myfp.MyFp16 object at 0x7fc4ab195d68>,
       <myfp.MyFp16 object at 0x7fc4ab195cf8>,
       <myfp.MyFp16 object at 0x7fc4ab195da0>,
       <myfp.MyFp16 object at 0x7fc4ab195e80>], dtype=object)
>>> a=_
>>> np.sum(a)
call add......
call add......
call add......
call add......
<myfp.MyFp16 object at 0x7fc4ab195cc0>

```

我们可以看到，实际上调用了__add__方法，并且结果为myfp.MyFp16 object 类型，
这样就能说明，实际上计算时是调用了softfloat进行计算的

## 计算结果对比

在对比计算结果时，发现numpy和softfloat计算的结果在直接使用乘法或者加法的时候完全一致，但使用np.sum或者np.dot时，结果不一致
对此，进行了进一步的测试

固定数组长度为10， calc0采用np.sum的计算方式，calc1采用直接相加的计算方式(为了以防万一，我们采用手动把10个数相加的方式),
分别测试

```python
import sfpy
import numpy as np
import misc

def calc0(llist):
    l0 = llist[0]
    new_list = llist[1:]
    for n in new_list:
        #n_sum = n[0] + n[1] + n[2] + n[3] + n[4] + n[5] + n[6] + n[7] + n[8] + n[9]
        n_sum = np.sum(n)
        l0 = l0 * n + n_sum
    return l0

def calc1(llist):
    l0 = llist[0]
    new_list = llist[1:]
    for n in new_list:
        n_sum = n[0] + n[1] + n[2] + n[3] + n[4] + n[5] + n[6] + n[7] + n[8] + n[9]
        #n_sum = np.sum(n)
        l0 = l0 * n + n_sum
    return l0

list_src = []
for i in range(12):
    list_src.append(misc.creat_matrix((10,)))

list_np = []
list_sfp = []
for src in list_src:
    list_np.append(np.array(src))
    list_sfp.append(np.array([sfpy.float.Float16(i) for i in src]))

np0 = calc0(list_np)
sfp0 = calc0(list_sfp)

np1 = calc1(list_np)
sfp1 = calc1(list_sfp)

np_res = [hex(misc.half_to_u16(i)) for i in np0]
print("numpy result use np.sum: ", np_res)

np_res = [hex(misc.half_to_u16(i)) for i in np1]
print("numpy result use +: ", np_res)

sfp_res = [hex(i.bits) for i in sfp0]
print("softfloat result use np.sum: ", sfp_res)

sfp_res = [hex(i.bits) for i in sfp1]
print("softfloat result use +: ", sfp_res)
```

计算结果为

```shell
numpy result use np.sum:  ['0xbabe', '0xbba3', '0xbd50', '0xbcca', '0xb8f5', '0xbc3a', '0xbbf7', '0xbc3c', '0xbc17', '0xbbc5']
numpy result use +:  ['0xbabf', '0xbba4', '0xbd51', '0xbccb', '0xb8f6', '0xbc3a', '0xbbf8', '0xbc3c', '0xbc18', '0xbbc6']
softfloat result use np.sum:  ['0xbabf', '0xbba4', '0xbd51', '0xbccb', '0xb8f6', '0xbc3a', '0xbbf8', '0xbc3c', '0xbc18', '0xbbc6']
softfloat result use +:  ['0xbabf', '0xbba4', '0xbd51', '0xbccb', '0xb8f6', '0xbc3a', '0xbbf8', '0xbc3c', '0xbc18', '0xbbc6']

```

我们可以看出，对于softfloat来讲，无论是使用np.sum还是采用直接相加的方式，结果不变；但对于numpy的内建数据类型np.float16来讲，在使用np.sum和直接相加这两种方式时，计算结果会有不同。

除此之外，np.float16直接操作的结果和softfloat操作的结果是比特一致的(为什么呢？)

那么，至少我们能够确定，问题出在numpy内建数据类型的计算上，并不是softfloat本身存在问题，至于为什么numpy的内建数据类型会呈现出这种结果，后续看一些numpy源码才能知晓
