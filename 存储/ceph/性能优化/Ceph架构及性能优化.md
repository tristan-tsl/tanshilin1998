# Ceph架构及性能优化

 原创

[Jacken_yang](https://blog.51cto.com/linuxnote)2016-06-20 21:10:02博主文章分类：[存储虚拟化](https://blog.51cto.com/linuxnote/category13)©著作权

*文章标签*[分布](https://blog.51cto.com/topic/fenbu.html)[架构优化](https://blog.51cto.com/topic/jiagouyouhua.html)[ceph](https://blog.51cto.com/topic/ceph.html)*文章分类*[其他](https://blog.51cto.com/nav/server1)[服务器](https://blog.51cto.com/nav/server)*阅读数*3.4万

对分布式存储系统的优化离不开以下几点：

**1. 硬件层面**

硬件规划

SSD选择

BIOS设置

**2. 软件层面**

Linux OS

Ceph Configurations

PG Number调整

CRUSH Map

其他因素

 

**硬件层面**

**1、 CPU**

ceph-osd进程在运行过程中会消耗CPU资源，所以一般会为每一个ceph-osd进程绑定一个CPU核上。

ceph-mon进程并不十分消耗CPU资源，所以不必为ceph-mon进程预留过多的CPU资源。

ceph-msd也是非常消耗CPU资源的，所以需要提供更多的CPU资源。

**2、 内存**

ceph-mon和ceph-mds需要2G内存，每个ceph-osd进程需要1G内存。

**3、 网络**

万兆网络现在基本上是跑Ceph必备的，网络规划上，也尽量考虑分离cilent和cluster网络。网络接口上可以使用bond来提供高可用或负载均衡。

**4、 SSD**

SSD在ceph中的使用可以有几种架构

a、 ssd作为Journal

b、 ssd作为高速ssd pool(需要更改crushmap)

c、 ssd做为tier pool

**5、 BIOS**

a、 开启VT和HT，VH是虚拟化云平台必备的，HT是开启超线程单个处理器都能使用线程级并行计算。

b、 关闭节能设置，可有一定的性能提升。

c、 NUMA思路就是将内存和CPU分割为多个区域，每个区域叫做NODE,然后将NODE高速互联。 node内cpu与内存访问速度快于访问其他node的内存， NUMA可能会在某些情况下影响ceph-osd 。解决的方案，一种是通过BIOS关闭NUMA，另外一种就是通过cgroup将ceph-osd进程与某一个CPU Core以及同一NODE下的内存进行绑定。但是第二种看起来更麻烦，所以一般部署的时候可以在系统层面关闭NUMA。CentOS系统下，通过修改/etc/grub.conf文件，添加numa=off来关闭NUMA。   

 

**软件层面**

**1、 Kernel pid max**

```bash
echo 4194303 > /proc/sys/kernel/pid_max1.
```

**2、 设置MTU，交换机端需要支持该功能，系统网卡设置才有效果**

配置文件追加MTU=9000

**3、 read_ahead, 通过数据预读并且记载到随机访问内存方式提高磁盘读操作**

```bash
echo "8192" > /sys/block/sda/queue/read_ahead_kb1.
```

**4、 swappiness, 主要控制系统对swap的使用**

```bash
echo "vm.swappiness = 0"/etc/sysctl.conf ;  sysctl –p1.
```

**5、 I/O Scheduler，SSD要用noop，SATA/SAS使用deadline**

```bash
echo "deadline" >/sys/block/sd[x]/queue/scheduler
echo "noop" >/sys/block/sd[x]/queue/scheduler1.2.
```

**6、 ceph.conf配置选项**

```bash
[global]#全局设置
fsid = 88caa60a-e6d1-4590-a2b5-bd4e703e46d9           #集群标识ID 
mon host = 10.0.1.21,10.0.1.22,10.0.1.23            #monitor IP 地址
auth cluster required = cephx                  #集群认证
auth service required = cephx                           #服务认证
auth client required = cephx                            #客户端认证
osd pool default size = 2                             #最小副本数
osd pool default min size = 1                           #PG 处于 degraded 状态不影响其 IO 能力,min_size是一个PG能接受IO的最小副本数
osd pool default pg num = 128                           #pool的pg数量
osd pool default pgp num = 128                          #pool的pgp数量
public network = 10.0.1.0/24                            #公共网络(monitorIP段) 
cluster network = 10.0.1.0/24                           #集群网络
max open files = 131072                                 #默认0#如果设置了该选项，Ceph会设置系统的max open fds
mon initial members = controller1, controller2, compute01 #初始monitor (由创建monitor命令而定)
##############################################################
[mon]
mon data = /var/lib/ceph/mon/ceph-$id
mon clock drift allowed = 1                             #默认值0.05#monitor间的clock drift
mon osd min down reporters = 13                         #默认值1#向monitor报告down的最小OSD数
mon osd down out interval = 600      #默认值300      #标记一个OSD状态为down和out之前ceph等待的秒数
##############################################################
[osd]
osd data = /var/lib/ceph/osd/ceph-$id
osd journal size = 20000 #默认5120                      #osd journal大小
osd journal = /var/lib/ceph/osd/$cluster-$id/journal #osd journal 位置
osd mkfs type = xfs                                     #格式化系统类型
osd mkfs options xfs = -f -i size=2048                  #强制格式化
filestore xattr use omap = true                         #默认false#为XATTRS使用object map，EXT4文件系统时使用，XFS或者btrfs也可以使用
filestore min sync interval = 10                        #默认0.1#从日志到数据盘最小同步间隔(seconds)
filestore max sync interval = 15                        #默认5#从日志到数据盘最大同步间隔(seconds)
filestore queue max ops = 25000                        #默认500#数据盘最大接受的操作数
filestore queue max bytes = 1048576000      #默认100   #数据盘一次操作最大字节数(bytes
filestore queue committing max ops = 50000 #默认500     #数据盘能够commit的操作数
filestore queue committing max bytes = 10485760000 #默认100 #数据盘能够commit的最大字节数(bytes)
filestore split multiple = 8 #默认值2                  #前一个子目录分裂成子目录中的文件的最大数量
filestore merge threshold = 40 #默认值10               #前一个子类目录中的文件合并到父类的最小数量
filestore fd cache size = 1024 #默认值128              #对象文件句柄缓存大小
journal max write bytes = 1073714824 #默认值1048560    #journal一次性写入的最大字节数(bytes)
journal max write entries = 10000 #默认值100         #journal一次性写入的最大记录数
journal queue max ops = 50000  #默认值50            #journal一次性最大在队列中的操作数
journal queue max bytes = 10485760000 #默认值33554432   #journal一次性最大在队列中的字节数(bytes)
osd max write size = 512 #默认值90                   #OSD一次可写入的最大值(MB)
osd client message size cap = 2147483648 #默认值100    #客户端允许在内存中的最大数据(bytes)
osd deep scrub stride = 131072 #默认值524288         #在Deep Scrub时候允许读取的字节数(bytes)
osd op threads = 16 #默认值2                         #并发文件系统操作数
osd disk threads = 4 #默认值1                        #OSD密集型操作例如恢复和Scrubbing时的线程
osd map cache size = 1024 #默认值500                 #保留OSD Map的缓存(MB)
osd map cache bl size = 128 #默认值50                #OSD进程在内存中的OSD Map缓存(MB)
osd mount options xfs = "rw,noexec,nodev,noatime,nodiratime,nobarrier" #默认值rw,noatime,inode64  #Ceph OSD xfs Mount选项
osd recovery op priority = 2 #默认值10              #恢复操作优先级，取值1-63，值越高占用资源越高
osd recovery max active = 10 #默认值15              #同一时间内活跃的恢复请求数 
osd max backfills = 4  #默认值10                  #一个OSD允许的最大backfills数
osd min pg log entries = 30000 #默认值3000           #修建PGLog是保留的最大PGLog数
osd max pg log entries = 100000 #默认值10000         #修建PGLog是保留的最大PGLog数
osd mon heartbeat interval = 40 #默认值30            #OSD ping一个monitor的时间间隔（默认30s）
ms dispatch throttle bytes = 1048576000 #默认值 104857600 #等待派遣的最大消息数
objecter inflight ops = 819200 #默认值1024           #客户端流控，允许的最大未发送io请求数，超过阀值会堵塞应用io，为0表示不受限
osd op log threshold = 50 #默认值5                  #一次显示多少操作的log
osd crush chooseleaf type = 0 #默认值为1              #CRUSH规则用到chooseleaf时的bucket的类型
##############################################################
[client]
rbd cache = true #默认值 true      #RBD缓存
rbd cache size = 335544320 #默认值33554432           #RBD缓存大小(bytes)
rbd cache max dirty = 134217728 #默认值25165824      #缓存为write-back时允许的最大dirty字节数(bytes)，如果为0，使用write-through
rbd cache max dirty age = 30 #默认值1                #在被刷新到存储盘前dirty数据存在缓存的时间(seconds)
rbd cache writethrough until flush = false #默认值true  #该选项是为了兼容linux-2.6.32之前的virtio驱动，避免因为不发送flush请求，数据不回写
              #设置该参数后，librbd会以writethrough的方式执行io，直到收到第一个flush请求，才切换为writeback方式。
rbd cache max dirty object = 2 #默认值0              #最大的Object对象数，默认为0，表示通过rbd cache size计算得到，librbd默认以4MB为单位对磁盘Image进行逻辑切分
      #每个chunk对象抽象为一个Object；librbd中以Object为单位来管理缓存，增大该值可以提升性能
rbd cache target dirty = 235544320 #默认值16777216    #开始执行回写过程的脏数据大小，不能超过 rbd_cache_max_dirty1.2.3.4.5.6.7.8.9.10.11.12.13.14.15.16.17.18.19.20.21.22.23.24.25.26.27.28.29.30.31.32.33.34.35.36.37.38.39.40.41.42.43.44.45.46.47.48.49.50.51.52.53.54.55.56.57.58.59.60.61.62.63.64.65.66.67.68.69.70.
```

**7、 PG Number**

PG和PGP数量一定要根据OSD的数量进行调整，计算公式如下，但是最后算出的结果一定要接近或者等于一个2的指数。

Total PGs = (Total_number_of_OSD * 100) / max_replication_count

例：

有100个osd，2副本，5个pool

Total PGs =100*100/2=5000

每个pool 的PG=5000/5=1000，那么创建pool的时候就指定pg为1024

ceph osd pool create pool_name 1024

**8、 修改crush map**

Crush map可以设置不同的osd对应到不同的pool，也可以修改每个osd的weight

配置可参考：[ http://linuxnote.blog.51cto.com/9876511/1790758](http://linuxnote.blog.51cto.com/9876511/1790758)

**9、 其他因素**

ceph osd perf

通过osd perf可以提供磁盘latency的状况，如果延时过长，应该剔除osd