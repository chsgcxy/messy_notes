# 符号扩展

在spike中，有一个符号扩展和非符号扩展函数，仔细想会挺有意思。有一种代码写多了，反而不会写了的感觉。

```c++
typedef uint64_t insn_bits_t;

class insn_t
{
private:
  insn_bits_t b;
  uint64_t x(int lo, int len) { return (b >> lo) & ((insn_bits_t(1) << len)-1); }
  uint64_t xs(int lo, int len) { return int64_t(b) << (64-lo-len) >> (64-len); }
};
```

x用来截取无符号立即数，xs用来截取有符号立即数， &是无法处理有符号数的，但位移能够让编译器采取有符号的处理方式，
当然这里的xs中如果不进行int64_t强制转换，那么就变成处理无符号立即数了
