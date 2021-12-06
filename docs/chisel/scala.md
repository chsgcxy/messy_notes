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

### extends

```scala
abstract class BtbModule(implicit val p: Parameters) extends Module with HasBtbParameters
```

应该解读为extends ( A with B with ....)

### case class

样例类，一种特殊的类，能够被优化以用于模式匹配。

- 构造器中的参数如果不被声明为var的话，默认是val类型
- 自动创建伴生对象，实现apply方法，可以不直接显示地new对象
- 伴生对象实现unapply方法，从而可以将case class应用于模式匹配
- 实现toString、hashCode、copy、equals方法

### implicit

Scala支持两种形式的隐式转换：

- 隐式值：用于给方法提供参数
- 隐式视图：用于类型间转换或使针对某类型的方法能调用成功

隐式值

```scala
scala> def persion(implicit name : String) = name
def persion(implicit name: String): String

scala> implicit val p : String  = "test"
val p: String = test

scala> persion
val res0: String = test
```

隐式视图

```scala
scala> import scala.language.implicitConversions

scala> def foo(msg: String) = println(msg)
def foo(msg: String): Unit

scala> foo(10)
1 |foo(10)
  |    ^^
  |    Found:    (10 : Int)
  |    Required: String

scala> implicit def abc(x: Int): String = x.toString
def abc(x: Int): String

scala> foo(10)
10
```

### 协变和逆变

这里首先要解释一下泛型编程，才能更好的理解协变和逆变的来龙去脉。首先泛型编程是一种思想，不在于语言，支持泛型编程的语言只是将其实现变得方便。
C语言可以使用宏来达到泛型编程的目的,但宏仅工作在预处理阶段，调试起来也很麻烦。C++使用模板来实现泛型编程，模板函数和模板类是主要途径。
scala和java一样，也支持泛型编程。泛型编程不属于OOO体系，它是对OOO的补充，OOO在算法和数据结构方面有着先天的不足，泛型编程弥补了这一点。这时候就会出现一个问题，如果T'是T的一个子类，
那么Pipeline[T']是不是应该被看做是Pipeline[T]的子类呢？这样就引出了协变和逆变。

scala 使用如下方法来解决上面的问题

- invariant 不变 写成Pipeline[T] 认为Pipeline[T']没有关系
- covariant 协变 写成Pipeline[+T]， 认为Pipeline[T'] 是Pipeline[T]的子类型
- contravariant 逆变 写成Pipeline[-T]， 认为Pipeline[T] 是Pipeline[T']的子类型

还可对类型边界进行限制

- 上边界，表达了泛型类型必须是某种类型或某种类型的子类， 语法为：“<:”
- 下边界，表达了泛型类型必须是某种类型或某种类型的父类，语法为：“>:”
