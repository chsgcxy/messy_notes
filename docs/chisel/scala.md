# scala

[官方网站](https://www.scala-lang.org/)

这里我们只针对scala3进行学习，直接跳过scala2
[scala3 book](https://docs.scala-lang.org/scala3/book/introduction.html)

## 关键语法举例解析

### 变量

注意val和var的区别，val是值，可以理解为const; var是变量。val不可被更改, 因为chisel中所有的都应该是电路, 一旦确定了不能更改，因此所有的都应该是val

内置的变量类型如下：

```scala
val b: Byte = 1
val i: Int = 1
val l: Long = 1
val s: Short = 1
val d: Double = 2.0
val f: Float = 3.0
val e: String = "config"
val a: Char = 'c'
```

### 循环

这里注意 for(i <- 1 until 3) 和 for(i <- 1 to 3) 的区别， until是不包含， to是包含

### 闭包

闭包本身是一个函数,起始我们在C语言中经常这样用,这里重点解释闭包的含义：闭包是一个函数，返回值依赖于声明在函数外部的一个或多个变量

```scala
var factor = 3  
val multiplier = (i:Int) => i * factor  
```

### 继承

继承,一个子类只能继承一个父类

### traits

接口，接口中可以包含抽象或者具体的方法和字段，也可以像类一样具有参数。接口可以多继承

下面的例子展示了抽象接口和非抽象接口, 抽象的实现方式,class和traits是一样的

```scala
trait Speaker1:
  def speak(): String  // has no body, so it’s abstract

trait Speaker2:
  def speak(): String = "Meow"
```

需要注意的是，**重写具体方法或接口必须使用override,虚方法或者虚接口,不需要**
