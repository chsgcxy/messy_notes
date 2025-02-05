# C及C++的默认数据类型转换在模拟器中的应用

在模拟器开发过程中，难免会遇到一些数据类型转换。一般情况下，我们更擅长于写明确的（显式的）数据类型转换，这也让我们忽略了编译器对数据类型转换的默认处理。有些情况下，代码会写的丑陋甚至出错。
还有一些情况下，我们对于强制类型转换出来数据到底是多少会有疑问。
最近在调试自研RISCV core时，发现riscv-isa-sim中的一些实现就涉及到这两种情况，特此记录。

## 示例1

vs2 要想转换成uint16_t，需要先转换成uint8_t. 不然的话会直接符号扩展成int16_t再转换成uint16_t

```c++
    int16_t vd_w = P.VU.elt<int16_t>(rd_num, i);
    int8_t vs1 = P.VU.elt<int8_t>(rs1_num, i);
    int8_t vs2 = P.VU.elt<int8_t>(rs2_num, i);
    P.VU.elt<uint16_t>(rd_num, i, true) = +((uint16_t)(uint8_t)vs2 * (int16_t)(int8_t)vs1) + vd_w;
```

## 示例2

通过op_mask的运算，使得vs2既转换成了uint128_t的类型，又仅截取了sew bit.

```c++
const uint128_t op_mask = (UINT64_MAX >> (64 - sew));
auto vs2 = P.VU.elt<int16_t>(rs2_num, i);
auto rs1 = (int16_t)RS1;
auto simm5 = (int16_t)insn.v_simm5();
uint128_t res = (((op_mask & simm5) + (op_mask & vs2)) >> sew) & 0x1u;
```

## 总结

当不同的数据类型做运算时，编译器为了提高计算的精度，会进行数据类型的自动转换。

- 整数提升: 如果操作数的类型小于int（char, short），则它们首先会被提升为int或unsigned int。具体取决于这些类型是否有符号以及 int是否能够表示其所有值。
- 操作数类型匹配: 如果两个操作数都是有符号的或都是无符号的,并且它们的类型不同,则较小类型的操作数会被转换为较大类型的操作数。
- 有符号与无符号混合: 如果一个操作数是有符号的而另一个是无符号的,并且它们的类型大小相同(如signed int和unsigned int),那么有符号整数会被转换为无符号整数。如果类型大小不同,则根据以下规则进行转换:
    - 如果有符号类型能够表示无符号类型的所有值,则无符号类型被转换为有符号类型。
    - 否则,两个操作数都会被转换为无符号类型的相应更大的整数类型。(例如char或short),则它们首先会被提升为int或unsigned int。具体取决于这些类型

```c++
uint16_t a = uint16_t(0xffa0);
int16_t b = int16_t(a);
int64_t c = int64_t(a);
uint64_t d = uint64_t(b);

std::cout << std::dec << a << std::endl;
std::cout << std::dec << b << std::endl;
std::cout << std::dec << c << std::endl;
std::cout << std::dec << d << std::endl;
```

看上面这一段代码。a和b是同宽度的，所以强制转换，内存值不变。uint16_t 转 int64_t 时，uint16_t的值首先转换成uint64_t,然后再转换成int64_t。int16_t 转 uint64_t时， int16_t 先符号扩展转换成int64_t, 再转换成 uint64_t。
