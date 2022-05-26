# 一览·zookeeper3.6.0新特性：拥抱prometheus

[![云原生生态圈](https://pic4.zhimg.com/v2-2dfe5b0a357e55331becc86d331ea0c1_xs.jpg?source=172ae18b)](https://www.zhihu.com/people/jasonadmin)

[云原生生态圈](https://www.zhihu.com/people/jasonadmin)

zookeeper3.6.0 新特性：

\1. 添加文档了zookeeper监控的文档:[https://github.com/apache/zookeeper/blob/master/zookeeper-docs/src/main/resources/markdown/zookeeperMonitor.md](https://link.zhihu.com/?target=https%3A//github.com/apache/zookeeper/blob/master/zookeeper-docs/src/main/resources/markdown/zookeeperMonitor.md)
\2. 服务的管理端口统一: 启用管理端口以接受HTTP和HTTPS通信。默认为禁用,java配置指令为`zookeeper.admin.portUnification`
\3. `zkSnapShotToolkit.sh`: 和mysql的mysqlbinlog查不多，将快照文件转化到标准输出,支持json
\4. zookeeper增加了zookeeperTools的使用文档
\5. 自动为Netty连接添加IP授权
\6. 允许延迟事务日志刷新
\7. 添加`getEphemerals`用于获取会话创建的所有临时节点
\8. 添加一个API和相应的CLI以获取特定路径下递归子节点的总数
\9. 自定义用户SSLContext
\10. 在zookeeper中内置数据已执行检查
\11. 集成ZooKeeper的可插拔指标系统
\12. 在follwers上的JMX上公开当前leader的ID
\13. 添加zkTxnLogToolkit.sh脚本恢复具有CRC错误的日志和快照条目所需的工具，可以交互式的选择修复
\14. 能够实时监控jute.maxBuffer的使用情况
\15. 添加CLI命令以递归方式列出znode和子节点
\16. ZooKeeper服务器中的审核日志记录

**zookeeper监控**
zookeeper内置增加了插拔式的指标系统，通过开放了7000端口和`/metrics`作为指标的访问路径:

```bash
root@99-129:/usr/local/apache-zookeeper-3.6.0-bin# curl http://192.168.99.129:7000/metrics
# HELP outstanding_changes_removed outstanding_changes_removed
# TYPE outstanding_changes_removed counter
outstanding_changes_removed 0.0
# HELP request_throttle_wait_count request_throttle_wait_count
# TYPE request_throttle_wait_count counter
request_throttle_wait_count 0.0
# HELP diff_count diff_count
# TYPE diff_count counter
diff_count 0.0
# HELP commit_propagation_latency commit_propagation_latency
# TYPE commit_propagation_latency summary
commit_propagation_latency{quantile="0.5",} NaN
commit_propagation_latency{quantile="0.9",} NaN
commit_propagation_latency{quantile="0.99",} NaN
commit_propagation_latency_count 0.0
commit_propagation_latency_sum 0.0
# HELP dead_watchers_cleaner_latency dead_watchers_c
```

**## zookeeper prometheus提供的Grafana监控模板**
如何使用prometheus监控zookeeper这里就不说了，看以前的文章

[Prometheus监控系列-部署篇mp.weixin.qq.com![图标](https://pic4.zhimg.com/v2-a2a448e6e469cff6e3ddead5192cd687_180x120.jpg)](https://link.zhihu.com/?target=https%3A//mp.weixin.qq.com/s/4o8i_PxjnU7x52Re2Ge7dQ)[Prometheus监控系列-监控篇mp.weixin.qq.com![图标](https://pic2.zhimg.com/v2-751325e65b3e967cd8c3a4ea7237e31d_ipico.jpg)](https://link.zhihu.com/?target=https%3A//mp.weixin.qq.com/s/kOyfacyxPtq_oALgA1FcQQ)



官方也提供一个监控的面板，ID:10465

![img](https://pic4.zhimg.com/80/v2-fdbbf9a5aa4716566d0509c61e521bf7_720w.jpg)

![img](https://pic4.zhimg.com/80/v2-20af3cbf79640564e3ea37d619315b9f_720w.jpg)

**## zookeeper新增的审核日志**
Apache ZooKeeper支持3.6.0版以上的审核日志。默认情况下，审核日志处于禁用状态。要启用审核日志，请在conf / zoo.cfg中配置audit.enable = true。审计日志并非记录在所有的ZooKeeper服务器上，而是仅记录在连接了客户端的服务器上，如下图所示

![img](https://pic1.zhimg.com/80/v2-b8d4f9971fa451d21def0e9be7730138_720w.jpg)

**### 日志的格式**
\* 会议:客户会话ID
\* 用户:与客户端会话相关联的用户的逗号分隔列表
\* ip:客户端IP地址
\* 操作:所选的任何一项审核操作。可能的值为（serverStart，serverStop，create，delete，setData，setAcl，multiOperation，reconfig，ephemeralZNodeDeleteOnSessionClose）
\* znode: znode的路径
\* znode类型:创建操作时znode的类型
\* ACL:znode ACL的字符串表示形式，如cdrwa（创建，删除，读取，写入，管理）。仅记录setAcl操作
\* 结果:操作结果。可能的值为（成功/失败/调用）。结果“ invoked”用于serverStop操作，因为在确保服务器实际停止之前已记录了stop。

```text
root@99-129:/usr/local/zookeeper# tail -f logs/zookeeper_audit.log
2020-04-20 05:29:40,099 INFO audit.Log4jAuditLogger: user=root	operation=serverStart	result=success
2020-04-20 05:30:42,912 INFO audit.Log4jAuditLogger: session=0x100013a1f1a0000	user=192.168.99.130	ip=192.168.99.130	operation=delete	znode=/str1000	result=success
2020-04-20 05:30:46,588 INFO audit.Log4jAuditLogger: session=0x100013a1f1a0000	user=192.168.99.130	ip=192.168.99.130	operation=delete	znode=/str1002	result=success
```

如果要修改自定义审核日志文件，备份数，最大文件大小，自定义审核记录器，需要在`log4j.properties`中修改定义。

**#### 谁是审核日志中的用户？**
默认情况下，只有四个身份验证提供程序：
\- IP认证提供者
\- SASLAuthenticationProvider
\- X509AuthenticationProvider
\- DigestAuthenticationProvider

根据配置的身份验证提供程序确定用户：
\1. 配置IPAuthenticationProvider后，将经过身份验证的IP用作用户
\2. 配置SASLAuthenticationProvider时，会将客户端主体作为用户
\3. 配置X509AuthenticationProvider时，将客户端证书作为用户
\4. 配置DigestAuthenticationProvider时，通过身份验证的用户为user

自定义身份验证提供程序可以重写org.apache.zookeeper.server.auth.AuthenticationProvider.getUserName（String id）以提供用户名。如果身份验证提供程序未覆盖此方法，则将org.apache.zookeeper.data.Id.id中存储的所有内容都用作用户。通常，只有用户名存储在此字段中，但是取决于用户身份验证提供者存储在其中的内容。对于审核日志记录，将org.apache.zookeeper.data.Id.id的值作为用户。

在ZooKeeper服务器中，并非所有操作都由客户端完成，而是某些操作由服务器本身完成。例如，当客户端关闭会话时，临时znode将被服务器删除。这些删除操作不是由客户端直接完成的，而是由服务器本身完成的，这些操作称为系统操作。对于这些系统操作，在审核记录这些操作时，会将与ZooKeeper服务器关联的用户视为用户。例如，如果在ZooKeeper中，服务器主体是zookeeper/hadoop.hadoop.com@HADOOP.COM，则它将成为系统用户，并且所有系统操作都将使用该用户名记录。

```text
2020-04-20 05:29:40,099 INFO audit.Log4jAuditLogger: user=root	operation=serverStart	result=success
```

如果没有与ZooKeeper服务器关联的用户，则将启动ZooKeeper服务器的用户视为该用户。例如，如果服务器由root启动，则将root作为系统用户

```text
user=root operation=serverStart result=success
```

单个客户端可以将多个身份验证方案附加到一个会话，在这种情况下，所有经过身份验证的方案都将作为用户使用，并以逗号分隔的列表形式显示。例如，如果客户端通过主体zkcli@HADOOP.COM和ip 127.0.0.1进行身份验证，则创建znode审核日志将如下所示：

```text
session=0x10c0bcb0000 user=zkcli@KUBEMASTER.TOP,127.0.0.1 ip=127.0.0.1 operation=create znode=/a result=success
```

**## zookeeper官方提供的一些新的工具集**
**### zkSnapShotToolkit.sh**
将快照数据转换成标准输出或者json文件

```text
root@99-131:/usr/local/apache-zookeeper-3.6.0-bin# /usr/local/apache-zookeeper-3.6.0-bin/bin/zkSnapShotToolkit.sh -d  /tmp/zookeeper/version-2/snapshot.40000b802
/str22589
  cZxid = 0x00000400005847
  ctime = Mon Apr 20 04:45:17 EDT 2020
  mZxid = 0x00000400005847
  mtime = Mon Apr 20 04:45:17 EDT 2020
  pZxid = 0x00000400005847
  cversion = 0
  dataVersion = 0
  aclVersion = 0
  ephemeralOwner = 0x00000000000000
  data = ZGVtbw== # base64编码
```


**### zkTxnLogToolkit.sh**
TxnLogToolkit是ZooKeeper附带的命令行工具，能够恢复带有损坏CRC的事务日志条目

```text
$ bin/zkTxnLogToolkit.sh log.100000001
ZooKeeper Transactional Log File with dbid 0 txnlog format version 2
4/5/18 2:15:58 PM CEST session 0x16295bafcc40000 cxid 0x0 zxid 0x100000001 createSession 30000
CRC ERROR - 4/5/18 2:16:05 PM CEST session 0x16295bafcc40000 cxid 0x1 zxid 0x100000002 closeSession null
4/5/18 2:16:05 PM CEST session 0x16295bafcc40000 cxid 0x1 zxid 0x100000002 closeSession null
4/5/18 2:16:12 PM CEST session 0x26295bafcc90000 cxid 0x0 zxid 0x100000003 createSession 30000
4/5/18 2:17:34 PM CEST session 0x26295bafcc90000 cxid 0x0 zxid 0x200000001 closeSession null
4/5/18 2:17:34 PM CEST session 0x16295bd23720000 cxid 0x0 zxid 0x200000002 createSession 30000
4/5/18 2:18:02 PM CEST session 0x16295bd23720000 cxid 0x2 zxid 0x200000003 create '/andor,#626262,v{s{31,s{'world,'anyone}}},F,1
EOF reached after 6 txns.
```

交互式选择性修复

```text
$ bin/zkTxnLogToolkit.sh -r log.100000001
ZooKeeper Transactional Log File with dbid 0 txnlog format version 2
CRC ERROR - 4/5/18 2:16:05 PM CEST session 0x16295bafcc40000 cxid 0x1 zxid 0x100000002 closeSession null
Would you like to fix it (Yes/No/Abort) ? y
EOF reached after 6 txns.
Recovery file log.100000001.fixed has been written with 1 fixed CRC error(s)
```



发布于 2020-04-20