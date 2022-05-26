# [RocketMQ(九)：主从同步的实现](https://www.cnblogs.com/yougewe/p/14198675.html)



**目录**

- [1. 主从同步概述](https://www.cnblogs.com/yougewe/p/14198675.html#_label0)
- [2. rocketmq主从同步配置](https://www.cnblogs.com/yougewe/p/14198675.html#_label1)
- [3. rocketmq主从同步的实现](https://www.cnblogs.com/yougewe/p/14198675.html#_label2)
- \4. rocketmq消息数据的同步实现
  - [4.1. HAService的开启](https://www.cnblogs.com/yougewe/p/14198675.html#_label3_0)
  - [4.2. 从节点同步实现](https://www.cnblogs.com/yougewe/p/14198675.html#_label3_1)
  - [4.3. master的数据同步服务](https://www.cnblogs.com/yougewe/p/14198675.html#_label3_2)



------

　　分布式系统的三大理论CAP就不说了，但是作为分布式消息系统的rocketmq, 主从功能是最最基础的保证可用性的手段了。也许该功能现在已经不是很常用了，但是对于我们理解一些分布式系统的常用工作原理还是有些积极意义的。

　　今天就一起来挖挖rocketmq是如何实现主从数据同步的吧。

 

[返回顶部](https://www.cnblogs.com/yougewe/p/14198675.html#_labelTop)

### 1. 主从同步概述

　　主从同步这个概念相信大家在平时的工作中，多少都会听到。其目的主要是用于做一备份类操作，以及一些读写分离场景。比如我们常用的关系型数据库mysql，就有主从同步功能在。

　　主从同步，就是将主服务器上的数据同步到从服务器上，也就是相当于新增了一个副本。

　　而具体的主从同步的实现也各有千秋，如mysql中通过binlog实现主从同步，es中通过translog实现主从同步，redis中通过aof实现主从同步。那么，rocketmq又是如何实现的主从同步呢？

　　另外，主从同步需要考虑的问题是哪些呢？

　　　　1. 数据同步的及时性？（延迟与一致性）
　　　　2. 对主服务器的影响性？（可用性）
　　　　3. 是否可替代主服务器？（可用性或者分区容忍性）

　　前面两个点是必须要考虑的，但对于第3个点，则可能不会被考虑。因为通过系统可能无法很好的做到这一点，所以很多系统就直接忽略这一点了，简单嘛。即很多时候只把从服务器当作是一个备份存在，不会接受写请求。如果要进行主从切换，必须要人工介入，做预知的有损切换。但随着技术的发展，现在已有非常多的自动切换主从的服务存在，这是在分布式系统满天下的当今的必然趋势。

 

[返回顶部](https://www.cnblogs.com/yougewe/p/14198675.html#_labelTop)

### 2. rocketmq主从同步配置

　　在rocketmq中，最核心的组件是 broker, 它负责几乎所有的存储读取业务。所以，要谈主从同步，那必然是针对broker进行的。我们再来回看rocketmq的部署架构图，以便全局观察：

![img](RocketMQ(九)：主从同步的实现.assets/830731-20201227205308183-813885278.jpg)

　　非常清晰的架构，无须多言。因为我们讲的是主从同步，所以只看broker这个组件，那么整个架构就可以简化为: BrokerMaster -> BrokerSlave 了。同样，再简化，主从同步就是如何将Master的数据同步到Slave这么个过程。

　　那么，如何配置使用主从同步呢？

　　conf/broker-a.properties (master配置)

[![复制代码](RocketMQ(九)：主从同步的实现.assets/copycode.gif)](javascript:void(0);)

```
#所属集群名字
brokerClusterName=DefaultCluster
#broker名字，名字可重复,为了管理,每个master起一个名字,他的slave同他,eg:Amaster叫broker-a,他的slave也叫broker-a
brokerName=broker-a
#0 表示 Master，>0 表示 Slave
brokerId=0
#Broker 的角色
#- ASYNC_MASTER 异步复制Master
#- SYNC_MASTER 同步双写Master
#- SLAVE
brokerRole=ASYNC_MASTER
#刷盘方式
#- ASYNC_FLUSH 异步刷盘
#- SYNC_FLUSH 同步刷盘
flushDiskType=ASYNC_FLUSH
#nameServer地址，分号分割
namesrvAddr=172.0.1.5:9876;172.0.1.6:9876
#在发送消息时，自动创建服务器不存在的topic，默认创建的队列数
defaultTopicQueueNums=4
#是否允许 Broker 自动创建Topic，建议线下开启，线上关闭
autoCreateTopicEnable=true
#是否允许 Broker 自动创建订阅组，建议线下开启，线上关闭
autoCreateSubscriptionGroup=true
#Broker 对外服务的监听端口,
listenPort=10911
#删除文件时间点，默认凌晨 4点
deleteWhen=04
#文件保留时间，默认 48 小时
fileReservedTime=120
#commitLog每个文件的大小默认1G
mapedFileSizeCommitLog=1073741824
#ConsumeQueue每个文件默认存30W条，根据业务情况调整
mapedFileSizeConsumeQueue=300000
#destroyMapedFileIntervalForcibly=120000
#redeleteHangedFileInterval=120000
#检测物理文件磁盘空间
diskMaxUsedSpaceRatio=88
#存储路径
storePathRootDir=/usr/local/rocketmq/store/broker-a
#commitLog 存储路径
storePathCommitLog=/usr/local/rocketmq/store/broker-a/commitlog
#消费队列存储路径存储路径
storePathConsumeQueue=/usr/local/rocketmq/store/broker-a/consumequeue
#消息索引存储路径
storePathIndex=/usr/local/rocketmq/store/broker-a/index
#checkpoint 文件存储路径
storeCheckpoint=/usr/local/rocketmq/store/checkpoint
#abort 文件存储路径
abortFile=/usr/local/rocketmq/store/abort
#限制的消息大小
maxMessageSize=65536
#flushCommitLogLeastPages=4
#flushConsumeQueueLeastPages=2
#flushCommitLogThoroughInterval=10000
#flushConsumeQueueThoroughInterval=60000
#checkTransactionMessageEnable=false
#发消息线程池数量
#sendMessageThreadPoolNums=128
#拉消息线程池数量
#pullMessageThreadPoolNums=128
```

[![复制代码](RocketMQ(九)：主从同步的实现.assets/copycode.gif)](javascript:void(0);)

　　conf/broker-a-s.properties (slave配置)

[![复制代码](RocketMQ(九)：主从同步的实现.assets/copycode.gif)](javascript:void(0);)

```
#所属集群名字
brokerClusterName=DefaultCluster
#broker名字，名字可重复,为了管理,每个master起一个名字,他的slave同他,eg:Amaster叫broker-a,他的slave也叫broker-a
brokerName=broker-a
#0 表示 Master，>0 表示 Slave
brokerId=1
#Broker 的角色
#- ASYNC_MASTER 异步复制Master
#- SYNC_MASTER 同步双写Master
#- SLAVE
brokerRole=SLAVE
#刷盘方式
#- ASYNC_FLUSH 异步刷盘
#- SYNC_FLUSH 同步刷盘
flushDiskType=ASYNC_FLUSH
#nameServer地址，分号分割
namesrvAddr=172.0.1.5:9876;172.0.1.6:9876
#在发送消息时，自动创建服务器不存在的topic，默认创建的队列数
defaultTopicQueueNums=4
#是否允许 Broker 自动创建Topic，建议线下开启，线上关闭
autoCreateTopicEnable=true
#是否允许 Broker 自动创建订阅组，建议线下开启，线上关闭
autoCreateSubscriptionGroup=true
#Broker 对外服务的监听端口,
listenPort=10920
#删除文件时间点，默认凌晨 4点
deleteWhen=04
#文件保留时间，默认 48 小时
fileReservedTime=120
#commitLog每个文件的大小默认1G
mapedFileSizeCommitLog=1073741824
#ConsumeQueue每个文件默认存30W条，根据业务情况调整
mapedFileSizeConsumeQueue=300000
#destroyMapedFileIntervalForcibly=120000
#redeleteHangedFileInterval=120000
#检测物理文件磁盘空间
diskMaxUsedSpaceRatio=88
#存储路径
storePathRootDir=/usr/local/rocketmq/store/broker-a-s
#commitLog 存储路径
storePathCommitLog=/usr/local/rocketmq/store/broker-a-s/commitlog
#消费队列存储路径存储路径
storePathConsumeQueue=/usr/local/rocketmq/store/broker-a-s/consumequeue
#消息索引存储路径
storePathIndex=/usr/local/rocketmq/store/broker-a-s/index
#checkpoint 文件存储路径
storeCheckpoint=/usr/local/rocketmq/store/checkpoint
#abort 文件存储路径
abortFile=/usr/local/rocketmq/store/abort
#限制的消息大小
maxMessageSize=65536
#flushCommitLogLeastPages=4
#flushConsumeQueueLeastPages=2
#flushCommitLogThoroughInterval=10000
#flushConsumeQueueThoroughInterval=60000
#checkTransactionMessageEnable=false
#发消息线程池数量
#sendMessageThreadPoolNums=128
#拉消息线程池数量
#pullMessageThreadPoolNums=128
```

[![复制代码](RocketMQ(九)：主从同步的实现.assets/copycode.gif)](javascript:void(0);)

　　实际上具体配置文件叫什么名字不重要，重要的是要在启动时指定指定对应的配置文件位置即可。启动master/slave命令如下:

```
    nohup sh /usr/local/rocketmq/bin/mqbroker -c /usr/local/rocketmq/conf/2m-2s-async/broker-a.properties > logs/broker-a.log 2>&1 &
    nohup sh /usr/local/rocketmq/bin/mqbroker -c /usr/local/rocketmq/conf/2m-2s-async/broker-a-s.properties > logs/broker-a-s.log 2>&1 &
```

　　以上配置，如果怕启动命令出错，也可以统一使用一个 broker.properties (默认查找), 里面写不同的内容，这样就无需在不同机器上使用不同的命令启动了，也避免了一定程度的误操作。

　　当然要在启动broker之前启动nameserver节点。这样，一个rocketmq的主从集群就配置好了。配置项看起来有点多，但核心实际上只有一个：在保持brokderName相同的前提下配置brokerRole=ASYNC_MASTER|SLAVE|SYNC_MASTER, 通过这个值就可以确定是主是从。从向主复制数据或者主向从同步数据。

 

[返回顶部](https://www.cnblogs.com/yougewe/p/14198675.html#_labelTop)

### 3. rocketmq主从同步的实现

　　了解完主从配置，才是我们理解实现的开始。也从上面的说明中，我们看出，一个broker是master或者slave是在配置文件中就指定了的，也就是说这个性质是改不了的了。所以，这个主从相关的动作，会在broker启动时就表现出不一样了。

　　我们先看看broker运行同步的大体框架如何：

[![复制代码](RocketMQ(九)：主从同步的实现.assets/copycode.gif)](javascript:void(0);)

```
    // org.apache.rocketmq.broker.BrokerController#start
    public void start() throws Exception {
        if (this.messageStore != null) {
            this.messageStore.start();
        }

        if (this.remotingServer != null) {
            this.remotingServer.start();
        }

        if (this.fastRemotingServer != null) {
            this.fastRemotingServer.start();
        }

        if (this.fileWatchService != null) {
            this.fileWatchService.start();
        }

        if (this.brokerOuterAPI != null) {
            this.brokerOuterAPI.start();
        }

        if (this.pullRequestHoldService != null) {
            this.pullRequestHoldService.start();
        }

        if (this.clientHousekeepingService != null) {
            this.clientHousekeepingService.start();
        }

        if (this.filterServerManager != null) {
            this.filterServerManager.start();
        }

        if (!messageStoreConfig.isEnableDLegerCommitLog()) {
            startProcessorByHa(messageStoreConfig.getBrokerRole());
            // 处理SLAVE消息同步
            handleSlaveSynchronize(messageStoreConfig.getBrokerRole());
            // 强制做一次注册动作
            this.registerBrokerAll(true, false, true);
        }
        // 定期向nameserver注册自身状态
        this.scheduledExecutorService.scheduleAtFixedRate(new Runnable() {

            @Override
            public void run() {
                try {
                    BrokerController.this.registerBrokerAll(true, false, brokerConfig.isForceRegister());
                } catch (Throwable e) {
                    log.error("registerBrokerAll Exception", e);
                }
            }
        }, 1000 * 10, Math.max(10000, Math.min(brokerConfig.getRegisterNameServerPeriod(), 60000)), TimeUnit.MILLISECONDS);

        if (this.brokerStatsManager != null) {
            this.brokerStatsManager.start();
        }

        if (this.brokerFastFailure != null) {
            this.brokerFastFailure.start();
        }


    }

    private void handleSlaveSynchronize(BrokerRole role) {
        // 只有slave节点，才进行同步操作
        if (role == BrokerRole.SLAVE) {
            if (null != slaveSyncFuture) {
                slaveSyncFuture.cancel(false);
            }
            // 设置master节点为空，避免一开始就进行同步
            // 后续必然有其他地方设计 master信息
            // 实际上它是在registerBrokerAll() 的时候，将master信息放入的
            this.slaveSynchronize.setMasterAddr(null);
            // 10秒钟同步一次数据
            slaveSyncFuture = this.scheduledExecutorService.scheduleAtFixedRate(new Runnable() {
                @Override
                public void run() {
                    try {
                        BrokerController.this.slaveSynchronize.syncAll();
                    }
                    catch (Throwable e) {
                        log.error("ScheduledTask SlaveSynchronize syncAll error.", e);
                    }
                }
            }, 1000 * 3, 1000 * 10, TimeUnit.MILLISECONDS);
        } else {
            //handle the slave synchronise
            if (null != slaveSyncFuture) {
                slaveSyncFuture.cancel(false);
            }
            this.slaveSynchronize.setMasterAddr(null);
        }
    }
    public synchronized void registerBrokerAll(final boolean checkOrderConfig, boolean oneway, boolean forceRegister) {
        TopicConfigSerializeWrapper topicConfigWrapper = this.getTopicConfigManager().buildTopicConfigSerializeWrapper();

        if (!PermName.isWriteable(this.getBrokerConfig().getBrokerPermission())
            || !PermName.isReadable(this.getBrokerConfig().getBrokerPermission())) {
            ConcurrentHashMap<String, TopicConfig> topicConfigTable = new ConcurrentHashMap<String, TopicConfig>();
            for (TopicConfig topicConfig : topicConfigWrapper.getTopicConfigTable().values()) {
                TopicConfig tmp =
                    new TopicConfig(topicConfig.getTopicName(), topicConfig.getReadQueueNums(), topicConfig.getWriteQueueNums(),
                        this.brokerConfig.getBrokerPermission());
                topicConfigTable.put(topicConfig.getTopicName(), tmp);
            }
            topicConfigWrapper.setTopicConfigTable(topicConfigTable);
        }
        // 强制注册或者进行周期性注册时间到时，向nameserver注册自身
        if (forceRegister || needRegister(this.brokerConfig.getBrokerClusterName(),
                                        this.getBrokerAddr(),
                                        this.brokerConfig.getBrokerName(),
                                        this.brokerConfig.getBrokerId(),
                                        this.brokerConfig.getRegisterBrokerTimeoutMills())) {
            doRegisterBrokerAll(checkOrderConfig, oneway, topicConfigWrapper);
        }
    }

    private void doRegisterBrokerAll(boolean checkOrderConfig, boolean oneway,
        TopicConfigSerializeWrapper topicConfigWrapper) {
        // 向多个nameserver依次注册
        List<RegisterBrokerResult> registerBrokerResultList = this.brokerOuterAPI.registerBrokerAll(
            this.brokerConfig.getBrokerClusterName(),
            this.getBrokerAddr(),
            this.brokerConfig.getBrokerName(),
            this.brokerConfig.getBrokerId(),
            this.getHAServerAddr(),
            topicConfigWrapper,
            this.filterServerManager.buildNewFilterServerList(),
            oneway,
            this.brokerConfig.getRegisterBrokerTimeoutMills(),
            this.brokerConfig.isCompressedRegister());

        if (registerBrokerResultList.size() > 0) {
            RegisterBrokerResult registerBrokerResult = registerBrokerResultList.get(0);
            if (registerBrokerResult != null) {
                if (this.updateMasterHAServerAddrPeriodically && registerBrokerResult.getHaServerAddr() != null) {
                    this.messageStore.updateHaMasterAddress(registerBrokerResult.getHaServerAddr());
                }
                // 更新master地址信息
                this.slaveSynchronize.setMasterAddr(registerBrokerResult.getMasterAddr());

                if (checkOrderConfig) {
                    this.getTopicConfigManager().updateOrderTopicConfig(registerBrokerResult.getKvTable());
                }
            }
        }
    }
    // org.apache.rocketmq.broker.out.BrokerOuterAPI#registerBrokerAll
    public List<RegisterBrokerResult> registerBrokerAll(
        final String clusterName,
        final String brokerAddr,
        final String brokerName,
        final long brokerId,
        final String haServerAddr,
        final TopicConfigSerializeWrapper topicConfigWrapper,
        final List<String> filterServerList,
        final boolean oneway,
        final int timeoutMills,
        final boolean compressed) {

        final List<RegisterBrokerResult> registerBrokerResultList = Lists.newArrayList();
        List<String> nameServerAddressList = this.remotingClient.getNameServerAddressList();
        if (nameServerAddressList != null && nameServerAddressList.size() > 0) {

            final RegisterBrokerRequestHeader requestHeader = new RegisterBrokerRequestHeader();
            requestHeader.setBrokerAddr(brokerAddr);
            requestHeader.setBrokerId(brokerId);
            requestHeader.setBrokerName(brokerName);
            requestHeader.setClusterName(clusterName);
            requestHeader.setHaServerAddr(haServerAddr);
            requestHeader.setCompressed(compressed);

            RegisterBrokerBody requestBody = new RegisterBrokerBody();
            requestBody.setTopicConfigSerializeWrapper(topicConfigWrapper);
            requestBody.setFilterServerList(filterServerList);
            final byte[] body = requestBody.encode(compressed);
            final int bodyCrc32 = UtilAll.crc32(body);
            requestHeader.setBodyCrc32(bodyCrc32);
            final CountDownLatch countDownLatch = new CountDownLatch(nameServerAddressList.size());
            for (final String namesrvAddr : nameServerAddressList) {
                // 多线程同时注册多个nameserver, 效果更佳
                brokerOuterExecutor.execute(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            RegisterBrokerResult result = registerBroker(namesrvAddr,oneway, timeoutMills,requestHeader,body);
                            if (result != null) {
                                registerBrokerResultList.add(result);
                            }

                            log.info("register broker[{}]to name server {} OK", brokerId, namesrvAddr);
                        } catch (Exception e) {
                            log.warn("registerBroker Exception, {}", namesrvAddr, e);
                        } finally {
                            countDownLatch.countDown();
                        }
                    }
                });
            }

            try {
                countDownLatch.await(timeoutMills, TimeUnit.MILLISECONDS);
            } catch (InterruptedException e) {
            }
        }

        return registerBrokerResultList;
    }
```

[![复制代码](RocketMQ(九)：主从同步的实现.assets/copycode.gif)](javascript:void(0);)

　　基本上，master与slave差别不大，各broker需要的功能，都会具有的。比如都会开启各服务端口，都会进行文件清理动作，都会向nameserver注册自身等等。唯一的差别在于，slave会另外开启一个同步的定时任务，每10秒向master发送一次同步请求，即 syncAll(); 那么，所谓的同步，到底是同步个啥？即其如何实现同步？

　　所有的主从同步的实现都在这里了：syncAll();

[![复制代码](RocketMQ(九)：主从同步的实现.assets/copycode.gif)](javascript:void(0);)

```
    // org.apache.rocketmq.broker.slave.SlaveSynchronize#syncAll
    public void syncAll() {
        // 同步topic配置信息
        this.syncTopicConfig();
        // 同步消费偏移量信息
        this.syncConsumerOffset();
        // 同步延迟信息
        this.syncDelayOffset();
        // 同步消费组信息数据，所以主从同步的核心，是基于消息的订阅来实现的
        this.syncSubscriptionGroupConfig();
    }

    // 同步topic配置信息
    private void syncTopicConfig() {
        String masterAddrBak = this.masterAddr;
        // 存在master地址，且该地址不是自身时，才会进行同步动作
        if (masterAddrBak != null && !masterAddrBak.equals(brokerController.getBrokerAddr())) {
            try {
                TopicConfigSerializeWrapper topicWrapper =
                    this.brokerController.getBrokerOuterAPI().getAllTopicConfig(masterAddrBak);
                // 版本发生变更，即数据有变化，则写入新的版本数据
                if (!this.brokerController.getTopicConfigManager().getDataVersion()
                    .equals(topicWrapper.getDataVersion())) {

                    this.brokerController.getTopicConfigManager().getDataVersion()
                        .assignNewOne(topicWrapper.getDataVersion());
                    this.brokerController.getTopicConfigManager().getTopicConfigTable().clear();
                    this.brokerController.getTopicConfigManager().getTopicConfigTable()
                        .putAll(topicWrapper.getTopicConfigTable());
                    // 持久化topic信息
                    this.brokerController.getTopicConfigManager().persist();

                    log.info("Update slave topic config from master, {}", masterAddrBak);
                }
            } catch (Exception e) {
                log.error("SyncTopicConfig Exception, {}", masterAddrBak, e);
            }
        }
    }

    // 同步消费偏移量信息
    private void syncConsumerOffset() {
        String masterAddrBak = this.masterAddr;
        if (masterAddrBak != null && !masterAddrBak.equals(brokerController.getBrokerAddr())) {
            try {
                ConsumerOffsetSerializeWrapper offsetWrapper =
                    this.brokerController.getBrokerOuterAPI().getAllConsumerOffset(masterAddrBak);
                this.brokerController.getConsumerOffsetManager().getOffsetTable()
                    .putAll(offsetWrapper.getOffsetTable());
                this.brokerController.getConsumerOffsetManager().persist();
                log.info("Update slave consumer offset from master, {}", masterAddrBak);
            } catch (Exception e) {
                log.error("SyncConsumerOffset Exception, {}", masterAddrBak, e);
            }
        }
    }
    // 额。。。 反正就是一个数字吧, 存储在 config/delayOffset.json 下
    private void syncDelayOffset() {
        String masterAddrBak = this.masterAddr;
        if (masterAddrBak != null && !masterAddrBak.equals(brokerController.getBrokerAddr())) {
            try {
                String delayOffset =
                    this.brokerController.getBrokerOuterAPI().getAllDelayOffset(masterAddrBak);
                if (delayOffset != null) {

                    String fileName =
                        StorePathConfigHelper.getDelayOffsetStorePath(this.brokerController
                            .getMessageStoreConfig().getStorePathRootDir());
                    try {
                        MixAll.string2File(delayOffset, fileName);
                    } catch (IOException e) {
                        log.error("Persist file Exception, {}", fileName, e);
                    }
                }
                log.info("Update slave delay offset from master, {}", masterAddrBak);
            } catch (Exception e) {
                log.error("SyncDelayOffset Exception, {}", masterAddrBak, e);
            }
        }
    }

    // 同步消费组信息数据
    private void syncSubscriptionGroupConfig() {
        String masterAddrBak = this.masterAddr;
        if (masterAddrBak != null  && !masterAddrBak.equals(brokerController.getBrokerAddr())) {
            try {
                SubscriptionGroupWrapper subscriptionWrapper =
                    this.brokerController.getBrokerOuterAPI()
                        .getAllSubscriptionGroupConfig(masterAddrBak);

                if (!this.brokerController.getSubscriptionGroupManager().getDataVersion()
                    .equals(subscriptionWrapper.getDataVersion())) {
                    SubscriptionGroupManager subscriptionGroupManager =
                        this.brokerController.getSubscriptionGroupManager();
                    subscriptionGroupManager.getDataVersion().assignNewOne(
                        subscriptionWrapper.getDataVersion());
                    subscriptionGroupManager.getSubscriptionGroupTable().clear();
                    subscriptionGroupManager.getSubscriptionGroupTable().putAll(
                        subscriptionWrapper.getSubscriptionGroupTable());
                    // 持久化消费组信息
                    subscriptionGroupManager.persist();
                    log.info("Update slave Subscription Group from master, {}", masterAddrBak);
                }
            } catch (Exception e) {
                log.error("SyncSubscriptionGroup Exception, {}", masterAddrBak, e);
            }
        }
    }
```

[![复制代码](RocketMQ(九)：主从同步的实现.assets/copycode.gif)](javascript:void(0);)

　　以上，就是rocketmq的主从同步的主体框架代码了。回答上面的几个疑问：同步个啥？同步4种数据：topic信息、消费偏移信息、延迟信息、订阅组信息；同步的及时性如何？每10秒发起一步同步请求，即延迟是10秒级的。

　　等等，以上同步的信息，看起来都是元数据信息。那么消息数据的同步去哪里了？这可是我们最关心的啊！

 

[返回顶部](https://www.cnblogs.com/yougewe/p/14198675.html#_labelTop)

### 4. rocketmq消息数据的同步实现

　　经过上一节的分析，我们好像摸到了点皮毛，然后发现不是想要的。因为定时任务只同步了元数据信息，而真正的数据信息同步去了哪里呢？实际上，它是由一个HAService去承载该功能的，HAService会使用的一个主循环，一直不停地向master拉取数据，然后添加到自身的commitlog文件中，从而实现真正的数据同步。

 



#### 4.1. HAService的开启

　　同步服务是一系列专门的实现的，它包括server端，客户端以及一些维护线程。这需要我们分开理解。同步服务的开启，是在messageStore初始化时做的。它会读取一个单独的端口配置，开启HA同步服务。

[![复制代码](RocketMQ(九)：主从同步的实现.assets/copycode.gif)](javascript:void(0);)

```
    // org.apache.rocketmq.store.DefaultMessageStore#DefaultMessageStore
    public DefaultMessageStore(final MessageStoreConfig messageStoreConfig, final BrokerStatsManager brokerStatsManager,
        final MessageArrivingListener messageArrivingListener, final BrokerConfig brokerConfig) throws IOException {
        this.messageArrivingListener = messageArrivingListener;
        this.brokerConfig = brokerConfig;
        this.messageStoreConfig = messageStoreConfig;
        this.brokerStatsManager = brokerStatsManager;
        this.allocateMappedFileService = new AllocateMappedFileService(this);
        if (messageStoreConfig.isEnableDLegerCommitLog()) {
            this.commitLog = new DLedgerCommitLog(this);
        } else {
            this.commitLog = new CommitLog(this);
        }
        this.consumeQueueTable = new ConcurrentHashMap<>(32);

        this.flushConsumeQueueService = new FlushConsumeQueueService();
        this.cleanCommitLogService = new CleanCommitLogService();
        this.cleanConsumeQueueService = new CleanConsumeQueueService();
        this.storeStatsService = new StoreStatsService();
        this.indexService = new IndexService(this);
        if (!messageStoreConfig.isEnableDLegerCommitLog()) {
            // 初始化 HAService
            this.haService = new HAService(this);
        } else {
            this.haService = null;
        }
        ...
        File file = new File(StorePathConfigHelper.getLockFile(messageStoreConfig.getStorePathRootDir()));
        MappedFile.ensureDirOK(file.getParent());
        lockFile = new RandomAccessFile(file, "rw");
    }

    // org.apache.rocketmq.store.ha.HAService#HAService
    public HAService(final DefaultMessageStore defaultMessageStore) throws IOException {
        this.defaultMessageStore = defaultMessageStore;
        // 开启server端服务
        this.acceptSocketService =
            new AcceptSocketService(defaultMessageStore.getMessageStoreConfig().getHaListenPort());
        this.groupTransferService = new GroupTransferService();
        // 初始化client
        this.haClient = new HAClient();
    }
    // 具体运行则都会被视为一个个的后台线程，会在start()操作中统一运行起来
    public void start() throws Exception {
        // server端服务启动，由master节点管控
        this.acceptSocketService.beginAccept();
        this.acceptSocketService.start();
        // 数据中转服务，它会接收用户的写请求，然后吐数据给到各slave节点
        this.groupTransferService.start();
        // 客户端请求服务，由slave节点发起
        this.haClient.start();
    }
```

[![复制代码](RocketMQ(九)：主从同步的实现.assets/copycode.gif)](javascript:void(0);)

　　HAService作为rocketmq中的一个小型服务，运行在后台线程中，为了简单起见或者资源隔离，它使用一些单独的端口和通信实现处理。也可谓麻雀虽小，五脏俱全。下面我就分三个单独的部分讲解下如何实现数据同步。

 



#### 4.2. 从节点同步实现

　　从节点负责主动拉取主节点数据，是一个比较重要的步骤。它的实现是在 HAClient 中的，该client启动起来之后，会一直不停地向master请求新的数据，然后同步到自己的commitlog中。

[![复制代码](RocketMQ(九)：主从同步的实现.assets/copycode.gif)](javascript:void(0);)

```
        // org.apache.rocketmq.store.ha.HAService.HAClient#run
        @Override
        public void run() {
            log.info(this.getServiceName() + " service started");

            while (!this.isStopped()) {
                try {
                    // 使用原生nio, 尝试连接至master
                    if (this.connectMaster()) {

                        if (this.isTimeToReportOffset()) {
                            // 隔一段时间向master汇报一次本slave的同步信息
                            boolean result = this.reportSlaveMaxOffset(this.currentReportedOffset);
                            // 如果连接无效，则关闭，下次再循环周期将会重新发起连接
                            if (!result) {
                                this.closeMaster();
                            }
                        }
                        this.selector.select(1000);
                        // 核心逻辑：处理获取到的消息数据
                        boolean ok = this.processReadEvent();
                        if (!ok) {
                            this.closeMaster();
                        }

                        if (!reportSlaveMaxOffsetPlus()) {
                            continue;
                        }

                        long interval =
                            HAService.this.getDefaultMessageStore().getSystemClock().now()
                                - this.lastWriteTimestamp;
                        if (interval > HAService.this.getDefaultMessageStore().getMessageStoreConfig()
                            .getHaHousekeepingInterval()) {
                            log.warn("HAClient, housekeeping, found this connection[" + this.masterAddress
                                + "] expired, " + interval);
                            this.closeMaster();
                            log.warn("HAClient, master not response some time, so close connection");
                        }
                    } else {
                        // 未连接成功，5秒后重试，可能会一直无用
                        this.waitForRunning(1000 * 5);
                    }
                } catch (Exception e) {
                    log.warn(this.getServiceName() + " service has exception. ", e);
                    this.waitForRunning(1000 * 5);
                }
            }

            log.info(this.getServiceName() + " service end");
        }
        
        private boolean connectMaster() throws ClosedChannelException {
            // 单例长链接
            if (null == socketChannel) {
                String addr = this.masterAddress.get();
                // 如果没有master, 则返回空
                // 针对master节点，也是同样的运行，只是不会连接到任何节点而已
                if (addr != null) {

                    SocketAddress socketAddress = RemotingUtil.string2SocketAddress(addr);
                    if (socketAddress != null) {
                        // 原生nio实现
                        this.socketChannel = RemotingUtil.connect(socketAddress);
                        if (this.socketChannel != null) {
                            this.socketChannel.register(this.selector, SelectionKey.OP_READ);
                        }
                    }
                }

                this.currentReportedOffset = HAService.this.defaultMessageStore.getMaxPhyOffset();

                this.lastWriteTimestamp = System.currentTimeMillis();
            }

            return this.socketChannel != null;
        }
    // org.apache.rocketmq.remoting.common.RemotingUtil#connect
    public static SocketChannel connect(SocketAddress remote) {
        return connect(remote, 1000 * 5);
    }
    public static SocketChannel connect(SocketAddress remote, final int timeoutMillis) {
        SocketChannel sc = null;
        try {
            sc = SocketChannel.open();
            sc.configureBlocking(true);
            sc.socket().setSoLinger(false, -1);
            sc.socket().setTcpNoDelay(true);
            sc.socket().setReceiveBufferSize(1024 * 64);
            sc.socket().setSendBufferSize(1024 * 64);
            sc.socket().connect(remote, timeoutMillis);
            sc.configureBlocking(false);
            return sc;
        } catch (Exception e) {
            if (sc != null) {
                try {
                    sc.close();
                } catch (IOException e1) {
                    e1.printStackTrace();
                }
            }
        }
        return null;
    }
    processReadEvent() 即是在收到master的新数据后，实现如何同步到本broker的commitlog中。其实现主要还是依赖于commitlogService.
        // org.apache.rocketmq.store.ha.HAService.HAClient#processReadEvent
        private boolean processReadEvent() {
            int readSizeZeroTimes = 0;
            while (this.byteBufferRead.hasRemaining()) {
                try {
                    int readSize = this.socketChannel.read(this.byteBufferRead);
                    if (readSize > 0) {
                        readSizeZeroTimes = 0;
                        boolean result = this.dispatchReadRequest();
                        if (!result) {
                            log.error("HAClient, dispatchReadRequest error");
                            return false;
                        }
                    } else if (readSize == 0) {
                        if (++readSizeZeroTimes >= 3) {
                            break;
                        }
                    } else {
                        log.info("HAClient, processReadEvent read socket < 0");
                        return false;
                    }
                } catch (IOException e) {
                    log.info("HAClient, processReadEvent read socket exception", e);
                    return false;
                }
            }

            return true;
        }

        private boolean dispatchReadRequest() {
            // 按协议读取数据
            final int msgHeaderSize = 8 + 4; // phyoffset + size
            int readSocketPos = this.byteBufferRead.position();

            while (true) {
                int diff = this.byteBufferRead.position() - this.dispatchPosition;
                if (diff >= msgHeaderSize) {
                    long masterPhyOffset = this.byteBufferRead.getLong(this.dispatchPosition);
                    int bodySize = this.byteBufferRead.getInt(this.dispatchPosition + 8);

                    long slavePhyOffset = HAService.this.defaultMessageStore.getMaxPhyOffset();

                    if (slavePhyOffset != 0) {
                        if (slavePhyOffset != masterPhyOffset) {
                            log.error("master pushed offset not equal the max phy offset in slave, SLAVE: "
                                + slavePhyOffset + " MASTER: " + masterPhyOffset);
                            return false;
                        }
                    }
                    // 数据读取完成，则立即添加到存储中
                    if (diff >= (msgHeaderSize + bodySize)) {
                        byte[] bodyData = new byte[bodySize];
                        this.byteBufferRead.position(this.dispatchPosition + msgHeaderSize);
                        this.byteBufferRead.get(bodyData);

                        HAService.this.defaultMessageStore.appendToCommitLog(masterPhyOffset, bodyData);

                        this.byteBufferRead.position(readSocketPos);
                        this.dispatchPosition += msgHeaderSize + bodySize;

                        if (!reportSlaveMaxOffsetPlus()) {
                            return false;
                        }

                        continue;
                    }
                }

                if (!this.byteBufferRead.hasRemaining()) {
                    this.reallocateByteBuffer();
                }

                break;
            }

            return true;
        }
    // org.apache.rocketmq.store.DefaultMessageStore#appendToCommitLog
    @Override
    public boolean appendToCommitLog(long startOffset, byte[] data) {
        if (this.shutdown) {
            log.warn("message store has shutdown, so appendToPhyQueue is forbidden");
            return false;
        }
        // 添加到commitlog中，并生成后续的consumeQueue,index等相关信息
        boolean result = this.commitLog.appendData(startOffset, data);
        if (result) {
            this.reputMessageService.wakeup();
        } else {
            log.error("appendToPhyQueue failed " + startOffset + " " + data.length);
        }

        return result;
    }
```

[![复制代码](RocketMQ(九)：主从同步的实现.assets/copycode.gif)](javascript:void(0);)

　　从slave节点的处理流程，我们基本上已经完全搞清楚了rocketmq如何同步数据的了。单独开启一个端口用于同步数据，slave一直不停地轮询master, 拿到新数据后，就将其添加到自身的commitlog中，构造自身的数据集。从而保持与master的同步。（请需要注意数据一致性）

 



#### 4.3. master的数据同步服务

　　从节点负责不停从主节点拉取数据，所以主节点只要给到数据就可以了。但至少，主节点还是有一个网络服务，以便接受从节点的请求。

　　这同样是在 HAService中，它直接以nio的形式开启一个服务端口，从而接收请求：

[![复制代码](RocketMQ(九)：主从同步的实现.assets/copycode.gif)](javascript:void(0);)

```
    // org.apache.rocketmq.store.ha.HAService.AcceptSocketService
    /**
     * Listens to slave connections to create {@link HAConnection}.
     */
    class AcceptSocketService extends ServiceThread {
        private final SocketAddress socketAddressListen;
        private ServerSocketChannel serverSocketChannel;
        private Selector selector;
        // 给定端口监听
        public AcceptSocketService(final int port) {
            this.socketAddressListen = new InetSocketAddress(port);
        }

        /**
         * Starts listening to slave connections.
         *
         * @throws Exception If fails.
         */
        public void beginAccept() throws Exception {
            this.serverSocketChannel = ServerSocketChannel.open();
            this.selector = RemotingUtil.openSelector();
            this.serverSocketChannel.socket().setReuseAddress(true);
            this.serverSocketChannel.socket().bind(this.socketAddressListen);
            this.serverSocketChannel.configureBlocking(false);
            this.serverSocketChannel.register(this.selector, SelectionKey.OP_ACCEPT);
        }

        /**
         * {@inheritDoc}
         */
        @Override
        public void run() {
            log.info(this.getServiceName() + " service started");

            while (!this.isStopped()) {
                try {
                    this.selector.select(1000);
                    Set<SelectionKey> selected = this.selector.selectedKeys();

                    if (selected != null) {
                        for (SelectionKey k : selected) {
                            if ((k.readyOps() & SelectionKey.OP_ACCEPT) != 0) {
                                SocketChannel sc = ((ServerSocketChannel) k.channel()).accept();

                                if (sc != null) {
                                    HAService.log.info("HAService receive new connection, "
                                        + sc.socket().getRemoteSocketAddress());

                                    try {
                                        HAConnection conn = new HAConnection(HAService.this, sc);
                                        // accept 接入后，开启另外的读线程处理数据请求
                                        conn.start();
                                        HAService.this.addConnection(conn);
                                    } catch (Exception e) {
                                        log.error("new HAConnection exception", e);
                                        sc.close();
                                    }
                                }
                            } else {
                                log.warn("Unexpected ops in select " + k.readyOps());
                            }
                        }

                        selected.clear();
                    }
                } catch (Exception e) {
                    log.error(this.getServiceName() + " service has exception.", e);
                }
            }

            log.info(this.getServiceName() + " service end");
        }
        ...
    }
    // org.apache.rocketmq.store.ha.HAConnection#start
    public void start() {
        this.readSocketService.start();
        this.writeSocketService.start();
    }
        // org.apache.rocketmq.store.ha.HAConnection.ReadSocketService#run
        @Override
        public void run() {
            HAConnection.log.info(this.getServiceName() + " service started");

            while (!this.isStopped()) {
                try {
                    this.selector.select(1000);
                    boolean ok = this.processReadEvent();
                    if (!ok) {
                        HAConnection.log.error("processReadEvent error");
                        break;
                    }

                    long interval = HAConnection.this.haService.getDefaultMessageStore().getSystemClock().now() - this.lastReadTimestamp;
                    if (interval > HAConnection.this.haService.getDefaultMessageStore().getMessageStoreConfig().getHaHousekeepingInterval()) {
                        log.warn("ha housekeeping, found this connection[" + HAConnection.this.clientAddr + "] expired, " + interval);
                        break;
                    }
                } catch (Exception e) {
                    HAConnection.log.error(this.getServiceName() + " service has exception.", e);
                    break;
                }
            }

            this.makeStop();

            writeSocketService.makeStop();

            haService.removeConnection(HAConnection.this);

            HAConnection.this.haService.getConnectionCount().decrementAndGet();

            SelectionKey sk = this.socketChannel.keyFor(this.selector);
            if (sk != null) {
                sk.cancel();
            }

            try {
                this.selector.close();
                this.socketChannel.close();
            } catch (IOException e) {
                HAConnection.log.error("", e);
            }

            HAConnection.log.info(this.getServiceName() + " service end");
        }

        private boolean processReadEvent() {
            int readSizeZeroTimes = 0;

            if (!this.byteBufferRead.hasRemaining()) {
                this.byteBufferRead.flip();
                this.processPosition = 0;
            }

            while (this.byteBufferRead.hasRemaining()) {
                try {
                    int readSize = this.socketChannel.read(this.byteBufferRead);
                    if (readSize > 0) {
                        readSizeZeroTimes = 0;
                        this.lastReadTimestamp = HAConnection.this.haService.getDefaultMessageStore().getSystemClock().now();
                        if ((this.byteBufferRead.position() - this.processPosition) >= 8) {
                            int pos = this.byteBufferRead.position() - (this.byteBufferRead.position() % 8);
                            long readOffset = this.byteBufferRead.getLong(pos - 8);
                            this.processPosition = pos;
                            // 读取唯一参数
                            HAConnection.this.slaveAckOffset = readOffset;
                            if (HAConnection.this.slaveRequestOffset < 0) {
                                HAConnection.this.slaveRequestOffset = readOffset;
                                log.info("slave[" + HAConnection.this.clientAddr + "] request offset " + readOffset);
                            }
                            // ...
                            HAConnection.this.haService.notifyTransferSome(HAConnection.this.slaveAckOffset);
                        }
                    } else if (readSize == 0) {
                        if (++readSizeZeroTimes >= 3) {
                            break;
                        }
                    } else {
                        log.error("read socket[" + HAConnection.this.clientAddr + "] < 0");
                        return false;
                    }
                } catch (IOException e) {
                    log.error("processReadEvent exception", e);
                    return false;
                }
            }

            return true;
        }
    // org.apache.rocketmq.store.ha.HAService#notifyTransferSome
    public void notifyTransferSome(final long offset) {
        for (long value = this.push2SlaveMaxOffset.get(); offset > value; ) {
            boolean ok = this.push2SlaveMaxOffset.compareAndSet(value, offset);
            if (ok) {
                this.groupTransferService.notifyTransferSome();
                break;
            } else {
                value = this.push2SlaveMaxOffset.get();
            }
        }
    }
```

[![复制代码](RocketMQ(九)：主从同步的实现.assets/copycode.gif)](javascript:void(0);)

　　端口开启及接受请求很容易，但如何响应客户端还是有点复杂的。各自同学自行深入吧！

　　GroupCommitService 通过一个写队列和读队列，在有消息写入时将被调用，从而达到实时通知的目的。

[![复制代码](RocketMQ(九)：主从同步的实现.assets/copycode.gif)](javascript:void(0);)

```
        // org.apache.rocketmq.store.ha.HAService.GroupTransferService#putRequest
        public synchronized void putRequest(final CommitLog.GroupCommitRequest request) {
            synchronized (this.requestsWrite) {
                this.requestsWrite.add(request);
            }
            this.wakeup();
        }

        public void notifyTransferSome() {
            this.notifyTransferObject.wakeup();
        }

        private void swapRequests() {
            // 交换buffer
            List<CommitLog.GroupCommitRequest> tmp = this.requestsWrite;
            this.requestsWrite = this.requestsRead;
            this.requestsRead = tmp;
        }

        private void doWaitTransfer() {
            synchronized (this.requestsRead) {
                if (!this.requestsRead.isEmpty()) {
                    for (CommitLog.GroupCommitRequest req : this.requestsRead) {
                        boolean transferOK = HAService.this.push2SlaveMaxOffset.get() >= req.getNextOffset();
                        long waitUntilWhen = HAService.this.defaultMessageStore.getSystemClock().now()
                            + HAService.this.defaultMessageStore.getMessageStoreConfig().getSyncFlushTimeout();
                        while (!transferOK && HAService.this.defaultMessageStore.getSystemClock().now() < waitUntilWhen) {
                            this.notifyTransferObject.waitForRunning(1000);
                            transferOK = HAService.this.push2SlaveMaxOffset.get() >= req.getNextOffset();
                        }

                        if (!transferOK) {
                            log.warn("transfer messsage to slave timeout, " + req.getNextOffset());
                        }

                        req.wakeupCustomer(transferOK ? PutMessageStatus.PUT_OK : PutMessageStatus.FLUSH_SLAVE_TIMEOUT);
                    }

                    this.requestsRead.clear();
                }
            }
        }

        public void run() {
            log.info(this.getServiceName() + " service started");

            while (!this.isStopped()) {
                try {
                    this.waitForRunning(10);
                    this.doWaitTransfer();
                } catch (Exception e) {
                    log.warn(this.getServiceName() + " service has exception. ", e);
                }
            }

            log.info(this.getServiceName() + " service end");
        }
```

[![复制代码](RocketMQ(九)：主从同步的实现.assets/copycode.gif)](javascript:void(0);)

　　至此，rocketmq主从同步解析完成。rocketmq基于commitlog实现核心主从同步，以及其他多个元数据信息的简单定时同步，并以两个缓冲buffer的形式，及时将数据推送到从节点。保证了尽量好的数据一致性。

 

　　最后，我们需要注意一个问题，就是主从的数据一致性到底是如何保证的？因为主的数据是直接写入的，那么从的数据又如何保证与主的一样，或者简单说就是，如何保证写入的顺序呢？如果某两条记录插入commitlog的顺序不一样，那么最终就会乱序，结果就完不一样了，比如进行主从切换，那么如果使用相同的偏移量进行取值，必然会得到不一样的结果。

　　实际上，从服务器仅使用一条线程进行数据同步，即拉取到的数据顺序是一致的，写入commitlog也是用同一条线程进行写入，自然就不会存在乱序问题了。这可能也是主从同步不能使用netty这种通信框架的原因，没必要也不能做。主从同步要求保证严格的顺序性，而无需过多考虑并发性。就像redis的单线程，同样撑起超高的性能。rocketmq主从同步基于原生 nio, 加上pagecache, mmap 同样实现了超高的性能。也就无需单线程同步会导致很大延迟了。

 

不要害怕今日的苦，你要相信明天，更苦！

分类: [协议类](https://www.cnblogs.com/yougewe/category/755891.html), [原理&故事](https://www.cnblogs.com/yougewe/category/789557.html), [并发&性能](https://www.cnblogs.com/yougewe/category/844109.html), [java](https://www.cnblogs.com/yougewe/category/923459.html), [大数据](https://www.cnblogs.com/yougewe/category/1238476.html), [源码](https://www.cnblogs.com/yougewe/category/1278448.html), [算法](https://www.cnblogs.com/yougewe/category/1844743.html)

标签: [commitlog](https://www.cnblogs.com/yougewe/tag/commitlog/), [主从同步](https://www.cnblogs.com/yougewe/tag/主从同步/), [高可用](https://www.cnblogs.com/yougewe/tag/高可用/), [rocketmq](https://www.cnblogs.com/yougewe/tag/rocketmq/), [nio](https://www.cnblogs.com/yougewe/tag/nio/), [双缓冲](https://www.cnblogs.com/yougewe/tag/双缓冲/), [定长存储](https://www.cnblogs.com/yougewe/tag/定长存储/)