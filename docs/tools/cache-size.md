# cache大小测试工具

这里记录一个cache大小测试工具，似乎不太可靠，但其中使用到的C++特性和思路可以参考

## code

```c++
#include <iostream>
#include <string>
#include <vector>
#include <random>

#define KB(x) ((size_t)(x) << 10)

int main()
{
    std::vector<std::size_t> sizes_kb;

    for (int i = 18; i < 28; i++)
        sizes_kb.push_back(1 << i);

    std::random_device rd;
    std::mt19937 gen(rd());

    for (std::size_t size : sizes_kb) {
        std::uniform_int_distribution<> dis(0, KB(size) - 1);
        std::vector<uint64_t> memory(KB(size));
        std::fill(memory.begin(), memory.end(), 1);

        int dummy = 0;
        clock_t begin = clock();
        for (int i = 0; i < (1 << 25); i++)
            dummy += memory[dis(gen)];
        clock_t end = clock();

        double elapsed_secs = double(end - begin) / CLOCKS_PER_SEC;
        std::cout << size << " KB, " << elapsed_secs << "secs, dummy:" << dummy << std::endl;
    }
}
```

## result

```text
~/workspace$ ./a.out
2 KB, 1.39024secs, dummy:33554432
4 KB, 1.36546secs, dummy:33554432
8 KB, 1.37217secs, dummy:33554432
16 KB, 1.37657secs, dummy:33554432
32 KB, 1.34883secs, dummy:33554432
64 KB, 1.37071secs, dummy:33554432
128 KB, 1.42015secs, dummy:33554432
256 KB, 1.52487secs, dummy:33554432
512 KB, 1.56197secs, dummy:33554432
1024 KB, 1.62009secs, dummy:33554432
2048 KB, 1.74029secs, dummy:33554432
4096 KB, 2.29474secs, dummy:33554432
8192 KB, 3.00552secs, dummy:33554432
16384 KB, 3.54919secs, dummy:33554432
32768 KB, 3.84491secs, dummy:33554432
65536 KB, 4.35051secs, dummy:33554432
131072 KB, 4.32022secs, dummy:33554432
```

```shell
yankexin@sophgo1:~/workspace$ getconf -a | grep CACHE
LEVEL1_ICACHE_SIZE                 32768
LEVEL1_ICACHE_ASSOC                8
LEVEL1_ICACHE_LINESIZE             64
LEVEL1_DCACHE_SIZE                 32768
LEVEL1_DCACHE_ASSOC                8
LEVEL1_DCACHE_LINESIZE             64
LEVEL2_CACHE_SIZE                  1048576
LEVEL2_CACHE_ASSOC                 16
LEVEL2_CACHE_LINESIZE              64
LEVEL3_CACHE_SIZE                  28835840
LEVEL3_CACHE_ASSOC                 11
LEVEL3_CACHE_LINESIZE              64
LEVEL4_CACHE_SIZE                  0
LEVEL4_CACHE_ASSOC                 0
LEVEL4_CACHE_LINESIZE              0
```

## 总结

没有明显的结论
