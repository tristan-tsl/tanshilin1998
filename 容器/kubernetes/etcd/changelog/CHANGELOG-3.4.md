以前的更改日志可以在[CHANGELOG-3.3](https://github.com/etcd-io/etcd/blob/main/CHANGELOG-3.3.md)找到。

在**生产**中运行的最低推荐 etcd 版本是 3.2.28+、3.3.18+、3.4.2+ 和 3.5.1+。

------

## v3.4.19（全部）

有关任何重大更改，请参阅[代码更改](https://github.com/etcd-io/etcd/compare/v3.4.18...v3.4.19)和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。

### etcd服务器

- 修复[排除由多个对等点激活的相同警报类型](https://github.com/etcd-io/etcd/pull/13475)。

------

## v3.4.18 (2021-10-15)

有关任何重大更改，请参阅[代码更改](https://github.com/etcd-io/etcd/compare/v3.4.17...v3.4.18)和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。

### 指标、监控

请参阅每个版本的所有指标[的指标列表](https://etcd.io/docs/latest/metrics/)。

- 添加[`etcd_disk_defrag_inflight`](https://github.com/etcd-io/etcd/pull/13397).

### 其他

- 更新

  基本映像

  从

  ```
  debian:buster-v1.4.0
  ```

  到

  ```
  debian:bullseye-20210927
  ```

  修复以下关键的CVE：

  - [CVE-2021-3711](https://nvd.nist.gov/vuln/detail/CVE-2021-3711)：在 openssl 的 SM2 解密中错误计算缓冲区大小
  - [CVE-2021-35942](https://nvd.nist.gov/vuln/detail/CVE-2021-35942)：glibc 中的整数溢出缺陷
  - [CVE-2019-9893](https://nvd.nist.gov/vuln/detail/CVE-2019-9893)：[libseccomp 中](https://nvd.nist.gov/vuln/detail/CVE-2019-9893)不正确的系统调用参数生成
  - [CVE-2021-36159](https://nvd.nist.gov/vuln/detail/CVE-2021-36159)：apk-tools 中的 libfetch 错误处理 FTP 和 HTTP 协议中的数字字符串以允许越界读取。

------

## v3.4.17 (2021-10-03)

有关任何重大更改，请参阅[代码更改](https://github.com/etcd-io/etcd/compare/v3.4.16...v3.4.17)和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。

### `etcdctl`

- 修复[etcdctl check datascale 命令](https://github.com/etcd-io/etcd/pull/11896)以使用 https 端点。

### gRPC 网关

- 添加[`MaxCallRecvMsgSize`](https://github.com/etcd-io/etcd/pull/13077)对 http 客户端的支持。

### 依赖

- 将[`github.com/dgrijalva/jwt-go](https://github.com/etcd-io/etcd/pull/13378)替换[为 github.com/golang-jwt/jwt'](https://github.com/etcd-io/etcd/pull/13378)。

### 去

- 用[*Go 1.12.17*](https://golang.org/doc/devel/release.html#go1.12)编译。

------

## v3.4.16 (2021-05-11)

有关任何重大更改，请参阅[代码更改](https://github.com/etcd-io/etcd/compare/v3.4.15...v3.4.16)和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。

### etcd服务器

- 添加[`--experimental-warning-apply-duration`](https://github.com/etcd-io/etcd/pull/12448)允许应用持续时间阈值可配置的标志。
- 修复[`--unsafe-no-fsync`](https://github.com/etcd-io/etcd/pull/12751)仍然写出数据，避免损坏（大部分时间）。
- 通过[在没有 marshal 的情况下记录范围响应大小，](https://github.com/etcd-io/etcd/pull/12871)减少[大约 30% 的内存分配](https://github.com/etcd-io/etcd/pull/12871)。
- [有条件地从健康检查中](https://github.com/etcd-io/etcd/pull/12880)添加[排除警报](https://github.com/etcd-io/etcd/pull/12880)。

### 指标

- 修复[客户端取消](https://github.com/etcd-io/etcd/pull/12803)从 ( https://github.com/etcd-io/etcd/pull/12196 )向后移植的监视[时生成的错误指标](https://github.com/etcd-io/etcd/pull/12803)。

### 去

- 用[*Go 1.12.17*](https://golang.org/doc/devel/release.html#go1.12)编译。

------

## [v3.4.15](https://github.com/etcd-io/etcd/releases/tag/v3.4.15) ( [2021-02-26](https://github.com/etcd-io/etcd/releases/tag/v3.4.15) )

有关任何重大更改，请参阅[代码更改](https://github.com/etcd-io/etcd/compare/v3.4.14...v3.4.15)和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。

### etcd服务器

- [在调试级别](https://github.com/etcd-io/etcd/pull/12677)记录[成功的 etcd 服务器端健康检查](https://github.com/etcd-io/etcd/pull/12677)。
- 修复[64 KB websocket 通知消息限制](https://github.com/etcd-io/etcd/pull/12402)。

### 包裹 `fileutil`

- 修复[`F_OFD_`常量](https://github.com/etcd-io/etcd/pull/12444)。

### 依赖

- 升级[`gorilla/websocket`到 v1.4.2](https://github.com/etcd-io/etcd/pull/12645)。

### 去

- 用[*Go 1.12.17*](https://golang.org/doc/devel/release.html#go1.12)编译。

------

## [v3.4.14](https://github.com/etcd-io/etcd/releases/tag/v3.4.14) (2020-11-25)

有关任何重大更改，请参阅[代码更改](https://github.com/etcd-io/etcd/compare/v3.4.13...v3.4.14)和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。

### 包裹 `clientv3`

- 修复[手表重新连接后验证令牌无效的问题](https://github.com/etcd-io/etcd/pull/12264)。当 clientConn 准备好时自动获取 AuthToken。

### etcd服务器

- 在具有学习节点的集群中启用 force-new-cluster 标志时[修复服务器恐慌](https://github.com/etcd-io/etcd/pull/12288)。

### 包裹 `netutil`

- 删除

  `netutil.DropPort/RecoverPort/SetLatency/RemoveLatency`

  。

  - 这些都不再使用了。它们仅用于旧版本的功能测试。
  - 删除以遵守最佳安全实践，最大限度地减少任意 shell 调用。

### `tools/etcd-dump-metrics`

- 实施[输入验证以防止任意 shell 调用](https://github.com/etcd-io/etcd/pull/12491)。

### 去

- 用[*Go 1.12.17*](https://golang.org/doc/devel/release.html#go1.12)编译。

------

## [v3.4.13](https://github.com/etcd-io/etcd/releases/tag/v3.4.13) (2020-8-24)

有关任何重大更改，请参阅[代码更改](https://github.com/etcd-io/etcd/compare/v3.4.12...v3.4.13)和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。

### 安全

- 一个[日志警告](https://github.com/etcd-io/etcd/pull/12242)时ETCD使用具有比700在Linux和777在Windows权限不同任何现有的目录添加。

### 去

- 用[*Go 1.12.17*](https://golang.org/doc/devel/release.html#go1.12)编译。

------

## [v3.4.12](https://github.com/etcd-io/etcd/releases/tag/v3.4.12) (2020-08-19)

有关任何重大更改，请参阅[代码更改](https://github.com/etcd-io/etcd/compare/v3.4.11...v3.4.12)和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。

### etcd服务器

- 修复

  慢写警告中的服务器恐慌

  。

  - 通过[PR#12238 修复](https://github.com/etcd-io/etcd/pull/12238)。

### 去

- 用[*Go 1.12.17*](https://golang.org/doc/devel/release.html#go1.12)编译。

------

## [v3.4.11](https://github.com/etcd-io/etcd/releases/tag/v3.4.11) (2020-08-18)

有关任何重大更改，请参阅[代码更改](https://github.com/etcd-io/etcd/compare/v3.4.10...v3.4.11)和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。

### etcd服务器

- 改进[`runtime.FDUsage`调用模式以减少 Memory Usage 和 CPU Usage 的对象 malloc](https://github.com/etcd-io/etcd/pull/11986)。
- 添加[`etcd --experimental-watch-progress-notify-interval`](https://github.com/etcd-io/etcd/pull/12216)标志以使监视进度通知间隔可配置。

### 包裹 `clientv3`

- 删除

  过多的监视取消日志记录消息

  。

  - 这个[州长/州长#93450](https://github.com/kubernetes/kubernetes/issues/93450)。

### 包裹 `runtime`

- [`runtime.FDUsage`通过删除不必要的排序进行](https://github.com/etcd-io/etcd/pull/12214)优化。

### 指标、监控

- 添加[`os_fd_used`和`os_fd_limit`监视当前操作系统文件描述符](https://github.com/etcd-io/etcd/pull/12214)。
- 添加[`etcd_disk_defrag_inflight`](https://github.com/etcd-io/etcd/pull/13397).

### 去

- 用[*Go 1.12.17*](https://golang.org/doc/devel/release.html#go1.12)编译。

------

## [v3.4.10](https://github.com/etcd-io/etcd/releases/tag/v3.4.10) (2020-07-16)

有关任何重大更改，请参阅[代码更改](https://github.com/etcd-io/etcd/compare/v3.4.9...v3.4.10)和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。

### 包裹 `etcd server`

- 添加

  `--unsafe-no-fsync`

  标志。

  - 设置该标志会禁用 fsync 的所有使用，这是不安全的并且会导致数据丢失。该标志使得运行 etcd 节点进行测试和开发成为可能，而不会在文件系统上放置大量负载。

- 添加[etcd --auth-token-ttl](https://github.com/etcd-io/etcd/pull/11980)标志以自定义`simpleTokenTTL`设置。

- 改进[runtime.FDUsage 对象 malloc 的 Memory Usage 和 CPU Usage](https://github.com/etcd-io/etcd/pull/11986)。

- 改进[mvcc.watchResponse 通道内存使用](https://github.com/etcd-io/etcd/pull/11987)。

- 修复

  `int64`raft logger 中的转换恐慌

  。

  - 修复[kubernetes / kubernetes # 91 937](https://github.com/kubernetes/kubernetes/issues/91937)。

### 重大变化

- 更改了

  现有目录权限的

  行为。

  - 以前，不会在现有数据目录和用于自动生成与客户端的 TLS 连接的自签名证书的目录上检查权限。现在添加一个检查以确保这些目录（如果已经存在）在 Linux 上具有 700 的所需权限，在 Windows 上具有 777 的所需权限。

### 去

- 用[*Go 1.12.17*](https://golang.org/doc/devel/release.html#go1.12)编译。

------

## [v3.4.9](https://github.com/etcd-io/etcd/releases/tag/v3.4.9) (2020-05-20)

有关任何重大更改，请参阅[代码更改](https://github.com/etcd-io/etcd/compare/v3.4.8...v3.4.9)和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。

### 包裹 `wal`

- 

  在 WAL 验证方法中

  添加[缺少的 CRC 校验和检查，否则会导致 panic](https://github.com/etcd-io/etcd/pull/11924)。

  - 请参阅https://github.com/etcd-io/etcd/issues/11918。

### 去

- 用[*Go 1.12.17*](https://golang.org/doc/devel/release.html#go1.12)编译。

------

## [v3.4.8](https://github.com/etcd-io/etcd/releases/tag/v3.4.8) (2020-05-18)

有关任何重大更改，请参阅[代码更改](https://github.com/etcd-io/etcd/compare/v3.4.7...v3.4.8)和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。

### `etcdctl`

- 确保[保存快照下载校验和以进行完整性检查](https://github.com/etcd-io/etcd/pull/11896)。

### 包裹 `clientv3`

- 确保[保存快照下载校验和以进行完整性检查](https://github.com/etcd-io/etcd/pull/11896)。

### etcd服务器

- 改进有关快照发送和接收的日志记录。

- [当 etcdserver 应用命令失败时添加日志](https://github.com/etcd-io/etcd/pull/11670)。

- [修复 mvcc 中的死锁错误](https://github.com/etcd-io/etcd/pull/11817)。

- 修复

  WAL 和服务器快照之间的不一致

  。

  - 以前，如果服务器在持久化 raft 硬状态之后但在保存快照之前崩溃，则服务器恢复会失败。
  - 有关更多信息，请参阅https://github.com/etcd-io/etcd/issues/10219。

### 包认证

- [通过保存一致的索引来修复数据损坏错误](https://github.com/etcd-io/etcd/pull/11652)。

### 指标、监控

- 添加[`etcd_debugging_auth_revision`](https://github.com/etcd-io/etcd/commit/f14d2a087f7b0fd6f7980b95b5e0b945109c95f3).

### 去

- 用[*Go 1.12.17*](https://golang.org/doc/devel/release.html#go1.12)编译。

------

## [v3.4.7](https://github.com/etcd-io/etcd/releases/tag/v3.4.7) (2020-04-01)

有关任何重大更改，请参阅[代码更改](https://github.com/etcd-io/etcd/compare/v3.4.6...v3.4.7)和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。

### etcd服务器

- [当最新索引大于 1 百万时](https://github.com/etcd-io/etcd/pull/11734)提高[压缩性能](https://github.com/etcd-io/etcd/pull/11734)。

### 包裹 `wal`

- 添加[`etcd_wal_write_bytes_total`](https://github.com/etcd-io/etcd/pull/11738).

### 指标、监控

- 添加[`etcd_wal_write_bytes_total`](https://github.com/etcd-io/etcd/pull/11738).

### 去

- 用[*Go 1.12.17*](https://golang.org/doc/devel/release.html#go1.12)编译。

------

## [v3.4.6](https://github.com/etcd-io/etcd/releases/tag/v3.4.6) (2020-03-29)

有关任何重大更改，请参阅[代码更改](https://github.com/etcd-io/etcd/compare/v3.4.5...v3.4.6)和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。

### 包裹 `lease`

- 修复

  跟随节点中的内存泄漏

  。

  - https://github.com/etcd-io/etcd/issues/11495
  - https://github.com/etcd-io/etcd/issues/11730

### 去

- 用[*Go 1.12.17*](https://golang.org/doc/devel/release.html#go1.12)编译。

------

## [v3.4.5](https://github.com/etcd-io/etcd/releases/tag/v3.4.5) (2020-03-18)

有关任何重大更改，请参阅[代码更改](https://github.com/etcd-io/etcd/compare/v3.4.4...v3.4.5)和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。

**同样，在从任何先前版本运行升级之前，请务必阅读下面的更改日志和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。**

### etcd服务器

- [`[CLIENT-PORT\]/health`在服务器端](https://github.com/etcd-io/etcd/pull/11704)登录[检查](https://github.com/etcd-io/etcd/pull/11704)。

### 客户端 v3

- 修复

  `"hasleader"`元数据嵌入

  。

  - 以前，`clientv3.WithRequireLeader(ctx)`是覆盖现有的上下文键。

### etcdctl v3

- 修复[`etcdctl member add`](https://github.com/etcd-io/etcd/pull/11638)命令以防止潜在的超时。

### 指标、监控

请参阅每个版本的所有指标[的指标列表](https://etcd.io/docs/latest/metrics/)。

- 添加[`etcd_server_client_requests_total`with`"type"`和`"client_api_version"`labels](https://github.com/etcd-io/etcd/pull/11687)。

### gRPC 代理

- 修复[`panic on error`](https://github.com/etcd-io/etcd/pull/11694)指标处理程序。

### 去

- 用[*Go 1.12.17*](https://golang.org/doc/devel/release.html#go1.12)编译。

------

## [v3.4.4](https://github.com/etcd-io/etcd/releases/tag/v3.4.4) (2020-02-24)

有关任何重大更改，请参阅[代码更改](https://github.com/etcd-io/etcd/compare/v3.4.3...v3.4.4)和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。

**同样，在从任何先前版本运行升级之前，请务必阅读下面的更改日志和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。**

### etcd服务器

- 修复

  `wait purge file loop during shutdown`

  。

  - 以前，在关机期间 etcd 可能会意外删除所需的 wal 文件，从而导致`etcdserver: open wal error: wal: file not found.`启动期间出现灾难性错误。
  - 现在，etcd 确保在服务器发出 raft 节点停止信号之前退出清除文件循环。

- [修复碎片整理中的损坏错误](https://github.com/etcd-io/etcd/pull/11613)。

- [在提升学习者时](https://github.com/etcd-io/etcd/pull/11640)修复[法定人数保护逻辑](https://github.com/etcd-io/etcd/pull/11640)。

- 当启用对等 mTLS 时，改进[对等损坏检查器](https://github.com/etcd-io/etcd/pull/11621)的工作。

### 指标、监控

请参阅每个版本的所有指标[的指标列表](https://etcd.io/docs/latest/metrics/)。

请注意，任何`etcd_debugging_*`指标都是实验性的，可能会发生变化。

- 添加[`etcd_debugging_mvcc_total_put_size_in_bytes`](https://github.com/etcd-io/etcd/pull/11374)普罗米修斯指标。
- 修复[etcd_debugging_mvcc_db_compaction_keys_total 始终为 0 的](https://github.com/etcd-io/etcd/pull/11400)错误。

### 认证

- 修复[通过 GRPC 网关添加用户时的](https://github.com/etcd-io/etcd/pull/11418)[NoPassword](https://github.com/etcd-io/etcd/issues/11414)[检查](https://github.com/etcd-io/etcd/pull/11418)（[问题#11414](https://github.com/etcd-io/etcd/issues/11414)）
- 修复[一些与身份验证相关的消息记录在错误级别的错误](https://github.com/etcd-io/etcd/pull/11586)

------

## [v3.4.3](https://github.com/etcd-io/etcd/releases/tag/v3.4.3) (2019-10-24)

有关任何重大更改，请参阅[代码更改](https://github.com/etcd-io/etcd/compare/v3.4.2...v3.4.3)和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。

**同样，在从任何先前版本运行升级之前，请务必阅读下面的更改日志和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。**

### 指标、监控

请参阅每个版本的所有指标[的指标列表](https://etcd.io/docs/latest/metrics/)。

请注意，任何`etcd_debugging_*`指标都是实验性的，可能会发生变化。

- 将[`etcd_cluster_version`](https://github.com/etcd-io/etcd/pull/11254)Prometheus 指标更改为仅包含主要和次要版本。

### 去

- 用[*Go 1.12.12*](https://golang.org/doc/devel/release.html#go1.12)编译。

------

## [v3.4.2](https://github.com/etcd-io/etcd/releases/tag/v3.4.2)（2019年10月11日）

有关任何重大更改，请参阅[代码更改](https://github.com/etcd-io/etcd/compare/v3.4.1...v3.4.2)和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。

**同样，在从任何先前版本运行升级之前，请务必阅读下面的更改日志和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。**

### etcdctl v3

- 修复[`etcdctl member add`](https://github.com/etcd-io/etcd/pull/11194)命令以防止潜在的超时。

### 等服务器

- [`tracing`](https://github.com/etcd-io/etcd/pull/11179)在 etcdserver 中添加到范围、放置和压缩请求。

### 去

- 使用[*Go 1.12.9*](https://golang.org/doc/devel/release.html#go1.12)编译，包括[*Go 1.12.8*](https://groups.google.com/d/msg/golang-announce/65QixT3tcmg/DrFiG6vvCwAJ)安全修复。

### 客户端 v3

- 

  针对多个端点

  修复[客户端平衡器故障转移](https://github.com/etcd-io/etcd/pull/11184)。

  - 修复[“kube-apiserver：多成员 etcd 集群上的故障转移在 DNS 不匹配时的证书检查失败”(kubernetes#83028)](https://github.com/kubernetes/kubernetes/issues/83028)。

- 修复

  客户端中的 IPv6 端点解析

  。

  - 修复[“1.16：当成员加入时，etcd 客户端没有正确解析 IPv6 地址”(kubernetes#83550)](https://github.com/kubernetes/kubernetes/issues/83550)。

------

## [v3.4.1](https://github.com/etcd-io/etcd/releases/tag/v3.4.1) (2019-09-17)

有关任何重大更改，请参阅[代码更改](https://github.com/etcd-io/etcd/compare/v3.4.0...v3.4.1)和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。

**同样，在从任何先前版本运行升级之前，请务必阅读下面的更改日志和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。**

### 指标、监控

请参阅每个版本的所有指标[的指标列表](https://etcd.io/docs/latest/metrics/)。

请注意，任何`etcd_debugging_*`指标都是实验性的，可能会发生变化。

- 添加[`etcd_debugging_mvcc_current_revision`](https://github.com/etcd-io/etcd/pull/11126)普罗米修斯指标。
- 添加[`etcd_debugging_mvcc_compact_revision`](https://github.com/etcd-io/etcd/pull/11126)普罗米修斯指标。

### etcd服务器

- 修复[安全服务器日志消息](https://github.com/etcd-io/etcd/commit/8b053b0f44c14ac0d9f39b9b78c17c57d47966eb)。
- 删除[文件描述符警告消息中的](https://github.com/etcd-io/etcd/commit/d5f79adc9cea9ec8c93669526464b0aa19ed417b)[冗余`%`字符](https://github.com/etcd-io/etcd/commit/d5f79adc9cea9ec8c93669526464b0aa19ed417b)。

### 包裹 `embed`

- 添加[`embed.Config.ZapLoggerBuilder`](https://github.com/etcd-io/etcd/pull/11148)以允许创建自定义 zap 记录器。

### 依赖

- [`google.golang.org/grpc`](https://github.com/grpc/grpc-go/releases)从升级[**`v1.23.0`**](https://github.com/grpc/grpc-go/releases/tag/v1.23.0)到[**`v1.23.1`**](https://github.com/grpc/grpc-go/releases/tag/v1.23.1).

### 去

- 使用[*Go 1.12.9*](https://golang.org/doc/devel/release.html#go1.12)编译，包括[*Go 1.12.8*](https://groups.google.com/d/msg/golang-announce/65QixT3tcmg/DrFiG6vvCwAJ)安全修复。

------

## v3.4.0 (2019-08-30)

有关任何重大更改，请参阅[代码更改](https://github.com/etcd-io/etcd/compare/v3.3.0...v3.4.0)和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。

- [v3.4.0](https://github.com/etcd-io/etcd/releases/tag/v3.4.0) (2019-08-30)，见[代码变化](https://github.com/etcd-io/etcd/compare/v3.4.0-rc.4...v3.4.0)。
- [v3.4.0-rc.4](https://github.com/etcd-io/etcd/releases/tag/v3.4.0-rc.4) (2019-08-29)，见[代码变化](https://github.com/etcd-io/etcd/compare/v3.4.0-rc.3...v3.4.0-rc.4)。
- [v3.4.0-rc.3](https://github.com/etcd-io/etcd/releases/tag/v3.4.0-rc.3) (2019-08-27)，见[代码变化](https://github.com/etcd-io/etcd/compare/v3.4.0-rc.2...v3.4.0-rc.3)。
- [v3.4.0-rc.2](https://github.com/etcd-io/etcd/releases/tag/v3.4.0-rc.2) (2019-08-23)，见[代码变化](https://github.com/etcd-io/etcd/compare/v3.4.0-rc.1...v3.4.0-rc.2)。
- [v3.4.0-rc.1](https://github.com/etcd-io/etcd/releases/tag/v3.4.0-rc.1) (2019-08-15)，见[代码变化](https://github.com/etcd-io/etcd/compare/v3.4.0-rc.0...v3.4.0-rc.1)。
- [v3.4.0-rc.0](https://github.com/etcd-io/etcd/releases/tag/v3.4.0-rc.0) (2019-08-12)，见[代码变化](https://github.com/etcd-io/etcd/compare/v3.3.0...v3.4.0-rc.0)。

**同样，在从任何先前版本运行升级之前，请务必阅读下面的更改日志和[v3.4 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_4/)。**

### 文档

- etcd 现在有一个新网站！请访问[https://etcd.io](https://etcd.io/)。

### 改进

- 添加 Raft 学习器：

  etcd#10725

  、

  etcd#10727

  、

  etcd#10730

  。

  - 用户指南：[运行时配置文档](https://etcd.io/docs/latest/op-guide/runtime-configuration/#add-a-new-member-as-learner)。
  - API 变更：[API 参考文档](https://etcd.io/docs/latest/dev-guide/api_reference_v3/)。
  - 有关实施的更多详细信息：[学习者设计文档](https://etcd.io/docs/latest/learning/design-learner/)和[实施任务列表](https://github.com/etcd-io/etcd/issues/10537)。

- 使用[新的 gRPC 平衡器接口](https://github.com/etcd-io/etcd/issues/9106)重写

  客户端平衡器

  。

  

  

  - [将 gRPC](https://github.com/etcd-io/etcd/pull/10911)升级[到 v1.23.0](https://github.com/etcd-io/etcd/pull/10911)。

  - 

    针对安全端点

    改进[客户端平衡器故障转移](https://github.com/etcd-io/etcd/pull/10911)。

    - 修复[“当第一个 etcd-server 不可用时，kube-apiserver 1.13.x 拒绝工作”(kubernetes#72102)](https://github.com/kubernetes/kubernetes/issues/72102)。

  - 修复[gRPC 恐慌“在关闭的通道上发送”](https://github.com/etcd-io/etcd/issues/9956)。

  - [新的客户端平衡器](https://etcd.io/docs/latest/learning/design-client/)使用异步解析器将端点传递给 gRPC 拨号函数。要阻塞直到底层连接启动，请传递`grpc.WithBlock()`到`clientv3.Config.DialOptions`。

- [在监视重试瞬态错误时](https://github.com/etcd-io/etcd/pull/9840)添加[退避](https://github.com/etcd-io/etcd/pull/9840)。

- 添加[抖动观看进度通知](https://github.com/etcd-io/etcd/pull/9278)，以防止[尖峰`etcd_network_client_grpc_sent_bytes_total`](https://github.com/etcd-io/etcd/issues/9246)。

- 改进[读取索引等待超时警告日志](https://github.com/etcd-io/etcd/pull/10026)，这表明本地节点可能网络缓慢。

- 改进

  慢请求应用警告日志

  。

  - 例如`read-only range request "key:\"/a\" range_end:\"/b\" " with result "range_response_count:3 size:96" took too long (97.966µs) to execute`。
  - 编辑[请求值字段](https://github.com/etcd-io/etcd/pull/9822)。
  - 提供[响应大小](https://github.com/etcd-io/etcd/pull/9826)。

- 改进[“变得不活动”警告日志](https://github.com/etcd-io/etcd/pull/10024)，这表明消息发送到对等方失败。

- 改进[TLS 设置错误日志记录](https://github.com/etcd-io/etcd/pull/9518)以帮助调试[启用 TLS 的集群配置问题](https://github.com/etcd-io/etcd/issues/9400)。

- 改进

  轻写工作负载下长时间运行的并发读取事务

  。

  - 以前，挂起写入的定期提交会阻止传入的读取事务，即使没有挂起的写入也是如此。
  - 现在，定期提交操作不会阻塞并发读事务，从而提高了长时间运行的读事务性能。

- 使

  后端读取事务完全并发

  。

  - 以前，正在进行的长时间运行的读取事务会阻止写入和未来的读取。
  - 通过此更改，在存在长时间运行的读取的情况下，写入吞吐量增加了 70%，P99 写入延迟减少了 90%。

- 改进[Raft Read Index 超时警告消息](https://github.com/etcd-io/etcd/pull/9897)。

- 调整

  服务器重启时的选举超时

  以减少

  重新加入服务器的破坏性

  。

  - 以前，etcd 在服务器启动时快进选举滴答声，只剩下一个滴答声用于领导选举。这是为了加快启动阶段，而不必等到所有选举周期结束。提前选举标记对于具有较大选举超时的跨数据中心部署很有用。但是，如果在领导者联系重新启动的节点之前最后一个滴答过去了，则会影响集群可用性。
  - 现在，当 etcd 重新启动时，它会在还剩 1 个刻度的情况下调整选举刻度，从而有更多时间让领导者防止破坏性重启。

- 添加

  Raft Pre-Vote 功能

  以减少

  破坏性的重新加入服务器

  。

  - 例如，一个不稳定（或重新加入）的成员可能会进出，并开始竞选。该成员将以更高的任期结束，并忽略所有具有更低任期的传入消息。在这种情况下，最终需要选出新的领导者，从而破坏集群可用性。Raft 实施 Pre-Vote 阶段来防止这种中断。If enabled, Raft runs an additional phase of election to check if pre-candidate can get enough votes to win an election.

- 调整

  定期压实保留窗口

  。

  - 例如每 5 分钟`etcd --auto-compaction-mode=revision --auto-compaction-retention=1000`自动`Compact`执行`"latest revision" - 1000`一次（当最新版本为 30000 时，在版本 29000 时压缩）。
  - 例如，以前，每 2.4 小时`etcd --auto-compaction-mode=periodic --auto-compaction-retention=24h`自动`Compact`具有 24 小时保留窗口。现在，`Compact`每 1 小时发生一次。
  - 例如，以前，每 3 分钟`etcd --auto-compaction-mode=periodic --auto-compaction-retention=30m`自动`Compact`具有 30 分钟保留时间窗口。现在，`Compact`每 30 分钟发生一次。
  - 当给定的时间小于 1 小时时，定期压实器会为每个压实周期记录最新修订，或者当给定的压实周期大于 1 小时（例如 1 小时`etcd --auto-compaction-mode=periodic --auto-compaction-retention=24h`）时，每 1 小时记录一次最新修订。
  - 对于每个压缩周期或 1 小时，压缩器使用在压缩周期之前获取的最后一个修订版来丢弃历史数据。
  - 压缩周期的保留窗口在每个给定的压缩周期或小时内移动。
  - 例如，当每小时写入是100 `etcd --auto-compaction-mode=periodic --auto-compaction-retention=24h`，`v3.2.x`，`v3.3.0`，`v3.3.1`，和`v3.3.2`紧凑版本2400，2640，2880，并为每2.4小时，同时`v3.3.3` *或稍后*压紧版本2400，2500，2600，每1小时。
  - Futhermore，当`etcd --auto-compaction-mode=periodic --auto-compaction-retention=30m`每分钟写是1000， ，`v3.3.0`，`v3.3.1`和`v3.3.2`紧凑的修订30000，33000，36000，并为每3分钟，同时`v3.3.3` *或稍后*压紧修订30000，60000，90000，并为每30分钟。

- 提高[租约到期/撤销操作性能](https://github.com/etcd-io/etcd/pull/9418)，解决[租约可扩展性问题](https://github.com/etcd-io/etcd/issues/9496)。

- [使用并发](https://github.com/etcd-io/etcd/pull/9229)[/](https://github.com/etcd-io/etcd/pull/9229)使[Lease`Lookup`非阻塞`Grant``Revoke`](https://github.com/etcd-io/etcd/pull/9229)。

- 

  ```
  raft.ErrProposalDropped
  ```

  在

  v3

   applier和

  v2

   applier 中使 etcd 服务器返回内部 Raft 提议下降。

  - 例如，一个节点从集群中移除，或者[`raftpb.MsgProp`在正在进行领导转移时到达当前领导](https://github.com/etcd-io/etcd/issues/8975)。

- 添加[`snapshot`](https://github.com/etcd-io/etcd/pull/9118)包以简化快照工作流程（[`godoc.org/github.com/etcd/clientv3/snapshot`](https://godoc.org/github.com/etcd-io/etcd/clientv3/snapshot)有关更多信息，请参见）。

- 提高[功能测试仪](https://github.com/etcd-io/etcd/tree/main/functional)覆盖：[代理层以在CI运行网络故障测试](https://github.com/etcd-io/etcd/pull/9081)，[TLS是用于服务器和客户端同时启用](https://github.com/etcd-io/etcd/pull/9534)，[活跃模式](https://github.com/etcd-io/etcd/issues/9230)，[随机播放测试序列](https://github.com/etcd-io/etcd/issues/9381)，[成员重新配置失败的情况下](https://github.com/etcd-io/etcd/pull/9564)，[灾难性的仲裁损失和快照从种子构件恢复](https://github.com/etcd-io/etcd/pull/9565)，[嵌入式ETCD](https://github.com/etcd-io/etcd/pull/9572)。

- 通过在写克隆时使用副本来改进[索引压缩阻塞](https://github.com/etcd-io/etcd/pull/9511)，以避免为整个索引的遍历持有锁。

- 更新[JWT 方法](https://github.com/etcd-io/etcd/pull/9883)以允许使用任何受支持的签名方法/算法。

- 添加

  租约检查点

  以定期将剩余的 TTL 持久化到共识日志中，以便在领导选举和服务器重新启动的情况下，长期租用会逐渐到期。

  - 由实验标志“--experimental-enable-lease-checkpoint”启用。

- 添加[gRPC 拦截器用于调试日志](https://github.com/etcd-io/etcd/pull/9990)；启用`etcd --debug`标志以查看每个请求的调试信息。

- [在快照状态中](https://github.com/etcd-io/etcd/pull/10109)添加[一致性检查](https://github.com/etcd-io/etcd/pull/10109)。如果快照文件的一致性检查失败，则`snapshot status`返回`"snapshot file integrity check failed..."`错误。

- 添加[`Verify`功能以对 WAL 内容执行损坏检查](https://github.com/etcd-io/etcd/pull/10603)。

- 改进[心跳发送失败日志记录](https://github.com/etcd-io/etcd/pull/10663)。

- 支持[无密码用户](https://github.com/etcd-io/etcd/pull/9817)，降低密码泄露带来的安全风险。用户只能使用`CommonName`基于身份验证的身份验证。

- 加入`etcd --experimental-peer-skip-client-san-verification`到[跳等客户端地址的验证](https://github.com/etcd-io/etcd/pull/10524)。

- 添加`etcd --experimental-compaction-batch-limit`到[设置在每个压缩批次中删除的最大修订](https://github.com/etcd-io/etcd/pull/11034)。

- 将默认压缩批量大小从 10k 修订版减少到 1k 修订版，以改善压缩期间的 p99 延迟，并将压缩之间的等待时间从 100 毫秒减少到 10 毫秒。

### 重大变化

- 使用[新的 gRPC 平衡器接口](https://github.com/etcd-io/etcd/issues/9106)重写

  客户端平衡器

  。

  

  

  - [将 gRPC](https://github.com/etcd-io/etcd/pull/10911)升级[到 v1.23.0](https://github.com/etcd-io/etcd/pull/10911)。

  - 

    针对安全端点

    改进[客户端平衡器故障转移](https://github.com/etcd-io/etcd/pull/10911)。

    - 修复[“当第一个 etcd-server 不可用时，kube-apiserver 1.13.x 拒绝工作”(kubernetes#72102)](https://github.com/kubernetes/kubernetes/issues/72102)。

  - 修复[gRPC 恐慌“在关闭的通道上发送”](https://github.com/etcd-io/etcd/issues/9956)。

  - [新的客户端平衡器](https://etcd.io/docs/latest/learning/design-client/)使用异步解析器将端点传递给 gRPC 拨号函数。要阻塞直到底层连接启动，请传递`grpc.WithBlock()`到`clientv3.Config.DialOptions`。

- 需要

  *Go 1.12+*

  。

  - 使用[*Go 1.12.9*](https://golang.org/doc/devel/release.html#go1.12)编译，包括[*Go 1.12.8*](https://groups.google.com/d/msg/golang-announce/65QixT3tcmg/DrFiG6vvCwAJ)安全修复。

- 从迁移依赖管理工具

  ```
  glide
  ```

  来

  启动模块

  。

  - <= 3.3 将`vendor`目录放在目录下`cmd/vendor`以[防止冲突的传递依赖项](https://github.com/etcd-io/etcd/issues/4913)。
  - 3.4 将`cmd/vendor`目录移动到`vendor`存储库根目录。
  - 删除`cmd`目录中的递归符号链接。
  - 现在`go get/install/build`在`etcd`包（例如`clientv3`，`tools/benchmark`）上使用 etcd`vendor`目录强制构建。

- 弃用的

  ```
  latest
  ```

   

  发布容器

  标签。

  - **`docker pull gcr.io/etcd-development/etcd:latest`不会是最新的**。

- 已弃用的

  次要

  版本

  发布容器

  标签。

  - `docker pull gcr.io/etcd-development/etcd:v3.3` 仍然会工作。
  - **`docker pull gcr.io/etcd-development/etcd:v3.4`不行**。
  - 改用**`docker pull gcr.io/etcd-development/etcd:v3.4.x`**确切的补丁版本。

- 

  官方版本中

  已弃用的[ACI](https://github.com/etcd-io/etcd/pull/9059)。

  - [AppC 于](https://github.com/appc/spec#-disclaimer-)2016 年底[正式暂停](https://github.com/appc/spec#-disclaimer-)。
  - [`acbuild`](https://github.com/containers/build#this-project-is-currently-unmaintained) 不再维护。
  - `*.aci`文件在`v3.4`发布时不可用。

- 移动

  `"github.com/coreos/etcd"`

  到

  `"github.com/etcd-io/etcd"`

  。

  - 将导入路径更改为`"go.etcd.io/etcd"`.
  - 例如`import "go.etcd.io/etcd/raft"`。

- 设为

  `ETCDCTL_API=3 etcdctl`默认

  。

  - 现在，`etcdctl set foo bar`必须是`ETCDCTL_API=2 etcdctl set foo bar`。
  - 现在，`ETCDCTL_API=3 etcdctl put foo bar`可能只是`etcdctl put foo bar`.

- 设为[`etcd --enable-v2=false`默认](https://github.com/etcd-io/etcd/pull/10935)。

- 设为[`embed.DefaultEnableV2` `false`默认](https://github.com/etcd-io/etcd/pull/10935)。

- **弃用的`etcd --ca-file`标志**。使用[`etcd --trusted-ca-file`](https://github.com/etcd-io/etcd/pull/9470)替代（`etcd --ca-file`标志已经标志着自V2.1不建议使用）。

- **弃用的`etcd --peer-ca-file`标志**。使用[`etcd --peer-trusted-ca-file`](https://github.com/etcd-io/etcd/pull/9470)替代（`etcd --peer-ca-file`标志已经标志着自V2.1不建议使用）。

- **弃用的`pkg/transport.TLSInfo.CAFile`字段**。[`pkg/transport.TLSInfo.TrustedCAFile`](https://github.com/etcd-io/etcd/pull/9470)改为使用（`CAFile`自 v2.1 以来，该字段已被标记为已弃用）。

- 

  在广告 URL 中的空主机

  上退出。

  - 地址[广告客户端 URL 接受空主机](https://github.com/etcd-io/etcd/issues/8379)。
  - 例如退出时出错`--advertise-client-urls=http://:2379`。
  - 例如退出时出错`--initial-advertise-peer-urls=http://:2380`。

- 退出

  隐藏的环境变量

  。

  - [隐藏环境变量的](https://github.com/etcd-io/etcd/issues/8380)地址[错误](https://github.com/etcd-io/etcd/issues/8380)。
  - 例如退出时出错`ETCD_NAME=abc etcd --name=def`。
  - 例如退出时出错`ETCD_INITIAL_CLUSTER_TOKEN=abc etcd --initial-cluster-token=def`。
  - 例如退出时出错`ETCDCTL_ENDPOINTS=abc.com ETCDCTL_API=3 etcdctl endpoint health --endpoints=def.com`。

- 将[`etcdserverpb.AuthRoleRevokePermissionRequest/key,range_end`字段类型从`string``bytes`](https://github.com/etcd-io/etcd/pull/9433)更改[为](https://github.com/etcd-io/etcd/pull/9433)。

- 弃用`etcd_debugging_mvcc_db_total_size_in_bytes`Prometheus 指标（将在 v3.5 中删除）。使用[`etcd_mvcc_db_total_size_in_bytes`](https://github.com/etcd-io/etcd/pull/9819)来代替。

- 弃用`etcd_debugging_mvcc_put_total`Prometheus 指标（将在 v3.5 中删除）。使用[`etcd_mvcc_put_total`](https://github.com/etcd-io/etcd/pull/10962)来代替。

- 弃用`etcd_debugging_mvcc_delete_total`Prometheus 指标（将在 v3.5 中删除）。使用[`etcd_mvcc_delete_total`](https://github.com/etcd-io/etcd/pull/10962)来代替。

- 弃用`etcd_debugging_mvcc_range_total`Prometheus 指标（将在 v3.5 中删除）。使用[`etcd_mvcc_range_total`](https://github.com/etcd-io/etcd/pull/10968)来代替。

- 弃用`etcd_debugging_mvcc_txn_total`Prometheus 指标（将在 v3.5 中删除）。使用[`etcd_mvcc_txn_total`](https://github.com/etcd-io/etcd/pull/10968)来代替。

- 将`etcdserver.ServerConfig.SnapCount`字段重命名为`etcdserver.ServerConfig.SnapshotCount`，以与标志名称一致`etcd --snapshot-count`。

- 将`embed.Config.SnapCount`字段重命名为[`embed.Config.SnapshotCount`](https://github.com/etcd-io/etcd/pull/9745)，以与标志名称一致`etcd --snapshot-count`。

- 更改[`embed.Config.CorsInfo`在`*cors.CORSInfo`类型`embed.Config.CORS`的`map[string\]struct{}`类型](https://github.com/etcd-io/etcd/pull/9490)。

- 已弃用

  `embed.Config.SetupLogging`

  。

  - 现在记录器是根据[`embed.Config.Logger`, `embed.Config.LogOutputs`,`embed.Config.Debug`字段](https://github.com/etcd-io/etcd/pull/9572)自动设置的。

- 重命名

  `etcd --log-output`为`etcd --log-outputs`

  以支持多个日志输出。

  - **`etcd --log-output`** 将在 v3.5 中弃用。

- 重命名[**`embed.Config.LogOutput`**为**`embed.Config.LogOutputs`**](https://github.com/etcd-io/etcd/pull/9624)以支持多个日志输出。

- 变化

  **`embed.Config.LogOutputs`**从类型`string`到`[]string`

  支持多种日志输出。

  - 现在`etcd --log-outputs`接受多个 writers，etcd 配置 YAML 文件`log-outputs`字段必须更改为`[]string`type。
  - 以前，`etcd --config-file etcd.config.yaml`可以有`log-outputs: default`字段，现在必须是`log-outputs: [default]`。

- 弃用

  `etcd --debug`

  标志。改用

  ```
  etcd --log-level=debug
  ```

  标志。

  - v3.5 将弃用`etcd --debug`flag 以支持`etcd --log-level=debug`.

- 

  ```
  etcdctl snapshot
  ```

  使用

  `snapshot`package

  更改 v3退出代码。

  - 错误退出，退出代码 1（不再有退出代码 5 或 6`snapshot save/restore`命令）。

- 已弃用

  `grpc.ErrClientConnClosing`

  。

  - `clientv3`而`proxy/grpcproxy`现在不返回`grpc.ErrClientConnClosing`。
  - `grpc.ErrClientConnClosing`已[在 gRPC >= 1.10 中弃用](https://github.com/grpc/grpc-go/pull/1854)。
  - 使用`clientv3.IsConnCanceled(error)`或`google.golang.org/grpc/status.FromError(error)`代替。

- 已过时

  GRPC网关

  端点

  ```
  /v3beta
  ```

  使用

  `/v3`

  。

  - 已弃用[`/v3alpha`](https://github.com/etcd-io/etcd/pull/9298)。
  - [`/v3beta`](https://github.com/etcd-io/etcd/issues/9189)在 v3.5 中弃用。
  - 在 v3.4 中，`curl -L http://localhost:2379/v3beta/kv/put -X POST -d '{"key": "Zm9v", "value": "YmFy"}'`仍然可以作为 的后备`curl -L http://localhost:2379/v3/kv/put -X POST -d '{"key": "Zm9v", "value": "YmFy"}'`，但`curl -L http://localhost:2379/v3beta/kv/put -X POST -d '{"key": "Zm9v", "value": "YmFy"}'`在 v3.5 中不起作用。使用`curl -L http://localhost:2379/v3/kv/put -X POST -d '{"key": "Zm9v", "value": "YmFy"}'`来代替。

- 更改

  `wal`包函数签名

  以支持

  结构化记录器和

  服务器端[记录到文件](https://github.com/etcd-io/etcd/issues/9438)。

  - 以前`Open(dirpath string, snap walpb.Snapshot) (*WAL, error)`，现在`Open(lg *zap.Logger, dirpath string, snap walpb.Snapshot) (*WAL, error)`。
  - 以前`OpenForRead(dirpath string, snap walpb.Snapshot) (*WAL, error)`，现在`OpenForRead(lg *zap.Logger, dirpath string, snap walpb.Snapshot) (*WAL, error)`。
  - 以前`Repair(dirpath string) bool`，现在`Repair(lg *zap.Logger, dirpath string) bool`。
  - 以前`Create(dirpath string, metadata []byte) (*WAL, error)`，现在`Create(lg *zap.Logger, dirpath string, metadata []byte) (*WAL, error)`。

- 删除[`pkg/cors`包](https://github.com/etcd-io/etcd/pull/9490)。

- 将内部包移动到

  ```
  etcdserver
  ```

  .

  - `"github.com/coreos/etcd/alarm"`到`"go.etcd.io/etcd/etcdserver/api/v3alarm"`。
  - `"github.com/coreos/etcd/compactor"`到`"go.etcd.io/etcd/etcdserver/api/v3compactor"`。
  - `"github.com/coreos/etcd/discovery"`到`"go.etcd.io/etcd/etcdserver/api/v2discovery"`。
  - `"github.com/coreos/etcd/etcdserver/auth"`到`"go.etcd.io/etcd/etcdserver/api/v2auth"`。
  - `"github.com/coreos/etcd/etcdserver/membership"`到`"go.etcd.io/etcd/etcdserver/api/membership"`。
  - `"github.com/coreos/etcd/etcdserver/stats"`到`"go.etcd.io/etcd/etcdserver/api/v2stats"`。
  - `"github.com/coreos/etcd/error"`到`"go.etcd.io/etcd/etcdserver/api/v2error"`。
  - `"github.com/coreos/etcd/rafthttp"`到`"go.etcd.io/etcd/etcdserver/api/rafthttp"`。
  - `"github.com/coreos/etcd/snap"`到`"go.etcd.io/etcd/etcdserver/api/snap"`。
  - `"github.com/coreos/etcd/store"`到`"go.etcd.io/etcd/etcdserver/api/v2store"`。

- 更改[快照文件权限](https://github.com/etcd-io/etcd/pull/9977)：在 Linux 上，快照文件从所有人可读（模式 0644）更改为仅用户可读（模式 0600）。

- 

  `pkg/adt.IntervalTree`从`struct``interface`

  更改[为](https://github.com/etcd-io/etcd/pull/10959)。

  - 请参阅[`pkg/adt`自述文件](https://github.com/etcd-io/etcd/tree/main/pkg/adt)和[`pkg/adt`godoc](https://godoc.org/go.etcd.io/etcd/pkg/adt)。

- Release 分支

  ```
  /version
  ```

  定义 version 

  ```
  3.4.x-pre
  ```

  ，而不是

  ```
  3.4.y+git
  ```

  .

  - 使用`3.4.5-pre`, 而不是`3.4.4+git`。

### 依赖

- [`github.com/coreos/bbolt`](https://github.com/etcd-io/bbolt/releases)从升级[**`v1.3.1-coreos.6`**](https://github.com/etcd-io/bbolt/releases/tag/v1.3.1-coreos.6)到.[`go.etcd.io/bbolt`](https://github.com/etcd-io/bbolt/releases) [**`v1.3.3`**](https://github.com/etcd-io/bbolt/releases/tag/v1.3.3)
- [`google.golang.org/grpc`](https://github.com/grpc/grpc-go/releases)从升级[**`v1.7.5`**](https://github.com/grpc/grpc-go/releases/tag/v1.7.5)到[**`v1.23.0`**](https://github.com/grpc/grpc-go/releases/tag/v1.23.0).
- 迁移[`github.com/ugorji/go/codec`](https://github.com/ugorji/go/releases)到[**`github.com/json-iterator/go`**](https://github.com/json-iterator/go), 以[重新生成 v2`client`](https://github.com/etcd-io/etcd/pull/9494)（有关更多信息，请参阅[#10667](https://github.com/etcd-io/etcd/pull/10667)）。
- 迁移[`github.com/ghodss/yaml`](https://github.com/ghodss/yaml/releases)到[**`sigs.k8s.io/yaml`**](https://github.com/kubernetes-sigs/yaml)（有关更多信息，请参阅[#10687](https://github.com/etcd-io/etcd/pull/10687)）。
- [`golang.org/x/crypto`](https://github.com/golang/crypto)从升级[**`crypto@9419663f5`**](https://github.com/golang/crypto/commit/9419663f5a44be8b34ca85f08abc5fe1be11f8a3)到[**`crypto@0709b304e793`**](https://github.com/golang/crypto/commit/0709b304e793a5edb4a2c0145f281ecdc20838a4).
- [`golang.org/x/net`](https://github.com/golang/net)从升级[**`net@66aacef3d`**](https://github.com/golang/net/commit/66aacef3dd8a676686c7ae3716979581e8b03c47)到[**`net@adae6a3d119a`**](https://github.com/golang/net/commit/adae6a3d119ae4890b46832a2e88a95adc62b8e7).
- [`golang.org/x/sys`](https://github.com/golang/sys)从升级[**`sys@ebfc5b463`**](https://github.com/golang/sys/commit/ebfc5b4631820b793c9010c87fd8fef0f39eb082)到[**`sys@c7b8b68b1456`**](https://github.com/golang/sys/commit/c7b8b68b14567162c6602a7c5659ee0f26417c18).
- [`golang.org/x/text`](https://github.com/golang/text)从升级[**`text@b19bf474d`**](https://github.com/golang/text/commit/b19bf474d317b857955b12035d2c5acb57ce8b01)到[**`v0.3.0`**](https://github.com/golang/text/releases/tag/v0.3.0).
- [`golang.org/x/time`](https://github.com/golang/time)从升级[**`time@c06e80d93`**](https://github.com/golang/time/commit/c06e80d9300e4443158a03817b8a8cb37d230320)到[**`time@fbb02b229`**](https://github.com/golang/time/commit/fbb02b2291d28baffd63558aa44b4b56f178d650).
- [`github.com/golang/protobuf`](https://github.com/golang/protobuf/releases)从升级[**`golang/protobuf@1e59b77b5`**](https://github.com/golang/protobuf/commit/1e59b77b52bf8e4b449a57e6f79f21226d571845)到[**`v1.3.2`**](https://github.com/golang/protobuf/releases/tag/v1.3.2).
- [`gopkg.in/yaml.v2`](https://github.com/go-yaml/yaml/releases)从升级[**`yaml@cd8b52f82`**](https://github.com/go-yaml/yaml/commit/cd8b52f8269e0feb286dfeef29f8fe4d5b397e0b)到[**`yaml@5420a8b67`**](https://github.com/go-yaml/yaml/commit/5420a8b6744d3b0345ab293f6fcba19c978f1183).
- [`github.com/dgrijalva/jwt-go`](https://github.com/dgrijalva/jwt-go/releases)从升级[**`v3.0.0`**](https://github.com/dgrijalva/jwt-go/releases/tag/v3.0.0)到[**`v3.2.0`**](https://github.com/dgrijalva/jwt-go/releases/tag/v3.2.0).
- [`github.com/soheilhy/cmux`](https://github.com/soheilhy/cmux/releases)从升级[**`v0.1.3`**](https://github.com/soheilhy/cmux/releases/tag/v0.1.3)到[**`v0.1.4`**](https://github.com/soheilhy/cmux/releases/tag/v0.1.4).
- [`github.com/google/btree`](https://github.com/google/btree/releases)从升级[**`google/btree@925471ac9`**](https://github.com/google/btree/commit/925471ac9e2131377a91e1595defec898166fe49)到[**`v1.0.0`**](https://github.com/google/btree/releases/tag/v1.0.0).
- [`github.com/spf13/cobra`](https://github.com/spf13/cobra/releases)从升级[**`spf13/cobra@1c44ec8d3`**](https://github.com/spf13/cobra/commit/1c44ec8d3f1552cac48999f9306da23c4d8a288b)到[**`v0.0.3`**](https://github.com/spf13/cobra/releases/tag/v0.0.3).
- [`github.com/spf13/pflag`](https://github.com/spf13/pflag/releases)从升级[**`v1.0.0`**](https://github.com/spf13/pflag/releases/tag/v1.0.0)到[**`spf13/pflag@1ce0cc6db`**](https://github.com/spf13/pflag/commit/1ce0cc6db4029d97571db82f85092fccedb572ce).
- [`github.com/coreos/go-systemd`](https://github.com/coreos/go-systemd/releases)从升级[**`v15`**](https://github.com/coreos/go-systemd/releases/tag/v15)到[**`v17`**](https://github.com/coreos/go-systemd/releases/tag/v17).
- [`github.com/prometheus/client_golang`](https://github.com/prometheus/client_golang/releases)从升级[**`prometheus/client_golang@5cec1d042`**](https://github.com/prometheus/client_golang/commit/5cec1d0429b02e4323e042eb04dafdb079ddf568)到[**`v1.0.0`**](https://github.com/prometheus/client_golang/releases/tag/v1.0.0).
- [`github.com/grpc-ecosystem/go-grpc-prometheus`](https://github.com/grpc-ecosystem/go-grpc-prometheus/releases)从升级[**`grpc-ecosystem/go-grpc-prometheus@0dafe0d49`**](https://github.com/grpc-ecosystem/go-grpc-prometheus/commit/0dafe0d496ea71181bf2dd039e7e3f44b6bd11a7)到[**`v1.2.0`**](https://github.com/grpc-ecosystem/go-grpc-prometheus/releases/tag/v1.2.0).
- [`github.com/grpc-ecosystem/grpc-gateway`](https://github.com/grpc-ecosystem/grpc-gateway/releases)从升级[**`v1.3.1`**](https://github.com/grpc-ecosystem/grpc-gateway/releases/tag/v1.3.1)到[**`v1.4.1`**](https://github.com/grpc-ecosystem/grpc-gateway/releases/tag/v1.4.1).
- 迁移[`github.com/kr/pty`](https://github.com/kr/pty/releases)到[**`github.com/creack/pty`**](https://github.com/creack/pty/releases/tag/v1.1.7)，因为后者已经替换了原来的模块。
- [`github.com/gogo/protobuf`](https://github.com/gogo/protobuf/releases)从升级[**`v1.0.0`**](https://github.com/gogo/protobuf/releases/tag/v1.0.0)到[**`v1.2.1`**](https://github.com/gogo/protobuf/releases/tag/v1.2.1).

### 指标、监控

请参阅每个版本的所有指标[的指标列表](https://etcd.io/docs/latest/metrics/)。

请注意，任何`etcd_debugging_*`指标都是实验性的，可能会发生变化。

- 添加[`etcd_snap_db_fsync_duration_seconds_count`](https://github.com/etcd-io/etcd/pull/9997)普罗米修斯指标。

- 添加[`etcd_snap_db_save_total_duration_seconds_bucket`](https://github.com/etcd-io/etcd/pull/9997)普罗米修斯指标。

- 添加[`etcd_network_snapshot_send_success`](https://github.com/etcd-io/etcd/pull/9997)普罗米修斯指标。

- 添加[`etcd_network_snapshot_send_failures`](https://github.com/etcd-io/etcd/pull/9997)普罗米修斯指标。

- 添加[`etcd_network_snapshot_send_total_duration_seconds`](https://github.com/etcd-io/etcd/pull/9997)普罗米修斯指标。

- 添加[`etcd_network_snapshot_receive_success`](https://github.com/etcd-io/etcd/pull/9997)普罗米修斯指标。

- 添加[`etcd_network_snapshot_receive_failures`](https://github.com/etcd-io/etcd/pull/9997)普罗米修斯指标。

- 添加[`etcd_network_snapshot_receive_total_duration_seconds`](https://github.com/etcd-io/etcd/pull/9997)普罗米修斯指标。

- 添加

  `etcd_network_active_peers`

  普罗米修斯指标。

  - 假设`"7339c4e5e833c029"`服务器`/metrics`返回`etcd_network_active_peers{Local="7339c4e5e833c029",Remote="729934363faa4a24"} 1`和`etcd_network_active_peers{Local="7339c4e5e833c029",Remote="b548c2511513015"} 1`。这表明本地节点`"7339c4e5e833c029"`当前有两个活动的远程对等点`"729934363faa4a24"`并且`"b548c2511513015"`在一个 3 节点集群中。如果节点`"b548c2511513015"`关闭，本地节点`"7339c4e5e833c029"`将显示`etcd_network_active_peers{Local="7339c4e5e833c029",Remote="729934363faa4a24"} 1`和`etcd_network_active_peers{Local="7339c4e5e833c029",Remote="b548c2511513015"} 0`。

- 添加

  `etcd_network_disconnected_peers_total`

  普罗米修斯指标。

  - 如果远程对等方`"b548c2511513015"`关闭，本地节点`"7339c4e5e833c029"`服务器`/metrics`将返回`etcd_network_disconnected_peers_total{Local="7339c4e5e833c029",Remote="b548c2511513015"} 1`，而活动对等方指标将显示`etcd_network_active_peers{Local="7339c4e5e833c029",Remote="729934363faa4a24"} 1`和`etcd_network_active_peers{Local="7339c4e5e833c029",Remote="b548c2511513015"} 0`。

- 添加

  `etcd_network_server_stream_failures_total`

  普罗米修斯指标。

  - 例如 `etcd_network_server_stream_failures_total{API="lease-keepalive",Type="receive"} 1`
  - 例如 `etcd_network_server_stream_failures_total{API="watch",Type="receive"} 1`

- 改进

  `etcd_network_peer_round_trip_time_seconds`

  Prometheus 指标以跟踪领导者的心跳。

  - 以前，它仅对快照消息的 TCP 连接进行采样。

- 增加

  `etcd_network_peer_round_trip_time_seconds`

  Prometheus 度量直方图上限。

  - 以前，最高存储桶仅收集耗时 0.8192 秒或更长时间的请求。
  - 现在，最高桶收集 0.8192 秒、1.6384 秒和 3.2768 秒或更多。

- 添加[`etcd_server_is_leader`](https://github.com/etcd-io/etcd/pull/9587)普罗米修斯指标。

- 添加[`etcd_server_id`](https://github.com/etcd-io/etcd/pull/9998)普罗米修斯指标。

- 添加[`etcd_cluster_version`](https://github.com/etcd-io/etcd/pull/10257)普罗米修斯指标。

- 添加

  `etcd_server_version`

  普罗米修斯指标。

  - 替换[Kubernetes`etcd-version-monitor`](https://github.com/etcd-io/etcd/issues/8948)。

- 添加[`etcd_server_go_version`](https://github.com/etcd-io/etcd/pull/9957)普罗米修斯指标。

- 添加[`etcd_server_health_success`](https://github.com/etcd-io/etcd/pull/10156)普罗米修斯指标。

- 添加[`etcd_server_health_failures`](https://github.com/etcd-io/etcd/pull/10156)普罗米修斯指标。

- 添加[`etcd_server_read_indexes_failed_total`](https://github.com/etcd-io/etcd/pull/10094)普罗米修斯指标。

- 添加[`etcd_server_heartbeat_send_failures_total`](https://github.com/etcd-io/etcd/pull/9761)普罗米修斯指标。

- 添加[`etcd_server_slow_apply_total`](https://github.com/etcd-io/etcd/pull/9761)普罗米修斯指标。

- 添加[`etcd_server_slow_read_indexes_total`](https://github.com/etcd-io/etcd/pull/9897)普罗米修斯指标。

- 添加

  `etcd_server_quota_backend_bytes`

  普罗米修斯指标。

  - 与`etcd_mvcc_db_total_size_in_bytes`和一起使用`etcd_mvcc_db_total_size_in_use_in_bytes`。
  - `etcd_server_quota_backend_bytes 2.147483648e+09` 表示当前配额大小为 2 GB。
  - `etcd_mvcc_db_total_size_in_bytes 20480` 表示当前物理分配的 DB 大小为 20 KB。
  - `etcd_mvcc_db_total_size_in_use_in_bytes 16384` 如果碎片整理操作完成，则表示未来的数据库大小。
  - `etcd_mvcc_db_total_size_in_bytes - etcd_mvcc_db_total_size_in_use_in_bytes` 是可以通过碎片整理操作保存在磁盘上的字节数。

- 添加

  `etcd_mvcc_db_total_size_in_use_in_bytes`

  普罗米修斯指标。

  - 与`etcd_mvcc_db_total_size_in_bytes`和一起使用`etcd_mvcc_db_total_size_in_use_in_bytes`。
  - `etcd_server_quota_backend_bytes 2.147483648e+09` 表示当前配额大小为 2 GB。
  - `etcd_mvcc_db_total_size_in_bytes 20480` 表示当前物理分配的 DB 大小为 20 KB。
  - `etcd_mvcc_db_total_size_in_use_in_bytes 16384` 如果碎片整理操作完成，则表示未来的数据库大小。
  - `etcd_mvcc_db_total_size_in_bytes - etcd_mvcc_db_total_size_in_use_in_bytes` 是可以通过碎片整理操作保存在磁盘上的字节数。

- 添加[`etcd_mvcc_db_open_read_transactions`](https://github.com/etcd-io/etcd/pull/10523/commits/ad80752715aaed449629369687c5fd30eb1bda76)普罗米修斯指标。

- 添加[`etcd_snap_fsync_duration_seconds`](https://github.com/etcd-io/etcd/pull/9762)普罗米修斯指标。

- 添加[`etcd_disk_backend_defrag_duration_seconds`](https://github.com/etcd-io/etcd/pull/9761)普罗米修斯指标。

- 添加[`etcd_mvcc_hash_duration_seconds`](https://github.com/etcd-io/etcd/pull/9761)普罗米修斯指标。

- 添加[`etcd_mvcc_hash_rev_duration_seconds`](https://github.com/etcd-io/etcd/pull/9761)普罗米修斯指标。

- 添加[`etcd_debugging_disk_backend_commit_rebalance_duration_seconds`](https://github.com/etcd-io/etcd/pull/9834)普罗米修斯指标。

- 添加[`etcd_debugging_disk_backend_commit_spill_duration_seconds`](https://github.com/etcd-io/etcd/pull/9834)普罗米修斯指标。

- 添加[`etcd_debugging_disk_backend_commit_write_duration_seconds`](https://github.com/etcd-io/etcd/pull/9834)普罗米修斯指标。

- 添加[`etcd_debugging_lease_granted_total`](https://github.com/etcd-io/etcd/pull/9778)普罗米修斯指标。

- 添加[`etcd_debugging_lease_revoked_total`](https://github.com/etcd-io/etcd/pull/9778)普罗米修斯指标。

- 添加[`etcd_debugging_lease_renewed_total`](https://github.com/etcd-io/etcd/pull/9778)普罗米修斯指标。

- 添加[`etcd_debugging_lease_ttl_total`](https://github.com/etcd-io/etcd/pull/9778)普罗米修斯指标。

- 添加[`etcd_network_snapshot_send_inflights_total`](https://github.com/etcd-io/etcd/pull/11009)普罗米修斯指标。

- 添加[`etcd_network_snapshot_receive_inflights_total`](https://github.com/etcd-io/etcd/pull/11009)普罗米修斯指标。

- 添加[`etcd_server_snapshot_apply_in_progress_total`](https://github.com/etcd-io/etcd/pull/11009)普罗米修斯指标。

- 添加[`etcd_server_is_learner`](https://github.com/etcd-io/etcd/pull/10731)普罗米修斯指标。

- 添加[`etcd_server_learner_promote_failures`](https://github.com/etcd-io/etcd/pull/10731)普罗米修斯指标。

- 添加[`etcd_server_learner_promote_successes`](https://github.com/etcd-io/etcd/pull/10731)普罗米修斯指标。

- 增加

  `etcd_debugging_mvcc_index_compaction_pause_duration_milliseconds`

  Prometheus 度量直方图上限。

  - 以前，最高存储桶仅收集耗时 1.024 秒或更长时间的请求。
  - 现在，最高桶收集 1.024 秒、2.048 秒和 4.096 秒或更多。

- 修复丢失的[`etcd_network_peer_sent_failures_total`](https://github.com/etcd-io/etcd/pull/9437)Prometheus 指标计数。

- 修复[`etcd_debugging_server_lease_expired_total`](https://github.com/etcd-io/etcd/pull/9557)Prometheus 指标。

- 修复[v2 服务器统计信息收集中的竞争条件](https://github.com/etcd-io/etcd/pull/9562)。

- 更改

  gRPC 代理以公开 etcd 服务器端点 /metrics

  。

  - 通过代理公开的指标不是 etcd 服务器成员，而是代理本身。

- 修复[db_compaction_total_duration_milliseconds 指标错误地将持续时间测量为 0 的错误](https://github.com/etcd-io/etcd/pull/10646)。

- 弃用`etcd_debugging_mvcc_db_total_size_in_bytes`Prometheus 指标（将在 v3.5 中删除）。使用[`etcd_mvcc_db_total_size_in_bytes`](https://github.com/etcd-io/etcd/pull/9819)来代替。

- 弃用`etcd_debugging_mvcc_put_total`Prometheus 指标（将在 v3.5 中删除）。使用[`etcd_mvcc_put_total`](https://github.com/etcd-io/etcd/pull/10962)来代替。

- 弃用`etcd_debugging_mvcc_delete_total`Prometheus 指标（将在 v3.5 中删除）。使用[`etcd_mvcc_delete_total`](https://github.com/etcd-io/etcd/pull/10962)来代替。

- 弃用`etcd_debugging_mvcc_range_total`Prometheus 指标（将在 v3.5 中删除）。使用[`etcd_mvcc_range_total`](https://github.com/etcd-io/etcd/pull/10968)来代替。

- 弃用`etcd_debugging_mvcc_txn_total`Prometheus 指标（将在 v3.5 中删除）。使用[`etcd_mvcc_txn_total`](https://github.com/etcd-io/etcd/pull/10968)来代替。

### 安全、认证

有关更多详细信息，请参阅[安全文档](https://etcd.io/docs/latest/op-guide/security/)。

- 支持 TLS 密码套件白名单。

  - 阻止[弱密码套件](https://github.com/etcd-io/etcd/issues/8320)。
  - 当使用无效的密码套件请求客户端 hello 时，TLS 握手失败。
  - 添加[`etcd --cipher-suites`](https://github.com/etcd-io/etcd/pull/9801)标志。
  - 如果为空，Go 会自动填充列表。

- 添加

  `etcd --host-whitelist`

  标志、

  `etcdserver.Config.HostWhitelist`

  、 和

  `embed.Config.HostWhitelist`

  ，以防止

  “DNS 重新绑定”

  攻击。

  - 任何网站都可以简单地创建一个授权的 DNS 名称，并将 DNS 定向到`"localhost"`（或任何其他地址）。然后，etcd 服务器侦听的所有 HTTP 端点`"localhost"`都可以访问，因此容易受到[DNS 重新绑定攻击 (CVE-2018-5702)](https://bugs.chromium.org/p/project-zero/issues/detail?id=1447#c2)。
  - 客户端源执行策略的工作原理如下：
    - 如果客户端连接通过 HTTPS 是安全的，请允许任何主机名..
    - 如果客户端连接不安全`"HostWhitelist"`且不为空，则只允许 Host 字段在白名单中的 HTTP 请求。
  - 默认情况下，`"HostWhitelist"`is `"*"`，这意味着不安全的服务器允许所有客户端 HTTP 请求。
  - 请注意，无论是否启用身份验证，都会强制执行客户端源策略，以实现更严格的控制。
  - 指定主机名时，不会自动添加环回地址。为了允许环回接口，将它们添加到白名单中手动（例如`"localhost"`，`"127.0.0.1"`等）。
  - 例如`etcd --host-whitelist example.com`，服务器将拒绝所有主机字段不是的 HTTP 请求`example.com`（也拒绝对 的请求`"localhost"`）。

- 支持[`etcd --cors`](https://github.com/etcd-io/etcd/pull/9490)v3 HTTP 请求（gRPC 网关）。

- [身份验证 JWT 令牌的](https://github.com/etcd-io/etcd/pull/8302)支持

  `ttl`字段`etcd`

  。

  - 例如`etcd --auth-token jwt,pub-key=<pub key path>,priv-key=<priv key path>,sign-method=<sign method>,ttl=5m`。

- 允许在[`etcdserver.ServerConfig.AuthToken`](https://github.com/etcd-io/etcd/pull/9369).

- 修复[证书 SAN 字段仅包含 IP 地址但不包含域名](https://github.com/etcd-io/etcd/issues/9541)时的

  TLS 重新加载

  。

  

  

  - 在 Go 中，`(*tls.Config).GetCertificate`当且仅当服务器的`(*tls.Config).Certificates`字段不为空，或者`(*tls.ClientHelloInfo).ServerName`不为空且来自客户端的有效 SNI 时，服务器才会调用TLS 重新加载。以前，etcd 总是`(*tls.Config).Certificates`在初始客户端 TLS 握手时填充，作为非空。因此，客户端总是需要提供匹配的 SNI 以通过 TLS 验证并触发`(*tls.Config).GetCertificate`重新加载 TLS 资产。
  - 但是，如果证书的 SAN 字段不[包含任何域名而只包含 IP 地址，](https://github.com/etcd-io/etcd/issues/9541)则会请求`*tls.ClientHelloInfo`一个空`ServerName`字段，从而无法在初始 TLS 握手时触发 TLS 重新加载；当过期的证书需要在线更换时，这就会成为一个问题。
  - 现在，`(*tls.Config).Certificates`在初始 TLS 客户端握手时创建为空，首先触发`(*tls.Config).GetCertificate`，然后在每个新的 TLS 连接上填充其余证书，即使客户端 SNI 为空（例如，证书仅包含 IP）。

### etcd服务器

- 添加

  `rpctypes.ErrLeaderChanged`

  .

  - 现在，当领导层发生变化时，带有读取索引的线性化请求会快速失败，而不是等到上下文超时。

- 添加

  `etcd --initial-election-tick-advance`

  标志以配置初始选举勾选快进。

  - 默认情况下，`etcd --initial-election-tick-advance=true`，然后本地成员快进选举滴答声以加快“初始”领导选举触发器。
  - 这有利于较大的选举刻度的情况。例如，跨数据中心部署可能需要更长的 10 秒选举超时。如果为 true，本地节点不需要等待最多 10 秒。取而代之的是，将其选举时间提前到 8 秒，并且在领导者选举前只剩下 2 秒了。
  - 主要假设是：集群没有活跃的领导者，因此提前滴答可以加快领导者选举。或者集群已经有一个已建立的leader，重新加入follower很可能在tick之前和选举超时之前收到leader的心跳。
  - 然而，当从leader到重新加入follower的网络拥塞，并且follower在左选举tick内没有收到leader心跳时，就会发生破坏性选举，从而影响集群可用性。
  - 现在，这可以通过设置禁用`etcd --initial-election-tick-advance=false`。
  - 禁用此功能会减慢跨数据中心部署的初始引导过程。通过`etcd --initial-election-tick-advance`以缓慢的初始引导为代价进行配置来进行权衡。
  - 如果是单节点，它无论如何都会前进。
  - 解决[重新加入跟随者节点的破坏性问题](https://github.com/etcd-io/etcd/issues/9333)。

- 添加

  `etcd --pre-vote`

  标志以启用运行额外的 Raft 选举阶段。

  - 例如，一个不稳定（或重新加入）的成员可能会进出，并开始竞选。该成员将以更高的任期结束，并忽略所有具有更低任期的传入消息。在这种情况下，最终需要选出新的领导者，从而破坏集群可用性。Raft 实施 Pre-Vote 阶段来防止这种中断。If enabled, Raft runs an additional phase of election to check if pre-candidate can get enough votes to win an election.
  - `etcd --pre-vote=false` 默认情况下。
  - v3.5 将`etcd --pre-vote=true`默认启用。

- 添加`etcd --experimental-compaction-batch-limit`到[设置在每个压缩批次中删除的最大修订](https://github.com/etcd-io/etcd/pull/11034)。

- 将默认压缩批量大小从 10k 修订版减少到 1k 修订版，以改善压缩期间的 p99 延迟，并将压缩之间的等待时间从 100 毫秒减少到 10 毫秒。

- 添加

  `etcd --discovery-srv-name`

  标志以支持具有发现功能的自定义 DNS SRV 名称。

  - 如果没有给出，etcd 查询`_etcd-server-ssl._tcp.[YOUR_HOST]`和`_etcd-server._tcp.[YOUR_HOST]`.
  - 如果`etcd --discovery-srv-name="foo"`，则查询`_etcd-server-ssl-foo._tcp.[YOUR_HOST]`和`_etcd-server-foo._tcp.[YOUR_HOST]`。
  - 用于在同一域下操作多个 etcd 集群。

- 支持 TLS 密码套件白名单。

  - 阻止[弱密码套件](https://github.com/etcd-io/etcd/issues/8320)。
  - 当使用无效的密码套件请求客户端 hello 时，TLS 握手失败。
  - 添加[`etcd --cipher-suites`](https://github.com/etcd-io/etcd/pull/9801)标志。
  - 如果为空，Go 会自动填充列表。

- 支持[`etcd --cors`](https://github.com/etcd-io/etcd/pull/9490)v3 HTTP 请求（gRPC 网关）。

- 重命名

  `etcd --log-output`为`etcd --log-outputs`

  以支持多个日志输出。

  - **`etcd --log-output`将在 v3.5 中弃用**。

- 添加

  `etcd --logger`

  标志以支持服务器端的

  结构化记录器和多个日志输出

  。

  - **`etcd --logger=capnslog`将在 v3.5 中弃用**。

  - 主要动机是促进自动化 etcd 监控，而不是在服务器日志开始中断时查看它。未来的发展将使 etcd 日志尽可能少，并使 etcd 更容易通过指标和警报进行监控。

  - `etcd --logger=capnslog --log-outputs=default` 是默认设置，与之前的 etcd 服务器日志格式相同。

  - ```
    etcd --logger=zap --log-outputs=default
    ```

    时不支持

    ```
    etcd --logger=zap
    ```

    。

    - 使用`etcd --logger=zap --log-outputs=stderr`来代替。
    - 或者，用于`etcd --logger=zap --log-outputs=systemd/journal`将日志发送到本地 systemd 日志。
    - 以前，如果 etcd 父进程 ID (PPID) 为 1（例如使用 systemd 运行），`etcd --logger=capnslog --log-outputs=default`则将服务器日志重定向到本地 systemd 日志。如果写入 journald 失败，它会`os.Stderr`作为后备写入。
    - 但是，即使使用 PPID 1，它也可能无法拨打 systemd 日志（例如，使用 Docker 容器运行嵌入式 etcd）。然后，[每个日志写入都会失败](https://github.com/etcd-io/etcd/pull/9729)并回退到`os.Stderr`，这是低效的。
    - 为避免此问题，必须手动配置 systemd 日志记录。

  - `etcd --logger=zap --log-outputs=stderr`将以[JSON 编码格式](https://godoc.org/go.uber.org/zap#NewProductionEncoderConfig)记录服务器操作并将日志写入`os.Stderr`. 使用它来覆盖日志日志重定向。

  - `etcd --logger=zap --log-outputs=stdout`将以[JSON 编码格式](https://godoc.org/go.uber.org/zap#NewProductionEncoderConfig)记录服务器操作并将日志写入`os.Stdout`使用此覆盖日志日志重定向。

  - `etcd --logger=zap --log-outputs=a.log`将以[JSON 编码格式](https://godoc.org/go.uber.org/zap#NewProductionEncoderConfig)记录服务器操作并将日志写入指定文件`a.log`。

  - `etcd --logger=zap --log-outputs=a.log,b.log,c.log,stdout` [将服务器日志写入多个文件`a.log`，`b.log`并`c.log`同时](https://github.com/etcd-io/etcd/pull/9579)`os.Stderr`以[JSON 编码格式](https://godoc.org/go.uber.org/zap#NewProductionEncoderConfig)输出到。

  - `etcd --logger=zap --log-outputs=/dev/null` 将丢弃所有服务器日志。

- 添加

  `etcd --log-level`

  标志以支持日志级别。

  - v3.5 将弃用`etcd --debug`flag 以支持`etcd --log-level=debug`.

- 添加[`etcd --backend-batch-limit`](https://github.com/etcd-io/etcd/pull/10283)标志。

- 添加[`etcd --backend-batch-interval`](https://github.com/etcd-io/etcd/pull/10283)标志。

- 修复

  `mvcc`“未同步”的观察者恢复操作

  。

  - “未同步”观察者是需要与已发生的事件同步的观察者。
  - 也就是说，“未同步”的观察者是旧版本请求的慢观察者。
  - “未同步”观察者还原操作未正确填充其底层观察者组。
  - 这可能会导致[“未同步”观察者丢失事件](https://github.com/etcd-io/etcd/issues/9086)。
  - 一个节点在未来的修订版中被一个观察者分割，并在分区被删除后落后于接收领导者快照。应用此快照时，etcd 监视存储将当前同步的观察者移动到未同步状态，因为同步观察者可能在网络分区期间变得陈旧。并重置同步的观察者组以重新启动观察者例程。以前，从同步观察者组移动到未同步时存在一个错误，因此当观察者被请求到网络分区节点时，客户端会错过事件。

- 修复

  `mvcc`因恢复操作而导致的服务器恐慌

  。

  - 让我们假设一个观察者被请求了一个未来的版本 X 并被发送到节点 A，节点 A 之后成为网络分区。同时，集群取得进展。然后当分区被移除时，leader 会向节点 A 发送一个快照。之前如果快照的最新修订版仍然低于监视修订版 X， **则**在快照恢复操作期间**etcd 服务器会发生恐慌**。
  - 现在，此服务器端恐慌已得到修复。

- 修复

  无效的 Election Proclaim/Resign HTTP(S) 请求上的服务器恐慌

  。

  - 以前，对 Election API 的格式错误的 HTTP 请求可能会在 etcd 服务器中引发恐慌。
  - 例如`curl -L http://localhost:2379/v3/election/proclaim -X POST -d '{"value":""}'`，`curl -L http://localhost:2379/v3/election/resign -X POST -d '{"value":""}'`。

- 修复

  基于修订的压缩保留解析

  。

  - 以前，`etcd --auto-compaction-mode revision --auto-compaction-retention 1`被[翻译为修订保留 3600000000000](https://github.com/etcd-io/etcd/issues/9337)。
  - 现在，`etcd --auto-compaction-mode revision --auto-compaction-retention 1`被正确解析为修订保留 1。

- 防止

  . 的大`TTL`值溢出`Lease` `Grant`

  。

  - `TTL``Grant`请求的参数是秒单位。
  - `TTL`价值太大的租约会以`math.MaxInt64` [意想不到的方式到期](https://github.com/etcd-io/etcd/issues/9374)。
  - `rpctypes.ErrLeaseTTLTooLarge`当请求`TTL`大于*9,000,000,000 秒*（大于 285 年）时，服务器现在返回给客户端。
  - 同样，etcd`Lease`用于短周期的保活或会话，范围为秒或分钟。不是几个小时或几天！

- 修复

  过期租约撤销

  。

  - 修复[“绑定租约到期时不删除密钥”的问题](https://github.com/etcd-io/etcd/issues/10686)。

- 启动[`raft.Config.CheckQuorum`时`ForceNewCluster`](https://github.com/etcd-io/etcd/pull/9347)启用 etcd 服务器。

- 允许[目录中的](https://github.com/etcd-io/etcd/pull/9743)

  非 WAL 文件`etcd --wal-dir`

  。

  - 以前，[`lost+found`](https://github.com/etcd-io/etcd/issues/7287)WAL 目录中的现有文件会阻止 etcd 服务器启动。
  - 现在，仅包含`lost+found`或不包含后缀的文件的WAL 目录`.wal`被认为是未初始化的。

- 修复[`ETCD_CONFIG_FILE`.env 变量解析`etcd`](https://github.com/etcd-io/etcd/pull/10762)。

- 修复[传输暂停/恢复中的](https://github.com/etcd-io/etcd/pull/10826)[竞争条件`rafthttp`](https://github.com/etcd-io/etcd/pull/10826)。

- 修复

  服务器因创建空角色而崩溃

  。

  - 以前，创建一个空名称的角色会导致 etcd 服务器崩溃，错误代码为`Unavailable`。
  - 现在，不允许使用错误代码创建具有空名称的角色`InvalidArgument`。

### 火

- 添加`isLearner`字段`etcdserverpb.Member`，`etcdserverpb.MemberAddRequest`并`etcdserverpb.StatusResponse`作为[raft learner 实现的](https://github.com/etcd-io/etcd/pull/10725)一部分。

- 将`MemberPromote`rpc添加到`etcdserverpb.Cluster`接口和相应的`MemberPromoteRequest`和`MemberPromoteResponse`作为[raft 学习器实现的](https://github.com/etcd-io/etcd/pull/10725)一部分。

- [`snapshot`](https://github.com/etcd-io/etcd/pull/9118)为快照恢复/保存操作添加包（[`godoc.org/github.com/etcd/clientv3/snapshot`](https://godoc.org/github.com/coreos/etcd/clientv3/snapshot)更多信息请参见）。

- 添加

  `watch_id`字段以`etcdserverpb.WatchCreateRequest`

  允许用户提供的手表 ID 到

  ```
  mvcc
  ```

  。

  - 对应`watch_id`通过 返回`etcdserverpb.WatchResponse`，如果有的话。

- 当[事件](https://github.com/etcd-io/etcd/issues/9294)的总大小超过标志值加上 gRPC 开销 512 字节时，添加

  `fragment`字段以`etcdserverpb.WatchCreateRequest`

  请求 etcd 服务器

  拆分监视事件

  

  ```
  etcd --max-request-bytes
  ```

  。

  - 默认的服务器端请求字节限制`embed.DefaultMaxRequestBytes`是 1.5 MiB 加上 gRPC 开销 512 字节。
  - 如果观察响应事件超过此服务器端请求限制并且使用`fragment`field创建观察请求`true`，则服务器会将观察事件拆分为一组块，每个块都是低于服务器端请求限制的观察事件的子集。
  - 当客户端带宽有限时很有用。
  - 例如，观察响应包含 10 个事件，其中每个事件为 1 MiB。服务器`etcd --max-request-bytes`标志值为 1 MiB。然后，服务器将向客户端发送 10 个单独的碎片事件。
  - 例如，watch response 包含 5 个事件，其中每个事件为 2 MiB。并且服务器`etcd --max-request-bytes`标志值是 1 MiB 并且`clientv3.Config.MaxCallRecvMsgSize`是 1 MiB。然后，服务器将尝试向客户端发送 5 个单独的碎片事件，客户端将出现`"code = ResourceExhausted desc = grpc: received message larger than max (...)"`.
  - 客户端必须实现碎片化的观察事件合并（`clientv3`在 etcd v3.4 中这样做）。

- 为当前 Raft 应用索引添加[`raftAppliedIndex`字段`etcdserverpb.StatusResponse`](https://github.com/etcd-io/etcd/pull/9176)。

- 为服务器端错误添加

  `errors`字段`etcdserverpb.StatusResponse`

  。

  - 例如 `"etcdserver: no leader", "NOSPACE", "CORRUPT"`

- 压缩后为实际数据库大小添加[`dbSizeInUse`字段`etcdserverpb.StatusResponse`](https://github.com/etcd-io/etcd/pull/9256)。

- 添加

  `WatchRequest.WatchProgressRequest`

  .

  - 手动触发向所有关联的观看流发送广播观看进度事件（带有最新标头的空观看响应）。
  - 可以将其视为`WithProgressNotify`可以手动触发。

注意：**v3.5 将弃用`etcd --log-package-levels`标志`capnslog`**；`etcd --logger=zap --log-outputs=stderr`将默认。**v3.5 将弃用`[CLIENT-URL]/config/local/log`端点。**

### 包裹 `embed`

- 添加

  `embed.Config.CipherSuites`

  以指定客户端/服务器和对等方之间的 TLS 握手支持的密码套件列表。

  - 如果为空，Go 会自动填充列表。
  - 双方`embed.Config.ClientTLSInfo.CipherSuites`并`embed.Config.CipherSuites`不能在同一时间非空。
  - 如果不为空，请指定`embed.Config.ClientTLSInfo.CipherSuites`或`embed.Config.CipherSuites`。

- 添加

  `embed.Config.InitialElectionTickAdvance`

  以启用/禁用初始选举勾选快进。

  - `embed.NewConfig()`默认情况下会`*embed.Config`以`InitialElectionTickAdvance`true返回。

- 定义[`embed.CompactorModePeriodic`](https://godoc.org/github.com/etcd-io/etcd/embed#pkg-variables)为`compactor.ModePeriodic`。

- 定义[`embed.CompactorModeRevision`](https://godoc.org/github.com/etcd-io/etcd/embed#pkg-variables)为`compactor.ModeRevision`。

- 更改[`embed.Config.CorsInfo`在`*cors.CORSInfo`类型`embed.Config.CORS`的`map[string\]struct{}`类型](https://github.com/etcd-io/etcd/pull/9490)。

- 删除

  `embed.Config.SetupLogging`

  。

  - 现在记录器是根据[`embed.Config.Logger`, `embed.Config.LogOutputs`,`embed.Config.Debug`字段](https://github.com/etcd-io/etcd/pull/9572)自动设置的。

- 添加[`embed.Config.Logger`](https://github.com/etcd-io/etcd/pull/9518)以支持服务器端的[结构化记录器`zap`](https://github.com/uber-go/zap)。

- 添加[`embed.Config.LogLevel`](https://github.com/etcd-io/etcd/pull/10947).

- 将`embed.Config.SnapCount`字段重命名为[`embed.Config.SnapshotCount`](https://github.com/etcd-io/etcd/pull/9745)，以与标志名称一致`etcd --snapshot-count`。

- 重命名[**`embed.Config.LogOutput`**为**`embed.Config.LogOutputs`**](https://github.com/etcd-io/etcd/pull/9624)以支持多个日志输出。

- 变化[**`embed.Config.LogOutputs`**从类型`string`到`[\]string`](https://github.com/etcd-io/etcd/pull/9579)支持多种日志输出。

- 添加[`embed.Config.BackendBatchLimit`](https://github.com/etcd-io/etcd/pull/10283)字段。

- 添加[`embed.Config.BackendBatchInterval`](https://github.com/etcd-io/etcd/pull/10283)字段。

- 设为[`embed.DefaultEnableV2` `false`默认](https://github.com/etcd-io/etcd/pull/10935)。

### 包裹 `pkg/adt`

- 

  `pkg/adt.IntervalTree`从`struct``interface`

  更改[为](https://github.com/etcd-io/etcd/pull/10959)。

  - 请参阅[`pkg/adt`自述文件](https://github.com/etcd-io/etcd/tree/main/pkg/adt)和[`pkg/adt`godoc](https://godoc.org/go.etcd.io/etcd/pkg/adt)。

- 提高

  `pkg/adt.IntervalTree`测试覆盖率

  。

  - 请参阅[`pkg/adt`自述文件](https://github.com/etcd-io/etcd/tree/main/pkg/adt)和[`pkg/adt`godoc](https://godoc.org/go.etcd.io/etcd/pkg/adt)。

- 修复

  红黑树以保持 black-height 属性

  。

  - 以前，删除操作违反了[black-height 属性](https://github.com/etcd-io/etcd/issues/10965)。

### 包裹 `integration`

- 添加

  `CLUSTER_DEBUG`以启用测试集群日志记录

  。

  - `capnslog`在集成测试中已弃用。

### 客户端 v3

- 添加[`MemberAddAsLearner`](https://github.com/etcd-io/etcd/pull/10725)到`Clientv3.Cluster`界面。该 API 用于向 etcd 集群添加学习者成员。

- 添加[`MemberPromote`](https://github.com/etcd-io/etcd/pull/10727)到`Clientv3.Cluster`界面。该 API 用于在 etcd 集群中提升学习者成员。

- 客户端可以

  `rpctypes.ErrLeaderChanged`

  从服务器接收。

  - 现在，当领导层发生变化时，带有读取索引的线性化请求会快速失败，而不是等到上下文超时。

- 添加

  `WithFragment` `OpOption`

  以在

  事件

  总大小超过

  ```
  etcd --max-request-bytes
  ```

  标志值加上 gRPC 开销 512 字节时支持[观察事件碎片](https://github.com/etcd-io/etcd/issues/9294)。

  - 默认情况下禁用手表碎片。
  - 默认的服务器端请求字节限制`embed.DefaultMaxRequestBytes`是 1.5 MiB 加上 gRPC 开销 512 字节。
  - 如果观察响应事件超过此服务器端请求限制并且使用`fragment`field创建观察请求`true`，则服务器会将观察事件拆分为一组块，每个块都是低于服务器端请求限制的观察事件的子集。
  - 当客户端带宽有限时很有用。
  - 例如，观察响应包含 10 个事件，其中每个事件为 1 MiB。服务器`etcd --max-request-bytes`标志值为 1 MiB。然后，服务器将向客户端发送 10 个单独的碎片事件。
  - 例如，watch response 包含 5 个事件，其中每个事件为 2 MiB。并且服务器`etcd --max-request-bytes`标志值是 1 MiB 并且`clientv3.Config.MaxCallRecvMsgSize`是 1 MiB。然后，服务器将尝试向客户端发送 5 个单独的碎片事件，客户端将出现`"code = ResourceExhausted desc = grpc: received message larger than max (...)"`.

- 添加

  `Watcher.RequestProgress`方法

  。

  - 手动触发向所有关联的观看流发送广播观看进度事件（带有最新标头的空观看响应）。
  - 可以将其视为`WithProgressNotify`可以手动触发。

- 修复

  响应队列已满时的租约保活间隔更新

  。

  - 如果`<-chan *clientv3LeaseKeepAliveResponse`从`clientv3.Lease.KeepAlive`从未消耗或信道是满的，客户端被[发送保持活动请求每500ms](https://github.com/etcd-io/etcd/issues/9911)代替每一个“TTL / 3”的持续时间预期速率的。

- 更改[快照文件权限](https://github.com/etcd-io/etcd/pull/9977)：在 Linux 上，快照文件从所有人可读（模式 0644）更改为仅用户可读（模式 0600）。

- 客户端可以选择使用

  `PermitWithoutStream`

  .

  - 通过设置`PermitWithoutStream`为 true，客户端可以在没有任何活动流 (RPC) 的情况下向服务器发送 keepalive ping。换句话说，它允许使用一元或简单的 RPC 调用发送 keepalive ping。
  - `PermitWithoutStream` 默认设置为 false。

- [如果](https://github.com/etcd-io/etcd/pull/10153)在`clientv3/concurrency`包中[取消](https://github.com/etcd-io/etcd/pull/10153)，[则](https://github.com/etcd-io/etcd/pull/10153)修复[释放锁定键的](https://github.com/etcd-io/etcd/pull/10153)逻辑。

- 修复[`(*Client).Endpoints()`方法竞争条件](https://github.com/etcd-io/etcd/pull/10595)。

- 已弃用

  `grpc.ErrClientConnClosing`

  。

  - `clientv3`而`proxy/grpcproxy`现在不返回`grpc.ErrClientConnClosing`。
  - `grpc.ErrClientConnClosing`已[在 gRPC >= 1.10 中弃用](https://github.com/grpc/grpc-go/pull/1854)。
  - 使用`clientv3.IsConnCanceled(error)`或`google.golang.org/grpc/status.FromError(error)`代替。

### etcdctl v3

- 设为

  `ETCDCTL_API=3 etcdctl`默认

  。

  - 现在，`etcdctl set foo bar`必须是`ETCDCTL_API=2 etcdctl set foo bar`。
  - 现在，`ETCDCTL_API=3 etcdctl put foo bar`可能只是`etcdctl put foo bar`.

- 添加[`etcdctl member add --learner`和`etcdctl member promote`](https://github.com/etcd-io/etcd/pull/10725)在 etcd 集群中添加和提升 raft learner 成员。

- 添加

  `etcdctl --password`

  标志。

  - 支持[`:`用户名中的字符](https://github.com/etcd-io/etcd/issues/9691)。
  - 例如 `etcdctl --user user --password password get foo`

- 添加[`etcdctl user add --new-user-password`](https://github.com/etcd-io/etcd/pull/9730)标志。

- 添加[`etcdctl check datascale`](https://github.com/etcd-io/etcd/pull/9185)命令。

- 添加[`etcdctl check datascale --auto-compact, --auto-defrag`](https://github.com/etcd-io/etcd/pull/9351)标志。

- 添加[`etcdctl check perf --auto-compact, --auto-defrag`](https://github.com/etcd-io/etcd/pull/9330)标志。

- 添加[`etcdctl defrag --cluster`](https://github.com/etcd-io/etcd/pull/9390)标志。

- 将[“筏应用索引”字段`endpoint status`](https://github.com/etcd-io/etcd/pull/9176)添加[到](https://github.com/etcd-io/etcd/pull/9176).

- 将[“错误”字段`endpoint status`](https://github.com/etcd-io/etcd/pull/9206)添加[到](https://github.com/etcd-io/etcd/pull/9206).

- 添加

  `etcdctl endpoint health --write-out`支持

  。

  - 以前，[`etcdctl endpoint health --write-out json`没有工作](https://github.com/etcd-io/etcd/issues/9532)。

- 添加[缺少的换行符`etcdctl endpoint health`](https://github.com/etcd-io/etcd/pull/10793)。

- 修复

  `etcdctl watch [key] [range_end] -- [exec-command…]`

  解析。

  - 之前， `ETCDCTL_API=3 etcdctl watch foo -- echo watch event received`惊慌失措。

- 修复[`etcdctl move-leader`启用 TLS 的端点的命令](https://github.com/etcd-io/etcd/pull/9807)。

- 将

  `progress`命令`etcdctl watch --interactive`

  添加[到](https://github.com/etcd-io/etcd/pull/9869).

  - 手动触发向所有关联的观看流发送广播观看进度事件（带有最新标头的空观看响应）。
  - 可以将其视为`WithProgressNotify`可以手动触发。

- 将

  超时

  添加到

  ```
  etcdctl snapshot save
  ```

  .

  - 用户可以`etcdctl snapshot save`使用 flag指定命令的超时时间`--command-timeout`。
  - 修复 etcdctl 以[在使用发现时从 DNS SRV 记录中](https://github.com/etcd-io/etcd/pull/10443)去除[不安全的端点](https://github.com/etcd-io/etcd/pull/10443)

### gRPC 代理

- 修复

  因恢复操作而导致的 etcd 服务器恐慌

  。

  - 让我们假设一个观察者被请求了一个未来的版本 X 并被发送到节点 A，节点 A 之后成为网络分区。同时，集群取得进展。然后当分区被移除时，leader 会向节点 A 发送一个快照。之前如果快照的最新修订版仍然低于监视修订版 X， **则**在快照恢复操作期间**etcd 服务器会发生恐慌**。
  - 特别是，gRPC 代理受到了影响，因为它通过密钥`"proxy-namespace__lostleader"`和监视修订检测到领导者丢失`"int64(math.MaxInt64 - 2)"`。
  - 现在，此服务器端恐慌已得到修复。

- 修复[缓存层内存泄漏](https://github.com/etcd-io/etcd/pull/10327)。

- 更改

  gRPC 代理以公开 etcd 服务器端点 /metrics

  。

  - 通过代理公开的指标不是 etcd 服务器成员，而是代理本身。

### gRPC 网关

- 将

  gRPC 网关

  端点替换

  ```
  /v3beta
  ```

  为

  `/v3`

  .

  - 已弃用[`/v3alpha`](https://github.com/etcd-io/etcd/pull/9298)。
  - [`/v3beta`](https://github.com/etcd-io/etcd/issues/9189)在 v3.5 中弃用。
  - 在 v3.4 中，`curl -L http://localhost:2379/v3beta/kv/put -X POST -d '{"key": "Zm9v", "value": "YmFy"}'`仍然可以作为 的后备`curl -L http://localhost:2379/v3/kv/put -X POST -d '{"key": "Zm9v", "value": "YmFy"}'`，但`curl -L http://localhost:2379/v3beta/kv/put -X POST -d '{"key": "Zm9v", "value": "YmFy"}'`在 v3.5 中不起作用。使用`curl -L http://localhost:2379/v3/kv/put -X POST -d '{"key": "Zm9v", "value": "YmFy"}'`来代替。

- 添加 API 端点

  `/{v3beta,v3}/lease/leases, /{v3beta,v3}/lease/revoke, /{v3beta,v3}/lease/timetolive`

  。

  - [`/{v3beta,v3}/kv/lease/leases, /{v3beta,v3}/kv/lease/revoke, /{v3beta,v3}/kv/lease/timetolive`](https://github.com/etcd-io/etcd/issues/9430)在 v3.5 中弃用。

- 支持[`etcd --cors`](https://github.com/etcd-io/etcd/pull/9490)v3 HTTP 请求（gRPC 网关）。

### 包裹 `raft`

- 修复[PreVote 迁移过程中的死锁](https://github.com/etcd-io/etcd/pull/8525)。

- 添加

  `raft.ErrProposalDropped`

  .

  - 如果提案被忽略，现在[`(r *raft) Step`返回`raft.ErrProposalDropped`](https://github.com/etcd-io/etcd/pull/9137)。
  - 例如，一个节点从集群中移除，或者[`raftpb.MsgProp`在正在进行领导转移时到达当前领导](https://github.com/etcd-io/etcd/issues/8975)。

- 改进

  Raft`becomeLeader`并`stepLeader`

  跟踪最新

  ```
  pb.EntryConfChange
  ```

  索引。

  - 之前记录`pendingConf`布尔字段扫描整个日志尾部，可以延迟心跳发送。

- 修复 上[丢失的学习器节点`(n *node) ApplyConfChange`](https://github.com/etcd-io/etcd/pull/9116)。

- 添加

  `raft.Config.MaxUncommittedEntriesSize`

  以限制未提交条目的总大小（以字节为单位）。

  - 一旦超过，筏返回`raft.ErrProposalDropped`错误。
  - 防止[无限制的 Raft 日志增长](https://github.com/cockroachdb/cockroach/issues/27772)。
  - [PR#10167 中](https://github.com/etcd-io/etcd/pull/10167)存在一个错误，但已通过[PR#10199](https://github.com/etcd-io/etcd/pull/10199)修复。

- 

  `raft.Ready.CommittedEntries`使用`raft.Config.MaxSizePerMsg`

  添加[分页](https://github.com/etcd-io/etcd/pull/9982)。

  - 如果 raft 日志变得非常大并且一次提交，这可以防止内存不足错误。
  - 修复[CommittedEntries 分页中的正确性错误](https://github.com/etcd-io/etcd/pull/10063)。

- 优化

  消息发送流量控制

  。

  - 如果在更新流控制信息后有更多非空条目要发送，领导者现在会发送更多附加条目。
  - 现在，Raft 允许多个 in-flight 附加消息。

- 

  将切片装箱时`maybeCommit`

  优化[内存分配](https://github.com/etcd-io/etcd/pull/10679)。

  - 通过装箱一个堆分配的切片头而不是堆栈上的切片头，我们可以在通过 sort.Interface 接口时避免分配。

- 避免[在 Raft entry`String`方法中分配内存](https://github.com/etcd-io/etcd/pull/10680)。

- [合并稳定和不稳定的日志时](https://github.com/etcd-io/etcd/pull/10684)避免[多次内存分配](https://github.com/etcd-io/etcd/pull/10684)。

- 将

  进度跟踪

  提取[到自己的组件中](https://github.com/etcd-io/etcd/pull/10683)。

  - 添加[包`raft/tracker`](https://github.com/etcd-io/etcd/pull/10807)。
  - 优化[的字符串表示`Progress`](https://github.com/etcd-io/etcd/pull/10882)。

- 使[和](https://github.com/etcd-io/etcd/pull/10803)[之间的关系显式`node``RawNode`](https://github.com/etcd-io/etcd/pull/10803)。

- 防止[学习者成为领导者](https://github.com/etcd-io/etcd/pull/10822)。

- 添加

  包`raft/quorum`来推理提交的索引以及多数和联合法定人数的投票结果

  。

  - 将[Voters 和 Learner`raft/tracker.Config`](https://github.com/etcd-io/etcd/pull/10865)捆绑[到](https://github.com/etcd-io/etcd/pull/10865)[struct 中](https://github.com/etcd-io/etcd/pull/10865)。

- 使用[成员集进行进度跟踪](https://github.com/etcd-io/etcd/pull/10779)。

- 实施[联合法定人数计算](https://github.com/etcd-io/etcd/pull/10779)。

- 重构[`raft/node.go`以集中配置更改应用程序](https://github.com/etcd-io/etcd/pull/10865)。

- 允许[选民通过快照成为学习者](https://github.com/etcd-io/etcd/pull/10864)。

- 添加[包`raft/confchange`内部支持联合共识](https://github.com/etcd-io/etcd/pull/10779)。

- 使用[`RawNode`节点的事件循环](https://github.com/etcd-io/etcd/pull/10892)。

- 添加[`RawNode.Bootstrap`方法](https://github.com/etcd-io/etcd/pull/10892)。

- 添加

  `raftpb.ConfChangeV2`以使用联合法定人数

  。

  - `raftpb.ConfChange`继续像今天一样工作：它允许执行单个配置更改。一个`pb.ConfChange`提议被添加到 Raft 日志中，因此在就绪处理期间也被应用程序观察到，并反馈给 ApplyConfChange。
  - `raftpb.ConfChangeV2` 允许联合配置更改，但在可能的情况下将继续在“一个阶段”（即不进入联合配置）中执行配置更改。
  - `raftpb.ConfChangeV2`消息启动配置更改。他们支持简单的“一次一个”成员变更协议和允许成员任意变更的完整联合共识。

- 更改[`raftpb.ConfState.Nodes`为`raftpb.ConfState.Voters`](https://github.com/etcd-io/etcd/pull/10914)。

- 允许

  学习者投票，但学习者仍然不计入法定人数

  。

  - 在学习者已被提升（即现在是选民）但尚未了解这一点的情况下是必要的。

- 修复[恢复联合共识](https://github.com/etcd-io/etcd/pull/11003)。

- 参观[`Progress`秩序稳定](https://github.com/etcd-io/etcd/pull/11004)。

- 主动

  探查新增关注者

  。

  - 一般的期望`tracker.Progress.Next == c.LastIndex`是跟随者根本没有日志（因此可能需要快照），尽管应用程序可能在添加副本之前应用了带外快照（因此使第一个索引成为更好的选择）。
  - 以前，当领导者应用添加选民的新配置时，它不会立即调查这些选民，从而延迟他们被追上的时间。

### 包裹 `wal`

- 添加[`Verify`功能以对 WAL 内容执行损坏检查](https://github.com/etcd-io/etcd/pull/10603)。
- 修复[`wal`创建失败时的目录清理](https://github.com/etcd-io/etcd/pull/10689)。

### 工装

- 添加[`etcd-dump-logs --entry-type`](https://github.com/etcd-io/etcd/pull/9628)标志以支持按条目类型进行 WAL 日志过滤。

- 添加[`etcd-dump-logs --stream-decoder`](https://github.com/etcd-io/etcd/pull/9790)标志以支持自定义解码器。

- 添加

  `SHA256SUMS`

  文件以释放资产。

  - etcd 维护者是一个分布式团队，此更改允许在不需要签名密钥的情况下削减发布和提供验证。

### 去

- 需要[*Go 1.12+*](https://github.com/etcd-io/etcd/pull/10045)。
- 使用[*Go 1.12.9*](https://golang.org/doc/devel/release.html#go1.12)编译，包括[*Go 1.12.8*](https://groups.google.com/d/msg/golang-announce/65QixT3tcmg/DrFiG6vvCwAJ)安全修复。

### 文件

- [将 etcd 映像从 Alpine 重新设置为 Debian，](https://github.com/etcd-io/etcd/pull/10805)以提高 etcd 版本的安全性和维护工作。