# [RocketMQ(七)：高性能探秘之MappedFile](https://www.cnblogs.com/yougewe/p/14164651.html)



**目录**

- [1. 高性能高并发系统的底层技能概述](https://www.cnblogs.com/yougewe/p/14164651.html#_label0)
- [2. 高性能高并发操作系统api列举](https://www.cnblogs.com/yougewe/p/14164651.html#_label1)
- [3. rocketmq中的高性能法宝](https://www.cnblogs.com/yougewe/p/14164651.html#_label2)
- [4. rocketmq中对mmap和pagecache的应用](https://www.cnblogs.com/yougewe/p/14164651.html#_label3)
- [5. mappedFile压测性能几何](https://www.cnblogs.com/yougewe/p/14164651.html#_label4)



------

　　RocketMQ作为消息中间件，经常会被用来和其他消息中间件做比较，比对rabbitmq, kafka... 但个人觉得它一直对标的，都是kafka。因为它们面对的场景往往都是超高并发，超高性能要求的场景。

　　所以，有必要深挖下其实现高性能，高并发的原因。实际上，这是非常大的话题，我这里也不打算一口吃个大胖子。我会给出个大概答案，然后我们再深入挖掘其中部分实现。如题所述。

 

[返回顶部](https://www.cnblogs.com/yougewe/p/14164651.html#_labelTop)

### 1. 高性能高并发系统的底层技能概述

　　我不打算单讲rocketmq到底是如何实现高性能高并发的，因为实际上的底层原则都是差不多的。rocketmq不过是其中的一个实现者而已。

　　那么，要想实现高性能高并发，大概需要怎么做的呢？本质上讲，我们的系统服务能利用的东西并不多，CPU、内存、磁盘、网络、硬件特性。。。 当然了，还有一个非常重要的东西，就是我们基本都是在做应用层服务，所以我们的能力往往必须依托于操作系统提供的服务，由这些服务去更好地利用底层硬件的东西。好吧，显得逼格好像有点高了，实际上就是一个系统API调用。

　　接下来，我们从每个小点出发，来看看我们如何做到高性能高并发：

　　第一个：CPU。可以说，CPU代表了单机的极限。如果能够做有效利用CPU, 使其随时可保证在80%以上的使用率，那么你这个服务绝对够牛逼了（注意不是导致疯狂GC的那种利用率哦）。那么，我们如何做到高效利用CPU呢？有些应用天然就是CPU型的，比如提供一些做大数的运算服务，天生就需要大量CPU运算。而其他的很多的IO型的应用，则CPU往往不会太高，或者说我们应该往高了的方向优化。

　　第二个：内存。内存是一个非常宝贵的资源，因为内存的调度速度非常快。如果一个应用的业务处理都是基于内存的，那么这个应用基本上就会超级强悍。大部分情况下，越大的内存往往也能提供越高的性能，比如ES的搜索服务，要想性能好必需有足够内存。当然了，内存除了使用起来非常方便之外，它还有一个重要的工作，就是内存的回收。当然，这部分工作一般都会被编程语言屏蔽掉，因为它实在太难了。我们一般只需按照语言特性，合理的处理对象即可。另外，我们可以使一些可能需要从外部设备读入的数据，加载到内存中长期使用，这将是一件非常重要的优化动作。如何维护好数据一致性与安全性和准确性，是这类工作的重点。

　　第三个：磁盘。内存虽好，但却不常有。内存往往意味着大小受限。而与之对应的就是磁盘，磁盘则往往意味空间非常大，数据永久存储安全。磁盘基本上就代表了单机的存储极限，但也同时限制了并发能力。

　　第四个：网络。也许这个名词不太合适，但却是因为网络才发生了变化。如果说前面讲的都是单机的极限性能，那么，网络就会带来分布式系统的极限性能。一个庞大的系统，一定是分布式的，因此必然会使用到网络这个设备。但我们一般不会在这上面节省多少东西，我们能做的，也许就是简单的压缩下文件数据而已。更多的，也许我们只是申请更大的带宽，或者开辟新的布线，以满足系统的需要。在网络这一环境，如何更好地组织网络设备，是重中之重，而这往往又回到了上面三个话题之一了。

   最后，排除上面几个硬技能，还有一个也是非常重要的技能：那就是算法，没有好的算法，再多的优化可能也只是杯水车薪。（当然了我们大部分情况下是无需高级算法的，因为大部分时间，我们只是大自然的搬运工）

 

[返回顶部](https://www.cnblogs.com/yougewe/p/14164651.html#_labelTop)

### 2. 高性能高并发操作系统api列举

　　前面说的，更多是理论上讲如何形成牛逼的应用服务。但我们又没那能力去搞操作系统的东西，所以也只能想想而已。那么说到底，我们能做什么呢？所谓工欲善其事，必先利其器。所谓利器，也就是看看操作系统提供什么样的底层API 。

　　我这里就稍微列几个吧（我也就知道这么些了）：

　　epoll系列: IO多路复用技术，高并发高性能网络应用必备。大致作用就是使用极少数的线程，高效地管理大量io事件，通知应用等。大概的接口有: epoll_create(), epoll_ctl(), epoll_wait();

　　pagecache系列: 操作系统页缓存，高效读写文件必备。大致作用就是保留部分磁盘数据在内存中，以便应用想读取或者磁盘数据数据时能够非常快速的响应。相关接口如: read(), write(), readpage(), writepage(), sync(), fsync().

　　mmap系列: 内存映射。可以将文件映射到内存中，用户写数据时直接向该内存缓冲区写数据，即可达到写磁盘的作用了，从而提高写入性能。接口如: mmap(), munmap();

　　directio系列: 直接io操作，避免用户态数据到内核态数据的相互copy, 节省cpu和内存占用。

　　cas系列: 高效安全锁实现。相关接口: cmpxchg() 。

　　多线程系列: 大部分网络应用，都io型的，那么如何同时处理多个请求就非常重要了。多线程提供非常便捷的并发编程基础，使得我们可以更简单的处理业务而且提供超高的处理能力。这自然是编程语言直接提供的。

 

[返回顶部](https://www.cnblogs.com/yougewe/p/14164651.html#_labelTop)

### 3. rocketmq中的高性能法宝

　　rocketmq想要实现高并发高性能处理能力，自然要从操作系统层面去寻求方法，自然也就逃不过前面的几点说法了。

　　首先，它基于netty实现了高性能的网络通信，netty基于事件的io模型，零拷贝的技术，已经提供了非常好的技术前提，rocketmq只需利用一下，就可以将自己变得很厉害了。当然，这只是其厉害的一个点，因为单有了高效网络通信处理能力还不够的。至少，rocketmq得提供高效的数据序列化方式。

　　其次，有了netty作为通信框架，高效接入请求后，rocketmq自身处理业务的方式非常重要。如果能够直接基于内存保存数据，那必然是最高性能的。但是它不能那样做，因为内存太小，无法容纳下应有的消息。所以，只能基于文件做存储。而文件本身的操作又是代价非常高的，所以，必须要有些稍微的措施，避免重量级的操作文件。所以，文件的多级存储又是非常重要的了，即如索引文件在db中的应用就知道了。

　　再其次，java提供了非常好的多线程编程环境，不加以利用就对不起观众了。良好的线程模型，为其高性能呐喊助威。

　　最后，基于pagecache和mmap的高效文件读写，才是其制胜法宝。这也是我们接下来想要重点说明的。

 

[返回顶部](https://www.cnblogs.com/yougewe/p/14164651.html#_labelTop)

### 4. rocketmq中对mmap和pagecache的应用

　　上一点中提到的每个点，都是rocketmq出众的原因，但我们今天只会来说一点：rocketmq的高效文件存储。

　　实际上，根据我之前的几篇文章，我们很容易找到rocketmq是如何对文件进行读写的。我们就以producer写消息数据为例，来回顾看看rmq是如何进行高效文件存储的。

[![复制代码](RocketMQ(七)：高性能探秘之MappedFile.assets/copycode.gif)](javascript:void(0);)

```
    // 处理器入口
    // org.apache.rocketmq.broker.processor.SendMessageProcessor#processRequest
    @Override
    public RemotingCommand processRequest(ChannelHandlerContext ctx,
                                          RemotingCommand request) throws RemotingCommandException {
        RemotingCommand response = null;
        try {
            response = asyncProcessRequest(ctx, request).get();
        } catch (InterruptedException | ExecutionException e) {
            log.error("process SendMessage error, request : " + request.toString(), e);
        }
        return response;
    }
    // 接收转发，异步处理
    public CompletableFuture<RemotingCommand> asyncProcessRequest(ChannelHandlerContext ctx,
                                                                  RemotingCommand request) throws RemotingCommandException {
        final SendMessageContext mqtraceContext;
        switch (request.getCode()) {
            case RequestCode.CONSUMER_SEND_MSG_BACK:
                return this.asyncConsumerSendMsgBack(ctx, request);
            default:
                // 写入数据
                SendMessageRequestHeader requestHeader = parseRequestHeader(request);
                if (requestHeader == null) {
                    return CompletableFuture.completedFuture(null);
                }
                mqtraceContext = buildMsgContext(ctx, requestHeader);
                this.executeSendMessageHookBefore(ctx, request, mqtraceContext);
                if (requestHeader.isBatch()) {
                    return this.asyncSendBatchMessage(ctx, request, mqtraceContext, requestHeader);
                } else {
                    return this.asyncSendMessage(ctx, request, mqtraceContext, requestHeader);
                }
        }
    }
    // org.apache.rocketmq.store.CommitLog#putMessage
    public PutMessageResult putMessage(final MessageExtBrokerInner msg) {
        // Set the storage time
        msg.setStoreTimestamp(System.currentTimeMillis());
        // Set the message body BODY CRC (consider the most appropriate setting
        // on the client)
        msg.setBodyCRC(UtilAll.crc32(msg.getBody()));
        // Back to Results
        AppendMessageResult result = null;

        StoreStatsService storeStatsService = this.defaultMessageStore.getStoreStatsService();

        String topic = msg.getTopic();
        int queueId = msg.getQueueId();

        final int tranType = MessageSysFlag.getTransactionValue(msg.getSysFlag());
        if (tranType == MessageSysFlag.TRANSACTION_NOT_TYPE
            || tranType == MessageSysFlag.TRANSACTION_COMMIT_TYPE) {
            // Delay Delivery
            if (msg.getDelayTimeLevel() > 0) {
                if (msg.getDelayTimeLevel() > this.defaultMessageStore.getScheduleMessageService().getMaxDelayLevel()) {
                    msg.setDelayTimeLevel(this.defaultMessageStore.getScheduleMessageService().getMaxDelayLevel());
                }

                topic = TopicValidator.RMQ_SYS_SCHEDULE_TOPIC;
                queueId = ScheduleMessageService.delayLevel2QueueId(msg.getDelayTimeLevel());

                // Backup real topic, queueId
                MessageAccessor.putProperty(msg, MessageConst.PROPERTY_REAL_TOPIC, msg.getTopic());
                MessageAccessor.putProperty(msg, MessageConst.PROPERTY_REAL_QUEUE_ID, String.valueOf(msg.getQueueId()));
                msg.setPropertiesString(MessageDecoder.messageProperties2String(msg.getProperties()));

                msg.setTopic(topic);
                msg.setQueueId(queueId);
            }
        }

        InetSocketAddress bornSocketAddress = (InetSocketAddress) msg.getBornHost();
        if (bornSocketAddress.getAddress() instanceof Inet6Address) {
            msg.setBornHostV6Flag();
        }

        InetSocketAddress storeSocketAddress = (InetSocketAddress) msg.getStoreHost();
        if (storeSocketAddress.getAddress() instanceof Inet6Address) {
            msg.setStoreHostAddressV6Flag();
        }

        long elapsedTimeInLock = 0;

        MappedFile unlockMappedFile = null;
        MappedFile mappedFile = this.mappedFileQueue.getLastMappedFile();

        putMessageLock.lock(); //spin or ReentrantLock ,depending on store config
        try {
            long beginLockTimestamp = this.defaultMessageStore.getSystemClock().now();
            this.beginTimeInLock = beginLockTimestamp;

            // Here settings are stored timestamp, in order to ensure an orderly
            // global
            msg.setStoreTimestamp(beginLockTimestamp);

            if (null == mappedFile || mappedFile.isFull()) {
                mappedFile = this.mappedFileQueue.getLastMappedFile(0); // Mark: NewFile may be cause noise
            }
            if (null == mappedFile) {
                log.error("create mapped file1 error, topic: " + msg.getTopic() + " clientAddr: " + msg.getBornHostString());
                beginTimeInLock = 0;
                return new PutMessageResult(PutMessageStatus.CREATE_MAPEDFILE_FAILED, null);
            }

            result = mappedFile.appendMessage(msg, this.appendMessageCallback);
            switch (result.getStatus()) {
                case PUT_OK:
                    break;
                case END_OF_FILE:
                    unlockMappedFile = mappedFile;
                    // Create a new file, re-write the message
                    mappedFile = this.mappedFileQueue.getLastMappedFile(0);
                    if (null == mappedFile) {
                        // XXX: warn and notify me
                        log.error("create mapped file2 error, topic: " + msg.getTopic() + " clientAddr: " + msg.getBornHostString());
                        beginTimeInLock = 0;
                        return new PutMessageResult(PutMessageStatus.CREATE_MAPEDFILE_FAILED, result);
                    }
                    result = mappedFile.appendMessage(msg, this.appendMessageCallback);
                    break;
                case MESSAGE_SIZE_EXCEEDED:
                case PROPERTIES_SIZE_EXCEEDED:
                    beginTimeInLock = 0;
                    return new PutMessageResult(PutMessageStatus.MESSAGE_ILLEGAL, result);
                case UNKNOWN_ERROR:
                    beginTimeInLock = 0;
                    return new PutMessageResult(PutMessageStatus.UNKNOWN_ERROR, result);
                default:
                    beginTimeInLock = 0;
                    return new PutMessageResult(PutMessageStatus.UNKNOWN_ERROR, result);
            }

            elapsedTimeInLock = this.defaultMessageStore.getSystemClock().now() - beginLockTimestamp;
            beginTimeInLock = 0;
        } finally {
            putMessageLock.unlock();
        }

        if (elapsedTimeInLock > 500) {
            log.warn("[NOTIFYME]putMessage in lock cost time(ms)={}, bodyLength={} AppendMessageResult={}", elapsedTimeInLock, msg.getBody().length, result);
        }

        if (null != unlockMappedFile && this.defaultMessageStore.getMessageStoreConfig().isWarmMapedFileEnable()) {
            this.defaultMessageStore.unlockMappedFile(unlockMappedFile);
        }

        PutMessageResult putMessageResult = new PutMessageResult(PutMessageStatus.PUT_OK, result);

        // Statistics
        storeStatsService.getSinglePutMessageTopicTimesTotal(msg.getTopic()).incrementAndGet();
        storeStatsService.getSinglePutMessageTopicSizeTotal(topic).addAndGet(result.getWroteBytes());

        handleDiskFlush(result, putMessageResult, msg);
        handleHA(result, putMessageResult, msg);

        return putMessageResult;
    }


    // org.apache.rocketmq.broker.processor.SendMessageProcessor#asyncSendMessage
    private CompletableFuture<RemotingCommand> asyncSendMessage(ChannelHandlerContext ctx, RemotingCommand request,
                                                                SendMessageContext mqtraceContext,
                                                                SendMessageRequestHeader requestHeader) {
        final RemotingCommand response = preSend(ctx, request, requestHeader);
        final SendMessageResponseHeader responseHeader = (SendMessageResponseHeader)response.readCustomHeader();

        if (response.getCode() != -1) {
            return CompletableFuture.completedFuture(response);
        }

        final byte[] body = request.getBody();

        int queueIdInt = requestHeader.getQueueId();
        TopicConfig topicConfig = this.brokerController.getTopicConfigManager().selectTopicConfig(requestHeader.getTopic());

        if (queueIdInt < 0) {
            queueIdInt = randomQueueId(topicConfig.getWriteQueueNums());
        }

        MessageExtBrokerInner msgInner = new MessageExtBrokerInner();
        msgInner.setTopic(requestHeader.getTopic());
        msgInner.setQueueId(queueIdInt);

        if (!handleRetryAndDLQ(requestHeader, response, request, msgInner, topicConfig)) {
            return CompletableFuture.completedFuture(response);
        }

        msgInner.setBody(body);
        msgInner.setFlag(requestHeader.getFlag());
        MessageAccessor.setProperties(msgInner, MessageDecoder.string2messageProperties(requestHeader.getProperties()));
        msgInner.setPropertiesString(requestHeader.getProperties());
        msgInner.setBornTimestamp(requestHeader.getBornTimestamp());
        msgInner.setBornHost(ctx.channel().remoteAddress());
        msgInner.setStoreHost(this.getStoreHost());
        msgInner.setReconsumeTimes(requestHeader.getReconsumeTimes() == null ? 0 : requestHeader.getReconsumeTimes());
        String clusterName = this.brokerController.getBrokerConfig().getBrokerClusterName();
        MessageAccessor.putProperty(msgInner, MessageConst.PROPERTY_CLUSTER, clusterName);
        msgInner.setPropertiesString(MessageDecoder.messageProperties2String(msgInner.getProperties()));

        CompletableFuture<PutMessageResult> putMessageResult = null;
        Map<String, String> origProps = MessageDecoder.string2messageProperties(requestHeader.getProperties());
        String transFlag = origProps.get(MessageConst.PROPERTY_TRANSACTION_PREPARED);
        if (transFlag != null && Boolean.parseBoolean(transFlag)) {
            if (this.brokerController.getBrokerConfig().isRejectTransactionMessage()) {
                response.setCode(ResponseCode.NO_PERMISSION);
                response.setRemark(
                        "the broker[" + this.brokerController.getBrokerConfig().getBrokerIP1()
                                + "] sending transaction message is forbidden");
                return CompletableFuture.completedFuture(response);
            }
            putMessageResult = this.brokerController.getTransactionalMessageService().asyncPrepareMessage(msgInner);
        } else {
            // 简单起见，我们只看非事务的消息写入
            putMessageResult = this.brokerController.getMessageStore().asyncPutMessage(msgInner);
        }
        return handlePutMessageResultFuture(putMessageResult, response, request, msgInner, responseHeader, mqtraceContext, ctx, queueIdInt);
    }
    // org.apache.rocketmq.store.DefaultMessageStore#asyncPutMessage
    @Override
    public CompletableFuture<PutMessageResult> asyncPutMessage(MessageExtBrokerInner msg) {
        PutMessageStatus checkStoreStatus = this.checkStoreStatus();
        if (checkStoreStatus != PutMessageStatus.PUT_OK) {
            return CompletableFuture.completedFuture(new PutMessageResult(checkStoreStatus, null));
        }

        PutMessageStatus msgCheckStatus = this.checkMessage(msg);
        if (msgCheckStatus == PutMessageStatus.MESSAGE_ILLEGAL) {
            return CompletableFuture.completedFuture(new PutMessageResult(msgCheckStatus, null));
        }
        // 写入消息数据到commitLog中
        long beginTime = this.getSystemClock().now();
        CompletableFuture<PutMessageResult> putResultFuture = this.commitLog.asyncPutMessage(msg);

        putResultFuture.thenAccept((result) -> {
            long elapsedTime = this.getSystemClock().now() - beginTime;
            if (elapsedTime > 500) {
                log.warn("putMessage not in lock elapsed time(ms)={}, bodyLength={}", elapsedTime, msg.getBody().length);
            }
            this.storeStatsService.setPutMessageEntireTimeMax(elapsedTime);

            if (null == result || !result.isOk()) {
                this.storeStatsService.getPutMessageFailedTimes().incrementAndGet();
            }
        });

        return putResultFuture;
    }
    // 写入消息数据到commitLog中
    // org.apache.rocketmq.store.CommitLog#asyncPutMessage
    public CompletableFuture<PutMessageResult> asyncPutMessage(final MessageExtBrokerInner msg) {
        // Set the storage time
        msg.setStoreTimestamp(System.currentTimeMillis());
        // Set the message body BODY CRC (consider the most appropriate setting
        // on the client)
        msg.setBodyCRC(UtilAll.crc32(msg.getBody()));
        // Back to Results
        AppendMessageResult result = null;

        StoreStatsService storeStatsService = this.defaultMessageStore.getStoreStatsService();

        String topic = msg.getTopic();
        int queueId = msg.getQueueId();

        final int tranType = MessageSysFlag.getTransactionValue(msg.getSysFlag());
        if (tranType == MessageSysFlag.TRANSACTION_NOT_TYPE
                || tranType == MessageSysFlag.TRANSACTION_COMMIT_TYPE) {
            // Delay Delivery
            if (msg.getDelayTimeLevel() > 0) {
                if (msg.getDelayTimeLevel() > this.defaultMessageStore.getScheduleMessageService().getMaxDelayLevel()) {
                    msg.setDelayTimeLevel(this.defaultMessageStore.getScheduleMessageService().getMaxDelayLevel());
                }

                topic = TopicValidator.RMQ_SYS_SCHEDULE_TOPIC;
                queueId = ScheduleMessageService.delayLevel2QueueId(msg.getDelayTimeLevel());

                // Backup real topic, queueId
                MessageAccessor.putProperty(msg, MessageConst.PROPERTY_REAL_TOPIC, msg.getTopic());
                MessageAccessor.putProperty(msg, MessageConst.PROPERTY_REAL_QUEUE_ID, String.valueOf(msg.getQueueId()));
                msg.setPropertiesString(MessageDecoder.messageProperties2String(msg.getProperties()));

                msg.setTopic(topic);
                msg.setQueueId(queueId);
            }
        }

        long elapsedTimeInLock = 0;
        // 获取mappedFile实例，后续将向其写入数据
        MappedFile unlockMappedFile = null;
        MappedFile mappedFile = this.mappedFileQueue.getLastMappedFile();
        // 上锁写数据，保证数据写入安全准确
        putMessageLock.lock(); //spin or ReentrantLock ,depending on store config
        try {
            long beginLockTimestamp = this.defaultMessageStore.getSystemClock().now();
            this.beginTimeInLock = beginLockTimestamp;

            // Here settings are stored timestamp, in order to ensure an orderly
            // global
            msg.setStoreTimestamp(beginLockTimestamp);
            // 确保mappedFile有效
            if (null == mappedFile || mappedFile.isFull()) {
                mappedFile = this.mappedFileQueue.getLastMappedFile(0); // Mark: NewFile may be cause noise
            }
            if (null == mappedFile) {
                log.error("create mapped file1 error, topic: " + msg.getTopic() + " clientAddr: " + msg.getBornHostString());
                beginTimeInLock = 0;
                return CompletableFuture.completedFuture(new PutMessageResult(PutMessageStatus.CREATE_MAPEDFILE_FAILED, null));
            }
            // 向mappedFile中追加数据，完成写入动作
            result = mappedFile.appendMessage(msg, this.appendMessageCallback);
            switch (result.getStatus()) {
                case PUT_OK:
                    break;
                case END_OF_FILE:
                    unlockMappedFile = mappedFile;
                    // Create a new file, re-write the message
                    mappedFile = this.mappedFileQueue.getLastMappedFile(0);
                    if (null == mappedFile) {
                        // XXX: warn and notify me
                        log.error("create mapped file2 error, topic: " + msg.getTopic() + " clientAddr: " + msg.getBornHostString());
                        beginTimeInLock = 0;
                        return CompletableFuture.completedFuture(new PutMessageResult(PutMessageStatus.CREATE_MAPEDFILE_FAILED, result));
                    }
                    result = mappedFile.appendMessage(msg, this.appendMessageCallback);
                    break;
                case MESSAGE_SIZE_EXCEEDED:
                case PROPERTIES_SIZE_EXCEEDED:
                    beginTimeInLock = 0;
                    return CompletableFuture.completedFuture(new PutMessageResult(PutMessageStatus.MESSAGE_ILLEGAL, result));
                case UNKNOWN_ERROR:
                    beginTimeInLock = 0;
                    return CompletableFuture.completedFuture(new PutMessageResult(PutMessageStatus.UNKNOWN_ERROR, result));
                default:
                    beginTimeInLock = 0;
                    return CompletableFuture.completedFuture(new PutMessageResult(PutMessageStatus.UNKNOWN_ERROR, result));
            }

            elapsedTimeInLock = this.defaultMessageStore.getSystemClock().now() - beginLockTimestamp;
            beginTimeInLock = 0;
        } finally {
            putMessageLock.unlock();
        }

        if (elapsedTimeInLock > 500) {
            log.warn("[NOTIFYME]putMessage in lock cost time(ms)={}, bodyLength={} AppendMessageResult={}", elapsedTimeInLock, msg.getBody().length, result);
        }

        if (null != unlockMappedFile && this.defaultMessageStore.getMessageStoreConfig().isWarmMapedFileEnable()) {
            this.defaultMessageStore.unlockMappedFile(unlockMappedFile);
        }

        PutMessageResult putMessageResult = new PutMessageResult(PutMessageStatus.PUT_OK, result);

        // Statistics
        storeStatsService.getSinglePutMessageTopicTimesTotal(msg.getTopic()).incrementAndGet();
        storeStatsService.getSinglePutMessageTopicSizeTotal(topic).addAndGet(result.getWroteBytes());

        CompletableFuture<PutMessageStatus> flushResultFuture = submitFlushRequest(result, putMessageResult, msg);
        CompletableFuture<PutMessageStatus> replicaResultFuture = submitReplicaRequest(result, putMessageResult, msg);
        return flushResultFuture.thenCombine(replicaResultFuture, (flushStatus, replicaStatus) -> {
            if (flushStatus != PutMessageStatus.PUT_OK) {
                putMessageResult.setPutMessageStatus(PutMessageStatus.FLUSH_DISK_TIMEOUT);
            }
            if (replicaStatus != PutMessageStatus.PUT_OK) {
                putMessageResult.setPutMessageStatus(replicaStatus);
            }
            return putMessageResult;
        });
    }
    
    // 获取有效的mappedFile实例
    // org.apache.rocketmq.store.MappedFileQueue#getLastMappedFile()
    public MappedFile getLastMappedFile() {
        MappedFile mappedFileLast = null;

        while (!this.mappedFiles.isEmpty()) {
            try {
                mappedFileLast = this.mappedFiles.get(this.mappedFiles.size() - 1);
                break;
            } catch (IndexOutOfBoundsException e) {
                //continue;
            } catch (Exception e) {
                log.error("getLastMappedFile has exception.", e);
                break;
            }
        }

        return mappedFileLast;
    }
    // 再次尝试获取 mappedFile, 没有则创建一个新的
    // org.apache.rocketmq.store.MappedFileQueue#getLastMappedFile(long)
    public MappedFile getLastMappedFile(final long startOffset) {
        return getLastMappedFile(startOffset, true);
    }
    public MappedFile getLastMappedFile(final long startOffset, boolean needCreate) {
        long createOffset = -1;
        MappedFile mappedFileLast = getLastMappedFile();

        if (mappedFileLast == null) {
            createOffset = startOffset - (startOffset % this.mappedFileSize);
        }

        if (mappedFileLast != null && mappedFileLast.isFull()) {
            createOffset = mappedFileLast.getFileFromOffset() + this.mappedFileSize;
        }

        if (createOffset != -1 && needCreate) {
            String nextFilePath = this.storePath + File.separator + UtilAll.offset2FileName(createOffset);
            String nextNextFilePath = this.storePath + File.separator
                + UtilAll.offset2FileName(createOffset + this.mappedFileSize);
            MappedFile mappedFile = null;
            // 分配创建一个新的commitLog文件
            if (this.allocateMappedFileService != null) {
                mappedFile = this.allocateMappedFileService.putRequestAndReturnMappedFile(nextFilePath,
                    nextNextFilePath, this.mappedFileSize);
            } else {
                try {
                    mappedFile = new MappedFile(nextFilePath, this.mappedFileSize);
                } catch (IOException e) {
                    log.error("create mappedFile exception", e);
                }
            }

            if (mappedFile != null) {
                if (this.mappedFiles.isEmpty()) {
                    mappedFile.setFirstCreateInQueue(true);
                }
                this.mappedFiles.add(mappedFile);
            }

            return mappedFile;
        }

        return mappedFileLast;
    }

    // 向commitLog中得到的mappedFile顺序写入数据
    public AppendMessageResult appendMessage(final MessageExtBrokerInner msg, final AppendMessageCallback cb) {
        return appendMessagesInner(msg, cb);
    }
    public AppendMessageResult appendMessagesInner(final MessageExt messageExt, final AppendMessageCallback cb) {
        assert messageExt != null;
        assert cb != null;

        int currentPos = this.wrotePosition.get();

        if (currentPos < this.fileSize) {
            ByteBuffer byteBuffer = writeBuffer != null ? writeBuffer.slice() : this.mappedByteBuffer.slice();
            byteBuffer.position(currentPos);
            AppendMessageResult result;
            if (messageExt instanceof MessageExtBrokerInner) {
                // 回调，写入数据到 commitLog 中
                // 将数据写入 byteBuffer, 即将数据写入了pagecache, 也就写入了磁盘文件中了
                result = cb.doAppend(this.getFileFromOffset(), byteBuffer, this.fileSize - currentPos, (MessageExtBrokerInner) messageExt);
            } else if (messageExt instanceof MessageExtBatch) {
                result = cb.doAppend(this.getFileFromOffset(), byteBuffer, this.fileSize - currentPos, (MessageExtBatch) messageExt);
            } else {
                return new AppendMessageResult(AppendMessageStatus.UNKNOWN_ERROR);
            }
            this.wrotePosition.addAndGet(result.getWroteBytes());
            this.storeTimestamp = result.getStoreTimestamp();
            return result;
        }
        log.error("MappedFile.appendMessage return null, wrotePosition: {} fileSize: {}", currentPos, this.fileSize);
        return new AppendMessageResult(AppendMessageStatus.UNKNOWN_ERROR);
    }
        // org.apache.rocketmq.store.CommitLog.DefaultAppendMessageCallback#doAppend(long, java.nio.ByteBuffer, int, org.apache.rocketmq.store.MessageExtBrokerInner)
        public AppendMessageResult doAppend(final long fileFromOffset, final ByteBuffer byteBuffer, final int maxBlank,
            final MessageExtBrokerInner msgInner) {
            // STORETIMESTAMP + STOREHOSTADDRESS + OFFSET <br>

            // PHY OFFSET
            long wroteOffset = fileFromOffset + byteBuffer.position();

            int sysflag = msgInner.getSysFlag();

            int bornHostLength = (sysflag & MessageSysFlag.BORNHOST_V6_FLAG) == 0 ? 4 + 4 : 16 + 4;
            int storeHostLength = (sysflag & MessageSysFlag.STOREHOSTADDRESS_V6_FLAG) == 0 ? 4 + 4 : 16 + 4;
            ByteBuffer bornHostHolder = ByteBuffer.allocate(bornHostLength);
            ByteBuffer storeHostHolder = ByteBuffer.allocate(storeHostLength);

            this.resetByteBuffer(storeHostHolder, storeHostLength);
            String msgId;
            if ((sysflag & MessageSysFlag.STOREHOSTADDRESS_V6_FLAG) == 0) {
                msgId = MessageDecoder.createMessageId(this.msgIdMemory, msgInner.getStoreHostBytes(storeHostHolder), wroteOffset);
            } else {
                msgId = MessageDecoder.createMessageId(this.msgIdV6Memory, msgInner.getStoreHostBytes(storeHostHolder), wroteOffset);
            }

            // Record ConsumeQueue information
            keyBuilder.setLength(0);
            keyBuilder.append(msgInner.getTopic());
            keyBuilder.append('-');
            keyBuilder.append(msgInner.getQueueId());
            String key = keyBuilder.toString();
            Long queueOffset = CommitLog.this.topicQueueTable.get(key);
            // 初始化queueId信息
            if (null == queueOffset) {
                queueOffset = 0L;
                CommitLog.this.topicQueueTable.put(key, queueOffset);
            }

            // Transaction messages that require special handling
            final int tranType = MessageSysFlag.getTransactionValue(msgInner.getSysFlag());
            switch (tranType) {
                // Prepared and Rollback message is not consumed, will not enter the
                // consumer queuec
                case MessageSysFlag.TRANSACTION_PREPARED_TYPE:
                case MessageSysFlag.TRANSACTION_ROLLBACK_TYPE:
                    queueOffset = 0L;
                    break;
                case MessageSysFlag.TRANSACTION_NOT_TYPE:
                case MessageSysFlag.TRANSACTION_COMMIT_TYPE:
                default:
                    break;
            }

            /**
             * Serialize message
             */
            final byte[] propertiesData =
                msgInner.getPropertiesString() == null ? null : msgInner.getPropertiesString().getBytes(MessageDecoder.CHARSET_UTF8);

            final int propertiesLength = propertiesData == null ? 0 : propertiesData.length;

            if (propertiesLength > Short.MAX_VALUE) {
                log.warn("putMessage message properties length too long. length={}", propertiesData.length);
                return new AppendMessageResult(AppendMessageStatus.PROPERTIES_SIZE_EXCEEDED);
            }

            final byte[] topicData = msgInner.getTopic().getBytes(MessageDecoder.CHARSET_UTF8);
            final int topicLength = topicData.length;

            final int bodyLength = msgInner.getBody() == null ? 0 : msgInner.getBody().length;

            final int msgLen = calMsgLength(msgInner.getSysFlag(), bodyLength, topicLength, propertiesLength);

            // Exceeds the maximum message
            if (msgLen > this.maxMessageSize) {
                CommitLog.log.warn("message size exceeded, msg total size: " + msgLen + ", msg body size: " + bodyLength
                    + ", maxMessageSize: " + this.maxMessageSize);
                return new AppendMessageResult(AppendMessageStatus.MESSAGE_SIZE_EXCEEDED);
            }

            // Determines whether there is sufficient free space
            if ((msgLen + END_FILE_MIN_BLANK_LENGTH) > maxBlank) {
                this.resetByteBuffer(this.msgStoreItemMemory, maxBlank);
                // 1 TOTALSIZE
                this.msgStoreItemMemory.putInt(maxBlank);
                // 2 MAGICCODE
                this.msgStoreItemMemory.putInt(CommitLog.BLANK_MAGIC_CODE);
                // 3 The remaining space may be any value
                // Here the length of the specially set maxBlank
                final long beginTimeMills = CommitLog.this.defaultMessageStore.now();
                byteBuffer.put(this.msgStoreItemMemory.array(), 0, maxBlank);
                return new AppendMessageResult(AppendMessageStatus.END_OF_FILE, wroteOffset, maxBlank, msgId, msgInner.getStoreTimestamp(),
                    queueOffset, CommitLog.this.defaultMessageStore.now() - beginTimeMills);
            }
            // 序列化写入数据，写header... body...
            // Initialization of storage space
            this.resetByteBuffer(msgStoreItemMemory, msgLen);
            // 1 TOTALSIZE
            this.msgStoreItemMemory.putInt(msgLen);
            // 2 MAGICCODE
            this.msgStoreItemMemory.putInt(CommitLog.MESSAGE_MAGIC_CODE);
            // 3 BODYCRC
            this.msgStoreItemMemory.putInt(msgInner.getBodyCRC());
            // 4 QUEUEID
            this.msgStoreItemMemory.putInt(msgInner.getQueueId());
            // 5 FLAG
            this.msgStoreItemMemory.putInt(msgInner.getFlag());
            // 6 QUEUEOFFSET
            this.msgStoreItemMemory.putLong(queueOffset);
            // 7 PHYSICALOFFSET
            this.msgStoreItemMemory.putLong(fileFromOffset + byteBuffer.position());
            // 8 SYSFLAG
            this.msgStoreItemMemory.putInt(msgInner.getSysFlag());
            // 9 BORNTIMESTAMP
            this.msgStoreItemMemory.putLong(msgInner.getBornTimestamp());
            // 10 BORNHOST
            this.resetByteBuffer(bornHostHolder, bornHostLength);
            this.msgStoreItemMemory.put(msgInner.getBornHostBytes(bornHostHolder));
            // 11 STORETIMESTAMP
            this.msgStoreItemMemory.putLong(msgInner.getStoreTimestamp());
            // 12 STOREHOSTADDRESS
            this.resetByteBuffer(storeHostHolder, storeHostLength);
            this.msgStoreItemMemory.put(msgInner.getStoreHostBytes(storeHostHolder));
            // 13 RECONSUMETIMES
            this.msgStoreItemMemory.putInt(msgInner.getReconsumeTimes());
            // 14 Prepared Transaction Offset
            this.msgStoreItemMemory.putLong(msgInner.getPreparedTransactionOffset());
            // 15 BODY
            this.msgStoreItemMemory.putInt(bodyLength);
            if (bodyLength > 0)
            this.msgStoreItemMemory.put(msgInner.getBody());
            // 16 TOPIC
            this.msgStoreItemMemory.put((byte) topicLength);
            this.msgStoreItemMemory.put(topicData);
            // 17 PROPERTIES
            this.msgStoreItemMemory.putShort((short) propertiesLength);
            if (propertiesLength > 0)
                this.msgStoreItemMemory.put(propertiesData);

            final long beginTimeMills = CommitLog.this.defaultMessageStore.now();
            // Write messages to the queue buffer
            // 将数据写入 ByteBuffer 中，
            byteBuffer.put(this.msgStoreItemMemory.array(), 0, msgLen);

            AppendMessageResult result = new AppendMessageResult(AppendMessageStatus.PUT_OK, wroteOffset, msgLen, msgId,
                msgInner.getStoreTimestamp(), queueOffset, CommitLog.this.defaultMessageStore.now() - beginTimeMills);

            switch (tranType) {
                case MessageSysFlag.TRANSACTION_PREPARED_TYPE:
                case MessageSysFlag.TRANSACTION_ROLLBACK_TYPE:
                    break;
                case MessageSysFlag.TRANSACTION_NOT_TYPE:
                case MessageSysFlag.TRANSACTION_COMMIT_TYPE:
                    // The next update ConsumeQueue information
                    CommitLog.this.topicQueueTable.put(key, ++queueOffset);
                    break;
                default:
                    break;
            }
            return result;
        }
```

[![复制代码](RocketMQ(七)：高性能探秘之MappedFile.assets/copycode.gif)](javascript:void(0);)

   以上过程看似复杂，实则只有最后一个bytebuffer.putXxx() 是真正的和mappedFile 是相关的。当然了，还有MappedFile的初始过程，它会先尝试从现有打开的mappFiles中获取最后一个实例，如果mappedFile满了之后，就会尝试创建一个新的mappedFile,  这个过程一般伴随着新的commitLog文件的创建。

　　mappedFile 的刷盘动作，主要分为同步刷盘和异步刷，底层都是一样的，即调用 flush(),MappedFileChannel.force(),  将pagecache强制刷入到磁盘上。一般地，将数据写入pagecache，基本就能保证不丢失了。但还是有例外情况，比如机器掉电，或者系统bug这种极端情况，还是会导致丢数据哟。

   下面大致来看看 mappedFile 同步刷盘过程：

[![复制代码](RocketMQ(七)：高性能探秘之MappedFile.assets/copycode.gif)](javascript:void(0);)

```
    // org.apache.rocketmq.store.CommitLog#handleDiskFlush
    public void handleDiskFlush(AppendMessageResult result, PutMessageResult putMessageResult, MessageExt messageExt) {
        // Synchronization flush
        // 同步刷盘
        if (FlushDiskType.SYNC_FLUSH == this.defaultMessageStore.getMessageStoreConfig().getFlushDiskType()) {
            final GroupCommitService service = (GroupCommitService) this.flushCommitLogService;
            if (messageExt.isWaitStoreMsgOK()) {
                // 提交一个刷盘任务到 GroupCommitService, 同步等待结果响应
                GroupCommitRequest request = new GroupCommitRequest(result.getWroteOffset() + result.getWroteBytes());
                service.putRequest(request);
                CompletableFuture<PutMessageStatus> flushOkFuture = request.future();
                PutMessageStatus flushStatus = null;
                try {
                    flushStatus = flushOkFuture.get(this.defaultMessageStore.getMessageStoreConfig().getSyncFlushTimeout(),
                            TimeUnit.MILLISECONDS);
                } catch (InterruptedException | ExecutionException | TimeoutException e) {
                    //flushOK=false;
                }
                if (flushStatus != PutMessageStatus.PUT_OK) {
                    log.error("do groupcommit, wait for flush failed, topic: " + messageExt.getTopic() + " tags: " + messageExt.getTags()
                        + " client address: " + messageExt.getBornHostString());
                    putMessageResult.setPutMessageStatus(PutMessageStatus.FLUSH_DISK_TIMEOUT);
                }
            } else {
                service.wakeup();
            }
        }
        // Asynchronous flush
        // 异步刷盘
        else {
            // 异步刷盘则直接唤醒一个刷盘线程即可
            if (!this.defaultMessageStore.getMessageStoreConfig().isTransientStorePoolEnable()) {
                flushCommitLogService.wakeup();
            } else {
                commitLogService.wakeup();
            }
        }
    }
        // org.apache.rocketmq.store.CommitLog.GroupCommitService#putRequest
        // 添加刷盘请求
        public synchronized void putRequest(final GroupCommitRequest request) {
            synchronized (this.requestsWrite) {
                this.requestsWrite.add(request);
            }
            this.wakeup();
        }
        // 刷盘线程一直运行
        public void run() {
            CommitLog.log.info(this.getServiceName() + " service started");

            while (!this.isStopped()) {
                try {
                    this.waitForRunning(10);
                    // 运行真正的刷动作
                    this.doCommit();
                } catch (Exception e) {
                    CommitLog.log.warn(this.getServiceName() + " service has exception. ", e);
                }
            }

            // Under normal circumstances shutdown, wait for the arrival of the
            // request, and then flush
            try {
                Thread.sleep(10);
            } catch (InterruptedException e) {
                CommitLog.log.warn("GroupCommitService Exception, ", e);
            }

            synchronized (this) {
                this.swapRequests();
            }

            this.doCommit();

            CommitLog.log.info(this.getServiceName() + " service end");
        }

        private void doCommit() {
            synchronized (this.requestsRead) {
                if (!this.requestsRead.isEmpty()) {
                    for (GroupCommitRequest req : this.requestsRead) {
                        // There may be a message in the next file, so a maximum of
                        // two times the flush
                        boolean flushOK = false;
                        for (int i = 0; i < 2 && !flushOK; i++) {
                            flushOK = CommitLog.this.mappedFileQueue.getFlushedWhere() >= req.getNextOffset();

                            if (!flushOK) {
                                // 刷盘实现
                                CommitLog.this.mappedFileQueue.flush(0);
                            }
                        }

                        req.wakeupCustomer(flushOK ? PutMessageStatus.PUT_OK : PutMessageStatus.FLUSH_DISK_TIMEOUT);
                    }

                    long storeTimestamp = CommitLog.this.mappedFileQueue.getStoreTimestamp();
                    if (storeTimestamp > 0) {
                        CommitLog.this.defaultMessageStore.getStoreCheckpoint().setPhysicMsgTimestamp(storeTimestamp);
                    }

                    this.requestsRead.clear();
                } else {
                    // Because of individual messages is set to not sync flush, it
                    // will come to this process
                    CommitLog.this.mappedFileQueue.flush(0);
                }
            }
        }

    // org.apache.rocketmq.store.MappedFileQueue#flush
    public boolean flush(final int flushLeastPages) {
        boolean result = true;
        MappedFile mappedFile = this.findMappedFileByOffset(this.flushedWhere, this.flushedWhere == 0);
        if (mappedFile != null) {
            long tmpTimeStamp = mappedFile.getStoreTimestamp();
            int offset = mappedFile.flush(flushLeastPages);
            long where = mappedFile.getFileFromOffset() + offset;
            result = where == this.flushedWhere;
            this.flushedWhere = where;
            if (0 == flushLeastPages) {
                this.storeTimestamp = tmpTimeStamp;
            }
        }

        return result;
    }
    // org.apache.rocketmq.store.MappedFile#flush
    /**
     * @return The current flushed position
     */
    public int flush(final int flushLeastPages) {
        if (this.isAbleToFlush(flushLeastPages)) {
            if (this.hold()) {
                int value = getReadPosition();

                try {
                    //We only append data to fileChannel or mappedByteBuffer, never both.
                    if (writeBuffer != null || this.fileChannel.position() != 0) {
                        this.fileChannel.force(false);
                    } else {
                        this.mappedByteBuffer.force();
                    }
                } catch (Throwable e) {
                    log.error("Error occurred when force data to disk.", e);
                }

                this.flushedPosition.set(value);
                this.release();
            } else {
                log.warn("in flush, hold failed, flush offset = " + this.flushedPosition.get());
                this.flushedPosition.set(getReadPosition());
            }
        }
        return this.getFlushedPosition();
    }
```

[![复制代码](RocketMQ(七)：高性能探秘之MappedFile.assets/copycode.gif)](javascript:void(0);)

　　最后，来看看mappedFile 的创建和预热过程如何：

[![复制代码](RocketMQ(七)：高性能探秘之MappedFile.assets/copycode.gif)](javascript:void(0);)

```
public MappedFile putRequestAndReturnMappedFile(String nextFilePath, String nextNextFilePath, int fileSize) {
      int canSubmitRequests = 2;
      if (this.messageStore.getMessageStoreConfig().isTransientStorePoolEnable()) {
        if (this.messageStore.getMessageStoreConfig().isFastFailIfNoBufferInStorePool()
            && BrokerRole.SLAVE != this.messageStore.getMessageStoreConfig().getBrokerRole()) { //if broker is slave, don't fast fail even no buffer in pool
            canSubmitRequests = this.messageStore.getTransientStorePool().availableBufferNums() - this.requestQueue.size();
        }
      }

      AllocateRequest nextReq = new AllocateRequest(nextFilePath, fileSize);
      boolean nextPutOK = this.requestTable.putIfAbsent(nextFilePath, nextReq) == null;

      if (nextPutOK) {
        if (canSubmitRequests <= 0) {
            log.warn("[NOTIFYME]TransientStorePool is not enough, so create mapped file error, " +
              "RequestQueueSize : {}, StorePoolSize: {}", this.requestQueue.size(), this.messageStore.getTransientStorePool().availableBufferNums());
            this.requestTable.remove(nextFilePath);
            return null;
        }
        boolean offerOK = this.requestQueue.offer(nextReq);
        if (!offerOK) {
            log.warn("never expected here, add a request to preallocate queue failed");
        }
        canSubmitRequests--;
      }

      AllocateRequest nextNextReq = new AllocateRequest(nextNextFilePath, fileSize);
      // 放入请求表中，会有任务处理
      boolean nextNextPutOK = this.requestTable.putIfAbsent(nextNextFilePath, nextNextReq) == null;
      if (nextNextPutOK) {
        if (canSubmitRequests <= 0) {
            log.warn("[NOTIFYME]TransientStorePool is not enough, so skip preallocate mapped file, " +
              "RequestQueueSize : {}, StorePoolSize: {}", this.requestQueue.size(), this.messageStore.getTransientStorePool().availableBufferNums());
            this.requestTable.remove(nextNextFilePath);
        } else {
            // 放入mmap处理队列，后台任务开始处理
            boolean offerOK = this.requestQueue.offer(nextNextReq);
            if (!offerOK) {
              log.warn("never expected here, add a request to preallocate queue failed");
            }
        }
      }

      if (hasException) {
        log.warn(this.getServiceName() + " service has exception. so return null");
        return null;
      }

      AllocateRequest result = this.requestTable.get(nextFilePath);
      try {
        if (result != null) {
            // 同步等待mmap请求处理完成
            boolean waitOK = result.getCountDownLatch().await(waitTimeOut, TimeUnit.MILLISECONDS);
            if (!waitOK) {
              log.warn("create mmap timeout " + result.getFilePath() + " " + result.getFileSize());
              return null;
            } else {
              this.requestTable.remove(nextFilePath);
              return result.getMappedFile();
            }
        } else {
            log.error("find preallocate mmap failed, this never happen");
        }
      } catch (InterruptedException e) {
        log.warn(this.getServiceName() + " service has exception. ", e);
      }

      return null;
    }
    
    // 任务只干一件事，处理调用mmapOperation
    public void run() {
      log.info(this.getServiceName() + " service started");

      while (!this.isStopped() && this.mmapOperation()) {

      }
      log.info(this.getServiceName() + " service end");
    }
    
    /**
     * Only interrupted by the external thread, will return false
     */
    private boolean mmapOperation() {
      boolean isSuccess = false;
      AllocateRequest req = null;
      try {
        req = this.requestQueue.take();
        AllocateRequest expectedRequest = this.requestTable.get(req.getFilePath());
        if (null == expectedRequest) {
            log.warn("this mmap request expired, maybe cause timeout " + req.getFilePath() + " "
              + req.getFileSize());
            return true;
        }
        if (expectedRequest != req) {
            log.warn("never expected here,  maybe cause timeout " + req.getFilePath() + " "
              + req.getFileSize() + ", req:" + req + ", expectedRequest:" + expectedRequest);
            return true;
        }

        if (req.getMappedFile() == null) {
            long beginTime = System.currentTimeMillis();

            MappedFile mappedFile;
            if (messageStore.getMessageStoreConfig().isTransientStorePoolEnable()) {
              try {
                mappedFile = ServiceLoader.load(MappedFile.class).iterator().next();
                // 初始化 mappedFile,实际就是创建commitLog文件
                mappedFile.init(req.getFilePath(), req.getFileSize(), messageStore.getTransientStorePool());
              } catch (RuntimeException e) {
                log.warn("Use default implementation.");
                mappedFile = new MappedFile(req.getFilePath(), req.getFileSize(), messageStore.getTransientStorePool());
              }
            } else {
              mappedFile = new MappedFile(req.getFilePath(), req.getFileSize());
            }

            long elapsedTime = UtilAll.computeElapsedTimeMilliseconds(beginTime);
            if (elapsedTime > 10) {
              int queueSize = this.requestQueue.size();
              log.warn("create mappedFile spent time(ms) " + elapsedTime + " queue size " + queueSize
                + " " + req.getFilePath() + " " + req.getFileSize());
            }

            // pre write mappedFile
            if (mappedFile.getFileSize() >= this.messageStore.getMessageStoreConfig()
              .getMappedFileSizeCommitLog()
              &&
              this.messageStore.getMessageStoreConfig().isWarmMapedFileEnable()) {
              mappedFile.warmMappedFile(this.messageStore.getMessageStoreConfig().getFlushDiskType(),
                this.messageStore.getMessageStoreConfig().getFlushLeastPagesWhenWarmMapedFile());
            }

            req.setMappedFile(mappedFile);
            this.hasException = false;
            isSuccess = true;
        }
      } catch (InterruptedException e) {
        log.warn(this.getServiceName() + " interrupted, possibly by shutdown.");
        this.hasException = true;
        return false;
      } catch (IOException e) {
        log.warn(this.getServiceName() + " service has exception. ", e);
        this.hasException = true;
        if (null != req) {
            requestQueue.offer(req);
            try {
              Thread.sleep(1);
            } catch (InterruptedException ignored) {
            }
        }
      } finally {
        if (req != null && isSuccess)
            req.getCountDownLatch().countDown();
      }
      return true;
    }
    
    // store.MappedFile.init()
    public void init(final String fileName, final int fileSize,
      final TransientStorePool transientStorePool) throws IOException {
      init(fileName, fileSize);
      this.writeBuffer = transientStorePool.borrowBuffer();
      this.transientStorePool = transientStorePool;
    }
    private void init(final String fileName, final int fileSize) throws IOException {
      this.fileName = fileName;
      this.fileSize = fileSize;
      this.file = new File(fileName);
      this.fileFromOffset = Long.parseLong(this.file.getName());
      boolean ok = false;

      ensureDirOK(this.file.getParent());

      try {
        // 最核心的创建mmap的地方
        // 创建 fileChannel
        // 创建 mappedByteBuffer, 后续直接使用
        this.fileChannel = new RandomAccessFile(this.file, "rw").getChannel();
        this.mappedByteBuffer = this.fileChannel.map(MapMode.READ_WRITE, 0, fileSize);
        TOTAL_MAPPED_VIRTUAL_MEMORY.addAndGet(fileSize);
        TOTAL_MAPPED_FILES.incrementAndGet();
        ok = true;
      } catch (FileNotFoundException e) {
        log.error("Failed to create file " + this.fileName, e);
        throw e;
      } catch (IOException e) {
        log.error("Failed to map file " + this.fileName, e);
        throw e;
      } finally {
        if (!ok && this.fileChannel != null) {
            this.fileChannel.close();
        }
      }
    }
```

[![复制代码](RocketMQ(七)：高性能探秘之MappedFile.assets/copycode.gif)](javascript:void(0);)

　　mappedFile 预热：

[![复制代码](RocketMQ(七)：高性能探秘之MappedFile.assets/copycode.gif)](javascript:void(0);)

```
// org.apache.rocketmq.store.MappedFile#warmMappedFile
    public void warmMappedFile(FlushDiskType type, int pages) {
        long beginTime = System.currentTimeMillis();
        ByteBuffer byteBuffer = this.mappedByteBuffer.slice();
        int flush = 0;
        long time = System.currentTimeMillis();
        for (int i = 0, j = 0; i < this.fileSize; i += MappedFile.OS_PAGE_SIZE, j++) {
            byteBuffer.put(i, (byte) 0);
            // force flush when flush disk type is sync
            if (type == FlushDiskType.SYNC_FLUSH) {
                if ((i / OS_PAGE_SIZE) - (flush / OS_PAGE_SIZE) >= pages) {
                    flush = i;
                    mappedByteBuffer.force();
                }
            }

            // prevent gc
            if (j % 1000 == 0) {
                log.info("j={}, costTime={}", j, System.currentTimeMillis() - time);
                time = System.currentTimeMillis();
                try {
                    Thread.sleep(0);
                } catch (InterruptedException e) {
                    log.error("Interrupted", e);
                }
            }
        }

        // force flush when prepare load finished
        if (type == FlushDiskType.SYNC_FLUSH) {
            log.info("mapped file warm-up done, force to disk, mappedFile={}, costTime={}",
                this.getFileName(), System.currentTimeMillis() - beginTime);
            mappedByteBuffer.force();
        }
        log.info("mapped file warm-up done. mappedFile={}, costTime={}", this.getFileName(),
            System.currentTimeMillis() - beginTime);

        this.mlock();
    }
```

[![复制代码](RocketMQ(七)：高性能探秘之MappedFile.assets/copycode.gif)](javascript:void(0);)

　　如此，整个rocketmq对mappedfile的使用过程就厘清了。

[返回顶部](https://www.cnblogs.com/yougewe/p/14164651.html#_labelTop)

### 5. mappedFile压测性能几何

　　到底使用mappedFile 之后，性能提升了多少呢？以便衡量收益如何。使用jmh 压测下。

[![复制代码](RocketMQ(七)：高性能探秘之MappedFile.assets/copycode.gif)](javascript:void(0);)

```
@State(Scope.Benchmark)
public class MmapFileBenchmarkTest {

    public static void main(String[] args) throws RunnerException {
        Options opt = new OptionsBuilder()
                .include(MmapFileBenchmarkTest.class.getSimpleName())
//                .include(BenchMarkUsage.class.getSimpleName()+".*measureThroughput*")
                // 预热3轮
                .warmupIterations(3)
                // 度量5轮
                .measurementIterations(5)
                .forks(1)
                .build();
        new Runner(opt).run();
    }

    private FileChannel fileChannel;

    private MappedByteBuffer mappedByteBuffer;

    private OutputStream outputStream;

    private int maxWriteLines = 100_0000;

    private int fileSize = 102400000;

    @Setup
    @Before
    public void setup() throws IOException {
        File file1 = new File("/tmp/t_mappedFileTest.txt");
        this.fileChannel = new RandomAccessFile(file1, "rw").getChannel();
        this.mappedByteBuffer = this.fileChannel.map(FileChannel.MapMode.READ_WRITE,
                            0, 1024000000);
        // 忽略预热
//        warmMappedFile();
        outputStream = FileUtils.openOutputStream(new File("/tmp/t_normalFileTest.txt"));

    }
    private void warmMappedFile() {
        long beginTime = System.currentTimeMillis();
        ByteBuffer byteBuffer = this.mappedByteBuffer.slice();
        int flush = 0;
        long time = System.currentTimeMillis();
        for (int i = 0, j = 0; i < this.fileSize; i += 4096, j++) {
            byteBuffer.put(i, (byte) 0);

            // prevent gc
            if (j % 1000 == 0) {
                logInfo("j=%s, costTime=%d", j, System.currentTimeMillis() - time);
                time = System.currentTimeMillis();
                try {
                    Thread.sleep(0);
                } catch (InterruptedException e) {
                    logInfo("Interrupted, %s", e);
                }
            }
        }
        // force flush when prepare load finished
        mappedByteBuffer.force();
//        this.mlock();
    }
    private void logInfo(String message, Object... args) {
        System.out.println(String.format(message, args));
    }

    @Benchmark
    @BenchmarkMode(Mode.Throughput)
    @OutputTimeUnit(TimeUnit.SECONDS)
    @Test
    public void testAppendMappedFile() throws IOException {
        for (int i = 0; i < maxWriteLines; i++ ) {
            mappedByteBuffer.put("abc1234567\n".getBytes());
        }
        mappedByteBuffer.flip();
    }

    @Benchmark
    @BenchmarkMode(Mode.Throughput)
    @OutputTimeUnit(TimeUnit.SECONDS)
    @Test
    public void testAppendNormalFile() throws IOException {
        for (int i = 0; i < maxWriteLines; i++ ) {
            outputStream.write("abc1234567\n".getBytes());
        }
        outputStream.flush();
    }

}
```

[![复制代码](RocketMQ(七)：高性能探秘之MappedFile.assets/copycode.gif)](javascript:void(0);)

　　测试结果如下：

[![复制代码](RocketMQ(七)：高性能探秘之MappedFile.assets/copycode.gif)](javascript:void(0);)

```
# Run progress: 0.00% complete, ETA 00:00:16
# Fork: 1 of 1
# Warmup Iteration   1: 14.808 ops/s
# Warmup Iteration   2: 16.170 ops/s
# Warmup Iteration   3: 18.633 ops/s
Iteration   1: 15.692 ops/s
Iteration   2: 17.273 ops/s
Iteration   3: 18.145 ops/s
Iteration   4: 18.356 ops/s
Iteration   5: 18.868 ops/s


Result "MmapFileBenchmarkTest.testAppendMappedFile":
  17.667 ±(99.9%) 4.795 ops/s [Average]
  (min, avg, max) = (15.692, 17.667, 18.868), stdev = 1.245
  CI (99.9%): [12.871, 22.462] (assumes normal distribution)


# JMH version: 1.19
# VM version: JDK 1.8.0_121, VM 25.121-b13
# Warmup: 3 iterations, 1 s each
# Measurement: 5 iterations, 1 s each
# Timeout: 10 min per iteration
# Threads: 1 thread, will synchronize iterations
# Benchmark mode: Throughput, ops/time
# Benchmark: MmapFileBenchmarkTest.testAppendNormalFile

# Run progress: 50.00% complete, ETA 00:00:09
# Fork: 1 of 1
# Warmup Iteration   1: 0.443 ops/s
# Warmup Iteration   2: 0.456 ops/s
# Warmup Iteration   3: 0.438 ops/s
Iteration   1: 0.406 ops/s
Iteration   2: 0.430 ops/s
Iteration   3: 0.408 ops/s
Iteration   4: 0.399 ops/s
Iteration   5: 0.410 ops/s


Result "MmapFileBenchmarkTest.testAppendNormalFile":
  0.411 ±(99.9%) 0.044 ops/s [Average]
  (min, avg, max) = (0.399, 0.411, 0.430), stdev = 0.011
  CI (99.9%): [0.367, 0.454] (assumes normal distribution)


# Run complete. Total time: 00:00:29

Benchmark                                    Mode  Cnt   Score   Error  Units
MmapFileBenchmarkTest.testAppendMappedFile  thrpt    5  17.667 ± 4.795  ops/s
MmapFileBenchmarkTest.testAppendNormalFile  thrpt    5   0.411 ± 0.044  ops/s
```

[![复制代码](RocketMQ(七)：高性能探秘之MappedFile.assets/copycode.gif)](javascript:void(0);)

　　很明显，mmap厉害些！结论粗糙，仅供参考！

不要害怕今日的苦，你要相信明天，更苦！

分类: [协议类](https://www.cnblogs.com/yougewe/category/755891.html), [原理&故事](https://www.cnblogs.com/yougewe/category/789557.html), [java](https://www.cnblogs.com/yougewe/category/923459.html), [大数据](https://www.cnblogs.com/yougewe/category/1238476.html), [源码](https://www.cnblogs.com/yougewe/category/1278448.html), [算法](https://www.cnblogs.com/yougewe/category/1844743.html)

标签: [pagecache](https://www.cnblogs.com/yougewe/tag/pagecache/), [并发](https://www.cnblogs.com/yougewe/tag/并发/), [rocketmq](https://www.cnblogs.com/yougewe/tag/rocketmq/), [mappedFile](https://www.cnblogs.com/yougewe/tag/mappedFile/), [高性能](https://www.cnblogs.com/yougewe/tag/高性能/), [锁](https://www.cnblogs.com/yougewe/tag/锁/)