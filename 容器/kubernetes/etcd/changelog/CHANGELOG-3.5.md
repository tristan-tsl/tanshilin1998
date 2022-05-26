以前的更改日志可以在[CHANGELOG-3.4](https://github.com/etcd-io/etcd/blob/main/CHANGELOG-3.4.md)找到。

在**生产**中运行的最低推荐 etcd 版本是 3.2.28+、3.3.18+、3.4.2+ 和 3.5.1+。

------

## [v3.5.2](https://github.com/etcd-io/etcd/releases/tag/v3.5.2)（全部）

有关任何重大更改，请参阅[代码更改](https://github.com/etcd-io/etcd/compare/v3.5.1...v3.5.2)和[v3.5 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_5/)。

### etcd服务器

- 修复[排除由多个对等点激活的相同警报类型](https://github.com/etcd-io/etcd/pull/13476)。
- 添加[`etcd --experimental-enable-lease-checkpoint-persist`](https://github.com/etcd-io/etcd/pull/13508)标志以启用检查点持久化。
- 修复[租约检查点不会阻止在领导者更改时重置 ttl](https://github.com/etcd-io/etcd/pull/13508)，需要启用检查点持久化。

------

## [v3.5.1](https://github.com/etcd-io/etcd/releases/tag/v3.5.1) (2021-10-15)

有关任何重大更改，请参阅[代码更改](https://github.com/etcd-io/etcd/compare/v3.5.0...v3.5.1)和[v3.5 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_5/)。

### etcd服务器

- 修复[无法在配置文件中指定自签名证书有效性参数](https://github.com/etcd-io/etcd/pull/13237)。
- 修复[确保存储在 v2store 和后端中的集群成员同步](https://github.com/etcd-io/etcd/pull/13348)

### etcd客户端

- [修复 etcd 客户端发送无效的 :authority 标头](https://github.com/etcd-io/etcd/issues/13192)

### 包clientv3

- 端点现在自我识别`etcd-endpoints://{id}/{authority}`为基于第一个端点传递的权限，例如`etcd-endpoints://0xc0009d8540/localhost:2079`

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

## v3.5.0 (2021-06)

有关任何重大更改，请参阅[代码更改](https://github.com/etcd-io/etcd/compare/v3.4.0...v3.5.0)和[v3.5 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_5/)。

- [v3.5.0](https://github.com/etcd-io/etcd/releases/tag/v3.5.0)（2021 待定），请参阅[代码更改](https://github.com/etcd-io/etcd/compare/v3.5.0-rc.1...v3.5.0)。
- [v3.5.0-rc.1](https://github.com/etcd-io/etcd/releases/tag/v3.5.0-rc.1) (2021-06-10)，见[代码变化](https://github.com/etcd-io/etcd/compare/v3.5.0-rc.0...v3.5.0-rc.1)。
- [v3.5.0-rc.0](https://github.com/etcd-io/etcd/releases/tag/v3.5.0-rc.0) (2021-06-04)，见[代码变化](https://github.com/etcd-io/etcd/compare/v3.5.0-beta.4...v3.5.0-rc.0)。
- [v3.5.0-beta.4](https://github.com/etcd-io/etcd/releases/tag/v3.5.0-beta.4) (2021-05-26)，见[代码变化](https://github.com/etcd-io/etcd/compare/v3.5.0-beta.3...v3.5.0-beta.4)。
- [v3.5.0-beta.3](https://github.com/etcd-io/etcd/releases/tag/v3.5.0-beta.3) (2021-05-18)，见[代码变化](https://github.com/etcd-io/etcd/compare/v3.5.0-beta.2...v3.5.0-beta.3)。
- [v3.5.0-](https://github.com/etcd-io/etcd/releases/tag/v3.5.0-beta.2) beta.2 (2021-05-18)，见[代码变化](https://github.com/etcd-io/etcd/compare/v3.5.0-beta.1...v3.5.0-beta.2)。
- [v3.5.0-beta.1](https://github.com/etcd-io/etcd/releases/tag/v3.5.0-beta.1) (2021-05-18)，见[代码变化](https://github.com/etcd-io/etcd/compare/v3.4.0...v3.5.0-beta.1)。

**同样，在从任何先前版本运行升级之前，请务必阅读下面的更改日志和[v3.5 升级指南](https://etcd.io/docs/latest/upgrades/upgrade_3_5/)。**

### 重大变化

- `go.etcd.io/etcd`Go 包已转移到`go.etcd.io/etcd/{api,pkg,raft,client,etcdctl,server,raft,tests}/v3`遵循[Go 模块](https://github.com/golang/go/wiki/Modules)约定

- `go.etcd.io/clientv3/snapshot`SnapshotManager 类已移至`go.etcd.io/clientv3/etcdctl`. `snapshot.Save`从远程服务器下载快照的方法保留在“go.etcd.io/clientv3/snapshot”中。

- `go.etcd.io/client' 包被迁移到了 'go.etcd.io/client/v2'。

- 更改了 clientv3 API 

  MemberList 的

  行为。

  - 以前，它直接与服务器的本地数据一起提供，这些数据可能是陈旧的。
  - 现在，它具有线性化保证。如果服务器与仲裁断开连接，`MemberList`调用将失败。

- gRPC 网关

  仅支持

  `/v3`

  端点。

  - 已弃用[`/v3beta`](https://github.com/etcd-io/etcd/pull/9298)。
  - `curl -L http://localhost:2379/v3beta/kv/put -X POST -d '{"key": "Zm9v", "value": "YmFy"}'`在 v3.5 中不起作用。使用`curl -L http://localhost:2379/v3/kv/put -X POST -d '{"key": "Zm9v", "value": "YmFy"}'`来代替。

- `etcd --experimental-enable-v2v3` 标志仍然是实验性的，将被弃用。

  - v2 存储模拟功能将在下一个版本中弃用。
  - etcd 3.5 是最后一个支持 V2 API 的版本。标志`--enable-v2`和`--experimental-enable-v2v3` [现在已弃用](https://github.com/etcd-io/etcd/pull/12940)，并将在 etcd v3.6 版本中删除。

- **`etcd --experimental-backend-bbolt-freelist-type`标志已被弃用。**使用**`etcd --backend-bbolt-freelist-type`**来代替。默认类型是 hashmap 并且它现在是稳定的。

- **`etcd --debug`标志已被弃用。**使用**`etcd --log-level=debug`**来代替。

- 删除[`embed.Config.Debug`](https://github.com/etcd-io/etcd/pull/10947)。

- **`etcd --log-output`标志已被弃用。**使用**`etcd --log-outputs`**来代替。

- **`etcd --logger=zap --log-outputs=stderr`** 现在是默认设置。

- **`etcd --logger=capnslog` 标志值已被弃用。**

- `etcd --logger=zap --log-outputs=default`不支持标志值。

  .

  - 使用`etcd --logger=zap --log-outputs=stderr`.
  - 或者，用于`etcd --logger=zap --log-outputs=systemd/journal`将日志发送到本地 systemd 日志。
  - 以前，如果 etcd 父进程 ID (PPID) 为 1（例如使用 systemd 运行），`etcd --logger=capnslog --log-outputs=default`则将服务器日志重定向到本地 systemd 日志。如果写入 journald 失败，它会`os.Stderr`作为后备写入。
  - 但是，即使使用 PPID 1，它也可能无法拨打 systemd 日志（例如，使用 Docker 容器运行嵌入式 etcd）。然后，[每个日志写入都会失败](https://github.com/etcd-io/etcd/pull/9729)并回退到`os.Stderr`，这是低效的。
  - 为避免此问题，必须手动配置 systemd 日志记录。

- **`etcd --log-outputs=stderr`** 现在是默认设置。

- **`etcd --log-package-levels`标志`capnslog`已被弃用。**现在，**`etcd --logger=zap --log-outputs=stderr`**是默认设置。

- `[CLIENT-URL]/config/local/log`端点已被弃用，`etcd --log-package-levels`标志也是如此。

  - `curl http://127.0.0.1:2379/config/local/log -XPUT -d '{"Level":"DEBUG"}'` 不会工作。
  - 请`etcd --logger=zap --log-outputs=stderr`改用。

- 已弃用的`etcd_debugging_mvcc_db_total_size_in_bytes`Prometheus 指标。使用`etcd_mvcc_db_total_size_in_bytes`来代替。

- 已弃用的`etcd_debugging_mvcc_put_total`Prometheus 指标。使用`etcd_mvcc_put_total`来代替。

- 已弃用的`etcd_debugging_mvcc_delete_total`Prometheus 指标。使用`etcd_mvcc_delete_total`来代替。

- 已弃用的`etcd_debugging_mvcc_txn_total`Prometheus 指标。使用`etcd_mvcc_txn_total`来代替。

- 已弃用的`etcd_debugging_mvcc_range_total`Prometheus 指标。使用`etcd_mvcc_range_total`来代替。

- 主分支`/version`输出`3.5.0-pre`，而不是`3.4.0+git`.

- 更改

  ```
  proxy
  ```

  包函数签名以

  支持结构化记录器

  。

  - 以前`NewClusterProxy(c *clientv3.Client, advaddr string, prefix string) (pb.ClusterServer, <-chan struct{})`，现在`NewClusterProxy(lg *zap.Logger, c *clientv3.Client, advaddr string, prefix string) (pb.ClusterServer, <-chan struct{})`。
  - 以前`Register(c *clientv3.Client, prefix string, addr string, ttl int)`，现在`Register(lg *zap.Logger, c *clientv3.Client, prefix string, addr string, ttl int) <-chan struct{}`。
  - 以前`NewHandler(t *http.Transport, urlsFunc GetProxyURLs, failureWait time.Duration, refreshInterval time.Duration) http.Handler`，现在`NewHandler(lg *zap.Logger, t *http.Transport, urlsFunc GetProxyURLs, failureWait time.Duration, refreshInterval time.Duration) http.Handler`。

- 更改了

  ```
  pkg/flags
  ```

  函数签名以

  支持结构化记录器

  。

  - 以前`SetFlagsFromEnv(prefix string, fs *flag.FlagSet) error`，现在`SetFlagsFromEnv(lg *zap.Logger, prefix string, fs *flag.FlagSet) error`。
  - 以前`SetPflagsFromEnv(prefix string, fs *pflag.FlagSet) error`，现在`SetPflagsFromEnv(lg *zap.Logger, prefix string, fs *pflag.FlagSet) error`。

- ClientV3 支持

  grpc 解析 API

  。

  - 可以使用[endpoints.Manager](https://github.com/etcd-io/etcd/blob/main/client/v3/naming/endpoints/endpoints.go)管理[端点](https://github.com/etcd-io/etcd/blob/main/client/v3/naming/endpoints/endpoints.go)
  - 以前支持的[GRPCResolver 已退役](https://github.com/etcd-io/etcd/pull/12675)。改用[解析器](https://github.com/etcd-io/etcd/blob/main/client/v3/naming/resolver/resolver.go)。

- [默认](https://github.com/etcd-io/etcd/pull/12770)开启[--pre-vote](https://github.com/etcd-io/etcd/pull/12770)。应防止个别成员扰乱 RAFT 领导者。

- [ETCD_CLIENT_DEBUG env](https://github.com/etcd-io/etcd/pull/12786)：现在支持日志级别（调试、信息、警告、错误、dpanic、恐慌、致命）。仅当设置时，覆盖应用程序范围的 grpc 日志记录设置。

- [Embed Etcd.Close()](https://github.com/etcd-io/etcd/pull/12828)需要调用一次并关闭 Etcd.Err() 流。

- [Embed Etcd 不再覆盖](https://github.com/etcd-io/etcd/pull/12861)默认的[global/grpc 记录器](https://github.com/etcd-io/etcd/pull/12861)。如果需要，请`embed.Config::SetupGlobalLoggers()`明确致电。

- [嵌入 Etcd 自定义记录器应使用更简单的 builder 进行配置`NewZapLoggerBuilder`](https://github.com/etcd-io/etcd/pull/12973)。

- `context cancelled`或 的客户端错误显示`context deadline exceeded`为`codes.Canceled`and `codes.DeadlineExceeded`，而不是`codes.Unknown`。

### 存储格式变化

- [WAL 日志的快照仍然存在 raftpb.ConfState](https://github.com/etcd-io/etcd/pull/12735)
- [后端](https://github.com/etcd-io/etcd/pull/12962)在`meta`存储桶`confState`键中[保留 raftpb.ConfState](https://github.com/etcd-io/etcd/pull/12962)。
- [后端](https://github.com/etcd-io/etcd/pull/)在`meta`存储桶中[保留应用的术语](https://github.com/etcd-io/etcd/pull/)。
- 后端保留`downgrade`在`cluster`存储桶中

### 安全

- 添加[`TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256`和`TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256`到`etcd --cipher-suites`](https://github.com/etcd-io/etcd/pull/11864)。
- 更改[了与 auth 相关的 WAL 条目的格式，以便不将密码保留为纯文本](https://github.com/etcd-io/etcd/pull/11943)。
- 添加第三方[安全审计报告](https://github.com/etcd-io/etcd/pull/12201)。
- 一个[日志警告](https://github.com/etcd-io/etcd/pull/12242)时ETCD使用具有比700在Linux和777在Windows权限不同任何现有的目录添加。
- 使用拆分证书时，为对等和客户端 tls 配置添加可选[`ClientCertFile`和`ClientKeyFile`](https://github.com/etcd-io/etcd/pull/12705)选项。

### 指标、监控

请参阅每个版本的所有指标[的指标列表](https://etcd.io/docs/latest/metrics/)。

请注意，任何`etcd_debugging_*`指标都是实验性的，可能会发生变化。

- 已弃用的`etcd_debugging_mvcc_db_total_size_in_bytes`Prometheus 指标。使用`etcd_mvcc_db_total_size_in_bytes`来代替。
- 已弃用的`etcd_debugging_mvcc_put_total`Prometheus 指标。使用`etcd_mvcc_put_total`来代替。
- 已弃用的`etcd_debugging_mvcc_delete_total`Prometheus 指标。使用`etcd_mvcc_delete_total`来代替。
- 已弃用的`etcd_debugging_mvcc_txn_total`Prometheus 指标。使用`etcd_mvcc_txn_total`来代替。
- 已弃用的`etcd_debugging_mvcc_range_total`Prometheus 指标。使用`etcd_mvcc_range_total`来代替。
- 添加[`etcd_debugging_mvcc_current_revision`](https://github.com/etcd-io/etcd/pull/11126)普罗米修斯指标。
- 添加[`etcd_debugging_mvcc_compact_revision`](https://github.com/etcd-io/etcd/pull/11126)普罗米修斯指标。
- 将[`etcd_cluster_version`](https://github.com/etcd-io/etcd/pull/11254)Prometheus 指标更改为仅包含主要和次要版本。
- 添加[`etcd_debugging_mvcc_total_put_size_in_bytes`](https://github.com/etcd-io/etcd/pull/11374)普罗米修斯指标。
- 添加[`etcd_server_client_requests_total`with`"type"`和`"client_api_version"`labels](https://github.com/etcd-io/etcd/pull/11687)。
- 添加[`etcd_wal_write_bytes_total`](https://github.com/etcd-io/etcd/pull/11738).
- 添加[`etcd_debugging_auth_revision`](https://github.com/etcd-io/etcd/commit/f14d2a087f7b0fd6f7980b95b5e0b945109c95f3).
- 添加[`os_fd_used`和`os_fd_limit`监视当前操作系统文件描述符](https://github.com/etcd-io/etcd/pull/12214)。
- 添加[`etcd_disk_defrag_inflight`](https://github.com/etcd-io/etcd/pull/13395).

### etcd服务器

- 添加[不要尝试向角色授予 nil 权限](https://github.com/etcd-io/etcd/pull/13086)。

- 添加[不激活警报 w/missing AlarmType](https://github.com/etcd-io/etcd/pull/13084)。

- 添加[`TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256`和`TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256`到`etcd --cipher-suites`](https://github.com/etcd-io/etcd/pull/11864)。

- [如果父目录不存在，则](https://github.com/etcd-io/etcd/pull/9626)自动[创建它](https://github.com/etcd-io/etcd/pull/9626)（修复[问题#9609](https://github.com/etcd-io/etcd/issues/9609)）。

- v4.0 将配置`etcd --enable-v2=true --enable-v2v3=/aaa`为启用由**v3 存储**支持的 v2 API 服务器。

- [ 

  ```
  etcd --backend-bbolt-freelist-type
  ```

  ] 标志现在稳定了。

  - `etcd --experimental-backend-bbolt-freelist-type` 已被弃用。

- 支持[降级API](https://github.com/etcd-io/etcd/pull/11715)。

- 弃用 v2 适用于集群版本。[使用 v3 请求设置集群版本并从 v3 后端恢复集群版本](https://github.com/etcd-io/etcd/pull/11427)。

- [使用 v2 api 更新集群版本，以支持升级过程中的混合版本集群](https://github.com/etcd-io/etcd/pull/12988)。

- [修复碎片整理中的损坏错误](https://github.com/etcd-io/etcd/pull/11613)。

- [在提升学习者时](https://github.com/etcd-io/etcd/pull/11640)修复[法定人数保护逻辑](https://github.com/etcd-io/etcd/pull/11640)。

- 当启用对等 mTLS 时，改进[对等损坏检查器](https://github.com/etcd-io/etcd/pull/11621)的工作。

- [`[CLIENT-PORT\]/health`在服务器端](https://github.com/etcd-io/etcd/pull/11704)登录[检查](https://github.com/etcd-io/etcd/pull/11704)。

- [在调试级别](https://github.com/etcd-io/etcd/pull/12677)记录[成功的 etcd 服务器端健康检查](https://github.com/etcd-io/etcd/pull/12677)。

- [当最新索引大于 1 百万时](https://github.com/etcd-io/etcd/pull/11734)提高[压缩性能](https://github.com/etcd-io/etcd/pull/11734)。

- [重构一致索引](https://github.com/etcd-io/etcd/pull/11699)。

- [当 etcdserver 应用命令失败时添加日志](https://github.com/etcd-io/etcd/pull/11670)。

- 提高[仅计数范围的性能](https://github.com/etcd-io/etcd/pull/11771)。

- 删除

  冗余存储还原操作以缩短启动时间

  。

  - 4000万关键测试数据，可将启动时间从5分钟缩短至2.5分钟。

- [修复 mvcc 中的死锁错误](https://github.com/etcd-io/etcd/pull/11817)。

- 修复

  WAL 和服务器快照之间的不一致

  。

  - 以前，如果服务器在持久化 raft 硬状态之后但在保存快照之前崩溃，则服务器恢复会失败。
  - 有关更多信息，请参阅https://github.com/etcd-io/etcd/issues/10219。
  - [在 WAL 验证方法中](https://github.com/etcd-io/etcd/pull/11924)添加[缺少的 CRC 校验和检查，否则会导致 panic](https://github.com/etcd-io/etcd/pull/11924)。
  - 请参阅https://github.com/etcd-io/etcd/issues/11918。

- 改进有关快照发送和接收的日志记录。

- [将 RangeOptions.limit argv 下推到索引树中以减少内存开销](https://github.com/etcd-io/etcd/pull/11990)。

- [为 /health response](https://github.com/etcd-io/etcd/pull/11983)添加[原因字段](https://github.com/etcd-io/etcd/pull/11983)。

- [有条件地从健康检查中](https://github.com/etcd-io/etcd/pull/12880)添加[排除警报](https://github.com/etcd-io/etcd/pull/12880)。

- 添加

  `etcd --unsafe-no-fsync`

  标志。

  - 设置该标志会禁用 fsync 的所有使用，这是不安全的并且会导致数据丢失。该标志使得运行 etcd 节点进行测试和开发成为可能，而不会在文件系统上放置大量负载。

- 添加[`etcd --auth-token-ttl`](https://github.com/etcd-io/etcd/pull/11980)标志以自定义`simpleTokenTTL`设置。

- 改进[`runtime.FDUsage`调用模式以减少 Memory Usage 和 CPU Usage 的对象 malloc](https://github.com/etcd-io/etcd/pull/11986)。

- 改进[mvcc.watchResponse 通道内存使用](https://github.com/etcd-io/etcd/pull/11987)。

- [在 UnaryInterceptor 中](https://github.com/etcd-io/etcd/pull/12086)记录[昂贵的请求信息](https://github.com/etcd-io/etcd/pull/12086)。

- [修复 etcdserverpb 中无效的 Go 类型](https://github.com/etcd-io/etcd/pull/12000)。

- [通过使用 v3 range request 及其相应的 timeout 改进健康检查](https://github.com/etcd-io/etcd/pull/12195)。

- 添加[`etcd --experimental-watch-progress-notify-interval`](https://github.com/etcd-io/etcd/pull/12216)标志以使监视进度通知间隔可配置。

- 修复

  慢写警告中的服务器恐慌

  。

  - 通过[PR#12238 修复](https://github.com/etcd-io/etcd/pull/12238)。

- 在具有学习节点的集群中启用 force-new-cluster 标志时[修复服务器恐慌](https://github.com/etcd-io/etcd/pull/12288)。

- 添加

  `etcd --self-signed-cert-validity`

  标志以支持设置证书过期时间。

  - 注意，当指定 auto-tls 或 peer-auto-tls 选项时，etcd 生成的证书默认有效期为 1 年。

- 添加[`etcd --experimental-warning-apply-duration`](https://github.com/etcd-io/etcd/pull/12448)允许应用持续时间阈值可配置的标志。

- 添加[`etcd --experimental-memory-mlock`](https://github.com/etcd-io/etcd/pull/TODO)防止 etcd 内存页面被换出的标志。

- 添加

  `etcd --socket-reuse-port`

  标志

  - 设置此标志启用`SO_REUSEPORT`允许重新绑定已在使用的端口。用户在使用此标志时应小心，以确保正确执行 flock。

- 添加

  `etcd --socket-reuse-address`

  标志

  - 设置此标志启用`SO_REUSEADDR`它允许绑定到`TIME_WAIT`状态中的地址，从而改善 etcd 重启时间。

- 通过[在没有 marshal 的情况下记录范围响应大小，](https://github.com/etcd-io/etcd/pull/12871)减少[大约 30% 的内存分配](https://github.com/etcd-io/etcd/pull/12871)。

- `ETCD_VERIFY="all"`环境触发对 etcd 数据目录文件[一致性](https://github.com/etcd-io/etcd/pull/12901)的[额外验证](https://github.com/etcd-io/etcd/pull/12901)。

- 添加[`etcd --enable-log-rotation`](https://github.com/etcd-io/etcd/pull/12774)布尔标志，如果为真，则启用日志轮换。

- 添加[`etcd --log-rotation-config-json`](https://github.com/etcd-io/etcd/pull/12774)允许传递 JSON 配置以配置文件输出目标的日志轮换的标志。

- 添加实验性分布式跟踪布尔标志[`--experimental-enable-distributed-tracing`](https://github.com/etcd-io/etcd/pull/12919)以启用跟踪。

- 添加[`etcd --experimental-distributed-tracing-address`](https://github.com/etcd-io/etcd/pull/12919)允许配置 OpenTelemetry 收集器地址的字符串标志。

- 添加[`etcd --experimental-distributed-tracing-service-name`](https://github.com/etcd-io/etcd/pull/12919)允许更改默认“etcd”服务名称的字符串标志。

- 添加[`etcd --experimental-distributed-tracing-instance-id`](https://github.com/etcd-io/etcd/pull/12919)配置实例 ID 的字符串标志，每个 etcd 实例必须是唯一的。

### 包裹 `runtime`

- [`runtime.FDUsage`通过删除不必要的排序进行](https://github.com/etcd-io/etcd/pull/12214)优化。

### 包裹 `embed`

- 删除

  `embed.Config.Debug`

  。

  - 使用`embed.Config.LogLevel`来代替。

- 添加[`embed.Config.ZapLoggerBuilder`](https://github.com/etcd-io/etcd/pull/11147)以允许创建自定义 zap 记录器。

- [用 etcd 服务器记录器对象](https://github.com/etcd-io/etcd/pull/12212)替换[global`*zap.Logger`](https://github.com/etcd-io/etcd/pull/12212)。

- [`embed.Config.EnableLogRotation`](https://github.com/etcd-io/etcd/pull/12774)如果为 true，则添加启用日志轮换。

- 添加[`embed.Config.LogRotationConfigJSON`](https://github.com/etcd-io/etcd/pull/12774)以允许通过 JSON 配置为文件输出目标配置日志轮换。

- 添加[`embed.Config.ExperimentalEnableDistributedTracing`](https://github.com/etcd-io/etcd/pull/12919)启用实验性分布式跟踪（如果为真）。

- 添加[`embed.Config.ExperimentalDistributedTracingAddress`](https://github.com/etcd-io/etcd/pull/12919)允许覆盖默认收集器地址。

- 添加[`embed.Config.ExperimentalDistributedTracingServiceName`](https://github.com/etcd-io/etcd/pull/12919)允许覆盖默认的“etcd”服务名称。

- 添加[`embed.Config.ExperimentalDistributedTracingServiceInstanceID`](https://github.com/etcd-io/etcd/pull/12919)允许配置实例 ID，每个 etcd 实例必须是唯一的。

### 包裹 `clientv3`

- 删除

  过多的监视取消日志记录消息

  。

  - 这个[州长/州长#93450](https://github.com/kubernetes/kubernetes/issues/93450)。

- 将[`TryLock`](https://github.com/etcd-io/etcd/pull/11104)方法添加到`clientv3/concurrency/Mutex`. 一种`Mutex`不等待获得互斥锁锁定的非阻塞方法，如果互斥锁被另一个会话锁定，则立即返回。

- 

  针对多个端点

  修复[客户端平衡器故障转移](https://github.com/etcd-io/etcd/pull/11184)。

  - 修复[`"kube-apiserver: failover on multi-member etcd cluster fails certificate check on DNS mismatch"`](https://github.com/kubernetes/kubernetes/issues/83028)。

- 修复

  客户端中的 IPv6 端点解析

  。

  - 修复[“1.16：当成员加入时，etcd 客户端没有正确解析 IPv6 地址”(kubernetes#83550)](https://github.com/kubernetes/kubernetes/issues/83550)。

- 修复[由 grpc 更改 balancer/resolver API 引起的错误](https://github.com/etcd-io/etcd/pull/11564)。此更改与 grpc >= [v1.26.0](https://github.com/grpc/grpc-go/releases/tag/v1.26.0)兼容，但与 < v1.26.0 版本不兼容。

- 撞到grpc v1.26.0后使用[ServerName作为权限](https://github.com/etcd-io/etcd/pull/11574)。删除[#11184 中的](https://github.com/etcd-io/etcd/pull/11184)解决方法。

- 修复

  `"hasleader"`元数据嵌入

  。

  - 以前，`clientv3.WithRequireLeader(ctx)`是覆盖现有的上下文键。

- 修复[由延迟取消引起的手表泄漏](https://github.com/etcd-io/etcd/pull/11850)。当客户端取消他们的监视时，取消请求现在将立即发送到服务器，而不是等待下一个监视事件。

- 确保[保存快照下载校验和以进行完整性检查](https://github.com/etcd-io/etcd/pull/11896)。

- 修复[手表重新连接后验证令牌无效的问题](https://github.com/etcd-io/etcd/pull/12264)。当 clientConn 准备好时自动获取 AuthToken。

- 改进[clientv3：在没有额外连接的情况下优雅地获取 AuthToken](https://github.com/etcd-io/etcd/pull/12165)。

- 更改了

  clientv3 拨号代码

  以使用 grpc 解析器 API 而不是自定义平衡器。

  - 端点现在自我识别为`etcd-endpoints://{id}/#initially={list of endpoints}`例如`etcd-endpoints://0xc0009d8540/#initially=[localhost:2079]`

- 确保[保存快照下载校验和以进行完整性检查](https://github.com/etcd-io/etcd/pull/11896)。

### 包裹 `lease`

- 修复

  跟随节点中的内存泄漏

  。

  - https://github.com/etcd-io/etcd/issues/11495
  - https://github.com/etcd-io/etcd/issues/11730

- 确保[在重新启动 etcd 后不会重复应用 grant/revoke](https://github.com/etcd-io/etcd/pull/11935)。

### 包裹 `wal`

- 添加[`etcd_wal_write_bytes_total`](https://github.com/etcd-io/etcd/pull/11738).
- 处理[超出范围的切片绑定`ReadAll`和进入限制`decodeRecord`](https://github.com/etcd-io/etcd/pull/11793)。

### etcdctl v3

- 修复`etcdctl member add`命令以防止潜在的超时。( [PR#11194](https://github.com/etcd-io/etcd/pull/11194)和[PR#11638](https://github.com/etcd-io/etcd/pull/11638) )
- 添加[`etcdctl watch --progress-notify`](https://github.com/etcd-io/etcd/pull/11462)标志。
- 添加[`etcdctl auth status`](https://github.com/etcd-io/etcd/pull/11536)命令以检查是否启用了身份验证
- [`etcdctl get --count-only`](https://github.com/etcd-io/etcd/pull/11743)为输出类型添加标志`fields`。
- 添加[`etcdctl member list -w=json --hex`](https://github.com/etcd-io/etcd/pull/11812)标志以十六进制格式 json 打印 memberListResponse。
- 更改[`etcdctl lock  exec-command`](https://github.com/etcd-io/etcd/pull/12829)为返回 exec 命令的退出代码。
- [新工具：`etcdutl`](https://github.com/etcd-io/etcd/pull/12971)合并了以下功能：`etcdctl snapshot status|restore`、`etcdctl backup`、`etcdctl defrag --data-dir ...`。
- [ETCDCTL_API=2`etcdctl migrate`](https://github.com/etcd-io/etcd/pull/12971)已[停用](https://github.com/etcd-io/etcd/pull/12971)。使用 etcd <=v3.4 恢复 v2 存储。

### gRPC 网关

- gRPC 网关

  仅支持

  `/v3`

  端点。

  - 已弃用[`/v3beta`](https://github.com/etcd-io/etcd/pull/9298)。
  - `curl -L http://localhost:2379/v3beta/kv/put -X POST -d '{"key": "Zm9v", "value": "YmFy"}'`在 v3.5 中确实有效。使用`curl -L http://localhost:2379/v3/kv/put -X POST -d '{"key": "Zm9v", "value": "YmFy"}'`来代替。

- [`enable-grpc-gateway`](https://github.com/etcd-io/etcd/pull/12297)使用配置文件时将标志设置为 true 以保持默认值与命令行配置相同。

### gRPC 代理

- 修复[`panic on error`](https://github.com/etcd-io/etcd/pull/11694)指标处理程序。
- 添加[gRPC keepalive 相关标志](https://github.com/etcd-io/etcd/pull/11711) `grpc-keepalive-min-time`,`grpc-keepalive-interval`和`grpc-keepalive-timeout`.
- [修复 grpc watch 代理在取消观察者失败时挂起](https://github.com/etcd-io/etcd/pull/12030)。
- [为 grpcproxy self](https://github.com/etcd-io/etcd/pull/12107)添加[指标处理程序](https://github.com/etcd-io/etcd/pull/12107)。
- [为 grpcproxy self](https://github.com/etcd-io/etcd/pull/12114)添加[健康处理程序](https://github.com/etcd-io/etcd/pull/12114)。

### 认证

- 修复[通过 GRPC 网关添加用户时的](https://github.com/etcd-io/etcd/pull/11418)[NoPassword](https://github.com/etcd-io/etcd/issues/11414)[检查](https://github.com/etcd-io/etcd/pull/11418)（[问题#11414](https://github.com/etcd-io/etcd/issues/11414)）
- 修复[一些与身份验证相关的消息记录在错误级别的错误](https://github.com/etcd-io/etcd/pull/11586)
- [通过保存一致的索引来修复数据损坏错误](https://github.com/etcd-io/etcd/pull/11652)。
- [提高 checkPassword 的性能](https://github.com/etcd-io/etcd/pull/11735)。
- [在 AuthStatus 中添加 authRevision 字段](https://github.com/etcd-io/etcd/pull/11659)。
- 修复[过期令牌不刷新的问题](https://github.com/etcd-io/etcd/pull/13308)。
- 

### 火

- 添加[`/v3/auth/status`](https://github.com/etcd-io/etcd/pull/11536)端点以检查是否启用了身份验证
- [将`Linearizable`字段添加到`etcdserverpb.MemberListRequest`](https://github.com/etcd-io/etcd/pull/11639).
- [学习者支持 Snapshot RPC](https://github.com/etcd-io/etcd/pull/12890/)。

### 包裹 `netutil`

- 删除

  `netutil.DropPort/RecoverPort/SetLatency/RemoveLatency`

  。

  - 这些都不再使用了。它们仅用于旧版本的功能测试。
  - 删除以遵守最佳安全实践，最大限度地减少任意 shell 调用。

### `tools/etcd-dump-metrics`

- 实施[输入验证以防止任意 shell 调用](https://github.com/etcd-io/etcd/pull/12491)。

### 依赖

- [`google.golang.org/grpc`](https://github.com/grpc/grpc-go/releases)从升级[**`v1.23.0`**](https://github.com/grpc/grpc-go/releases/tag/v1.23.0)到[**`v1.37.0`**](https://github.com/grpc/grpc-go/releases/tag/v1.37.0).
- [`go.uber.org/zap`](https://github.com/uber-go/zap/releases)从升级[**`v1.14.1`**](https://github.com/uber-go/zap/releases/tag/v1.14.1)到[**`v1.16.0`**](https://github.com/uber-go/zap/releases/tag/v1.16.0).

### 平台

- etcd 现在

  正式支持`arm64`

  .

  - 请参阅https://github.com/etcd-io/etcd/pull/12928以使用`arm64`EC2 实例 (Graviton 2)添加自动化测试。
  - 有关新的平台支持层策略，请参阅https://github.com/etcd-io/website/pull/273。

### 发布

- 添加 s390x 构建支持（[PR#11548](https://github.com/etcd-io/etcd/pull/11548)和[PR#11358](https://github.com/etcd-io/etcd/pull/11358)）

### 去

- 需要[*Go 1.16+*](https://github.com/etcd-io/etcd/pull/11110)。
- 用[*Go 1.16+*](https://golang.org/doc/devel/release.html#go1.16)编译
- etcd 使用[go 模块](https://github.com/etcd-io/etcd/pull/12279)（而不是供应商目录）来跟踪依赖项。

### 项目治理

- etcd 团队添加了一个明确定义和公开讨论的项目[治理](https://github.com/etcd-io/etcd/pull/11175)。