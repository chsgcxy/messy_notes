# WSL

在windows上通过安装WSL，能够实现快速高效的搭建linux开发环境。能够满足一般的开发需求。

## 解决占用硬盘太大的问题

WSL占用的硬盘空间似乎不会自动释放，这里需要手动进行一些操作。不然C盘会红到爆炸

在Windows文件管理器中搜索ext4.vhdx, 找到对应的WSL分发版本对应的存储文件
在powershell中输入如下命令：

```shell
WSL --shutdown
diskpart (需要管理员权限)
select vdisk file="xxxxxxxxx\ext4.vhdx"
compact vdisk
detach vdisk
```
