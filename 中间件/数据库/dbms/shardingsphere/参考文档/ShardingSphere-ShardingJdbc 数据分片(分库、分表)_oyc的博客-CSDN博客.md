ShardingSphere-ShardingJdbc 数据分片(分库、分表)

置顶 乾源 2020-10-25 16:10:02  976  收藏 1
分类专栏： SpringBoot SpringBoot+SpringCloud ShardingSphere 文章标签： mysql 数据库 java spring spring boot
版权

SpringBoot
同时被 3 个专栏收录
39 篇文章3 订阅
订阅专栏

SpringBoot+SpringCloud
34 篇文章12 订阅
订阅专栏

ShardingSphere
3 篇文章0 订阅
订阅专栏
摘要：
我们实际开发中，总有几张和业务相关的大表，这里的大表是指数据量巨大。如用户表、订单表，又或者公司业务中的主表，可能很快这种表的数据就达到了百万、千万、亿级别的规模，并且增长规模一直很快。这种情况下，单表已经满足不了了存储需求了，同时，这么大的数据量，即使搭配合理的索引，数据库查询也是很慢的，这时就需要对这些大表进行分库、分表。应用需要能对sql进行解析、改写、路由、结果集合并等一些操作，以及分布式事务、分布式id生成器等。

典型的数据库中间件设计方案有2种（原文：https://github.com/Meituan-Dianping/Zebra/wiki/%E6%95%B0%E6%8D%AE%E5%BA%93%E4%B8%AD%E9%97%B4%E4%BB%B6%E4%B8%BB%E6%B5%81%E8%AE%BE%E8%AE%A1）：

服务端代理(proxy：代理数据库)：独立部署一个代理服务，这个代理服务背后管理多个数据库实例。而在应用中，我们通过一个普通的数据源(c3p0、druid、dbcp等)与代理服务器建立连接，所有的sql操作语句都是发送给这个代理，由这个代理去操作底层数据库，得到结果并返回给应用。在这种方案下，分库分表和读写分离的逻辑对开发人员是完全透明的。典型案例：阿里巴巴开源的cobar，mycat团队在cobar基础上开发的mycat，mysql官方提供的mysql-proxy，奇虎360在mysql-proxy基础开发的atlas。目前除了mycat，其他几个项目基本已经没有维护。
客户端代理(datasource：代理数据源)：应用程序需要使用一个特定的数据源，其作用是代理，内部管理了多个普通的数据源(c3p0、druid、dbcp等)，每个普通数据源各自与不同的库建立连接。应用程序产生的sql交给数据源代理进行处理，数据源内部对sql进行必要的操作，如sql改写等，然后交给各个普通的数据源去执行，将得到的结果进行合并，返回给应用。数据源代理通常也实现了JDBC规范定义的API，因此能够直接与orm框架整合。在这种方案下，用户的代码需要修改，使用这个代理的数据源，而不是直接使用c3p0、druid、dbcp这样的连接池。典型案例：阿里巴巴开源的tddl，大众点评开源的zebra，当当网开源的sharding-jdbc。
本文主要记录如何在springboot中使用ShardingSpehere-ShardingJdbc将mysql数据分片（即分库、分表）

一、数据库环境准备
程序环境：SpringBoot+MyBatis-plus

数据库环境：

IP	
数据库

数据表
127.0.0.1:3306	shardingsphere	user_split_0、user_split_1
127.0.0.1:3306	shardingsphere1	user_split_0、user_split_1
具体如下图所示：



二、引入相关依赖
<!--shardingsphere数据分片、脱敏工具-->
<dependency>
    <groupId>org.apache.shardingsphere</groupId>
    <artifactId>sharding-jdbc-spring-boot-starter</artifactId>
    <version>4.1.0</version>
</dependency>
三、配置数据分片规则
#### spring  ####
spring:
  # 配置说明地址 https://shardingsphere.apache.org/document/legacy/4.x/document/cn/manual/sharding-jdbc/configuration/config-spring-boot/#%E6%95%B0%E6%8D%AE%E5%88%86%E7%89%87
  shardingsphere:
    # 数据库
    datasource:
      # 数据库的别名
      names: ds0,ds1
      # 主库1
      ds0:
        ###  数据源类别
        type: com.alibaba.druid.pool.DruidDataSource
        driverClassName: com.mysql.cj.jdbc.Driver
        url: jdbc:mysql://127.0.0.1:3306/shardingsphere?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&serverTimezone=GMT%2B8
        username: root
        password: 123456
      # 从库1
      ds1:
        ###  数据源类别
        type: com.alibaba.druid.pool.DruidDataSource
        driverClassName: com.mysql.cj.jdbc.Driver
        url: jdbc:mysql://127.0.0.1:3306/shardingsphere1?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&serverTimezone=GMT%2B8
        username: root
        password: 123456

    # *** 数据库分库分表配置 start
    sharding:
      # 默认数据库
      default-data-source-name: ds0
     
      # 水平拆分的数据库（表） 配置分库 + 分表策略 行表达式分片策略
      # 1.默认分库策略 shardingsphere-->ds0 shardingsphere1-->ds1
      default-database-strategy:
        inline:
          sharding-column: user_id
          algorithm-expression: ds$->{user_id % 2}
      # 2.默认分表策略 user_split_0 user_split_1
      default-table-strategy:
        inline:
          sharding-column: age  # 分表策略 其中user为逻辑表 分表主要取决于age行
          algorithm-expression: user_split_$->{age % 2}
      # 数据节点
      tables:
        user:
          actual-data-nodes: ds$->{0..1}.user_split_$->{0..1}
      # *** 数据库分库分表配置 end

#    sharding:
#      # 默认数据库
#      default-data-source-name: ds0
#      default-database-strategy:
#        inline:
#          sharding-column: user_id
#          algorithm-expression: ds$->{user_id % 2}
#      tables:
#        user:
#            #指定user表里面主键id生成策略 雪花算法
#          key-generator:
#            column: user_id
#            type: SNOWFLAKE
#          actual-data-nodes: ds$->{0..1}.user_split_$->{0..1}
#          table-strategy:
#            inline:
#              sharding-column: age
#              algorithm-expression: user_split_$->{age % 2}
#      binding-tables: user

    props:
      # 打印SQL
      sql.show: true
      check:
        table:
          metadata: true
          # 是否在启动时检查分表元数据一致性
          enabled: true
      query:
        with:
          cipher:
            column: true
规则说明：

分库策略：根据用户表的user_id而分库，如果 user_id % 2 = 0 则使用ds0，如果user_id % 2 = 1 则使用ds1；
分表策略：根据用户表的age而分库，如果 age % 2 = 0 则使用user_split_0，如果age % 2 = 1 则使用user_split_1。
其他说明：

关于逻辑表、真实表、数据节点概念参见官方文档
配置文件中分片，属于行表达式分片，实际业务中，可以自己实现官方的接口，实现自己业务需要的分库、分表算法，具体实现的4个接口参见分片。
shardingsphere有四种分片算法，因此shardingsphere提供了4种类型的接口，在sharding-core-api模块下的org.apache.shardingsphere.api.sharding包内，类名为PreciseShardingAlgorithm（精准分片）、RangeShardingAlgorithm（范围分片）、HintShardingAlgorithm（Hint分片）、ComplexKeysShardingAlgorithm（复杂分片）。
shardingsphere分片策略：包含分片键和分片算法，由于分片算法的独立性，将其独立抽离。真正可用于分片操作的是分片键 + 分片算法，也就是分片策略。目前提供5种分片策略。

(1)标准分片策略：对应StandardShardingStrategy。提供对SQL语句中的=, IN和BETWEEN AND的分片操作支持。StandardShardingStrategy只支持单分片键，提供PreciseShardingAlgorithm和RangeShardingAlgorithm两个分片算法。PreciseShardingAlgorithm是必选的，用于处理=和IN的分片。RangeShardingAlgorithm是可选的，用于处理BETWEEN AND分片，如果不配置RangeShardingAlgorithm，SQL中的BETWEEN AND将按照全库路由处理。

(2)复合分片策略：对应ComplexShardingStrategy。复合分片策略。提供对SQL语句中的=, IN和BETWEEN AND的分片操作支持。ComplexShardingStrategy支持多分片键，由于多分片键之间的关系复杂，因此并未进行过多的封装，而是直接将分片键值组合以及分片操作符透传至分片算法，完全由应用开发者实现，提供最大的灵活度。

(3)行表达式分片策略：对应InlineShardingStrategy。使用Groovy的表达式，提供对SQL语句中的=和IN的分片操作支持，只支持单分片键。对于简单的分片算法，可以通过简单的配置使用，从而避免繁琐的Java代码开发，如: t_user_$->{u_id % 8} 表示t_user表根据u_id模8，而分成8张表，表名称为t_user_0到t_user_7。

(4)Hint分片策略：对应HintShardingStrategy。通过Hint而非SQL解析的方式分片的策略。

(5)不分片策略：对应NoneShardingStrategy。不分片的策略。

 

四、测试分片结果
（1）user_id=100，age=18 (100%2=0 ,使用ds0;18%2=0,使用user_split_0)


（2）user_id=101，age=18 (101%2=1 ,使用ds1;18%2=0,使用user_split_0)


（3）user_id=102，age=17 (102%2=0 ,使用ds0;17%2=1,使用user_split_1）


（4）查询结果


当查询的时候，如果条件是根据分片键查询，那么最终定位到某一个库的某一个表，如果条件中没有分片键，则会进行全路由，也就是四个库都查

ShardingSphere-jdbc为我们做了，根据配置的分片策略，进行 SQL解析 => 执行器优化 => SQL路由 => SQL改写 => SQL执行 => 结果归并 工作。具体文档见内核剖析

官方原文：https://shardingsphere.apache.org/document/legacy/4.x/document/cn/manual/sharding-jdbc/usage/sharding/

源码传送门：https://github.com/oycyqr/springboot-learning-demo/tree/master/springboot-shardingsphere-split