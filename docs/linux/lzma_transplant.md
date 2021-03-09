# transplant LZMA compression algo from linux2.6.32 to linux2.6.29

不同的压缩算法的压缩效率、压缩/解压缩时间不同。LZMA的压缩率要比gzip高的多。最近项目中遇到系统镜像超出分区大小的问题，这个问题可以通过改变内核压缩算法来解决。可惜项目中所使用的内核linux2.6.29版本太低，仅支持gzip压缩，不支持LZMA压缩，所以我们从高版本内核中移植LZMA和bzip2压缩算法来解决这一问题。

## 目标

- 从linux2.6.32移植LZMA和bzip2到linux2.6.29
- 目标架构为powerpc
- initramfs采用LZMA压缩，image镜像采用gzip压缩

## 如何选择LZMA来压缩initramfs

在内核配置中,需要选择支持LZMA并且选择built-in initramfs compression mode 为LZMA

```text
    General setup --->
         [*] Initial RAM filesystem and RAM disk (initramfs/initrd) support
         (../../../product/s3000gb/rootfs) Initramfs source file(s)
         (0)     User ID to map to 0 (user root)
         (0)     Group ID to map to 0 (group root)  
         [*]   Support initial ramdisks compressed using gzip
         [ ]   Support initial ramdisks compressed using bzip2
         [*]   Support initial ramdisks compressed using LZMA
               Built-in initramfs compression mode (LZMA)  --->
```

## 移植过程

我们先查找与Support initial ramdisks compressed using LZMA 相关的代码，我们可以通过查看此配置选项的help信息来找到具体的文件，help信息中有两个相关的宏

```text
Symbol: RD_LZMA [=y]
Depends on: BLK_DEV_INITRD [=y] && EMBEDDED [=y]
Selects: DECOMPRESS_LZMA
```

我们在2.6.32中搜索 ==RD_LZMA==, 会发现大部分的引用都是在/arch/xx/config/xxx_defconfig文件中，我们不去关心，下面列出了我们需要关心的所有搜索结果

```text
usr/Kconfig: config RD_LZMA
usr/Kconfig:    depends on RD_LZMA
```

我们发现其实RD_LZMA仅在usr目录下有引用，其实在内核编译时，usr/built-in.o 主要就是initramfs的镜像，我们定制initramfs是通过创建一个cpio格式的档案文件来实现的，我们就是要实现用LZMA来压缩这个cpio文件。

我们查看一下usr目录下的文件, 单从文件名已经能够推理出各个文件的关系，我们可以直接同步到linux2.6.29中

```text
root@99-252:~/V2.1.5.67086/kernel/uClinux/linux-2.6.32.x/usr# ls -al

-rw-r--r--  1 13448 6406 12543  5月 17  2016 gen_init_cpio.c
-rw-r--r--  1 13448 6406  1024  5月 17  2016 initramfs_data.bz2.S
-rw-r--r--  1 13448 6406  1023  5月 17  2016 initramfs_data.gz.S
-rw-r--r--  1 13448 6406  1025  5月 17  2016 initramfs_data.lzma.S
-rw-r--r--  1 13448 6406  1021  5月 17  2016 initramfs_data.S
-rw-r--r--  1 13448 6406  4514  5月 17  2016 Kconfig
-rw-r--r--  1 13448 6406  2154  5月 17  2016 Makefile
```

这些文件具体的功能是什么呢？具体到每个文件里面去看一下，发现其实这些文件里面没做什么有价值的操作，仅仅是根据kconfig指定了cpio的压缩格式。

接下来我们再去找另一个宏==DECOMPRESS_LZMA==，找的方法和上一个一样，我们先在linux2.6.32中查找这个宏，同样的,会有很多arch/xx/configs/xxx_defconfig文件中有引用，这些我们不去关系，下面列出了除defconfig之外的引用。

```text
// squashfs是压缩只读文件系统，能够压缩系统内的文档，inode以及目录，显然这个我们也无需关心
fs/squashfs/Kconfig:    select DECOMPRESS_LZMA
fs/squashfs/Kconfig:    select DECOMPRESS_LZMA_NEEDED

// 头文件，显然这个必须移植
include/linux/decompress/unlzma_mm.h:#elif defined(CONFIG_DECOMPRESS_LZMA_NEEDED)

// 解压缩相关的文件，显然这个我们必须移植
lib/decompress.c:#ifndef CONFIG_DECOMPRESS_LZMA
lib/Makefile:lib-$(CONFIG_DECOMPRESS_LZMA) += decompress_unlzma.o
lib/Kconfig:config DECOMPRESS_LZMA
lib/Kconfig:config DECOMPRESS_LZMA_NEEDED
lib/decompress_unlzma.c:#elif defined(CONFIG_DECOMPRESS_LZMA_NEEDED)

// 已经同步过了，不再需要关心
usr/Kconfig:    select DECOMPRESS_LZMA
```

我们发现其实我们只需要移植头文件和lib目录下的解压缩文件就可以了，移植的方法是对比相应的目录找到相关的代码，同步，需要注意makefile和kconfig也需要相应的修改。

移植完成后咱们来尝试编译一下kernel, 先进入menuconfig设置一下新增的配置，勾选之前描述的选项，然后编译

我们发现确实生成了lzma的cpio文件

```text
make kernel
scripts/kconfig/conf -s arch/powerpc/Kconfig
  CHK     include/linux/version.h
  CHK     include/linux/utsrelease.h
  SYMLINK include/asm -> include/asm-powerpc
  CALL    scripts/checksyscalls.sh
sed: can't read /home/chenhao/ros5.4/br_ros5.4_rsp_dev_20161214/rsp/kernel/linux-2.6.29.6-bmw/arch/x86/include/asm/unistd_32.h: No such file or directory
  CHK     include/linux/compile.h
  GEN     usr/initramfs_data.cpio.lzma
  AS      usr/initramfs_data.lzma.o
  LD      usr/built-in.o
```

但最终编译出的镜像大小没有改变，这是什么原因呢？

我们相信LZMA的压缩率是比gzip高的多的，而且我们也可以实际验证这一点

```shell
root@ubuntu:~/test_lzma# lzma -k initramfs_data.cpio 
root@ubuntu:~/test_lzma# gzip initramfs_data.cpio
root@ubuntu:~/test_lzma# ls -al
-rw-r--r--  1 root    root    63202304 Jul 11 05:10 initramfs_data.cpio
-rw-r--r--  1 root    root    21340431 Jul 11 05:10 initramfs_data.cpio.gz
-rw-r--r--  1 root    root    13816814 Jul 11 05:10 initramfs_data.cpio.lzma
```

那么极大可能是压缩时没有真正的使用LZMA压缩算法,我们先去看一下cpio压缩文件

```shell
root@ubuntu:~/ros5.4/br_ros5.4_rsp_dev_20161214/rsp/kernel/linux-2.6.29.6-bmw/usr# lzmainfo initramfs_data.cpio.lzma 

lzmainfo: initramfs_data.cpio.lzma: Not a .lzma file
```

看来真的是这样，仅仅是压缩文件名变成了lzma，其实压缩算法没有改变。那么具体initramfs是怎样压缩的呢？还记得我们前面说的usr目录下的那几个文件吗？那几个文件不就是决定压缩算法的吗？一定是那个地方出了问题。

我们先看一下linux2.6.32/usr目录下的==Makefile==文件

```shell
 26 #####
 27 # Generate the initramfs cpio archive
 28
 29 hostprogs-y := gen_init_cpio
 30 initramfs   := $(CONFIG_SHELL) $(srctree)/scripts/gen_initramfs_list.sh
 31 ramfs-input := $(if $(filter-out "",$(CONFIG_INITRAMFS_SOURCE)), \
 32                         $(shell echo $(CONFIG_INITRAMFS_SOURCE)),-d)
 33 ramfs-args  := \
 34         $(if $(CONFIG_INITRAMFS_ROOT_UID), -u $(CONFIG_INITRAMFS_ROOT_UID)) \
 35         $(if $(CONFIG_INITRAMFS_ROOT_GID), -g $(CONFIG_INITRAMFS_ROOT_GID))
 36 
 37 # .initramfs_data.cpio.d is used to identify all files included
 38 # in initramfs and to detect if any files are added/removed.
 39 # Removed files are identified by directory timestamp being updated
 40 # The dependency list is generated by gen_initramfs.sh -l
 41 ifneq ($(wildcard $(obj)/.initramfs_data.cpio.d),)
 42         include $(obj)/.initramfs_data.cpio.d
 43 endif
 44 
 45 quiet_cmd_initfs = GEN     $@
 46       cmd_initfs = $(initramfs) -o $@ $(ramfs-args) $(ramfs-input)
 47 
 48 targets := initramfs_data.cpio.gz initramfs_data.cpio.bz2 initramfs_data.cpio.lzma initramfs_data.cpio
 49 # do not try to update files included in initramfs
 50 $(deps_initramfs): ;
```

我想大家也发现了，整个makefile没有说压缩什么事，但是==30行==和==46行==明显是在编译的时候调用了scripts目录下的gen_initramfs_list.sh 的脚本，很多资料都会讲到这个文件的作用，压缩算法一定在这个脚本中指定了，我们去linux2.6.32中看一下

```shell
227 is_cpio_compressed=
228 compr="gzip -9 -f"
229
230 arg="$1"
231 case "$arg" in
232         "-l")   # files included in initramfs - used by kbuild
233                 dep_list="list_"
234                 echo "deps_initramfs := \\"
235                 shift
236                 ;;
237         "-o")   # generate compressed cpio image named $1
238                 shift
239                 output_file="$1"
240                 cpio_list="$(mktemp ${TMPDIR:-/tmp}/cpiolist.XXXXXX)"
241                 output=${cpio_list}
242                 echo "$output_file" | grep -q "\.gz$" && compr="gzip -9 -f"
243                 echo "$output_file" | grep -q "\.bz2$" && compr="bzip2 -9 -f"
244                 echo "$output_file" | grep -q "\.lzma$" && compr="lzma -9 -f"
245                 echo "$output_file" | grep -q "\.cpio$" && compr="cat"
246                 shift
247                 ;;
248 esac

282 # If output_file is set we will generate cpio archive and compress it
283 # we are carefull to delete tmp files
284 if [ ! -z ${output_file} ]; then
285         if [ -z ${cpio_file} ]; then
286                 cpio_tfile="$(mktemp ${TMPDIR:-/tmp}/cpiofile.XXXXXX)"
287                 usr/gen_init_cpio ${cpio_list} > ${cpio_tfile}
288         else
289                 cpio_tfile=${cpio_file}
290         fi
291         rm ${cpio_list}
292         if [ "${is_cpio_compressed}" = "compressed" ]; then
293                 cat ${cpio_tfile} > ${output_file}
294         else
295                 (cat ${cpio_tfile} | ${compr}  - > ${output_file}) \
296                 || (rm -f ${output_file} ; false)
297         fi
298         [ -z ${cpio_file} ] && rm ${cpio_tfile}
299 fi
```

确实这里面实现了cpio的压缩，那么不多说，把这些都同步过去。

同步完成之后，再次编译，编译通过，镜像大小已经由23M变为15M,显然第一步压缩搞定；接下来我们就要启动一下这个镜像，看看启动时根文件系统解压缩是否有问题。

很不幸，启动时内核报错

```shell
Kernel panic - not syncing: bad gzip magic numbers
```

不要慌，有错误打印就好办，从打印看很明显是内核还以为根文件系统是gzip压缩格式的。

我们先找到具体打印的位置

下述代码来源于2.6.32内核

```c
// lib/inflate.c
1187 /*
1188  * Do the uncompression!
1189  */
1190 static int INIT gunzip(void)
1191 {

1203     if (magic[0] != 037 ||
1204         ((magic[1] != 0213) && (magic[1] != 0236))) {
1205             error("bad gzip magic numbers");
1206             return -1;
1207     }

// lib/decompress.c
 static const struct compress_format {
 27         unsigned char magic[2];
 28         const char *name;
 29         decompress_fn decompressor;
 30 } compressed_formats[] = {
 31         { {037, 0213}, "gzip", gunzip },
 32         { {037, 0236}, "gzip", gunzip },
 33         { {0x42, 0x5a}, "bzip2", bunzip2 },
 34         { {0x5d, 0x00}, "lzma", unlzma },
 35         { {0, 0}, NULL, NULL }
 36 };
 37 
 38 decompress_fn decompress_method(const unsigned char *inbuf, int len,
 39                                 const char **name)
 40 {
 41         const struct compress_format *cf;
 42 
 43         if (len < 2)
 44                 return NULL;    /* Need at least this much... */
 45 
 46         for (cf = compressed_formats; cf->name; cf++) {
 47                 if (!memcmp(inbuf, cf->magic, 2))
 48                         break;
 49 
 50         }
 51         if (name)
 52                 *name = cf->name;
 53         return cf->decompressor;
 54 }
 
// init/initramfs.c
414 static char * __init unpack_to_rootfs(char *buf, unsigned len)
415 {
447                 decompress = decompress_method(buf, len, &compress_name);
```

下述代码来源于2.6.29内核

```c
479 static char * __init unpack_to_rootfs(char *buf, unsigned len, int check_only)
480 {
515                 gunzip();

```

相信通过上面的代码片段大家已经了解了initramfs是如何解压缩的,不多说，接着同步代码，主要是将decompress_method 移植过来，其他的不动。

修改完后，我们再次编译，启动，initramfs已经能够正常解压缩了，至此，移植活动就完成了。

## 后记

在做这个的时候也想过直接去找内核的path,但找起来比较复杂，就放弃了这个思路。

对于内核的编译、压缩、解压缩需要进一步深入研究。
