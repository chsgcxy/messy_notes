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

## python调用c/c++

可以参考[Python调用C++程序的几种方法](https://blog.csdn.net/zong596568821xp/article/details/81133511)

## getattr

```python
def getattr(object, name, default)
getattr(object, name[, default]) -> value

Get a named attribute from an object; getattr(x, 'y') is equivalent to x.y. When a default argument is given, it is returned when the attribute doesn't exist; without it, an exception is raised in that case.
```

可以从模块中获得类的实例，也可以从类中获得属性值，总之，getattr(x, 'y')是一个返回x.y的功能，因此y中如果包含字符'.'会被解析成attribute
