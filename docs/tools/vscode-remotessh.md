# vscode

linux开发者普遍喜欢传统的vim,利用ctags和cscope等工具，也能做到很方便的进行代码开发。github上也有很多开源的vim配置方案，比如广受大家喜欢的spf13-vim等。但如果你尝试了使用vscode,那么你很有可能会放弃坚持了多年的vim。现代编辑器不只有vscode一家，atom等也有一些用户，当然java、scala开发者可能更喜欢idea一些。但总体来讲，尤其是C/C++和python开发，vscode已经成为了主流

## 丰富的插件扩展

没有插件的vscode是没有灵魂的，这里罗列一些常用插件，vscode的很多插件都支持配置，具体的配置在插件说明中能够很轻易的找到。

### c/c++

开发C/C++必备

### highlight-words

能够实现高亮某个单词，并且高亮可以设置成快捷键，非常推荐

通过如下配置，能够使用一个色块来高亮某一个单词，并且为全字符匹配模式

```json
"highlightwords.box": {
        "light": true,
        "dark": false
    },
"highlightwords.defaultMode": 1,
"highlightwords.showSidebar": false,
```

快捷键相关关键字为Highlight Remove All 和 Highlight Toggle Current,可以在Keyboard shortcut中进行设置

### Markdown Preview Enhanced

markdown增强解析器，边写边看效果，还挺不错

### Python

python 必备

### RISC-V Support

支持riscv汇编语法高亮

### Setting Sync

可以将你的配置传到github上，当在一个新环境中部署vscode时，不必再重复进行繁琐的配置，可以直接从github拉取

### 主题

在扩展商店中搜索theme，可以找到非常丰富的主题，总有一款你喜欢的。

### Remote-SSH

我们在工作时，公司往往会选择在服务器上做开发，会给每人分配一个ssh ID以供登录到ssh server。这样在开发时，就只能选择vim + ctags + cscope这种开发环境。对于习惯于vscode的人来讲，这是灾难性的。习惯了vscode的直接之后，就再也不想动手敲来敲去。

vscode引入了Remote-SSH插件来解决这个问题，它能够让我们用本地电脑的vscode通过ssh直接编辑远程的代码。

这里主要参考vscode官方文档[https://code.visualstudio.com/docs/remote/ssh#_getting-started]

在这里大致总结一下安装过程，本地以win10为例

远端需要的操作如下

- 远端安装ssh server并开启
- 配置一些安全可选项，具体参考官方文档

本地需要的操作如下

- 本地安装vscode以及Remote-SSH扩展
- 本地安装ssh服务
- 本地登录远端ssh服务器

#### 本地具体过程

这里主要讲本地如何操作，远端一般已经部署完毕

安装vscode及Remote-SSH扩展

安装完毕vscode之后，在扩展中选择Remote-SSH扩展。当然，你完全可以使用Setting Sync扩展来同步你的配置，这样就不用每次在一个新的环境中进行繁琐的配置

安装ssh服务

这里参考微软官方文档[https://docs.microsoft.com/zh-cn/windows-server/administration/openssh/openssh_install_firstuse]

需要注意的是，如果使用PowerShell, 需要以**管理员权限**运行，在安装完ssh之后，使用ssh命令来测试是否安装成功，并且顺便激活path。否则==Set-Service -Name sshd -StartupType 'Automatic'== 命令可能会找不到sshd
