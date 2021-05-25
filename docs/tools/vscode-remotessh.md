# Vscode remote ssh

我们在工作时，公司往往会选择在服务器上做开发，会给每人分配一个ssh ID以供登录到ssh server。这样在开发时，就只能选择vim + ctags + cscope这种开发环境。对于习惯于vscode的人来讲，这是灾难性的。习惯了vscode的直接之后，就再也不想动手敲来敲去。

vscode引入了Remote-SSH插件来解决这个问题，它能够让我们用本地电脑的vscode通过ssh直接编辑远程的代码。

这里主要参考vscode官方文档[https://code.visualstudio.com/docs/remote/ssh#_getting-started]

## 安装汇总

在这里大致总结一下安装过程，本地以win10为例

远端需要的操作如下

- 远端安装ssh server并开启
- 配置一些安全可选项，具体参考官方文档

本地需要的操作如下

- 本地安装vscode以及Remote-SSH扩展
- 本地安装ssh服务
- 本地登录远端ssh服务器

## 本地具体过程

这里主要讲本地如何操作，远端一般已经部署完毕

### 安装vscode及Remote-SSH扩展

安装完毕vscode之后，在扩展中选择Remote-SSH扩展。当然，你完全可以使用Setting Sync扩展来同步你的配置，这样就不用每次在一个新的环境中进行繁琐的配置

### 安装ssh服务

这里参考微软官方文档[https://docs.microsoft.com/zh-cn/windows-server/administration/openssh/openssh_install_firstuse]

需要注意的是，如果使用PowerShell, 需要以**管理员权限**运行，在安装完ssh之后，使用ssh命令来测试是否安装成功，并且顺便激活path。否则==Set-Service -Name sshd -StartupType 'Automatic'== 命令可能会找不到sshd
