# Redis 哨兵文档

Redis Sentinel 为Redis 提供高可用。实际上，这意味着使用 Sentinel，您可以创建一个 Redis 部署，无需人工干预即可抵抗某些类型的故障。

Redis Sentinel 还提供其他附带任务，例如监控、通知并充当客户端的配置提供程序。

这是宏观层面（即*大图*）的 Sentinel 功能的完整列表：

- **监控**。Sentinel 会不断检查您的主实例和副本实例是否按预期工作。
- **通知**。Sentinel 可以通过 API 通知系统管理员或其他计算机程序，其中一个受监控的 Redis 实例出现问题。
- **自动故障转移**。如果 master 没有按预期工作，Sentinel 可以启动一个故障转移过程，其中一个副本被提升为 master，其他额外的副本被重新配置为使用新的 master，并且使用 Redis 服务器的应用程序会被告知要使用的新地址连接时。
- **配置提供程序**。Sentinel 充当客户端服务发现的权威来源：客户端连接到 Sentinel 以请求负责给定服务的当前 Redis 主节点的地址。如果发生故障转移，Sentinels 将报告新地址。



## Sentinel 的分布式特性

Redis Sentinel 是一个分布式系统：

Sentinel 本身旨在运行在多个 Sentinel 进程协同工作的配置中。多个 Sentinel 进程协作的优势如下：

1. 当多个 Sentinel 同意某个给定的 master 不再可用时，就会执行故障检测。这降低了误报的可能性。
2. 即使并非所有 Sentinel 进程都在工作，Sentinel 也能正常工作，从而使系统能够抵御故障。毕竟，拥有一个本身就是单点故障的故障转移系统并没有什么乐趣。

Sentinel、Redis 实例（主实例和副本）以及连接到 Sentinel 和 Redis 的客户端的总和，也是一个具有特定属性的更大的分布式系统。在本文档中，概念将从理解 Sentinel 的基本属性所需的基本信息开始，到更复杂的信息（可选）以了解 Sentinel 的工作原理。



# 快速开始



## 获取哨兵

Sentinel 的当前版本称为**Sentinel 2**。它使用更强大且更易于预测的算法（在本文档中进行了解释）重写了最初的 Sentinel 实现。

从 Redis 2.8 开始提供稳定版本的 Redis Sentinel。

新的开发在*不稳定的*分支中进行，新功能有时会在被认为稳定后立即移植到最新的稳定分支中。

Redis Sentinel 版本 1 随 Redis 2.6 一起提供，已弃用，不应使用。



## 运行哨兵

如果您正在使用`redis-sentinel`可执行文件（或者如果您有一个具有该名称的符号链接到`redis-server`可执行文件），您可以使用以下命令行运行 Sentinel：

```
redis-sentinel /path/to/sentinel.conf
```

否则，您可以直接使用`redis-server`在 Sentinel 模式下启动它的可执行文件：

```
redis-server /path/to/sentinel.conf --sentinel
```

两种方式的工作方式相同。

但是**，**在运行 Sentinel 时**必须**使用配置文件，因为系统将使用该文件来保存在重启时将重新加载的当前状态。如果没有给出配置文件或配置文件路径不可写，Sentinel 将简单地拒绝启动。

Sentinel 默认运行**侦听 TCP 端口 26379 的连接**，因此**要使**Sentinel 工作，您的服务器的端口 26379**必须打开**以接收来自其他 Sentinel 实例的 IP 地址的连接。否则哨兵不能说话，也不能就该做什么达成一致，所以永远不会执行故障转移。



## 部署前需要了解的关于 Sentinel 的基本知识

1. 您至少需要三个 Sentinel 实例才能进行稳健的部署。
2. 应该将三个 Sentinel 实例放置在被认为以独立方式发生故障的计算机或虚拟机中。例如，在不同的可用区域上执行的不同物理服务器或虚拟机。
3. Sentinel + Redis 分布式系统不保证在故障期间保留已确认的写入，因为 Redis 使用异步复制。然而，有一些方法可以部署 Sentinel，使丢失写入的窗口限于某些时刻，而还有其他不太安全的部署方法。
4. 您的客户需要 Sentinel 支持。流行的客户端库有 Sentinel 支持，但不是全部。
5. 没有 HA 设置是安全的，如果您不在开发环境中不时进行测试，或者如果可以的话，在生产环境中，如果它们可以工作，则更好。您可能有一个错误配置，只有在为时已晚（在您的主人停止工作的凌晨 3 点）时才会变得明显。
6. **Sentinel、Docker 或其他形式的网络地址转换或端口映射应谨慎混合使用**：Docker 执行端口重新映射，破坏其他 Sentinel 进程的 Sentinel 自动发现以及主服务器的副本列表。查看本文档后面[有关*Sentinel 和 Docker*](https://redis.io/topics/sentinel#sentinel-docker-nat-and-possible-issues)的[部分](https://redis.io/topics/sentinel#sentinel-docker-nat-and-possible-issues)以获取更多信息。



## 配置哨兵

Redis 源代码分发包含一个名为的文件`sentinel.conf` ，该文件是可用于配置 Sentinel 的自文档示例配置文件，但典型的最小配置文件如下所示：

```
sentinel monitor mymaster 127.0.0.1 6379 2
sentinel down-after-milliseconds mymaster 60000
sentinel failover-timeout mymaster 180000
sentinel parallel-syncs mymaster 1

sentinel monitor resque 192.168.1.3 6380 4
sentinel down-after-milliseconds resque 10000
sentinel failover-timeout resque 180000
sentinel parallel-syncs resque 5
```

您只需要指定要监控的主节点，为每个分离的主节点（可能有任意数量的副本）指定不同的名称。无需指定自动发现的副本。Sentinel 将使用有关副本的附加信息自动更新配置（以便在重新启动时保留该信息）。每次在故障转移期间将副本提升为主服务器以及每次发现新的 Sentinel 时，都会重写配置。

上面的示例配置基本上监控了两组 Redis 实例，每组由一个主实例和未定义数量的副本组成。一组实例称为`mymaster`，另一组称为`resque`。

`sentinel monitor`语句参数的含义如下：

```
sentinel monitor <master-group-name> <ip> <port> <quorum>
```

为了清楚起见，让我们逐行检查配置选项的含义：

第一行用于告诉 Redis 监视名为*mymaster*的主*节点*，该主*节点*位于地址 127.0.0.1 和端口 6379，仲裁为 2。一切都很明显，但**仲裁**参数：

- 该**仲裁**是需要同意的事实主人是不可达的，这样才能真正纪念主为失败，并在可能最终开始故障转移过程哨兵的数量。
- 然而**，仲裁仅用于检测故障**。为了实际执行故障转移，其中一个哨兵需要被选为故障转移的领导者并被授权继续。这只发生在**大多数 Sentinel 进程**的投票中。

因此，例如，如果您有 5 个 Sentinel 进程，并且给定 master 的仲裁设置为值 2，则会发生以下情况：

- 如果两个 Sentinel 同时同意 master 无法访问，则两者之一将尝试启动故障转移。
- 如果总共至少有三个 Sentinel 可访问，则故障转移将被授权并实际开始。

实际上，这意味着在故障期间，**如果大多数 Sentinel 进程无法通信**（也就是少数分区中没有故障转移），则**Sentinel 永远不会启动故障转移**。



## 其他哨兵选项

其他选项几乎总是采用以下形式：

```
sentinel <option_name> <master_name> <option_value>
```

并用于以下目的：

- `down-after-milliseconds` 是 Sentinel 开始认为它已关闭的实例不应该可达的时间（以毫秒为单位）（要么不回复我们的 PING，要么回复错误）。
- `parallel-syncs`设置可以在故障转移后同时重新配置为使用新主服务器的副本数。数字越小，完成故障转移过程所需的时间就越长，但是，如果将副本配置为提供旧数据，您可能不希望所有副本同时与主服务器重新同步。虽然复制过程对于副本来说大多是非阻塞的，但有时它会停止从主服务器加载批量数据。您可能希望通过将此选项设置为值 1 来确保一次只能访问一个副本。

本文档的其余部分描述了其他选项，并记录在`sentinel.conf`Redis 分发版附带的示例文件中。

可以在运行时修改配置参数：

- 使用`SENTINEL SET`.
- 全局配置参数使用`SENTINEL CONFIG SET`.

有关更多信息，请参阅[*在运行时重新配置 Sentinel*部分](https://redis.io/topics/sentinel#reconfiguring-sentinel-at-runtime)。



## Sentinel 部署示例

现在您已经了解了有关 Sentinel 的基本信息，您可能想知道应该将 Sentinel 进程放在哪里，需要多少 Sentinel 进程等等。本节显示了一些示例部署。

我们使用 ASCII art 以*图形* 格式向您展示配置示例，这就是不同符号的含义：

```
+--------------------+
| This is a computer |
| or VM that fails   |
| independently. We  |
| call it a "box"    |
+--------------------+
```

我们在框中写下它们正在运行的内容：

```
+-------------------+
| Redis master M1   |
| Redis Sentinel S1 |
+-------------------+
```

不同的盒子用线连接起来，表示它们会说话：

```
+-------------+               +-------------+
| Sentinel S1 |---------------| Sentinel S2 |
+-------------+               +-------------+
```

网络分区使用斜线显示为中断线：

```
+-------------+                +-------------+
| Sentinel S1 |------ // ------| Sentinel S2 |
+-------------+                +-------------+
```

另请注意：

- 大师被称为M1，M2，M3，...，Mn。
- 副本称为 R1、R2、R3、...、Rn（R 代表*副本*）。
- 哨兵被称为 S1、S2、S3、...、Sn。
- 客户端称为 C1、C2、C3、...、Cn。
- 当一个实例因为 Sentinel 动作而改变角色时，我们把它放在方括号里，所以 [M1] 意味着一个现在因为 Sentinel 干预而成为 master 的实例。

请注意，我们永远不会显示**只使用两个 Sentinel 的设置**，因为 Sentinel 总是需要**与大多数人交谈**才能启动故障转移。



## 示例 1：只有两个 Sentinel，不要这样做

```
+----+         +----+
| M1 |---------| R1 |
| S1 |         | S2 |
+----+         +----+

Configuration: quorum = 1
```

- 在这个设置中，如果主 M1 发生故障，R1 将被提升，因为两个 Sentinel 可以就故障达成一致（显然法定人数设置为 1）并且还可以授权故障转移，因为多数是二。显然它表面上可以工作，但是请检查下一点以了解为什么此设置已损坏。
- 如果M1运行的盒子停止工作，S1也停止工作。在另一个盒子 S2 中运行的 Sentinel 将无法授权故障转移，因此系统将变得不可用。

请注意，需要多数来订购不同的故障转移，然后将最新配置传播到所有 Sentinel。另请注意，在上述设置的单侧进行故障转移的能力，没有任何协议，将是非常危险的：

```
+----+           +------+
| M1 |----//-----| [M1] |
| S1 |           | S2   |
+----+           +------+
```

在上面的配置中，我们以完全对称的方式创建了两个 master（假设 S2 可以在未经授权的情况下进行故障转移）。客户端可能会无限期地向双方写入，并且无法了解分区何时恢复正确的配置，以防止*永久性裂脑情况*。

所以请始终**在三个不同的盒子中部署至少三个 Sentinel**。



## 示例 2：三个盒子的基本设置

这是一个非常简单的设置，其优点是易于调整以提高安全性。它基于三个盒子，每个盒子同时运行一个 Redis 进程和一个 Sentinel 进程。

```
       +----+
       | M1 |
       | S1 |
       +----+
          |
+----+    |    +----+
| R2 |----+----| R3 |
| S2 |         | S3 |
+----+         +----+

Configuration: quorum = 2
```

如果主 M1 发生故障，S2 和 S3 将就故障达成一致，并能够授权故障转移，使客户端能够继续。

在每个 Sentinel 设置中，由于 Redis 使用异步复制，总是存在丢失一些写入的风险，因为给定的确认写入可能无法到达提升为主节点的副本。然而，在上面的设置中，由于客户端被旧主机分区，因此存在更高的风险，如下图所示：

```
         +----+
         | M1 |
         | S1 | <- C1 (writes will be lost)
         +----+
            |
            /
            /
+------+    |    +----+
| [M2] |----+----| R3 |
| S2   |         | S3 |
+------+         +----+
```

在这种情况下，网络分区隔离了旧的 master M1，因此副本 R2 被提升为 master。然而，像 C1 这样与旧主服务器在同一分区中的客户端可能会继续向旧主服务器写入数据。这些数据将永远丢失，因为当分区恢复时，master 将被重新配置为新 master 的副本，丢弃其数据集。

可以使用以下 Redis 复制功能缓解此问题，如果主节点检测到它不再能够将其写入传输到指定数量的副本，则该功能允许停止接受写入。

```
min-replicas-to-write 1
min-replicas-max-lag 10
```

使用上述配置（`redis.conf`更多信息请参见Redis发行版中的自我注释示例），Redis实例在充当master时，如果无法写入至少1个副本，则将停止接受写入。由于复制是异步的，*因此无法写入*实际上意味着副本已断开连接，或者没有向我们发送超过指定`max-lag`秒数的异步确认。

使用此配置，上例中的旧 Redis master M1 将在 10 秒后变得不可用。当分区恢复时，哨兵配置将收敛到新的配置，客户端 C1 将能够获取有效配置并继续使用新的主配置。

然而天下没有免费的午餐。通过这种改进，如果两个副本宕机，主节点将停止接受写入。这是一种权衡。



## 示例 3：客户端中的 Sentinel

有时我们只有两个 Redis 盒子可用，一个用于主服务器，一个用于副本。示例 2 中的配置在这种情况下不可行，因此我们可以采用以下方法，其中 Sentinel 放置在客户端的位置：

```
            +----+         +----+
            | M1 |----+----| R1 |
            |    |    |    |    |
            +----+    |    +----+
                      |
         +------------+------------+
         |            |            |
         |            |            |
      +----+        +----+      +----+
      | C1 |        | C2 |      | C3 |
      | S1 |        | S2 |      | S3 |
      +----+        +----+      +----+

      Configuration: quorum = 2
```

在这个设置中，Sentinels 的观点与客户端相同：如果大多数客户端可以访问主节点，那就没问题了。这里的C1、C2、C3是通用客户端，并不代表C1标识连接到Redis的单个客户端。它更有可能是应用服务器、Rails 应用程序或类似的东西。

如果运行 M1 和 S1 的机器出现故障，故障转移将毫无问题地发生，但是很容易看出不同的网络分区会导致不同的行为。例如，如果客户端和 Redis 服务器之间的网络断开，Sentinel 将无法设置，因为 Redis 主节点和副本都将不可用。

请注意，如果 C3 被 M1 分区（使用上述网络几乎不可能，但更可能使用不同的布局，或者由于软件层的故障），我们会遇到与示例 2 中所述类似的问题，不同之处在于这里我们没有办法打破对称性，因为只有一个副本和主节点，所以主节点在与副本断开连接时不能停止接受查询，否则在副本失败时主节点将永远不可用。

所以这是一个有效的设置，但示例 2 中的设置具有优势，例如 Redis 的 HA 系统与 Redis 本身在相同的盒子中运行，这可能更易于管理，并且能够限制时间量少数分区中的 master 可以接收写入。



## 示例 4：少于三个客户端的 Sentinel 客户端

如果客户端少于三个框（例如三个 Web 服务器），则无法使用示例 3 中描述的设置。在这种情况下，我们需要采用如下混合设置：

```
            +----+         +----+
            | M1 |----+----| R1 |
            | S1 |    |    | S2 |
            +----+    |    +----+
                      |
               +------+-----+
               |            |
               |            |
            +----+        +----+
            | C1 |        | C2 |
            | S3 |        | S4 |
            +----+        +----+

      Configuration: quorum = 3
```

这类似于示例 3 中的设置，但这里我们在可用的四个框中运行四个 Sentinel。如果主 M1 变得不可用，其他三个哨兵将执行故障转移。

理论上，此设置可以移除运行 C2 和 S4 的框，并将仲裁设置为 2。但是，如果我们的应用程序层没有高可用性，我们不太可能希望 Redis 端具有 HA。



## Sentinel、Docker、NAT 和可能的问题

Docker 使用一种称为端口映射的技术：与程序认为正在使用的端口相比，在 Docker 容器内运行的程序可能会使用不同的端口公开。这对于在同一服务器中同时使用相同端口运行多个容器非常有用。

Docker 不是唯一发生这种情况的软件系统，还有其他网络地址转换设置可以重新映射端口，有时不是端口而是 IP 地址。

重新映射端口和地址会以两种方式与 Sentinel 产生问题：

1. Sentinel 对其他 Sentinel 的自动发现不再有效，因为它基于*hello*消息，其中每个 Sentinel 宣布它们正在侦听连接的端口和 IP 地址。然而 Sentinel 无法理解地址或端口被重新映射，因此它宣布了一个不正确的信息，其他 Sentinel 无法连接。
2. 副本以类似的方式列在Redis 主节点的[INFO](https://redis.io/commands/info)输出中：主节点通过检查 TCP 连接的远程对等方来检测地址，而端口在握手期间由副本自身通告，但是端口可能是错误的原因与第 1 点中暴露的原因相同。

由于 Sentinel 使用 masters [INFO](https://redis.io/commands/info)输出信息自动检测副本，因此检测到的副本将无法访问，并且 Sentinel 将永远无法对 master 进行故障转移，因为从系统的角度来看没有好的副本，因此目前没有使用 Sentinel 监视一组使用 Docker 部署的主实例和副本实例的方法，**除非您指示 Docker 映射端口 1:1**。

对于第一个问题，如果您想使用带有转发端口的 Docker（或任何其他重新映射端口的 NAT 设置）运行一组 Sentinel 实例，您可以使用以下两个 Sentinel 配置指令来强制 Sentinel 宣布一个一组特定的 IP 和端口：

```
sentinel announce-ip <ip>
sentinel announce-port <port>
```

请注意，Docker 能够在*主机网络模式下运行*（查看该`--net=host`选项以获取更多信息）。这应该不会产生问题，因为在此设置中不会重新映射端口。



## IP 地址和 DNS 名称

旧版本的 Sentinel 不支持主机名，并且需要在任何地方指定 IP 地址。从 6.2 版开始，Sentinel*可选*支持主机名。

**默认情况下禁用此功能。如果您要启用 DNS/主机名支持，请注意：**

1. Redis 和 Sentinel 节点上的名称解析配置必须可靠并且能够快速解析地址。地址解析中的意外延迟可能会对 Sentinel 产生负面影响。
2. 您应该在任何地方使用主机名并避免混合主机名和 IP 地址。为此，请分别对所有 Redis 和 Sentinel 实例使用`replica-announce-ip <hostname>`和`sentinel announce-ip <hostname>`。

启用`resolve-hostnames`全局配置允许 Sentinel 接受主机名：

- 作为`sentinel monitor`命令的一部分
- 作为副本地址，如果副本使用主机名值 `replica-announce-ip`

Sentinel 将接受主机名作为有效输入并解析它们，但在宣布实例、更新配置文件等时仍会引用 IP 地址。

启用`announce-hostnames`全局配置会使 Sentinel 改用主机名。这会影响对客户端的回复、写入配置文件的值、向副本发出的[REPLICAOF](https://redis.io/commands/replicaof)命令等。

此行为可能与所有可能明确要求 IP 地址的 Sentinel 客户端不兼容。

当客户端使用 TLS 连接到实例并需要名称而不是 IP 地址以执行证书 ASN 匹配时，使用主机名可能很有用。



# 快速教程

在本文档的下一部分中，将逐步介绍有关[*Sentinel API*](https://redis.io/topics/sentinel#sentinel-api)、配置和语义的所有详细信息。然而，对于想要尽快使用系统的人来说，本节是一个教程，展示了如何配置 3 个 Sentinel 实例并与之交互。

这里我们假设实例在端口 5000、5001、5002 上执行。我们还假设您在端口 6379 上有一个正在运行的 Redis 主服务器，在端口 6380 上运行一个副本。我们将在此期间到处使用 IPv4 环回地址 127.0.0.1教程，假设您在个人计算机上运行模拟。

三个 Sentinel 配置文件应如下所示：

```
port 5000
sentinel monitor mymaster 127.0.0.1 6379 2
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
sentinel parallel-syncs mymaster 1
```

其他两个配置文件将相同，但使用 5001 和 5002 作为端口号。

以上配置需要注意的几点：

- 主集称为`mymaster`。它标识主节点及其副本。由于每个*主集*有不同的名称，Sentinel 可以同时监控不同的主集和副本集。
- 法定人数设置为 2（`sentinel monitor`配置指令的最后一个参数）的值。
- 该`down-after-milliseconds`值是 5000 毫秒，即 5 秒，因此只要我们在这段时间内没有收到来自 ping 的任何回复，就会检测到主节点失败。

启动三个 Sentinel 后，您将看到它们记录的一些消息，例如：

```
+monitor master mymaster 127.0.0.1 6379 quorum 2
```

这是一个 Sentinel 事件，如果您[订阅](https://redis.io/commands/subscribe)了稍后在[*Pub/Sub 消息*部分中](https://redis.io/topics/sentinel#pubsub-messages)指定的事件名称，您可以通过 Pub/Sub 接收此类事件。

Sentinel 在故障检测和故障转移期间生成并记录不同的事件。



## 向 Sentinel 询问 master 的状态

开始使用 Sentinel 最明显的事情是检查它正在监视的 master 是否运行良好：

```
$ redis-cli -p 5000
127.0.0.1:5000> sentinel master mymaster
 1) "name"
 2) "mymaster"
 3) "ip"
 4) "127.0.0.1"
 5) "port"
 6) "6379"
 7) "runid"
 8) "953ae6a589449c13ddefaee3538d356d287f509b"
 9) "flags"
10) "master"
11) "link-pending-commands"
12) "0"
13) "link-refcount"
14) "1"
15) "last-ping-sent"
16) "0"
17) "last-ok-ping-reply"
18) "735"
19) "last-ping-reply"
20) "735"
21) "down-after-milliseconds"
22) "5000"
23) "info-refresh"
24) "126"
25) "role-reported"
26) "master"
27) "role-reported-time"
28) "532439"
29) "config-epoch"
30) "1"
31) "num-slaves"
32) "1"
33) "num-other-sentinels"
34) "2"
35) "quorum"
36) "2"
37) "failover-timeout"
38) "60000"
39) "parallel-syncs"
40) "1"
```

如您所见，它打印了有关 master 的许多信息。有一些我们特别感兴趣：

1. `num-other-sentinels`是 2，所以我们知道 Sentinel 已经为这个 master 检测到了另外两个 Sentinel。如果您检查日志，您将看到`+sentinel`生成的事件。
2. `flags`只是`master`. 如果主人倒下了，我们也可以在这里看到`s_down`或`o_down`标记。
3. `num-slaves` 正确设置为 1，因此 Sentinel 还检测到我们的主服务器附加了一个副本。

为了探索有关此实例的更多信息，您可能需要尝试以下两个命令：

```
SENTINEL replicas mymaster
SENTINEL sentinels mymaster
```

第一个将提供有关连接到 master 的副本的类似信息，第二个将提供有关其他 Sentinel 的信息。



## 获取当前master的地址

正如我们已经指定的那样，Sentinel 还充当想要连接到一组主副本和副本的客户端的配置提供程序。由于可能的故障转移或重新配置，客户端不知道谁是给定实例集的当前活动主服务器，因此 Sentinel 导出了一个 API 来提出这个问题：

```
127.0.0.1:5000> SENTINEL get-master-addr-by-name mymaster
1) "127.0.0.1"
2) "6379"
```



## 测试故障转移

此时，我们的玩具 Sentinel 部署已准备好进行测试。我们可以杀死我们的主人并检查配置是否发生变化。为此，我们可以这样做：

```
redis-cli -p 6379 DEBUG sleep 30
```

此命令将使我们的 master 不再可访问，休眠 30 秒。它基本上模拟了出于某种原因挂起的主人。

如果您检查 Sentinel 日志，您应该能够看到很多操作：

1. 每个 Sentinel 都会检测到 master 因`+sdown`事件而宕机。
2. 此事件后来升级为`+odown`，这意味着多个 Sentinel 同意无法访问 master 的事实。
3. Sentinel 投票选出将开始第一次故障转移尝试的 Sentinel。
4. 故障转移发生。

如果你再次询问 的当前主地址是什么`mymaster`，最终我们这次应该得到不同的答复：

```
127.0.0.1:5000> SENTINEL get-master-addr-by-name mymaster
1) "127.0.0.1"
2) "6380"
```

到目前为止一切顺利……此时您可以跳转到创建您的 Sentinel 部署，或者可以阅读更多内容以了解所有 Sentinel 命令和内部结构。



# 哨兵API

Sentinel 提供了一个 API 以检查其状态、检查受监控的主节点和副本的健康状况、订阅以接收特定通知以及在运行时更改 Sentinel 配置。

默认情况下，Sentinel 使用 TCP 端口 26379 运行（请注意，6379 是普通的 Redis 端口）。Sentinel 接受使用 Redis 协议的命令，因此您可以使用`redis-cli`或任何其他未修改的 Redis 客户端来与 Sentinel 对话。

可以直接查询 Sentinel 以从其角度检查受监控 Redis 实例的状态，查看它知道的其他 Sentinel，等等。或者，使用 Pub/Sub，可以在每次发生某些事件（例如故障转移或实例进入错误条件等）时从 Sentinel接收*推送样式*通知。



## 哨兵命令

该`SENTINEL`命令是 Sentinel 的主要 API。以下是其子命令的列表（在适用的地方注明了最低版本）：

- **SENTINEL CONFIG GET`<name>`** ( `>= 6.2`) 获取全局 Sentinel 配置参数的当前值。指定的名称可以是通配符，类似于Redis [CONFIG GET](https://redis.io/commands/config-get)命令。
- **SENTINEL CONFIG SET`<name>` `<value>`** ( `>= 6.2`) 设置全局 Sentinel 配置参数的值。
- **SENTINEL CKQUORUM`<master name>`**检查当前 Sentinel 配置是否能够达到故障转移主服务器所需的法定人数，以及授权故障转移所需的大多数人数。此命令应用于监控系统以检查 Sentinel 部署是否正常。
- **SENTINEL FLUSHCONFIG**强制 Sentinel 在磁盘上重写其配置，包括当前 Sentinel 状态。通常 Sentinel 会在每次其状态发生变化时重写配置（在状态子集的上下文中，该子集在重新启动时保留在磁盘上）。但是有时配置文件可能会因为操作错误、磁盘故障、包升级脚本或配置管理器而丢失。在这些情况下，强制 Sentinel 重写配置文件的方法很方便。即使之前的配置文件完全丢失，此命令也能工作。
- **SENTINEL FAILOVER`<master name>`**强制故障转移，就好像主**节点**不可访问一样，并且不要求其他 Sentinel 同意（但是，将发布新版本的配置，以便其他 Sentinel 更新其配置）。
- **SENTINEL GET-MASTER-ADDR-BY-NAME`<master name>`**返回具有该名称的 master 的 ip 和端口号。如果此主服务器的故障转移正在进行或成功终止，它会返回提升的副本的地址和端口。
- **SENTINEL INFO-CACHE** ( `>= 3.2`)从 master 和**replica**返回缓存的[INFO](https://redis.io/commands/info)输出。
- **Sentinel IS-MASTER-DOWN-BY-ADDR** 从当前 Sentinel 的角度检查 ip:port 指定的 master 是否已关闭。此命令主要供内部使用。
- **SENTINEL MASTER`<master name>`**显示指定主机的状态和信息。
- **SENTINEL MASTERS**显示受监视的主机及其状态的列表。
- **SENTINEL MONITOR**启动 Sentinel 的监控。有关更多信息，请参阅[*在运行时重新配置 Sentinel*部分](https://redis.io/topics/sentinel#reconfiguring-sentinel-at-runtime)。
- **SENTINEL MYID** ( `>= 6.2`) 返回 Sentinel 实例的 ID。
- **SENTINEL PENDING-SCRIPTS**此命令返回有关挂起脚本的信息。
- **SENTINEL REMOVE**停止 Sentinel 的监控。有关更多信息，请参阅[*在运行时重新配置 Sentinel*部分](https://redis.io/topics/sentinel#reconfiguring-sentinel-at-runtime)。
- **SENTINEL REPLICAS`<master name>`** ( `>= 5.0`) 显示此主服务器的副本列表及其状态。
- **SENTINEL SENTINELS`<master name>`**显示此 master 的哨兵实例列表及其状态。
- **SENTINEL SET**设置 Sentinel 的监控配置。有关更多信息，请参阅[*在运行时重新配置 Sentinel*部分](https://redis.io/topics/sentinel#reconfiguring-sentinel-at-runtime)。
- **SENTINEL SIMULATE-FAILURE (crash-after-election|crash-after-promotion|help)** ( `>= 3.2`) 此命令模拟不同的 Sentinel 崩溃场景。
- **SENTINEL RESET`<pattern>`**此命令将重置所有具有匹配名称的主机。模式参数是一个全局样式的模式。重置过程会清除 master 中的任何先前状态（包括正在进行的故障转移），并删除已发现并与 master 关联的每个副本和哨兵。

出于连接管理和管理目的，Sentinel 支持以下 Redis 命令子集：

- **ACL** ( `>= 6.2`) 此命令管理 Sentinel 访问控制列表。有关详细信息，请参阅[ACL](https://redis.io/topics/acl)文档页面和[*Sentinel 访问控制列表身份验证*](https://redis.io/topics/sentinel#sentinel-access-control-list-authentication)。
- **AUTH** ( `>= 5.0.1`) 验证客户端连接。有关更多信息，请参阅[AUTH](https://redis.io/commands/auth)命令和[*使用身份验证配置 Sentinel 实例*部分](https://redis.io/topics/sentinel#configuring-sentinel-instances-with-authentication)。
- **CLIENT**此命令管理客户端连接。有关更多信息，请参阅其子命令页面。
- **COMMAND** ( `>= 6.2`) 此命令返回有关命令的信息。有关详细信息，请参阅[COMMAND](https://redis.io/commands/command)命令及其各种子命令。
- **HELLO** ( `>= 6.0`) 切换连接的协议。有关更多信息，请参阅[HELLO](https://redis.io/commands/hello)命令。
- **INFO**返回有关 Sentinel 服务器的信息和统计信息。有关更多信息，请参阅[INFO](https://redis.io/commands/info)命令。
- **PING**此命令仅返回 PONG。
- **ROLE**此命令返回字符串“sentinel”和受监控主站的列表。有关更多信息，请参阅[ROLE](https://redis.io/commands/role)命令。
- **SHUTDOWN**关闭 Sentinel 实例。

最后，Sentinel 还支持[SUBSCRIBE](https://redis.io/commands/subscribe)、[UNSUBSCRIBE](https://redis.io/commands/unsubscribe)、[PSUBSCRIBE](https://redis.io/commands/psubscribe)和[PUNSUBSCRIBE](https://redis.io/commands/punsubscribe)命令。有关更多详细信息，请参阅发布[*/订阅消息*部分](https://redis.io/topics/sentinel#pubsub-messages)。



## 在运行时重新配置 Sentinel

从 Redis 2.8.4 版开始，Sentinel 提供了一个 API 来添加、删除或更改给定主服务器的配置。请注意，如果您有多个哨兵，则应将更改应用于所有实例，以便 Redis Sentinel 正常工作。这意味着更改单个 Sentinel 的配置不会自动将更改传播到网络中的其他 Sentinel。

以下是`SENTINEL`用于更新 Sentinel 实例配置的子命令列表。

- **SENTINEL MONITOR`<name>` `<ip>` `<port>` `<quorum>`**此命令告诉 Sentinel 开始监视具有指定名称、IP、端口和仲裁的新主服务器。它与配置文件中的`sentinel monitor`配置指令相同`sentinel.conf`，区别在于不能在 as 中使用主机名`ip`，但需要提供 IPv4 或 IPv6 地址。
- **SENTINEL REMOVE`<name>`**用于移除指定的master：master将不再被监控，并将完全从Sentinel的内部状态中移除，因此它不再被`SENTINEL masters`等等列出。
- **SENTINEL SET `<name>`[ `<option>` `<value>`...]** [SET](https://redis.io/commands/config-set)命令与Redis的[CONFIG SET](https://redis.io/commands/config-set)命令非常相似，用于更改特定master 的配置参数。可以指定多个选项/值对（或根本不指定）。可以通过配置的所有配置参数也可以`sentinel.conf`使用 SET 命令进行配置。

以下是一个`SENTINEL SET`命令示例，用于修改`down-after-milliseconds`名为 的主站的配置`objects-cache`：

```
SENTINEL SET objects-cache-master down-after-milliseconds 1000
```

如前所述，`SENTINEL SET`可用于设置启动配置文件中可设置的所有配置参数。此外，可以仅更改 master 仲裁配置，而无需使用`SENTINEL REMOVE`后跟删除和重新添加 master `SENTINEL MONITOR`，而只需使用：

```
SENTINEL SET objects-cache-master quorum 5
```

请注意，没有等效的 GET 命令，因为`SENTINEL MASTER`它以易于解析的格式（作为字段/值对数组）提供所有配置参数。

从 Redis 6.2 版本开始，Sentinel 还允许获取和设置全局配置参数，这些参数仅在之前的配置文件中受支持。

- **SENTINEL CONFIG GET`<name>`**获取全局 Sentinel 配置参数的当前值。指定的名称可以是通配符，类似于Redis [CONFIG GET](https://redis.io/commands/config-get)命令。
- **SENTINEL CONFIG SET`<name>` `<value>`**设置全局 Sentinel 配置参数的值。

可以操作的全局参数包括：

- `resolve-hostnames`, `announce-hostnames`. 请参阅[*IP 地址和 DNS 名称*](https://redis.io/topics/sentinel#ip-addresses-and-dns-names)。
- `announce-ip`, `announce-port`. 请参阅[*Sentinel、Docker、NAT 和可能的问题*](https://redis.io/topics/sentinel#sentinel-docker-nat-and-possible-issues)。
- `sentinel-user`, `sentinel-pass`. 请参阅[*使用身份验证配置 Sentinel 实例*](https://redis.io/topics/sentinel#configuring-sentinel-instances-with-authentication)。



## 添加或删除哨兵

由于 Sentinel 实现了自动发现机制，因此将新 Sentinel 添加到您的部署中是一个简单的过程。您需要做的就是启动配置为监视当前活动主站的新 Sentinel。在 10 秒内，Sentinel 将获取其他 Sentinel 的列表以及附加到 master 的副本集。

如果需要一次添加多个Sentinel，建议一个接一个添加，等其他所有Sentinel都知道第一个，再添加下一个。这对于仍然保证多数只能在分区的一侧实现是很有用的，在添加新 Sentinel 的过程中可能会发生故障。

这可以通过在没有网络分区的情况下以 30 秒的延迟添加每个新 Sentinel 来轻松实现。

在该过程结束时，可以使用该命令 `SENTINEL MASTER mastername`来检查所有 Sentinel 是否同意监视 master 的 Sentinel 总数。

移除 Sentinel 有点复杂：**Sentinel 永远不会忘记已经看到的 Sentinel**，即使它们很长时间无法访问，因为我们不想动态更改授权故障转移和创建新配置所需的多数数字。因此，为了删除 Sentinel，应在没有网络分区的情况下执行以下步骤：

1. 停止要移除的 Sentinel 的 Sentinel 进程。
2. `SENTINEL RESET *`向所有其他 Sentinel 实例发送命令（`*`如果您只想重置一个主服务器，则可以使用确切的主服务器名称）。一个接一个，实例之间至少等待 30 秒。
3. 通过检查`SENTINEL MASTER mastername`每个 Sentinel的输出，检查所有 Sentinel 是否同意当前活动的 Sentinel 数量。



## 删除旧的 master 或无法访问的副本

Sentinel 永远不会忘记给定 master 的副本，即使它们很长一段时间都无法访问。这很有用，因为哨兵应该能够在网络分区或故障事件后正确地重新配置返回的副本。

此外，在故障转移后，故障转移的主服务器实际上被添加为新主服务器的副本，这样一旦新主服务器再次可用，它将被重新配置为与新主服务器进行复制。

但是，有时您希望从 Sentinels 监视的副本列表中永远删除一个副本（可能是旧的 master）。

为此，您需要向`SENTINEL RESET mastername`所有 Sentinel发送一个命令：它们将在接下来的 10 秒内刷新副本列表，只添加从当前主[INFO](https://redis.io/commands/info)输出中列为正确复制的副本。



## 发布/订阅消息

客户端可以将 Sentinel 用作与 Redis 兼容的发布/[订阅](https://redis.io/commands/subscribe)服务器（但您不能使用[PUBLISH](https://redis.io/commands/publish)），以便[订阅](https://redis.io/commands/subscribe)或[PSUBSCRIBE](https://redis.io/commands/psubscribe)到频道并获得有关特定事件的通知。

频道名称与事件名称相同。例如，命名的通道`+sdown`将接收与进入`SDOWN`（SDOWN 意味着从您正在查询的 Sentinel 的角度来看该实例不再可访问）条件的实例相关的所有通知。

要获取所有消息，只需使用 订阅即可`PSUBSCRIBE *`。

以下是您可以使用此 API 接收的频道和消息格式的列表。第一个字是通道/事件名称，其余的是数据的格式。

注意：指定*实例详细信息*的地方意味着提供以下参数来标识目标实例：

```
<instance-type> <name> <ip> <port> @ <master-name> <master-ip> <master-port>
```

标识 master 的部分（从 @ 参数到结尾）是可选的，并且仅在实例本身不是 master 时才指定。

- **+reset-master** `<instance details>` -- 主机被重置。
- **+slave** `<instance details>` -- 检测到并附加了一个新的副本。
- **+failover-state-reconf-slaves** `<instance details>` -- 故障转移状态更改为`reconf-slaves`state。
- **+failover-detected** `<instance details>` --**检测到**由另一个 Sentinel 或任何其他外部实体启动的故障转移（一个附加的副本变成了一个主）。
- **+slave-reconf-sent** `<instance details>` -- 领导哨兵向该实例发送[REPLICAOF](https://redis.io/commands/replicaof)命令，以便为新副本重新配置它。
- **+slave-reconf-inprog** `<instance details>` -- 正在重新配置的副本显示为新主 ip:port 对的副本，但同步过程尚未完成。
- **+slave-reconf-done** `<instance details>` -- 副本现在与新的主服务器同步。
- **-dup-sentinel** `<instance details>` -- 指定 master 的一个或多个 sentinel 被删除为重复的（例如，当 Sentinel 实例重新启动时会发生这种情况）。
- **+sentinel** `<instance details>` -- 检测到并附加了此主人的新哨兵。
- **+sdown** `<instance details>` -- 指定的实例现在处于主观关闭状态。
- **-sdown** `<instance details>` -- 指定的实例不再处于主观关闭状态。
- **+odown** `<instance details>` -- 指定的实例现在处于 Objectively Down 状态。
- **-odown** `<instance details>` -- 指定的实例不再处于 Objectively Down 状态。
- **+new-epoch** `<instance details>` -- 当前纪元已更新。
- **+try-failover** `<instance details>` -- 正在进行新的故障转移，等待多数人选举。
- **+elected-leader** `<instance details>` -- 赢得指定时期的选举，可以进行故障转移。
- **+failover-state-select-slave** `<instance details>` -- 新的故障转移状态是`select-slave`：我们正在尝试寻找合适的副本进行升级。
- **no-good-slave** `<instance details>` -- 没有好的副本可以推广。目前我们会在一段时间后尝试，但可能这会改变，在这种情况下状态机将完全中止故障转移。
- **selected-slave** `<instance details>` -- 我们找到了要提升的指定好的副本。
- **failover-state-send-slaveof-noone——** `<instance details>`我们正在尝试将提升的副本重新配置为主副本，等待它切换。
- **failover-end-for-timeout——** `<instance details>`故障转移因超时而终止，副本最终将被配置为与新的主**节点**进行复制。
- **故障转移结束** `<instance details>`——故障转移成功终止。所有副本似乎都被重新配置为使用新的主副本进行复制。
- **switch-master** `<master name> <oldip> <oldport> <newip> <newport>` -- 主新 IP 和地址是配置更改后指定的。这是**大多数外部用户感兴趣的消息**。
- **+tilt** -- 进入倾斜模式。
- **-tilt** -- 退出倾斜模式。



## -BUSY 状态的处理

当 Lua 脚本运行的时间超过配置的 Lua 脚本时间限制时，Redis 实例会返回 -BUSY 错误。在触发故障转移之前发生这种情况时，Redis Sentinel 将尝试发送[SCRIPT KILL](https://redis.io/commands/script-kill) 命令，只有在脚本为只读时才会成功。

如果在此尝试后实例仍处于错误状态，则最终将进行故障转移。



## 副本优先级

Redis 实例有一个名为`replica-priority`. 此信息由 Redis 副本实例在其[INFO](https://redis.io/commands/info)输出中公开，Sentinel 使用它从可用于故障转移主服务器的副本中选择一个副本：

1. 如果副本优先级设置为 0，则副本永远不会提升为主服务器。
2. Sentinel 首选具有*较低*优先级编号的副本。

比如当前master的同一个数据中心有一个副本S1，另一个数据中心有另一个副本S2，可以设置S1的优先级为10，S2的优先级为100，这样如果master 失败并且 S1 和 S2 都可用，则首选 S1。

有关副本选择方式的更多信息，请查看本文档的[*副本选择和优先级*部分](https://redis.io/topics/sentinel#replica-selection-and-priority)。



## Sentinel 和 Redis 身份验证

当 master 被配置为需要来自客户端的身份验证时，作为一种安全措施，副本也需要知道凭据，以便与 master 进行身份验证并创建用于异步复制协议的 master-replica 连接。



## Redis 访问控制列表认证

从 Redis 6 开始，用户身份验证和权限由[访问控制列表 (ACL) 管理](https://redis.io/topics/acl)。

为了让 Sentinel 在配置了 ACL 时连接到 Redis 服务器实例，Sentinel 配置必须包含以下指令：

```
sentinel auth-user <master-group-name> <username>
sentinel auth-pass <master-group-name> <password>
```

用于访问组实例的用户名和密码在哪里`<username>`和`<password>`在哪里。这些凭据应在具有最低控制权限的组的所有 Redis 实例上进行配置。例如：

```
127.0.0.1:6379> ACL SETUSER sentinel-user ON >somepassword allchannels +multi +slaveof +ping +exec +subscribe +config|rewrite +role +publish +info +client|setname +client|kill +script|kill
```



### Redis 仅密码身份验证

在 Redis 6 之前，使用以下配置指令实现身份验证：

- `requirepass` 在 master 中，为了设置认证密码，并确保实例不会处理非认证客户端的请求。
- `masterauth` 在副本中，以便副本与主服务器进行身份验证，以便从中正确复制数据。

使用Sentinel的时候，没有一个master，因为在failover之后，replicas可能会扮演masters的角色，老的masters可以重新配置作为replicas，所以你要做的就是在上面设置指令您的所有实例，包括主实例和副本实例。

这通常也是一个合理的设置，因为您不想只保护主服务器中的数据，在副本中可以访问相同的数据。

但是，在不常见的情况下，您需要一个无需身份验证即可访问的副本，您仍然可以通过设置**副本优先级为零**来防止此副本提升为主副本，并在此副本中仅配置`masterauth`指令，不使用该`requirepass`指令，以便未经身份验证的客户端可以读取数据。

为了让 Sentinel 在配置了 Redis 服务器实例时连接到 Redis 服务器实例`requirepass`，Sentinel 配置必须包含 `sentinel auth-pass`指令，格式为：

```
sentinel auth-pass <master-group-name> <password>
```



## 使用身份验证配置 Sentinel 实例

可以通过要求客户端通过[AUTH](https://redis.io/commands/auth)命令进行身份验证来保护 Sentinel 实例本身。从 Redis 6.2 开始，可以使用[访问控制列表 (ACL)](https://redis.io/topics/acl)，而以前的版本（从 Redis 5.0.1 开始）支持仅密码身份验证。

请注意，Sentinel 的身份验证配置应**应用于**部署中的**每个实例**，并且**所有实例应使用相同的配置**。此外，不应同时使用 ACL 和仅密码身份验证。



### Sentinel 访问控制列表身份验证

使用 ACL 保护 Sentinel 实例的第一步是防止对其进行任何未经授权的访问。为此，您需要禁用默认超级用户（或至少设置一个强密码）并创建一个新超级用户并允许它访问 Pub/Sub 频道：

```
127.0.0.1:5000> ACL SETUSER admin ON >admin-password allchannels +@all
OK
127.0.0.1:5000> ACL SETUSER default off
OK
```

Sentinel 使用默认用户连接到其他实例。您可以使用以下配置指令提供另一个超级用户的凭据：

```
sentinel sentinel-user <username>
sentinel sentinel-pass <password>
```

Sentinel 的超级用户和密码分别在哪里`<username>`和`<password>`是（例如`admin`和`admin-password`在上面的例子中）。

最后，为了验证传入的客户端连接，您可以创建 Sentinel 受限用户配置文件，如下所示：

```
127.0.0.1:5000> ACL SETUSER sentinel-user ON >user-password -@all +auth +client|getname +client|id +client|setname +command +hello +ping +role +sentinel|get-master-addr-by-name +sentinel|master +sentinel|myid +sentinel|replicas +sentinel|sentinels
```

有关更多信息，请参阅您选择的 Sentinel 客户端的文档。



### Sentinel 仅密码身份验证

要将 Sentinel 与仅密码身份验证一起使用，请将`requirepass`配置指令添加到**所有**Sentinel 实例，如下所示：

```
requirepass "your_password_here"
```

以这种方式配置时，哨兵将做两件事：

1. 客户端需要密码才能向 Sentinels 发送命令。这是显而易见的，因为这就是此类配置指令在 Redis 中的工作方式。
2. 此外，该 Sentinel 实例将使用配置为访问本地 Sentinel 的相同密码，以便对其连接的所有其他 Sentinel 实例进行身份验证。

这意味着**您必须`requirepass`在所有 Sentinel 实例中配置相同的密码**。这样每个 Sentinel 都可以与其他 Sentinel 通信，而无需为每个 Sentinel 配置访问所有其他 Sentinel 的密码，这是非常不切实际的。

在使用此配置之前，请确保您的客户端库可以向Sentinel 实例发送[AUTH](https://redis.io/commands/auth)命令。



## 哨兵客户端实现

Sentinel 需要明确的客户端支持，除非系统配置为执行脚本，该脚本执行将所有请求透明重定向到新主实例（虚拟 IP 或其他类似系统）。客户端库实现的主题包含在文档[Sentinel 客户端指南中](https://redis.io/topics/sentinel-clients)。



# 更先进的概念

在接下来的部分中，我们将介绍有关 Sentinel 如何工作的一些细节，而不会诉诸于本文档最后一部分将介绍的实现细节和算法。



## SDOWN和ODOWN故障状态

Redis Sentinel 有两种不同的*停机*概念，一种称为*主观停机*条件 (SDOWN)，是给定 Sentinel 实例本地的停机条件。另一种称为*客观关闭* 条件（ODOWN），当足够多的 Sentinels（至少配置为`quorum`被监控主机的参数的数量）具有 SDOWN 条件时达到，并使用`SENTINEL is-master-down-by-addr`命令从其他 Sentinels 获取反馈。

从 Sentinel 的角度来看，当它在配置中作为`is-master-down-after-milliseconds` 参数指定的秒数内没有收到对 PING 请求的有效回复时，就会达到 SDOWN 条件。

对 PING 的可接受回复是以下之一：

- PING 回复 +PONG。
- PING 回复 -LOADING 错误。
- PING 回复 -MASTERDOWN 错误。

任何其他回复（或根本没有回复）都被视为无效。但是请注意，**在 INFO 输出中将自己宣传为副本的逻辑主机被视为已关闭**。

请注意，SDOWN 要求在配置的整个间隔内不会收到任何可接受的回复，例如，如果间隔是 30000 毫秒（30 秒）并且我们每 29 秒收到一个可接受的 ping 回复，则认为该实例正在工作。

SDOWN 不足以触发故障转移：它仅意味着单个 Sentinel 认为 Redis 实例不可用。要触发故障转移，必须达到 ODOWN 状态。

要从 SDOWN 切换到 ODOWN，没有使用强一致性算法，而只是一种八卦形式：如果给定的 Sentinel 收到报告说**在给定的时间范围内**主节点没有从足够的 Sentinel 工作，则 SDOWN 被提升为 ODOWN。如果此确认稍后丢失，则清除该标志。

需要使用实际多数的更严格的授权才能真正启动故障转移，但不达到 ODOWN 状态就不能触发故障转移。

ODOWN 条件**仅适用于 masters**。对于其他类型的实例，哨兵不需要采取行动，因此副本和其他哨兵永远不会达到 ODOWN 状态，但只有 SDOWN 是。

然而 SDOWN 也有语义含义。例如，处于 SDOWN 状态的副本不会被执行故障转移的 Sentinel 选择提升。



## 哨兵和副本自动发现

Sentinel 与其他 Sentinel 保持连接，以便相互检查彼此的可用性并交换消息。但是，您不需要在您运行的每个 Sentinel 实例中配置其他 Sentinel 地址的列表，因为 Sentinel 使用 Redis 实例的 Pub/Sub 功能来发现正在监视相同主节点和副本的其他 Sentinel。

此功能是通过将*hello 消息发送*到名为 的通道 来实现的`__sentinel__:hello`。

类似地，您不需要配置附加到主服务器的副本列表是什么，因为 Sentinel 会通过查询 Redis 自动发现此列表。

- 每个 Sentinel`__sentinel__:hello`每两秒向每个受监控的主和副本 Pub/Sub 通道发布一条消息，通过 ip、端口、runid 宣布其存在。
- 每个 Sentinel 订阅`__sentinel__:hello`每个 master 和 replica的 Pub/Sub 通道，寻找未知的哨兵。当检测到新的哨兵时，将它们添加为该主站的哨兵。
- Hello 消息还包括主站的完整当前配置。如果接收 Sentinel 的给定 master 的配置比收到的旧，它会立即更新为新配置。
- 在向主服务器添加新哨兵之前，哨兵总是检查是否已经存在具有相同 runid 或相同地址（IP 和端口对）的哨兵。在这种情况下，所有匹配的哨兵都会被删除，并添加新的哨兵。



## 在故障转移过程之外对实例进行 Sentinel 重新配置

即使没有进行故障转移，Sentinels 也会始终尝试在受监控的实例上设置当前配置。具体来说：

- 声称是 master 的副本（根据当前配置）将被配置为副本以与当前 master 进行复制。
- 连接到错误 master 的副本将被重新配置为使用正确的 master 进行复制。

对于 Sentinel 重新配置副本，必须在一段时间内观察错误的配置，这比用于广播新配置的时间更长。

这可以防止配置陈旧的哨兵（例如，因为他们刚刚从分区重新加入）在收到更新之前尝试更改副本配置。

还要注意总是尝试强加当前配置的语义如何使故障转移对分区更具抵抗力：

- 故障转移的主节点在返回可用时被重新配置为副本。
- 在分区期间被分区的副本一旦可达就会重新配置。

关于本节要记住的重要教训是：**Sentinel 是一个系统，其中每个进程将始终尝试将最后一个逻辑配置强加给一组受监视的实例**。



## 副本选择和优先级

当 Sentinel 实例准备好执行故障转移时，由于 master 处于`ODOWN`state 并且 Sentinel 从大多数已知的 Sentinel 实例获得了故障转移的授权，因此需要选择合适的副本。

副本选择过程评估有关副本的以下信息：

1. 从主站断开连接的时间。
2. 副本优先。
3. 已处理复制偏移。
4. 运行标识。

一个副本被发现与 master 断开连接超过配置的 master 超时（down-after-milliseconds 选项）的十倍以上，加上从 Sentinel 执行故障转移的角度来看 master 也不可用的时间，被认为不适合故障转移并被跳过。

更严格地说，一个副本的[INFO](https://redis.io/commands/info)输出表明它已与主服务器断开连接超过：

```
(down-after-milliseconds * 10) + milliseconds_since_master_is_in_SDOWN_state
```

被认为是不可靠的并且完全被忽视。

副本选择仅考虑通过上述测试的副本，并根据上述标准，按以下顺序对其进行排序。

1. 副本按照Redis 实例文件中的`replica-priority`配置进行排序`redis.conf`。较低的优先级将是首选。
2. 如果优先级相同，则检查replica处理的replication offset，选择从master接收到更多数据的replica。
3. 如果多个副本具有相同的优先级并处理来自主服务器的相同数据，则会执行进一步检查，选择具有字典序较小运行 ID 的副本。具有较低的运行 ID 对于副本来说并不是真正的优势，但对于使副本选择过程更具确定性而不是诉诸随机选择副本是有用的。

在大多数情况下，`replica-priority`不需要显式设置，因此所有实例将使用相同的默认值。如果有特定的故障转移首选项，则`replica-priority`必须在所有实例上设置，包括主实例，因为主实例可能在未来某个时间点成为副本——然后它需要适当的`replica-priority`设置。

Redis 实例可以配置一个特殊`replica-priority`的零，以便**永远不会**被 Sentinels 选为新的 master。然而，以这种方式配置的副本仍然会被 Sentinels 重新配置，以便在故障转移后与新的主服务器进行复制，唯一的区别是它本身永远不会成为主服务器。



# 算法和内部

在以下部分中，我们将探讨 Sentinel 行为的详细信息。用户并不严格需要了解所有细节，但深入了解 Sentinel 可能有助于更有效地部署和操作 Sentinel。



## 法定人数

前面的部分显示了 Sentinel 监控的每个主节点都与配置的**仲裁**相关联。它指定需要就主服务器的不可达性或错误条件达成一致以触发故障转移的 Sentinel 进程数。

但是，在触发故障转移后，为了真正执行故障转移，**至少需要大多数 Sentinel 授权 Sentinel 进行故障转移**。Sentinel 永远不会在存在少数 Sentinel 的分区中执行故障转移。

让我们试着把事情说得更清楚一点：

- 法定人数：需要检测错误条件以便将主服务器标记为**ODOWN**的 Sentinel 进程数。
- 故障转移由**ODOWN**状态触发。
- 一旦触发故障转移，尝试故障转移的 Sentinel 需要向大多数 Sentinel 请求授权（如果法定人数设置为大于多数的数字，则需要多于多数）。

差异可能看起来很微妙，但实际上很容易理解和使用。例如，如果您有 5 个 Sentinel 实例，并且法定人数设置为 2，则只要 2 个 Sentinel 认为无法访问主服务器，就会触发故障转移，但是只有当它获得时，两个 Sentinel 之一才能进行故障转移至少来自 3 个哨兵的授权。

相反，如果将仲裁配置为 5，则所有 Sentinel 必须就主错误情况达成一致，并且需要所有 Sentinel 的授权才能进行故障转移。

这意味着可以通过两种方式使用仲裁来调整 Sentinel：

1. 如果法定人数设置为小于我们部署的大多数 Sentinel 的值，我们基本上使 Sentinel 对 master 故障更加敏感，即使只有少数 Sentinel 不再能够与 master 交谈，也会触发故障转移.
2. 如果法定人数设置为大于大多数 Sentinel 的值，我们将使 Sentinel 仅在有大量（大于大多数）连接良好的 Sentinel 同意 master 宕机时才能进行故障转移。



## 配置时代

由于以下几个重要原因，哨兵需要获得多数人的授权才能启动故障转移：

当 Sentinel 被授权时，它会为它正在故障转移的主**节点**获得一个唯一的**配置纪元**。这是一个数字，将用于在故障转移完成后对新配置进行版本控制。因为大多数人同意将给定的版本分配给给定的 Sentinel，其他 Sentinel 将无法使用它。这意味着每个故障转移的每个配置都使用唯一版本进行版本控制。我们将看到为什么这如此重要。

此外，Sentinel 有一个规则：如果一个 Sentinel 为给定 master 的故障转移投票了另一个 Sentinel，它将等待一段时间再次尝试故障转移同一个 master。此延迟是`2 * failover-timeout`您可以在`sentinel.conf`. 这意味着 Sentinel 不会同时尝试对同一个 master 进行故障转移，第一个请求获得授权的将尝试，如果失败，另一个将在一段时间后尝试，依此类推。

Redis Sentinel 保证了*活性*属性，即如果大多数 Sentinel 能够通话，则最终在 master 宕机时将有权进行故障转移。

Redis Sentinel 还保证了每个 Sentinel 将使用不同*配置 epoch*故障转移同一个 master的*安全*属性。



## 配置传播

一旦 Sentinel 能够成功地故障转移一个 master，它将开始广播新配置，以便其他 Sentinel 将更新他们关于给定 master 的信息。

要将故障转移视为成功，它需要 Sentinel 能够将`REPLICAOF NO ONE`命令发送到选定的副本，并且稍后在主服务器的[INFO](https://redis.io/commands/info)输出中观察到切换到主服务器。

此时，即使replicas的重新配置正在进行，也认为failover成功，所有的Sentinels都需要开始上报新的配置。

传播新配置的方式是我们需要使用不同版本号（配置纪元）授权每个 Sentinel 故障转移的原因。

每个 Sentinel 都使用 Redis Pub/Sub 消息在 master 和所有副本中连续广播其 master 的配置版本。同时所有的 Sentinels 等待消息以查看其他 Sentinels 通告的配置是什么。

配置在`__sentinel__:hello`Pub/Sub 频道中广播。

因为每个配置都有不同的版本号，所以较大的版本总是胜过较小的版本。

例如，master 的配置`mymaster`开始时所有 Sentinel 都认为 master 位于 192.168.1.50:6379。此配置具有版本 1。一段时间后，Sentinel 被授权使用版本 2 进行故障转移。如果故障转移成功，它将开始广播新配置，例如 192.168.1.50:9000，版本 2。所有其他实例将看到此配置并相应地更新其配置，因为新配置具有更高的版本。

这意味着 Sentinel 保证了第二个活性属性：一组能够通信的 Sentinel 将全部收敛到具有更高版本号的相同配置。

基本上，如果网络被分区，每个分区都会收敛到更高的本地配置。在没有分区的特殊情况下，只有一个分区，每个 Sentinel 都会同意配置。



## 分区下的一致性

Redis Sentinel 配置最终是一致的，因此每个分区都会收敛到可用的更高配置。然而，在使用 Sentinel 的真实系统中，存在三种不同的玩家：

- Redis 实例。
- 哨兵实例。
- 客户。

为了定义系统的行为，我们必须考虑所有三个。

下面是一个简单的网络，其中有 3 个节点，每个节点运行一个 Redis 实例和一个 Sentinel 实例：

```
            +-------------+
            | Sentinel 1  |----- Client A
            | Redis 1 (M) |
            +-------------+
                    |
                    |
+-------------+     |          +------------+
| Sentinel 2  |-----+-- // ----| Sentinel 3 |----- Client B
| Redis 2 (S) |                | Redis 3 (M)|
+-------------+                +------------+
```

在这个系统中，最初的状态是Redis 3为主，Redis 1和Redis 2为副本。发生分区隔离旧主服务器。Sentinel 1 和 2 启动了故障转移，将 Sentinel 1 提升为新的主服务器。

Sentinel 属性保证 Sentinel 1 和 2 现在具有 master 的新配置。但是 Sentinel 3 仍然具有旧配置，因为它位于不同的分区中。

我们知道 Sentinel 3 会在网络分区恢复时更新其配置，但是如果有客户端与旧主机分区，在分区期间会发生什么？

客户端仍然可以写入旧主机 Redis 3。当分区重新加入时，Redis 3 将变成 Redis 1 的副本，分区期间写入的所有数据都将丢失。

根据您的配置，您可能希望或不希望这种情况发生：

- 如果您使用 Redis 作为缓存，那么客户端 B 仍然能够写入旧的 master 可能会很方便，即使它的数据会丢失。
- 如果您使用Redis作为存储，这并不好，您需要配置系统以部分防止此问题。

由于 Redis 是异步复制的，因此在这种情况下无法完全防止数据丢失，但是您可以使用以下 Redis 配置选项来限制 Redis 3 和 Redis 1 之间的差异：

```
min-replicas-to-write 1
min-replicas-max-lag 10
```

使用上述配置（`redis.conf`更多信息请参见Redis发行版中的自我注释示例），Redis实例在充当master时，如果无法写入至少1个副本，则将停止接受写入。由于复制是异步的，*因此无法写入*实际上意味着副本已断开连接，或者没有向我们发送超过指定`max-lag`秒数的异步确认。

使用此配置，上述示例中的 Redis 3 将在 10 秒后变得不可用。当分区恢复时，Sentinel 3 配置将收敛到新配置，并且客户端 B 将能够获取有效配置并继续。

总的来说，Redis + Sentinel 整体是一个**最终一致的系统**，其中合并功能是**last failover wins**，并且丢弃来自旧 master 的数据以复制当前 master 的数据，因此始终存在丢失已确认写入的窗口. 这是由于Redis异步复制和系统“虚拟”合并功能的丢弃性质。请注意，这不是 Sentinel 本身的限制，如果您使用高度一致的复制状态机编排故障转移，则相同的属性仍将适用。只有两种方法可以避免丢失已确认的写入：

1. 使用同步复制（以及适当的共识算法来运行复制状态机）。
2. 使用最终一致的系统，可以合并同一对象的不同版本。

Redis 目前无法使用上述任何系统，并且目前处于开发目标之外。然而，有一些代理在 Redis 存储（例如 SoundCloud [Roshi](https://github.com/soundcloud/roshi)或 Netflix [Dynomite ）](https://github.com/Netflix/dynomite)之上实现了解决方案“2” 。



## 哨兵持久状态

哨兵状态保存在哨兵配置文件中。例如，每次接收或创建新配置（领导哨兵）时，对于主控，该配置与配置纪元一起保存在磁盘上。这意味着停止和重新启动 Sentinel 进程是安全的。



## 倾斜模式

Redis Sentinel 严重依赖于计算机时间：例如，为了了解实例是否可用，它会记住最近成功回复 PING 命令的时间，并将其与当前时间进行比较以了解它的年龄。

但是，如果计算机时间发生意外变化，或者计算机非常忙碌，或者进程因某种原因被阻塞，Sentinel 可能会开始以意外方式运行。

TILT 模式是一种特殊的“保护”模式，当检测到会降低系统可靠性的异常情况时，哨兵可以进入该模式。Sentinel 计时器中断通常每秒调用 10 次，因此我们预计两次调用计时器中断之间将经过或多或少 100 毫秒。

Sentinel 所做的是注册上一次调用定时器中断的时间，并将其与当前调用进行比较：如果时间差为负或意外大（2 秒或更多），则进入 TILT 模式（或者如果已经是进入退出 TILT 模式推迟）。

在 TILT 模式下，Sentinel 将继续监视所有内容，但是：

- 它根本停止表演。
- `SENTINEL is-master-down-by-addr`由于不再信任检测故障的能力，它开始对请求做出否定答复。

如果 30 秒内一切正常，则退出 TILT 模式。

在 Sentinel TILT 模式下，如果我们发送 INFO 命令，我们可以得到以下响应：

```
$ redis-cli -p 26379
127.0.0.1:26379> info
(Other information from Sentinel server skipped.)

# Sentinel
sentinel_masters:1
sentinel_tilt:0
sentinel_tilt_since_seconds:-1
sentinel_running_scripts:0
sentinel_scripts_queue_length:0
sentinel_simulate_failure_flags:0
master0:name=mymaster,status=ok,address=127.0.0.1:6379,slaves=0,sentinels=1
```

“哨兵*倾斜*起因_秒”字段表示哨兵已经处于倾斜模式的秒数。如果不处于 TILT 模式，则该值将为 -1。

请注意，可以使用许多内核提供的单调时钟 API 以某种方式替换 TILT 模式。然而，目前还不清楚这是否是一个好的解决方案，因为当前系统避免了进程只是暂停或调度程序长时间未执行的问题。

**关于本手册页中使用的 slave 一词的说明**：从 Redis 5 开始，如果不是为了向后兼容，Redis 项目不再使用 slave 一词。不幸的是，在这个命令中，slave 这个词是协议的一部分，所以只有当这个 API 自然被弃用时，我们才能删除此类事件。

本网站是 [开源软件](https://github.com/redis/redis-io) ，由[Redis Ltd](https://redis.com/)赞助 [。](https://redis.com/) 查看所有[版权](https://redis.io/topics/sponsors)。