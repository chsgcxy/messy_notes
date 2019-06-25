# python

## \__init__.py

\__init__.py文件的作用是将文件夹变为一个Python模块,我们在导入一个包时，实际上是导入了它的\__init__.py文件。这样我们可以在\__init__.py文件中批量导入我们所需要的模块，而不再需要一个一个的导入。

可以参考[Python \__init__.py作用详解](https://www.cnblogs.com/Lands-ljk/p/5880483.html)

## ubuntu下鼠标变成加号无法点击

原因是把shell命令行终端当成了python环境，误输入了import指令，直接杀死包含import的进程

```shell
ps -e | grep "import"
kill -9 xxx
```
