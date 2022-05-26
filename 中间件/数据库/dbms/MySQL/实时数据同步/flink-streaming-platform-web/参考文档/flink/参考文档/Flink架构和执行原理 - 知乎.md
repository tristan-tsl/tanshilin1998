# Flink架构和执行原理

[![Snail](https://pic1.zhimg.com/v2-e79dc6902f2046c8cb26797c318998ba_xs.jpg?source=172ae18b)](https://www.zhihu.com/people/xueai2020)

[Snail](https://www.zhihu.com/people/xueai2020)

只要不放弃,蜗牛也可以爬到金字塔的顶端!xueai8.com

17 人赞同了该文章

在大数据领域，有许多流计算框架，但是通常很难兼顾延迟性和吞吐量。Apache Storm提供低延迟，但目前不提供高吞吐量，也不支持在发生故障时正确处理状态。Apache Spark Streaming的微批处理方法实现了高吞吐量的容错性，但是难以实现真正的低延时和实时处理，并且表达能力方面也不是特别丰富。而Apache Flink兼顾了低延迟和高吞吐量，是企业部署流计算时的首选。

### 1、Flink架构

Flink 是可以运行在多种不同的环境中的，例如，它可以通过单进程多线程的方式直接运行，从而提供调试的能力。它也可以运行在 Yarn 或者 K8S 这种资源管理系统上面，也可以在各种云环境中执行。

Flink的整体架构如下图所示。

![img](https://pic2.zhimg.com/80/v2-9baeebbb52cb8ba6bc4e86b9542b87e1_720w.jpg)

针对不同的执行环境，Flink 提供了一套统一的分布式作业执行引擎，也就是 Flink Runtime（Flink运行时）这一层。Flink 在 Runtime 层之上提供了 DataStream 和 DataSet 两套 API，分别用来编写流作业与批作业，以及一组更高级的 API 来简化特定作业的编写。

Flink runtime是Flink的核心计算结构，这是一个分布式系统，它接受流数据流程序，并在一台或多台机器上以容错的方式执行这些数据流程序。这个运行时可以作为YARN的应用程序在集群中运行，也可以很快在Mesos集群中运行，或者在一台机器中运行（通常用于调试Flink应用程序）。

Flink Runtime 层的主要架构如下图所示，它展示了一个 Flink 集群的基本结构。Flink Runtime 层的整个架构采用了标准 Master-Slave 的结构，即总是由一个Flink Master和一个或多个Flink TaskManager组成。在下面的架构图中，其中左侧的AM（Application Manager）部分即是Master，它负责管理整个集群中的资源并处理作业提交、作业监督；而右侧的两个 TaskExecutor 则是 Slave，这是工作（worker）进程，负责提供具体的资源并实际执行作业。

![img](https://pic2.zhimg.com/80/v2-d94d8ca8597a60aff269dcae21db39c9_720w.jpg)

Flink Master是Flink集群的主进程。它包含三个不同的组件：Resource Manager、Dispatcher以及每个运行时Flink作业的JobManager。这三个组件都包含在 AppMaster 进程中。

- Dispatcher 负责接收用户提供的作业，并且负责为这个新提交的作业拉起一个新的 JobManager 组件。
- ResourceManager 负责资源的管理，在整个 Flink 集群中只有一个 ResourceManager。
- JobManager 负责管理作业的执行，在一个 Flink 集群中可能有多个作业同时执行，每个作业都有自己的 JobManager 组件。

TaskManager是一个Flink集群的工作（worker）进程。任务（Tasks）被调度给TaskManager执行。它们彼此通信以在后续任务之间交换数据。

总体来说，Flink运行时由两种类型的进程组成：

- JobManager：是执行过程中的 master 进程，负责协调和管理程序的分布式执行，主要的内容包括调度任务（task），管理检查点（checkpoints）和协调故障恢复（failure recovery）等等。至少要有一个JobManager。可以设置多个JobManager以配置高可用性，其中一个总是leader，其他的都是standby。
- TaskManager：作为 worker 节点在 JVM 上运行，可以同时执行若干个线程以完成分配给它的 数据流的task(子任务)，并缓冲和交换数据流。必须始终至少有一个TaskManager。

JobManager和TaskManager可以多种方式启动：直接在机器上作为独立集群（standalone）启动，或者在容器中启动，或者由诸如YARN或Mesos之类的资源框架管理。

客户端不是运行时和程序执行的一部分，而是用于准备和向JobManager发送数据流。之后，客户端可以断开连接，或保持连接以接收作业进度报告。客户端可以作为触发执行的Java/Scala程序的一部分运行，也可以在命令行进程（./bin/flink run）中运行。

### 2、Flink计算资源

每个worker (TaskManager)都是一个JVM进程，可以在单独的线程中执行一个或多个子任务。为了控制一个worker接受多少任务，一个worker具有所谓的"任务插槽"(task slots，至少一个)。

每个task slot表示TaskManager资源的一个固定子集。例如，一个TaskManager拥有三个slot，那么它会为每个slot分配其1/3的托管内存。对资源进行槽化意味着子任务不会与来自其他作业的子任务争夺托管内存，而是拥有一定数量的预留托管内存。

Task 的并行度依赖于 Task Manager 上可用的任务插槽数量，每个 task 占据了分配给它的任务插槽的资源。每个任务插槽上运行着若干个线程，同一个插槽上的线程共享同一个 JVM，同一个 JVM 上的任务共享 TCP 连接和心跳（heart beat）信息。

通过调整任务槽的数量，用户可以定义子任务如何彼此隔离。每个TaskManager有一个slot意味着每个任务组运行在各自的JVM中(例如，可以在单独的容器中启动JVM)。拥有多个slot意味着多个子任务共享同一个JVM。相同JVM中的任务共享TCP连接(通过多路复用)和心跳消息。它们还可以共享数据集和数据结构，从而减少每个任务的开销。

![img](https://pic1.zhimg.com/80/v2-f20382f6fdff00f7b795591091d72eb8_720w.jpg)

默认情况下，Flink允许多个子任务共享slot，即使它们是不同任务的子任务，只要它们来自相同的作业。结果是一个slost可以容纳作业的整个管道。允许这个插槽共享（slot sharing）有两个主要好处：

- Flink集群需要的任务插槽与作业中使用的最高并行度一样多。不需要计算一个程序总共包含多少任务(具有不同的并行度)。
- 更容易得到更好的资源利用。如果没有插槽共享，非密集型source/map()子任务将阻塞与资源密集型窗口子任务一样多的资源。使用插槽共享，将上图中右侧TaskManager的基本并行度从2提高到6，如下图所示。这样可以充分利用slot资源，同时确保繁重的子任务在TaskManager中得到公平分配。

![img](https://pic2.zhimg.com/80/v2-9cdfcb9304a622c19c89ad6b5d8e24dd_720w.jpg)

API还包括一个资源组（resource group）机制，可用于防止不需要的插槽共享。

根据经验，一个好的默认task slot数量应该是CPU内核的数量。使用超线程，每个slost可接受2个或更多的硬件线程上下文。

### 3、Flink资源管理

Apache Flink是一个分布式系统，需要计算资源才能执行应用程序。实际上，Flink作业调度可以看做是对资源和任务进行匹配的过程。Flink集成了所有常见的集群资源管理器，如Hadoop YARN、Apache Mesos和Kubernetes，但也可以设置为作为独立集群运行。

在 Flink 中，资源是由 TaskManager上的 Slot 来表示的，每个 Slot 可以用来执行不同的任务（task）。而作业中实际的task，包含了待执行的用户逻辑。作业调度的主要目的就是为了给task找到匹配的slot。

在 ResourceManager 中，有一个子组件叫做 SlotManager，它维护了当前集群中所有 TaskManager 上的slot的信息与状态，如该slot在哪个TaskManager中，该slot 当前是否空闲等。如下图所示：

![img](https://pic2.zhimg.com/80/v2-9f93d3dde1af71894a60bd92dfeaf381_720w.jpg)

当JobManger为特定task申请资源的时候，根据当前是Per-job模式还是Session模式，ResourceManager 可能会去申请资源来启动新的TaskManager。当TaskManager启动之后，它会通过服务发现找到当前活跃的ResourceManager并进行注册。在注册信息中，会包含该TaskManager中所有 slot的信息。ResourceManager 收到注册信息后，其中的 SlotManager 就会记录下相应的slot信息。当 JobManager 为某个task来申请资源时，SlotManager 就会从当前空闲的slot中按一定规则选择一个空闲的slot进行分配。当分配完成后，ResourceManager会首先向TaskManager发送 RPC 要求将选定的slot 分配给特定的 JobManager。TaskManager 如果还没有执行过该JobManager的task 的话，它需要首先向相应的 JobManager 建立连接，然后发送提供slot的RPC请求。在JobManager中，所有Task的请求会缓存到SlotPool中。当有slot被提供之后，SlotPool 会从缓存的请求中选择相应的请求并结束相应的请求过程。

当task结束之后，无论是正常结束还是异常结束，都会通知 JobManager 相应的结束状态，然后在 TaskManager 端将slot标记为已占用但未执行任务的状态。JobManager 会首先将相应的slot缓存到 SlotPool中，但不会立即释放。这种方式避免了如果将slot直接还给 ResourceManager，在任务异常结束之后需要重启时，需要立刻重新申请slot的问题。通过延时释放，失败的task可以尽快调度回原来的 TaskManager，从而加快故障恢复的速度。当 SlotPool中缓存的slot超过指定的时间仍未使用时，SlotPool 就会发起释放该slot的过程。与申请slot的过程对应，SlotPool 会首先通知TaskManager来释放该slot，然后TaskManager通知ResourceManager该slot已经被释放，从而最终完成释放的逻辑。

除了正常的通信逻辑外，在ResourceManager和TaskManager之间还存在定时的心跳消息来同步slot 的状态。在分布式系统中，消息的丢失、错乱不可避免，这些问题会在分布式系统的组件中引入不一致状态，如果没有定时消息，那么组件无法从这些不一致状态中恢复。此外，当组件之间长时间未收到对方的心跳时，就会认为对应的组件已经失效，并进入到故障恢复的流程。

发布于 2020-04-28

[Flink](https://www.zhihu.com/topic/20043072)

[流计算](https://www.zhihu.com/topic/19660111)

[Apache Storm](https://www.zhihu.com/topic/19673110)