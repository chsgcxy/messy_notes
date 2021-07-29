# 如何写一个又高效又美观的reverse

写一个又高效又美观的byte reverse

```c++
#include <iostream>

template <int N>
inline void reverse(uint8_t *a, uint8_t *b)
{
    *a = *b;
    reverse<N - 1>(a + 1, b - 1);
}

template <>
inline void reverse<1>(uint8_t *a, uint8_t *b)
{
    *a = *b;
}

int main()
{
    uint64_t tmp = 0x1234567890abcdef;
    uint64_t b;

    reverse<8>((uint8_t *)&b, (uint8_t *)&tmp + 7);

    std::cout << "a = 0x" << std::hex << tmp << " b = 0x" << std::hex << b << std::endl;
    return 0;
}

```
