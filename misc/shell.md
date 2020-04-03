# shell 小点总结

总结近期用到的shell命令，及对shell的理解，shell是一种linux提供的脚本语言，我们可以通过script的形式来组织shell，shell的解析器有多种，bash, csh, ksh, tcsh, 其中bash是开源的，我们用的也比较多

bash官网: https://www.gnu.org/software/bash/

关于shell本身的官方网站目前也没有找到，只是在一些网站上找到了一些文档说明，看具体内容，具有一定参考性， 但也不是太全。在bash的官方文档中也有一些介绍。

[shell 文档../books/shell.pdf](../books/shell.pdf)

## 查看当前shell解析器

可以通过查看SHELL环境变量来确认当前默认的shell解析器

```shell
chsgcxy@chsgcxy-TM1703:~/workspace/messy_notes$ echo $SHELL
/bin/bash
```

## 变量定义

需要注意的是，变量定义“=”两侧不能加空格，而且变量名区分大小写

## Command substitution

命令替代（先完成命令，再把命令结果替换）一共有两种方式

- `command`
    echo “Today’s date is `date`”
    Today’s date is Thu 7 Jul 2016 16:53:20 BST
- $( .... ) in bash only
    echo “Today’s date is $(date)”
    Today’s date is Thu 7 Jul 2016 16:53:31 BST

其中括号的方式只有bash支持，通用性欠缺一些，但是``在嵌套使用时需要转义

## 关于单双引号

- Single forward quote
    All characters enclosed between a pair of single forward quotes are shielded - apart from
    the ' character itself!
- Double quotes
    All the characters enclosed between a pair of double quotes are shielded except for $ ` \
    and "

```shell
chsgcxy@chsgcxy-TM1703:~/workspace/Demo$ cat a.sh 
#! /bin/bash

name="chsgcxy"

test1='$name'
test2="$name"
test3='`ls`'
test4="`ls`"

echo $test1
echo $test2
echo $test3
echo $test4
chsgcxy@chsgcxy-TM1703:~/workspace/Demo$ ./a.sh 
$name
chsgcxy
`ls`
a.sh bash b.sh Demo.iml src
```

即单引号不会做解析，双引号会对变量和命令替换做解析

## $的特殊组合

### "$!"

($!) Expands to the process id of the job most recently placed into the back-
ground

If a command is terminated by the control operator ‘&’, the shell executes the command
asynchronously in a subshell.

参考自[shell.pdf](../books/shell.pdf) 3.4.2 Special Parameters

### "$$"

($$) Expands to the process id of the shell. In a () subshell, it expands to the
process id of the invoking shell, not the subshell

## 算数运算

需要使用expr来进行算数运算，使用(()) 两层括号也可以，值得注意的是，expr是Linux的内置软件，并不是shell语言的关键字

```shell
chsgcxy@chsgcxy-TM1703:~/workspace/Demo$ cat a.sh
#! /bin/bash

a=`expr 3 + 2`
echo $a

b=3+2
echo $b

c=$((3 + 2))
echo $c

chsgcxy@chsgcxy-TM1703:~/workspace/Demo$ ./a.sh
5
3+2
5
```

## shift

shift [n]
Shift the positional parameters to the left by n. The positional parameters
from n+1 . . . $# are renamed to $1 . . . $#-n. Parameters represented by the
numbers $# to $#-n+1 are unset. n must be a non-negative number less than or
equal to $#. If n is zero or greater than $#, the positional parameters are not
changed. If n is not supplied, it is assumed to be 1. The return status is zero
unless n is greater than $# or less than zero, non-zero otherwise.

可以用来做参数解析，这样就不用考虑参数顺序

```shell
for arg in "$@"; do
    case $arg in
        -h|--help)
        printf "Usage:"
        exit 0
        ;;
        -n|--num)
        num="$2"
        shift
        shift
        ;;
        -c)
        option="creat"
        shift
        ;;
        *)
        dir="$1"
        ;;
    esac
done
```

## 自动交互

使用如下的格式完成自动交互，结尾的delimiter要顶格写，前面不能有任何字符，后面也不能有任何字符，包括空格和 tab 缩进;
开始的delimiter前后的空格会被忽略掉

```shell
command << delimiter
    document
delimiter
```

实例如下

```shell
ftp -n -p 172.16.10.103 << EOF
    user chsgcxy 123456
    cd xxxx
    lcd xxxx
    put xxxx
    close
    bye
EOF
```

## ftp

ftp 要注意主动模式和被动模式（-p选项）
如果把FTP服务器部署在防火墙或者NAT服务器的背 后，则采用主动操作模式的客户端只能够建立命令连接而无法进行文件传输。如果部署完FTP服务器后，系统管理员发现用户可以连接上FTP服务器，可以查看 目录下的文件，但是却无法下载或者上传文件，如果排除权限方面的限制外，那么很有可能就是这个操作模式选择错误

## debug

Shell Debugging Options

- -x print commands and args as executed
- -v print shell input as read
- -n don't run the script but check its syntax
- -u treat unset variables as errors

The shell options, ( eg -x -v -n and -u ) can be invoked be in several ways -
in a known area which can be enclosed within set commands to turn on and off the
option ( set +<option> will turn the option off

set -e 可以使shell脚本在发生错误的时候退出
