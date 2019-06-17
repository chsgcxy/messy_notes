# How to use markdown with vscode

- [How to use markdown with vscode](#how-to-use-markdown-with-vscode)
  - [auto-creat-topic](#auto-creat-topic)

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
