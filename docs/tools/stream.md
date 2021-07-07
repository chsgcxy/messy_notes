# 评估DDR通道数

整体思路：获取实际的峰峰值总带宽T，按照DDR型号及频率，确认单通道带宽t，channel数 = T/t

获取峰峰值带宽使用[jeffhammond/STREAM](https://github.com/jeffhammond/STREAM)
[stream官方文档](https://www.cs.virginia.edu/stream/)
[网友对于stream的解读](https://zhuanlan.zhihu.com/p/147658532)
获取DDR型号及频率，使用 dmidecode --type memory 命令

## 获取峰峰值带宽

### 确认工具能够正常运行

```shell
git clone https://github.com/jeffhammond/STREAM.git
cd STREAM
make stream_c.exe
./stream_c.exe
```

### 获取测试机L3 Cache的大小

方法一：

```text
~/workspace$ getconf -a | grep CACHE
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

方法二：

sudo dmidecode -t cache

方法三：

lscpu

### 根据L3 Cache大小修改STREAM_ARRAY_SIZE

可以直接修改stream.c中的STREAM_ARRAY_SIZE，也可以在make的时候
-DSTREAM_ARRAY_SIZE 来进行修改

STREAM_ARRAY_SIZE = LEVEL3_CACHE_SIZE * 4

因为L3 Cache获取到的是28MB, 那么STREAM_ARRAY_SIZE设置为120MB比较合适

### 再次编译运行stream

```text
-------------------------------------------------------------
STREAM version $Revision: 5.10 $
-------------------------------------------------------------
This system uses 8 bytes per array element.
-------------------------------------------------------------
Array size = 120000000 (elements), Offset = 0 (elements)
Memory per array = 915.5 MiB (= 0.9 GiB).
Total memory required = 2746.6 MiB (= 2.7 GiB).
Each kernel will be executed 10 times.
 The *best* time for each kernel (excluding the first iteration)
 will be used to compute the reported bandwidth.
-------------------------------------------------------------
Number of Threads requested = 80
Number of Threads counted = 80
-------------------------------------------------------------
Your clock granularity/precision appears to be 1 microseconds.
Each test below will take on the order of 31161 microseconds.
   (= 31161 clock ticks)
Increase the size of the arrays if this shows that
you are not getting at least 20 clock ticks per test.
-------------------------------------------------------------
WARNING -- The above is only a rough guideline.
For best results, please be sure you know the
precision of your system timer.
-------------------------------------------------------------
Function    Best Rate MB/s  Avg time     Min time     Max time
Copy:           44672.0     0.055925     0.042980     0.101943
Scale:          50632.9     0.046314     0.037920     0.062966
Add:            57618.5     0.056867     0.049984     0.069840
Triad:          57517.2     0.060273     0.050072     0.096959
-------------------------------------------------------------
Solution Validates: avg error less than 1.000000e-13 on all three arrays
-------------------------------------------------------------

```

## 获取DDR型号及频率

```text
sudo dmidecode -t memory

# dmidecode 3.1
Getting SMBIOS data from sysfs.
SMBIOS 3.2 present.
# SMBIOS implementations newer than version 3.1.1 are not
# fully supported by this version of dmidecode.

Handle 0x1000, DMI type 16, 23 bytes
Physical Memory Array
    Location: System Board Or Motherboard
    Use: System Memory
    Error Correction Type: Multi-bit ECC
    Maximum Capacity: 7680 GB
    Error Information Handle: Not Provided
    Number Of Devices: 24

Handle 0x1100, DMI type 17, 84 bytes
Memory Device
    Array Handle: 0x1000
    Error Information Handle: Not Provided
    Total Width: 72 bits
    Data Width: 64 bits
    Size: 32 GB
    Form Factor: DIMM
    Set: 1
    Locator: A1
    Bank Locator: Not Specified
    Type: DDR4
    Type Detail: Synchronous Registered (Buffered)
    Speed: 2666 MT/s
    Manufacturer: 00CE00B300CE
    Serial Number: 41137A10
    Asset Tag: 02184251
    Part Number: M393A4K40CB2-CTD
    Rank: 2
    Configured Clock Speed: 2666 MT/s
    Minimum Voltage: 1.2 V
    Maximum Voltage: 1.2 V
    Configured Voltage: 1.2 V
```

DDR规格容量及传输速度对照表

DDR规格 | 容量 | 传输带宽
--- | --- | ---
DDR  | 266 | 2.1 GB/s
DDR  | 333 | 2.6 GB/s
DDR  | 400 | 3.2 GB/s
DDR2 |  533 | 4.2 GB/s
DDR2 |  667 | 5.3 GB/s
DDR2 |  800 | 6.4 GB/s
DDR3 |  1066 | 8.5 GB/s
DDR3 |  1333 | 10.6 GB/s
DDR3 |  1600 | 12.8 GB/s
DDR3 |  1866 | 14.9 GB/s
DDR4 |  2133 | 17 GB/s
DDR4 |  2400 | 19.2 GB/s
DDR4 |  2666 | 21.3 GB/s
DDR4 |  3200 | 25.6 GB/s

## 计算通道数

57 // 21 = 3
