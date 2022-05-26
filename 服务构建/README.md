可以直接基于编程语言的基础镜像

由jenkins/gitlab-ci触发构建

拉取源码

通过Dockerfile进行构建

如果有检查指令则运行检查(又或者是直接包含在构建动作中)

通过构建工具构建源码, 例如java的mvn, nodejs的npm, golang的go

拷贝调试工具, 拷贝监控组件到容器中

静态语言需要执行指令以拉取配置文件