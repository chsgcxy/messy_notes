# LPC1114 使用USER命令实现hex转bin

支持先烧后焊

```text
$KARM\BIN\ElfDwT.exe ./xxx.axf
$KARM\BIN40\fromelf.exe --i32 -o ./xxx.hex ./xxx.axf
```

hex文件拼接

```text
$KARM\BIN40\hexcombine ./xxx1.hex ./xxx2.hex
```

axf 转 bin

```text
$KARM\BIN40\fromelf.exe --bin -o "$L@L.bin" "#L"
```
