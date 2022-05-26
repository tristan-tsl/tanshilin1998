《小鑫发现》之Flink-SQL管理工具flink-streaming-platform-web

iOLO_FXX 2021-01-08 11:09:47  643  收藏
分类专栏： Java Flink 文章标签： java kafka 数据库 flink
版权

Java
同时被 2 个专栏收录
4 篇文章0 订阅
订阅专栏

Flink
2 篇文章0 订阅
订阅专栏
介绍
一个方便操作Flink-SQL的工具

准备环境、程序和依赖
Flink 1.12 下载地址

这里下载的事scala 2.11的版本

Kafka 2.12-2.5.0 下载地址

这里没有去下载zookeeper，因为kafka里自带zookeeper，所以就直接用这个，别问为啥，问就是为了省事。
另外为啥是这个版本，不是最新，别问，问就是因为本地就是这个，懒得下载最新的了。

Scala 2.11 下载地址

根据自己的环境进行下载，本人是Mac下载的scala-2.12.12.tgz

Flink-streaming-platform-web 下载地址

另外注意这里的版本，因为都会影响后续Flink进行依赖lib时候的版本号，对不上，可能会出现ClassNotFound等问题，很凸(艹皿艹 )

构建Scala环境
为啥构建这个呢，因为没构建这个环境的时候，程序运行的时候出现了错误，我按照提示进行增加本地的Scala环境，所以这里还是记录一下。



设置环境变量vim ~/.bash_profile

export SCALA_HOME=/Users/iOLO/dev/OpenSource/scala-2.11.12
export PATH=$SCALA_HOME/bin:$PATH
1
2
别忘了生效命令，source ~/.bash_profile
验证必备，验证命令

$ scala -version                        
Scala code runner version 2.11.12 -- Copyright 2002-2017, LAMP/EPFL
$ scala                     
Welcome to Scala 2.11.12 (Java HotSpot(TM) 64-Bit Server VM, Java 1.8.0_171).
Type in expressions for evaluation. Or try :help.
scala>
1
2
3
4
5
6
构建Flink环境并启动
下载好Flink的压缩包之后去解压

注意这里规定好一个目录，一会的web工具也放在一个文件夹下，别问为啥，问了我也不知道。



修改一下Flink配置文件，这里就直接贴出来我修改的地方，几乎没有动，因为我不太懂，所以能用就行

# 这是运行任务的数量，默认是1，这里改成是10，别问，问就是因为我喜欢
taskmanager.numberOfTaskSlots: 10
# 这里是checkpoint存储的问题，分别由内存，fs，rockDB，我这里的用的是内存，不过好像默认是就是内存
# 我也不太懂，就改了改
state.backend: jobmanager
# 这里群里发的配置，我也不知道是啥，就直接改了
jobmanager.execution.failover-strategy: region
# 这个是关键，是啥作用不知道，但是web工具备注上说明这个需要改成这个
classloader.resolve-order: parent-first
1
2
3
4
5
6
7
8
9
进入对应的Flink目录，启动Flink。

~/dev/Flink/flink-1.12.0/bin $ pwd
/Users/iOLO/dev/Flink/flink-1.12.0/bin
~/dev/Flink/flink-1.12.0/bin $ ./start-cluster.sh                                    
Starting cluster.
Starting standalonesession daemon on host nothing.attdns.com.
Starting taskexecutor daemon on host nothing.attdns.com.
~/dev/Flink/flink-1.12.0/bin $ jps                                             
20928 Jps
20848 TaskManagerRunner
6901
20601 StandaloneSessionClusterEntrypoint
6954 Launcher
1004 NutstoreGUI
1
2
3
4
5
6
7
8
9
10
11
12
13
看见TaskManagerRunner和StandaloneSessionClusterEntrypoint 就表示启动成功。
在bin目录下，启动命令是./start-cluster.sh，停止命令是./stop-cluster.sh

然后进入网页查看页面 http://127.0.0.1:8081/



OK ，Flink准备工作就绪，下一步Kafka。

搭建Kafka
进入Kafka文件目录



修改配置文件，这里就只修改server.properties ，zookeeper的就用默认的，没什么需要修改的地方

# 注意这里都是用的localhost，具体是为啥，我也忘了，反正当时是报错，我就改成这个，而且我发现这些地方最好都是域名，别是地址，不明白为啥
listeners=PLAINTEXT://localhost:9092
# 
advertised.listeners=PLAINTEXT://localhost:9092
############################# Log Basics #############################
# 指定目录log，方便日后查找，并且会出现一个错误，meta.properties的，在这个目录删除就行了
log.dirs=/Users/iOLO/dev/middleware/log/kafka/log
############################# Zookeeper #############################
# 指定zookeeper
zookeeper.connect=localhost:2181
1
2
3
4
5
6
7
8
9
10
先启动zookeeper，进入Kafka的bin目录

$ pwd
/kafka_2.12-2.5.0/bin
$  ./zookeeper-server-start.sh ../config/zookeeper.properties
babababa的一堆信息
[2021-01-08 09:50:53,125] INFO binding to port 0.0.0.0/0.0.0.0:2181 (org.apache.zookeeper.server.NIOServerCnxnFactory)
[2021-01-08 09:50:53,150] INFO zookeeper.snapshotSizeFactor = 0.33 (org.apache.zookeeper.server.ZKDatabase)
[2021-01-08 09:50:53,160] INFO Reading snapshot /tmp/zookeeper/version-2/snapshot.111 (org.apache.zookeeper.server.persistence.FileSnap)
[2021-01-08 09:50:53,201] INFO Snapshotting: 0x135 to /tmp/zookeeper/version-2/snapshot.135 (org.apache.zookeeper.server.persistence.FileTxnSnapLog)
[2021-01-08 09:50:53,225] INFO Using checkIntervalMs=60000 maxPerMinute=10000 (org.apache.zookeeper.server.ContainerManager)
$ jps
20848 TaskManagerRunner
6901
22136 QuorumPeerMain
20601 StandaloneSessionClusterEntrypoint
6954 Launcher
1004 NutstoreGUI
22478 Jps
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
看见QuorumPeerMain表示有了zookeeper的进程

然后启动Kafka，./kafka-server-start.sh ../config/server.properties

$ pwd
/kafka_2.12-2.5.0/bin
$ ./kafka-server-start.sh ../config/server.properties
babababad的一堆信息
1
2
3
4
然后用jps看是否有Kafka的信息就行了

注意，我这里，都没有用到后台启动，为的就是方便查看运行信息和方便关闭，后台启动自行查询

创建Kafka的Topics

依然是在kafka的bin目录下

$ pwd                                      
/kafka_2.12-2.5.0/bin
$ ./kafka-topics.sh --create --zookeeper 127.0.0.1:2181 --replication-factor 1 --partitions 1 --topic flink2    
Created topic flink2.
$ ./kafka-topics.sh --list --zookeeper localhost:2181                                    
__consumer_offsets
flink2
1
2
3
4
5
6
7
有人会疑问，为啥是flink2呢，不是1，别问，问就是告诉你，你还没看见我flink100呢，你就明白我测试了多少次。

分别开启窗口启动生产者 和 消费者
生产者

$ ./kafka-console-producer.sh --broker-list localhost:9092 --topic flink2                                            
>
>1
>2
>消费者

$ ./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic flink2 --from-beginning
1
然后去验证，在生产者那发送消息，消费者那可以看到，很神奇吧。
消息体是{"day_time": "20210103","id": 1,"amnount":110}



在MySQL里建立一个数据表，用于查看效果
数据库名是flink_web
建表脚本是

CREATE TABLE `sync_test_2` (
  `day_time` varchar(64) NOT NULL,
  `total_gmv` bigint(11) DEFAULT NULL,
  PRIMARY KEY (`day_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
1
2
3
4
5
到此环境算是构建完成了

下载所需依赖
这一步是现在Flink需要依赖的jar包，这些jar很关键，他是保证整套flink程序进行解析，链接等操作的依赖，并且一定要下载正确的版本，跟Flink对应上。

所有的jar都放在Flink目录下的lib里

其实这里有个窍门，官网已经提供了各类connectors的建议，根据官网来，应该就没错
官网地址





开启flink-streaming-platform-web服务
从git上下载完，进行解压，记住，要和之前的Flink在一个目录

修改配置文件，主要修改数据库地址，在config的application.properties里

####jdbc信息
server.port=9084
spring.datasource.url=jdbc:mysql://127.0.0.1:3306/flink_web?characterEncoding=UTF-8&useSSL=false
spring.datasource.username=root
spring.datasource.password=mima
1
2
3
4
5
useSSL=false 注意这个，如果你的MySQL支持ssl那就不用加，不支持，记得加上，防止报错

创建数据表脚本，依然是在flink_web下，脚本在 https://github.com/zhp8341/flink-streaming-platform-web/blob/master/docs/sql/flink_web.sql，请自行下载和创建。

然后进入到bin目录下，记住进入bin目录，启动脚本，一会告诉你咋回事。

$ sh ./deploy.sh start               
开始启动服务 app_name=flink-streaming-web-1.1.1.RELEASE.jar

开始启动进程 flink-streaming-web-1.1.1.RELEASE.jar
Start java end pid= 25087
1
2
3
4
5
启动命令是 sh ./deploy.sh start，停止命令是sh ./deploy.sh stop

解密，为啥在进入bin里面，不是在其他目录启动呢，看启动脚本，你就明白了，主要是目录层级的问题，仔细看看吧。

打开页面查看 http://127.0.0.1:9084/admin/index?message=nologin，登录号：admin 密码 123456。





需要先配置系统环境，按照我的结局配置就行，少一个都不行，记住，yarn那个没有也没事，写上就行，如果下载web是最新的版本，应该此问题就解决了。


然后去新增配置


SQL语句如下

 CREATE TABLE sync_test_2 (
     day_time string,
     total_gmv bigint,
     PRIMARY KEY (day_time) NOT ENFORCED
 ) WITH (
  'connector' = 'jdbc',
  'url' = 'jdbc:mysql://127.0.0.1:3306/flink_web',
  'table-name' = 'sync_test_2',
  'username' = 'root',
  'password' = 'mima',
  'scan.auto-commit' = 'false',
  'sink.buffer-flush.max-rows' = '1'
 );
 create table flink_test_3 ( 
  id BIGINT,
  day_time VARCHAR,
  amnount BIGINT,
  proctime AS PROCTIME ()
)
 with ( 
  'connector'='kafka',
  'topic'='flink2',
  'scan.startup.mode' = 'earliest-offset',
  'properties.bootstrap.servers'='localhost:9092',
  'format'='json'
 );
INSERT INTO sync_test_2
SELECT day_time,SUM(amnount) AS total_gmv
FROM flink_test_3
GROUP BY day_time;
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
然后的步骤是，先点击开启配置，然后在点击提交任务，变成这样。


然后点击日志详情，查看是否成功，然后再去Flink那查任务是否Running



见证奇迹
下面就精彩了，之前所有都是为了铺垫这个。

先看MySQL表的数据表，内容是空的。


然后在之前的kafka的生产者处，发送消息体 {"day_time": "20210101","id": 1,"amnount":10}

$ ./kafka-console-producer.sh --broker-list localhost:9092 --topic flink2                             
>{"day_time": "20210101","id": 1,"amnount":10}
>
>1
>2
>3
>看一下消费者是否有提示


再看眼MySQL的表


神奇不
然后多试试，几个内容，神奇的效果就会出来。

{"day_time": "20210703","id": 5,"amnount":10}
{"day_time": "20210803","id": 6,"amnount":10}
{"day_time": "20210903","id": 7,"amnount":10}
{"day_time": "20210803","id": 8,"amnount":10}
{"day_time": "20210903","id": 9,"amnount":90}
{"day_time": "20211003","id": 10,"amnount":100}
{"day_time": "20211003","id": 10,"amnount":100}
{"day_time": "20211103","id": 11,"amnount":110}
{"day_time": "20210603","id": 6,"amnount":10}
{"day_time": "20210603","id": 6,"amnount":10}
{"day_time": "20210603","id": 6,"amnount":10}
{"day_time": "20210603","id": 6,"amnount":10}
{"day_time": "20210603","id": 6,"amnount":10}
{"day_time": "20211003","id": 10,"amnount":100}
{"day_time": "20211003","id": 10,"amnount":100}
{"day_time": "20210101","id": 1,"amnount":10}
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
结束
整体就是这个样子，其实这些使用sql-client也可以实现，不过有了可视化页面，更方便人们操作，并且web也提供了很多其他的功能，并且也在长期迭代中，希望大家多多支持（还有我）
另外如果有问题，多看看日志。

下面给几个主要查资料的网站

Flink-streaming-platform-web
Flink相关jar的repo
Flink官网