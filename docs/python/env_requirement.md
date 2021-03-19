# python 虚拟环境及依赖

当在一台机器上开发python软件时，有时候会遇到多个软件用的同一python库的不同版本，这时候就会很麻烦。
而且，我往往在调试时会根据需要单独的安装一些依赖库，当别人使用时或者部署在新环境中时，就会很麻烦，需要
一个个库的进行安装。python的requirement.txt 和 virtual env 解决了这一问题。

## 切换镜像源

```shell
mkdir ~/.pip
cd ~/.pip
gedit ./pip.conf

[global]
index-url = http://mirrors.aliyun.com/pypi/simple/

[install]
trusted-host=mirrors.aliyun.com
```

## 虚拟env

```shell
pip3 install virtualenv
python3 -m virtualenv .isatest(想要创建的env的名称)
source .isatest/bin/activate
```

## requirement

生成依赖文件

```shell
pip3 freeze > requirements.txt
```

仅生成当前目录下的依赖

```shell
pip3 install pipreqs
pipreqs ./
```

安装依赖文件中指定的包

```shell
pip3 install -r requirement.txt
```
