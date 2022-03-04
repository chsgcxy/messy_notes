# git技巧

## 统计代码

统计代码行数

```shell
git log --since=2021-05-27 --author="xxxxx" --pretty=tformat: --numstat | gawk '{ add += $1 ; subs += $2 ; loc += $1 - $2 } END { printf "added lines: %s removed lines: %s total lines: %s\n",add,subs,loc}'
```

统计提交次数

```shell
git log --author="xxxxx" --oneline | wc -l
```

## git clone问题

问题

```shell
xxx:~/workspace$ git clone xxxxx
Cloning into 'xxxxx'...
fatal: unable to access 'xxxxx/': server certificate verification failed. CAfile: /etc/ssl/certs/ca-certificates.crt CRLfile: none
```

解决方法

```shell
export GIT_SSL_NO_VERIFY=1
```
