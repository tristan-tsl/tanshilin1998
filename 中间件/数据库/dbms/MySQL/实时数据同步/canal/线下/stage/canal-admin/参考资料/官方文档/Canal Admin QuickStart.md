# Canal Admin QuickStart

rewerma edited this page on 3 Sep 2019 · [8 revisions](https://github.com/alibaba/canal/wiki/Canal-Admin-QuickStart/_history)

## 背景

canal-admin设计上是为canal提供整体配置管理、节点运维等面向运维的功能，提供相对友好的WebUI操作界面，方便更多用户快速和安全的操作

## 准备

canal-admin的限定依赖：

1. MySQL，用于存储配置和节点等相关数据
2. canal版本，要求>=1.1.4 (需要依赖canal-server提供面向admin的动态运维管理接口)

## 部署

1. 下载 canal-admin, 访问 release 页面 , 选择需要的包下载, 如以 1.1.4 版本为例

```
wget https://github.com/alibaba/canal/releases/download/canal-1.1.4/canal.admin-1.1.4.tar.gz
```

1. 解压缩

```
mkdir /tmp/canal-admin
tar zxvf canal.admin-$version.tar.gz  -C /tmp/canal-admin
```

解压完成后，进入 /tmp/canal 目录，可以看到如下结构

```
drwxr-xr-x   6 agapple  staff   204B  8 31 15:37 bin
drwxr-xr-x   8 agapple  staff   272B  8 31 15:37 conf
drwxr-xr-x  90 agapple  staff   3.0K  8 31 15:37 lib
drwxr-xr-x   2 agapple  staff    68B  8 31 15:26 logs
```

1. 配置修改

```
vi conf/application.yml
server:
  port: 8089
spring:
  jackson:
    date-format: yyyy-MM-dd HH:mm:ss
    time-zone: GMT+8

spring.datasource:
  address: 127.0.0.1:3306
  database: canal_manager
  username: canal
  password: canal
  driver-class-name: com.mysql.jdbc.Driver
  url: jdbc:mysql://${spring.datasource.address}/${spring.datasource.database}?useUnicode=true&characterEncoding=UTF-8&useSSL=false
  hikari:
    maximum-pool-size: 30
    minimum-idle: 1

canal:
  adminUser: admin
  adminPasswd: admin
```

1. 初始化元数据库

```
mysql -h127.1 -uroot -p

# 导入初始化SQL
> source conf/canal_manager.sql
```

a. 初始化SQL脚本里会默认创建canal_manager的数据库，建议使用root等有超级权限的账号进行初始化 b. canal_manager.sql默认会在conf目录下，也可以通过链接下载 [canal_manager.sql](https://raw.githubusercontent.com/alibaba/canal/master/canal-admin/canal-admin-server/src/main/resources/canal_manager.sql)

1. 启动

```
sh bin/startup.sh
```

查看 admin 日志

```
vi logs/admin.log

2019-08-31 15:43:38.162 [main] INFO  o.s.boot.web.embedded.tomcat.TomcatWebServer - Tomcat initialized with port(s): 8089 (http)
2019-08-31 15:43:38.180 [main] INFO  org.apache.coyote.http11.Http11NioProtocol - Initializing ProtocolHandler ["http-nio-8089"]
2019-08-31 15:43:38.191 [main] INFO  org.apache.catalina.core.StandardService - Starting service [Tomcat]
2019-08-31 15:43:38.194 [main] INFO  org.apache.catalina.core.StandardEngine - Starting Servlet Engine: Apache Tomcat/8.5.29
....
2019-08-31 15:43:39.789 [main] INFO  o.s.w.s.m.m.annotation.ExceptionHandlerExceptionResolver - Detected @ExceptionHandler methods in customExceptionHandler
2019-08-31 15:43:39.825 [main] INFO  o.s.b.a.web.servlet.WelcomePageHandlerMapping - Adding welcome page: class path resource [public/index.html]
```

此时代表canal-admin已经启动成功，可以通过 http://127.0.0.1:8089/ 访问，默认密码：admin/123456 ![img](https://camo.githubusercontent.com/c9f9671ee6fb639a6044528229a64875fa0d1a16ca8b138a24be60212b181380/687474703a2f2f646c322e69746579652e636f6d2f75706c6f61642f6174746163686d656e742f303133322f323330342f34343663373761362d643839312d333634302d623636342d3335343030326632346334372e706e67)

1. 关闭

```
sh bin/stop.sh
```

1. canal-server端配置

使用canal_local.properties的配置覆盖canal.properties

```
# register ip
canal.register.ip =

# canal admin config
canal.admin.manager = 127.0.0.1:8089
canal.admin.port = 11110
canal.admin.user = admin
canal.admin.passwd = 4ACFE3202A5FF5CF467898FC58AAB1D615029441
# admin auto register
canal.admin.register.auto = true
canal.admin.register.cluster =
```

启动admin-server即可。

或在启动命令中使用参数：sh bin/startup.sh local 指定配置

just have fun!