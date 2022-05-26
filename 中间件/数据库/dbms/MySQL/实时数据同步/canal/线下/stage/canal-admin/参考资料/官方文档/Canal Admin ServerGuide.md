# Canal Admin ServerGuide

agapple edited this page on 20 Aug 2020 · [2 revisions](https://github.com/alibaba/canal/wiki/Canal-Admin-ServerGuide/_history)

# 背景

canal-admin设计上是为canal提供整体配置管理、节点运维等面向运维的功能，提供相对友好的WebUI操作界面，方便更多用户快速和安全的操作

# 准备

首先确保你先完成了canal-admin的基本部署和运维指南，请参考:

1. [Canal Admin QuickStart](https://github.com/alibaba/canal/wiki/Canal-Admin-QuickStart)
2. [Canal Admin Guide](https://github.com/alibaba/canal/wiki/Canal-Admin-Guide)

# 设计理念

引入了canal-admin之后，canal-server之前面向命令行的运维方式需要有一些变化，主要的变化在于配置体系上，每个server节点上不应该再去维护复杂而且冗长的canal.properties/instance.properties，应该选择以最小化、无状态的方式去启动，因此在canal 1.1.4上，对于配置做了一些重构来支持canal-admin，同时也兼容了原先的命令行运维模式.

## 变化点

1. 引入canal_local.properties，针对canal-server启动所需要的配置，做了最小化配置，只需要关注和admin请求的必要参数即可

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

### 面向user/passwd的安全ACL机制

针对canal.admin.passwd，这里默认做了密码加密处理，这里的passwd是一个密文，和canal-admin里application.yml里的密码原文做对应.

密文的生成方式，请登录mysql，执行如下密文生成sql即可(记得去掉第一个首字母的星号)

```
select password('admin')

+-------------------------------------------+
| password('admin')                         |
+-------------------------------------------+
| *4ACFE3202A5FF5CF467898FC58AAB1D615029441 |
+-------------------------------------------+
```

请注意几点：

1. 这个密码方式，同样对于canal.user.passwd有效 (1.1.4新增的，用于控制用户访问canal-server的订阅binlog的ACL机制)
2. canal.admin.user/canal.admin.passwd，这是一个双向认证，canal-server会以这个密文和canal-admin做请求，同时canal-admin也会以密码原文生成加密串后和canal-server进行admin端口链接，所以这里一定要确保这两个密码内容的一致性

### 面向容器无状态的运维

server的信息维护除了在canal-admin上基于WebUI的操作以外，还有更加方便的auto register机制，主要针对面向容器化之后可以通过扩容节点，自动完成集群配置的维护和instance分流

```
# 是否开启自动注册模式
canal.admin.register.auto = true
# 可以指定默认注册的集群名，如果不指定，默认注册为单机模式
canal.admin.register.cluster = 
```

配置状态化清理

1. canal.properties里的canal.id，目前已经废弃为基于canal.registerIp + canal.adminPort作为唯一标识，请求canal-admin来获取配置
2. instance.properties里的canal.instance.mysql.slaveId，这个在canal 1.0.26版本之后就已变更为随机生成，确保HA模式下slaveId的唯一性

# 启动

目前conf下会包含canal.properties/canal_local.properties两个文件，考虑历史版本兼容性，默认配置会以canal.properties为主，如果要启动为对接canal-admin模式，可以有两种方式

1. 指定为local配置文件

```
sh bin/startup.sh local
```

1. 变更默认配置，比如删除canal.properties，重命名canal_local.properties为canal.properties