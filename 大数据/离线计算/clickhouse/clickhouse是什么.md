[TOC]

# 思路

简介

组成

角度

​	边缘



# 介绍

## 宏观感受

数据库, 存储/查询/计算大量数据

列式存储数据库, 与mysql这种行数数据库相比, 数据都是按列去存的, 查询时也是直接查询一列并做计算, 由于列的很容易固定, 所以一列数据更容易优化, 例如压缩、编解码, 在实际应用场景中, 从几百上千列精简到1列或者几列, 性能会显著提升, 资源使用量也会显著降低

clickhouse本身是前沿技术工程实践者, 很多优秀的思路都被实现在ch里面, 例如LSM(顺序写)、MMAP(零拷贝)、SIMD(向量化执行)、Llvm(表达式计算)、MultiThread(计算并行)、Async(异步化)、SHARE-REPLICAS(分片副本)、MMP(大规模并行计算)、Skipping-Index(稀疏索引)+索引内存化、



## 使用上

## 不适合做什么

不适做OLTP: 没有完整的事务、没有完整的SQL支持、没有稠密索引，点查性能低(主键)、无法高频低量写入

没有很好的join支持

高并发性能低



## 应用上

日志系统: 存储可抽取列的索引: 业务-缓存-服务-服务类型-版本-时间-原始日志

存储采集数据: 复杂的多维度时序数据

# 形态

整体可以这样划分层级

```
environment(环境)
	service(业务)
		share(分片)-replicas(副本)
            database(数据库)
            	table(表)
            		partition(分区)
            			column(字段)
            			projection(投影查询)
            			materializedViem(物化视图)
```

过多的元数据会导致启动时间过长



## 业务区

不同业务先可以分开使用ch, 而不是单个ch

不同环境使用不同的ch

## SHARD(分片)

为什么需要分片?

在结合拆分键后可以提升性能(tps/qps)、稳定性、可拓展性、统一管理

应用在租户场景中, 如果所有的租户都往一个节点写入/查询, 那么这一台很有可能会扛不住, 从而引发ch不可用, 业务受损, 但是如果通过tenant_id拆分到多个节点并行写入/查询, 那么就可以实现

另一个问题就是即使平时能抗住, 但是突发性扛不住导致整体不可用也是个问题, 拆分之后就可以互补影响, 一些灰度操作也可以通过分片隔离的形式开展

当需要持续加入租户以及随着时间推移数据量越来越多时, 节点的存储、计算、内存会有不可用危机, 通过增加大权重分片+TTL或者手动迁移数据就可以解决这个问题, 当然也可以提前预估好未来的量并一次性配置好来避免调整, 但是这样又会有资源利用率过低的问题

当然我们也可以通过在节点层硬性分离, 但是那样会引发成本和资源利用率及可操作性问题, 实际上tenant_id会再次结合业务时间进行拆分



在ch中, 分片是一个集群逻辑概念, 每个点都冗余这个逻辑并并行操作实际存储的各个副本

如果基于分布式表来写数据, 该节点需要手动主动拆分(sharding_key和weight)写入到所有副本, 从而放大写入和合并, 影响集群性能引发不可用, 如果节点宕机就会直接丢失数据

写入时建议使用本地表而不是分布式表

客户端同步写+异常重试可以在客户端侧解决ch集群不稳定引起的数据丢失问题



边缘:

​	几十个。更多可能需要更复杂（非平面）的路由



通过配置文件为ch配置分布式集群(2分片1副本)

```
<remote_servers>
    <logs>
        <shard>
            <weight>1</weight>
            <internal_replication>true</internal_replication>
            <replica>
                <host>example01-01-1</host>
                <port>9000</port>
            </replica>
        </shard>
        <shard>
            <weight>2</weight>
            <internal_replication>true</internal_replication>
            <replica>
                <host>example01-02-1</host>
                <port>9000</port>
            </replica>
        </shard>
    </logs>
</remote_servers>
```

`remote_servers` 为ch固定标签, `logs` 为分布式集群名称, 统一业务线下共用, 不用业务线使用不同的集群, `shard` 为ch固定标签, `replica` 为物理ch节点

在使用时, 先在每个副本创建本地表

```
CREATE TABLE [IF NOT EXISTS] [db.]table_name_local () ENGINE = ReplicateMergeTree();
```

上面这种方式为物理一致性(同步复制), 数据一致性不依赖于分布表而依赖于副本合并树表, 对zookeeper有一定压力或者说受到zookeeper性能的影响

实际上还有另外一种方式: internal_replication为false + MergeTree实现逻辑一致性(异步复制), 分散写入点以提高性能, 但是分散查询时会有数据一致性问题

再创建分布式表

```
CREATE TABLE [IF NOT EXISTS] [db.]table_name_all [ON CLUSTER cluster]
(
    name1 [type1] [DEFAULT|MATERIALIZED|ALIAS expr1],
    name2 [type2] [DEFAULT|MATERIALIZED|ALIAS expr2],
    ...
) ENGINE = Distributed(cluster, db, local_table[, sharding_key[, policy_name]])
[SETTINGS name=value, ...]
```

## REPLICA(副本)

为什么需要副本?

使用副本机制多点并发写入提升应用层集群的稳定性, 同时任意副本查询提升查询性能



已有实现方式:

ch使用MergeTree下的ReplicatedMergeTree、ReplicatedSummingMergeTree、ReplicatedReplacingMergeTree、ReplicatedAggregatingMergeTree、ReplicatedCollapsingMergeTree、ReplicatedVersionedCollapsingMergetree、ReplicatedGraphiteMergeTree基于协调器(ZooKeeper 3.4.5+)实现副本机制(后续可以使用clickhouse-keeper), 协调器不可用时MergeTree不可写入(触发写入异常)

通过设置`insert_quorum>2` 保证同步写入, 同时建议和实际副本数一致

新的副本启动时会根据`replicated_max_ratio_of_wrong_parts `系统参数检查数据差异程度, 如果差异程度过高会无法启动, 从而无法触发自检通过, 那么业务路由规则将不会使用到新的副本, 不会出现查询有问题(缺失数据、统计结果不准确)

创建本地副本表时需要在每个副本上创建表, 可以通过分布式表对集群上所有的副本进行DDL, 内部会自动做初始同步, alter、insert语句会自动被同步到其他副本上, 建表语句中的zk路径建议加一层uuid, `ReplicatedMergeTree('/clickhouse/tables/{shard}/my_db/my_table/{UUID}','{replica}')`



```
        <shard>
            <weight>1</weight>
            <internal_replication>true</internal_replication>
            <replica>
                <host>example01-01-1</host>
                <port>9000</port>
            </replica>
            <replica>
                <host>example01-01-2</host>
                <port>9000</port>
            </replica>
        </shard>
```

边缘:

​	磁盘: 10TB。更大的磁盘更难更换/重新同步

​	2 是 HA 的最小值。三是“黄金标准”。最多6-8还是可以的。大量实时插入会影响 zookeeper 流量

### COORDINATION(协调器)

用来维护复制表多个副本的元数据及任务管理

启动时需要建立客户端

边缘:

​	大多数情况下3个就足够了(一个冗余度)。使用更多节点可以扩大 zookeeper 的读取吞吐量，但根本不提高写入

查询

```
SELECT czxid, mzxid, name, value FROM system.zookeeper WHERE path = '/';
```

#### zookeeper

通过底层提供多个zookeeper集群, 上层岔开使用不同的zookeeper集群, 从而提升zookeeper整体集群的性能



#### clickhouse-keeper

目前尚未成熟，但是做贡献价值很高

部署&集成

`/etc/clickhouse-server/config.d/keeper.xml`

```
<?xml version="1.0" ?>
<yandex>
    <keeper_server>
        <tcp_port>2181</tcp_port>
        <server_id>1</server_id>
        <log_storage_path>/var/lib/clickhouse/coordination/log</log_storage_path>
        <snapshot_storage_path>/var/lib/clickhouse/coordination/snapshots</snapshot_storage_path>

        <coordination_settings>
            <operation_timeout_ms>10000</operation_timeout_ms>
            <session_timeout_ms>30000</session_timeout_ms>
            <raft_logs_level>trace</raft_logs_level>
              <rotate_log_storage_interval>10000</rotate_log_storage_interval>
        </coordination_settings>

      <raft_configuration>
            <server>
               <id>1</id>
                 <hostname>hostname1</hostname>
               <port>9444</port>
          </server>
          <server>
               <id>2</id>
                 <hostname>hostname2</hostname>
               <port>9444</port>
          </server>
      </raft_configuration>

    </keeper_server>

    <zookeeper>
        <node>
            <host>localhost</host>
            <port>2181</port>
        </node>
    </zookeeper>

    <distributed_ddl>
        <path>/clickhouse/testcluster/task_queue/ddl</path>
    </distributed_ddl>
</yandex>
```





## DATABASE(数据库)

`CREATE DATABASE [IF NOT EXISTS] db_name [ON CLUSTER cluster] [ENGINE = engine(...)]`

不同业务方向可以使用不同的数据库, 在实例层作为逻辑隔离, 底层也确实是不同的文件目录



由Ordinary、Atomic 引擎组成

`Ordinary`文件系统上的布局更简单。在大多数情况下，解决原子问题（无锁重命名、删除、表的原子交换）并不是那么重要。

|                                                              | 普通的                                                       | 原子                                                         |
| :----------------------------------------------------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| 文件系统布局                                                 | 很简单的                                                     | 更复杂                                                       |
| 外部工具支持 （如 clickhouse-backup）                        | 好/成熟                                                      | 有限/测试版                                                  |
| 一些 DDL 查询（DROP / RENAME）可能挂了很长时间（等待一些其他的事情） | 是的                                                         | 没有                                                         |
| 可以交换 2 张桌子                                            | 将 a重命名 为 a_old， 将 b 重命名为 a，a_old 到 b；操作不是原子的，并且 可以在中间中断（虽然机会很低）。 | 交换表 t1 和 t2原子，没有中间状态。                          |
| zookeeper路径中的uuid                                        | 无法使用。典型的模式是在需要创建 同一张表的新版本时，在 zookeeper 路径中添加版本后缀。 | 您可以在 zookeeper 路径中使用 uuid。 当您扩展集群时，这需要格外小心，并使 Zookeeper 路径更难以映射到真实表。但允许对表进行任何类型的操作（重命名、使用相同名称重新创建等）。 |
| 没有 TO 语法的物化视图（！我们建议始终使用 TO 语法！）       | .inner.mv_name名字可想而知，容易搭配MV。                     | .inner_id.{uuid}名称不可预知，难以与 MV 匹配（可能对 MV 链有问题，类似场景） |

## View(视图)

由普通视图、物化视图 组成

同时有Live视图、Window视图 实验性功能

作为元数据会在启动时被加载

### View(普通视图)

相当于SQL查询语句

```
CREATE [OR REPLACE] VIEW [IF NOT EXISTS] [db.]table_name [ON CLUSTER] AS SELECT ...
```

### MaterializedView(物化视图)

通过使用物化视图存储预计算可以提高特定分析场景的查询效率

```
CREATE MATERIALIZED VIEW [IF NOT EXISTS] [db.]table_name [ON CLUSTER] [TO[db.]name] [ENGINE = engine] [POPULATE] AS SELECT ...
```

实现原理类似于触发器

通过create as select创建表结构, 通过insert trigger增量insert数据(非update/delete)

通过指定`POPULATE` 可以实现初量数据初始化, 但是会导致在操作期间丢失源表的增量数据

边缘:

​	取决于是否需要实时插入 (延迟时间), 没有不考虑这个则数量问题不大, 反之:

​	最多几个, 如果表获得实时插入，则越少越好。（无论 MV 是链接的还是全部来自同一个源表）,拥有的越多，插入的成本就越高，并且在某些 MV 之间出现一些不一致的风险就越大（插入到 MV 和主表不是原子的）



### 实验性

#### LIVE视图

```
CREATE LIVE VIEW [IF NOT EXISTS] [db.]table_name [WITH [TIMEOUT [value_in_sec] [AND]] [REFRESH [value_in_sec]]] AS SELECT ...
```

实时视图存储相应SELECT查询的结果，并在查询结果更改时随时更新。 查询结果以及与新数据结合所需的部分结果存储在内存中，为重复查询提供更高的性能。当使用WATCH查询更改查询结果时，实时视图可以提供推送通知。

实时视图是通过插入到查询中指定的最里面的表来触发的。 

实时视图的工作方式类似于分布式表中查询的工作方式。 但不是组合来自不同服务器的部分结果，而是将当前数据的部分结果与新数据的部分结果组合在一起。当实时视图查询包含子查询时，缓存的部分结果仅存储在最里面的子查询中。



部分查询场景下通过LIVE视图缓存查询结果以及加速查询应该可行且有用的

#### window view(窗口视图)

```
CREATE WINDOW VIEW [IF NOT EXISTS] [db.]table_name [TO [db.]table_name] [ENGINE = engine] [WATERMARK = strategy] [ALLOWED_LATENESS = interval_function] AS SELECT ... GROUP BY time_window_function
```

Window view可以通过时间窗口聚合数据，并在满足窗口触发条件时自动触发对应窗口计算。其通过将计算状态保存降低处理延迟，支持将处理结果输出至目标表或通过`WATCH`语句输出至终端。

创建window view的方式和创建物化视图类似。Window view使用默认为`AggregatingMergeTree`的内部存储引擎存储计算中间状态。

部分查询场景下通过Window视图自动做汇总查询可以加速查询



## Table(表)

其实更应该称之为引擎

核心就是MergeTree (合并树表引擎)

作为元数据会在启动时被加载, 通知会启动很多后台定时检查执行的线程

底层使用IStorage接口承载表对象, IStorage上层实现有IStorageSystemOneBlock(系统表)、StorageMergeTree(合并树引擎)、StorageTinyLog(日志表引擎)等, 其中定义了DDL(Alter/Drop/Rename)/Read/Write等函数, 组合了Parser接口、Interpreter接口, Parser接口承载解析SQL(不同类型的SQL有不同的Parser实现类, 例如: ParserRenameQuery、ParserDropQuery、ParserAlterQuery、ParserInsertQuery、ParserSelectQuery、)并创建AST(抽象语法树)对象, IStorage从而查询列数据, Interpreter接口承载对列数据加工(格式化)、计算(IFunctions转换、IAggregateFunctions聚合)、过滤等, Aggregate-Functions是有状态函数有上下文关联关系, 从而生成IBlock(数据承载接口); IBlock(块流)由Column(数据对象)、DataType(数据类型)和ColumnName(列名称字符)事物组成, 通过ColumnWithAndName方法找到对于Column&DataType并调用, 由IBlockInputStream(输入接口)、IBlockOutputStream(输出接口)函数组成串联动作, 操作引擎表元数据(DDL)、运算时数据、业务引擎数据

一个创建表的例子

`/etc/clickhouse-server/config.d/macros.xml`

```
<?xml version="1.0" ?>
<yandex>
    <macros>
        <cluster>testcluster</cluster>
        <replica>replica2</replica>
        <shard>1</shard>
    </macros>
</yandex>
```



```
create table test on '{cluster}'   ( A Int64, S String)
Engine = ReplicatedMergeTree('/clickhouse/{cluster}/tables/{database}/{table}','{replica}')
Order by A;

insert into test select number, '' from numbers(100000000);

-- on both nodes:
select count() from test;
```



2019年的测试数据: 单次插入1列需要2Mb内存



### MergeTree(合并树)

数据可以以数据片段的形式一个接着一个的快速写入，数据片段在后台按照一定的规则进行合并。相比在插入时不断修改（重写）已存储的数据，这种策略会高效很多。

在一次写入少于1048576行时是原子性的, 要么一个块都写入成功、要么都失败, 同一个块由于块hash值一样, 所以第二次执行时会直接被去重

虽然称为树, 但是实际上却并不是BTree(没有刻意维护BTree, 但是由于写入已经是有序的了, 所以类似BTree)

```
CREATE TABLE [IF NOT EXISTS] [db.]table_name [ON CLUSTER cluster]
(
    name1 [type1] [DEFAULT|MATERIALIZED|ALIAS expr1] [TTL expr1],
    name2 [type2] [DEFAULT|MATERIALIZED|ALIAS expr2] [TTL expr2],
    ...
    INDEX index_name1 expr1 TYPE type1(...) GRANULARITY value1,
    INDEX index_name2 expr2 TYPE type2(...) GRANULARITY value2
) ENGINE = MergeTree()
ORDER BY expr
[PARTITION BY expr]
[PRIMARY KEY expr]
[SAMPLE BY expr]
[TTL expr [DELETE|TO DISK 'xxx'|TO VOLUME 'xxx'], ...]
[SETTINGS name=value, ...]
```

物理文件存储结构

```
table_name
	partition_1
		# 基础文件
		checksums.txt	: 校验文件, 记录其他文件的size及其哈希值
		columns.txt		: 列信息
		count.txt		: 计数文件, 快速返回select count(1)的结果
		primary.idx		: 一级索引文件
		[Column].bin	: 列的数据文件, 存储实际数据(默认LZ4压缩格式) 
		[Column].mrk	: 列在稀疏索引查询后.bin文件偏移量标记文件
		[Column].mrk2	: 在上面的基础上针对自适应索引大小的索引间隔
		
		# 分区
		partition.dat		: 记录分区表达式最终生成的值
		minmax_[Column].idx	: 记录当前分区下分区字段对应的原始数据的最小和最大值, 用于分区裁剪
		
		# 二级索引
		skp.idx_[Column].idx : 二级稀疏索引, 类似一级稀疏索引
		skp_idx_[Column].mrk : 二级稀疏索引标记文件, 类似一级稀疏索引标记文件
```

WAL(Write-Ahead Log)

通过WAL机制可以在MergeTree的首层减少高频写入,  防止生成过多的part

当单次插入数据行数小于`min_rows_for_compact_part`时，就会以in memory part的形式插入，in memory part的数据暂时不落盘，但会写日志到多个`wal.bin`文件

边缘?

```
    <merge_tree>
        <min_rows_for_compact_part>100</min_rows_for_compact_part> 
        <min_bytes_for_compact_part>104857600</min_bytes_for_compact_part> <!-- 100MB -->
        <in_memory_parts_enable_wal>true</in_memory_parts_enable_wal>
    </merge_tree>
```



```
min_bytes_for_compact_part
min_rows_for_compact_part
write_ahead_log_max_bytes
```



PART

每次写入之后都会额外生成一个part目录, part目录的数据依然可以被查询到, 默认会作为两个table格体输出, 可以通过指定输出格式合并在一个table格体中, 目录名称由`分区ID值_当前合并批次的区块ID最小值(从所在分片的分区顺序值开始)_当前合并批次的区块ID最大值_层级数量` 四层目录组成, 当分区键值为分区函数计算值或者单纯字符串/Float的128为Hash值,插入动作的当前合并批次值由全局计数器维护, 官方建议写入频率低于1次/s 10K-500K 行, 写入频率需要考虑实际业务需要(可用最低延迟)， 批量写入数据时，必须控制每个批次的数据中涉及到的分区的数量、数据行数量、块大小、块内数据有序, 通过调大`background_pool_size`提升资源层供给合并写入性能, 使用更好的磁盘(意味着更贵), 更好的压缩设置, 更好的合并树设置(合并算法等)

少量的未合并的part在查询时会稍慢(随着数量加剧), 如果是多点副本表的话会被同步原始part到另外的副本表上, 同步动作是否同步/异步由同步仲裁值决定

合并是系统后台异步合并, 生成新part会存在内存中一段时间(时间有linux内核参数`/proc/sys/vm/dirty_expire_centisecs`定义, 默认30s)(如何统计这部分的资源值? 挂载共享盘会有问题), 比较消耗CPU/Memory/磁盘(Inode/IOPS/双倍存储量), 默认会在插入动作后的8分钟后执行, 如果未合并的PART过多(超过系统设定值)会引发后续插入失败(exception: too many parts), 合并之后会将原始part删除, 同时也可以通过`optimize TABLE table_name FINAL`指令手动触发系统合并该表的part

启用时会检查Part的完整性



调整以下参数直接影响实际效果

```
    <merge_tree>
        <max_suspicious_broken_parts>5</max_suspicious_broken_parts> <--当数据损坏时可以允许被自动detached的数量->
        <--跟查询有关系->
        <--用来压制活动的(可被查询的)part的数量, 超过数量会导致insert直接报错('Too many parts') ->
        <parts_to_throw_insert>300</parts_to_throw_insert> 
        <--用来梯度延迟插入时间以减少额外part的数量, 什么时候开始延迟插入, 可以看出来默认是50%的时候就会进行延迟插入->
        <parts_to_delay_insert>150</parts_to_delay_insert>
        <--跟插入有关系, 所以可以看出来官方默认实际上并没有对静置环境中的insert做限制->
        <--用来压制非活动part生成的数量, 超过数量会导致insert直接报错('Too many inactive parts')->
        <inactive_parts_to_throw_insert>0</inactive_parts_to_throw_insert>
        <--延迟插入时间以减少非活动part的数量->
        <inactive_parts_to_delay_insert>0</inactive_parts_to_delay_insert>
        <--用来梯度延迟插入时间以减少非活动part的数量, 计算公式为 pow(max_delay_to_insert * 1000, (1 + parts_count_in_partition - parts_to_delay_insert) / (parts_to_throw_insert - parts_to_delay_insert), 默认是从299个活动分区开始会延迟insert语句1秒钟 ->
        <max_delay_to_insert>1</max_delay_to_insert>
        <max_parts_in_total>100000</max_parts_in_total> <--表的所有分区的活动part数量超过定义数量时会直接报错"Too many parts"->
        
        <old_parts_lifetime>480</old_parts_lifetime> <--原始part的延迟处理(合并&删除)时间, 防止内存中的新part在IOPS压力大时没有写入磁盘而服务器意外重启引发丢失, 默认8分钟->
        <max_bytes_to_merge_at_max_space_in_pool>161061273600</max_bytes_to_merge_at_max_space_in_pool> <--限制Part占用磁盘的最大值, 防止块过大, 默认150GB->
        <max_bytes_to_merge_at_min_space_in_pool>1048576</max_bytes_to_merge_at_min_space_in_pool> <--限制Part占用磁盘的最小值, 防止块过小而过多, 默认1MB->
        <merge_max_block_size>8192</merge_max_block_size> <--限制单次从合并的Part读入内存的行数, 防止合并消耗过多的内存资源, 引发系统不可用 ->
        <max_part_loading_threads>auto</max_part_loading_threads> <--ClickHouse 启动时读取部件的最大线程数, 默认值: auto(CPU 核心数) ->
        
      	<merge_tree_clear_old_temporary_directories_interval_seconds>60</merge_tree_clear_old_temporary_directories_interval_seconds> <--设置ClickHouse执行旧临时目录清理的时间间隔 ->
      	<merge_tree_clear_old_parts_interval_seconds>1</merge_tree_clear_old_parts_interval_seconds> <--设置 ClickHouse执行清理旧Part、WAL和Mutation的时间间隔->
        
    </merge_tree>
```

副本复制表中特有的(没有用到复制表则问题不大)

```
    <merge_tree>
    	<--在Zookeeper存储哈希和以检查重复项的最近插入块的数量(FIFO淘汰规则), 即重复检查窗口大小(超过这个窗口数量的重复insert不会认为是重复insert, 不会被去重) ->
        <replicated_deduplication_window>100</replicated_deduplication_window>
        <--非复制MergeTree表中最近插入的块的数量，其中存储了哈希和以检查重复项, 默认0(禁用重复数据删除) ->
        <non_replicated_deduplication_window>0</non_replicated_deduplication_window>
        <--从 Zookeeper 中删除插入块的哈希和之后的秒数, 默认值: 604800(1周), 通过时间约束窗口大小 ->
        <replicated_deduplication_window_seconds>604800</replicated_deduplication_window_seconds>
        <--HTTP连接超时时间->
        <replicated_fetches_http_connection_timeout>0</replicated_fetches_http_connection_timeout>
        <--HTTP发送超时时间->
        <replicated_fetches_http_send_timeout>0</replicated_fetches_http_send_timeout>
        <--HTTP接收超时时间->
        <replicated_fetches_http_receive_timeout>0</replicated_fetches_http_receive_timeout>
        <--限制复制表副本同步及初始化时获取的网络上数据交换的最大速度->
        <max_replicated_fetches_network_bandwidth>0</max_replicated_fetches_network_bandwidth>
        <--限制复制表副本同步及初始化时发送的网络上数据交换的最大速度->
        <max_replicated_sends_network_bandwidth>1</max_replicated_sends_network_bandwidth>
    </merge_tree>
```





调试

查看正在进行的合并

```
SELECT * FROM system.merges
```

合并慢的原因(dmesg / system journals / clickhouse monitoring)

​	增加的插入压力

​	磁盘问题/高负载（运行缓慢，空间不足等）

​	高 CPU 负载（没有足够的 CPU 能力来赶上合并）

​	导致高合并压力的表模式问题（高/增加的表/分区数等）

查看正在进行的mutation

```
SELECT * FROM system.mutations;
```

查看协调器上的信息(zookeeper/clickhouse-keeper)

```
select name, ctime from system.zookeeper
```



#### primary key(主键)

默认为排序键



#### order by(排序)

```
ORDER BY expr
```

默认按照主键进行排序

在批量插入数据时也可以对数据提前进行排序

查询时尽可能结合limit 使用

zorder?

#### partition(分区)

在分区表中, 在查询语句中指定分区键值(分区裁剪器)可以加速查询、减少资源消耗、提高稳定性、提高并发(qps/tps)

同一分区的片段才能合并

能设置分区的表就分区, 例如使用业务时间按照年月日进行分区, 同时也要求查询SQL中必须分区键值

官方不建议单表同时使用的分区数超过1000个, 分区数过多会剧烈消耗文件描述符, 文件描述符值来着系统内核, 同时需要消耗更多的系统资源来承担, 在某种程度上是恒定的, 实际还需要测试一下看看在超过1000个分区数时的性能, 以及分区值唯一+时间YYYYMMDD时的性能对比单纯的YYYYMMDD

```
PARTITION BY (device_partition_value, toYYYYMM(VisitDate))
```

总体超过几十万可能会导致性能下降

由函数和字段组成, 跟MySQL不一样的是并没有限制分区数量

ch作为olap分析场景, 通过时间分区是可以的, 通过数据特征ID (例如设备ID)分区是否合适呢

另外一种可实现方式: 如果业务侧能够冗余一个设备分区值, 通过对设备进行生成对应数值然后取模100作为分区值, 然后作为一级分区规则, 但是实际上貌似并没有意义



##### 调试

查看表的分区信息

```
SELECT
    partition,
    name,
    active
FROM system.parts
WHERE table = 'visits'
```

如果一个分区内有多part, 可以手动触发合并改分区`OPTIMIZE TABLE visits PARTITION 201902;`



#### projection(投影查询)

类似索引, 类似物化视图, 另一角度上可以解决物化视图的数据不一致问题, 同时提高物化视图一般的查询速度

建议使用投影SQL优化定时刷新的业务场景的SQL



边缘:

​	最多几个, 类似于物化视图



```
set allow_experimental_projection_optimization = 1;
ALTER TABLE hits_v1 ADD PROJECTION p1( 
    SELECT 
      WatchID,Title
    ORDER BY WatchID
);

ALTER TABLE hits_v1 ADD PROJECTION agg_p2( 
      SELECT
          UserID, 
          SearchPhrase, 
          count()
        GROUP BY UserID, SearchPhrase
    );
```



##### 底层存储原理

​	投影存储在part目录中。它类似于索引，但包含一个存储匿名`MergeTree`表部分的子目录。该表由投影的定义查询导出。如果有`GROUP BY`子句，则底层存储引

擎变为AggregatingMergeTree，所有聚合函数都转换为`AggregateFunction`. 如果有`ORDER BY`子句，则`MergeTree`表将其用作其主键表达式。在合并过程中，

投影部分通过其存储的合并例程进行合并。父表部分的校验和与投影部分相结合。其他维护作业类似于跳过索引。

​	所以可以看出来跟物化视图一样是增量数据, 如果源表已经有数据了则手动初始化一下`alter table hits_v1 MATERIALIZE PROJECTION p1`

​		通过查询合并状态查看投影查询的初始化状态

```
SELECT table,mutation_id,command,is_done FROM system.mutations WHERE is_done = 0;
SELECT table,mutation_id,command,is_done FROM system.mutations WHERE is_done = 1 and position(command,'PROJECTION') >0;
```

​		通过查询part大小查看实际效果的压缩情况

```
SELECT name,partition,
    formatReadableSize(bytes_on_disk) AS bytes,
    formatReadableSize(parent_bytes_on_disk) AS parent_bytes,
    parent_rows,
    rows / parent_rows AS ratio
FROM system.projection_parts;
```



##### 查询原理

1. 检查投影是否可以用来回答给定的查询，即它生成与查询基表相同的答案。
2. 选择最佳可行匹配，其中包含要读取的最少颗粒。
3. 使用投影的查询管道将不同于使用原始部分的查询管道。如果某些部分没有投影，我们可以添加管道以动态“投影”它



##### 限制

​	不能和FINAL子句一起使用, 对一张 MergeTree 可以创建多个 Projection ，当执行 Select 语句的时候，能根据查询范围，自动匹配最优的 Projection 提供查询加速。如果没有命中 Projection , 就直接查询底表



##### 投影生效原则

​		Where 必须是 PROJECTION 定义中 GROUP BY 的子集

​		GROUP BY 必须是 PROJECTION 定义中 GROUP BY 的子集

​		SELECT 必须是 PROJECTION 定义中 SELECT 的子集

​		匹配多个 PROJECTION 的时候，选取读取 part 最少的

​		返回的数据行小于基表总数

​		查询覆盖的分区 part 超过一半



##### 删除

```
ALTER TABLE hits_v1 DROP PROJECTION p1;
```



#### TTL

TTL全称Time To Live(存活时间), 表可以设置一个用于移除过期行的表达式，以及多个用于在磁盘或卷上自动转移数据片段的表达式; 当表中的行过期时，ClickHouse 会删除所有对应的行。对于数据片段的转移特性，必须所有的行都满足转移条件

底层对应分区内的`ttl.txt` 文件, 保存了列和表的最大最小值以及表达式计算之后的时间戳, 当分区进行合并时会根据TTL规则清理数据, 清理数据可以导致`.bin`等文件删除, 由专门任务队列轮询检测(由`merge_with_ttl_timeout `系统参数定义, 默认86400s, 即1天)、触发执行, 或者手动检测执行TTL(`OPTIMIZE TABLE table_with_ttl FINAL;`)

```
TTL expr
    [DELETE|TO DISK 'xxx'|TO VOLUME 'xxx'][, DELETE|TO DISK 'aaa'|TO VOLUME 'bbb'] ...
    [WHERE conditions]
    [GROUP BY key_expr [SET v1 = aggr_func(v1) [, v2 = aggr_func(v2) ...]] ]
```

或者后续修改

```
# 修改TTL
ALTER TABLE table_name MODIFY TTL ttl_expression;

# 删除TTL
ALTER TABLE table_name REMOVE TTL;
```

可以通过`SYSTEM STOP/START TTL MERGES` 控制全局TTL任务运行状态, 通过`SYSTEM STOP/START TTL MERGES table_name`控制指定表的TTL任务运行状态



#### Codecs(编解码)

使用合适的编解码方式可以提升查询/存储效率

### ReplacingMergeTree(替换合并树)&CollapsingMergeTree(折叠合并树)

在一定程度上可以去重, 同一个分区内的同一个Part在写入和合并时可以根据排序键去重, 默认为保留最后一条, 但是可以通过给ReplacingMergeTree传递参数(特点列)以突出排序后特定列的顺序并保留保留最后一个

实现同样的效果的方式是在查询时使用FINAL子句(并行查询), 这样在查询时就会有性能削弱

```
CREATE TABLE [IF NOT EXISTS] [db.]table_name [ON CLUSTER cluster]
(
    name1 [type1] [DEFAULT|MATERIALIZED|ALIAS expr1],
    name2 [type2] [DEFAULT|MATERIALIZED|ALIAS expr2],
    ...
) ENGINE = ReplacingMergeTree([ver])
[PARTITION BY expr]
[ORDER BY expr]
[PRIMARY KEY expr]
[SAMPLE BY expr]
[SETTINGS name=value, ...]
```



| 替换合并树                                                   | 折叠合并树                                                   |
| :----------------------------------------------------------- | :----------------------------------------------------------- |
| + 非常易于使用（总是更换）                                   | - 更复杂（类似于会计，放置“回滚”记录来修复某些问题）         |
| + 不需要存储行的先前状态                                     | - 需要存储（某处）该行的先前状态，或者从表本身中提取它（点查询对 ClickHouse 不好） |
| - 没有删除                                                   | + 支持删除                                                   |
| - w/o FINAL - 你总是可以看到重复的，需要总是“支付” FINAL 性能损失 | + 正确设计的查询可以在没有最终结果的情况下给出正确的结果（即`sum(amount * sign)`，无论您是否重复，都是正确的） |
| - 只有`uniq()`相似的东西可以在物化视图中计算                 | + 可以在物化视图中进行基本计数和求和                         |

### ReplicatedMergeTree(副本合并树)

这里参考上文的副本部分

### Distributed(分布式表)

只是作为逻辑上的表, 底层并不存储数据

分布式表的命名建议以`_all`结尾

暂时建议不要直接向Distributed表写数据, 会有读写放大问题







## Column(列)

使用的类型、列数据存储, 由IColumn(列)接口和Field(单列值, 或者成为行中列)对象组成; IColumn由ColumnString、ColumnArray、ColumnTuple等组成, 包含了insertRangeFrom、insertFrom(插入数据)、cut(分页)、filter(过滤) 等函数; Field内部组合了Null、UInt64、String、Array等数据类型的存储和处理函数; Field存储和查询的序列化动作由IDataType承载, 包含了serializeXxx、deserializeXxx等对等函数

作为元数据会在启动时被加载

底层存储为`Xxx.bin`文件, 由压缩数据块组组成; 通过使用压缩数据块在可行性、收益(性能、高压缩率)、损耗(系统资源、延迟)上达到一个平衡, 并减少直接操作时的额外操作; 压缩数据块由元数据和数据组成; 元数据由CompressionMethod(压缩算法类型UInt8-1字节)、CompressedSize(压缩后的数据大小UInt32-2字节)、UncompressedSize(压缩前的数据大小UInt32-2字节)组成, 可以通过`clickhouse-compressor --stat < Xxx.bin` 看出块数量和压缩前后大小; 压缩数据块大小固定为64KB~1MB, 由`min_compress_block_size` (默认65536)和`max_compress_block_size`(默认1048576)系统参数指定, 一次`index_granularity` 行作为原始块, 小于64KB则等下次累计达到64KB再写入, 大于64KB小于1MB则写入1个块, 如果超过1MB则截断超出部分作为新一次;



边缘:

​	最多几百个。对于数千列，插入/后台合并可能会变得更慢/需要更多 RAM

列类型选择

​	整数数值 优于 浮点数值

​	数值|日期 选择优于 字符串

​	DataTime 选择优于 数值(整形时间戳), CH中DateTime的底层就是时间戳，效率高，可读性好，且转换函数丰富

​	默认值(空/无意义值) 选择优于 Nullable, 因为存储Nullable列时需要 创建|维护|查询 多类多个额外的文件来存储NULL的标记，并且Nullable列无法被索引

字段长度尽可能的小

查询时尽可能避免在查询SQL中做计算, 而是将计算前置在业务层(常量计算)或者将计算后置在业务层(虚拟列计算)

添加列

```
ALTER TABLE [db].name [ON CLUSTER cluster] ADD COLUMN name [type] [default_expr] [AFTER name_after]
```



### Int(整数)

存储数字(整数)

UInt8(TINYINT, BOOL, BOOLEAN, INT1), UInt16(SMALLINT, INT2), UInt32(INT, INT4, INTEGER), UInt64(BIGINT), UInt128, UInt256, Int8, Int16, Int32, Int64, Int128, Int256

有符号边缘:

| 长度 |                           取值范围                           |
| :--: | :----------------------------------------------------------: |
|  8   |                         [-128 : 127]                         |
|  16  |                       [-32768 : 32767]                       |
|  32  |                  [-2147483648 : 2147483647]                  |
|  64  |         [-9223372036854775808 : 9223372036854775807]         |
| 128  | [-170141183460469231731687303715884105728 : 170141183460469231731687303715884105727] |
| 256  | [-57896044618658097711785492504343953926634992332820282019728792003956564819968 : 57896044618658097711785492504343953926634992332820282019728792003956564819967] |

无符号: 从0开始, 取值范围与有符号一样, 即右值x2+1

### Float(浮点数)

额外存储小数位, 计算结果小位数如果过多会四舍五入

Float32,Float64

边缘:

​	Float32(float): 单精度浮点数(7位小数)

​	Float64(double): 双精度浮点数(64位小数)

- 最小: `-Inf` – 负无穷

```
SELECT -0.5 / 0
┌─divide(-0.5, 0)─┐
│            -inf │
└─────────────────┘
```

- 最大: `Inf` – 正无穷

```
SELECT 0.5 / 0
┌─divide(0.5, 0)─┐
│            inf │
└────────────────┘
```

-  `NaN` – 非数字

```
SELECT 0 / 0

┌─divide(0, 0)─┐
│          nan │
└──────────────┘
```



### Decimal(高精度浮点值)

为了保持存储和计算的精度, 并且可以使用专门的数值计算公式, 性能稍低, Decimal128 的运算速度明显慢于 Decimal32/Decimal64, 不同高精度浮点值计算之后的结果的类型会和更高的高精度浮点值保持一致, Float32/Float64可以通过toDecimal转换为Decimal(小心精度丢失问题), 反之亦然, 计算结果小位数如果过多会直接丢弃, 整数位过多会直接异常(`DB::Exception: Scale is out of bounds`)

Decimal(P,S),Decimal32(S),Decimal64(S),Decimal128(S)

其中 P - 精度。有效范围：[1:38]，决定可以有多少个十进制数字（包括分数）。S - 规模。有效范围：[0：P]，决定数字的小数部分中包含的小数位数。

P取值[1:9] 相当于Decimal32(S), P取值[10:18]相当于Decimal64(S), P取值[19:38]相当于Decimal128(S)

小数位取值

​	Decimal32(S) - ( -1 * 10^(9 - S),1*10^(9-S) )

​	Decimal64(S) - ( -1 * 10^(18 - S),1*10^(18-S) )

​	Decimal128(S) - ( -1 * 10^(38 - S),1*10^(38-S) )



### String(字符串)

存储字符, 理论上来讲一切皆可字符, 在CH中并没有长度限制, 声明时的长度并没有实际意义且不受限制, 使用时直接使用String(LONGTEXT, MEDIUMTEXT, TINYTEXT, TEXT, LONGBLOB, MEDIUMBLOB, TINYBLOB, BLOB, VARCHAR, CHAR)即可, 同样可以直接存储字节数组, 存储字符串时建议使用UTF-8编码





### Date(日期)

由Date、Date32、Datetime、Datetime64 组成

通过11位无符号整数时间戳 或者 符合格式的字符串 插入, 底层存储为时间戳

可以通过函数互相转换

​	Date、Date32、Datetime、Datetime64、String

​	https://clickhouse.com/docs/en/sql-reference/functions/date-time-functions/

#### Date

存储年月日, 格式为: YYYY-MM-DD, 本身不额外存储时区(不能通过修改时区修改该值)

边缘: [1970-01-01: 2149-11-11]

##### Date32

边缘: [1925-01-01: 2283-11-11]

#### Datetime

存储年月日时分秒, 格式为: `YYYY-MM-DD hh:mm:ss`, 通过声明`DateTime([timezone])` 使用, 底层存储时间戳, 时区信息存储在列的元数据上, 时区创建时如果未声明则默认为系统当前的或者全局配置中的`timezone`, 需要注意存储和查询时的时区对应问题, 默认格式可以通过系统参数`date_time_output_format` 自定义, 或者通过在查询时通过`formatDateTime`函数格式化

精确度: 1秒

边缘: [1970-01-01 00:00:00, 2105-12-31 23:59:59]

#### Datetime64

边缘: [1925-01-01 00:00:00, 2283-11-11 23:59:59]



### AggregateFunction(聚合函数)

聚合函数可以具有实现定义的中间状态，该状态可以序列化为`AggregateFunction(…)`数据类型并存储在表中，通常通过物化视图的方式。产生聚合函数状态的常用方法是调用带有`-State`后缀的聚合函数。以后要得到聚合的最终结果，必须使用`-Merge`后缀相同的聚合函数。

`AggregateFunction(name, types_of_arguments…)`— 参数数据类型

**参数**

- 聚合函数的名称。如果函数是参数化的，也要指定它的参数。
- 聚合函数参数的类型。

**例子**

```
CREATE TABLE t
(
    column1 AggregateFunction(uniq, UInt64),
    column2 AggregateFunction(anyIf, String, UInt8),
    column3 AggregateFunction(quantiles(0.5, 0.9), UInt64)
) ENGINE = ...
```

uniq、 anyIf ( any) + If ) 和quantiles)是 ClickHouse 支持的聚合函数。

数据插入

​	要插入数据，请`INSERT SELECT`与聚合`-State`函数一起使用。

函数示例

```
uniqState(UserID)
quantilesState(0.5, 0.9)(SendTiming)
```

与相应的函数`uniq`和相比`quantiles`，`-State`- 函数返回状态，而不是最终值。换句话说，它们返回一个`AggregateFunction`类型的值。

在`SELECT`查询的结果中，`AggregateFunction`类型的值具有所有 ClickHouse 输出格式的特定于实现的二进制表示。例如，如果将数据转储为`TabSeparated`带有查询的格式`SELECT`，则可以使用`INSERT`查询将这个转储加载回来。

数据查询

从`AggregatingMergeTree`表中选择数据时，使用`GROUP BY`子句和与插入数据时相同的聚合函数，但使用`-Merge`后缀。

带后缀的聚合函数`-Merge`接受一组状态，将它们组合起来，返回完整数据聚合的结果。

例如，以下两个查询返回相同的结果：

```
SELECT uniq(UserID) FROM table
SELECT uniqMerge(state) FROM (SELECT uniqState(UserID) AS state FROM table GROUP BY RegionID)
```



## INDEX(索引)

ch中的索引由分区索引、一级索引、二级索引组成; 一级索引(主键索引)、二级索引(跳数索引)都是稀疏索引 (跳数索引), 稀疏意味着不会对索引值连续建立索引, 而是固定跳跃般的建立索引; 索引值规范: `第一条数据的主键值组_第一个跳跃颗粒度后的主键值组_第二个跳跃颗粒度后的主键值组_...`, 每奇数组称为MarkRange, 查询时会先将查询条件值转化成[-inf:condition_value:+inf]然后递归交集裁剪匹配缩小索引查询区间(递归缩减最小长度由`merge_tree_coarse_index_granularity`定义, 默认值8); 与mysql不同的是ch中索引值存储的是mrk的编号; mrk文件由编号-数据文件偏移信息(Block块序号、块文件起始位置、块文件结束位置)组成; 



作为元数据会在启动时被加载, MRK信息使用LRU(最近最少)缓存淘汰算法, 通过`mark_cache_size` 配置缓存空间最大大小



二级索引边缘:

​	一到十几个。不同类型的索引有不同的惩罚，bloom_filter 比 min_max 索引重 100 倍 在某些时候插入速度会变慢。尝试创建尽可能少的索引。可以将许多列组合成一个索引，该索引适用于任何谓词，但影响较小。





```
SET allow_experimental_data_skipping_indices = 1
INDEX index_name expr TYPE type(...) GRANULARITY granularity_value
```

`type(...)`

- `minmax`
  存储指定表达式的极值（如果表达式是 `tuple` ，则存储 `tuple` 中每个元素的极值），这些信息用于跳过数据块，类似主键。

- `set(max_rows)`
  存储指定表达式的不重复值（不超过 `max_rows` 个，`max_rows=0` 则表示『无限制』）。这些信息可用于检查数据块是否满足 `WHERE` 条件。

- `ngrambf_v1(n, size_of_bloom_filter_in_bytes, number_of_hash_functions, random_seed)`
  存储一个包含数据块中所有 n元短语（ngram） 的 布隆过滤器 。只可用在字符串上。
  可用于优化 `equals` ， `like` 和 `in` 表达式的性能。

- `n` – 短语长度。

- `size_of_bloom_filter_in_bytes` – 布隆过滤器大小，字节为单位。（因为压缩得好，可以指定比较大的值，如 256 或 512）。

- `number_of_hash_functions` – 布隆过滤器中使用的哈希函数的个数。

- `random_seed` – 哈希函数的随机种子。

- `tokenbf_v1(size_of_bloom_filter_in_bytes, number_of_hash_functions, random_seed)`
  跟 `ngrambf_v1` 类似，但是存储的是token而不是ngrams。Token是由非字母数字的符号分割的序列。

- `bloom_filter(bloom_filter([false_positive])` – 为指定的列存储布隆过滤器

  可选参数`false_positive`用来指定从布隆过滤器收到错误响应的几率。取值范围是 (0,1)，默认值：0.025

  支持的数据类型：`Int*`, `UInt*`, `Float*`, `Enum`, `Date`, `DateTime`, `String`, `FixedString`, `Array`, `LowCardinality`, `Nullable`。

  以下函数会用到这个索引： equals, notEquals, in, notIn, has



granularity_value: 多少个index_granularity组成一个索引minmax值, 值越小意味着查询效率越高存储量越大



```
INDEX sample_index (u64 * length(s)) TYPE minmax GRANULARITY 4
INDEX sample_index2 (u64 * length(str), i32 + f64 * 100, date, str) TYPE set(100) GRANULARITY 4
INDEX sample_index3 (lower(str), str) TYPE ngrambf_v1(3, 256, 2, 0) GRANULARITY 4
```



案例

```
CREATE TABLE table_name
(
    u64 UInt64,
    i32 Int32,
    s String,
    ...
    INDEX a (u64 * i32, s) TYPE minmax GRANULARITY 3,
    INDEX b (u64 * length(s)) TYPE set(1000) GRANULARITY 4
) ENGINE = MergeTree()
...;
SELECT count() FROM table WHERE s < 'z'
SELECT count() FROM table WHERE u64 * i32 == 10 AND u64 * length(s) >= 1234
```

分析:

​	索引值对应的就是文件中的数据的位置了, 而在mysql中对应的是id, 在mysql中如果扫描行过多就需要建立索引减少扫描行, 但是在ch中的最小建议扫描行是多少呢

​	跳数索引并不是真正意义上的索引，正常的索引都是让数据按照索引key进行聚集，或者把行号按照索引key聚集起来。而ClickHouse的跳数索引并不会做任何聚集的事情，它只是加速筛选Block的一种手段。以 `INDEX a (u64 * i32) TYPE minmax GRANULARITY 3 `这个索引定义为例，它会对`u64 * i32`列的每3个列存块做一个minmax值统计，统计结果存放在单独的索引文件里。查询在没有`u64 * i32` 跳数索引的情况下，需要扫描全部数据文件，才能找到对应的`u64 * i32`行。有了索引后，数据扫描的逻辑变成了先扫描`u64 * i32`索引文件，检查`u64 * i32`的minmax区间是否覆盖目标值，后续扫描主表的时候可以跳过不相关的Block，这其实就是在OLAP里常用的Block Meta Scan技术, 当`u64 * i32`列存块的minmax区间相对于原始占比很大时，跳数索引就无法起到加速作用，甚至会让查询更慢(因为有额外动作), 在使用组合索引时需要符合最左匹配原则(右列的索引必须在左列存在并生效后生效), 基于索引区分粒度顺序(不是逆序)原则建立索引







几个重要的参数:

`index_granularity` : [最大]固定跳跃距离, 默认值为8192

 `index_granularity_bytes`  : 最大跳跃大小, 默认值10Mb

`min_index_granularity_bytes` : 最小索引粒度大小， 默认值1024b

`enable_mixed_granularity_parts`: 是否启用通过 `index_granularity_bytes` 控制索引粒度的大小。在19.11版本之前, 只有 `index_granularity` 配置能够用于限制索引粒度的大小。当从具有很大的行（几十上百兆字节）的表中查询数据时候，`index_granularity_bytes` 配置能够提升ClickHouse的性能。如果您的表里有很大的行，可以开启这项配置来提升`SELECT` 查询的性能。

```
enable_mixed_granularity_parts
```





## Function(函数)

### uniq

如果业务层不要求精准计算, 则应尽可能使用`uniq`代替使用`uniqExact`、`DISTINCT`





## 语句

### DDL(表定义)

### DML(表修改)

### DQL(表查询)

查询会阻塞表删除

通过

#### JOIN(连接)

能否使用子查询的地方使用子查询而不是join

右表会被全部加载在内存进行连接, 索引需要尽可能小

#### SUBQUERY(子查询)

全局子查询需要手动带distinct

### 



## 系统

### fsync

对于数据库来说稳定写入是最重要的

需要对比sync和async的

​	1、性能差异

​	2、稳定性差异, 什么情况下会丢失数据、能不能完全避免(当不稳定丢失多少数据、能否精准修复、修复成本)



以下是官方文档中摘抄出来整理的系统参数:

可以看出来默认就是稳定写入的, 创建表时可以覆盖以下参数、也可以在服务器级设置参数

------------------------------------------------------------------------------------------------------------------------------------------- exporte_data

output_format_avro_sync_interval

​	设置输出 Avro 文件的同步标记之间的最小数据大小（以字节为单位）。

​	类型：无符号整数

​	可能的值：32（32 字节）- 1073741824（1 GiB）

​	默认值：32768 (32 KiB)

------------------------------------------------------------------------------------------------------------------------------------------- metadata

fsync_metadata

​	写入文件时启用或禁用fsync 。.sql默认启用。

​	如果服务器有数百万个不断被创建和销毁的小表，那么禁用它是有意义的。

------------------------------------------------------------------------------------------------------------------------------------------- ddl

replication_alter_partitions_sync=2

​	允许设置等待通过ALTER、OPTIMIZE或TRUNCATE查询在副本上执行的操作。

​	可能的值：

​	0 — 不要等待。

​	1 — 等待自己的执行。

​	2 — 等待所有人。

​	默认值：1。

database_atomic_wait_for_drop_and_detach_synchronously=1

​	SYNC为所有DROP和DETACH查询添加修饰符。

​	可能的值：

​	0 — 查询将延迟执行。

​	1 — 查询将立即执行。

​	默认值：0。

------------------------------------------------------------------------------------------------------------------------------------------- distributed

fsync_after_insert

​	数据同步插入

fsync_directories

​	元数据同步

insert_distributed_sync=1

​	启用或禁用同步数据插入到分布式表中。

​	默认情况下，向Distributed表中插入数据时，ClickHouse 服务器以异步方式向集群节点发送数据。当 时insert_distributed_sync=1，数据是同步处理的，只有在所有分片上保存所有数据（如果为真INSERT，每个分片至少有一个副本），操作成功。internal_replication

​	可能的值：

​	0 — 数据以异步模式插入。

​	1 — 数据以同步模式插入。

​	默认值：0。

​	也可以看看

​	分布式表引擎

​	管理分布式表

------------------------------------------------------------------------------------------------------------------------------------------- insert-sync

async-insert=0 

​	启用或禁用异步插入。这仅对通过 HTTP 协议的插入有意义。请注意，重复数据删除不适用于此类插入。

​	如果启用，数据在插入表之前会被组合成批次，因此可以在没有缓冲表的情况下对 ClickHouse 进行小而频繁的插入（每秒最多 15000 次查询）。

​	在超出 async_insert_max_data_size 或自第一次查询以来的 async_insert_busy_timeout_ms 毫秒后插入数据。INSERT如果 async_insert_stale_timeout_ms 设置为非零值，则在 async_insert_stale_timeout_ms 自上次查询后的毫秒后插入数据。

​	如果启用了 wait_for_async_insert ，则每个客户端都将等待数据被处理并刷新到表中。否则，即使没有插入数据，查询也会几乎立即被处理。

​	可能的值：

​	0 — 插入是同步进行的，一个接一个。

​	1 — 启用多个异步插入。

​	默认值：0。

wait_for_async_insert=1

​	启用或禁用等待异步插入的处理。如果启用，服务器将OK仅在插入数据后返回。否则，OK即使没有插入数据，它也会返回。

​	可能的值：

​	0 —OK即使尚未插入数据，服务器也会返回。

​	1 — 服务器OK仅在插入数据后返回。

​	默认值：1。

------------------------------------------------------------------------------------------------------------------------------------------- insert-async

async_insert_threads

​	后台数据解析和插入的最大线程数。

​	可能的值：

​	正整数。

​	0 — 禁用异步插入。

​	默认值：16。

wait_for_async_insert_timeout

​	等待异步插入处理的超时时间（以秒为单位）。

​	可能的值：

​	正整数。

​	0 — 禁用。

​	默认值：lock_acquire_timeout。

async_insert_max_data_size

​	在插入之前，每个查询收集的未解析数据的最大大小（以字节为单位）。

​	可能的值：

​	正整数。

​	0 — 禁用异步插入。

​	默认值：1000000。

async_insert_busy_timeout_ms

​	INSERT自插入收集的数据之前第一次查询以来的最大超时时间（以毫秒为单位） 。

​	可能的值：

​	正整数。

​	0 — 禁用超时。

​	默认值：200。

async_insert_stale_timeout_ms

​	INSERT在转储收集的数据之前，自上次查询以来的最大超时时间（以毫秒为单位） 。如果启用，只要不超过 async_insert_max_data_size ，该设置就会在每次查询时延长 async_insert_busy_timeout_ms 。INSERT

​	可能的值：

​	正整数。

​	0 — 禁用超时。

​	默认值：0。

### THREAD(线程)

clickhouse中运行的最小单元是线程, 在使用了线程池优化了线程使用

#### 通过以下参数进行控制线程池的使用

```
SELECT
    name,
    value
FROM system.settings
WHERE name LIKE '%pool%'

┌─name─────────────────────────────────────────┬─value─┐
│ connection_pool_max_wait_ms                  │ 0     │
│ distributed_connections_pool_size            │ 1024  │
│ background_buffer_flush_schedule_pool_size   │ 16    │
│ background_pool_size                         │ 16    │
│ background_move_pool_size                    │ 8     │
│ background_fetches_pool_size                 │ 8     │
│ background_schedule_pool_size                │ 16    │
│ background_message_broker_schedule_pool_size │ 16    │
│ background_distributed_schedule_pool_size    │ 16    │
│ postgresql_connection_pool_size              │ 16    │
│ postgresql_connection_pool_wait_timeout      │ -1    │
│ odbc_bridge_connection_pool_size             │ 16    │
└──────────────────────────────────────────────┴───────┘
```

#### 观察

##### 系统的指标参数

```
SELECT
    metric,
    value
FROM system.metrics
WHERE metric LIKE 'Background%'

┌─metric──────────────────────────────────┬─value─┐
│ BackgroundPoolTask                      │     0 │
│ BackgroundFetchesPoolTask               │     0 │
│ BackgroundMovePoolTask                  │     0 │
│ BackgroundSchedulePoolTask              │     0 │
│ BackgroundBufferFlushSchedulePoolTask   │     0 │
│ BackgroundDistributedSchedulePoolTask   │     0 │
│ BackgroundMessageBrokerSchedulePoolTask │     0 │
└─────────────────────────────────────────┴───────┘


SELECT *
FROM system.asynchronous_metrics
WHERE lower(metric) LIKE '%thread%'
ORDER BY metric ASC

┌─metric───────────────────────────────────┬─value─┐
│ HTTPThreads                              │     0 │
│ InterserverThreads                       │     0 │
│ MySQLThreads                             │     0 │
│ OSThreadsRunnable                        │     2 │
│ OSThreadsTotal                           │  2910 │
│ PostgreSQLThreads                        │     0 │
│ TCPThreads                               │     1 │
│ jemalloc.background_thread.num_runs      │     0 │
│ jemalloc.background_thread.num_threads   │     0 │
│ jemalloc.background_thread.run_intervals │     0 │
└──────────────────────────────────────────┴───────┘


SELECT *
FROM system.metrics
WHERE lower(metric) LIKE '%thread%'
ORDER BY metric ASC

Query id: 6acbb596-e28f-4f89-94b2-27dccfe88ee9

┌─metric─────────────┬─value─┬─description───────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ GlobalThread       │   151 │ Number of threads in global thread pool.                                                                          │
│ GlobalThreadActive │   144 │ Number of threads in global thread pool running a task.                                                           │
│ LocalThread        │     0 │ Number of threads in local thread pools. The threads in local thread pools are taken from the global thread pool. │
│ LocalThreadActive  │     0 │ Number of threads in local thread pools running a task.                                                           │
│ QueryThread        │     0 │ Number of query processing threads                                                                                │
└────────────────────┴───────┴───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

##### 查询正在运行中的线程

```
SELECT query, length(thread_ids) AS threads_count FROM system.processes ORDER BY threads_count;
```

##### 在系统上查看运行的线程

```
# 计算 clickhouse-server 使用的线程数
cat /proc/$(pidof -s clickhouse-server)/status | grep Threads
Threads: 103

ps hH $(pidof -s clickhouse-server) | wc -l
103

ps hH -AF | grep clickhouse | wc -l
116

# 按类型划分的线程数（使用 ps 和 clickhouse-local）
ps H -o 'tid comm' $(pidof -s clickhouse-server) |  tail -n +2 | awk '{ printf("%s\t%s\n", $1, $2) }' | clickhouse-local -S "threadid UInt16, name String" -q "SELECT name, count() FROM table GROUP BY name WITH TOTALS ORDER BY count() DESC FORMAT PrettyCompact"
```

##### 查看线程的堆栈信息

```
# 来自池的工作线程的堆栈跟踪
SET allow_introspection_functions = 1;

WITH arrayMap(x -> demangle(addressToSymbol(x)), trace) AS all
SELECT
    thread_id,
    query_id,
    arrayStringConcat(all, '\n') AS res
FROM system.stack_trace
WHERE res ILIKE '%Pool%'
FORMAT Vertical;

```



### 内存

查看内存被使用情况

```
SELECT *, formatReadableSize(value) FROM system.asynchronous_metrics WHERE metric like '%Cach%' or metric like '%Mem%' order by metric format PrettyCompactMonoBlock;

SELECT event_time, metric, value, formatReadableSize(value) FROM system.asynchronous_metric_log WHERE event_time > now() - 600 and (metric like '%Cach%' or metric like '%Mem%') and value <> 0 order by metric, event_time format PrettyCompactMonoBlock;

SELECT formatReadableSize(sum(bytes_allocated)) FROM system.dictionaries;

SELECT
    database,
    name,
    formatReadableSize(total_bytes)
FROM system.tables
WHERE engine IN ('Memory','Set','Join');

SELECT formatReadableSize(sum(memory_usage)) FROM system.merges;

SELECT formatReadableSize(sum(memory_usage)) FROM system.processes;

SELECT
    initial_query_id,
    elapsed,
    formatReadableSize(memory_usage),
    formatReadableSize(peak_memory_usage),
    query
FROM system.processes
ORDER BY peak_memory_usage DESC
LIMIT 10;

SELECT
    metric,
    formatReadableSize(value)
FROM system.asynchronous_metrics
WHERE metric IN ('UncompressedCacheBytes', 'MarkCacheBytes');

SELECT
    formatReadableSize(sum(primary_key_bytes_in_memory)) AS primary_key_bytes_in_memory,
    formatReadableSize(sum(primary_key_bytes_in_memory_allocated)) AS primary_key_bytes_in_memory_allocated
FROM system.parts;

SELECT
    type,
    event_time,
    initial_query_id,
    formatReadableSize(memory_usage),
    query
FROM system.query_log
WHERE (event_date >= today()) AND (event_time >= (now() - 7200))
ORDER BY memory_usage DESC
LIMIT 10;

```



```
for i in `seq 1 600`; do clickhouse-client --empty_result_for_aggregation_by_empty_set=0 -q "select (select 'Merges: \
'||formatReadableSize(sum(memory_usage)) from system.merges), (select \
'Processes: '||formatReadableSize(sum(memory_usage)) from system.processes)";\
sleep 3;  done 

Merges: 96.57 MiB	Processes: 41.98 MiB
Merges: 82.24 MiB	Processes: 41.91 MiB
Merges: 66.33 MiB	Processes: 41.91 MiB
Merges: 66.49 MiB	Processes: 37.13 MiB
Merges: 67.78 MiB	Processes: 37.13 MiB

```



```
echo "         Merges      Processes       PrimaryK       TempTabs          Dicts"; \
for i in `seq 1 600`; do clickhouse-client --empty_result_for_aggregation_by_empty_set=0  -q "select \
(select leftPad(formatReadableSize(sum(memory_usage)),15, ' ') from system.merges)||
(select leftPad(formatReadableSize(sum(memory_usage)),15, ' ') from system.processes)||
(select leftPad(formatReadableSize(sum(primary_key_bytes_in_memory_allocated)),15, ' ') from system.parts)|| \
(select leftPad(formatReadableSize(sum(total_bytes)),15, ' ') from system.tables \
 WHERE engine IN ('Memory','Set','Join'))||
(select leftPad(formatReadableSize(sum(bytes_allocated)),15, ' ') FROM system.dictionaries)
"; sleep 3;  done 

         Merges      Processes       PrimaryK       TempTabs          Dicts
         0.00 B         0.00 B      21.36 MiB       1.58 GiB     911.07 MiB
         0.00 B         0.00 B      21.36 MiB       1.58 GiB     911.07 MiB
         0.00 B         0.00 B      21.35 MiB       1.58 GiB     911.07 MiB
         0.00 B         0.00 B      21.36 MiB       1.58 GiB     911.07 MiB


```



### 存储

考量因素为存储量、IOPS(这里需要好好计算一下)

CH中的默认存储点由配置文件中的`<PATH>/var/lib/clickhouse/</PATH>` 指定, 创建目录时注意权限问题, `chown clickhouse:clickhouse -R /root`, 由disks和storage_policies组成

#### system.disks(磁盘)

通过`system.disks`表可以查询系统加载到的磁盘系统, 系统默认配置的磁盘名为`default`

- `name`( String ) — 服务器配置中磁盘的名称
- `path`( String ) — 文件系统中挂载点的路径
- `free_space`( UInt64) — 磁盘上的可用空间（以字节为单位）
- `total_space`( UInt64) — 以字节为单位的磁盘容量
- `keep_free_space`( UInt64) — 应在磁盘上保持空闲的磁盘空间量（以字节为单位）,`keep_free_space_bytes`在磁盘配置参数中定义



```
<storage_configuration>
    <disks>
        <disk_hot1>
            <path>/root/hotdata1/</path>
        </disk_hot1>
        <disk_hot2>
            <path>/root/hotdata2/</path>
        </disk_hot2>	
        <disk_cold>
            <path>/root/colddata/</path>
            <keep_free_space_bytes>1073741824</keep_free_space_bytes>
        </disk_cold>  
    </disks>
</storage_configuration>
```



#### system.storage_policies(存储策略)

通过`system.storage_policies`表可以查询存储策略, 表引用的存储策略默认为`default`, 可以在创建表时指定`SETTINGS storage_policy = <my_storage_policy>`, 一经指定便无法修改, 但是却可以通过移动分区数据到其他磁盘/卷达到部分修改效果`ALTER TABLE hot_cold_table MOVE PART 'all_1_2_1' TO DISK 'disk_hot1'` / `ALTER TABLE hot_cold_table MOVE PART 'all_1_2_1' TO VOLUME 'cold'`

- `policy_name`( String ) — 存储策略的名称
- `volume_name`( String ) — 存储策略中定义的卷名
- `volume_priority`( UInt64) — 配置中的卷序号，数据按此优先级填充卷，即插入和合并期间的数据写入优先级较低的卷（考虑其他规则：TTL，，，`max_data_part_size`）`move_factor`
- `disks`( Array(String)) — 磁盘名称，在存储策略中定义
- `max_data_part_size`( UInt64 ) — 可以存储在卷磁盘上的数据部分的最大大小（0 — 无限制）
- `move_factor`( Float64) — 可用磁盘空间的比率。当比率超过配置参数的值时，ClickHouse 开始按顺序将数据移动到下一个卷
- `prefer_not_to_merge`( UInt8 ) — 设置的值`prefer_not_to_merge`，启用此设置后，不允许合并此卷上的数据，这允许控制 ClickHouse 如何处理慢速磁盘，如果存储策略包含多个卷，则每个卷的信息都存储在表的单独行中



通过存储策略的调整可以不同的集群存储效果



##### 磁盘分片

类似JBOD(磁盘堆), 全称Just a Bunch of Disks, 利用多分区轮询存储多磁盘机制, 在应用层实现集群存储

```
<storage_configuration>	
    <policies>
        <jbod_policies>
            <volumes>
                <jbod>
                    <disk>disk_hot1</disk>
                    <disk>disk_hot2</disk>
                </jbod>
            </volumes>
        </jbod_policies>
    </policies>
</storage_configuration>
```



##### 磁盘下沉

类似HOT/COLD(冷热), 冷热分离, 可以加速查询、减少存储成本、加强稳定性、提高安全性; 但是实际上却不能实现符合业务特点的冷热分离(非今年的数据不放在默认磁盘卷上而是在S3/HDD这种), 在storage_policies上定义的move_factor百分比不能很精确的对应每个表的今年的时间点位置的磁盘占用比, 而且当在磁盘组添加一个新的磁盘后, 新的磁盘上由于没有权重, 存储量将远远小于老的磁盘, 而且这个时候如果触发存储下沉那么是否是导致最近的数据被移动到低级磁盘上，导致查询出现问题, 从而引起系统不可用

**实现符合业务特点、且无损害的冷热分离需要参考TTL**



```
<storage_configuration>
    <policies>
        <moving_from_hot_to_cold>
            <volumes>
                <hot>
                    <disk>disk_hot1</disk>
                </hot>
                <cold>
                    <disk>disk_cold</disk>
                </cold>
            </volumes>
            <move_factor>0.2</move_factor>
        </moving_from_hot_to_cold>
    </policies>
</storage_configuration>
```



通过`system.part_log ` 、`system.parts` 查询移动状态和进度



# 系统配置

https://clickhouse.com/docs/zh/operations/server-configuration-parameters/settings/



## 用户







# 查询

## prewhere

相比于where, 会先仅仅是取出prewhere表达式的列去过滤



# 使用

存储从单一来源注册的许多指标的最佳模式(暂时没有很看明白)

参考文档: https://kb.altinity.com/altinity-kb-schema-design/best-schema-for-storing-many-metrics-registered-from-the-single-source/

## 创建

​	排序、索引、分区

​		https://kb.altinity.com/engines/mergetree-table-engine-family/pick-keys/

​	列编码

​		https://kb.altinity.com/altinity-kb-schema-design/codecs/altinity-kb-how-to-test-different-compression-codecs/



## 查询

https://kb.altinity.com/altinity-kb-queries-and-syntax/

```
SET max_block_size = '16k';
```



## 优化

为每一个账户添加join_use_nulls配置，左表中的一条记录在右表中不存在，右表的相应字段会返回该字段相应数据类型的默认值，而不是标准SQL中的Null值

JOIN操作时一定要把数据量小的表放在右边，ClickHouse中无论是Left Join 、Right Join还是Inner Join永远都是拿着右表中的每一条记录到左表中查找该记录是否存在，所以右表必须是小表

尽量减少JOIN时的左右表的数据量，必要时可以提前对某张表进行聚合操作，减少数据条数。有些时候，先GROUP BY再JOIN比先JOIN再GROUP BY查询时间更短

当两表关联查询只需要从左表出结果时，建议用IN而不是JOIN，即写成`SELECT ... FROM left_table WHERE join_key IN (SELECT ... FROM right_table)`的风格

CH的查询优化器比较弱，JOIN操作的谓词不会下推，因此**要尽量减少JOIN时的左右表的数据量**，必要时可以提前对某张表进行聚合操作，减少数据条数，**即一**

**定要先做完过滤、聚合等操作，再在结果集上做JOIN**

两张分布式表上的IN和JOIN之前必须加上GLOBAL关键字。如果不加GLOBAL关键字的话，每个节点都会单独发起一次对右表的查询，而右表又是分布式表，就导

致右表一共会被查询N2次（N是该分布式表的shard数量），这就是所谓的查询放大，会带来不小的overhead。加上GLOBAL关键字之后，右表只会在接收查询请

求的那个节点查询一次，并将其分发到其他节点上

不把所有业务逻辑计算都写在SQL中、不使用大SQL



# 部署

## 版本

​	https://kb.altinity.com/altinity-kb-setup-and-maintenance/clickhouse-versions/

​	https://clickhouse.com/docs/zh/faq/operations/production/

​	product(生产)环境 < PET(性能压测)环境 < QA(质量验收)环境需要保持节奏

​	通常来说生产环境应该仅使用LTS(长期支持)版本, 但是当LTS出现严重受损时需要升级切换为stable版本

​		安全、稳定、严重性能、性能、公共功能、功能

​	DEV、对照环境无论如何都可以使用stable(已验证)版本、prestable(预可用)、testing(测试中)

​	升级版本时需要仔细阅读`changelog`

​	在github(https://github.com/clickhouse/clickhouse)存储仓库上的tags列表通过搜索`lts` 或者 `stable` 查询lts和stable的具体版本, 以及在dockerhub(https://hub.docker.com/r/clickhouse/clickhouse-server/tags)上搜索具体镜像tag



## 实例

一个就够了。单个 ClickHouse 可以非常有效地使用节点的资源，并且可能需要一些复杂的调整才能在单个节点上运行多个实例



## 配置文件

https://kb.altinity.com/altinity-kb-setup-and-maintenance/altinity-kb-server-config-files/

config.xml

```
<!-- Maximum number of threads in the Global thread pool.-->
<max_thread_pool_size>10000</max_thread_pool_size>
```

users.xml

```
<background_pool_size>64</background_pool_size>
<!--300秒也就是5分钟超时-->
<max_execution_time>300</max_execution_time>
<!--超时即杀掉:throw :break-->
<timeout_overflow_mode>throw</timeout_overflow_mode>
<max_threads>20</max_threads>
<max_bytes_before_external_group_by></max_bytes_before_external_group_by>53687091200
<!--单查询内存数,100G-->
<max_memory_usage>107374182400</max_memory_usage>
<!--总内存数,120G-->         
<max_memory_usage_for_all_queries>120849018880</max_memory_usage_for_all_queries>
<!-- Use cache of uncompressed blocks of data. Meaningful only for processing many of very short queries. -->
<use_uncompressed_cache>0</use_uncompressed_cache>
<join_use_nulls>0</join_use_nulls>
```

计划

​	https://kb.altinity.com/altinity-kb-setup-and-maintenance/clickhouse-deployment-plan/



容器环境中资源限制问题

​	https://github.com/ClickHouse/ClickHouse/issues/2261



优化

关闭虚拟内存，物理内存和虚拟内存的数据交换，会导致查询变慢



## 在K8S上部署

https://github.com/Altinity/clickhouse-operator/tree/master/docs/chi-examples

https://github.com/Altinity/clickhouse-operator/blob/eb3fc4e28514d0d6ea25a40698205b02949bcf9d/docs/chi-examples/03-persistent-volume-07-do-not-chown.yaml



# 监控

## 整体

### 状态

CPU一般在50%左右会出现查询波动，达到70%会出现大范围的查询超时

内存、磁盘(存储量)、网络

要根据请求特点及目前数据量分布情况提前预估好底层资源以维持可用

如果iops不够: 升级磁盘规格、通过分片打散到不同磁盘集群上、使用分布式存储自动打散到不同的磁盘、升级存储网络

#### 采集端点

​	启用内置的prometheus采集端点

​		https://clickhouse.com/docs/en/operations/server-configuration-parameters/settings/#server_configuration_parameters-prometheus

```
 	<prometheus>
        <endpoint>/metrics</endpoint>
        <port>8001</port>
        <metrics>true</metrics>
        <events>true</events>
        <asynchronous_metrics>true</asynchronous_metrics>
    </prometheus>
```

​	或者使用clickhouse-exporter(并结合对应的grafana-dashboard)

​		https://github.com/ClickHouse/clickhouse_exporter



#### 使用grafana-dashboard查询查看

​	https://grafana.com/grafana/dashboards/14192

​	https://github.com/Altinity/clickhouse-operator/tree/master/grafana-dashboard



#### 告警规则

​	https://github.com/Altinity/clickhouse-operator/blob/master/deploy/prometheus/prometheus-alert-rules-clickhouse.yaml

​	https://github.com/Altinity/clickhouse-operator/blob/master/deploy/prometheus/prometheus-alert-rules-zookeeper.yaml

​	

#### 其他

https://kb.altinity.com/altinity-kb-setup-and-maintenance/altinity-kb-monitoring/

https://clickhouse.com/docs/en/operations/monitoring/

https://www.ibm.com/docs/en/obi/current?topic=technologies-monitoring-clickhouse

https://docs.google.com/spreadsheets/d/1K92yZr5slVQEvDglfZ88k_7bfsAKqahY9RPp_2tSdVU/edit#gid=521173956

https://kb.altinity.com/altinity-kb-setup-and-maintenance/altinity-kb-settings-to-adjust/



### 性能

打开数据采集

```
  <!-- Profiles of settings. -->
    <profiles>
        <!-- Default settings. -->
        <default>
             <log_queries>1</log_queries>
```

展示

https://grafana.com/grafana/dashboards/13606

https://grafana.com/grafana/dashboards/2515



#### opentelemetry

https://clickhouse.com/docs/en/operations/opentelemetry/

当前的支持并没有很多，但是可以尝试一下看看效果



### 日志



## 细节

DDL进度监控

​	https://kb.altinity.com/altinity-kb-queries-and-syntax/altinity-kb-alter-modify-column-is-stuck-the-column-is-inaccessible/

系统表

​	https://clickhouse.com/docs/en/operations/system-tables/#system_tables-replicas







# 维护

## 优雅下线

https://kb.altinity.com/altinity-kb-setup-and-maintenance/altinity-kb-shutting-down-a-node/

https://github.com/ClickHouse/ClickHouse/blob/master/programs/server/Server.cpp#L1353

1、从负载均衡列表中删除当前节点, 切断外部查询SQL

2.1、等待当前副本的查询语句结束(`SHOW PROCESSLIST;`)

2.2、将当前副本的数据同步到其他节点(`SYSTEM SYNC REPLICA db.table;`)

3、通过系统指令关闭副本(`SYSTEM SHUTDOWN;`)



## 优雅上线

进程正常运行

副本表进度同步正常 



## 系统参数

https://clickhouse.com/docs/en/operations/settings/settings/

https://clickhouse.com/docs/en/operations/settings/merge-tree-settings/



## 系统日志

https://kb.altinity.com/altinity-kb-setup-and-maintenance/altinity-kb-system-tables-eat-my-disk/



由asynchronous_metric_log、metric_log、query_thread_log、query_log、query_views_log、part_log、session_log、text_log、trace_log、crash_log、opentelemetry_span_log、zookeeper_log组成

可以关闭(非常不推荐), 在权衡磁盘存储与系统消耗来看, 为以上系统日志表设置TTL是更好的办法

```
ALTER TABLE system.query_log MODIFY SETTING ttl_only_drop_parts = 1;
ALTER TABLE system.query_log MODIFY TTL event_date + INTERVAL 14 DAY;
```



### query_log

可以通过以下参数更加详细的控制

```
name                              | value       | description                                                                                                                                                       
----------------------------------+-------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------
log_queries_min_type              | QUERY_START | Minimal type in query_log to log, possible values (from low to high): QUERY_START, QUERY_FINISH, EXCEPTION_BEFORE_START, EXCEPTION_WHILE_PROCESSING.
log_queries_min_query_duration_ms | 0           | Minimal time for the query to run, to get to the query_log/query_thread_log.
log_queries_cut_to_length         | 100000      | If query length is greater than specified threshold (in bytes), then cut query when writing to query log. Also limit length of printed query in ordinary text log.
log_profile_events                | 1           | Log query performance statistics into the query_log and query_thread_log.
log_query_settings                | 1           | Log query settings into the query_log.
log_queries_probability           | 1           | Log queries with the specified probabality.

```



# 疑问

## 集群

目前路由规则是在客户端做的, 但是实际上应该在集群代理层面做





## 分片

### 分布式表在分发时会有放大问题, 但是如果是重定向的话会不会更好?

上游要保证一个包在一个分片上, redis可以基于key做hash, 但是SQL貌似有点难, 但是如果拓展专门定义了分片规则及值(代表着hash(key))那么是否可以实现ch 第1端的快速重定向(解包、解析、判断)

类似于redis cluster

### 如何扩容

如果底层是分布式存储的话, 在达到一定量之前可以通过扩大存储供给量扩大磁盘(存储量/IOPS), 通过多副本扩大集群查询需要的CPU、内存、线程、内核资源

同时可以在系统配置文件中定义历史数据存储的地方, 实现冷数据自动迁移

### 扩容如何平衡

映射槽(动态权重、可用状态)、重定向(路由)

## 副本

### 生产环境下异地部署

例如部署在三个机房

那么需要声明三个副本并分别运行在3个机房中, 1个机房中含有整体数据的所有分片, 为满足当查询所有分片时跨所有机房的前提做铺垫, 并且当一个机房出现问题时不会导致整体服务不可用

## 表

### 分区

### ch作为olap分析场景, 通过时间分区是可以的, 通过数据特征ID (例如设备ID)分区是否合适呢

写入是没什么问题的, 但是查询要考虑实际情况, 看看是否有数据上卷的操作, 如果有数据上卷则会跨区提高并行程度



## 存储

### 如何自动扩容以及平衡

当达到80%时自动扩容1倍





# 参考文档

https://clickhouse.com/docs/zh/
