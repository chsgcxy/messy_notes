# sbt

sbt(Simple Build Tool)是scala的构建工具, 采用scala来编写配置文件

[sbt无痛入门指南](https://zhuanlan.zhihu.com/p/82727108)这里面介绍了如何安装SBT，并且配置国内仓库，并且使用全局仓库。

花费半天的时间，根据sbt官方文档来写一些简单构建，就足以应付日常需求了[sbt官方文档](https://www.scala-sbt.org/1.x/docs/index.html)

sbt使用build.sbt脚本来建立构建规则，主要是定义构建对象(projects)并且设置一些依赖。sbt对于构建目录进行了限制，所以使用一个项目模板是非常省事的方法。

sbt默认的构建project目录是repo的根目录。比如我们创建了一个名为hello的repo，那么我们的scala源码应该放在src/main/scala/ 目录下，此时默认的构建对象
就是hello。如果我们要新增一个构建对象testrun，我们应该创建一个 testrun/src/main/scala/ 的目录，并且把源文件放在这个目录下，同时，应该在build.sbt中添加
一个testrun的构建说明

```scala
lazy var testRun = (project in file("testrun"))
```

这看起来像不像Makefile！！！
