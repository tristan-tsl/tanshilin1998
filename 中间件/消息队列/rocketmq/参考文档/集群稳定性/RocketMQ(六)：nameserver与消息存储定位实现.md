# [RocketMQ(六)：nameserver与消息存储定位实现](https://www.cnblogs.com/yougewe/p/14128845.html)



**目录**

- [1. 为什么会有nameserver？](https://www.cnblogs.com/yougewe/p/14128845.html#_label0)
- [2. nameserver的启动流程解析](https://www.cnblogs.com/yougewe/p/14128845.html#_label1)
- [3. nameserver 业务处理框架](https://www.cnblogs.com/yougewe/p/14128845.html#_label2)
- [4. topic存储位置策略](https://www.cnblogs.com/yougewe/p/14128845.html#_label3)
- [5. MessageQueue到底存在哪里？](https://www.cnblogs.com/yougewe/p/14128845.html#_label4)



------

　　在rocketmq中，nameserver充当了一个配置管理者的角色，看起来好似不太重要。然而它是一个不或缺的角色，没有了它的存在，各个broker就是一盘散沙，各自为战。

　　所以，实际上，在rocketmq中，nameserver也是一个领导者的角色。它可以决定哪个消息存储到哪里，哪个broker干活或者上下线，在出现异常情况时，它要能够及时处理。以便让整个团队发挥应有的作用。nameserver相当于一个分布式系统的协调者。但是这个名字，是不是看起来很熟悉？请看后续！

 

[返回顶部](https://www.cnblogs.com/yougewe/p/14128845.html#_labelTop)

### 1. 为什么会有nameserver？

　　如文章开头所说，nameserver担任的，差不多是一个系统协调者这么个角色。那么，我们知道，在分布式协调工作方面，有很多现成的组件可用。比如 zookeeper, 那么为什么还要自己搞一套nameserver出来？是为了刷存在感？

　　对于为什么不选择zk之类的组件实现协调者角色，初衷如何我们不得而知。但至少有几个可知答案可以做下支撑：（以zk为例）

　　　　1. zk存在大量的集群间通信；
　　　　2. zk是一个比较重的组件，而本身就作为消息中间的mq，则最好不好另外再依赖其他组件；（个人感觉）
　　　　3. zk对于数据的固化能力比较弱，配置往往受限于zk的数据格式；

　　总体来说，可能就是rocketmq想要做的功能在zk上不太好做，或者做起来也费劲，或者太重，索性就不要搞了。自己搞一个完全定制化的好了。事实上，rocketmq的nameserver也实现得相当简单轻量。这也是设计者的初衷吧。

 

[返回顶部](https://www.cnblogs.com/yougewe/p/14128845.html#_labelTop)

### 2. nameserver的启动流程解析

　　一般地，一个框架级别的服务启动，还是有些复杂的，那样的话，我们懒得去看其具体过程。但前面说了，nameserver实现得非常轻量级，所以，其启动也就相当简单。所以，我们可以快速一览其过程。

　　整个nameserver的启动类是 org.apache.rocketmq.namesrv.NamesrvStartup, 工作过程大致如下：

[![复制代码](RocketMQ(六)：nameserver与消息存储定位实现.assets/copycode.gif)](javascript:void(0);)

```
    // 入口main
    public static void main(String[] args) {
        main0(args);
    }

    public static NamesrvController main0(String[] args) {
        try {
            // 创建本服务的核心控制器, 解析各种配置参数，默认值之类的
            NamesrvController controller = createNamesrvController(args);
            // 开启服务, 如打开
            start(controller);
            String tip = "The Name Server boot success. serializeType=" + RemotingCommand.getSerializeTypeConfigInThisServer();
            log.info(tip);
            System.out.printf("%s%n", tip);
            return controller;
        } catch (Throwable e) {
            e.printStackTrace();
            System.exit(-1);
        }

        return null;
    }
```

[![复制代码](RocketMQ(六)：nameserver与消息存储定位实现.assets/copycode.gif)](javascript:void(0);)

　　所以整个启动过程，基本就是一个 Controller 搞定了，你说不简单吗？额，也许不一定！整个创建 Controller 的过程就是解析参数的过程，有兴趣可以打开如下代码看看：

![img](RocketMQ(六)：nameserver与消息存储定位实现.assets/ContractedBlock.gif) View Code

　　接下来，我们主要来看看这start()过程到底如何，复杂性必然都在这里了。

[![复制代码](RocketMQ(六)：nameserver与消息存储定位实现.assets/copycode.gif)](javascript:void(0);)

```
    // org.apache.rocketmq.namesrv.NamesrvStartup#start
    public static NamesrvController start(final NamesrvController controller) throws Exception {

        if (null == controller) {
            throw new IllegalArgumentException("NamesrvController is null");
        }
        // 初始化controller各环境，如果失败，则退出启动
        boolean initResult = controller.initialize();
        if (!initResult) {
            controller.shutdown();
            System.exit(-3);
        }
        // 注册一个关闭钩子
        Runtime.getRuntime().addShutdownHook(new ShutdownHookThread(log, new Callable<Void>() {
            @Override
            public Void call() throws Exception {
                controller.shutdown();
                return null;
            }
        }));
        // 核心start()方法
        controller.start();

        return controller;
    }
    // org.apache.rocketmq.namesrv.NamesrvController#initialize
    public boolean initialize() {

        this.kvConfigManager.load();

        this.remotingServer = new NettyRemotingServer(this.nettyServerConfig, this.brokerHousekeepingService);

        this.remotingExecutor =
            Executors.newFixedThreadPool(nettyServerConfig.getServerWorkerThreads(), new ThreadFactoryImpl("RemotingExecutorThread_"));
        // 注册处理器
        this.registerProcessor();
        // 启动后台扫描线程，扫描掉线的broker
        this.scheduledExecutorService.scheduleAtFixedRate(new Runnable() {

            @Override
            public void run() {
                NamesrvController.this.routeInfoManager.scanNotActiveBroker();
            }
        }, 5, 10, TimeUnit.SECONDS);
        // 打印日志定时任务
        this.scheduledExecutorService.scheduleAtFixedRate(new Runnable() {

            @Override
            public void run() {
                NamesrvController.this.kvConfigManager.printAllPeriodically();
            }
        }, 1, 10, TimeUnit.MINUTES);

        if (TlsSystemConfig.tlsMode != TlsMode.DISABLED) {
            // Register a listener to reload SslContext
            try {
                fileWatchService = new FileWatchService(
                    new String[] {
                        TlsSystemConfig.tlsServerCertPath,
                        TlsSystemConfig.tlsServerKeyPath,
                        TlsSystemConfig.tlsServerTrustCertPath
                    },
                    new FileWatchService.Listener() {
                        boolean certChanged, keyChanged = false;
                        @Override
                        public void onChanged(String path) {
                            if (path.equals(TlsSystemConfig.tlsServerTrustCertPath)) {
                                log.info("The trust certificate changed, reload the ssl context");
                                reloadServerSslContext();
                            }
                            if (path.equals(TlsSystemConfig.tlsServerCertPath)) {
                                certChanged = true;
                            }
                            if (path.equals(TlsSystemConfig.tlsServerKeyPath)) {
                                keyChanged = true;
                            }
                            if (certChanged && keyChanged) {
                                log.info("The certificate and private key changed, reload the ssl context");
                                certChanged = keyChanged = false;
                                reloadServerSslContext();
                            }
                        }
                        private void reloadServerSslContext() {
                            ((NettyRemotingServer) remotingServer).loadSslContext();
                        }
                    });
            } catch (Exception e) {
                log.warn("FileWatchService created error, can't load the certificate dynamically");
            }
        }
        // no false
        return true;
    }
    private void registerProcessor() {
        if (namesrvConfig.isClusterTest()) {

            this.remotingServer.registerDefaultProcessor(new ClusterTestRequestProcessor(this, namesrvConfig.getProductEnvName()),
                this.remotingExecutor);
        } else {
            // 只会有一个处理器处理业务
            this.remotingServer.registerDefaultProcessor(new DefaultRequestProcessor(this), this.remotingExecutor);
        }
    }
    
    // 初始化完成后，接下来是 start() 方法
    // org.apache.rocketmq.namesrv.NamesrvController#start
    public void start() throws Exception {
        // 开启后台端口服务，nameserver可连接
        this.remotingServer.start();
        // 文件检测线程
        if (this.fileWatchService != null) {
            this.fileWatchService.start();
        }
    }
```

[![复制代码](RocketMQ(六)：nameserver与消息存储定位实现.assets/copycode.gif)](javascript:void(0);)

　　可见，controller的启动过程也非常简单，就是设置好各初始实例，开几个后台定时任务，注册处理器，然后将tcp端口打开，即可。其中端口服务是使用netty作为通信组件，其操作完全遵从netty编程范式。可自行查阅。

![img](RocketMQ(六)：nameserver与消息存储定位实现.assets/ContractedBlock.gif) View Code

　　至此，nameserver的启动流程就完成了，果然是轻量级。至于其提供什么样的服务，我们下一节再讲。

 

[返回顶部](https://www.cnblogs.com/yougewe/p/14128845.html#_labelTop)

### 3. nameserver 业务处理框架

　　因nameserver和broker一样，都共用了remoting模块的代码，即都依赖于netty的handler处理机制。所以其处理器入口都是一样的。反正最终都是找到对应的processor, 然后处理业务即可。此处，nameserver只会提供一个默认的处理器，即DefaultRequestProcessor。所以，只需了解其processRequest()即可知nameserver的整体能力了。

[![复制代码](RocketMQ(六)：nameserver与消息存储定位实现.assets/copycode.gif)](javascript:void(0);)

```
    // org.apache.rocketmq.namesrv.processor.DefaultRequestProcessor#processRequest
    @Override
    public RemotingCommand processRequest(ChannelHandlerContext ctx,
        RemotingCommand request) throws RemotingCommandException {

        if (ctx != null) {
            log.debug("receive request, {} {} {}",
                request.getCode(),
                RemotingHelper.parseChannelRemoteAddr(ctx.channel()),
                request);
        }

        switch (request.getCode()) {
            case RequestCode.PUT_KV_CONFIG:
                return this.putKVConfig(ctx, request);
            case RequestCode.GET_KV_CONFIG:
                return this.getKVConfig(ctx, request);
            case RequestCode.DELETE_KV_CONFIG:
                return this.deleteKVConfig(ctx, request);
            case RequestCode.QUERY_DATA_VERSION:
                return queryBrokerTopicConfig(ctx, request);
            // 注册broker信息，这种操作一般是在broker启动的时候进行请求
            case RequestCode.REGISTER_BROKER:
                Version brokerVersion = MQVersion.value2Version(request.getVersion());
                if (brokerVersion.ordinal() >= MQVersion.Version.V3_0_11.ordinal()) {
                    return this.registerBrokerWithFilterServer(ctx, request);
                } else {
                    return this.registerBroker(ctx, request);
                }
            // 下线broker
            case RequestCode.UNREGISTER_BROKER:
                return this.unregisterBroker(ctx, request);
            // 获取路由信息，即哪个topic存在于哪些broker上，哪些messageQueue在哪里等
            case RequestCode.GET_ROUTEINFO_BY_TOPIC:
                return this.getRouteInfoByTopic(ctx, request);
            case RequestCode.GET_BROKER_CLUSTER_INFO:
                return this.getBrokerClusterInfo(ctx, request);
            case RequestCode.WIPE_WRITE_PERM_OF_BROKER:
                return this.wipeWritePermOfBroker(ctx, request);
            case RequestCode.GET_ALL_TOPIC_LIST_FROM_NAMESERVER:
                return getAllTopicListFromNameserver(ctx, request);
            case RequestCode.DELETE_TOPIC_IN_NAMESRV:
                return deleteTopicInNamesrv(ctx, request);
            case RequestCode.GET_KVLIST_BY_NAMESPACE:
                return this.getKVListByNamespace(ctx, request);
            case RequestCode.GET_TOPICS_BY_CLUSTER:
                return this.getTopicsByCluster(ctx, request);
            case RequestCode.GET_SYSTEM_TOPIC_LIST_FROM_NS:
                return this.getSystemTopicListFromNs(ctx, request);
            case RequestCode.GET_UNIT_TOPIC_LIST:
                return this.getUnitTopicList(ctx, request);
            case RequestCode.GET_HAS_UNIT_SUB_TOPIC_LIST:
                return this.getHasUnitSubTopicList(ctx, request);
            case RequestCode.GET_HAS_UNIT_SUB_UNUNIT_TOPIC_LIST:
                return this.getHasUnitSubUnUnitTopicList(ctx, request);
            case RequestCode.UPDATE_NAMESRV_CONFIG:
                return this.updateConfig(ctx, request);
            case RequestCode.GET_NAMESRV_CONFIG:
                return this.getConfig(ctx, request);
            default:
                break;
        }
        return null;
    }
```

[![复制代码](RocketMQ(六)：nameserver与消息存储定位实现.assets/copycode.gif)](javascript:void(0);)

　　以上就是整个nameserver提供的服务列表了，也没啥注释，见字如悟吧，我们也不想过多纠缠。但总体上，其处理的业务类型并不多，主要有三类：

　　　　1. 配置信息kv的操作；
　　　　2. broker上下线管理操作；
　　　　3. topic路由信息管理服务；

　　各自实现当然是按照业务处理，本无需多说，但为了解概要，我们还是挑一个重点来说说吧：broker的上线处理注册：

[![复制代码](RocketMQ(六)：nameserver与消息存储定位实现.assets/copycode.gif)](javascript:void(0);)

```
    // 为保持前沿起见，咱们以高版本服务展开思路（即版本大于3.0.11）
    public RemotingCommand registerBrokerWithFilterServer(ChannelHandlerContext ctx, RemotingCommand request)
        throws RemotingCommandException {
        final RemotingCommand response = RemotingCommand.createResponseCommand(RegisterBrokerResponseHeader.class);
        final RegisterBrokerResponseHeader responseHeader = (RegisterBrokerResponseHeader) response.readCustomHeader();
        final RegisterBrokerRequestHeader requestHeader =
            (RegisterBrokerRequestHeader) request.decodeCommandCustomHeader(RegisterBrokerRequestHeader.class);

        if (!checksum(ctx, request, requestHeader)) {
            response.setCode(ResponseCode.SYSTEM_ERROR);
            response.setRemark("crc32 not match");
            return response;
        }

        RegisterBrokerBody registerBrokerBody = new RegisterBrokerBody();

        if (request.getBody() != null) {
            try {
                registerBrokerBody = RegisterBrokerBody.decode(request.getBody(), requestHeader.isCompressed());
            } catch (Exception e) {
                throw new RemotingCommandException("Failed to decode RegisterBrokerBody", e);
            }
        } else {
            registerBrokerBody.getTopicConfigSerializeWrapper().getDataVersion().setCounter(new AtomicLong(0));
            registerBrokerBody.getTopicConfigSerializeWrapper().getDataVersion().setTimestamp(0);
        }
        // 重点实现: registerBroker
        RegisterBrokerResult result = this.namesrvController.getRouteInfoManager().registerBroker(
            requestHeader.getClusterName(),
            requestHeader.getBrokerAddr(),
            requestHeader.getBrokerName(),
            requestHeader.getBrokerId(),
            requestHeader.getHaServerAddr(),
            registerBrokerBody.getTopicConfigSerializeWrapper(),
            registerBrokerBody.getFilterServerList(),
            ctx.channel());

        responseHeader.setHaServerAddr(result.getHaServerAddr());
        responseHeader.setMasterAddr(result.getMasterAddr());

        byte[] jsonValue = this.namesrvController.getKvConfigManager().getKVListByNamespace(NamesrvUtil.NAMESPACE_ORDER_TOPIC_CONFIG);
        response.setBody(jsonValue);

        response.setCode(ResponseCode.SUCCESS);
        response.setRemark(null);
        return response;
    }
    // org.apache.rocketmq.namesrv.routeinfo.RouteInfoManager#registerBroker
    public RegisterBrokerResult registerBroker(
        final String clusterName,
        final String brokerAddr,
        final String brokerName,
        final long brokerId,
        final String haServerAddr,
        final TopicConfigSerializeWrapper topicConfigWrapper,
        final List<String> filterServerList,
        final Channel channel) {
        RegisterBrokerResult result = new RegisterBrokerResult();
        try {
            try {
                // 上锁更新各表数据
                this.lock.writeLock().lockInterruptibly();
                // 集群名表
                Set<String> brokerNames = this.clusterAddrTable.get(clusterName);
                if (null == brokerNames) {
                    brokerNames = new HashSet<String>();
                    this.clusterAddrTable.put(clusterName, brokerNames);
                }
                brokerNames.add(brokerName);

                boolean registerFirst = false;
                // broker详细信息表
                BrokerData brokerData = this.brokerAddrTable.get(brokerName);
                if (null == brokerData) {
                    registerFirst = true;
                    brokerData = new BrokerData(clusterName, brokerName, new HashMap<Long, String>());
                    this.brokerAddrTable.put(brokerName, brokerData);
                }
                Map<Long, String> brokerAddrsMap = brokerData.getBrokerAddrs();
                //Switch slave to master: first remove <1, IP:PORT> in namesrv, then add <0, IP:PORT>
                //The same IP:PORT must only have one record in brokerAddrTable
                Iterator<Entry<Long, String>> it = brokerAddrsMap.entrySet().iterator();
                while (it.hasNext()) {
                    Entry<Long, String> item = it.next();
                    if (null != brokerAddr && brokerAddr.equals(item.getValue()) && brokerId != item.getKey()) {
                        it.remove();
                    }
                }

                String oldAddr = brokerData.getBrokerAddrs().put(brokerId, brokerAddr);
                registerFirst = registerFirst || (null == oldAddr);

                if (null != topicConfigWrapper
                    && MixAll.MASTER_ID == brokerId) {
                    if (this.isBrokerTopicConfigChanged(brokerAddr, topicConfigWrapper.getDataVersion())
                        || registerFirst) {
                        // 首次注册或者topic变更，则更新topic信息
                        ConcurrentMap<String, TopicConfig> tcTable =
                            topicConfigWrapper.getTopicConfigTable();
                        if (tcTable != null) {
                            for (Map.Entry<String, TopicConfig> entry : tcTable.entrySet()) {
                                this.createAndUpdateQueueData(brokerName, entry.getValue());
                            }
                        }
                    }
                }
                // 存活的broker信息表
                BrokerLiveInfo prevBrokerLiveInfo = this.brokerLiveTable.put(brokerAddr,
                    new BrokerLiveInfo(
                        System.currentTimeMillis(),
                        topicConfigWrapper.getDataVersion(),
                        channel,
                        haServerAddr));
                if (null == prevBrokerLiveInfo) {
                    log.info("new broker registered, {} HAServer: {}", brokerAddr, haServerAddr);
                }

                if (filterServerList != null) {
                    if (filterServerList.isEmpty()) {
                        this.filterServerTable.remove(brokerAddr);
                    } else {
                        this.filterServerTable.put(brokerAddr, filterServerList);
                    }
                }
                // slave节点注册需绑定masterAddr 返回
                if (MixAll.MASTER_ID != brokerId) {
                    String masterAddr = brokerData.getBrokerAddrs().get(MixAll.MASTER_ID);
                    if (masterAddr != null) {
                        BrokerLiveInfo brokerLiveInfo = this.brokerLiveTable.get(masterAddr);
                        if (brokerLiveInfo != null) {
                            result.setHaServerAddr(brokerLiveInfo.getHaServerAddr());
                            result.setMasterAddr(masterAddr);
                        }
                    }
                }
            } finally {
                this.lock.writeLock().unlock();
            }
        } catch (Exception e) {
            log.error("registerBroker Exception", e);
        }

        return result;
    }
```

[![复制代码](RocketMQ(六)：nameserver与消息存储定位实现.assets/copycode.gif)](javascript:void(0);)

　　好吧，是不是很抽象。没关系，能知道大概意思就行了。大体上就是broker上线了，nameserver需要知道这些事，要把这信息加入到各表项中，以备将来使用。具体理解我们应该要从业务性质出发才能透彻。反正就和咱们平时写业务代码并无二致。

 

[返回顶部](https://www.cnblogs.com/yougewe/p/14128845.html#_labelTop)

### 4. topic存储位置策略

　　nameserver除了有注册broker的核心作用外，还有一个非常核心的作用就是，为各消费者或生产者提供各topic信息所在位置。这个位置决定了数据如何存储以及如何访问问题，只要这个决策出问题，则整个集群的可靠性就无法保证了。所以，这个点需要我们深入理解下。

　　在kafka中，其存储策略是和shard强相关的，一个topic分配了多少shard就决定了它可以存储到几个机器节点上，即kafka是以shard作为粒度分配存储的。

　　但rocketmq中则不太一样，类似的概念有：topic是最外层的存储，而messageQueue则是内一层的存储，它是否是按照topic存储或者按照msgQueue存在呢？实际上，在官方文档中，已经描述清楚了： Broker 在实际部署过程中对应一台服务器，每个 Broker 可以存储多个Topic的消息，每个Topic的消息也可以分片存储于不同的 Broker。Message Queue 用于存储消息的物理地址，每个Topic中的消息地址存储于多个 Message Queue 中。

　　即rocketmq中是以message queue作为最细粒度的存储的，实际上这基本无悬念，因为分布式存储需要。（试想以topic为存储粒度会带来多少问题就知道了）

　　那么，它又是如何划分哪个message queue存储在哪里的呢？

[![复制代码](RocketMQ(六)：nameserver与消息存储定位实现.assets/copycode.gif)](javascript:void(0);)

```
    // RequestCode.GET_ROUTEINFO_BY_TOPIC
    public RemotingCommand getRouteInfoByTopic(ChannelHandlerContext ctx,
        RemotingCommand request) throws RemotingCommandException {
        final RemotingCommand response = RemotingCommand.createResponseCommand(null);
        final GetRouteInfoRequestHeader requestHeader =
            (GetRouteInfoRequestHeader) request.decodeCommandCustomHeader(GetRouteInfoRequestHeader.class);
        // 获取topic路由信息
        TopicRouteData topicRouteData = this.namesrvController.getRouteInfoManager().pickupTopicRouteData(requestHeader.getTopic());

        if (topicRouteData != null) {
            // 顺序消费配置
            if (this.namesrvController.getNamesrvConfig().isOrderMessageEnable()) {
                String orderTopicConf =
                    this.namesrvController.getKvConfigManager().getKVConfig(NamesrvUtil.NAMESPACE_ORDER_TOPIC_CONFIG,
                        requestHeader.getTopic());
                topicRouteData.setOrderTopicConf(orderTopicConf);
            }

            byte[] content = topicRouteData.encode();
            response.setBody(content);
            response.setCode(ResponseCode.SUCCESS);
            response.setRemark(null);
            return response;
        }

        response.setCode(ResponseCode.TOPIC_NOT_EXIST);
        response.setRemark("No topic route info in name server for the topic: " + requestHeader.getTopic()
            + FAQUrl.suggestTodo(FAQUrl.APPLY_TOPIC_URL));
        return response;
    }
    // org.apache.rocketmq.namesrv.routeinfo.RouteInfoManager#pickupTopicRouteData
    public TopicRouteData pickupTopicRouteData(final String topic) {
        TopicRouteData topicRouteData = new TopicRouteData();
        boolean foundQueueData = false;
        boolean foundBrokerData = false;
        Set<String> brokerNameSet = new HashSet<String>();
        List<BrokerData> brokerDataList = new LinkedList<BrokerData>();
        topicRouteData.setBrokerDatas(brokerDataList);

        HashMap<String, List<String>> filterServerMap = new HashMap<String, List<String>>();
        topicRouteData.setFilterServerTable(filterServerMap);

        try {
            try {
                this.lock.readLock().lockInterruptibly();
                // 获取所有topic的messageQueue信息
                List<QueueData> queueDataList = this.topicQueueTable.get(topic);
                if (queueDataList != null) {
                    topicRouteData.setQueueDatas(queueDataList);
                    foundQueueData = true;

                    Iterator<QueueData> it = queueDataList.iterator();
                    while (it.hasNext()) {
                        QueueData qd = it.next();
                        brokerNameSet.add(qd.getBrokerName());
                    }
                    // 根据brokerName, 查找broker信息，如果没找到说明该broker可能已经下线，不能算在路由信息内
                    for (String brokerName : brokerNameSet) {
                        BrokerData brokerData = this.brokerAddrTable.get(brokerName);
                        if (null != brokerData) {
                            BrokerData brokerDataClone = new BrokerData(brokerData.getCluster(), brokerData.getBrokerName(), (HashMap<Long, String>) brokerData
                                .getBrokerAddrs().clone());
                            brokerDataList.add(brokerDataClone);
                            // 只要找到一个broker就可以进行路由处理
                            foundBrokerData = true;
                            for (final String brokerAddr : brokerDataClone.getBrokerAddrs().values()) {
                                List<String> filterServerList = this.filterServerTable.get(brokerAddr);
                                filterServerMap.put(brokerAddr, filterServerList);
                            }
                        }
                    }
                }
            } finally {
                this.lock.readLock().unlock();
            }
        } catch (Exception e) {
            log.error("pickupTopicRouteData Exception", e);
        }

        log.debug("pickupTopicRouteData {} {}", topic, topicRouteData);
        // 只有队列信息和broker信息都找到时，整个路由信息才可返回
        if (foundBrokerData && foundQueueData) {
            return topicRouteData;
        }

        return null;
    }
    // QueueData 作为路由信息的重要组成部分，其数据结构如下
public class QueueData implements Comparable<QueueData> {
    private String brokerName;
    private int readQueueNums;
    private int writeQueueNums;
    private int perm;
    private int topicSynFlag;
    ...
}
    // brokerData 数据结构如下
public class BrokerData implements Comparable<BrokerData> {
    private String cluster;
    private String brokerName;
    private HashMap<Long/* brokerId */, String/* broker address */> brokerAddrs;
    ...
}
```

[![复制代码](RocketMQ(六)：nameserver与消息存储定位实现.assets/copycode.gif)](javascript:void(0);)

　　ok, 从上面的实现中，我们可以看到，查找路由信息，是根据topic进行查找的。而topic信息保存在 topicQueueTable 中。这里有个重要点是，整个路由查找过程，居然和queueId是无关的，那么它又是如何定位queueId所在的位置呢？另外，这个topicQueTable里的数据又是何时维护的呢？

　　首先，对于topicQueueTable的维护，是在broker注册和解注册时维护的，这很好理解。

[![复制代码](RocketMQ(六)：nameserver与消息存储定位实现.assets/copycode.gif)](javascript:void(0);)

```
    // 也就前面看到的broker为master节点时的 createAndUpdateQueueData()
    private void createAndUpdateQueueData(final String brokerName, final TopicConfig topicConfig) {
        QueueData queueData = new QueueData();
        queueData.setBrokerName(brokerName);
        queueData.setWriteQueueNums(topicConfig.getWriteQueueNums());
        queueData.setReadQueueNums(topicConfig.getReadQueueNums());
        queueData.setPerm(topicConfig.getPerm());
        queueData.setTopicSynFlag(topicConfig.getTopicSysFlag());

        List<QueueData> queueDataList = this.topicQueueTable.get(topicConfig.getTopicName());
        // topic的首个broker
        if (null == queueDataList) {
            queueDataList = new LinkedList<QueueData>();
            queueDataList.add(queueData);
            this.topicQueueTable.put(topicConfig.getTopicName(), queueDataList);
            log.info("new topic registered, {} {}", topicConfig.getTopicName(), queueData);
        } else {
            boolean addNewOne = true;

            Iterator<QueueData> it = queueDataList.iterator();
            // 添加一个broker
            while (it.hasNext()) {
                QueueData qd = it.next();
                if (qd.getBrokerName().equals(brokerName)) {
                    if (qd.equals(queueData)) {
                        addNewOne = false;
                    } else {
                        log.info("topic changed, {} OLD: {} NEW: {}", topicConfig.getTopicName(), qd,
                            queueData);
                        it.remove();
                    }
                }
            }

            if (addNewOne) {
                queueDataList.add(queueData);
            }
        }
    }
```

[![复制代码](RocketMQ(六)：nameserver与消息存储定位实现.assets/copycode.gif)](javascript:void(0);)

　　但针对queueId又是何时进行处理的呢？看起来nameserver不得而知。

　　事实上，数据发送到哪个broker或从哪个broker上进行数据消费，是由各客户端根据策略决定的。比如在producer中是这样处理的：

[![复制代码](RocketMQ(六)：nameserver与消息存储定位实现.assets/copycode.gif)](javascript:void(0);)

```
    // org.apache.rocketmq.client.impl.producer.DefaultMQProducerImpl#sendDefaultImpl
    private SendResult sendDefaultImpl(
        Message msg,
        final CommunicationMode communicationMode,
        final SendCallback sendCallback,
        final long timeout
    ) throws MQClientException, RemotingException, MQBrokerException, InterruptedException {
        this.makeSureStateOK();
        Validators.checkMessage(msg, this.defaultMQProducer);
        final long invokeID = random.nextLong();
        long beginTimestampFirst = System.currentTimeMillis();
        long beginTimestampPrev = beginTimestampFirst;
        long endTimestamp = beginTimestampFirst;
        // 此处即是nameserver返回的路由信息，即可用的broker列表
        TopicPublishInfo topicPublishInfo = this.tryToFindTopicPublishInfo(msg.getTopic());
        if (topicPublishInfo != null && topicPublishInfo.ok()) {
            boolean callTimeout = false;
            MessageQueue mq = null;
            Exception exception = null;
            SendResult sendResult = null;
            int timesTotal = communicationMode == CommunicationMode.SYNC ? 1 + this.defaultMQProducer.getRetryTimesWhenSendFailed() : 1;
            int times = 0;
            String[] brokersSent = new String[timesTotal];
            for (; times < timesTotal; times++) {
                // 首次进入时，只是选择一个队列发送
                String lastBrokerName = null == mq ? null : mq.getBrokerName();
                MessageQueue mqSelected = this.selectOneMessageQueue(topicPublishInfo, lastBrokerName);
                if (mqSelected != null) {
                    mq = mqSelected;
                    brokersSent[times] = mq.getBrokerName();
                    try {
                        beginTimestampPrev = System.currentTimeMillis();
                        if (times > 0) {
                            //Reset topic with namespace during resend.
                            msg.setTopic(this.defaultMQProducer.withNamespace(msg.getTopic()));
                        }
                        long costTime = beginTimestampPrev - beginTimestampFirst;
                        if (timeout < costTime) {
                            callTimeout = true;
                            break;
                        }
                        // 向选择出来的messageQueue 发送消息数据
                        sendResult = this.sendKernelImpl(msg, mq, communicationMode, sendCallback, topicPublishInfo, timeout - costTime);
                        endTimestamp = System.currentTimeMillis();
                        this.updateFaultItem(mq.getBrokerName(), endTimestamp - beginTimestampPrev, false);
                        switch (communicationMode) {
                            case ASYNC:
                                return null;
                            case ONEWAY:
                                return null;
                            case SYNC:
                                if (sendResult.getSendStatus() != SendStatus.SEND_OK) {
                                    if (this.defaultMQProducer.isRetryAnotherBrokerWhenNotStoreOK()) {
                                        continue;
                                    }
                                }

                                return sendResult;
                            default:
                                break;
                        }
                    } catch (RemotingException e) 
                    ...
    }
    // org.apache.rocketmq.client.impl.producer.DefaultMQProducerImpl#selectOneMessageQueue
    public MessageQueue selectOneMessageQueue(final TopicPublishInfo tpInfo, final String lastBrokerName) {
        return this.mqFaultStrategy.selectOneMessageQueue(tpInfo, lastBrokerName);
    }
    // org.apache.rocketmq.client.latency.MQFaultStrategy#selectOneMessageQueue
    public MessageQueue selectOneMessageQueue(final TopicPublishInfo tpInfo, final String lastBrokerName) {
        // 容错处理，不影响策略理解
        if (this.sendLatencyFaultEnable) {
            try {
                int index = tpInfo.getSendWhichQueue().getAndIncrement();
                for (int i = 0; i < tpInfo.getMessageQueueList().size(); i++) {
                    int pos = Math.abs(index++) % tpInfo.getMessageQueueList().size();
                    if (pos < 0)
                        pos = 0;
                    MessageQueue mq = tpInfo.getMessageQueueList().get(pos);
                    if (latencyFaultTolerance.isAvailable(mq.getBrokerName())) {
                        if (null == lastBrokerName || mq.getBrokerName().equals(lastBrokerName))
                            return mq;
                    }
                }

                final String notBestBroker = latencyFaultTolerance.pickOneAtLeast();
                int writeQueueNums = tpInfo.getQueueIdByBroker(notBestBroker);
                if (writeQueueNums > 0) {
                    final MessageQueue mq = tpInfo.selectOneMessageQueue();
                    if (notBestBroker != null) {
                        mq.setBrokerName(notBestBroker);
                        mq.setQueueId(tpInfo.getSendWhichQueue().getAndIncrement() % writeQueueNums);
                    }
                    return mq;
                } else {
                    latencyFaultTolerance.remove(notBestBroker);
                }
            } catch (Exception e) {
                log.error("Error occurred when selecting message queue", e);
            }

            return tpInfo.selectOneMessageQueue();
        }

        return tpInfo.selectOneMessageQueue(lastBrokerName);
    }
    // org.apache.rocketmq.client.impl.producer.TopicPublishInfo#selectOneMessageQueue
    // 直接使用轮询的方式选择一个队列 
    public MessageQueue selectOneMessageQueue(final String lastBrokerName) {
        if (lastBrokerName == null) {
            // 任意选择一个messageQueue作为发送目标
            return selectOneMessageQueue();
        } else {
            int index = this.sendWhichQueue.getAndIncrement();
            // 最大尝试n次获取不一样的MQueue, 如仍然获取不到，则随便选择一个即可
            for (int i = 0; i < this.messageQueueList.size(); i++) {
                int pos = Math.abs(index++) % this.messageQueueList.size();
                if (pos < 0)
                    pos = 0;
                MessageQueue mq = this.messageQueueList.get(pos);
                if (!mq.getBrokerName().equals(lastBrokerName)) {
                    return mq;
                }
            }
            return selectOneMessageQueue();
        }
    }
```

[![复制代码](RocketMQ(六)：nameserver与消息存储定位实现.assets/copycode.gif)](javascript:void(0);)

　　好了，通过上面的描述，我们大概知道了，一个消息要发送往消息server时，首先会根据topic找到所有可用的broker列表（nameserver提供），然后根据一个所谓策略选择一个MessageQueue，最后向这个MessageQueue发送数据即可。所以，这个MessageQueue是非常重要的，我们来看下其数据结构：

[![复制代码](RocketMQ(六)：nameserver与消息存储定位实现.assets/copycode.gif)](javascript:void(0);)

```
// org.apache.rocketmq.common.message.MessageQueue
public class MessageQueue implements Comparable<MessageQueue>, Serializable {
    private static final long serialVersionUID = 6191200464116433425L;
    private String topic;
    private String brokerName;
    private int queueId;
    ...
}
```

[![复制代码](RocketMQ(六)：nameserver与消息存储定位实现.assets/copycode.gif)](javascript:void(0);)

　　这是非常之简洁啊，仅有主要的三个核心：topic(主题),brokerName(broker标识),queueId(队列id)。 

　　前面提到的客户端策略，会选择一个MessageQueue, 即会得到一个broker标识，对应一个queueId。所以，数据存放在哪个broker，是由客户端决定的，且存放位置未知。也就是说，rocketmq中同一个topic的数据，是散乱存放在一堆broker中的。这和我们通常的认知是有一定差距的。

　　这样设计有什么好处呢？好处自然是有的，比如假如其中有些broker挂掉了，那么整个集群无需经过什么再均衡策略，同样可以工作得很好，因为客户端可以直接向正常的broker发送消息即可。其他好处。。。

　　但是我个人觉得这样的设计，也不见得很好，比如你不能够很确定地定位到某条消息在哪个broker上，完全无规律可循。另外，如果想在单queueId上保持一定的规则，则是不可能的（也许有其他曲线救国之法）。另外，对于queueId, 只是一个系统内部的概念，实际上用户并不能指定该值。

 

[返回顶部](https://www.cnblogs.com/yougewe/p/14128845.html#_labelTop)

### 5. MessageQueue到底存在哪里？

　　按照上面说的，一个topic数据可能被存放在n个broker中，且以messageQueue的queueId作为单独存储。那么，到底数据存放在哪里？所说的n个broker到底指哪几个broker？每个broker上到底存放了几个queueId？这些问题如果没有搞清楚，我们就无法说清楚这玩意。

　　我们先来回答第一个问题，topic数据到底存放在几个broker中？回顾下前面broker的注册过程可知：

[![复制代码](RocketMQ(六)：nameserver与消息存储定位实现.assets/copycode.gif)](javascript:void(0);)

```
    // org.apache.rocketmq.namesrv.routeinfo.RouteInfoManager#registerBroker
    if (null != topicConfigWrapper
        && MixAll.MASTER_ID == brokerId) {
        if (this.isBrokerTopicConfigChanged(brokerAddr, topicConfigWrapper.getDataVersion())
            || registerFirst) {
            // 首次注册或者topic变更，则更新topic信息
            ConcurrentMap<String, TopicConfig> tcTable =
                topicConfigWrapper.getTopicConfigTable();
            if (tcTable != null) {
                // 遍历所有topic, 将当前新进的broker 加入到处理机器中
                for (Map.Entry<String, TopicConfig> entry : tcTable.entrySet()) {
                    this.createAndUpdateQueueData(brokerName, entry.getValue());
                }
            }
        }
    }
```

[![复制代码](RocketMQ(六)：nameserver与消息存储定位实现.assets/copycode.gif)](javascript:void(0);)

　　看完这段，我们就明白了，原来所谓的n个broker可处理topic信息，实际上指的是所有broker啊！好吧，咱也不懂为啥这么干，反正就是这么干了，topic可能分布在所有broker机器上。至于具体哪一台，你猜啊！

　　接下来我们看第二个问题，一个broker到底存储了几个queueId的数据？实际上，我们稍微想想前面的实现，broker是指所有的broker，如果所有broker都是一样的配置，那么是不是应该让每个broker都存储所有queueId呢？（尽管没啥依据，还是可以想想的嘛）

　　rocketmq的各客户端（生产者、消费者）每次向服务器发送生产或消费请求时，都可能向nameserver请求拉取路由信息，但这些信息从我们前面调查的结果来看，并不包含queueId信息。那么，后续又是如何转换为queueId的呢？实际上，就是在拉取了nameserver的路由信息之后，本地再做一次分配就可以了：

![img](RocketMQ(六)：nameserver与消息存储定位实现.assets/ContractedBlock.gif) View Code

　　生产者分配queueId的实现如下：

[![复制代码](RocketMQ(六)：nameserver与消息存储定位实现.assets/copycode.gif)](javascript:void(0);)

```
    // org.apache.rocketmq.client.impl.factory.MQClientInstance#topicRouteData2TopicPublishInfo
    public static TopicPublishInfo topicRouteData2TopicPublishInfo(final String topic, final TopicRouteData route) {
        TopicPublishInfo info = new TopicPublishInfo();
        info.setTopicRouteData(route);
        // 为每个broker指定queueId的分配情况（最大queueId）
        // 这样的配置不知道累不累
        if (route.getOrderTopicConf() != null && route.getOrderTopicConf().length() > 0) {
            String[] brokers = route.getOrderTopicConf().split(";");
            for (String broker : brokers) {
                String[] item = broker.split(":");
                int nums = Integer.parseInt(item[1]);
                for (int i = 0; i < nums; i++) {
                    MessageQueue mq = new MessageQueue(topic, item[0], i);
                    info.getMessageQueueList().add(mq);
                }
            }

            info.setOrderTopic(true);
        } else {
            List<QueueData> qds = route.getQueueDatas();
            Collections.sort(qds);
            for (QueueData qd : qds) {
                if (PermName.isWriteable(qd.getPerm())) {
                    BrokerData brokerData = null;
                    for (BrokerData bd : route.getBrokerDatas()) {
                        if (bd.getBrokerName().equals(qd.getBrokerName())) {
                            brokerData = bd;
                            break;
                        }
                    }
                    // 还是有broker无法处理queue哦
                    if (null == brokerData) {
                        continue;
                    }
                    // 非master节点不能接受写请求
                    if (!brokerData.getBrokerAddrs().containsKey(MixAll.MASTER_ID)) {
                        continue;
                    }
                    // 根据 writeQueueNums 数量，要求该broker接受所有小于该值的queueId
                    for (int i = 0; i < qd.getWriteQueueNums(); i++) {
                        MessageQueue mq = new MessageQueue(topic, qd.getBrokerName(), i);
                        info.getMessageQueueList().add(mq);
                    }
                }
            }

            info.setOrderTopic(false);
        }

        return info;
    }
```

[![复制代码](RocketMQ(六)：nameserver与消息存储定位实现.assets/copycode.gif)](javascript:void(0);)

　　可以看出，生产者对应的broker中，负责写的broker只能是master节点，负责所有小于writeQueueNums的queueId的数据存储。（如果所有broker配置一样，则相当于所有broker都存储所有queueId），所以，这存储关系，可能是理不清楚了。

　　我们再来看看消费者是如何对应queueId的呢？

[![复制代码](RocketMQ(六)：nameserver与消息存储定位实现.assets/copycode.gif)](javascript:void(0);)

```
    // org.apache.rocketmq.client.impl.factory.MQClientInstance#topicRouteData2TopicSubscribeInfo
    public static Set<MessageQueue> topicRouteData2TopicSubscribeInfo(final String topic, final TopicRouteData route) {
        Set<MessageQueue> mqList = new HashSet<MessageQueue>();
        List<QueueData> qds = route.getQueueDatas();
        for (QueueData qd : qds) {
            if (PermName.isReadable(qd.getPerm())) {
                // 可读取broker上对应的所有小于readQueueNums 的队列
                for (int i = 0; i < qd.getReadQueueNums(); i++) {
                    MessageQueue mq = new MessageQueue(topic, qd.getBrokerName(), i);
                    mqList.add(mq);
                }
            }
        }

        return mqList;
    }
```

[![复制代码](RocketMQ(六)：nameserver与消息存储定位实现.assets/copycode.gif)](javascript:void(0);)

　　原理和生产者差不多，就是通过一个 readQueueNums 来限定读取的队列数，基本上就是等于所有队列了，原因可能是原本数据就存储了所有queueId，如果消费者不读取，又该谁来读取呢。

　　

　　好了，到此我们总算厘清了整个rocketmq的消息存储定位方式了。总结一句话就是：任何节点都可能有任意topic的任意queueId数据。这结果，不禁又让我有一种千头万绪的感觉！

　　以上仅是一些正常的rocketmq数据存储的实现，只能算是皮毛。事实上，分布式系统中一个非常重要的能力是容错，欲知后事如何且听下回分解。

不要害怕今日的苦，你要相信明天，更苦！

分类: [协议类](https://www.cnblogs.com/yougewe/category/755891.html), [原理&故事](https://www.cnblogs.com/yougewe/category/789557.html), [并发&性能](https://www.cnblogs.com/yougewe/category/844109.html), [java](https://www.cnblogs.com/yougewe/category/923459.html), [大数据](https://www.cnblogs.com/yougewe/category/1238476.html), [源码](https://www.cnblogs.com/yougewe/category/1278448.html), [算法](https://www.cnblogs.com/yougewe/category/1844743.html), [数据库](https://www.cnblogs.com/yougewe/category/1846971.html)

标签: [元数据管理](https://www.cnblogs.com/yougewe/tag/元数据管理/), [锁](https://www.cnblogs.com/yougewe/tag/锁/), [路由](https://www.cnblogs.com/yougewe/tag/路由/), [rocketmq](https://www.cnblogs.com/yougewe/tag/rocketmq/), [netty](https://www.cnblogs.com/yougewe/tag/netty/), [nameserver](https://www.cnblogs.com/yougewe/tag/nameserver/), [消息中间件](https://www.cnblogs.com/yougewe/tag/消息中间件/), [定长存储](https://www.cnblogs.com/yougewe/tag/定长存储/)