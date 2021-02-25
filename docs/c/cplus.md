# C++操作符重载

[TOC]

## operator-reload

```c++
#include <iostream>

class obj {
  public:

    void say_hello(void) const
    {
        std::cout << "hello world" << std::endl;
    }
};

class Test {
  public:

    obj* _obj;

    Test(obj *p): _obj(p) {};

    inline const obj* operator->() const {
        return _obj;
    }

    inline bool operator <= (const Test& a) {
        std::cout << "op <=" << std::endl;
        return 1;
    }
};

int main(void)
{
    obj o1;
    Test a(&o1);

    a->say_hello();
    const obj *b = a.operator->();
    bool val = (a <= a);
    a.operator<=(a);
    b->say_hello();

    return 0;
}
```
