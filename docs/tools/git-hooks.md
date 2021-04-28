# git 钩子与自动编码风格检查

实际上，为了保证编码风格的统一，好多开源软件提供了编码风格检查脚本，并且在git commit的时候会自动检查

我很喜欢这种设计，这是一种守的设计，从结构上限制了程序员的行为。那么这个功能是怎么实现的呢，这里做一下粗略总结，作为一个引子

## git的hooks机制

git 提供了一些钩子机制，用来在git命令前后执行一些使用者想要执行的内容。这些钩子在 .git/hooks目录下,
比如我的电脑中的一个repo下面的hooks目录

```shell
chsgcxy@chsgcxy-xxxx:~/workspace/xxxx/.git/hooks$ ls
applypatch-msg.sample      post-update.sample     prepare-commit-msg.sample  pre-receive.sample
commit-msg.sample          pre-applypatch.sample  pre-push.sample            update.sample
fsmonitor-watchman.sample  pre-commit.sample      pre-rebase.sample
```

这里面有所有的钩子的sample，这个是按照名称来绑定的，比如pre-commit.sample， 如果我们把.sample去掉，那么pre-commit这个钩子就生效了，并且它会在敲git commit的时候先去执行，如果这个脚本返回成功，才能完成commit动作，否则commit会失败

当然git也没有限制这个钩子文件的类型，它可以是shell，python，应用，等等等的，只要它名字是那个，并且可执行，当然也可以是软链接喽

## 自动编码风格检查

比如qemu中，在scripts目录下面提供了一个名为checkpatch.pl的脚本，它可以检查一个patch的编码风格是否符合规范，我们可以写如下简单脚本调用它，并且这个脚本命名为pre-commit并放在.git/hooks目录下即可

```shell
git diff --cached > .cur_commit.patch
./scripts/checkpatch.pl --patch --no-signoff .cur_commit.patch
res=$?
rm .cur_commit.patch
if [ $res -ne 0 ]; then
    exit 1
else
    exit 0
fi
```

## 关于sign-off

上述操作显然无法生成带sign-off的patch，因此忽略signoff检查
git commit时，可以通过-s(--signoff)参数来确定使用signoff,并且-m信息中最后一行应该像下面这样

```text
Signed-off-by: chsgcxy <chsgcxy@outlook.com>
```

## 关于部署

有了这个自动检查，那么很显然是想推广，但很遗憾，这仅对本地生效，在clone代码时也无法把这个clone下来，似乎都没有上传的途径。怎么办呢，代码总要编译吧，总有一个下载下来绝大多少人都会进行的操作吧，一般可以选择在编译的时候，在编译脚本中生效钩子文件，钩子文件可以采取软链接的方式，这样钩子文件也可以在项目中归档。
