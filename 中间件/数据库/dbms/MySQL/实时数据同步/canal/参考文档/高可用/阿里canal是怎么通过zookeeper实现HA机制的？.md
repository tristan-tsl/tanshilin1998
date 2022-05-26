# [阿里canal是怎么通过zookeeper实现HA机制的？](https://segmentfault.com/a/1190000023297973)

[![img](https://avatar-static.segmentfault.com/775/497/775497217-5ec76f3adf506_huge128)**liuyongfei**](https://segmentfault.com/u/liuyongfei)发布于 2020-07-20

![img](https://sponsor.segmentfault.com/lg.php?bannerid=0&campaignid=0&zoneid=25&loc=https%3A%2F%2Fsegmentfault.com%2Fa%2F1190000023297973&referer=https%3A%2F%2Fwww.google.com%2F&cb=60dd6be84f)

> 可以访问 [这里](https://link.segmentfault.com/?url=https%3A%2F%2Fmp.weixin.qq.com%2Fmp%2Fappmsgalbum%3Faction%3Dgetalbum%26amp%3Balbum_id%3D1410124501450571776%26amp%3B__biz%3DMzAwMjk5NTY3Mw%3D%3D%23wechat_redirect) 查看更多关于**大数据平台建设**的原创文章。

### 一. 阿里canal工作原理

canal 是阿里的一款开源项目，纯Java开发。基于数据库增量日志解析，提供增量数据订阅&消费，目前主要支持了MySQL(也支持mariaDB)。

#### MySQL主备复制原理

![mysql主备复制原理.jpeg](https://segmentfault.com/img/bVIVV0)

1. Master 将变更写入binlog日志；
2. Slave 的 I/O thread 会去请求 Master 的binlog，并将得到的binlog写到本地的relay-log(中继日志)文件中；
3. Slave 的 SQL thread 会从中继日志读取binlog，然后执行binlog日志中的内容，也就是在自己本地再次执行一遍SQL语句，从而使从服务器和主服务器的数据保持一致。

##### 更多

MySQL 的 Binary Log 介绍

- [http://dev.mysql.com/doc/refman/5.5/en/binary-log.html](https://link.segmentfault.com/?url=http%3A%2F%2Fdev.mysql.com%2Fdoc%2Frefman%2F5.5%2Fen%2Fbinary-log.html)
- [http://www.taobaodba.com/html/474\_mysqls-binary-log\_details.html](https://link.segmentfault.com/?url=http%3A%2F%2Fwww.taobaodba.com%2Fhtml%2F474_mysqls-binary-log_details.html)

#### canal的工作原理

![canal工作原理.jpeg](https://segmentfault.com/img/bVTmbI)

1. canal 模拟 mysql slave 的交互协议，伪装自己为 mysql slave，向 mysql master发送 dump 协议；
2. mysql master 收到 dump 请求，开始推送binary log给 slave(也就是canal)
3. canal 解析 binary log对象(原始为byte流)。

##### 更多

关于 canal的详细介绍，可以访问官网：[https://github.com/alibaba/canal](https://link.segmentfault.com/?url=https%3A%2F%2Fgithub.com%2Falibaba%2Fcanal)

### 二. 阿里canal的HA机制

#### 1. 什么是HA机制

> 所谓HA（High Available），即高可用（7*24小时不中断服务）。

#### 2. 单点故障

实现高可用最关键的策略是消除单点故障。比如Hadoop2.0之前，在HDFS集群中NameNode存在单点故障：

1. NameNode机器发生意外，如宕机，集群将无法使用；
2. NameNode机器需要升级，包括软件、硬件升级，此时集群也将无法使用。

#### 3. Hadoop2.0引入HA机制

通过配置Active/Standby两个NameNodes实现在集群中对NameNode的热备来解决上述问题。

- 有一台节点是Active模式，也就是工作模式，其它的节点是 Standby（备用模式）；
- 干活的（Active模式的节点）如果挂了，就从备用模式的节点中选出一台顶上去。

**更多**
关于 Hadoop 的HA 机制的详细介绍，可以访问：[https://blog.csdn.net/pengjunlee/article/details/81583052](https://link.segmentfault.com/?url=https%3A%2F%2Fblog.csdn.net%2Fpengjunlee%2Farticle%2Fdetails%2F81583052)

#### 4. zookeeper的watcher和EPHEMERAL节点

##### zookeeper的watcher

watcher 机制涉及到客户端与服务器（注意，不止一个机器，一般是集群）的两者数据通信与消息通信：
![zk-watcher.jpg](https://segmentfault.com/img/bVbJUWP)

##### 更多

关于watcher 的详细介绍，可以访问：[https://www.jianshu.com/p/4c071e963f18](https://link.segmentfault.com/?url=https%3A%2F%2Fwww.jianshu.com%2Fp%2F4c071e963f18)

##### zookeeper的节点类型

EPHEMERAL节点是 zookeeper的临时节点，临时节点与session生命周期绑定，**客户端会话失效后临时节点会自动清除**。

##### 更多

关于 zookeeper EPHEMERAL节点的详细介绍，可以访问：
[https://blog.csdn.net/randompeople/article/details/70500076](https://link.segmentfault.com/?url=https%3A%2F%2Fblog.csdn.net%2Frandompeople%2Farticle%2Fdetails%2F70500076)

#### 5. canal的 HA机制

整个 HA 机制的控制主要是依赖了zookeeper的上述两个特性：watcher、EPHEMERAL节点。canal的 HA 机制实现分为两部分，canal server 和 canal client分别有对应的实现。
![canal的HA机制.jpg](https://segmentfault.com/img/bVbJUWV)

##### canal server实现流程

1. canal server 要启动某个 canal instance 时都先向 zookeeper 进行一次尝试启动判断 (实现：创建 EPHEMERAL 节点，谁创建成功就允许谁启动）；
2. 创建 zookeeper 节点成功后，对应的 canal server 就启动对应的 canal instance，没有创建成功的 canal instance 就会处于 standby 状态；
3. 一旦 zookeeper 发现 canal server A 创建的节点消失后，立即通知其他的 canal server 再次进行步骤1的操作，重新选出一个 canal server 启动instance；
4. canal client 每次进行connect时，会首先向 zookeeper 询问当前是谁启动了canal instance，然后和其建立链接，一旦链接不可用，会重新尝试connect。

**注意**
为了减少对mysql dump的请求，不同server上的instance要求同一时间只能有一个处于running，其他的处于standby状态。

##### canal client实现流程

- canal client 的方式和 canal server 方式类似，也是利用 zookeeper 的抢占EPHEMERAL 节点的方式进行控制
- **为了保证有序性，一份 instance 同一时间只能由一个 canal client 进行get/ack/rollback操作，否则客户端接收无法保证有序**。

### 三. canal的HA集群模式部署

#### 1. canal下载地址

- 下载地址： [https://github.com/alibaba/canal/releases](https://link.segmentfault.com/?url=https%3A%2F%2Fgithub.com%2Falibaba%2Fcanal%2Freleases)
  我使用的是 1.1.4 稳定版本。

#### 2. mysql开启binlog

MySQL , 需要先开启 Binlog 写入功能，配置 binlog-format 为 ROW 模式，my.cnf 中配置如下：

```ini
[mysqld]
log-bin=mysql-bin # 开启 binlog
binlog-format=ROW # 选择 ROW 模式
server_id=1 # 配置 MySQL replaction 需要定义，不要和 canal 的 slaveId 重复
```

#### 3. mysql授权账号权限

授权 canal 链接 MySQL 账号具有作为 MySQL slave 的权限, 如果已有账户可直接 grant：

```pgsql
CREATE USER canal IDENTIFIED BY 'canal';  
GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'canal'@'%';
-- GRANT ALL PRIVILEGES ON *.* TO 'canal'@'%' ;
FLUSH PRIVILEGES;
```

**备注**
可以通过在 mysql 终端中执行以下命令判断配置是否生效：

```gams
show variables like 'log_bin';
show variables like 'binlog_format';
```

#### 4. 修改配置

canal 服务的部署其实特别简单，解压之后只需修改`canal.properties、instance.properties`这两个配置两个文件即可。

##### 修改canal.properties中配置

```stylus
//指定注册的zk集群地址
canal.zkServers =127.0.0.1:2181,127.0.0.2:2181
//HA模式必须使用该xml，需要将相关数据写入zookeeper,保证数据集群共享
canal.instance.global.spring.xml = classpath:spring/default-instance.xml
// 这个demo就是conf目录里的实例，如果要建别的实例'test'就建个test目录，把example里面的instance.properties文件拷贝到test的实例目录下就好了，然后在这里的配置就是canal.destinations = demo,test
canal.destinations = demo 
```

##### 修改demo.properties中配置

```ini
## mysql serverId , v1.0.26+ will autoGen
# canal伪装的mysql slave的编号，不能与mysql数据库和其他的slave重复
canal.instance.mysql.slaveId=1003
#  按需修改成自己的数据库信息
# position info
canal.instance.master.address=10.200.*.109:3306

# username/password 数据库的用户名和密码
canal.instance.dbUsername=canal
canal.instance.dbPassword=canal
canal.instance.defaultDatabaseName = test
```

#### 5. 详细步骤

canal 的HA集群模式部署详细步骤，可以访问：[https://blog.csdn.net/XDSXHDYY/article/details/97825508](https://link.segmentfault.com/?url=https%3A%2F%2Fblog.csdn.net%2FXDSXHDYY%2Farticle%2Fdetails%2F97825508)

### 四. 通过实例感受zookeeper在HA机制中的作用

说了这么多，下面通过一个实例演示来感受一下 zookeeper 到底起了什么作用。
新建一个叫 'demo' 的实例：

```powershell
$ cd /data/application/canal.deployer-1.1.4/conf
$ cp -r example demo
```

配置文件的修改可以参考**第三部分**贴出的配置。

#### 环境

##### 1. 版本

```apache
canal(1.1.4) + Zookeeper(3.4.6-78--1) 
```

##### 2. canal集群

canal server部署在两台机器上：

```apache
10.200.*.108 和 10.200.*.109
```

##### 3. zookeeper 集群

zookeeper部署在三台机器上：

```apache
10.200.*.109:2181,10.200.*.110:2181,10.200.*.111:2181
```

#### 从 zookeeper 中查看active节点信息

##### 1. 使用 zkClient链接zookeeper server

```vim
$ ./zkCli.sh -server localhost:2181
```

##### 2. 查看 zookeeper集群中，canal server的 active节点信息

```awk
[zk: localhost:2181(CONNECTED) 3] get /otter/canal/destinations/demo/running
```

![zk1.png](https://segmentfault.com/img/bVbJUZA)

由于我还没有启动任何一台 canal server，所以查询的节点不存在。

#### 分别启动多台机器上的canal server

分别登陆 108 和 109 两台机器，cd 到 canal 所在目录，命令行启动服务：

```apache
cd /data/application/canal.deployer-1.1.4
sh bin/startup.sh
```

#### 现象一：只会有一个canal server的demo(instance名称)处于active状态

##### 1. 继续查看zookeeper集群中，canal server的 active节点信息

![zk2.png](https://segmentfault.com/img/bVbJU0l)

从图中可以看出：

- 当前工作的节点为：10.200.*.109:11111。

##### 2. 分别查看canal server的 启动日志

通过去 109 和 108 这两台机器上找到 canal server 启动日志，去验证一下上面的结论。

- 查看 109 机器的 canal server 启动日志：

```autoit
[root@dc23x109-jiqi canal.deployer-1.1.4]# tail -f logs/demo/demo.log
```

- 查看 108 机器的 canal server 启动日志：
  ![log2.png](https://segmentfault.com/img/bVbJU0N)

从图中可以看出：

- 该log目录下面没有 demo目录，也就是说 108 机器上的 canal server 压根没有产生启动日志。

##### 3. 结论

通过从 zookeeper 中查看节点信息和分别从两台 canal server 所在的机器上查看日志，可以得出如下结论：

- 109 和 108 上的 canal server 在接到 `sh startup.sh` 命令后，都向 zookeeper 尝试创建 EPHEMERAL 节点，109的 canal server 创建成功，因此启动的demo实例就处于active状态；
- 108机器上的 canal server 创建 EPHEMERAL 节点失败，因此该 server 的 demo 实例就处于standby状态。
- 相同名称的实例在分布在多个机器上的多个 server 里，同一时刻只会有一个实例处于 active 状态，减少对mysql master dump 的请求。

#### 现象二：关闭一个canal server后会重新选出一个canal server

##### 1. 手动关闭109机器的canal server

```vim
cd /data/application/canal.deployer-1.1.4
sh bin/stop.sh
```

##### 2. 查看zookeeper集群中，canal server的 active节点信息

![zk3.png](https://segmentfault.com/img/bVbJU1l)

从图中可以看出：

- 当前可用的 canal server 切换为：10.200.*.109:11111。

##### 3. 结论

1. 再次验证，canal server 启动时向 zookeeper 创建的节点就是**临时节点**，**它与 session 生命周期绑定，当我手动执行关闭命令，客户端会话会失效，临时节点会自动清除**；
2. **一旦 zookeeper 发现 canal server 108 机器创建的节点消失后，就会通知其它的 canal server 再次进行向 zookeeper 尝试创建临时节点的操作，就会有新的 active 节点产生**；
3. 这不就是 HA 机制最核心的作用嘛，一个机器机器发生意外，如宕机，另外一个机器能够立马顶上，保证集群的正常使用，从而保证服务的高可用。

### 更多文章 

欢迎访问更多关于**消息中间件**的原创文章：

- [RabbitMQ系列之消息确认机制](https://link.segmentfault.com/?url=https%3A%2F%2Fmp.weixin.qq.com%2Fs%3F__biz%3DMzAwMjk5NTY3Mw%3D%3D%26amp%3Bmid%3D2247483748%26amp%3Bidx%3D1%26amp%3Bsn%3D2575b6275448703ce3ee090aef2453e2%26amp%3Bchksm%3D9ac0a5d2adb72cc4f5a2a503e1d68b5487e537c9731e6d09de4e7db811c1dd481006888b2f88%26amp%3Bscene%3D178%26amp%3Bcur_album_id%3D1341676193447493632%23rd)
- [RabbitMQ系列之RPC实现](https://link.segmentfault.com/?url=https%3A%2F%2Fmp.weixin.qq.com%2Fs%3F__biz%3DMzAwMjk5NTY3Mw%3D%3D%26amp%3Bmid%3D2247483765%26amp%3Bidx%3D1%26amp%3Bsn%3Debe9a7bfa0b5e856193e8bb0574ed6bf%26amp%3Bchksm%3D9ac0a5c3adb72cd549e808b3d8b86eec605ccad32746fc7a5af9305dc3003b7c957f52e133fc%26amp%3Bscene%3D178%26amp%3Bcur_album_id%3D1341676193447493632%23rd)
- [RabbitMQ系列之怎么确保消息不丢失](https://link.segmentfault.com/?url=https%3A%2F%2Fmp.weixin.qq.com%2Fs%3F__biz%3DMzAwMjk5NTY3Mw%3D%3D%26amp%3Bmid%3D2247483770%26amp%3Bidx%3D1%26amp%3Bsn%3D6ba73c94078b8d1deefb0b47f78af023%26amp%3Bchksm%3D9ac0a5ccadb72cdaef904f90e1637d12308832069aaea44d903ea4c0014bb3af10acfbc5b894%26amp%3Bscene%3D178%26amp%3Bcur_album_id%3D1341676193447493632%23rd)
- [RabbitMQ系列之基本概念和基本用法](https://link.segmentfault.com/?url=https%3A%2F%2Fmp.weixin.qq.com%2Fs%3F__biz%3DMzAwMjk5NTY3Mw%3D%3D%26amp%3Bmid%3D2247483736%26amp%3Bidx%3D1%26amp%3Bsn%3D3a8a21e08081f0fbce73c7a599564011%26amp%3Bchksm%3D9ac0a5eeadb72cf857eed41a225d354ab60620f86539fa0b708e2d711db05047fd0df6cb47a0%26amp%3Bscene%3D178%26amp%3Bcur_album_id%3D1341676193447493632%23rd)
- [RabbitMQ系列之部署模式](https://link.segmentfault.com/?url=https%3A%2F%2Fmp.weixin.qq.com%2Fs%3F__biz%3DMzAwMjk5NTY3Mw%3D%3D%26amp%3Bmid%3D2247483736%26amp%3Bidx%3D2%26amp%3Bsn%3Ddf1a94b423f256af24d4a35c55bf054f%26amp%3Bchksm%3D9ac0a5eeadb72cf861143d380a6abf7c177aee77ff9fde18b8bf1b0dc2a6130266d14d0b99f2%26amp%3Bscene%3D178%26amp%3Bcur_album_id%3D1341676193447493632%23rd)
- [RabbitMQ系列之单机模式安装](https://link.segmentfault.com/?url=https%3A%2F%2Fmp.weixin.qq.com%2Fs%3F__biz%3DMzAwMjk5NTY3Mw%3D%3D%26amp%3Bmid%3D2247483716%26amp%3Bidx%3D1%26amp%3Bsn%3D0e6d06c1192bf26d68bb6f3d1dde0ea4%26amp%3Bchksm%3D9ac0a5f2adb72ce42bc107ee4e129870d3cb7e46a4c77b99448c999a9083d265c8161eb3be9c%26amp%3Bscene%3D178%26amp%3Bcur_album_id%3D1341676193447493632%23rd)