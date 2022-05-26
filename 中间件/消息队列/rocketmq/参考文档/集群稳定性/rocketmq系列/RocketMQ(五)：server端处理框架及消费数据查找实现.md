# [RocketMQ(五)：server端处理框架及消费数据查找实现](https://www.cnblogs.com/yougewe/p/14092169.html)



**目录**

- [1. rocketmq的通信模型](https://www.cnblogs.com/yougewe/p/14092169.html#_label0)
- [2. rocketmq的业务处理方案](https://www.cnblogs.com/yougewe/p/14092169.html#_label1)
- [3. 消息数据的拉取实现](https://www.cnblogs.com/yougewe/p/14092169.html#_label2)



------

　　rocketmq作为一个高性能的消息中间件，咱们光停留在使用层面，总感觉缺点什么。虽然rocketmq的官方设计文档讲得还是比较详细的，但纸上得来终觉浅！今天我们就来亲自挖一挖rocketmq的实现细节：server端处理框架以及如果进行消费消息。

　　说白了，就是先走马观花一下，然后就消费消息这个细节看看如何处理就行。

 

[返回顶部](https://www.cnblogs.com/yougewe/p/14092169.html#_labelTop)

### 1. rocketmq的通信模型

　　咱们先来个整体部署架构图，有个整体概念。

![img](RocketMQ(五)：server端处理框架及消费数据查找实现.assets/830731-20201206105541807-43667222.png)

 

　　上面的图中，producer和consumer属于客户端，虽然也都非常重要。但在服务端的部署中，我们并不需要其参与，所以，只剩下broker和nameserver了。它俩的分工也很明确，nameserver负责管理元数据信息，即哪个topic/msgqueue在哪个broker上，发现broker等等。而broker则是最核心的处理消息的服务，它负责接收客户端的读写请求，保证数据落地以及主从数据同步。而这就是一个消息中件的最本质的功能：数据存储。

　　所以，从某种意义上说，类似rocketmq这种的消息中件，我们可以理解为就是一个小型数据库。 

　　ok, 回到正题：rocketmq的通信模型是怎么样的呢？大体链路我们可以从如上架构图中得出，但是我们还想说更细点的是：rocketmq是如何实现这些服务组件集群间的通信的？因netty是一个非常高效易用的通信框架，所以netty作为通信服务实现，是再容易不过了。而在使用上，我们更多的，只需要设计出相应的数据格式（协议）进行编解码，然后编写相应的handler用于处理业务就可以了。（可参考前面的netty文章：https://www.cnblogs.com/yougewe/p/13415440.html）

　　rocketmq的逻辑存储分布大致为：1个mq集群 -> n个topic -> m个queue, 具体消息存储分布图可以简单看作如下图所示：

![img](RocketMQ(五)：server端处理框架及消费数据查找实现.assets/830731-20201206110101729-68766424.png)

 

 　其中，通信的建立我们可以概览下，netty Server handler设置大致如下：

[![复制代码](RocketMQ(五)：server端处理框架及消费数据查找实现.assets/copycode.gif)](javascript:void(0);)

```
    // org.apache.rocketmq.remoting.netty.NettyRemotingServer#start
    @Override
    public void start() {
        this.defaultEventExecutorGroup = new DefaultEventExecutorGroup(
            nettyServerConfig.getServerWorkerThreads(),
            new ThreadFactory() {

                private AtomicInteger threadIndex = new AtomicInteger(0);

                @Override
                public Thread newThread(Runnable r) {
                    return new Thread(r, "NettyServerCodecThread_" + this.threadIndex.incrementAndGet());
                }
            });

        prepareSharableHandlers();

        ServerBootstrap childHandler =
            this.serverBootstrap.group(this.eventLoopGroupBoss, this.eventLoopGroupSelector)
                .channel(useEpoll() ? EpollServerSocketChannel.class : NioServerSocketChannel.class)
                .option(ChannelOption.SO_BACKLOG, 1024)
                .option(ChannelOption.SO_REUSEADDR, true)
                .option(ChannelOption.SO_KEEPALIVE, false)
                .childOption(ChannelOption.TCP_NODELAY, true)
                .childOption(ChannelOption.SO_SNDBUF, nettyServerConfig.getServerSocketSndBufSize())
                .childOption(ChannelOption.SO_RCVBUF, nettyServerConfig.getServerSocketRcvBufSize())
                .localAddress(new InetSocketAddress(this.nettyServerConfig.getListenPort()))
                .childHandler(new ChannelInitializer<SocketChannel>() {
                    @Override
                    public void initChannel(SocketChannel ch) throws Exception {
                        ch.pipeline()
                            .addLast(defaultEventExecutorGroup, HANDSHAKE_HANDLER_NAME, handshakeHandler)
                            .addLast(defaultEventExecutorGroup,
                                // 编解码器
                                encoder,
                                new NettyDecoder(),
                                new IdleStateHandler(0, 0, nettyServerConfig.getServerChannelMaxIdleTimeSeconds()),
                                connectionManageHandler,
                                // 业务处理器入口
                                serverHandler
                            );
                    }
                });

        if (nettyServerConfig.isServerPooledByteBufAllocatorEnable()) {
            childHandler.childOption(ChannelOption.ALLOCATOR, PooledByteBufAllocator.DEFAULT);
        }

        try {
            ChannelFuture sync = this.serverBootstrap.bind().sync();
            InetSocketAddress addr = (InetSocketAddress) sync.channel().localAddress();
            this.port = addr.getPort();
        } catch (InterruptedException e1) {
            throw new RuntimeException("this.serverBootstrap.bind().sync() InterruptedException", e1);
        }

        if (this.channelEventListener != null) {
            this.nettyEventExecutor.start();
        }

        this.timer.scheduleAtFixedRate(new TimerTask() {

            @Override
            public void run() {
                try {
                    NettyRemotingServer.this.scanResponseTable();
                } catch (Throwable e) {
                    log.error("scanResponseTable exception", e);
                }
            }
        }, 1000 * 3, 1000);
    }
```

[![复制代码](RocketMQ(五)：server端处理框架及消费数据查找实现.assets/copycode.gif)](javascript:void(0);)

　　不出netty意料的处理方法，不必细说。

 

[返回顶部](https://www.cnblogs.com/yougewe/p/14092169.html#_labelTop)

### 2. rocketmq的业务处理方案

　　我们通常的业务系统，一般会暴露出各种restful或者其他协议的接口，然后供下游系统调用。同样，rocketmq也会存在各系统间的调用问题，它自然是不会按照各种如springmvc一样的restful接口实现的。为了实现高效的处理，rocketmq使用了一个code标识来代表服务端接到请求后该如何处理的问题。具体是统一封装在一个类中：org.apache.rocketmq.common.protocol.RequestCode 。

[![复制代码](RocketMQ(五)：server端处理框架及消费数据查找实现.assets/copycode.gif)](javascript:void(0);)

```
public class RequestCode {

    public static final int SEND_MESSAGE = 10;

    public static final int PULL_MESSAGE = 11;

    public static final int QUERY_MESSAGE = 12;
    public static final int QUERY_BROKER_OFFSET = 13;
    public static final int QUERY_CONSUMER_OFFSET = 14;
    public static final int UPDATE_CONSUMER_OFFSET = 15;
    public static final int UPDATE_AND_CREATE_TOPIC = 17;
    public static final int GET_ALL_TOPIC_CONFIG = 21;
    public static final int GET_TOPIC_CONFIG_LIST = 22;

    public static final int GET_TOPIC_NAME_LIST = 23;

    public static final int UPDATE_BROKER_CONFIG = 25;

    public static final int GET_BROKER_CONFIG = 26;

    public static final int TRIGGER_DELETE_FILES = 27;

    public static final int GET_BROKER_RUNTIME_INFO = 28;
    public static final int SEARCH_OFFSET_BY_TIMESTAMP = 29;
    public static final int GET_MAX_OFFSET = 30;
    public static final int GET_MIN_OFFSET = 31;

    public static final int GET_EARLIEST_MSG_STORETIME = 32;

    public static final int VIEW_MESSAGE_BY_ID = 33;

    public static final int HEART_BEAT = 34;

    public static final int UNREGISTER_CLIENT = 35;

    public static final int CONSUMER_SEND_MSG_BACK = 36;

    public static final int END_TRANSACTION = 37;
    public static final int GET_CONSUMER_LIST_BY_GROUP = 38;

    public static final int CHECK_TRANSACTION_STATE = 39;

    public static final int NOTIFY_CONSUMER_IDS_CHANGED = 40;

    public static final int LOCK_BATCH_MQ = 41;

    public static final int UNLOCK_BATCH_MQ = 42;
    public static final int GET_ALL_CONSUMER_OFFSET = 43;

    public static final int GET_ALL_DELAY_OFFSET = 45;

    public static final int CHECK_CLIENT_CONFIG = 46;

    public static final int UPDATE_AND_CREATE_ACL_CONFIG = 50;

    public static final int DELETE_ACL_CONFIG = 51;

    public static final int GET_BROKER_CLUSTER_ACL_INFO = 52;

    public static final int UPDATE_GLOBAL_WHITE_ADDRS_CONFIG = 53;

    public static final int GET_BROKER_CLUSTER_ACL_CONFIG = 54;

    public static final int PUT_KV_CONFIG = 100;

    public static final int GET_KV_CONFIG = 101;

    public static final int DELETE_KV_CONFIG = 102;

    public static final int REGISTER_BROKER = 103;

    public static final int UNREGISTER_BROKER = 104;
    public static final int GET_ROUTEINFO_BY_TOPIC = 105;

    public static final int GET_BROKER_CLUSTER_INFO = 106;
    public static final int UPDATE_AND_CREATE_SUBSCRIPTIONGROUP = 200;
    public static final int GET_ALL_SUBSCRIPTIONGROUP_CONFIG = 201;
    public static final int GET_TOPIC_STATS_INFO = 202;
    public static final int GET_CONSUMER_CONNECTION_LIST = 203;
    public static final int GET_PRODUCER_CONNECTION_LIST = 204;
    public static final int WIPE_WRITE_PERM_OF_BROKER = 205;

    public static final int GET_ALL_TOPIC_LIST_FROM_NAMESERVER = 206;

    public static final int DELETE_SUBSCRIPTIONGROUP = 207;
    public static final int GET_CONSUME_STATS = 208;

    public static final int SUSPEND_CONSUMER = 209;

    public static final int RESUME_CONSUMER = 210;
    public static final int RESET_CONSUMER_OFFSET_IN_CONSUMER = 211;
    public static final int RESET_CONSUMER_OFFSET_IN_BROKER = 212;

    public static final int ADJUST_CONSUMER_THREAD_POOL = 213;

    public static final int WHO_CONSUME_THE_MESSAGE = 214;

    public static final int DELETE_TOPIC_IN_BROKER = 215;

    public static final int DELETE_TOPIC_IN_NAMESRV = 216;
    public static final int GET_KVLIST_BY_NAMESPACE = 219;

    public static final int RESET_CONSUMER_CLIENT_OFFSET = 220;

    public static final int GET_CONSUMER_STATUS_FROM_CLIENT = 221;

    public static final int INVOKE_BROKER_TO_RESET_OFFSET = 222;

    public static final int INVOKE_BROKER_TO_GET_CONSUMER_STATUS = 223;

    public static final int QUERY_TOPIC_CONSUME_BY_WHO = 300;

    public static final int GET_TOPICS_BY_CLUSTER = 224;

    public static final int REGISTER_FILTER_SERVER = 301;
    public static final int REGISTER_MESSAGE_FILTER_CLASS = 302;

    public static final int QUERY_CONSUME_TIME_SPAN = 303;

    public static final int GET_SYSTEM_TOPIC_LIST_FROM_NS = 304;
    public static final int GET_SYSTEM_TOPIC_LIST_FROM_BROKER = 305;

    public static final int CLEAN_EXPIRED_CONSUMEQUEUE = 306;

    public static final int GET_CONSUMER_RUNNING_INFO = 307;

    public static final int QUERY_CORRECTION_OFFSET = 308;
    public static final int CONSUME_MESSAGE_DIRECTLY = 309;

    public static final int SEND_MESSAGE_V2 = 310;

    public static final int GET_UNIT_TOPIC_LIST = 311;

    public static final int GET_HAS_UNIT_SUB_TOPIC_LIST = 312;

    public static final int GET_HAS_UNIT_SUB_UNUNIT_TOPIC_LIST = 313;

    public static final int CLONE_GROUP_OFFSET = 314;

    public static final int VIEW_BROKER_STATS_DATA = 315;

    public static final int CLEAN_UNUSED_TOPIC = 316;

    public static final int GET_BROKER_CONSUME_STATS = 317;

    /**
     * update the config of name server
     */
    public static final int UPDATE_NAMESRV_CONFIG = 318;

    /**
     * get config from name server
     */
    public static final int GET_NAMESRV_CONFIG = 319;

    public static final int SEND_BATCH_MESSAGE = 320;

    public static final int QUERY_CONSUME_QUEUE = 321;

    public static final int QUERY_DATA_VERSION = 322;

    /**
     * resume logic of checking half messages that have been put in TRANS_CHECK_MAXTIME_TOPIC before
     */
    public static final int RESUME_CHECK_HALF_MESSAGE = 323;

    public static final int SEND_REPLY_MESSAGE = 324;

    public static final int SEND_REPLY_MESSAGE_V2 = 325;

    public static final int PUSH_REPLY_MESSAGE_TO_CLIENT = 326;
}
```

[![复制代码](RocketMQ(五)：server端处理框架及消费数据查找实现.assets/copycode.gif)](javascript:void(0);)

　　哎，说实话，虽然大部分意思可以通过表面含义去理解，但是这种潦草的注释，也是够了。总之一句话，需要处理的code，都可以在这里找到。这些code也会在broker启动时注册到某个地方，以便有请求到来时，可能根据code去处理相应业务。

[![复制代码](RocketMQ(五)：server端处理框架及消费数据查找实现.assets/copycode.gif)](javascript:void(0);)

```
    // org.apache.rocketmq.broker.BrokerController#registerProcessor
    public void registerProcessor() {
        /**
         * SendMessageProcessor
         */
        SendMessageProcessor sendProcessor = new SendMessageProcessor(this);
        sendProcessor.registerSendMessageHook(sendMessageHookList);
        sendProcessor.registerConsumeMessageHook(consumeMessageHookList);

        this.remotingServer.registerProcessor(RequestCode.SEND_MESSAGE, sendProcessor, this.sendMessageExecutor);
        this.remotingServer.registerProcessor(RequestCode.SEND_MESSAGE_V2, sendProcessor, this.sendMessageExecutor);
        this.remotingServer.registerProcessor(RequestCode.SEND_BATCH_MESSAGE, sendProcessor, this.sendMessageExecutor);
        this.remotingServer.registerProcessor(RequestCode.CONSUMER_SEND_MSG_BACK, sendProcessor, this.sendMessageExecutor);
        this.fastRemotingServer.registerProcessor(RequestCode.SEND_MESSAGE, sendProcessor, this.sendMessageExecutor);
        this.fastRemotingServer.registerProcessor(RequestCode.SEND_MESSAGE_V2, sendProcessor, this.sendMessageExecutor);
        this.fastRemotingServer.registerProcessor(RequestCode.SEND_BATCH_MESSAGE, sendProcessor, this.sendMessageExecutor);
        this.fastRemotingServer.registerProcessor(RequestCode.CONSUMER_SEND_MSG_BACK, sendProcessor, this.sendMessageExecutor);
        /**
         * PullMessageProcessor
         */
        this.remotingServer.registerProcessor(RequestCode.PULL_MESSAGE, this.pullMessageProcessor, this.pullMessageExecutor);
        this.pullMessageProcessor.registerConsumeMessageHook(consumeMessageHookList);

        /**
         * ReplyMessageProcessor
         */
        ReplyMessageProcessor replyMessageProcessor = new ReplyMessageProcessor(this);
        replyMessageProcessor.registerSendMessageHook(sendMessageHookList);

        this.remotingServer.registerProcessor(RequestCode.SEND_REPLY_MESSAGE, replyMessageProcessor, replyMessageExecutor);
        this.remotingServer.registerProcessor(RequestCode.SEND_REPLY_MESSAGE_V2, replyMessageProcessor, replyMessageExecutor);
        this.fastRemotingServer.registerProcessor(RequestCode.SEND_REPLY_MESSAGE, replyMessageProcessor, replyMessageExecutor);
        this.fastRemotingServer.registerProcessor(RequestCode.SEND_REPLY_MESSAGE_V2, replyMessageProcessor, replyMessageExecutor);

        /**
         * QueryMessageProcessor
         */
        NettyRequestProcessor queryProcessor = new QueryMessageProcessor(this);
        this.remotingServer.registerProcessor(RequestCode.QUERY_MESSAGE, queryProcessor, this.queryMessageExecutor);
        this.remotingServer.registerProcessor(RequestCode.VIEW_MESSAGE_BY_ID, queryProcessor, this.queryMessageExecutor);

        this.fastRemotingServer.registerProcessor(RequestCode.QUERY_MESSAGE, queryProcessor, this.queryMessageExecutor);
        this.fastRemotingServer.registerProcessor(RequestCode.VIEW_MESSAGE_BY_ID, queryProcessor, this.queryMessageExecutor);

        /**
         * ClientManageProcessor
         */
        ClientManageProcessor clientProcessor = new ClientManageProcessor(this);
        this.remotingServer.registerProcessor(RequestCode.HEART_BEAT, clientProcessor, this.heartbeatExecutor);
        this.remotingServer.registerProcessor(RequestCode.UNREGISTER_CLIENT, clientProcessor, this.clientManageExecutor);
        this.remotingServer.registerProcessor(RequestCode.CHECK_CLIENT_CONFIG, clientProcessor, this.clientManageExecutor);

        this.fastRemotingServer.registerProcessor(RequestCode.HEART_BEAT, clientProcessor, this.heartbeatExecutor);
        this.fastRemotingServer.registerProcessor(RequestCode.UNREGISTER_CLIENT, clientProcessor, this.clientManageExecutor);
        this.fastRemotingServer.registerProcessor(RequestCode.CHECK_CLIENT_CONFIG, clientProcessor, this.clientManageExecutor);

        /**
         * ConsumerManageProcessor
         */
        ConsumerManageProcessor consumerManageProcessor = new ConsumerManageProcessor(this);
        this.remotingServer.registerProcessor(RequestCode.GET_CONSUMER_LIST_BY_GROUP, consumerManageProcessor, this.consumerManageExecutor);
        this.remotingServer.registerProcessor(RequestCode.UPDATE_CONSUMER_OFFSET, consumerManageProcessor, this.consumerManageExecutor);
        this.remotingServer.registerProcessor(RequestCode.QUERY_CONSUMER_OFFSET, consumerManageProcessor, this.consumerManageExecutor);

        this.fastRemotingServer.registerProcessor(RequestCode.GET_CONSUMER_LIST_BY_GROUP, consumerManageProcessor, this.consumerManageExecutor);
        this.fastRemotingServer.registerProcessor(RequestCode.UPDATE_CONSUMER_OFFSET, consumerManageProcessor, this.consumerManageExecutor);
        this.fastRemotingServer.registerProcessor(RequestCode.QUERY_CONSUMER_OFFSET, consumerManageProcessor, this.consumerManageExecutor);

        /**
         * EndTransactionProcessor
         */
        this.remotingServer.registerProcessor(RequestCode.END_TRANSACTION, new EndTransactionProcessor(this), this.endTransactionExecutor);
        this.fastRemotingServer.registerProcessor(RequestCode.END_TRANSACTION, new EndTransactionProcessor(this), this.endTransactionExecutor);

        /**
         * Default
         */
        AdminBrokerProcessor adminProcessor = new AdminBrokerProcessor(this);
        this.remotingServer.registerDefaultProcessor(adminProcessor, this.adminBrokerExecutor);
        this.fastRemotingServer.registerDefaultProcessor(adminProcessor, this.adminBrokerExecutor);
    }
    // org.apache.rocketmq.remoting.netty.NettyRemotingServer#registerProcessor
    @Override
    public void registerProcessor(int requestCode, NettyRequestProcessor processor, ExecutorService executor) {
        ExecutorService executorThis = executor;
        if (null == executor) {
            executorThis = this.publicExecutor;
        }

        Pair<NettyRequestProcessor, ExecutorService> pair = new Pair<NettyRequestProcessor, ExecutorService>(processor, executorThis);
        // HashMap<Integer/* request code */, Pair<NettyRequestProcessor, ExecutorService>> processorTable
        // 将code注册到hash表中，备用
        this.processorTable.put(requestCode, pair);
    }
```

[![复制代码](RocketMQ(五)：server端处理框架及消费数据查找实现.assets/copycode.gif)](javascript:void(0);)

　　当真正的请求到来时，同可以直接从处理器表中，根据code直接取出，然后传入数据命令处理即可。

[![复制代码](RocketMQ(五)：server端处理框架及消费数据查找实现.assets/copycode.gif)](javascript:void(0);)

```
    // org.apache.rocketmq.remoting.netty.NettyRemotingAbstract#processRequestCommand
    /**
     * Process incoming request command issued by remote peer.
     *
     * @param ctx channel handler context.
     * @param cmd request command.
     */
    public void processRequestCommand(final ChannelHandlerContext ctx, final RemotingCommand cmd) {
        // 从 processorTable 中获取处理器
        final Pair<NettyRequestProcessor, ExecutorService> matched = this.processorTable.get(cmd.getCode());
        final Pair<NettyRequestProcessor, ExecutorService> pair = null == matched ? this.defaultRequestProcessor : matched;
        final int opaque = cmd.getOpaque();

        if (pair != null) {
            Runnable run = new Runnable() {
                @Override
                public void run() {
                    try {
                        doBeforeRpcHooks(RemotingHelper.parseChannelRemoteAddr(ctx.channel()), cmd);
                        final RemotingResponseCallback callback = new RemotingResponseCallback() {
                            @Override
                            public void callback(RemotingCommand response) {
                                doAfterRpcHooks(RemotingHelper.parseChannelRemoteAddr(ctx.channel()), cmd, response);
                                if (!cmd.isOnewayRPC()) {
                                    if (response != null) {
                                        response.setOpaque(opaque);
                                        response.markResponseType();
                                        try {
                                            ctx.writeAndFlush(response);
                                        } catch (Throwable e) {
                                            log.error("process request over, but response failed", e);
                                            log.error(cmd.toString());
                                            log.error(response.toString());
                                        }
                                    } else {
                                    }
                                }
                            }
                        };
                        if (pair.getObject1() instanceof AsyncNettyRequestProcessor) {
                            AsyncNettyRequestProcessor processor = (AsyncNettyRequestProcessor)pair.getObject1();
                            processor.asyncProcessRequest(ctx, cmd, callback);
                        } else {
                            NettyRequestProcessor processor = pair.getObject1();
                            RemotingCommand response = processor.processRequest(ctx, cmd);
                            callback.callback(response);
                        }
                    } catch (Throwable e) {
                        log.error("process request exception", e);
                        log.error(cmd.toString());

                        if (!cmd.isOnewayRPC()) {
                            final RemotingCommand response = RemotingCommand.createResponseCommand(RemotingSysResponseCode.SYSTEM_ERROR,
                                RemotingHelper.exceptionSimpleDesc(e));
                            response.setOpaque(opaque);
                            ctx.writeAndFlush(response);
                        }
                    }
                }
            };

            if (pair.getObject1().rejectRequest()) {
                final RemotingCommand response = RemotingCommand.createResponseCommand(RemotingSysResponseCode.SYSTEM_BUSY,
                    "[REJECTREQUEST]system busy, start flow control for a while");
                response.setOpaque(opaque);
                ctx.writeAndFlush(response);
                return;
            }

            try {
                final RequestTask requestTask = new RequestTask(run, ctx.channel(), cmd);
                pair.getObject2().submit(requestTask);
            } catch (RejectedExecutionException e) {
                if ((System.currentTimeMillis() % 10000) == 0) {
                    log.warn(RemotingHelper.parseChannelRemoteAddr(ctx.channel())
                        + ", too many requests and system thread pool busy, RejectedExecutionException "
                        + pair.getObject2().toString()
                        + " request code: " + cmd.getCode());
                }

                if (!cmd.isOnewayRPC()) {
                    final RemotingCommand response = RemotingCommand.createResponseCommand(RemotingSysResponseCode.SYSTEM_BUSY,
                        "[OVERLOAD]system busy, start flow control for a while");
                    response.setOpaque(opaque);
                    ctx.writeAndFlush(response);
                }
            }
        } else {
            String error = " request type " + cmd.getCode() + " not supported";
            final RemotingCommand response =
                RemotingCommand.createResponseCommand(RemotingSysResponseCode.REQUEST_CODE_NOT_SUPPORTED, error);
            response.setOpaque(opaque);
            ctx.writeAndFlush(response);
            log.error(RemotingHelper.parseChannelRemoteAddr(ctx.channel()) + error);
        }
    }
```

[![复制代码](RocketMQ(五)：server端处理框架及消费数据查找实现.assets/copycode.gif)](javascript:void(0);)

　　综上，整个rocketmq的code的定义，注册，以及使用，我们就有了完整的理解。了解完这些code，我们也大致可以理解rocketmq能够干多少事了。

　　而上面的processRequestCommand()也让我们看到了rmq处理请求的大体框架流程。如此，我们也大体有了概念了。

　　如果想对任意一个实现存疑问，则只需要查看其相应的processor的实现即可，从表面看是这样的。是不是有一种任督二脉被打通了的感觉。别急，敬畏之心。

 

[返回顶部](https://www.cnblogs.com/yougewe/p/14092169.html#_labelTop)

### 3. 消息数据的拉取实现

　　经过第二节，我们已经有了大体框架概念，现在，我就想了解server是如何给到消息的，请给答案。

　　基本上rocketmq的存储分为三级存储：按逻辑分： broker级存储 -> topic级存储 -> consumequeue级存储。按物理分：broker级存储 -> commitlog级存储 -> consumequeue-queueId级存储。 其中，commitlog, consumequeue 都是定长的，commitlog单个文件默认都1G大小，而consumequeue单个文件默认存储30w条记录，大小约为5.72M。定长长存储的最大好处就是，可以从最外部预估出文件中存储了些什么样数据。而且 commitlog和consumequeue文件的命名方式，都是按照起始offset作为命名的。offset作为定位记录的重要条件，有着非凡的作用。但commitlog有commitlog的offset, consumequeue有consumequeue的offset. 那么，客户端在进行消费消息的时候，到底用哪一个呢？

　　如果按照commitlog的offset进行定位，理论上只会有一次查找的过程，那么，单次定位自然是非常快的。但问题是，我们如何快速知道哪些consumer需要消费哪些数据呢？commitlog中的数据是顺序存储的，我们虽然可以快速定位一条记录，但却要为一次的记录定位预判付出巨大的代价，因为我们可能需要移动非常多的磁盘指针，然后才能知道下一个消费点在哪里！所以，貌似以commitlog的offset作为依据是不太可取的。

　　如果按照consumequeue的offset进行定位呢？我们可以很快地找到consumequeue的位置，而且移动起磁盘指针会相当地快。因消息整体是按照 topic -> queueId -> 记录 的方式进行的，且consumequeue单个数据是定长的，我们可以立即定位到记录所在位置。但是，定位consumequeue位置后，却无法知道具体的数据，因为consumequeue中仅保存了极少信息，数据真实偏移地址、数据大小以及hashtag. 不管怎么样，我们需要二次定位。取出真实的commitlog的offset, 然后按照大小取值，即得到真实的数据了。虽然存在二次查找问题，但因第一次查找是超级快速的，所以损失非常小，但却带来了非常大的收益。

　　我们回溯下注册过程，发现在 PULL_MESSAGE 注册的是 pullMessageProcessor , 如下：

[![复制代码](RocketMQ(五)：server端处理框架及消费数据查找实现.assets/copycode.gif)](javascript:void(0);)

```
        /**
         * PullMessageProcessor
         */
        this.remotingServer.registerProcessor(RequestCode.PULL_MESSAGE, this.pullMessageProcessor, this.pullMessageExecutor);
        this.pullMessageProcessor.registerConsumeMessageHook(consumeMessageHookList);
```

[![复制代码](RocketMQ(五)：server端处理框架及消费数据查找实现.assets/copycode.gif)](javascript:void(0);)

　　再往前看看 pullMessageProcessor 的具体初始化过程如下：

[![复制代码](RocketMQ(五)：server端处理框架及消费数据查找实现.assets/copycode.gif)](javascript:void(0);)

```
    // org.apache.rocketmq.broker.BrokerController#BrokerController
    public BrokerController(
        final BrokerConfig brokerConfig,
        final NettyServerConfig nettyServerConfig,
        final NettyClientConfig nettyClientConfig,
        final MessageStoreConfig messageStoreConfig
    ) {
        this.brokerConfig = brokerConfig;
        this.nettyServerConfig = nettyServerConfig;
        this.nettyClientConfig = nettyClientConfig;
        this.messageStoreConfig = messageStoreConfig;
        this.consumerOffsetManager = new ConsumerOffsetManager(this);
        this.topicConfigManager = new TopicConfigManager(this);
        // pullMessageProcessor 实例化
        this.pullMessageProcessor = new PullMessageProcessor(this);
        ...
    }
```

[![复制代码](RocketMQ(五)：server端处理框架及消费数据查找实现.assets/copycode.gif)](javascript:void(0);)

　　所以，要看如何实现消息的拉取，看看 PullMessageProcessor.processRequest() 就知道了。

[![复制代码](RocketMQ(五)：server端处理框架及消费数据查找实现.assets/copycode.gif)](javascript:void(0);)

```
    // org.apache.rocketmq.broker.processor.PullMessageProcessor#processRequest
    @Override
    public RemotingCommand processRequest(final ChannelHandlerContext ctx,
        RemotingCommand request) throws RemotingCommandException {
        return this.processRequest(ctx.channel(), request, true);
    }
    
    private RemotingCommand processRequest(final Channel channel, RemotingCommand request, boolean brokerAllowSuspend)
        throws RemotingCommandException {
        RemotingCommand response = RemotingCommand.createResponseCommand(PullMessageResponseHeader.class);
        final PullMessageResponseHeader responseHeader = (PullMessageResponseHeader) response.readCustomHeader();
        final PullMessageRequestHeader requestHeader =
            (PullMessageRequestHeader) request.decodeCommandCustomHeader(PullMessageRequestHeader.class);
        // 响应的opaque id与请求一致，以便可回滚上下文
        response.setOpaque(request.getOpaque());

        log.debug("receive PullMessage request command, {}", request);

        if (!PermName.isReadable(this.brokerController.getBrokerConfig().getBrokerPermission())) {
            response.setCode(ResponseCode.NO_PERMISSION);
            response.setRemark(String.format("the broker[%s] pulling message is forbidden", this.brokerController.getBrokerConfig().getBrokerIP1()));
            return response;
        }
        // 消费组有效性检查
        SubscriptionGroupConfig subscriptionGroupConfig =
            this.brokerController.getSubscriptionGroupManager().findSubscriptionGroupConfig(requestHeader.getConsumerGroup());
        if (null == subscriptionGroupConfig) {
            response.setCode(ResponseCode.SUBSCRIPTION_GROUP_NOT_EXIST);
            response.setRemark(String.format("subscription group [%s] does not exist, %s", requestHeader.getConsumerGroup(), FAQUrl.suggestTodo(FAQUrl.SUBSCRIPTION_GROUP_NOT_EXIST)));
            return response;
        }

        if (!subscriptionGroupConfig.isConsumeEnable()) {
            response.setCode(ResponseCode.NO_PERMISSION);
            response.setRemark("subscription group no permission, " + requestHeader.getConsumerGroup());
            return response;
        }

        final boolean hasSuspendFlag = PullSysFlag.hasSuspendFlag(requestHeader.getSysFlag());
        final boolean hasCommitOffsetFlag = PullSysFlag.hasCommitOffsetFlag(requestHeader.getSysFlag());
        final boolean hasSubscriptionFlag = PullSysFlag.hasSubscriptionFlag(requestHeader.getSysFlag());

        final long suspendTimeoutMillisLong = hasSuspendFlag ? requestHeader.getSuspendTimeoutMillis() : 0;

        TopicConfig topicConfig = this.brokerController.getTopicConfigManager().selectTopicConfig(requestHeader.getTopic());
        if (null == topicConfig) {
            log.error("the topic {} not exist, consumer: {}", requestHeader.getTopic(), RemotingHelper.parseChannelRemoteAddr(channel));
            response.setCode(ResponseCode.TOPIC_NOT_EXIST);
            response.setRemark(String.format("topic[%s] not exist, apply first please! %s", requestHeader.getTopic(), FAQUrl.suggestTodo(FAQUrl.APPLY_TOPIC_URL)));
            return response;
        }

        if (!PermName.isReadable(topicConfig.getPerm())) {
            response.setCode(ResponseCode.NO_PERMISSION);
            response.setRemark("the topic[" + requestHeader.getTopic() + "] pulling message is forbidden");
            return response;
        }
        // queueId 检查
        if (requestHeader.getQueueId() < 0 || requestHeader.getQueueId() >= topicConfig.getReadQueueNums()) {
            String errorInfo = String.format("queueId[%d] is illegal, topic:[%s] topicConfig.readQueueNums:[%d] consumer:[%s]",
                requestHeader.getQueueId(), requestHeader.getTopic(), topicConfig.getReadQueueNums(), channel.remoteAddress());
            log.warn(errorInfo);
            response.setCode(ResponseCode.SYSTEM_ERROR);
            response.setRemark(errorInfo);
            return response;
        }

        SubscriptionData subscriptionData = null;
        ConsumerFilterData consumerFilterData = null;
        if (hasSubscriptionFlag) {
            try {
                subscriptionData = FilterAPI.build(
                    requestHeader.getTopic(), requestHeader.getSubscription(), requestHeader.getExpressionType()
                );
                if (!ExpressionType.isTagType(subscriptionData.getExpressionType())) {
                    consumerFilterData = ConsumerFilterManager.build(
                        requestHeader.getTopic(), requestHeader.getConsumerGroup(), requestHeader.getSubscription(),
                        requestHeader.getExpressionType(), requestHeader.getSubVersion()
                    );
                    assert consumerFilterData != null;
                }
            } catch (Exception e) {
                log.warn("Parse the consumer's subscription[{}] failed, group: {}", requestHeader.getSubscription(),
                    requestHeader.getConsumerGroup());
                response.setCode(ResponseCode.SUBSCRIPTION_PARSE_FAILED);
                response.setRemark("parse the consumer's subscription failed");
                return response;
            }
        } else {
            ConsumerGroupInfo consumerGroupInfo =
                this.brokerController.getConsumerManager().getConsumerGroupInfo(requestHeader.getConsumerGroup());
            if (null == consumerGroupInfo) {
                log.warn("the consumer's group info not exist, group: {}", requestHeader.getConsumerGroup());
                response.setCode(ResponseCode.SUBSCRIPTION_NOT_EXIST);
                response.setRemark("the consumer's group info not exist" + FAQUrl.suggestTodo(FAQUrl.SAME_GROUP_DIFFERENT_TOPIC));
                return response;
            }

            if (!subscriptionGroupConfig.isConsumeBroadcastEnable()
                && consumerGroupInfo.getMessageModel() == MessageModel.BROADCASTING) {
                response.setCode(ResponseCode.NO_PERMISSION);
                response.setRemark("the consumer group[" + requestHeader.getConsumerGroup() + "] can not consume by broadcast way");
                return response;
            }

            subscriptionData = consumerGroupInfo.findSubscriptionData(requestHeader.getTopic());
            if (null == subscriptionData) {
                log.warn("the consumer's subscription not exist, group: {}, topic:{}", requestHeader.getConsumerGroup(), requestHeader.getTopic());
                response.setCode(ResponseCode.SUBSCRIPTION_NOT_EXIST);
                response.setRemark("the consumer's subscription not exist" + FAQUrl.suggestTodo(FAQUrl.SAME_GROUP_DIFFERENT_TOPIC));
                return response;
            }

            if (subscriptionData.getSubVersion() < requestHeader.getSubVersion()) {
                log.warn("The broker's subscription is not latest, group: {} {}", requestHeader.getConsumerGroup(),
                    subscriptionData.getSubString());
                response.setCode(ResponseCode.SUBSCRIPTION_NOT_LATEST);
                response.setRemark("the consumer's subscription not latest");
                return response;
            }
            if (!ExpressionType.isTagType(subscriptionData.getExpressionType())) {
                consumerFilterData = this.brokerController.getConsumerFilterManager().get(requestHeader.getTopic(),
                    requestHeader.getConsumerGroup());
                if (consumerFilterData == null) {
                    response.setCode(ResponseCode.FILTER_DATA_NOT_EXIST);
                    response.setRemark("The broker's consumer filter data is not exist!Your expression may be wrong!");
                    return response;
                }
                if (consumerFilterData.getClientVersion() < requestHeader.getSubVersion()) {
                    log.warn("The broker's consumer filter data is not latest, group: {}, topic: {}, serverV: {}, clientV: {}",
                        requestHeader.getConsumerGroup(), requestHeader.getTopic(), consumerFilterData.getClientVersion(), requestHeader.getSubVersion());
                    response.setCode(ResponseCode.FILTER_DATA_NOT_LATEST);
                    response.setRemark("the consumer's consumer filter data not latest");
                    return response;
                }
            }
        }

        if (!ExpressionType.isTagType(subscriptionData.getExpressionType())
            && !this.brokerController.getBrokerConfig().isEnablePropertyFilter()) {
            response.setCode(ResponseCode.SYSTEM_ERROR);
            response.setRemark("The broker does not support consumer to filter message by " + subscriptionData.getExpressionType());
            return response;
        }

        MessageFilter messageFilter;
        if (this.brokerController.getBrokerConfig().isFilterSupportRetry()) {
            messageFilter = new ExpressionForRetryMessageFilter(subscriptionData, consumerFilterData,
                this.brokerController.getConsumerFilterManager());
        } else {
            messageFilter = new ExpressionMessageFilter(subscriptionData, consumerFilterData,
                this.brokerController.getConsumerFilterManager());
        }
        // 真实的消息拉取，核心方法
        final GetMessageResult getMessageResult =
            this.brokerController.getMessageStore().getMessage(requestHeader.getConsumerGroup(), requestHeader.getTopic(),
                requestHeader.getQueueId(), requestHeader.getQueueOffset(), requestHeader.getMaxMsgNums(), messageFilter);
        if (getMessageResult != null) {
            response.setRemark(getMessageResult.getStatus().name());
            responseHeader.setNextBeginOffset(getMessageResult.getNextBeginOffset());
            responseHeader.setMinOffset(getMessageResult.getMinOffset());
            responseHeader.setMaxOffset(getMessageResult.getMaxOffset());

            if (getMessageResult.isSuggestPullingFromSlave()) {
                responseHeader.setSuggestWhichBrokerId(subscriptionGroupConfig.getWhichBrokerWhenConsumeSlowly());
            } else {
                responseHeader.setSuggestWhichBrokerId(MixAll.MASTER_ID);
            }

            switch (this.brokerController.getMessageStoreConfig().getBrokerRole()) {
                case ASYNC_MASTER:
                case SYNC_MASTER:
                    break;
                case SLAVE:
                    if (!this.brokerController.getBrokerConfig().isSlaveReadEnable()) {
                        response.setCode(ResponseCode.PULL_RETRY_IMMEDIATELY);
                        responseHeader.setSuggestWhichBrokerId(MixAll.MASTER_ID);
                    }
                    break;
            }

            if (this.brokerController.getBrokerConfig().isSlaveReadEnable()) {
                // consume too slow ,redirect to another machine
                if (getMessageResult.isSuggestPullingFromSlave()) {
                    responseHeader.setSuggestWhichBrokerId(subscriptionGroupConfig.getWhichBrokerWhenConsumeSlowly());
                }
                // consume ok
                else {
                    responseHeader.setSuggestWhichBrokerId(subscriptionGroupConfig.getBrokerId());
                }
            } else {
                responseHeader.setSuggestWhichBrokerId(MixAll.MASTER_ID);
            }
            // 设置响应code
            switch (getMessageResult.getStatus()) {
                case FOUND:
                    response.setCode(ResponseCode.SUCCESS);
                    break;
                case MESSAGE_WAS_REMOVING:
                    response.setCode(ResponseCode.PULL_RETRY_IMMEDIATELY);
                    break;
                case NO_MATCHED_LOGIC_QUEUE:
                case NO_MESSAGE_IN_QUEUE:
                    if (0 != requestHeader.getQueueOffset()) {
                        response.setCode(ResponseCode.PULL_OFFSET_MOVED);

                        // XXX: warn and notify me
                        log.info("the broker store no queue data, fix the request offset {} to {}, Topic: {} QueueId: {} Consumer Group: {}",
                            requestHeader.getQueueOffset(),
                            getMessageResult.getNextBeginOffset(),
                            requestHeader.getTopic(),
                            requestHeader.getQueueId(),
                            requestHeader.getConsumerGroup()
                        );
                    } else {
                        response.setCode(ResponseCode.PULL_NOT_FOUND);
                    }
                    break;
                case NO_MATCHED_MESSAGE:
                    response.setCode(ResponseCode.PULL_RETRY_IMMEDIATELY);
                    break;
                case OFFSET_FOUND_NULL:
                    response.setCode(ResponseCode.PULL_NOT_FOUND);
                    break;
                case OFFSET_OVERFLOW_BADLY:
                    response.setCode(ResponseCode.PULL_OFFSET_MOVED);
                    // XXX: warn and notify me
                    log.info("the request offset: {} over flow badly, broker max offset: {}, consumer: {}",
                        requestHeader.getQueueOffset(), getMessageResult.getMaxOffset(), channel.remoteAddress());
                    break;
                case OFFSET_OVERFLOW_ONE:
                    response.setCode(ResponseCode.PULL_NOT_FOUND);
                    break;
                case OFFSET_TOO_SMALL:
                    response.setCode(ResponseCode.PULL_OFFSET_MOVED);
                    log.info("the request offset too small. group={}, topic={}, requestOffset={}, brokerMinOffset={}, clientIp={}",
                        requestHeader.getConsumerGroup(), requestHeader.getTopic(), requestHeader.getQueueOffset(),
                        getMessageResult.getMinOffset(), channel.remoteAddress());
                    break;
                default:
                    assert false;
                    break;
            }

            if (this.hasConsumeMessageHook()) {
                ConsumeMessageContext context = new ConsumeMessageContext();
                context.setConsumerGroup(requestHeader.getConsumerGroup());
                context.setTopic(requestHeader.getTopic());
                context.setQueueId(requestHeader.getQueueId());

                String owner = request.getExtFields().get(BrokerStatsManager.COMMERCIAL_OWNER);

                switch (response.getCode()) {
                    case ResponseCode.SUCCESS:
                        int commercialBaseCount = brokerController.getBrokerConfig().getCommercialBaseCount();
                        int incValue = getMessageResult.getMsgCount4Commercial() * commercialBaseCount;

                        context.setCommercialRcvStats(BrokerStatsManager.StatsType.RCV_SUCCESS);
                        context.setCommercialRcvTimes(incValue);
                        context.setCommercialRcvSize(getMessageResult.getBufferTotalSize());
                        context.setCommercialOwner(owner);

                        break;
                    case ResponseCode.PULL_NOT_FOUND:
                        if (!brokerAllowSuspend) {

                            context.setCommercialRcvStats(BrokerStatsManager.StatsType.RCV_EPOLLS);
                            context.setCommercialRcvTimes(1);
                            context.setCommercialOwner(owner);

                        }
                        break;
                    case ResponseCode.PULL_RETRY_IMMEDIATELY:
                    case ResponseCode.PULL_OFFSET_MOVED:
                        context.setCommercialRcvStats(BrokerStatsManager.StatsType.RCV_EPOLLS);
                        context.setCommercialRcvTimes(1);
                        context.setCommercialOwner(owner);
                        break;
                    default:
                        assert false;
                        break;
                }

                this.executeConsumeMessageHookBefore(context);
            }

            switch (response.getCode()) {
                case ResponseCode.SUCCESS:

                    this.brokerController.getBrokerStatsManager().incGroupGetNums(requestHeader.getConsumerGroup(), requestHeader.getTopic(),
                        getMessageResult.getMessageCount());

                    this.brokerController.getBrokerStatsManager().incGroupGetSize(requestHeader.getConsumerGroup(), requestHeader.getTopic(),
                        getMessageResult.getBufferTotalSize());

                    this.brokerController.getBrokerStatsManager().incBrokerGetNums(getMessageResult.getMessageCount());
                    if (this.brokerController.getBrokerConfig().isTransferMsgByHeap()) {
                        final long beginTimeMills = this.brokerController.getMessageStore().now();
                        final byte[] r = this.readGetMessageResult(getMessageResult, requestHeader.getConsumerGroup(), requestHeader.getTopic(), requestHeader.getQueueId());
                        this.brokerController.getBrokerStatsManager().incGroupGetLatency(requestHeader.getConsumerGroup(),
                            requestHeader.getTopic(), requestHeader.getQueueId(),
                            (int) (this.brokerController.getMessageStore().now() - beginTimeMills));
                        response.setBody(r);
                    } else {
                        try {
                            FileRegion fileRegion =
                                new ManyMessageTransfer(response.encodeHeader(getMessageResult.getBufferTotalSize()), getMessageResult);
                            channel.writeAndFlush(fileRegion).addListener(new ChannelFutureListener() {
                                @Override
                                public void operationComplete(ChannelFuture future) throws Exception {
                                    getMessageResult.release();
                                    if (!future.isSuccess()) {
                                        log.error("transfer many message by pagecache failed, {}", channel.remoteAddress(), future.cause());
                                    }
                                }
                            });
                        } catch (Throwable e) {
                            log.error("transfer many message by pagecache exception", e);
                            getMessageResult.release();
                        }

                        response = null;
                    }
                    break;
                case ResponseCode.PULL_NOT_FOUND:

                    if (brokerAllowSuspend && hasSuspendFlag) {
                        long pollingTimeMills = suspendTimeoutMillisLong;
                        if (!this.brokerController.getBrokerConfig().isLongPollingEnable()) {
                            pollingTimeMills = this.brokerController.getBrokerConfig().getShortPollingTimeMills();
                        }

                        String topic = requestHeader.getTopic();
                        long offset = requestHeader.getQueueOffset();
                        int queueId = requestHeader.getQueueId();
                        PullRequest pullRequest = new PullRequest(request, channel, pollingTimeMills,
                            this.brokerController.getMessageStore().now(), offset, subscriptionData, messageFilter);
                        this.brokerController.getPullRequestHoldService().suspendPullRequest(topic, queueId, pullRequest);
                        response = null;
                        break;
                    }

                case ResponseCode.PULL_RETRY_IMMEDIATELY:
                    break;
                case ResponseCode.PULL_OFFSET_MOVED:
                    if (this.brokerController.getMessageStoreConfig().getBrokerRole() != BrokerRole.SLAVE
                        || this.brokerController.getMessageStoreConfig().isOffsetCheckInSlave()) {
                        MessageQueue mq = new MessageQueue();
                        mq.setTopic(requestHeader.getTopic());
                        mq.setQueueId(requestHeader.getQueueId());
                        mq.setBrokerName(this.brokerController.getBrokerConfig().getBrokerName());

                        OffsetMovedEvent event = new OffsetMovedEvent();
                        event.setConsumerGroup(requestHeader.getConsumerGroup());
                        event.setMessageQueue(mq);
                        event.setOffsetRequest(requestHeader.getQueueOffset());
                        event.setOffsetNew(getMessageResult.getNextBeginOffset());
                        this.generateOffsetMovedEvent(event);
                        log.warn(
                            "PULL_OFFSET_MOVED:correction offset. topic={}, groupId={}, requestOffset={}, newOffset={}, suggestBrokerId={}",
                            requestHeader.getTopic(), requestHeader.getConsumerGroup(), event.getOffsetRequest(), event.getOffsetNew(),
                            responseHeader.getSuggestWhichBrokerId());
                    } else {
                        responseHeader.setSuggestWhichBrokerId(subscriptionGroupConfig.getBrokerId());
                        response.setCode(ResponseCode.PULL_RETRY_IMMEDIATELY);
                        log.warn("PULL_OFFSET_MOVED:none correction. topic={}, groupId={}, requestOffset={}, suggestBrokerId={}",
                            requestHeader.getTopic(), requestHeader.getConsumerGroup(), requestHeader.getQueueOffset(),
                            responseHeader.getSuggestWhichBrokerId());
                    }

                    break;
                default:
                    assert false;
            }
        } else {
            response.setCode(ResponseCode.SYSTEM_ERROR);
            response.setRemark("store getMessage return null");
        }

        boolean storeOffsetEnable = brokerAllowSuspend;
        storeOffsetEnable = storeOffsetEnable && hasCommitOffsetFlag;
        storeOffsetEnable = storeOffsetEnable
            && this.brokerController.getMessageStoreConfig().getBrokerRole() != BrokerRole.SLAVE;
        if (storeOffsetEnable) {
            this.brokerController.getConsumerOffsetManager().commitOffset(RemotingHelper.parseChannelRemoteAddr(channel),
                requestHeader.getConsumerGroup(), requestHeader.getTopic(), requestHeader.getQueueId(), requestHeader.getCommitOffset());
        }
        return response;
    }
```

[![复制代码](RocketMQ(五)：server端处理框架及消费数据查找实现.assets/copycode.gif)](javascript:void(0);)

　　代码相当复杂不！实际上还行，主要逻辑都写在这儿了。主要就是各种异常情况的判定，以及获取消息之后的状态码的设定。而拉取消息却只有一行，让我们细看下：

[![复制代码](RocketMQ(五)：server端处理框架及消费数据查找实现.assets/copycode.gif)](javascript:void(0);)

```
    // org.apache.rocketmq.store.DefaultMessageStore#getMessage
    public GetMessageResult getMessage(final String group, final String topic, final int queueId, final long offset,
        final int maxMsgNums,
        final MessageFilter messageFilter) {
        if (this.shutdown) {
            log.warn("message store has shutdown, so getMessage is forbidden");
            return null;
        }

        if (!this.runningFlags.isReadable()) {
            log.warn("message store is not readable, so getMessage is forbidden " + this.runningFlags.getFlagBits());
            return null;
        }

        long beginTime = this.getSystemClock().now();

        GetMessageStatus status = GetMessageStatus.NO_MESSAGE_IN_QUEUE;
        long nextBeginOffset = offset;
        long minOffset = 0;
        long maxOffset = 0;

        GetMessageResult getResult = new GetMessageResult();

        final long maxOffsetPy = this.commitLog.getMaxOffset();
        // 根据topic和queueId获取 consumeQueue
        // 主要就是从 consumeQueueTable 的hashMap中获取或者新创建
        ConsumeQueue consumeQueue = findConsumeQueue(topic, queueId);
        if (consumeQueue != null) {
            minOffset = consumeQueue.getMinOffsetInQueue();
            maxOffset = consumeQueue.getMaxOffsetInQueue();

            if (maxOffset == 0) {
                status = GetMessageStatus.NO_MESSAGE_IN_QUEUE;
                nextBeginOffset = nextOffsetCorrection(offset, 0);
            } else if (offset < minOffset) {
                status = GetMessageStatus.OFFSET_TOO_SMALL;
                nextBeginOffset = nextOffsetCorrection(offset, minOffset);
            } else if (offset == maxOffset) {
                status = GetMessageStatus.OFFSET_OVERFLOW_ONE;
                nextBeginOffset = nextOffsetCorrection(offset, offset);
            } else if (offset > maxOffset) {
                status = GetMessageStatus.OFFSET_OVERFLOW_BADLY;
                if (0 == minOffset) {
                    nextBeginOffset = nextOffsetCorrection(offset, minOffset);
                } else {
                    nextBeginOffset = nextOffsetCorrection(offset, maxOffset);
                }
            } else {
                // 根据offset可获取consumeQueue索引信息
                SelectMappedBufferResult bufferConsumeQueue = consumeQueue.getIndexBuffer(offset);
                if (bufferConsumeQueue != null) {
                    try {
                        status = GetMessageStatus.NO_MATCHED_MESSAGE;

                        long nextPhyFileStartOffset = Long.MIN_VALUE;
                        long maxPhyOffsetPulling = 0;

                        int i = 0;
                        final int maxFilterMessageCount = Math.max(16000, maxMsgNums * ConsumeQueue.CQ_STORE_UNIT_SIZE);
                        final boolean diskFallRecorded = this.messageStoreConfig.isDiskFallRecorded();
                        ConsumeQueueExt.CqExtUnit cqExtUnit = new ConsumeQueueExt.CqExtUnit();
                        // 依次遍历队列文件，查找消息的具体索引信息
                        for (; i < bufferConsumeQueue.getSize() && i < maxFilterMessageCount; i += ConsumeQueue.CQ_STORE_UNIT_SIZE) {
                            // 从comsumeQueue中获取偏移量
                            long offsetPy = bufferConsumeQueue.getByteBuffer().getLong();
                            int sizePy = bufferConsumeQueue.getByteBuffer().getInt();
                            long tagsCode = bufferConsumeQueue.getByteBuffer().getLong();

                            maxPhyOffsetPulling = offsetPy;
                            // 是否超出文件偏移过小，快速判定
                            if (nextPhyFileStartOffset != Long.MIN_VALUE) {
                                if (offsetPy < nextPhyFileStartOffset)
                                    continue;
                            }

                            boolean isInDisk = checkInDiskByCommitOffset(offsetPy, maxOffsetPy);

                            if (this.isTheBatchFull(sizePy, maxMsgNums, getResult.getBufferTotalSize(), getResult.getMessageCount(),
                                isInDisk)) {
                                break;
                            }

                            boolean extRet = false, isTagsCodeLegal = true;
                            if (consumeQueue.isExtAddr(tagsCode)) {
                                extRet = consumeQueue.getExt(tagsCode, cqExtUnit);
                                if (extRet) {
                                    tagsCode = cqExtUnit.getTagsCode();
                                } else {
                                    // can't find ext content.Client will filter messages by tag also.
                                    log.error("[BUG] can't find consume queue extend file content!addr={}, offsetPy={}, sizePy={}, topic={}, group={}",
                                        tagsCode, offsetPy, sizePy, topic, group);
                                    isTagsCodeLegal = false;
                                }
                            }
                            // 消息过滤器处理
                            if (messageFilter != null
                                && !messageFilter.isMatchedByConsumeQueue(isTagsCodeLegal ? tagsCode : null, extRet ? cqExtUnit : null)) {
                                if (getResult.getBufferTotalSize() == 0) {
                                    status = GetMessageStatus.NO_MATCHED_MESSAGE;
                                }

                                continue;
                            }
                            // 根据偏移量信息，从commitlog 中获取具体消息数据
                            SelectMappedBufferResult selectResult = this.commitLog.getMessage(offsetPy, sizePy);
                            if (null == selectResult) {
                                if (getResult.getBufferTotalSize() == 0) {
                                    status = GetMessageStatus.MESSAGE_WAS_REMOVING;
                                }

                                nextPhyFileStartOffset = this.commitLog.rollNextFile(offsetPy);
                                continue;
                            }

                            if (messageFilter != null
                                && !messageFilter.isMatchedByCommitLog(selectResult.getByteBuffer().slice(), null)) {
                                if (getResult.getBufferTotalSize() == 0) {
                                    status = GetMessageStatus.NO_MATCHED_MESSAGE;
                                }
                                // release...
                                selectResult.release();
                                continue;
                            }

                            this.storeStatsService.getGetMessageTransferedMsgCount().incrementAndGet();
                            getResult.addMessage(selectResult);
                            status = GetMessageStatus.FOUND;
                            nextPhyFileStartOffset = Long.MIN_VALUE;
                        }

                        if (diskFallRecorded) {
                            long fallBehind = maxOffsetPy - maxPhyOffsetPulling;
                            brokerStatsManager.recordDiskFallBehindSize(group, topic, queueId, fallBehind);
                        }

                        nextBeginOffset = offset + (i / ConsumeQueue.CQ_STORE_UNIT_SIZE);

                        long diff = maxOffsetPy - maxPhyOffsetPulling;
                        long memory = (long) (StoreUtil.TOTAL_PHYSICAL_MEMORY_SIZE
                            * (this.messageStoreConfig.getAccessMessageInMemoryMaxRatio() / 100.0));
                        getResult.setSuggestPullingFromSlave(diff > memory);
                    } finally {

                        bufferConsumeQueue.release();
                    }
                } else {
                    status = GetMessageStatus.OFFSET_FOUND_NULL;
                    nextBeginOffset = nextOffsetCorrection(offset, consumeQueue.rollNextFile(offset));
                    log.warn("consumer request topic: " + topic + "offset: " + offset + " minOffset: " + minOffset + " maxOffset: "
                        + maxOffset + ", but access logic queue failed.");
                }
            }
        } else {
            status = GetMessageStatus.NO_MATCHED_LOGIC_QUEUE;
            nextBeginOffset = nextOffsetCorrection(offset, 0);
        }

        if (GetMessageStatus.FOUND == status) {
            this.storeStatsService.getGetMessageTimesTotalFound().incrementAndGet();
        } else {
            this.storeStatsService.getGetMessageTimesTotalMiss().incrementAndGet();
        }
        long elapsedTime = this.getSystemClock().now() - beginTime;
        this.storeStatsService.setGetMessageEntireTimeMax(elapsedTime);

        getResult.setStatus(status);
        getResult.setNextBeginOffset(nextBeginOffset);
        getResult.setMaxOffset(maxOffset);
        getResult.setMinOffset(minOffset);
        return getResult;
    }

    public ConsumeQueue findConsumeQueue(String topic, int queueId) {
        ConcurrentMap<Integer, ConsumeQueue> map = consumeQueueTable.get(topic);
        if (null == map) {
            ConcurrentMap<Integer, ConsumeQueue> newMap = new ConcurrentHashMap<Integer, ConsumeQueue>(128);
            ConcurrentMap<Integer, ConsumeQueue> oldMap = consumeQueueTable.putIfAbsent(topic, newMap);
            if (oldMap != null) {
                map = oldMap;
            } else {
                map = newMap;
            }
        }

        ConsumeQueue logic = map.get(queueId);
        if (null == logic) {
            ConsumeQueue newLogic = new ConsumeQueue(
                topic,
                queueId,
                StorePathConfigHelper.getStorePathConsumeQueue(this.messageStoreConfig.getStorePathRootDir()),
                this.getMessageStoreConfig().getMappedFileSizeConsumeQueue(),
                this);
            ConsumeQueue oldLogic = map.putIfAbsent(queueId, newLogic);
            if (oldLogic != null) {
                logic = oldLogic;
            } else {
                logic = newLogic;
            }
        }

        return logic;
    }
    // 以上查找过程，有一个重要的点，即如何根据offset找到索引所在位置？
    // 查找索引所在文件的实现,如下：
    // org.apache.rocketmq.store.ConsumeQueue#getIndexBuffer
    public SelectMappedBufferResult getIndexBuffer(final long startIndex) {
        int mappedFileSize = this.mappedFileSize;
        long offset = startIndex * CQ_STORE_UNIT_SIZE;
        if (offset >= this.getMinLogicOffset()) {
            // 委托给mappedFileQueue进行查找到单个具体的consumequeue文件
            MappedFile mappedFile = this.mappedFileQueue.findMappedFileByOffset(offset);
            if (mappedFile != null) {
                // 再根据剩余的偏移量，直接类似于数组下标的形式，一次性定位到具体的数据记录
                // 这设计，这效率不能再高了
                SelectMappedBufferResult result = mappedFile.selectMappedBuffer((int) (offset % mappedFileSize));
                return result;
            }
        }
        return null;
    }
    // org.apache.rocketmq.store.MappedFileQueue#findMappedFileByOffset
    public MappedFile findMappedFileByOffset(final long offset) {
        return findMappedFileByOffset(offset, false);
    }
    /**
     * Finds a mapped file by offset.
     *
     * @param offset Offset.
     * @param returnFirstOnNotFound If the mapped file is not found, then return the first one.
     * @return Mapped file or null (when not found and returnFirstOnNotFound is <code>false</code>).
     */
    public MappedFile findMappedFileByOffset(final long offset, final boolean returnFirstOnNotFound) {
        try {
            MappedFile firstMappedFile = this.getFirstMappedFile();
            MappedFile lastMappedFile = this.getLastMappedFile();
            if (firstMappedFile != null && lastMappedFile != null) {
                // 越界处理
                if (offset < firstMappedFile.getFileFromOffset() || offset >= lastMappedFile.getFileFromOffset() + this.mappedFileSize) {
                    LOG_ERROR.warn("Offset not matched. Request offset: {}, firstOffset: {}, lastOffset: {}, mappedFileSize: {}, mappedFiles count: {}",
                        offset,
                        firstMappedFile.getFileFromOffset(),
                        lastMappedFile.getFileFromOffset() + this.mappedFileSize,
                        this.mappedFileSize,
                        this.mappedFiles.size());
                } else {
                    // 直接根据偏移量和单文件大小，即计算出偏移量所在文件（或者说应该在的文件）
                    // firstMappedFile.getFileFromOffset() / this.mappedFileSize 代表了第一条记录所处的文件位置编号
                    // offset / this.mappedFileSize 代表当前offset所处的文件编号
                    // 那么，两个编号相减就是当前offset对应的文件编号，因为第一个文件编号的相对位置是0
                    // 但有个前提：就是每个文件存储的大小必须是真实的对应的 offset 大小之差，而实际上consumeQueue根本无法确定它存了多少offset
                    // consumequeue 只知道自身可以存放30w个记录，总共5.72M大小
                    // 也就是说，只要文件定长，offset用于定位 commitlog文件是合理的，用于定位 consumequeue 也是合理的
                    // 事实上，针对消费者这个 offset 是consumeQueue 分配的，而不是真正的commitlog的offset, 它只是一个逻辑偏移量，并非真正的物理偏移
                    int index = (int) ((offset / this.mappedFileSize) - (firstMappedFile.getFileFromOffset() / this.mappedFileSize));
                    MappedFile targetFile = null;
                    try {
                        // 根据偏移量可以以 O(1) 复杂度或者准确说，一次就定位到所在consumequeue文件
                        // 然后再根据剩余的偏移量信息，再一次就准确定位到具体的索引记录位置
                        targetFile = this.mappedFiles.get(index);
                    } catch (Exception ignored) {
                    }

                    if (targetFile != null && offset >= targetFile.getFileFromOffset()
                        && offset < targetFile.getFileFromOffset() + this.mappedFileSize) {
                        return targetFile;
                    }
                    // 推算不正确？做兜底顺序查找！
                    for (MappedFile tmpMappedFile : this.mappedFiles) {
                        if (offset >= tmpMappedFile.getFileFromOffset()
                            && offset < tmpMappedFile.getFileFromOffset() + this.mappedFileSize) {
                            return tmpMappedFile;
                        }
                    }
                }

                if (returnFirstOnNotFound) {
                    return firstMappedFile;
                }
            }
        } catch (Exception e) {
            log.error("findMappedFileByOffset Exception", e);
        }

        return null;
    }
```

[![复制代码](RocketMQ(五)：server端处理框架及消费数据查找实现.assets/copycode.gif)](javascript:void(0);)

 

　　如此，整个查找过程就清晰了：大概就是先查找consumequeue所在的buffer，然后从该buffer中根据offset定位到具体的consumequeue索引记录取出数据偏移及大小信息, 然后根据该索引信息到commitlog文件中取出数据即可, 如果配置了过滤器则通过过滤器验证的数据才为有效数据;

　　整个查找过程的时序图大致如下：

![img](RocketMQ(五)：server端处理框架及消费数据查找实现.assets/830731-20201206110755975-181524907.png)

 

 

　　最后，提个问题：根据以上内容，一次pull会拿到多少条消息数据呢？

不要害怕今日的苦，你要相信明天，更苦！

分类: [协议类](https://www.cnblogs.com/yougewe/category/755891.html), [原理&故事](https://www.cnblogs.com/yougewe/category/789557.html), [java](https://www.cnblogs.com/yougewe/category/923459.html), [大数据](https://www.cnblogs.com/yougewe/category/1238476.html), [源码](https://www.cnblogs.com/yougewe/category/1278448.html), [算法](https://www.cnblogs.com/yougewe/category/1844743.html)

标签: [nameserver](https://www.cnblogs.com/yougewe/tag/nameserver/), [broker](https://www.cnblogs.com/yougewe/tag/broker/), [多级存储](https://www.cnblogs.com/yougewe/tag/多级存储/), [页缓存](https://www.cnblogs.com/yougewe/tag/页缓存/), [架构](https://www.cnblogs.com/yougewe/tag/架构/), [分片](https://www.cnblogs.com/yougewe/tag/分片/), [rocketmq](https://www.cnblogs.com/yougewe/tag/rocketmq/), [netty](https://www.cnblogs.com/yougewe/tag/netty/), [消息队列](https://www.cnblogs.com/yougewe/tag/消息队列/), [定长存储](https://www.cnblogs.com/yougewe/tag/定长存储/)