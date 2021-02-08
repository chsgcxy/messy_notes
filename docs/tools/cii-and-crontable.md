# 自动化部署之gitlab.ci 和 crontable

和github的action类似，gitlab的CI/CD也是一套自动化部署工具，通过在.gitlab-ci.yml中写入配置就可以实现自动化测试等功能

这里只总结简单使用方法，详细可以参考https://docs.gitlab.com/ee/ci/

## CI基本概念

- Job 待执行的任务
- Pipeline 流水线中可以包含多个任务，在达到触发条件后，会根据.gitlab-ci.yml创建一条流水线
- Stage 流水线阶段，一个流水线中可以有多个流水线阶段，一个阶段可以有多个任务，阶段按序执行
- Environment variables 有CI内置环境变量，也可以自定义环境变量
- cache 存放一些环境依赖
- artifacts 在stage之间传递结果

## CI环境搭建

todo...
