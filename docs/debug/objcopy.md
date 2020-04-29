# objcopy

[TOC]

在使用objcopy的过程中，发现-j选项只能提取WA flag的段（具体还需要进一步确认，只是因为我增加了wa flag属性就能够提取了）， 特此记录一下

---

我在代码中自定义了一个段，汇编代码如下：

```S
    .section .ddrdata
    .align 8
ddrdata:
    .dword 0x2debba328c9d8d5c, 0x3b87beaeebcf3a2b
    .dword 0x28a10827080f6e69, 0x1793c3b898462757
```

在链接时，做了如下处理

```lds
  . = 0x10000;
  .scdata : { *(.ddrdata) }
```

于是生成的elf文件，截取部分readelf信息如下

```shell
output$ riscv32-unknown-elf-readelf -S test
There are 11 section headers, starting at offset 0x7630:

节头：
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 3] .data             PROGBITS        00002000 003000 000610 00  WA  0   0 256
  [ 4] .scdata           PROGBITS        00010000 003700 000400 00      0   0 256
  [10] .shstrtab         STRTAB          00000000 0075d0 00005f 00      0   0  1
```

我发现当我使用如下命令提取scdata段时，得到的文件为空

```shell
output$ riscv32-unknown-elf-objcopy -O binary -j .scdata test 111.bin
output$ ll 111.bin 
-rwxr-xr-x 1 chsgcxy chsgcxy 0 3月  12 15:08 111.bin*
```

于是尝试提取.data段，发现是可以提取的，那就想是不是因为data段有WA flag，所以可以提取呢，
把自定义段添加wa标记试一下

```S
    .section .ddrdata,"aw"
    .align 8
ddrdata:
    .dword 0x2debba328c9d8d5c, 0x3b87beaeebcf3a2b
    .dword 0x28a10827080f6e69, 0x1793c3b898462757
```

再次查看生成的elf文件

```shell
output$ riscv32-unknown-elf-readelf -S test
There are 11 section headers, starting at offset 0x7630:

节头：
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 3] .data             PROGBITS        00002000 003000 000610 00  WA  0   0 256
  [ 4] .scdata           PROGBITS        00010000 003700 000400 00  WA  0   0 256
  [10] .shstrtab         STRTAB          00000000 0075d0 00005f 00      0   0  1
```

再次尝试提取

```shell
output$ riscv32-unknown-elf-objcopy -O binary -j .scdata test 111.bin
output$ ll 111.bin 
-rwxr-xr-x 1 chsgcxy chsgcxy 1024 3月  12 15:19 111.bin*

output$ hexdump 111.bin | more
0000000 8d5c 8c9d ba32 2deb 3a2b ebcf beae 3b87
0000010 6e69 080f 0827 28a1 2757 9846 c3b8 1793
```

提取成功了，但是这里就有疑问了，objcopy是有这种限制吗？此问题需要进一步探索
