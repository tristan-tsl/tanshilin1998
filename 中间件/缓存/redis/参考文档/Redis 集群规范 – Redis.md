# Redis 集群规范

欢迎使用**Redis 集群规范**。在这里，您将找到有关 Redis 集群的算法和设计原理的信息。本文档是一项正在进行的工作，因为它与 Redis 的实际实现不断同步。



# 设计的主要特性和原理



## Redis 集群目标

Redis Cluster 是 Redis 的分布式实现，具有以下目标，按设计中的重要性排序：

- 高达 1000 个节点的高性能和线性可扩展性。没有代理，使用异步复制，并且不对值执行合并操作。
- 可接受的写入安全程度：系统尝试（以最大努力的方式）保留来自与大多数主节点连接的客户端的所有写入。通常有一些小窗口，确认的写入可能会丢失。当客户端位于少数分区时，丢失已确认写入的 Windows 会更大。
- 可用性：Redis 集群能够在大多数主节点可访问的分区中存活下来，并且对于每个不再可访问的主节点，至少有一个可访问的副本。此外，使用*副本迁移*，不再被任何副本复制的主节点将从被多个副本覆盖的主节点接收一个。

本文档中描述的内容在 Redis 3.0 或更高版本中实现。



## 实现的子集

Redis Cluster 实现了非分布式版本 Redis 中可用的所有单键命令。执行复杂的多键操作的命令，如集合类型联合或交集，只要键都散列到同一个槽，就可以实现。

Redis Cluster 实现了一个称为**哈希标签**的概念，可以使用它来强制某些键存储在同一个哈希槽中。但是在手动重新分片过程中，多键操作可能会在一段时间内变得不可用，而单键操作始终可用。

Redis Cluster 不支持像 Redis 的独立版本那样支持多个数据库。只有数据库 0 并且不允许使用[SELECT](https://redis.io/commands/select)命令。



## Redis 集群协议中的客户端和服务器角色

在 Redis 集群中，节点负责保存数据，并获取集群的状态，包括将键映射到正确的节点。集群节点还能够自动发现其他节点，检测非工作节点，并在需要时将副本节点提升为 master，以便在发生故障时继续运行。

为了执行它们的任务，所有集群节点都使用 TCP 总线和二进制协议连接，称为**Redis 集群总线**. 每个节点都使用集群总线连接到集群中的每个其他节点。节点使用 gossip 协议来传播有关集群的信息以发现新节点、发送 ping 数据包以确保所有其他节点正常工作，以及发送发送特定条件所需的集群消息。集群总线还用于在集群中传播 Pub/Sub 消息，并在用户请求时协调手动故障转移（手动故障转移不是由 Redis 集群故障检测器启动，而是由系统管理员直接启动的故障转移）。

由于集群节点无法代理请求，客户端可能会使用重定向错误`-MOVED`和`-ASK`. 客户端理论上可以自由地向集群中的所有节点发送请求，如果需要可以重定向，因此客户端不需要保存集群的状态。然而，能够缓存键和节点之间的映射的客户端可以以合理的方式提高性能。



## 写安全

Redis Cluster 使用节点间异步复制，**最后一次故障转移赢得**隐式合并功能。这意味着最后选出的主数据集最终会替换所有其他副本。在分区期间总是有可能丢失写入的时间窗口。然而，在客户端连接到大多数主节点和客户端连接到少数主节点的情况下，这些窗口是非常不同的。

与在少数方执行的写入相比，Redis 集群更努力地保留连接到大多数主节点的客户端执行的写入。以下是导致故障期间多数分区中收到的已确认写入丢失的场景示例：

1. 写入可能会到达主节点，但是虽然主节点可能能够回复客户端，但写入可能无法通过主节点和副本节点之间使用的异步复制传播到副本。如果 master 在没有写入到达副本的情况下死亡，并且 master 在足够长的时间内无法访问以提升其副本之一，则写入将永远丢失。在主节点突然完全故障的情况下，这通常很难观察到，因为主节点尝试在大约同一时间回复客户端（确认写入）和副本（传播写入）。然而，这是一种现实世界的故障模式。
2. 另一种理论上可能的写入丢失的故障模式如下：

- 由于分区，无法访问主服务器。
- 它被它的一个副本故障转移。
- 一段时间后，它可能会再次访问。
- 具有过期路由表的客户端可能会在旧主节点被集群转换为（新主节点的）副本之前写入旧主节点。

第二种故障模式不太可能发生，因为主节点无法与大多数其他主节点通信足够长的时间进行故障转移将不再接受写入，并且当分区固定时仍然拒绝写入一小段时间允许其他节点通知配置更改。这种故障模式还要求客户端的路由表尚未更新。

针对分区少数方的写入有一个更大的窗口，可以在其中丢失。例如，Redis 集群在少数主节点和至少一个或多个客户端的分区上丢失了大量写入，因为如果主节点在多数方。

具体来说，对于要进行故障转移的主站，它必须至少在 10 年内无法被大多数主站访问`NODE_TIMEOUT`，因此如果在此之前分区已修复，则不会丢失任何写入。当分区持续时间超过 时`NODE_TIMEOUT`，在少数方执行的所有写入操作可能会丢失。然而，一旦`NODE_TIMEOUT`时间过去，Redis 集群的少数方将开始拒绝写入而不与多数方联系，因此存在一个最大窗口，之后少数方将不再可用。因此，在那之后，不会接受或丢失任何写入。



## 可用性

Redis Cluster 在分区的少数方不可用。在分区的大多数侧，假设至少有大多数主节点和每个无法访问的主节点的副本，集群在`NODE_TIMEOUT`一段时间后再次可用，再加上副本获得选举和故障转移其主节点（故障转移）所需的更多秒通常在 1 或 2 秒内执行）。

这意味着 Redis Cluster 旨在在集群中的几个节点发生故障时幸免于难，但对于需要在大型网络分裂情况下提供可用性的应用程序，它不是一个合适的解决方案。

在由 N 个主节点组成的集群的示例中，每个节点都有一个副本，只要单个节点被分区，集群的大多数侧将保持可用，并且将保持可用的概率为`1-(1/(N*2-1))`两个节点时分区（在第一个节点失败后，我们`N*2-1`总共剩下节点，唯一没有副本的主节点失败的概率是`1/(N*2-1))`.

例如，在具有 5 个节点和每个节点一个副本的集群中，有`1/(5*2-1) = 11.11%`可能在将两个节点与多数节点分开后，该集群将不再可用。

由于 Redis 集群功能称为**副本迁移**，通过将副本迁移到孤立的主节点（主节点不再具有副本）这一事实，集群可用性在许多实际场景中得到了提高。因此，在每个成功的故障事件中，集群可能会重新配置副本布局，以便更好地抵抗下一次故障。



## 表现

在 Redis 集群中，节点不会将命令代理到负责给定密钥的正确节点，而是将客户端重定向到为密钥空间的给定部分提供服务的正确节点。

最终，客户端获得集群的最新表示以及哪个节点为哪个密钥子集提供服务，因此在正常操作期间，客户端直接联系正确的节点以发送给定的命令。

由于使用异步复制，节点不会等待其他节点对写入的确认（如果没有使用[WAIT](https://redis.io/commands/wait)命令明确请求）。

此外，由于多键命令仅限于*近*键，因此除非重新分片，否则数据永远不会在节点之间移动。

正常操作的处理与单个 Redis 实例的情况完全相同。这意味着在具有 N 个主节点的 Redis 集群中，随着设计的线性扩展，您可以获得与单个 Redis 实例乘以 N 相同的性能。同时，查询通常在单次往返中执行，因为客户端通常保持与节点的持久连接，因此延迟数字也与单个独立的 Redis 节点情况相同。

非常高的性能和可扩展性，同时保留弱但合理的数据安全性和可用性形式是 Redis 集群的主要目标。



## 为什么要避免合并操作

Redis 集群设计避免了多个节点中相同键值对的版本冲突，因为在 Redis 数据模型的情况下，这并不总是可取的。Redis 中的值通常非常大；通常会看到包含数百万个元素的列表或排序集。数据类型在语义上也很复杂。传输和合并这些类型的值可能是一个主要瓶颈和/或可能需要应用程序端逻辑的非平凡参与、额外的内存来存储元数据等。

这里没有严格的技术限制。CRDT 或同步复制状态机可以模拟类似于 Redis 的复杂数据类型。但是，此类系统的实际运行时行为与 Redis Cluster 不同。Redis 集群旨在涵盖非集群 Redis 版本的确切用例。



# Redis Cluster 主要组件概览



## 密钥分发模型

密钥空间被分成 16384 个槽，有效地设置了 16384 个主节点的集群大小上限（但是建议的最大节点大小约为 1000 个节点）。

集群中的每个主节点处理 16384 个哈希槽的一个子集。当没有正在进行的集群重新配置（即哈希槽从一个节点移动到另一个节点时），集群是**稳定的**。当集群稳定时，单个节点将服务一个哈希槽（但是，服务节点可以有一个或多个副本，在网络分裂或故障的情况下将替换它，并且可以用于扩展读取过时数据的读取操作是可以接受的）。

用于将键映射到散列槽的基本算法如下（阅读下一段以了解该规则的散列标签例外）：

```
HASH_SLOT = CRC16(key) mod 16384
```

CRC16 规定如下：

- 名称：XMODEM（也称为ZMODEM或CRC-16/ACORN）
- 宽度：16位
- Poly：1021（实际上是 x 16 + x 12 + x 5 + 1）
- 初始化：0000
- 反映输入字节：假
- 反射输出 CRC：假
- 输出 CRC 的异或常数：0000
- “123456789”的输出：31C3

使用了 16 个 CRC16 输出位中的 14 个（这就是上面公式中存在模 16384 运算的原因）。

在我们的测试中，CRC16 在将不同类型的密钥均匀分布在 16384 个插槽方面表现得非常好。

**注意**：本文档的附录 A 中提供了所用 CRC16 算法的参考实现。



## 键哈希标签

为实现**哈希标签**而使用的哈希槽的计算有一个例外。哈希标签是一种确保在同一个哈希槽中分配多个键的方法。这是为了在 Redis 集群中实现多键操作。

为了实现散列标签，键的散列槽在某些条件下以稍微不同的方式计算。如果密钥包含一个“{...}”图案仅之间子 `{`和`}`，以获得散列时隙被散列。但是，由于可能多次出现`{`或者`}`算法由以下规则很好地指定：

- 如果键包含一个`{`字符。
- 如果`}`右边有一个字符`{`
- 并且如果在第一次出现`{`和第一次出现之间有一个或多个字符`}`。

然后，而不是散列密钥，只散列第一次出现`{`和接下来的第一次出现之间的`}`内容。

例子：

- 这两个键`{user1000}.following`和`{user1000}.followers`由于只有子意愿散列到相同的散列时隙`user1000`将为了计算散列时隙被散列。
- 对于键`foo{}{bar}`，整个键将像往常一样散列，因为第一次出现的`{`后面跟`}`在右边，中间没有字符。
- 对于键`foo{{bar}}zap`，子字符串`{bar`将被散列，因为它是第一次出现`{`和第一次出现`}`在其右侧之间的子字符串。
- 对于密钥`foo{bar}{zap}`的子串`bar`将被散列，由于算法停止在所述第一有效或无效（无字节内）匹配`{`和`}`。
- 该算法得出的结论是，如果密钥以 开头`{}`，则保证它作为一个整体进行散列。这在使用二进制数据作为键名时很有用。

添加hash标签异常，以下是该`HASH_SLOT`函数在Ruby和C语言中的实现。

Ruby 示例代码：

```
def HASH_SLOT(key)
    s = key.index "{"
    if s
        e = key.index "}",s+1
        if e && e != s+1
            key = key[s+1..e-1]
        end
    end
    crc16(key) % 16384
end
```

C 示例代码：

```
unsigned int HASH_SLOT(char *key, int keylen) {
    int s, e; /* start-end indexes of { and } */

    /* Search the first occurrence of '{'. */
    for (s = 0; s < keylen; s++)
        if (key[s] == '{') break;

    /* No '{' ? Hash the whole key. This is the base case. */
    if (s == keylen) return crc16(key,keylen) & 16383;

    /* '{' found? Check if we have the corresponding '}'. */
    for (e = s+1; e < keylen; e++)
        if (key[e] == '}') break;

    /* No '}' or nothing between {} ? Hash the whole key. */
    if (e == keylen || e == s+1) return crc16(key,keylen) & 16383;

    /* If we are here there is both a { and a } on its right. Hash
     * what is in the middle between { and }. */
    return crc16(key+s+1,e-s-1) & 16383;
}
```



## 集群节点属性

每个节点在集群中都有一个唯一的名称。节点名称是 160 位随机数的十六进制表示，在节点第一次启动时获得（通常使用 /dev/urandom）。节点将其 ID 保存在节点配置文件中，并且将永远使用相同的 ID，或者至少只要系统管理员没有删除节点配置文件，或者通过[CLUSTER RESET](https://redis.io/commands/cluster-reset)命令请求*硬重置*。

节点 ID 用于标识整个集群中的每个节点。给定节点可以更改其 IP 地址，而无需更改节点 ID。集群还能够检测 IP/端口的变化并使用运行在集群总线上的 gossip 协议重新配置。

节点 ID 不是与每个节点相关联的唯一信息，而是唯一始终全局一致的信息。每个节点还具有以下相关联的信息集。一些信息是关于这个特定节点的集群配置细节的，并且最终在整个集群中是一致的。其他一些信息，例如上次 ping 节点的时间，则是每个节点的本地信息。

每个节点维护以下关于它在集群中知道的其他节点的信息：节点 ID、节点的 IP 和端口、一组标志、如果它被标记为`replica`，则该节点的主节点是什么，最后一次节点被 ping 和最后一次收到 pong 时，节点的当前 *配置时期*（在本规范后面解释），链接状态和最后提供的散列槽集。

[CLUSTER NODES](https://redis.io/commands/cluster-nodes)文档中描述[了所有节点字段的](https://redis.io/commands/cluster-nodes)详细[说明](https://redis.io/commands/cluster-nodes)。

的[群集节点](https://redis.io/commands/cluster-nodes)命令可在簇中被发送到任何节点，并提供该集群的状态，并根据本地视图所查询的节点具有群集的每个节点的信息。

以下是发送到由三个节点组成的小型集群中的主节点的[CLUSTER NODES](https://redis.io/commands/cluster-nodes)命令的示例输出。

```
$ redis-cli cluster nodes
d1861060fe6a534d42d8a19aeb36600e18785e04 127.0.0.1:6379 myself - 0 1318428930 1 connected 0-1364
3886e65cc906bfd9b1f7e7bde468726a052d1dae 127.0.0.1:6380 master - 1318428930 1318428931 2 connected 1365-2729
d289c575dcbc4bdd2931585fd4339089e461a27d 127.0.0.1:6381 master - 1318428931 1318428931 3 connected 2730-4095
```

在上面的列表中，不同的字段按顺序排列：节点 id、地址：端口、标志、上次发送的 ping、上次接收的 pong、配置时期、链接状态、插槽。一旦我们谈到 Redis Cluster 的特定部分，就会涉及到有关上述字段的详细信息。



## 集群总线

每个 Redis 集群节点都有一个额外的 TCP 端口，用于接收来自其他 Redis 集群节点的传入连接。此端口与用于接收来自客户端的传入连接的普通 TCP 端口有固定的偏移量。要获取Redis Cluster端口，需要在普通命令端口加10000。例如，如果 Redis 节点正在侦听端口 6379 上的客户端连接，则集群总线端口 16379 也将打开。

节点到节点的通信只使用集群总线和集群总线协议：一种由不同类型和大小的帧组成的二进制协议。集群总线二进制协议没有公开记录，因为它不适合外部软件设备使用该协议与 Redis 集群节点通信。但是，您可以通过阅读Redis 集群源代码中的`cluster.h`和`cluster.c`文件来获取有关集群总线协议的更多详细信息 。



## 集群拓扑

Redis 集群是一个全网状网络，其中每个节点都使用 TCP 连接与其他每个节点相连。

在 N 个节点的集群中，每个节点都有 N-1 个传出 TCP 连接和 N-1 个传入连接。

这些 TCP 连接始终保持活动状态，不会按需创建。当一个节点期望 pong 回复以响应集群总线中的 ping 时，在等待足够长的时间以将该节点标记为不可达之前，它将尝试通过从头开始重新连接来刷新与该节点的连接。

而Redis Cluster节点形成全网状，**节点使用gossip协议和配置更新机制，以避免在正常情况下节点之间交换过多的消息**，因此交换的消息数量不是指数级的。



## 节点握手

节点总是接受集群总线端口上的连接，甚至在收到时回复 ping，即使 ping 节点不受信任。但是，如果发送节点不被视为集群的一部分，则接收节点将丢弃所有其他数据包。

一个节点只会通过两种方式接受另一个节点作为集群的一部分：

- 如果一个节点向自己展示一条`MEET`消息。meet 消息与[PING](https://redis.io/commands/ping)消息完全一样，但强制接收者接受该节点作为集群的一部分。**仅当**系统管理员通过以下命令请求时，`MEET`节点**才会**向其他节点发送消息：

  CLUSTER MEET ip 端口

- 如果一个已经被信任的节点会谈论这个其他节点，那么一个节点也会将另一个节点注册为集群的一部分。所以如果 A 知道 B，B 知道 C，最终 B 会向 A 发送关于 C 的八卦消息。 当这种情况发生时，A 会将 C 注册为网络的一部分，并会尝试与 C 连接。

这意味着只要我们将任何连接图中的节点连接起来，它们最终都会自动形成一个全连接图。这意味着集群能够自动发现其他节点，但前提是存在系统管理员强制的信任关系。

这种机制使集群更加健壮，但可以防止不同的 Redis 集群在 IP 地址更改或其他网络相关事件后意外混合。



# 重定向和重新分片



## 移动重定向

Redis 客户端可以自由地向集群中的每个节点发送查询，包括副本节点。节点会分析查询，如果可以接受（即查询中只提到了一个key，或者提到的多个key都在同一个hash slot），它会查找哪个节点负责hash slot钥匙或钥匙所属的地方。

如果散列槽由节点提供服务，则查询将被简单处理，否则节点将检查其内部散列槽到节点映射，并以 MOVED 错误回复客户端，如下例所示：

```
GET x
-MOVED 3999 127.0.0.1:6381
```

该错误包括密钥 (3999) 的哈希槽和可以为查询提供服务的实例的 ip:port。客户端需要重新向指定节点的 IP 地址和端口发出查询。请注意，即使客户端在重新发出查询之前等待了很长时间，并且在此期间集群配置发生了变化，如果哈希槽 3999 现在由另一个节点提供服务，则目标节点将再次回复 MOVED 错误。如果联系的节点没有更新的信息，也会发生同样的情况。

因此，虽然从集群节点的角度来看，由 ID 标识，但我们尝试简化与客户端的接口，仅公开哈希槽和由 IP:port 对标识的 Redis 节点之间的映射。

客户端不需要，但应该尝试记住哈希槽 3999 由 127.0.0.1:6381 提供服务。这样，一旦需要发出新命令，它就可以计算目标密钥的哈希槽，并有更大的机会选择正确的节点。

另一种方法是在收到 MOVED 重定向时使用[CLUSTER NODES](https://redis.io/commands/cluster-nodes)或[CLUSTER SLOTS](https://redis.io/commands/cluster-slots)命令刷新整个客户端集群布局。当遇到重定向时，可能会重新配置多个插槽而不是一个，因此尽快更新客户端配置通常是最佳策略。

请注意，当集群稳定时（配置没有持续变化），最终所有客户端都将获得哈希槽 -> 节点的映射，从而使集群高效，客户端直接寻址正确的节点，无需重定向、代理或其他单一故障点实体。

客户端**还必须能够处理**本文档后面描述的**-ASK 重定向**，否则它不是完整的 Redis 集群客户端。



## 集群实时重新配置

Redis Cluster 支持在集群运行时添加和删除节点的能力。添加或删除节点被抽象为相同的操作：将哈希槽从一个节点移动到另一个节点。这意味着可以使用相同的基本机制来重新平衡集群、添加或删除节点等。

- 为了向集群添加新节点，将向集群添加一个空节点，并将一些哈希槽集从现有节点移动到新节点。
- 为了从集群中删除一个节点，分配给该节点的哈希槽被移动到其他现有节点。
- 为了重新平衡集群，在节点之间移动一组给定的哈希槽。

实现的核心是移动哈希槽的能力。从实际的角度来看，哈希槽只是一组键，因此Redis Cluster 在*重新分片*期间真正做的是将键从一个实例移动到另一个实例。移动一个散列槽意味着将所有碰巧散列的键移动到这个散列槽中。

要了解其工作原理，我们需要展示`CLUSTER`用于操作 Redis 集群节点中的插槽转换表的子命令。

以下子命令可用（其中在这种情况下没有用）：

- [CLUSTER ADDSLOTS](https://redis.io/commands/cluster-addslots) slot1 [ [slot2](https://redis.io/commands/cluster-addslots) ] ... [slotN]
- [CLUSTER DELSLOTS](https://redis.io/commands/cluster-delslots) slot1 [ [slot2](https://redis.io/commands/cluster-delslots) ] ... [slotN]
- [CLUSTER SETSLOT](https://redis.io/commands/cluster-setslot)插槽 NODE 节点
- [CLUSTER SETSLOT](https://redis.io/commands/cluster-setslot)插槽[迁移](https://redis.io/commands/cluster-setslot)节点
- [CLUSTER SETSLOT](https://redis.io/commands/cluster-setslot) slot IMPORTING 节点

前两个命令`ADDSLOTS`和`DELSLOTS`仅用于为 Redis 节点分配（或删除）槽。分配槽意味着告诉给定的主节点它将负责为指定的哈希槽存储和提供内容。

分配哈希槽后，它们将使用 gossip 协议在集群中传播，如后面 *配置传播*部分所述。

该`ADDSLOTS`命令通常用于从头创建新集群时，为每个主节点分配所有 16384 个可用哈希槽的子集。

将`DELSLOTS`主要用于群集配置的人工修改或用于调试任务：在实践中很少使用。

所述`SETSLOT`子命令用于如果到一个时隙分配给特定的节点ID`SETSLOT <slot> NODE`被使用的形式。否则，插槽可以设置为两种特殊状态`MIGRATING`和`IMPORTING`。这两种特殊状态用于将哈希槽从一个节点迁移到另一个节点。

- 当一个槽被设置为 MIGRATING 时，节点将接受关于这个哈希槽的所有查询，但只有当有问题的键存在时，否则查询将使用`-ASK`重定向转发到作为迁移目标的节点。
- 当一个槽被设置为 IMPORTING 时，节点将接受关于这个哈希槽的所有查询，但[前提](https://redis.io/commands/asking)是请求之前有一个[ASKING](https://redis.io/commands/asking)命令。如果客户端未给出[ASKING](https://redis.io/commands/asking)命令，则查询将通过`-MOVED`重定向错误重定向到真正的哈希槽所有者，这通常会发生。

让我们通过一个哈希槽迁移的例子来更清楚地说明这一点。假设我们有两个 Redis 主节点，分别称为 A 和 B。我们想将哈希槽 8 从 A 移动到 B，因此我们发出如下命令：

- 我们发送 B: CLUSTER SETSLOT 8 IMPORTING A
- 我们发送 A：CLUSTER SETSLOT 8 MIGRATING B

每次使用属于哈希槽 8 的键查询客户端时，所有其他节点将继续将客户端指向节点“A”，因此会发生以下情况：

- 所有关于现有键的查询都由“A”处理。
- 所有关于 A 中不存在的键的查询都由“B”处理，因为“A”会将客户端重定向到“B”。

这样我们就不再在“A”中创建新键了。同时，`redis-cli`在重新分片和 Redis 集群配置期间使用会将哈希槽 8 中的现有键从 A 迁移到 B。这是使用以下命令执行的：

```
CLUSTER GETKEYSINSLOT slot count
```

上述命令将返回`count`指定哈希槽中的键。对于返回的密钥，`redis-cli`向节点“A”发送一个[MIGRATE](https://redis.io/commands/migrate)命令，该命令将以原子方式将指定的密钥从 A 迁移到 B（两个实例都锁定迁移密钥所需的时间（通常非常短的时间），因此没有竞争状况）。这是[MIGRATE 的](https://redis.io/commands/migrate)工作原理：

```
MIGRATE target_host target_port "" target_database id timeout KEYS key1 key2 ...
```

[MIGRATE](https://redis.io/commands/migrate)将连接到目标实例，发送密钥的序列化版本，一旦收到 OK 代码，将删除其自己数据集中的旧密钥。从外部客户端的角度来看，密钥在任何给定时间都存在于 A 或 B 中。

在Redis Cluster中不需要指定0以外的数据库，但是 [MIGRATE](https://redis.io/commands/migrate)是一个通用命令，可以用于其他不涉及Redis Cluster的任务。 [MIGRATE](https://redis.io/commands/migrate)优化为即使在移动复杂的键（例如长列表）时也尽可能快，但在 Redis Cluster 中，如果使用数据库的应用程序存在延迟限制，则在存在大键的情况下重新配置集群不被认为是明智的过程。

当迁移过程最终完成时，将`SETSLOT <slot> NODE <node-id>`命令发送到迁移中涉及的两个节点，以便将时隙再次设置为其正常状态。通常将相同的命令发送到所有其他节点，以避免等待新配置在集群中自然传播。



## ASK 重定向

在上一节中，我们简要讨论了 ASK 重定向。为什么我们不能简单地使用 MOVED 重定向？因为 MOVED 意味着我们认为哈希槽永久由不同的节点提供服务，并且应该针对指定节点尝试下一个查询，而 ASK 意味着只向指定节点发送下一个查询。

这是必需的，因为关于哈希槽 8 的下一个查询可能是关于仍在 A 中的键，所以我们总是希望客户端在需要时先尝试 A，然后再尝试 B。由于这种情况仅发生在 16384 个可用哈希槽中的一个哈希槽中，因此对集群的性能影响是可以接受的。

我们需要强制客户端行为，因此为了确保客户端只会在尝试 A 之后尝试节点 B，如果客户端在发送查询之前发送 ASKING 命令，节点 B 将只接受设置为 IMPORTING 的插槽的查询。

基本上，ASKING 命令在客户端上设置一个一次性标志，强制节点为有关 IMPORTING 插槽的查询提供服务。

从客户端的角度来看，ASK 重定向的完整语义如下：

- 如果收到 ASK 重定向，则只发送被重定向到指定节点的查询，但继续向旧节点发送后续查询。
- 使用 ASKING 命令启动重定向查询。
- 不要更新本地客户端表以将哈希槽 8 映射到 B。

一旦哈希槽 8 迁移完成，A 将发送一条 MOVED 消息，客户端可以将哈希槽 8 永久映射到新的 IP 和端口对。请注意，如果有问题的客户端更早地执行映射，这不是问题，因为它不会在发出查询之前发送 ASKING 命令，因此 B 将使用 MOVED 重定向错误将客户端重定向到 A。

在[CLUSTER SETSLOT](https://redis.io/commands/cluster-setslot) 命令文档中以类似的术语解释了插槽迁移，但使用了不同的措辞（为了文档中的冗余）。



## 客户端首次连接和重定向处理

虽然可能有一个 Redis 集群客户端实现，它不记得内存中的插槽配置（插槽编号和为其提供服务的节点地址之间的映射），并且只能通过联系等待重定向的随机节点来工作，但这样的客户端将是非常低效。

Redis 集群客户端应该尝试足够聪明以记住插槽配置。但是，此配置*不需要*是最新的。由于联系错误的节点只会导致重定向，因此应该触发客户端视图的更新。

在两种不同的情况下，客户端通常需要获取完整的插槽列表和映射的节点地址：

- 在启动时填充初始插槽配置。
- 当`MOVED`收到重定向时。

请注意，客户端可以`MOVED`通过仅更新其表中移动的插槽来处理重定向，但这通常效率不高，因为通常会同时修改多个插槽的配置（例如，如果将副本提升为主服务器，则服务的所有插槽由旧主人将被重新映射）。`MOVED`通过从头开始获取节点到节点的完整映射，对重定向做出反应要简单得多。

为了检索插槽配置，Redis 集群提供了一种替代[CLUSTER NODES](https://redis.io/commands/cluster-nodes)命令的替代方法，该命令不需要解析，并且只向客户端提供严格需要的信息。

新命令称为[CLUSTER SLOTS](https://redis.io/commands/cluster-slots)并提供一组槽范围，以及为指定范围提供服务的关联主节点和副本节点。

以下是[CLUSTER SLOTS](https://redis.io/commands/cluster-slots)的输出示例：

```
127.0.0.1:7000> cluster slots
1) 1) (integer) 5461
   2) (integer) 10922
   3) 1) "127.0.0.1"
      2) (integer) 7001
   4) 1) "127.0.0.1"
      2) (integer) 7004
2) 1) (integer) 0
   2) (integer) 5460
   3) 1) "127.0.0.1"
      2) (integer) 7000
   4) 1) "127.0.0.1"
      2) (integer) 7003
3) 1) (integer) 10923
   2) (integer) 16383
   3) 1) "127.0.0.1"
      2) (integer) 7002
   4) 1) "127.0.0.1"
      2) (integer) 7005
```

返回数组的每个元素的前两个子元素是范围的开始-结束槽。附加元素代表地址-端口对。第一个地址-端口对是服务于该时隙的主设备，而附加的地址-端口对是服务于同一时隙且未处于错误状态（即未设置 FAIL 标志）的所有副本。

例如，输出的第一个元素表示从 5461 到 10922（包括开始和结束）的插槽由 127.0.0.1:7001 提供服务，并且可以缩放与 127.0.0.1:7004 处的副本联系的只读负载。

如果集群配置错误，则[CLUSTER SLOTS](https://redis.io/commands/cluster-slots)不能保证返回覆盖完整 16384 个插槽的范围，因此客户端应初始化插槽配置映射，用 NULL 对象填充目标节点，如果用户尝试执行有关键的命令，则报告错误属于未分配的插槽。

在发现插槽未分配时向调用方返回错误之前，客户端应尝试再次获取插槽配置以检查集群现在是否已正确配置。



## 多键操作

使用哈希标签，客户端可以自由使用多键操作。例如以下操作是有效的：

```
MSET {user:1000}.name Angela {user:1000}.surname White
```

当密钥所属的哈希槽的重新分片正在进行时，多密钥操作可能变得不可用。

更具体地说，即使在重新分片期间，针对所有存在且仍然散列到同一插槽（源节点或目标节点）的键的多键操作仍然可用。

对不存在或在重新分片期间在源节点和目标节点之间拆分的键的操作将产生`-TRYAGAIN`错误。客户端可以在一段时间后尝试操作，或者返回错误。

一旦指定散列槽的迁移终止，该散列槽的所有多键操作都将再次可用。



## 使用副本节点扩展读取

通常副本节点会将客户端重定向到给定命令中涉及的哈希槽的权威主节点，但是客户端可以使用副本来使用[READONLY](https://redis.io/commands/readonly)命令扩展读取。

[READONLY](https://redis.io/commands/readonly)告诉 Redis Cluster 副本节点，客户端可以读取可能过时的数据，并且对运行写入查询不感兴趣。

当连接处于只读模式时，仅当操作涉及副本的主节点未提供的密钥时，集群才会向客户端发送重定向。这可能是因为：

1. 客户端发送了一个关于这个副本的主节点从未服务过的哈希槽的命令。
2. 集群被重新配置（例如重新分片）并且副本不再能够为给定的哈希槽提供命令。

发生这种情况时，客户端应更新其哈希槽映射，如前几节所述。

可以使用[READWRITE](https://redis.io/commands/readwrite)命令清除连接的只读状态。



# 容错



## 心跳和八卦消息

Redis Cluster 节点不断地交换乒乓包。这两种报文结构相同，都携带重要的配置信息。唯一的实际区别是消息类型字段。我们将 ping 和 pong 数据包的总和称为*心跳数据包*。

通常节点发送 ping 数据包会触发接收者回复 pong 数据包。然而，这不一定是真的。节点可以只发送 pong 数据包来向其他节点发送有关其配置的信息，而不会触发回复。例如，为了尽快广播新配置，这很有用。

通常一个节点每秒会 ping 几个随机节点，这样每个节点发送的 ping 数据包（和接收的 pong 数据包）的总数是一个恒定的数量，而不管集群中的节点数量如何。

然而，每个节点都确保 ping 超过一半`NODE_TIMEOUT`时间没有发送 ping 或接收到 pong 的所有其他节点。在`NODE_TIMEOUT`过去之前，节点还尝试重新连接与另一个节点的 TCP 链接，以确保不会因为当前 TCP 连接存在问题而认为节点不可达。

如果`NODE_TIMEOUT`设置为一个小数字并且节点数 (N) 非常大，则全局交换的消息数量可能会很大，因为每个节点都会尝试 ping 每隔一半没有新信息的其他节点`NODE_TIMEOUT`时间。

例如，在节点超时设置为 60 秒的 100 个节点集群中，每个节点将尝试每 30 秒发送 99 个 ping，每秒 ping 总数为 3.3。乘以 100 个节点，这就是整个集群中每秒 330 次 ping。

有一些方法可以减少消息数量，但是目前还没有报告 Redis Cluster 故障检测使用的带宽有问题，所以现在使用明显和直接的设计。请注意，即使在上面的示例中，每秒交换的 330 个数据包也平均分配给 100 个不同的节点，因此每个节点接收的流量是可以接受的。



## 心跳包内容

Ping 和 pong 数据包包含一个对所有类型的数据包（例如请求故障转移投票的数据包）通用的标头，以及一个特定于 Ping 和 Pong 数据包的特殊 Gossip 部分。

公共头有以下信息：

- 节点 ID，一个 160 位伪随机字符串，在第一次创建节点时分配，并在 Redis 集群节点的整个生命周期中保持不变。
- 发送节点的`currentEpoch`和`configEpoch`字段，用于挂载Redis Cluster使用的分布式算法（这将在下一节中详细解释）。如果节点是副本，`configEpoch`则是`configEpoch`其主节点的最后一个已知节点。
- 节点标志，指示节点是副本、主节点和其他单比特节点信息。
- 发送节点服务的哈希槽位图，或者如果节点是副本，则是其主节点服务的槽位图。
- 发送方 TCP 基端口（即 Redis 用于接受客户端命令的端口；在此基础上加 10000 即可获得集群总线端口）。
- 从发送者的角度来看集群的状态（down 或 ok）。
- 发送节点的主节点 ID，如果是副本。

Ping 和 pong 数据包还包含八卦部分。本部分向接收方提供了发送方节点对集群中其他节点的看法的视图。gossip 部分仅包含有关发送者已知的节点集中的一些随机节点的信息。八卦部分中提到的节点数量与集群大小成正比。

对于八卦部分中添加的每个节点，将报告以下字段：

- 节点标识。
- 节点的IP和端口。
- 节点标志。

Gossip 部分允许接收节点从发送方的角度获取有关其他节点状态的信息。这对于故障检测和发现集群中的其他节点都很有用。



## 故障检测

Redis Cluster 故障检测用于识别何时大多数节点不再可以访问主节点或副本节点，然后通过将副本提升为主节点来做出响应。当无法进行副本提升时，集群将处于错误状态以停止接收来自客户端的查询。

如前所述，每个节点都采用与其他已知节点相关联的标志列表。有两个用于故障检测的标志，称为`PFAIL`和`FAIL`。`PFAIL`表示*可能的失败*，并且是未确认的失败类型。`FAIL`意味着节点出现故障，并且这种情况在固定时间内得到了大多数主节点的确认。

**PFAIL 标志：**

当某个节点`PFAIL`在`NODE_TIMEOUT`一段时间内无法访问时，该节点会使用该标志来标记另一个节点。主节点和副本节点都可以将另一个节点标记为`PFAIL`，而不管其类型如何。

Redis 集群节点的不可访问性的概念是我们有一个**活动 ping**（我们发送的 ping，但我们尚未收到回复）等待的时间超过`NODE_TIMEOUT`。`NODE_TIMEOUT`与网络往返时间相比，此机制的工作必须很大。为了在正常操作期间增加可靠性，节点将在`NODE_TIMEOUT`没有回复 ping 的情况下尝试在一半时间过去后立即与集群中的其他节点重新连接。这种机制确保连接保持活动状态，因此断开的连接通常不会导致节点之间出现错误的故障报告。

**失败标志：**

`PFAIL`单独的标志只是每个节点关于其他节点的本地信息，但不足以触发副本提升。对于要被视为关闭的节点，需要将`PFAIL`条件升级为`FAIL`条件。

如本文档的节点心跳部分所述，每个节点都会向所有其他节点发送八卦消息，包括一些随机已知节点的状态。每个节点最终都会为每个其他节点接收一组节点标志。通过这种方式，每个节点都有一种机制来通知其他节点他们检测到的故障情况。

甲`PFAIL`条件升级为`FAIL`条件时，下面的一组条件满足：

- 某个节点，我们称之为 A，有另一个节点 B 标记为`PFAIL`。
- 从集群中大多数主节点的角度来看，节点 A 通过八卦部分收集了有关 B 状态的信息。
- 大多数主人及时发出信号`PFAIL`或`FAIL`条件`NODE_TIMEOUT * FAIL_REPORT_VALIDITY_MULT`。（在当前实现中，有效性因子设置为 2，所以这只是两倍的`NODE_TIMEOUT`时间）。

如果上述所有条件都为真，节点 A 将：

- 将节点标记为`FAIL`。
- 向所有可达节点发送`FAIL`消息（与`FAIL`心跳消息中的条件相反）。

该`FAIL`消息将强制每个接收节点标记处于`FAIL`状态的节点，无论它是否已经标记了处于`PFAIL`状态的节点。

请注意，*FAIL 标志主要是一种方式*。也就是说，一个节点可以从`PFAIL`到`FAIL`，但是一个`FAIL`标志只能在以下情况下被清除：

- 该节点已经可以访问并且是一个副本。在这种情况下，`FAIL`可以清除标志，因为副本不会进行故障转移。
- 该节点已经可以访问并且是一个不为任何时隙提供服务的主节点。在这种情况下，`FAIL`可以清除标志，因为没有插槽的主节点并没有真正参与集群，并且正在等待配置以加入集群。
- 该节点已经可以访问并且是一个主节点，但是很长一段时间（N 倍`NODE_TIMEOUT`）过去了，没有任何可检测的副本提升。在这种情况下，最好重新加入集群并继续。

需要注意的是，虽然`PFAIL`->`FAIL`转换使用了一种协议形式，但所使用的协议很弱：

1. 节点在一段时间内收集其他节点的意见，所以即使大多数主节点需要“同意”，实际上这只是我们在不同时间从不同节点收集的状态，我们不确定，也不要求，在某个特定时刻，大多数大师都同意了。然而，我们丢弃了旧的失败报告，因此大多数主节点在一个时间窗口内发出了失败信号。
2. 虽然检测到`FAIL`条件的每个节点都会使用该`FAIL`消息在集群中的其他节点上强制该条件，但无法确保该消息将到达所有节点。例如，一个节点可能会检测到这种`FAIL`情况，并且由于分区将无法到达任何其他节点。

然而，Redis 集群故障检测有一个活跃度要求：最终所有节点都应该就给定节点的状态达成一致。有两种情况可能源于裂脑情况。一些少数节点认为该节点处于`FAIL`状态，或者少数节点认为该节点未处于`FAIL`状态。在这两种情况下，集群最终都会有一个给定节点状态的单一视图：

**情况 1**：如果大多数主节点将节点标记为`FAIL`，由于故障检测及其产生的*连锁效应*，每个其他节点最终都会将主节点标记为`FAIL`，因为在指定的时间窗口内将报告足够多的故障。

**情况 2**：当只有少数主节点`FAIL`将节点标记为 时，副本提升将不会发生（因为它使用更正式的算法确保每个人最终都知道提升）并且每个节点都将根据`FAIL`状态清除`FAIL`状态上面的结算规则（即经过N次后没有促销`NODE_TIMEOUT`）。

**该`FAIL`标志仅用作触发器来运行**副本提升**算法的安全部分**。理论上，一个副本可以独立行动并在其主节点无法访问时启动副本升级，如果大多数主节点实际上可达，则等待主节点拒绝提供确认。然而，`PFAIL -> FAIL`国家的复杂性、薄弱的协议以及`FAIL`消息强制在集群的可达部分在最短的时间内传播状态，具有实际优势。由于这些机制，如果集群处于错误状态，通常所有节点将在大约同一时间停止接受写入。从使用 Redis Cluster 的应用程序的角度来看，这是一个理想的特性。还避免了由于本地问题而无法到达其主节点的副本发起的错误选举尝试（否则大多数其他主节点可以访问主节点）。



# 配置处理、传播和故障转移



## 集群当前纪元

Redis Cluster 使用了一个类似于 Raft 算法“术语”的概念。在 Redis 集群中，该术语被称为 epoch，它用于为事件提供增量版本控制。当多个节点提供相互冲突的信息时，另一个节点就有可能了解哪个状态是最新的。

的`currentEpoch`是一个64位无符号数。

在节点创建时，每个 Redis Cluster 节点，包括副本节点和主节点，都设置`currentEpoch`为 0。

每次从另一个节点收到一个数据包，如果发送方的纪元（集群总线消息头的一部分）大于本地节点纪元，`currentEpoch`则更新到发送方纪元。

由于这些语义，最终所有节点都会同意`currentEpoch`集群中最大的节点。

当集群的状态发生变化并且节点寻求同意以执行某些操作时，将使用此信息。

目前，这仅在副本升级期间发生，如下一节所述。基本上，纪元是集群的逻辑时钟，它指示给定的信息胜过具有较小纪元的信息。



## 配置时代

每个 master 总是`configEpoch`在 ping 和 pong 数据包中广告它，以及一个位图广告它所服务的插槽集。

将`configEpoch`创建一个新的节点时被主人设置为零。

`configEpoch`在副本选举期间创建一个新的。试图替换失败的 master 的副本会增加它们的 epoch，并尝试从大多数 master 那里获得授权。当副本被授权时，`configEpoch` 会创建一个新的唯一文件，并且副本使用新的`configEpoch`.

正如在下一节中所解释的，`configEpoch`当不同的节点声明不同的配置时（这种情况可能由于网络分区和节点故障而发生），这有助于解决冲突。

副本节点也在`configEpoch`ping 和 pong 数据包中通告该字段，但在副本的情况下，该字段表示`configEpoch`截至上次交换数据包时其主节点的。这允许其他实例检测副本何时具有需要更新的旧配置（主节点不会向具有旧配置的副本授予投票权）。

每当`configEpoch`某个已知节点发生变化时，所有接收到此信息的节点都会将其永久存储在nodes.conf 文件中。`currentEpoch`值也是如此。`fsync-ed`在节点继续其操作之前更新这两个变量时，保证会被保存并保存到磁盘。

`configEpoch`在故障转移期间使用简单算法生成的值保证是新的、增量的和唯一的。



## 副本选举和提升

副本选举和提升由副本节点处理，在主节点的帮助下投票选举要提升的副本。`FAIL`从至少一个具有成为主节点的先决条件的副本的角度来看，当主节点处于某种状态时，就会发生副本选举。

为了让副本将自己提升为 master，它需要开始选举并赢得它。All the replicas for a given master can start an election if the master is in `FAIL`state, however only one replica will win the election and promote itself to master.

当满足以下条件时，副本开始选举：

- 副本的主节点处于`FAIL`状态。
- 主服务器正在服务非零数量的插槽。
- 副本复制链接与主节点断开连接的时间不超过给定的时间，以确保提升的副本的数据合理新鲜。这个时间是用户可配置的。

为了被选举，副本的第一步是增加它的`currentEpoch`计数器，并从主实例请求投票。

副本通过`FAILOVER_AUTH_REQUEST`向集群的每个主节点广播数据包来请求投票。然后它等待最多两倍`NODE_TIMEOUT`于回复到达的时间（但总是至少 2 秒）。

一旦 master 为给定的副本投票，并以 肯定答复`FAILOVER_AUTH_ACK`，它就不能再为同一 master 的另一个副本投票一段时间`NODE_TIMEOUT * 2`。在此期间，它将无法回复同一主站的其他授权请求。这不是保证安全所必需的，但对于防止多个副本同时被选举（即使具有不同的`configEpoch`）很有用，这通常是不需要的。

副本会丢弃任何`AUTH_ACK`具有小于`currentEpoch`发送投票请求时的纪元的回复。这确保它不会计算为上一次选举准备的选票。

Once the replica receives ACKs from the majority of masters, it wins the election. 否则，如果在两次`NODE_TIMEOUT`（但总是至少 2 秒）内没有达到多数，选举将被中止，之后将再次尝试新的选举`NODE_TIMEOUT * 4`（并且总是至少 4 秒）。



## 副本等级

一旦主节点处于`FAIL`状态，副本就会等待一小段时间，然后再尝试被选举。该延迟计算如下：

```
DELAY = 500 milliseconds + random delay between 0 and 500 milliseconds +
        REPLICA_RANK * 1000 milliseconds.
```

固定延迟确保我们等待`FAIL`状态在群集中传播，否则复制品可能会尝试选择，而主人仍然不知道`FAIL`国家，则拒绝授予他们的投票。

随机延迟用于使副本不同步，因此它们不太可能同时开始选举。

的`REPLICA_RANK`是此副本关于它已经从主处理的复制数据的量的秩。当 master 失败时，副本交换消息以建立（尽力而为）等级：具有最新复制偏移量的副本位于等级 0，第二大的副本位于等级 1，依此类推。通过这种方式，最新的副本尝试在其他副本之前被选举。

排名顺序没有严格执行；if a replica of higher rank fails to be elected, the others will try shortly.

一旦副本赢取选举，它就会获得一个新的唯一和增量`configEpoch`，其高于任何其他现有主站的唯一唯一增量。它开始在 ping 和 pong 数据包中将自己宣传为 master，为一组服务的时隙提供一个`configEpoch`将赢得过去的时隙。

为了加快其他节点的重新配置，向集群的所有节点广播一个 pong 数据包。当前无法访问的节点在收到来自另一个节点的 ping 或 pong 数据包时最终将被重新配置，或者`UPDATE`如果检测到它通过心跳数据包发布的信息已过期，则将收到来自另一个节点的数据包。

其他节点将检测到有一个新的 master 服务于旧 master 服务的相同插槽，但具有更大的`configEpoch`，并将升级它们的配置。旧 master 的副本（或故障转移的 master，如果它重新加入集群）不仅会升级配置，还会重新配置以从新 master 复制。下一节将解释如何配置重新加入集群的节点。



## 大师回复副本投票请求

在上一节中讨论了副本如何尝试被选举。本节从被请求投票给给定副本的主节点的角度解释发生了什么。

主节点以`FAILOVER_AUTH_REQUEST`副本请求的形式接收投票请求。

要获得投票权，需要满足以下条件：

1. master 只在给定的 epoch 内投票一次，并且拒绝为较旧的 epoch 投票：每个 master 都有一个 lastVoteEpoch 字段，并且只要`currentEpoch`auth 请求包中的不大于 lastVoteEpoch就会拒绝再次投票。当 master 对投票请求做出肯定答复时，lastVoteEpoch 会相应更新，并安全地存储在磁盘上。
2. 仅当副本的主节点标记为 时，主节点才会投票给副本`FAIL`。
3. `currentEpoch`小于 master 的Auth 请求将`currentEpoch`被忽略。因此，主回复将始终`currentEpoch`与身份验证请求相同。如果同一个副本再次要求投票，增加`currentEpoch`，可以保证新的投票不能接受来自主服务器的旧延迟回复。

不使用规则 3 导致的问题示例：

Master`currentEpoch`为 5，lastVoteEpoch 为 1（这可能发生在几次选举失败后）

- 副本`currentEpoch`为 3。
- 副本尝试用epoch 4（3 + 1）选举，主答复为OK `currentEpoch`，但回复延迟。
- Replica 将尝试再次被选举，稍后，在 epoch 5 (4+1)，延迟的回复到达具有`currentEpoch`5的副本，并被接受为有效。

1. `NODE_TIMEOUT * 2`如果某个 master 的副本已经被投票，那么master 在过去之前不会投票给同一个 master的副本。This is not strictly required as it is not possible for two replicas to win the election in the same epoch. 然而，实际上它确保了当一个副本被选举时它有足够的时间通知其他副本并避免另一个副本赢得新选举的可能性，从而执行不必要的第二次故障转移。
2. 大师们毫不费力地以任何方式选择最好的复制品。如果副本的 master 处于`FAIL`state 并且 master 在当前任期内没有投票，则授予赞成票。最好的副本是最有可能开始选举并在其他复制品之前赢得它，因为它通常能够先开始投票过程，因为它的*级别较高，*如前一节所述。
3. 当 master 拒绝为给定的副本投票时，没有否定响应，该请求将被简单地忽略。
4. 对于副本所声明的插槽，主节点不会投票给副本发送`configEpoch`比`configEpoch`主表中的任何值都少的值。请记住，副本发送`configEpoch`其主服务器的 ，以及其主服务器服务的插槽的位图。这意味着请求投票的副本必须具有它想要故障转移的插槽的配置，该配置更新或等于授予投票的主服务器之一。



## 分区期间配置纪元有用的实际示例

本节说明了如何使用 epoch 概念使副本提升过程对分区更具抵抗力。

- 不再可以无限期地访问主节点。主节点有三个副本 A、B、C。
- Replica A wins the election and is promoted to master.
- 网络分区使 A 对于大多数集群不可用。
- Replica B wins the election and is promoted as master.
- A 分区使 B 不可用于集群的大多数。
- 之前的分区是固定的，A又可用了。

此时 B 已关闭，A 再次可用并担任主控角色（实际上`UPDATE`消息会立即重新配置它，但在这里我们假设所有`UPDATE`消息都丢失了）。同时，副本 C 将尝试被选举以故障转移 B。 这是发生的事情：

1. C will try to get elected and will succeed, since for the majority of masters its master is actually down. 它将获得一个新的增量`configEpoch`。
2. A 将无法声称是其哈希槽的主节点，因为与 A 发布的节点相比，其他节点已经拥有与更高配置时期（B 之一）相关联的相同哈希槽。
3. 因此，所有节点将升级其表以将哈希槽分配给 C，并且集群将继续其操作。

正如您将在下一节中看到的，重新加入集群的陈旧节点通常会尽快收到有关配置更改的通知，因为只要它 ping 任何其他节点，接收器就会检测到它有陈旧信息，并会发送一个`UPDATE`信息。



## 哈希槽配置传播

Redis Cluster 的一个重要部分是用于传播有关哪个集群节点正在为给定的哈希槽集提供服务的信息的机制。这对于新集群的启动以及在副本升级为故障主节点的插槽后升级配置的能力都至关重要。

相同的机制允许在无限时间内分区的节点以合理的方式重新加入集群。

散列槽配置有两种传播方式：

1. 心跳消息。ping 或 pong 数据包的发送方总是添加有关它（或它的主机，如果它是副本）所服务的哈希槽集的信息。
2. `UPDATE`消息。由于在每个心跳包中都有关于发送者`configEpoch`和所服务的哈希槽集的信息，如果心跳包的接收者发现发送者信息是陈旧的，它将发送一个带有新信息的包，迫使陈旧节点更新其信息。

心跳或`UPDATE`消息的接收者使用某些简单的规则来更新其映射哈希槽到节点的表。当一个新的 Redis Cluster 节点被创建时，它的本地哈希槽表被简单地初始化为`NULL`条目，这样每个哈希槽都不会绑定或链接到任何节点。这看起来类似于以下内容：

```
0 -> NULL
1 -> NULL
2 -> NULL
...
16383 -> NULL
```

节点为了更新其哈希槽表而遵循的第一条规则如下：

**规则 1**：如果一个哈希槽未被分配（设置为`NULL`），并且一个已知节点声明它，我将修改我的哈希槽表并将声明的哈希槽关联到它。

因此，如果我们收到来自节点 A 的心跳，声称为配置纪元值为 3 的哈希槽 1 和 2 提供服务，则该表将被修改为：

```
0 -> NULL
1 -> A [3]
2 -> A [3]
...
16383 -> NULL
```

创建新集群时，系统管理员需要手动分配（使用[CLUSTER ADDSLOTS](https://redis.io/commands/cluster-addslots)命令、通过 redis-cli 命令行工具或通过任何其他方式）每个主节点服务的插槽仅分配给节点本身，并且信息将在整个集群中迅速传播。

然而，这条规则还不够。我们知道哈希槽映射可以在两个事件期间改变：

1. 副本在故障转移期间替换其主服务器。
2. 一个插槽从一个节点重新分片到另一个节点。

现在让我们专注于故障转移。当副本故障转移其主服务器时，它会获得一个配置纪元，该纪元保证大于其主纪元（并且更普遍地大于之前生成的任何其他配置纪元）。例如，作为 A 的副本的节点 B 可能会故障转移 A，配置 epoch 为 4。它将开始发送心跳包（第一次在集群范围内进行大规模广播），并且由于以下第二条规则，接收者将更新他们的哈希槽表：

**规则 2**：如果已经分配了一个哈希槽，并且一个已知节点正在使用`configEpoch`大于`configEpoch`当前与该槽关联的主节点的 来通告它，我会将哈希槽重新绑定到新节点。

因此，在收到来自 B 的消息声称服务于配置时期为 4 的哈希槽 1 和 2 后，接收方将按以下方式更新其表：

```
0 -> NULL
1 -> B [4]
2 -> B [4]
...
16383 -> NULL
```

活性属性：由于第二条规则，最终集群中的所有节点都会同意插槽的所有者是`configEpoch`广告节点中最大的一个。

Redis Cluster 中的这种机制称为**last failover wins**。

在重新分片期间也会发生同样的情况。当导入哈希槽的节点完成导入操作时，其配置纪元会增加，以确保更改将在整个集群中传播。



## 更新消息，仔细看看

记住上一节，更容易了解更新消息的工作原理。节点 A 可能会在一段时间后重新加入集群。它将发送心跳包，它声称它服务于配置时期为 3 的哈希槽 1 和 2。所有具有更新信息的接收器将改为看到相同的哈希槽与具有更高配置时期的节点 B 相关联。因此，他们将`UPDATE`使用插槽的新配置向 A发送消息。由于上述**规则 2**，A 将更新其配置 。



## 节点如何重新加入集群

节点重新加入集群时使用相同的基本机制。继续上面的例子，节点 A 将被通知散列槽 1 和 2 现在由 B 服务。假设这两个是 A 服务的唯一散列槽，由 A 服务的散列槽的计数将下降到 0！所以 A 将**重新配置为新 master 的副本**。

实际遵循的规则比这更复杂一些。一般来说，A可能会在很长时间后重新加入，同时可能会发生原来由A服务的hash slot被多个节点服务，例如hash slot 1可能由B服务，hash slot 2可能由C服务.

所以实际的*Redis Cluster 节点角色切换规则*是：**一个主节点将改变它的配置来复制（作为一个副本）窃取其最后一个哈希槽的节点**。

在重新配置期间，最终服务的哈希槽数量将降至零，节点将相应地重新配置。请注意，在基本情况下，这仅意味着旧主服务器将是故障转移后替换它的副本的副本。然而，在一般形式中，该规则涵盖了所有可能的情况。

副本完全相同：它们重新配置以复制窃取其前主节点最后一个哈希槽的节点。



## 副本迁移

Redis Cluster 实现了一个叫做*副本迁移*的概念，以提高系统的可用性。这个想法是，在具有主副本设置的集群中，如果副本和主节点之间的映射是固定的，如果单个节点发生多个独立故障，则可用性会随着时间的推移而受到限制。

例如，在每个主节点都有一个副本的集群中，只要主节点或副本失败，集群就可以继续运行，但如果两者同时失败，则不能继续运行。然而，有一类故障是由硬件或软件问题引起的单个节点的独立故障，这些故障会随着时间的推移而累积。例如：

- Master A 有一个副本 A1。
- 大师 A 失败。A1 被提升为新主。
- 三小时后，A1 以独立方式失效（与 A 的失效无关）。由于节点 A 仍处于停机状态，因此没有其他副本可用于提升。集群无法继续正常运行。

如果 master 和 replica 之间的映射是固定的，那么使集群更能抵抗上述场景的唯一方法是向每个 master 添加副本，但是这样做的成本很高，因为它需要执行更多的 Redis 实例、更多的内存和等等。

另一种方法是在集群中创建不对称，并让集群布局随时间自动变化。例如，集群可能有三个主节点 A、B、C。A 和 B 各有一个副本，A1 和 B1。但是主 C 是不同的，它有两个副本：C1 和 C2。

副本迁移是自动重新配置副本以*迁移*到不再覆盖的主节点（没有工作副本）的过程。通过副本迁移，上面提到的场景变成了以下场景：

- 大师 A 失败。A1 被提升。
- C2 作为 A1 的副本迁移，否则没有任何副本支持。
- 三小时后，A1 也失败了。
- C2 被提升为新的 master 以取代 A1。
- 集群可以继续操作。



## 副本迁移算法

迁移算法不使用任何形式的协议，因为 Redis 集群中的副本布局不是集群配置的一部分，需要与配置时期保持一致和/或版本化。相反，它使用一种算法来避免在没有支持主服务器时大量迁移副本。该算法保证最终（一旦集群配置稳定）每个主节点都将得到至少一个副本的支持。

这就是算法的工作原理。首先，我们需要定义在这种情况下什么是 *好的副本*：`FAIL`从给定节点的角度来看，好的副本是未处于状态的副本。

在检测到至少有一个没有好的副本的主节点的每个副本中触发算法的执行。然而，在检测到这种情况的所有副本中，只有一个子集应该起作用。这个子集实际上通常是单个副本，除非不同的副本在给定时刻对其他节点的故障状态有略微不同的看法。

的*作用复制品*是与附接副本的最大数量，即不是在FAIL状态，并具有最小的节点ID的主人之间的复制品。

因此，例如，如果有 10 个主节点，每个主节点有 1 个副本，而 2 个主节点每个有 5 个副本，那么将尝试迁移的副本是 - 在具有 5 个副本的 2 个主节点中 - 节点 ID 最低的一个。鉴于没有使用协议，当集群配置不稳定时，可能会出现竞争条件，即多个副本认为自己是具有较低节点 ID 的非故障副本（这在实践中不太可能发生） ）。如果发生这种情况，结果是多个副本迁移到同一个主服务器，这是无害的。如果比赛以某种方式发生，让放弃的主人没有副本，

最终，每个 master 都将得到至少一个副本的支持。但是，正常的行为是单个副本从具有多个副本的 master 迁移到孤立的 master。

该算法由用户可配置的参数控制，该参数称为 `cluster-migration-barrier`：在副本迁移离开之前，必须保留主副本的良好副本数量。例如，如果此参数设置为 2，则只有当它的 master 保留有两个工作副本时，副本才能尝试迁移。



## configEpoch 冲突解决算法

`configEpoch`在故障转移期间通过副本提升创建新值时，它们保证是唯一的。

然而，有两个不同的事件以不安全的方式创建新的 configEpoch 值，只是增加`currentEpoch`本地节点的本地值并希望同时没有冲突。这两个事件都是系统管理员触发的：

1. 带有`TAKEOVER`选项的[CLUSTER FAILOVER](https://redis.io/commands/cluster-failover)命令能够手动将副本节点提升为主节点，*而大多数*主节点都不*可用*。例如，这在多数据中心设置中很有用。
2. 出于性能原因，用于集群重新平衡的插槽迁移也会在本地节点内生成新的配置时期，而无需达成一致。

具体来说，在手动重分片过程中，当一个hash slot从节点A迁移到节点B时，重分片程序会强制B将其配置升级到集群中找到的最大纪元，加1（除非节点是已经是具有最大配置时期的那个），而无需其他节点的同意。通常现实世界的重新分片涉及移动数百个哈希槽（尤其是在小集群中）。要求在重新分片期间为每个散列槽移动生成新配置时期的协议是低效的。此外，它每次都需要在每个集群节点中进行 fsync 以存储新配置。由于它的执行方式，

然而，由于上述两种情况，有可能（尽管不太可能）以具有相同配置时期的多个节点结束。系统管理员执行的重新分片操作和同时发生的故障转移（加上很多运气不好）可能会导致`currentEpoch`冲突，如果它们传播得不够快。

此外，软件错误和文件系统损坏也可能导致多个节点具有相同的配置时期。

当服务于不同哈希槽的主节点具有相同的 时`configEpoch`，没有问题。更重要的是，故障转移到主服务器的副本具有独特的配置时期。

也就是说，手动干预或重新分片可能会以不同的方式更改集群配置。Redis Cluster 的主要活性属性要求插槽配置始终收敛，因此在每种情况下，我们确实希望所有主节点都有不同的`configEpoch`.

为了实施这个，**冲突解决算法**是在两个节点结束了相同的情况下使用`configEpoch`。

- 如果一个主节点检测到另一个主节点正在用相同的`configEpoch`.
- 并且，如果该节点与声明相同`configEpoch`.
- 然后它将其增加`currentEpoch`1，并将其用作新的`configEpoch`.

如果有任何一组节点具有相同的`configEpoch`，则除具有最大节点 ID 的节点之外的所有节点都将向前移动，从而保证最终每个节点都将选择一个唯一的 configEpoch，无论发生什么。

这种机制还保证在创建新集群后，所有节点都以不同的`configEpoch`（即使实际上没有使用）开始，因为`redis-cli`确保`CONFIG SET-CONFIG-EPOCH`在启动时使用。但是，如果由于某种原因使节点配置错误，它将自动将其配置更新为不同的配置时期。



## 节点重置

节点可以通过软件重置（无需重新启动），以便在不同的角色或不同的集群中重用。这在正常操作、测试和云环境中非常有用，在这些环境中，可以重新配置给定节点以加入不同的节点集以扩大或创建新集群。

在 Redis 集群节点使用[CLUSTER RESET](https://redis.io/commands/cluster-reset)命令[重置](https://redis.io/commands/cluster-reset)。该命令有两种变体：

- `CLUSTER RESET SOFT`
- `CLUSTER RESET HARD`

命令必须直接发送到节点才能复位。如果未提供复位类型，则执行软复位。

以下是复位执行的操作列表：

1. 软复位和硬复位：如果节点是副本，则变成主节点，并丢弃其数据集。如果节点是主节点并且包含密钥，则中止重置操作。
2. 软硬复位：释放所有槽位，复位手动故障切换状态。
3. 软和硬重置：节点表中的所有其他节点都被删除，因此该节点不再知道任何其他节点。
4. 仅硬重置：`currentEpoch`、`configEpoch`和`lastVoteEpoch`设置为 0。
5. 仅硬重置：节点 ID 更改为新的随机 ID。

无法重置具有非空数据集的主节点（因为通常您希望将数据重新分片到其他节点）。然而，在适当的特殊情况下（例如，当一个集群被完全破坏以创建一个新集群时），必须在继续重置之前执行[FLUSHALL](https://redis.io/commands/flushall)。



## 从集群中删除节点

通过将节点的所有数据重新分片到其他节点（如果它是主节点）并关闭它，实际上可以从现有集群中删除节点。但是，其他节点仍会记住其节点 ID 和地址，并会尝试与其连接。

出于这个原因，当一个节点被删除时，我们还想从所有其他节点表中删除它的条目。这是通过使用`CLUSTER FORGET <node-id>`命令来完成的 。

该命令做了两件事：

1. 它从节点表中删除具有指定节点 ID 的节点。
2. 它设置了 60 秒的禁令，以防止重新添加具有相同节点 ID 的节点。

需要第二个操作，因为 Redis Cluster 使用 gossip 来自动发现节点，因此从节点 A 中删除节点 X 可能会导致节点 B 再次将节点 X 八卦到 A。由于 60 秒禁令，Redis Cluster 管理工具有 60 秒的时间从所有节点中删除节点，防止由于自动发现而重新添加节点。

[CLUSTER FORGET](https://redis.io/commands/cluster-forget)文档中提供了更多信息。



# 发布/订阅

在 Redis 集群中，客户端可以订阅每个节点，也可以发布到每个其他节点。集群将确保根据需要转发已发布的消息。

当前的实现将简单地将每个发布的消息广播到所有其他节点，但在某些时候，这将使用布隆过滤器或其他算法进行优化。



# 附录



## 附录 A：ANSI C 中的 CRC16 参考实现

```
/*
 * Copyright 2001-2010 Georges Menie (www.menie.org)
 * Copyright 2010 Salvatore Sanfilippo (adapted to Redis coding style)
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the University of California, Berkeley nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE REGENTS AND CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/* CRC16 implementation according to CCITT standards.
 *
 * Note by @antirez: this is actually the XMODEM CRC 16 algorithm, using the
 * following parameters:
 *
 * Name                       : "XMODEM", also known as "ZMODEM", "CRC-16/ACORN"
 * Width                      : 16 bit
 * Poly                       : 1021 (That is actually x^16 + x^12 + x^5 + 1)
 * Initialization             : 0000
 * Reflect Input byte         : False
 * Reflect Output CRC         : False
 * Xor constant to output CRC : 0000
 * Output for "123456789"     : 31C3
 */

static const uint16_t crc16tab[256]= {
    0x0000,0x1021,0x2042,0x3063,0x4084,0x50a5,0x60c6,0x70e7,
    0x8108,0x9129,0xa14a,0xb16b,0xc18c,0xd1ad,0xe1ce,0xf1ef,
    0x1231,0x0210,0x3273,0x2252,0x52b5,0x4294,0x72f7,0x62d6,
    0x9339,0x8318,0xb37b,0xa35a,0xd3bd,0xc39c,0xf3ff,0xe3de,
    0x2462,0x3443,0x0420,0x1401,0x64e6,0x74c7,0x44a4,0x5485,
    0xa56a,0xb54b,0x8528,0x9509,0xe5ee,0xf5cf,0xc5ac,0xd58d,
    0x3653,0x2672,0x1611,0x0630,0x76d7,0x66f6,0x5695,0x46b4,
    0xb75b,0xa77a,0x9719,0x8738,0xf7df,0xe7fe,0xd79d,0xc7bc,
    0x48c4,0x58e5,0x6886,0x78a7,0x0840,0x1861,0x2802,0x3823,
    0xc9cc,0xd9ed,0xe98e,0xf9af,0x8948,0x9969,0xa90a,0xb92b,
    0x5af5,0x4ad4,0x7ab7,0x6a96,0x1a71,0x0a50,0x3a33,0x2a12,
    0xdbfd,0xcbdc,0xfbbf,0xeb9e,0x9b79,0x8b58,0xbb3b,0xab1a,
    0x6ca6,0x7c87,0x4ce4,0x5cc5,0x2c22,0x3c03,0x0c60,0x1c41,
    0xedae,0xfd8f,0xcdec,0xddcd,0xad2a,0xbd0b,0x8d68,0x9d49,
    0x7e97,0x6eb6,0x5ed5,0x4ef4,0x3e13,0x2e32,0x1e51,0x0e70,
    0xff9f,0xefbe,0xdfdd,0xcffc,0xbf1b,0xaf3a,0x9f59,0x8f78,
    0x9188,0x81a9,0xb1ca,0xa1eb,0xd10c,0xc12d,0xf14e,0xe16f,
    0x1080,0x00a1,0x30c2,0x20e3,0x5004,0x4025,0x7046,0x6067,
    0x83b9,0x9398,0xa3fb,0xb3da,0xc33d,0xd31c,0xe37f,0xf35e,
    0x02b1,0x1290,0x22f3,0x32d2,0x4235,0x5214,0x6277,0x7256,
    0xb5ea,0xa5cb,0x95a8,0x8589,0xf56e,0xe54f,0xd52c,0xc50d,
    0x34e2,0x24c3,0x14a0,0x0481,0x7466,0x6447,0x5424,0x4405,
    0xa7db,0xb7fa,0x8799,0x97b8,0xe75f,0xf77e,0xc71d,0xd73c,
    0x26d3,0x36f2,0x0691,0x16b0,0x6657,0x7676,0x4615,0x5634,
    0xd94c,0xc96d,0xf90e,0xe92f,0x99c8,0x89e9,0xb98a,0xa9ab,
    0x5844,0x4865,0x7806,0x6827,0x18c0,0x08e1,0x3882,0x28a3,
    0xcb7d,0xdb5c,0xeb3f,0xfb1e,0x8bf9,0x9bd8,0xabbb,0xbb9a,
    0x4a75,0x5a54,0x6a37,0x7a16,0x0af1,0x1ad0,0x2ab3,0x3a92,
    0xfd2e,0xed0f,0xdd6c,0xcd4d,0xbdaa,0xad8b,0x9de8,0x8dc9,
    0x7c26,0x6c07,0x5c64,0x4c45,0x3ca2,0x2c83,0x1ce0,0x0cc1,
    0xef1f,0xff3e,0xcf5d,0xdf7c,0xaf9b,0xbfba,0x8fd9,0x9ff8,
    0x6e17,0x7e36,0x4e55,0x5e74,0x2e93,0x3eb2,0x0ed1,0x1ef0
};

uint16_t crc16(const char *buf, int len) {
    int counter;
    uint16_t crc = 0;
    for (counter = 0; counter < len; counter++)
            crc = (crc<<8) ^ crc16tab[((crc>>8) ^ *buf++)&0x00FF];
    return crc;
}
```

本网站是 [开源软件](https://github.com/redis/redis-io) ，由[Redis Ltd](https://redis.com/)赞助 [。](https://redis.com/) 查看所有[版权](https://redis.io/topics/sponsors)。