# How to use markdown with vscode

- [How to use markdown with vscode](#how-to-use-markdown-with-vscode)
  - [auto-creat-topic](#auto-creat-topic)
  - [插入公式](#插入公式)

## auto-creat-topic

- install 'markdown TOC'
- right click and select 'Markdown TOC: Insert/Update'
- if that not auto add newline and creat like this

```md
<!-- TOC -->autoauto- [How to use markdown with vscode](#how-to-use-markdown-with-vscode)auto    - [auto-creat-topic](#auto-creat-topic)autoauto<!-- /TOC -->
```

you can use ctrl + h to replace 'autoauto' with '/n' and replace 'auto    ' with '\n  ';
and if you face this problem, you should close function 'auto update when save'

## 插入公式

vscode要使能插入公式预览必须安装'markdown math'插件

- 同行使用$a+b$来声明
- 单独一行使用$$a+b$$来声明
- 使用{}来表示一个变量边界

详细使用可以参考：

1. [Cmd Markdown 公式指导手册](https://www.zybuluo.com/codeep/note/163962)
2. [Markdown数学公式语法](https://www.jianshu.com/p/e74eb43960a1)

## plantuml

vscode 支持plantuml插件，依赖于java和Graphviz，而且对文件后缀有要求。
实际上vscode并不能完美使用plantuml,理想中的方式是直接在markdown的预览中能够看到plantuml的效果，但是实际上我们只能创建一个单独plantuml文件来生成图片
markdown解析器的版本太多了，导致很难做到兼容，我希望能够在vscode中和github中看到同样的效果，所以，对于流程图，使用嵌入图片应该是最好的选择；当然还有公式的显示也是让人头疼，不知道其他人有没有更好的解决方案，其实目的就是无论在什么地方都能比较轻松的看到markdown效果，而且在本机的离线状态下也能够看到markdown效果。或许之前使用过的github.io会是个不错的选择？？？

使用方法参考[使用Emacs敲出UML，PlantUML快速指南](http://archive.3zso.com/archives/plantuml-quickstart.html)