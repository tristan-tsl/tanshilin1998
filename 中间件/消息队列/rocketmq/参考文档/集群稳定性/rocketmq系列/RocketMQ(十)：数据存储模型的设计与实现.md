# [RocketMQ(十)：数据存储模型的设计与实现](https://www.cnblogs.com/yougewe/p/14224366.html)



**目录**

- [1. 消息中间件的实现方式概述](https://www.cnblogs.com/yougewe/p/14224366.html#_label0)
- [2. rocketmq存储模型设计概述](https://www.cnblogs.com/yougewe/p/14224366.html#_label1)
- [3. commitlog文件的存储结构](https://www.cnblogs.com/yougewe/p/14224366.html#_label2)
- [4. consumequeue文件的存储结构](https://www.cnblogs.com/yougewe/p/14224366.html#_label3)
- [5. index文件的存储结构](https://www.cnblogs.com/yougewe/p/14224366.html#_label4)
- [6. 写在最后](https://www.cnblogs.com/yougewe/p/14224366.html#_label5)



------

　　消息中间件，说是一个通信组件也没有错，因为它的本职工作是做消息的传递。然而要做到高效的消息传递，很重要的一点是数据结构，数据结构设计的好坏，一定程度上决定了该消息组件的性能以及能力上限。

 

[返回顶部](https://www.cnblogs.com/yougewe/p/14224366.html#_labelTop)

### 1. 消息中间件的实现方式概述

　　消息中间件实现起来自然是很难的，但我们可以从某些角度，简单了说说实现思路。

　　它的最基本的两个功能接口为：接收消息的发送（produce）, 消息的消费（consume）. 就像一个邮递员一样，经过它与不经过它实质性的东西没有变化，它只是一个中介（其他功能效应，咱们抛却不说）。

　　为了实现这两个基本的接口，我们就得实现两个最基本的能力：消息的存储和查询。存储即是接收发送过来的消息，查询则包括业务查询与系统自行查询推送。

 

我们先来看第一个点：消息的存储。

　　直接基于内存的消息组件，可以做到非常高效的传递，基本上此时的消息中间件就是由几个内存队列组成，只要保证这几个队列的安全性和实时性，就可以工作得很好了。然而基于内存则必然意味着能力有限或者成本相当高，所以这样的设计适用范围得结合业务现状做下比对。

　　另一个就是基于磁盘的消息组件，磁盘往往意味着更大的存储空间，或者某种程度上意味着无限的存储空间，因为毕竟所有的大数据都是存放在磁盘上的，前提是系统需要协调好各磁盘间的数据关系。然而，磁盘也意味着性能的下降，数据存放起来更麻烦。但rocketmq借助于操作系统的pagecache和mmap以及顺序写机制，在读写性能方面已经非常优化。所以，更重要的是如何设计好磁盘的数据据结构。

 

然后是第二个点：消息的查询。

　　具体如何查询，则必然依赖于如何存储，与上面的原理类似，不必细说。但一般会有两种消费模型：推送消息模型和拉取消费模型。即是消息中间件主动向消费者推送消息，或者是消费者主动查询消息中间件。二者也各有优劣，推送模型一般可以体现出更强的实时性以及保持比较小的server端存储空间占用，但是也带来了非常大的复杂度，它需要处理各种消费异常、重试、负载均衡、上下线，这不是件小事。而拉取模型则会对消息中间件减轻许多工作，主要是省去了异常、重试、负载均衡类的工作，将这些工作转嫁到消费者客户端上。但与此同时，也会对消息中间件提出更多要求，即要求能够保留足够长时间的数据，以便所有合法的消费者都可以进行消费。而对于客户端，则也需要中间件提供相应的便利，以便可以实现客户端的基本诉求，比如消费组管理，上下线管理以及最基本的高效查询能力。

 

[返回顶部](https://www.cnblogs.com/yougewe/p/14224366.html#_labelTop)

### 2. rocketmq存储模型设计概述

　　很明显，rocketmq的初衷就是要应对大数据的消息传递，所以其必然是基于磁盘的存储。而其性能如上节所述，其利用操作系统的pagecache和mmap机制，读写性能非常好，另外他使用顺序写机制，使普通磁盘也能体现出非常高的性能。

　　但是，以上几项，只是为高性能提供了必要的前提。但具体如何利用，还需要从重设计。毕竟，快不是目的，实现需求才是意义。

　　rocketmq中主要有四种存储文件：commitlog 数据文件, consumequeue 消费队列文件, index 索引文件, 元数据信息文件。最后一个元数据信息文件比较简单，因其数据量小，方便操作。但针对前三个文件，都会涉及大量的数据问题，所以必然好详细设计其结构。

　　从总体上来说，rocketmq都遵从定长数据结构存储，定长的最大好处就在于可以快速定位位置，这是其高性能的出发点。定长模型。

　　从核心上来说，commitlog文件保存了所有原始数据，所有数据想要获取，都能从或也只能从commitlog文件中获取，由于commitlog文件保持了顺序写的特性，所以其性能非常高。而因数据只有一份，所以也就从根本上保证了数据一致性。

　　而根据各业务场景，衍生出了consumequeue和index文件，即 consumequeue 文件是为了消费者能够快速获取到相应消息而设计，而index文件则为了能够快速搜索到消息而设计。从功能上说，consumequeue和index文件都是索引文件，只是索引的维度不同。consumequeue 是以topic和queueId维度进行划分的索引，而index 则是以时间和key作为划分的索引。有了这两个索引之后，就可以为各自的业务场景，提供高性能的服务了。具体其如何实现索引，我们稍后再讲！

　　commitlog vs consumequeue 的存储模型如下:

![img](RocketMQ(十)：数据存储模型的设计与实现.assets/830731-20210102225705987-61834568.png)

 

[返回顶部](https://www.cnblogs.com/yougewe/p/14224366.html#_labelTop)

### 3. commitlog文件的存储结构

　　直接顺序写的形式存储，每个文件设定固定大小，默认是1G即: 1073741824 bytes. 写满一个文件后，新开一个文件写入。文件名就是其存储的起始消息偏移量。

　　官方描述如下：

> CommitLog：消息主体以及元数据的存储主体，存储Producer端写入的消息主体内容,消息内容不是定长的。单个文件大小默认1G ，文件名长度为20位，左边补零，剩余为起始偏移量，比如00000000000000000000代表了第一个文件，起始偏移量为0，文件大小为1G=1073741824；当第一个文件写满了，第二个文件为00000000001073741824，起始偏移量为1073741824，以此类推。消息主要是顺序写入日志文件，当文件满了，写入下一个文件；

　　当给定一个偏移量，要查找某条消息时，只需在所有的commitlog文件中，根据其名字即可知道偏移的数据信息是否存在其中，即相当于可基于文件实现一个二分查找，实际上rocketmq实现得更简洁，直接一次性查找即可定位：

[![复制代码](RocketMQ(十)：数据存储模型的设计与实现.assets/copycode.gif)](javascript:void(0);)

```
    // org.apache.rocketmq.store.CommitLog#getData
    public SelectMappedBufferResult getData(final long offset, final boolean returnFirstOnNotFound) {
        int mappedFileSize = this.defaultMessageStore.getMessageStoreConfig().getMappedFileSizeCommitLog();
        // 1. 先在所有commitlog文件中查找到对应所在的 commitlog 分片文件
        MappedFile mappedFile = this.mappedFileQueue.findMappedFileByOffset(offset, returnFirstOnNotFound);
        if (mappedFile != null) {
            // 再从该分片文件中，移动余数的大小偏移，即可定位到要查找的消息记录了
            int pos = (int) (offset % mappedFileSize);
            SelectMappedBufferResult result = mappedFile.selectMappedBuffer(pos);
            return result;
        }

        return null;
    }
    // 查找偏移所在commitlog文件的实现方式：
    // org.apache.rocketmq.store.MappedFileQueue#findMappedFileByOffset(long, boolean)
    // firstMappedFile.getFileFromOffset() / this.mappedFileSize 代表了第一条记录所处的文件位置编号
    // offset / this.mappedFileSize 代表当前offset所处的文件编号
    // 那么，两个编号相减就是当前offset对应的文件编号，因为第一个文件编号的相对位置是0
    // 但有个前提：就是每个文件存储的大小必须是真实的对应的 offset 大小之差，而实际上consumeQueue根本无法确定它存了多少offset
    // 也就是说，只要文件定长，offset用于定位 commitlog文件就是合理的
    int index = (int) ((offset / this.mappedFileSize) - (firstMappedFile.getFileFromOffset() / this.mappedFileSize));
    MappedFile targetFile = null;
    try {
        // 所以，此处可以找到 commitlog 文件对应的 mappedFile
        targetFile = this.mappedFiles.get(index);
    } catch (Exception ignored) {
    }
    if (targetFile != null && offset >= targetFile.getFileFromOffset()
        && offset < targetFile.getFileFromOffset() + this.mappedFileSize) {
        return targetFile;
    }
    // 如果快速查找失败，则退回到遍历方式, 使用O(n)的复杂度再查找一次
    for (MappedFile tmpMappedFile : this.mappedFiles) {
        if (offset >= tmpMappedFile.getFileFromOffset()
            && offset < tmpMappedFile.getFileFromOffset() + this.mappedFileSize) {
            return tmpMappedFile;
        }
    }
```

[![复制代码](RocketMQ(十)：数据存储模型的设计与实现.assets/copycode.gif)](javascript:void(0);)

　　定位到具体的消息记录位置后，如何知道要读多少数据呢？这实际上在commitlog的数据第1个字节中标明，只需读出即可知道。

　　具体commitlog的存储实现如下：

[![复制代码](RocketMQ(十)：数据存储模型的设计与实现.assets/copycode.gif)](javascript:void(0);)

```
    // org.apache.rocketmq.store.CommitLog.DefaultAppendMessageCallback#doAppend
    ...
    // Initialization of storage space
    this.resetByteBuffer(msgStoreItemMemory, msgLen);
    // 1 TOTALSIZE, 首先将消息大小写入
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
    byteBuffer.put(this.msgStoreItemMemory.array(), 0, msgLen);
    ...
```

[![复制代码](RocketMQ(十)：数据存储模型的设计与实现.assets/copycode.gif)](javascript:void(0);)

　　可以看出，commitlog的存储还是比较简单的，因为其主要就是负责将接收到的所有消息，依次写入同一文件中。因为专一所以专业。

 

[返回顶部](https://www.cnblogs.com/yougewe/p/14224366.html#_labelTop)

### 4. consumequeue文件的存储结构

　　consumequeue作为消费者的重要依据，同样起着非常重要的作用。消费者在进行消费时，会使用一些偏移量作为依据（拉取模型实现）。而这些个偏移量，实际上就是指的consumequeue的偏移量（注意不是commitlog的偏移量）。这样做有什么好处呢？首先，consumequeue作为索引文件，它被要求要有非常高的查询性能，所以越简单越好。最好是能够一次性定位到数据！

　　如果想一次性定位数据，那么唯一的办法是直接使用commitlog的offset。但这会带来一个最大的问题，就是当我当前消息消费拉取完成后，下一条消息在哪里呢？如果单靠commitlog文件，那么，它必然需要将下一条消息读入，然后再根据topic判定是不是需要的数据。如此一来，就必然存在大量的commitlog文件的io问题了。所以，这看起来是非常快速的一个解决方案，最终又变成了非常费力的方案了。

　　而使用commitlog文件的offset，则好了许多。因为consumequeue的文件存储格式是一条消息占20字节，即定长。根据这20字节，你可以找到commitlog的offset. 而因为consumequeue本身就是按照topic/queueId进行划分的，所以，本次消费完成后，下一次消费的数据必定就在consumequeue的下一位置。如此简单快速搞得定了。具体consume的存储格式，如官方描述：

> ConsumeQueue：消息消费队列，引入的目的主要是提高消息消费的性能，由于RocketMQ是基于主题topic的订阅模式，消息消费是针对主题进行的，如果要遍历commitlog文件中根据topic检索消息是非常低效的。Consumer即可根据ConsumeQueue来查找待消费的消息。其中，ConsumeQueue（逻辑消费队列）作为消费消息的索引，保存了指定Topic下的队列消息在CommitLog中的起始物理偏移量offset，消息大小size和消息Tag的HashCode值。consumequeue文件可以看成是基于topic的commitlog索引文件，故consumequeue文件夹的组织方式如下：topic/queue/file三层组织结构，具体存储路径为：$HOME/store/consumequeue/{topic}/{queueId}/{fileName}。同样consumequeue文件采取定长设计，每一个条目共20个字节，分别为8字节的commitlog物理偏移量、4字节的消息长度、8字节tag hashcode，单个文件由30W个条目组成，可以像数组一样随机访问每一个条目，每个ConsumeQueue文件大小约5.72M；

　　其中fileName也是以偏移量作为命名依据，因为这样才能根据offset快速查找到数据所在的分片文件。

　　其存储实现如下：

[![复制代码](RocketMQ(十)：数据存储模型的设计与实现.assets/copycode.gif)](javascript:void(0);)

```
    // org.apache.rocketmq.store.ConsumeQueue#putMessagePositionInfo
    private boolean putMessagePositionInfo(final long offset, final int size, final long tagsCode,
        final long cqOffset) {

        if (offset + size <= this.maxPhysicOffset) {
            log.warn("Maybe try to build consume queue repeatedly maxPhysicOffset={} phyOffset={}", maxPhysicOffset, offset);
            return true;
        }
        // 依次写入 offset + size + tagsCode
        this.byteBufferIndex.flip();
        this.byteBufferIndex.limit(CQ_STORE_UNIT_SIZE);
        this.byteBufferIndex.putLong(offset);
        this.byteBufferIndex.putInt(size);
        this.byteBufferIndex.putLong(tagsCode);

        final long expectLogicOffset = cqOffset * CQ_STORE_UNIT_SIZE;

        MappedFile mappedFile = this.mappedFileQueue.getLastMappedFile(expectLogicOffset);
        if (mappedFile != null) {

            if (mappedFile.isFirstCreateInQueue() && cqOffset != 0 && mappedFile.getWrotePosition() == 0) {
                this.minLogicOffset = expectLogicOffset;
                this.mappedFileQueue.setFlushedWhere(expectLogicOffset);
                this.mappedFileQueue.setCommittedWhere(expectLogicOffset);
                this.fillPreBlank(mappedFile, expectLogicOffset);
                log.info("fill pre blank space " + mappedFile.getFileName() + " " + expectLogicOffset + " "
                    + mappedFile.getWrotePosition());
            }

            if (cqOffset != 0) {
                long currentLogicOffset = mappedFile.getWrotePosition() + mappedFile.getFileFromOffset();

                if (expectLogicOffset < currentLogicOffset) {
                    log.warn("Build  consume queue repeatedly, expectLogicOffset: {} currentLogicOffset: {} Topic: {} QID: {} Diff: {}",
                        expectLogicOffset, currentLogicOffset, this.topic, this.queueId, expectLogicOffset - currentLogicOffset);
                    return true;
                }

                if (expectLogicOffset != currentLogicOffset) {
                    LOG_ERROR.warn(
                        "[BUG]logic queue order maybe wrong, expectLogicOffset: {} currentLogicOffset: {} Topic: {} QID: {} Diff: {}",
                        expectLogicOffset,
                        currentLogicOffset,
                        this.topic,
                        this.queueId,
                        expectLogicOffset - currentLogicOffset
                    );
                }
            }
            this.maxPhysicOffset = offset + size;
            // 将buffer写入 consumequeue 的 mappedFile 中
            return mappedFile.appendMessage(this.byteBufferIndex.array());
        }
        return false;
    }
    当需要进行查找进，也就会根据offset, 定位到某个 consumequeue 文件，然后再根据偏移余数信息，再找到对应记录，取出20字节，即是 commitlog信息。此处实现与 commitlog 的offset查找实现如出一辙。
    // 查找索引所在文件的实现,如下：
    // org.apache.rocketmq.store.ConsumeQueue#getIndexBuffer
    public SelectMappedBufferResult getIndexBuffer(final long startIndex) {
        int mappedFileSize = this.mappedFileSize;
        // 给到客户端的偏移量是除以 20 之后的，也就是说 如果上一次的偏移量是 1, 那么下一次的偏移量应该是2
        // 一次性消费多条记录另算, 自行加减
        long offset = startIndex * CQ_STORE_UNIT_SIZE;
        if (offset >= this.getMinLogicOffset()) {
            // 委托给mappedFileQueue进行查找到单个具体的consumequeue文件
            // 根据 offset 和规范的命名，可以快速定位分片文件，如上 commitlog 的查找实现
            MappedFile mappedFile = this.mappedFileQueue.findMappedFileByOffset(offset);
            if (mappedFile != null) {
                // 再根据剩余的偏移量，直接类似于数组下标的形式，一次性定位到具体的数据记录
                SelectMappedBufferResult result = mappedFile.selectMappedBuffer((int) (offset % mappedFileSize));
                return result;
            }
        }
        return null;
    }
```

[![复制代码](RocketMQ(十)：数据存储模型的设计与实现.assets/copycode.gif)](javascript:void(0);)

　　如果想一次性消费多条消息，则只需要依次从查找到索引记录开始，依次读取多条，然后同理回查commitlog即可。即consumequeue的连续，成就了commitlog的不连续。如下消息拉取实现：

[![复制代码](RocketMQ(十)：数据存储模型的设计与实现.assets/copycode.gif)](javascript:void(0);)

```
    // org.apache.rocketmq.store.DefaultMessageStore#getMessage
    // 其中 bufferConsumeQueue 是刚刚查找出的consumequeue的起始消费位置
    // 基于此文件迭代，完成多消息记录消费
    ...
    long nextPhyFileStartOffset = Long.MIN_VALUE;
    long maxPhyOffsetPulling = 0;

    int i = 0;
    final int maxFilterMessageCount = Math.max(16000, maxMsgNums * ConsumeQueue.CQ_STORE_UNIT_SIZE);
    final boolean diskFallRecorded = this.messageStoreConfig.isDiskFallRecorded();
    ConsumeQueueExt.CqExtUnit cqExtUnit = new ConsumeQueueExt.CqExtUnit();
    for (; i < bufferConsumeQueue.getSize() && i < maxFilterMessageCount; i += ConsumeQueue.CQ_STORE_UNIT_SIZE) {
        // 依次取出commitlog的偏移量，数据大小，hashCode
        // 一次循环即是取走一条记录，多次循环则依次往下读取
        long offsetPy = bufferConsumeQueue.getByteBuffer().getLong();
        int sizePy = bufferConsumeQueue.getByteBuffer().getInt();
        long tagsCode = bufferConsumeQueue.getByteBuffer().getLong();

        maxPhyOffsetPulling = offsetPy;

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

        if (messageFilter != null
            && !messageFilter.isMatchedByConsumeQueue(isTagsCodeLegal ? tagsCode : null, extRet ? cqExtUnit : null)) {
            if (getResult.getBufferTotalSize() == 0) {
                status = GetMessageStatus.NO_MATCHED_MESSAGE;
            }

            continue;
        }

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
    // 分配下一次读取的offset偏移信息，同样要除以单条索引大小
    nextBeginOffset = offset + (i / ConsumeQueue.CQ_STORE_UNIT_SIZE);

    long diff = maxOffsetPy - maxPhyOffsetPulling;
    long memory = (long) (StoreUtil.TOTAL_PHYSICAL_MEMORY_SIZE
        * (this.messageStoreConfig.getAccessMessageInMemoryMaxRatio() / 100.0));
    getResult.setSuggestPullingFromSlave(diff > memory);
    ...
```

[![复制代码](RocketMQ(十)：数据存储模型的设计与实现.assets/copycode.gif)](javascript:void(0);)

　　以上即理论的实现，无须多言。

 

[返回顶部](https://www.cnblogs.com/yougewe/p/14224366.html#_labelTop)

### 5. index文件的存储结构

　　index文件是为搜索场景而生的，如果没有搜索业务需求，则这个实现是意义不大的。一般这种搜索，主要用于后台查询验证类使用，或者有其他同的有妙用，不得而知。总之，一切为搜索。它更多的需要借助于时间限定，以key或者id进行查询。

　　官方描述如下：

> IndexFile（索引文件）提供了一种可以通过key或时间区间来查询消息的方法。Index文件的存储位置是：$HOME \store\index\${fileName}，文件名fileName是以创建时的时间戳命名的，固定的单个IndexFile文件大小约为400M，一个IndexFile可以保存 2000W个索引，IndexFile的底层存储设计为在文件系统中实现HashMap结构，故rocketmq的索引文件其底层实现为hash索引。
> IndexFile索引文件为用户提供通过“按照Message Key查询消息”的消息索引查询服务，IndexFile文件的存储位置是：$HOME\store\index\${fileName}，文件名fileName是以创建时的时间戳命名的，文件大小是固定的，等于40+500W\*4+2000W\*20= 420000040个字节大小。如果消息的properties中设置了UNIQ_KEY这个属性，就用 topic + “#” + UNIQ_KEY的value作为 key 来做写入操作。如果消息设置了KEYS属性（多个KEY以空格分隔），也会用 topic + “#” + KEY 来做索引。
> 其中的索引数据包含了Key Hash/CommitLog Offset/Timestamp/NextIndex offset 这四个字段，一共20 Byte。NextIndex offset 即前面读出来的 slotValue，如果有 hash冲突，就可以用这个字段将所有冲突的索引用链表的方式串起来了。Timestamp记录的是消息storeTimestamp之间的差，并不是一个绝对的时间。整个Index File的结构如图，40 Byte 的Header用于保存一些总的统计信息，4\*500W的 Slot Table并不保存真正的索引数据，而是保存每个槽位对应的单向链表的头。20\*2000W 是真正的索引数据，即一个 Index File 可以保存 2000W个索引。

　　具体结构图如下：

![img](RocketMQ(十)：数据存储模型的设计与实现.assets/830731-20210102230345473-1226296822.png)

　　那么，如果要查找一个key, 应当如何查找呢？rocketmq会根据时间段找到一个index索引分版，然后再根据key做hash得到一个值，然后定位到 slotValue . 然后再从slotValue去取出索引数据的地址，找到索引数据，然后再回查 commitlog 文件。从而得到具体的消息数据。也就是，相当于搜索经历了四级查询： 索引分片文件查询 -> slotValue 查询 -> 索引数据查询 -> commitlog 查询 。 

　　具体查找实现如下：

[![复制代码](RocketMQ(十)：数据存储模型的设计与实现.assets/copycode.gif)](javascript:void(0);)

```
    // org.apache.rocketmq.broker.processor.QueryMessageProcessor#queryMessage
    public RemotingCommand queryMessage(ChannelHandlerContext ctx, RemotingCommand request)
        throws RemotingCommandException {
        final RemotingCommand response =
            RemotingCommand.createResponseCommand(QueryMessageResponseHeader.class);
        final QueryMessageResponseHeader responseHeader =
            (QueryMessageResponseHeader) response.readCustomHeader();
        final QueryMessageRequestHeader requestHeader =
            (QueryMessageRequestHeader) request
                .decodeCommandCustomHeader(QueryMessageRequestHeader.class);

        response.setOpaque(request.getOpaque());

        String isUniqueKey = request.getExtFields().get(MixAll.UNIQUE_MSG_QUERY_FLAG);
        if (isUniqueKey != null && isUniqueKey.equals("true")) {
            requestHeader.setMaxNum(this.brokerController.getMessageStoreConfig().getDefaultQueryMaxNum());
        }
        // 从索引文件中查询消息
        final QueryMessageResult queryMessageResult =
            this.brokerController.getMessageStore().queryMessage(requestHeader.getTopic(),
                requestHeader.getKey(), requestHeader.getMaxNum(), requestHeader.getBeginTimestamp(),
                requestHeader.getEndTimestamp());
        assert queryMessageResult != null;

        responseHeader.setIndexLastUpdatePhyoffset(queryMessageResult.getIndexLastUpdatePhyoffset());
        responseHeader.setIndexLastUpdateTimestamp(queryMessageResult.getIndexLastUpdateTimestamp());

        if (queryMessageResult.getBufferTotalSize() > 0) {
            response.setCode(ResponseCode.SUCCESS);
            response.setRemark(null);

            try {
                FileRegion fileRegion =
                    new QueryMessageTransfer(response.encodeHeader(queryMessageResult
                        .getBufferTotalSize()), queryMessageResult);
                ctx.channel().writeAndFlush(fileRegion).addListener(new ChannelFutureListener() {
                    @Override
                    public void operationComplete(ChannelFuture future) throws Exception {
                        queryMessageResult.release();
                        if (!future.isSuccess()) {
                            log.error("transfer query message by page cache failed, ", future.cause());
                        }
                    }
                });
            } catch (Throwable e) {
                log.error("", e);
                queryMessageResult.release();
            }

            return null;
        }

        response.setCode(ResponseCode.QUERY_NOT_FOUND);
        response.setRemark("can not find message, maybe time range not correct");
        return response;
    }
    // org.apache.rocketmq.store.DefaultMessageStore#queryMessage
    @Override
    public QueryMessageResult queryMessage(String topic, String key, int maxNum, long begin, long end) {
        QueryMessageResult queryMessageResult = new QueryMessageResult();

        long lastQueryMsgTime = end;

        for (int i = 0; i < 3; i++) {
            // 委托给 indexService 搜索记录, 时间是必备参数
            QueryOffsetResult queryOffsetResult = this.indexService.queryOffset(topic, key, maxNum, begin, lastQueryMsgTime);
            if (queryOffsetResult.getPhyOffsets().isEmpty()) {
                break;
            }

            Collections.sort(queryOffsetResult.getPhyOffsets());

            queryMessageResult.setIndexLastUpdatePhyoffset(queryOffsetResult.getIndexLastUpdatePhyoffset());
            queryMessageResult.setIndexLastUpdateTimestamp(queryOffsetResult.getIndexLastUpdateTimestamp());

            for (int m = 0; m < queryOffsetResult.getPhyOffsets().size(); m++) {
                long offset = queryOffsetResult.getPhyOffsets().get(m);

                try {

                    boolean match = true;
                    MessageExt msg = this.lookMessageByOffset(offset);
                    if (0 == m) {
                        lastQueryMsgTime = msg.getStoreTimestamp();
                    }

                    if (match) {
                        SelectMappedBufferResult result = this.commitLog.getData(offset, false);
                        if (result != null) {
                            int size = result.getByteBuffer().getInt(0);
                            result.getByteBuffer().limit(size);
                            result.setSize(size);
                            queryMessageResult.addMessage(result);
                        }
                    } else {
                        log.warn("queryMessage hash duplicate, {} {}", topic, key);
                    }
                } catch (Exception e) {
                    log.error("queryMessage exception", e);
                }
            }

            if (queryMessageResult.getBufferTotalSize() > 0) {
                break;
            }

            if (lastQueryMsgTime < begin) {
                break;
            }
        }

        return queryMessageResult;
    }

    public QueryOffsetResult queryOffset(String topic, String key, int maxNum, long begin, long end) {
        List<Long> phyOffsets = new ArrayList<Long>(maxNum);

        long indexLastUpdateTimestamp = 0;
        long indexLastUpdatePhyoffset = 0;
        maxNum = Math.min(maxNum, this.defaultMessageStore.getMessageStoreConfig().getMaxMsgsNumBatch());
        try {
            this.readWriteLock.readLock().lock();
            if (!this.indexFileList.isEmpty()) {
                //从最后一个索引文件，依次搜索
                for (int i = this.indexFileList.size(); i > 0; i--) {
                    IndexFile f = this.indexFileList.get(i - 1);
                    boolean lastFile = i == this.indexFileList.size();
                    if (lastFile) {
                        indexLastUpdateTimestamp = f.getEndTimestamp();
                        indexLastUpdatePhyoffset = f.getEndPhyOffset();
                    }
                    // 判定该时间段是否数据是否在该索引文件中
                    if (f.isTimeMatched(begin, end)) {
                        // 构建出 key的hash, 然后查找 slotValue, 然后得以索引数据, 然后将offset放入 phyOffsets 中
                        f.selectPhyOffset(phyOffsets, buildKey(topic, key), maxNum, begin, end, lastFile);
                    }

                    if (f.getBeginTimestamp() < begin) {
                        break;
                    }

                    if (phyOffsets.size() >= maxNum) {
                        break;
                    }
                }
            }
        } catch (Exception e) {
            log.error("queryMsg exception", e);
        } finally {
            this.readWriteLock.readLock().unlock();
        }

        return new QueryOffsetResult(phyOffsets, indexLastUpdateTimestamp, indexLastUpdatePhyoffset);
    }
    // org.apache.rocketmq.store.index.IndexFile#selectPhyOffset
    public void selectPhyOffset(final List<Long> phyOffsets, final String key, final int maxNum,
        final long begin, final long end, boolean lock) {
        if (this.mappedFile.hold()) {
            int keyHash = indexKeyHashMethod(key);
            int slotPos = keyHash % this.hashSlotNum;
            int absSlotPos = IndexHeader.INDEX_HEADER_SIZE + slotPos * hashSlotSize;

            FileLock fileLock = null;
            try {
                int slotValue = this.mappedByteBuffer.getInt(absSlotPos);

                if (slotValue <= invalidIndex || slotValue > this.indexHeader.getIndexCount()
                    || this.indexHeader.getIndexCount() <= 1) {
                    // 超出搜索范围，不处理
                } else {
                    for (int nextIndexToRead = slotValue; ; ) {
                        if (phyOffsets.size() >= maxNum) {
                            break;
                        }

                        int absIndexPos =
                            IndexHeader.INDEX_HEADER_SIZE + this.hashSlotNum * hashSlotSize
                                + nextIndexToRead * indexSize;
                        // 依次读出 keyHash+offset+timeDiff+nextOffset
                        int keyHashRead = this.mappedByteBuffer.getInt(absIndexPos);
                        long phyOffsetRead = this.mappedByteBuffer.getLong(absIndexPos + 4);

                        long timeDiff = (long) this.mappedByteBuffer.getInt(absIndexPos + 4 + 8);
                        int prevIndexRead = this.mappedByteBuffer.getInt(absIndexPos + 4 + 8 + 4);

                        if (timeDiff < 0) {
                            break;
                        }

                        timeDiff *= 1000L;
                        // 根据文件名可得到索引写入时间
                        long timeRead = this.indexHeader.getBeginTimestamp() + timeDiff;
                        boolean timeMatched = (timeRead >= begin) && (timeRead <= end);

                        if (keyHash == keyHashRead && timeMatched) {
                            phyOffsets.add(phyOffsetRead);
                        }

                        if (prevIndexRead <= invalidIndex
                            || prevIndexRead > this.indexHeader.getIndexCount()
                            || prevIndexRead == nextIndexToRead || timeRead < begin) {
                            break;
                        }

                        nextIndexToRead = prevIndexRead;
                    }
                }
            } catch (Exception e) {
                log.error("selectPhyOffset exception ", e);
            } finally {
                if (fileLock != null) {
                    try {
                        fileLock.release();
                    } catch (IOException e) {
                        log.error("Failed to release the lock", e);
                    }
                }

                this.mappedFile.release();
            }
        }
    }
```

[![复制代码](RocketMQ(十)：数据存储模型的设计与实现.assets/copycode.gif)](javascript:void(0);)

　　看起来挺费劲，但真正处理起来性能还好，虽然没有consumequeue高效，但有mmap和pagecache的加持，效率还是扛扛的。而且，搜索相对慢一些，用户也是可以接受的嘛。毕竟这只是一个附加功能，并非核心所在。

　　而索引文件并没有使用什么高效的搜索算法，而是简单从最后一个文件遍历完成，因为时间戳不一定总是有规律的，与其随意查找，还不如直接线性查找。另外，实际上对于索引重建问题，搜索可能不一定会有效。不过，我们可以通过扩大搜索时间范围的方式，总是能够找到存在的数据。而且因其使用hash索引实现，性能还是不错的。

　　另外，index索引文件与commitlog和consumequeue有一个不一样的地方，就是它不能进行顺序写，因为hash存储，写一定是任意的。且其slotValue以一些统计信息可能随时发生变化，这也给顺序写带来了不可解决的问题。

　　其具体写索引过程如下：

[![复制代码](RocketMQ(十)：数据存储模型的设计与实现.assets/copycode.gif)](javascript:void(0);)

```
    // org.apache.rocketmq.store.index.IndexFile#putKey
    public boolean putKey(final String key, final long phyOffset, final long storeTimestamp) {
        if (this.indexHeader.getIndexCount() < this.indexNum) {
            int keyHash = indexKeyHashMethod(key);
            int slotPos = keyHash % this.hashSlotNum;
            int absSlotPos = IndexHeader.INDEX_HEADER_SIZE + slotPos * hashSlotSize;

            FileLock fileLock = null;

            try {
                // 先尝试拉取slot对应的数据
                // 如果为0则说明是第一次写入, 否则为当前的索引条数
                int slotValue = this.mappedByteBuffer.getInt(absSlotPos);
                if (slotValue <= invalidIndex || slotValue > this.indexHeader.getIndexCount()) {
                    slotValue = invalidIndex;
                }

                long timeDiff = storeTimestamp - this.indexHeader.getBeginTimestamp();

                timeDiff = timeDiff / 1000;

                if (this.indexHeader.getBeginTimestamp() <= 0) {
                    timeDiff = 0;
                } else if (timeDiff > Integer.MAX_VALUE) {
                    timeDiff = Integer.MAX_VALUE;
                } else if (timeDiff < 0) {
                    timeDiff = 0;
                }
                // 直接计算出本次存储的索引记录位置
                // 因索引条数只会依次增加，故索引数据将表现为顺序写样子，主要是保证了数据不会写冲突了
                int absIndexPos =
                    IndexHeader.INDEX_HEADER_SIZE + this.hashSlotNum * hashSlotSize
                        + this.indexHeader.getIndexCount() * indexSize;
                // 按协议写入内容即可
                this.mappedByteBuffer.putInt(absIndexPos, keyHash);
                this.mappedByteBuffer.putLong(absIndexPos + 4, phyOffset);
                this.mappedByteBuffer.putInt(absIndexPos + 4 + 8, (int) timeDiff);
                this.mappedByteBuffer.putInt(absIndexPos + 4 + 8 + 4, slotValue);
                // 写入slotValue为当前可知的索引记录条数
                // 即每次写入索引之后，如果存在hash冲突，那么它会写入自身的位置
                // 而此时 slotValue 必定存在一个值，那就是上一个发生冲突的索引，从而形成自然的链表
                // 查找数据时，只需根据slotValue即可以找到上一个写入的索引，这设计妙哉！
                // 做了2点关键性保证：1. 数据自增不冲突; 2. hash冲突自刷新; 磁盘版的hash结构已然形成
                this.mappedByteBuffer.putInt(absSlotPos, this.indexHeader.getIndexCount());

                if (this.indexHeader.getIndexCount() <= 1) {
                    this.indexHeader.setBeginPhyOffset(phyOffset);
                    this.indexHeader.setBeginTimestamp(storeTimestamp);
                }

                if (invalidIndex == slotValue) {
                    this.indexHeader.incHashSlotCount();
                }
                this.indexHeader.incIndexCount();
                this.indexHeader.setEndPhyOffset(phyOffset);
                this.indexHeader.setEndTimestamp(storeTimestamp);

                return true;
            } catch (Exception e) {
                log.error("putKey exception, Key: " + key + " KeyHashCode: " + key.hashCode(), e);
            } finally {
                if (fileLock != null) {
                    try {
                        fileLock.release();
                    } catch (IOException e) {
                        log.error("Failed to release the lock", e);
                    }
                }
            }
        } else {
            log.warn("Over index file capacity: index count = " + this.indexHeader.getIndexCount()
                + "; index max num = " + this.indexNum);
        }

        return false;
    }
```

[![复制代码](RocketMQ(十)：数据存储模型的设计与实现.assets/copycode.gif)](javascript:void(0);)

　　rocketmq 巧妙地使用了自增结构和hash slot, 完美实现一个磁盘版的hash索引。相信这也会给我们平时的工作带来一些提示。

　　

[返回顶部](https://www.cnblogs.com/yougewe/p/14224366.html#_labelTop)

### 6. 写在最后

　　以上就是本文对rocketmq的存储模型设计的解析了，通过这些解析，相信大家对其工作原理也会有质的理解。存储实际上是目前我们的许多的系统中的非常核心部分，因为大部分的业务几乎都是在存储之前做一些简单的计算。

   很显然业务很重要，但有了存储的底子，还何愁业务实现难？

　　

 

不要害怕今日的苦，你要相信明天，更苦！

分类: [协议类](https://www.cnblogs.com/yougewe/category/755891.html), [原理&故事](https://www.cnblogs.com/yougewe/category/789557.html), [并发&性能](https://www.cnblogs.com/yougewe/category/844109.html), [java](https://www.cnblogs.com/yougewe/category/923459.html), [大数据](https://www.cnblogs.com/yougewe/category/1238476.html), [源码](https://www.cnblogs.com/yougewe/category/1278448.html), [算法](https://www.cnblogs.com/yougewe/category/1844743.html), [数据库](https://www.cnblogs.com/yougewe/category/1846971.html)

标签: [顺序写](https://www.cnblogs.com/yougewe/tag/顺序写/), [consumequeue](https://www.cnblogs.com/yougewe/tag/consumequeue/), [索引](https://www.cnblogs.com/yougewe/tag/索引/), [数据库设计](https://www.cnblogs.com/yougewe/tag/数据库设计/), [定长存储](https://www.cnblogs.com/yougewe/tag/定长存储/), [rocketmq](https://www.cnblogs.com/yougewe/tag/rocketmq/), [hash](https://www.cnblogs.com/yougewe/tag/hash/), [commitlog](https://www.cnblogs.com/yougewe/tag/commitlog/)