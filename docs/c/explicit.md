# C++中的explicit

explicit关键字在c++中用于修饰*构造函数*，用来禁止隐式类型转换或隐式构造函数调用。当使用explicit修饰构造函数时，该构造函数将不能用于隐式类型转换，只能通过显式调用构造函数来进行对象的初始化。

## 隐式类型转换

在c++中，如果一个类的构造函数仅包含一个参数，那么在某些情况下，*编译器*会自动的使用这个构造函数进行隐式类型转换。

```c++
class float16 {
public:
  float16() : value(0) {}
  explicit float16(uint16_t raw) : value(raw) {}
  uint16_t value;
};

void dump_float16(const float16 &f16)
{
    std::cout << std::hex << f16.value << std::endl;
}

int main()
{
    dump_float16(0x3c00);
    return 0;
}

```

会有如下打印

```
123.cc: In function ‘int main()’:
123.cc:17:18: error: invalid initialization of reference of type ‘const float16&’ from expression of type ‘int’
   17 |     dump_float16(0x3c00);
      |                  ^~~~~~
123.cc:10:34: note: in passing argument 1 of ‘void dump_float16(const float16&)’
   10 | void dump_float16(const float16 &f16)
      |                   ~~~~~~~~~~~~~~~^~~
```

如果我们把explicit去掉，则可以编译通过，编译器将int类型的0x3c00转换为uint16_t，再利用float16的构造函数构造float16实例，传入dump_float16的函数。但这个行为可能不是我们想要的，是编写错误。

## 总结

当一个构造函数只有一个参数的时候，并且不希望这个参数被隐式转换成类的对象，需要使用explicit。当构造函数有多个参数的时候，explicit是没有意义的，因为这时不可能发生这个类的隐式类型转换。不使用explicit，可能代码中的隐式类型转换也不会导致代码出现错误，但开发者必须对这个行为是有意识的，在需要的地方适当的添加explicit是个好习惯。
