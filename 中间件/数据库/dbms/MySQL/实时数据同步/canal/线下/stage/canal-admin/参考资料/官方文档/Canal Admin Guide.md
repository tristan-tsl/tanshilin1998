# Canal Admin Guide

agapple edited this page on 31 Aug 2019 · [4 revisions](https://github.com/alibaba/canal/wiki/Canal-Admin-Guide/_history)

# 背景

canal-admin设计上是为canal提供整体配置管理、节点运维等面向运维的功能，提供相对友好的WebUI操作界面，方便更多用户快速和安全的操作

# 准备

首先确保你先完成了canal-admin的基本部署，请参考: [Canal Admin QuickStart](https://github.com/alibaba/canal/wiki/Canal-Admin-QuickStart)

# 设计理念

canal-admin的核心模型主要有：

1. instance，对应canal-server里的instance，一个最小的订阅mysql的队列
2. server，对应canal-server，一个server里可以包含多个instance
3. 集群，对应一组canal-server，组合在一起面向高可用HA的运维

简单解释：

1. instance因为是最原始的业务订阅诉求，它会和 server/集群 这两个面向资源服务属性的进行关联，比如instance A绑定到server A上或者集群 A上，
2. 有了任务和资源的绑定关系后，对应的资源服务就会接收到这个任务配置，在对应的资源上动态加载instance，并提供服务
   - 动态加载的过程，有点类似于之前的autoScan机制，只不过基于canal-admin之后可就以变为远程的web操作，而不需要在机器上运维配置文件
3. 将server抽象成资源之后，原本canal-server运行所需要的canal.properties/instance.properties配置文件就需要在web ui上进行统一运维，每个server只需要以最基本的启动配置 (比如知道一下canal-admin的manager地址，以及访问配置的账号、密码即可)

理解了这一层基本概念之后，就开始WebUI的操作介绍.

# 集群运维

1. 创建集群

![img](https://camo.githubusercontent.com/2e7ad02a4cb9f73a4c9fccd1df2c13821d221bba5334d28baa1931ae241669c8/687474703a2f2f646c322e69746579652e636f6d2f75706c6f61642f6174746163686d656e742f303133322f323330362f39636666376363372d616261302d336435652d616230362d6261373338386536653064632e706e67)

1. 集群变更

![img](https://camo.githubusercontent.com/95dc425ee241873d54c04e096cf9a2e7cb87ae78714e503e7230c7c569a811f3/687474703a2f2f646c322e69746579652e636f6d2f75706c6f61642f6174746163686d656e742f303133322f323330382f63313539363564382d633966612d333865322d613064312d6135653533393539303365662e706e67)

配置项：

- 修改集群/删除集群，属于基本的集群信息维护和删除
- 主配置，主要是指集群对应的canal.properties配置，设计上一个集群的所有server会共享一份全局canal.properties配置 (如果有个性化的配置需求，可以创建多个集群)
- 查看server，主要是指查看挂载在这个集群下的所有server列表

# Server运维

1. 新建Server

![img](https://camo.githubusercontent.com/b469f47dccc866c9d19c95209da187e3760923a9aa16a2be620649b1a4341246/687474703a2f2f646c322e69746579652e636f6d2f75706c6f61642f6174746163686d656e742f303133322f323331302f63623938383833622d346431392d336339382d396462312d3631313663616133346633632e706e67)

配置项：

- 所属集群，可以选择为单机 或者 集群。一般单机Server的模式主要用于一次性的任务或者测试任务
- Server名称，唯一即可，方便自己记忆
- Server Ip，机器ip
- admin端口，canal 1.1.4版本新增的能力，会在canal-server上提供远程管理操作，默认值11110
- tcp端口，canal提供netty数据订阅服务的端口
- metric端口， promethues的exporter监控数据端口 (未来会对接监控)

1. Server变更

![img](https://camo.githubusercontent.com/9708fbec10496a7a8b21cffff8889d6210b7026b223f0cbf83b5d13a5fcfb3e0/687474703a2f2f646c322e69746579652e636f6d2f75706c6f61642f6174746163686d656e742f303133322f323331322f34376566343932312d633736612d333536342d383065372d6462666636623962333934322e706e67)

配置项:

- 配置，主要是维护单机模式的canal.properties配置，注意：挂载到集群模式的server，不允许单独编辑server的canal.properties配置，需要保持集群配置统一
- 修改/删除，主要是维护server的基本属性，比如名字和ip、port
- 启动/停止，主要是提供动态启停server的能力，比如集群内这个机器打算下线了，可以先通过停止释放instance的运行，集群中的其他机器通过HA就会开始接管任务
- 日志，查看server的根日志，主要是canal/canal.log的最后100行日志
- 详情，主要提供查询在当前这个server上运行的instance列表，以server维度方便快速做instance的启动、停止操作. 比如针对集群模式，如果server之间任务运行负载不均衡，可以通过对高负载Server执行部分Instance的停止操作来达到均衡的目的 ![img](https://camo.githubusercontent.com/e847d1d92aebb4b1e2a128ff59e0b8f628968b273bbafe331e66c62858dbfffd/687474703a2f2f646c322e69746579652e636f6d2f75706c6f61642f6174746163686d656e742f303133322f323331342f65656636633663642d646636312d333863322d623839662d6563646665346330306266372e706e67)

# Instance运维

1. 创建Instance

![img](https://camo.githubusercontent.com/e5f1b9f031e7791f3de816ddf6bbbf75d6caf7f2132bbafd2e79a52907c0fc81/687474703a2f2f646c322e69746579652e636f6d2f75706c6f61642f6174746163686d656e742f303133322f323331362f37663066646562622d616563372d333036622d383635372d3636353766653134326531622e706e67)

instance配置比较简单，主要关注：

- 资源关联，比如挂载到具体的单机 或 集群
- instance.properties配置维护，可以载入默认模板进行修改

1. Instance变更

![img](https://camo.githubusercontent.com/626b23a038986a83fac0765fc2d15229b031b9770b84a1d367879b7ff20c4fd9/687474703a2f2f646c322e69746579652e636f6d2f75706c6f61642f6174746163686d656e742f303133322f323331382f61306566393430662d663739382d333233332d393831342d6661316337616539313236662e706e67)

配置项:

- 修改，主要就是维护instance.properties配置，做了修改之后会触发对应单机或集群server上的instance做动态reload
- 删除，相当于直接执行instance stop，并执行配置删除
- 启动/停止，对instance进行状态变更，做了修改会触发对应单机或集群server上的instance做启动/停止操作
- 日志，主要针对instance运行状态时，获取对应instance的最后100行日志，比如example/example.log

# 系统运维

主要是涉及canal-admin的元数据配置，配置都在二进制包解压之后的conf目录下

```
-rwxr-xr-x  1 agapple  staff   403B  8 31 15:43 application.yml
-rwxr-xr-x  1 agapple  staff   5.0K  8 31 14:56 canal-template.properties
-rwxr-xr-x  1 agapple  staff   3.8K  8 30 22:14 canal_manager.sql
-rwxr-xr-x  1 agapple  staff   2.0K  8 31 14:56 instance-template.properties
-rwxr-xr-x  1 agapple  staff   1.5K  8 30 22:14 logback.xml
```

1. application.yml，springboot默认依赖的配置，比如链接数据库的账号密码，链接canal-server admin管理的账号密码
2. logback.xml，日志配置
3. canal-template.properties，canal配置的默认模板，针对canal-server开启自动注册时，会选择这个默认模板
4. instance-template.properties，instance配置的默认模板