# Apache ZooKeeper 3.7.0 发布，分布式服务框架

[执笔记忆的空白 ](https://122.51.148.168/users/26)2021-03-30 09:39:06 ⋅ 755 阅读

Apache ZooKeeper 是 Apache 软件基金会的一个软件项目，它为大型分布式计算提供开源的分布式配置服务、同步服务和命名注册。ZooKeeper 曾经是 Hadoop 的一个子项目，但现在是一个独立的顶级项目。

ZooKeeper 的架构通过冗余服务实现高可用性。因此，如果第一次无应答，客户端就可以询问另一台 ZooKeeper 主机。ZooKeeper 节点将它们的数据存储于一个分层的命名空间，非常类似于一个文件系统或一个前缀树结构。客户端可以在节点读写，从而以这种方式拥有一个共享的配置服务。

Apache ZooKeeper 3.7.0 正式发布，本次部分更新内容如下：

### **新功能**

- [ZOOKEEPER-1112](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-1112) - 增加对 C 客户端 SASL 认证的支持；
- [ZOOKEEPER-3264](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3264) - Zookeeper 的基准测试工具；
- [ZOOKEEPER-3301](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3301) - 强制执行配额限制；
- [ZOOKEEPER-3681](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3681) - 添加对 Travis CI 构建的 s390x 支持；
- [ZOOKEEPER-3714](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3714) - 向 Perl 客户端添加（Cyrus）SASL 身份验证支持；
- [ZOOKEEPER-3874](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3874) - 从 Java 启动 ZooKeeper 服务器的官方 API；
- [ZOOKEEPER-3948](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3948) - 为 ZooKeeperServer 测试引入确定性的运行时行为注入框架；
- [ZOOKEEPER-3959](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3959) - 允许具有 SASL 的多个超级用户；
- [ZOOKEEPER-3969](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3969) - 添加 whoami API 和 Cli 命令；

### **改进**

- [ZOOKEEPER-1871](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-1871) - 向 zkCli 添加选项以在执行命令之前等待连接；
- [ZOOKEEPER-2272](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-2272) - ZooKeeperServer 和 KerberosName 中的代码清理；
- [ZOOKEEPER-2649](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-2649) - ZooKeeper 不会在客户端已通过身份验证的日志会话 ID 中写入；
- [ZOOKEEPER-2779](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-2779) - 添加选项以不会为重新配置节点设置ACL；
- [ZOOKEEPER-3101](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3101) - 添加注释提醒用户在向 ZOO_ERRORS 添加值时向 zerror 添加大小写；
- [ZOOKEEPER-3342](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3342) - 使用标准字符集；
- [ZOOKEEPER-3411](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3411) - 删除不建议使用的 CLI:ls2 和 rmr；
- [ZOOKEEPER-3427](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3427) - 引入 SnapshotComparer，可帮助调试快照；
- [ZOOKEEPER-3482](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3482) - 用于客户端和 Quorum 的 SSL 的 SASL（Kerberos）身份验证；
- [ZOOKEEPER-3567](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3567) - 为 zk python 客户端添加 SSL 支持；
- [ZOOKEEPER-3582](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3582) - 将异步 api 调用重构为 lambda 样式；
- [ZOOKEEPER-3638](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3638) - 将 Jetty 更新为 9.4.24.v20191120；
- [ZOOKEEPER-3640](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3640) - 在 cli_mt 中实现“批处理模式”；
- [ZOOKEEPER-3649](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3649) - ls -s CLI 需要换行；
- [ZOOKEEPER-3662](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3662) - 删除 Follower Class 中的 NPE Possibility；
- [ZOOKEEPER-3663](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3663) - 清理 ZNodeName 类；
- [ZOOKEEPER-4048](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-4048) - 将 Mockito 升级到 3.6.2 —— 允许在 JDK16 上构建；
- [ZOOKEEPER-4188](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-4188) - 添加有关 whoami CLI 的文档；
- [ZOOKEEPER-4209](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-4209) - 在 3.5 分支上，将 Netty 版本更新为 4.1.53.Final ；
- [ZOOKEEPER-4221](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-4221) - 改善消息超出 jute.maxbufer 大小时的错误消息；
- [ZOOKEEPER-4231](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-4231) - 为快照压缩配置添加文档；

## **Bug**

- [ZOOKEEPER-1105](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-1105) - C 客户端 zookeeper_close 不向服务器发送 CLOSE_OP 请求；
- [ZOOKEEPER-1677](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-1677) - INET_ADDRSTRLEN 的滥用；
- [ZOOKEEPER-1998](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-1998) - C库从 zookeeper_interest 无条件调用 getaddrinfo；
- [ZOOKEEPER-2307](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-2307) - ZooKeeper 无法启动，因为 acceptedEpoch 小于 currentEpoch；
- [ZOOKEEPER-2475](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-2475) - 在 Zoookeeper Javadoc 中包含 ZKClientConfig API；
- [ZOOKEEPER-2490](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-2490) - 在 Windows 上无限连接；
- [ZOOKEEPER-3112](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3112) - 由于连接时出现 UnresolvedAddressException 而导致 fd 泄漏；
- [ZOOKEEPER-3613](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3613) - 用户意外在值的末尾包含空格时，ZKConfig无法在getBoolean() 上返回正确的值；
- [ZOOKEEPER-3651](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3651) - NettyServerCnxnFactoryTest 异常；
- [ZOOKEEPER-4200](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-4200) - 修复 WatcherCleanerTest 在 macOS Catalina 上失败的问题；
- [ZOOKEEPER-4201](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-4201) - C 客户端：macOS Catalina 上与 SASL 相关的编译问题；
- [ZOOKEEPER-4205](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-4205) - 使用端口 8080 时测试失败；
- [ZOOKEEPER-4230](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-4230) - 在 RestMain 中使用动态临时文件夹而不是静态临时文件夹；
- [ZOOKEEPER-4232](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-4232) - InvalidSnapshotTest 破坏了其自己的测试数据；

## **Wish**

- [ZOOKEEPER-3415](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3415) - 转换内部逻辑以使用 Java 8 流；
- [ZOOKEEPER-3763](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fissues.apache.org%2Fjira%2Fbrowse%2FZOOKEEPER-3763) - 还原 ZKUtil.deleteRecursive 以帮助与 3.5 和 3.6 的应用程序兼容；

完整详情可查看：[https://zookeeper.apache.org/doc/r3.7.0/releasenotes.html](https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fzookeeper.apache.org%2Fdoc%2Fr3.7.0%2Freleasenotes.html)