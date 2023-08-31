# screen

我们经常需要通过SSH等登录到linux服务器去执行一些任务，正常情况下，当我们关闭ssh客户端，执行的任务也被关闭。有些时候，我们希望能够在关闭客户端时，任务仍然进行，这时候可以使用screen。
GNU Screen可以看作是窗口管理器的命令行界面版本。它提供了统一的管理多个会话的界面和相应的功能。

## 创建screen终端

```shell
screen -S test_name
```
or just screen
 
## 查看终端

```shell
screen -ls
```

## 保存并退出终端

在screen终端内按Ctrl+a, 然后按d

## 重新attach终端

screen -r
