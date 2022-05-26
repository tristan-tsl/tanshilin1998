# Ceph调优

更新时间：2021/03/18 GMT+08:00

[查看PDF](https://support.huaweicloud.com/tngg-kunpengsdss/kunpengsdss-tngg.pdf)

[分享](javascript:void(0);)

#### Ceph配置调优

- 目的

  通过调整Ceph配置选项，最大化利用系统资源。

- 方法

  所有的ceph配置参数都是通过修改/etc/ceph/ceph.conf实现的。比方说要修改默认副本数为4，则在/etc/ceph/ceph.conf文件中添加osd_pool_default_size = 4这一行字段，然后**systemctl restart ceph.target**重启Ceph守护进程使之生效。

  以上操作只是对当前Ceph节点生效，需要修改所有Ceph节点的ceph.conf文件并重启Ceph守护进程才对整个Ceph集群生效。Ceph参数优化项如[表1](https://support.huaweicloud.com/tngg-kunpengsdss/kunpengcephobject_05_0008.html#kunpengcephobject_05_0008__zh-cn_topic_0185390465_table175574113129)所示：

  

  | 参数名称        | 参数说明                                                     | 优化建议                                     |
  | --------------- | ------------------------------------------------------------ | -------------------------------------------- |
  | **[global]**    |                                                              |                                              |
  | cluster_network | 配置一层不同于public network的网段，用于OSD间副本复制/数据均衡，缓解public network网络压力。 | 修改建议：192.168.4.0/24，不同于public即可。 |
  | public_network  | 修改建议：192.168.3.0/24，不同于cluster即可。                |                                              |

  其他配置选项优化可参考[表2](https://support.huaweicloud.com/tngg-kunpengsdss/kunpengcephobject_05_0008.html#kunpengcephobject_05_0008__zh-cn_topic_0185390465_table1822794911165)。

  

  | 参数名称                           | 参数含义                                                     | 优化建议                                     |
  | ---------------------------------- | ------------------------------------------------------------ | -------------------------------------------- |
  | **[global]**                       |                                                              |                                              |
  | osd_pool_default_min_size          | PG处于degraded状态不影响其IO能力，**“min_size”**是一个PG能接受IO的最小副本数。 | 默认值：0修改建议：1                         |
  | cluster_network                    | 配置一层不同于public network的网段，用于OSD间副本复制/数据均衡，缓解public network网络压力。 | 修改建议：192.168.4.0/24                     |
  | osd_pool_default_size              | 副本数设置。                                                 | 默认值：3修改建议：3                         |
  | osd_memory_target                  | 该选项设置了每个OSD进程能申请到的内存大小。                  | 默认值：4294967296修改建议：4294967296       |
  | **[mon]**                          |                                                              |                                              |
  | mon_clock_drift_allowed            | monitor间的clock drift。                                     | 默认值：0.05修改建议：1                      |
  | mon_osd_min_down_reporters         | 向monitor报告down的最小OSD数。                               | 默认值：2修改建议：13                        |
  | mon_osd_down_out_interval          | 标记一个OSD状态为down和out之前ceph等待的秒数。               | 默认值：600修改建议：600                     |
  | **[OSD]**                          |                                                              |                                              |
  | osd_journal_size                   | osd journal大小。                                            | 默认值：5120修改建议：20000                  |
  | osd_max_write_size                 | OSD一次可写入的最大值（MB）。                                | 默认值：90修改建议：512                      |
  | osd_client_message_size_cap        | 客户端允许在内存中的最大数据（Bytes）。                      | 默认值：100修改建议：2147483648              |
  | osd_deep_scrub_stride              | 在Deep Scrub时候允许读取的字节数（Bytes）。                  | 默认值：524288修改建议：131072               |
  | osd_map_cache_size                 | 保留OSD Map的缓存（MB）。                                    | 默认值：50修改建议：1024                     |
  | osd_recovery_op_priority           | 恢复操作优先级，取值1-63，值越高占用资源越高。               | 默认值：3修改建议：2                         |
  | osd_recovery_max_active            | 同一时间内活跃的恢复请求数。                                 | 默认值：3修改建议：10                        |
  | osd_max_backfills                  | 一个OSD允许的最大backfills数。                               | 默认值：1修改建议：4                         |
  | osd_min_pg_log_entries             | PG正常状态下最大能记录的PGLog数。                            | 默认值：3000修改建议：30000                  |
  | osd_max_pg_log_entries             | PG降级状态下最大能记录的PGLog数。                            | 默认值：3000修改建议：100000                 |
  | osd_mon_heartbeat_interval         | OSD ping一个monitor的时间间隔（单位S）。                     | 默认值：30修改建议：40                       |
  | ms_dispatch_throttle_bytes         | 等待派遣的最大消息数。                                       | 默认值：10485760修改建议：1048576000         |
  | objecter_inflight_ops              | 客户端流控，允许的最大未发送IO请求数，超过阀值会堵塞应用IO，为0表示不受限。 | 默认值：1024修改建议：819200                 |
  | osd_op_log_threshold               | 一次显示多少操作的log。                                      | 默认值：5修改建议：50                        |
  | osd_crush_chooseleaf_type          | CRUSH规则用到chooseleaf时的bucket的类型。                    | 默认值：1修改建议：0                         |
  | journal_max_write_bytes            | 一次性写入journal的最大字节数（Bytes）。                     | 默认值：1048560修改建议：1073714824          |
  | journal_max_write_entries          | 一次性写入journal的最大记录数。                              | 默认值：100修改建议：10000                   |
  | **[Client]**                       |                                                              |                                              |
  | rbd_cache                          | RBD缓存。                                                    | 默认值：True（表示开启该功能）修改建议：True |
  | rbd_cache_size                     | RBD缓存大小（Bytes）。                                       | 默认值：33554432修改建议：335544320          |
  | rbd_cache_max_dirty                | 缓存为write-back时允许的最大dirty字节数（Bytes），如果为0，使用write-through。 | 默认值：25165824修改建议：134217728          |
  | rbd_cache_max_dirty_age            | 在被刷新到存储盘前dirty数据存在缓存的时间（Seconds）。       | 默认值：1修改建议：30                        |
  | rbd_cache_writethrough_until_flush | 该选项是为了兼容linux-2.6.32之前的virtio驱动，避免因为不发送flush请求，数据不回写。设置该参数为True后，librbd会以writethrough的方式执行IO，直到收到第一个flush请求，才切换为writeback方式。 | 默认值：True修改建议：False                  |
  | rbd_cache_max_dirty_object         | 最大的Object对象数，默认为0，表示通过rbd cache size计算得到，librbd默认以4MB为单位对磁盘Image进行逻辑切分。每个chunk对象抽象为一个Object；librbd中以Object为单位来管理缓存，增大该值可以提升性能。 | 默认值：0修改建议：2                         |
  | rbd_cache_target_dirty             | 开始执行回写过程的脏数据大小，不能超过 **“rbd_cache_max_dirty”**。 | 默认值：16777216修改建议：235544320          |

#### PG分布调优

- 目的

  调整每个OSD上承载的PG数量，使每个OSD的负载更加均衡。

- 方法

  Ceph默认为每个存储池分配8个**“pg/pgp”**，在创建存储池的时候使用**ceph osd pool create {pool-name} {pg-num} {pgp-num}**指定**“pg/pgp”**数量，或者使用**ceph osd pool set {pool_name} pg_num {pg-num}**和**ceph osd pool set {pool_name} pgp_num {pgp-num}**修改已创建好的存储池的**“pg/pgp”**数量。修改完成后使用**ceph osd pool get {pool_name} pg_num/pgp_num**查看存储池的**“pg/pgp”**数量。

  **“ceph balancer mode”**默认为“none”，用**ceph balancer mode upmap**命令调整为“upmap”。**“ceph balancer”**功能默认不打开，**ceph balancer on/off**用来打开/关闭**“ceph balancer”**功能。

  PG分布参数配置如[表3](https://support.huaweicloud.com/tngg-kunpengsdss/kunpengcephobject_05_0008.html#kunpengcephobject_05_0008__kunpengcephblock_05_0008_zh-cn_topic_0185390466_table2452858866)所示：

  

  | 参数名称           | 参数说明                                                     | 优化建议                                                     |
  | ------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
  | pg_num             | Total PGs = (Total_number_of_OSD * 100) / max_replication_count，得出的结果向上取到最近的2的整数次幂。 | 默认值：8现象：pg数量太少的话会有warning提示修改建议：根据计算公式具体计算得到的值 |
  | pgp_num            | pgp数量设置为与pg相同。                                      | 默认值：8现象：pgp数量建议与pg数量相同修改建议：根据计算公式具体计算得到的值 |
  | ceph_balancer_mode | 使能balancer均衡器插件，并设置均衡器插件模式为“upmap”。      | 默认值：none现象：若PG数量不均衡会出现个别OSD负载较大而成为瓶颈修改建议：upmap |

  ![img](Ceph调优.assets/support-doc-new-note.svg)说明：

  - 每个OSD上承载的PG数量应相同或非常接近，否则容易出现个别OSD压力较大成为瓶颈，运用balancer插件可以实现PG分布优化，可通过**ceph balancer eval**或**ceph pg dump**随时查看当前PG分布情况。
  - 通过**ceph balancer mode upmap**以及**ceph balancer on**使Ceph PG自动均衡优化，Ceph每隔60秒会调整少量PG分布。通过**ceph balancer eval**或**ceph pg dump**随时查看当前PG分布情况，若PG分布情况不再变化，则说明分布已达到最佳。
  - 上述每个OSD对应的PG分布主要影响写入的负载均衡。除了每个OSD对应的PG数量优化外，主PG的分布情况也需要视情况优化，即尽可能地将主PG均匀分布到各个OSD上。

#### OSD、RGW绑核

- 目的

  将OSD和RGW进程绑定到固定CPU核上，避免个别CPU压力过大。

- 方法

  当网卡软中断和Ceph进程共用CPU时，在网络压力较大的情况下，容易出现个别CPU压力过大成为瓶颈，影响整个Ceph集群性能。优化策略是将网卡软中断和Ceph进程分别绑定到不同CPU core上。具体优化项如[表4](https://support.huaweicloud.com/tngg-kunpengsdss/kunpengcephobject_05_0008.html#kunpengcephobject_05_0008__table2012238359)所示。

  

  | 参数名称 | 参数含义                                                     | 优化建议                                                     |
  | -------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
  | osd.[N]  | 将osd.n守护进程绑定到指定空闲NUMA节点上，此处的空闲NUMA节点指处理网卡软中断的节点以外的节点。 | 默认值：无修改建议：将osd.[N] 守护进程绑定到指定free CPU core上（即没有绑定网卡软终端的CPU core），分离CPU负载压力，避免CPU成为瓶颈 |
  | rgw.[N]  | 将RGW守护进程绑定到指定空闲NUMA节点上，此处的空闲NUMA节点指处理网卡软中断的节点以外的节点。 | 默认值：无修改建议：将rgw.[N] 守护进程绑定到指定free CPU core上（即没有绑定网卡软终端的CPU core），分离CPU负载压力，避免CPU成为瓶颈 |

  ![img](Ceph调优.assets/support-doc-new-note.svg)说明：

  Ceph OSD、RGW守护进程应当与网卡软中断在不同的CPU core上处理，否则在网络压力大的时候容易出现CPU瓶颈。

  随后在所有Ceph节点上执行以下命令完成绑核：

  `for i in `ps -ef | grep rgw | grep -v grep | awk '{print $2}'`; do taskset -pc 4-47 $i; done for i in `ps -ef | grep osd | grep -v grep | awk '{print $2}'`; do taskset -pc 4-47 $i; done `

  ![img](Ceph调优.assets/support-doc-new-note.svg)说明：

  [网络性能调优](https://support.huaweicloud.com/tngg-kunpengsdss/kunpengcephobject_05_0007.html#kunpengcephobject_05_0007__section1175411521319)将网卡软中断绑定到所属NUMA节点的CPU core上，当网络压力较大时，绑定了软中断的CPU core利用率较高，建议将osd_numa_node设置为与网卡不同的NUMA节点。比方说**cat /sys/class/net/ <网口名> /device/numa_node**查询到网卡归属于NUMA节点2，则设置osd_numa_node = 0或者osd_numa_node = 1，尽量避免OSD与网卡软中断使用相同的CPU core。RGW绑核原理类似，查询到空闲的NUMA节点后，可以用 lscpu 命令查询与NUMA节点相对应的CPU core编号，上述命令行中4-47为当前节点空闲CPU core，请根据实际情况修改该值。