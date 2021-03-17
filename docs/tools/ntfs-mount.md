# 移动硬盘 Ubuntu挂载问题

手里的移动硬盘在ubuntu下意外的copy文件时拔出，再插入后无法自动挂载，切换到win10系统可以正常挂载。以下是解决过程

## 手动挂载

```shell
chsgcxy@chsgcxy-TM1703:/$ sudo fdisk -l

Disk /dev/sdb: 1.8 TiB, 2000398933504 bytes, 3907029167 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: dos
Disk identifier: 0x60a353fe

Device     Boot Start        End    Sectors  Size Id Type
/dev/sdb1  *       64 3907024128 3907024065  1.8T  7 HPFS/NTFS/exFAT
```

查看到移动硬盘的设备节点（突然想起做设备驱动的时候经常需要搞flash挂载）
根据节点尝试挂载，其实主要想看一下挂载过程中是否有异常打印，然后是否能根据异常打印来定位原因。

```shell
chsgcxy@chsgcxy-TM1703:/$ cd media/
chsgcxy@chsgcxy-TM1703:/media$ sudo mkdir xijie
chsgcxy@chsgcxy-TM1703:/media$ sudo chmod 755 xijie/

chsgcxy@chsgcxy-TM1703:/media$ sudo mount -o rw /dev/sdb1 xijie/
$MFTMirr does not match $MFT (record 0).
Failed to mount '/dev/sdb1': Input/output error
NTFS is either inconsistent, or there is a hardware fault, or it's a
SoftRAID/FakeRAID hardware. In the first case run chkdsk /f on Windows
then reboot into Windows twice. The usage of the /f parameter is very
important! If the device is a SoftRAID/FakeRAID then first activate
it and mount a different device under the /dev/mapper/ directory, (e.g.
/dev/mapper/nvidia_eahaabcc1). Please see the 'dmraid' documentation
for more details.
```

## 解决

```shell
chsgcxy@chsgcxy-TM1703:/media$ sudo apt-get install ntfs-3g
chsgcxy@chsgcxy-TM1703:/media$ sudo ntfsfix /dev/sdb1
Mounting volume... $MFTMirr does not match $MFT (record 0).
FAILED
Attempting to correct errors... 
Processing $MFT and $MFTMirr...
Reading $MFT... OK
Reading $MFTMirr... OK
Comparing $MFTMirr to $MFT... FAILED
Correcting differences in $MFTMirr record 0...OK
Processing of $MFT and $MFTMirr completed successfully.
Setting required flags on partition... OK
Going to empty the journal ($LogFile)... OK
Checking the alternate boot sector... OK
NTFS volume version is 3.1.
NTFS partition /dev/sdb1 was processed successfully.

```

重新插拔移动硬盘，自动挂载成功。