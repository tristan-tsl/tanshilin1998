[ShardingSphere](https://shardingsphere.apache.org/document/legacy/4.x/document/cn/) > [用户手册](https://shardingsphere.apache.org/document/legacy/4.x/document/cn/manual/) > Sharding-Proxy

[简介](https://shardingsphere.apache.org/document/legacy/4.x/document/cn/manual/sharding-proxy/#简介)[对比](https://shardingsphere.apache.org/document/legacy/4.x/document/cn/manual/sharding-proxy/#对比)

## 简介

Sharding-Proxy是ShardingSphere的第二个产品。 它定位为透明化的数据库代理端，提供封装了数据库二进制协议的服务端版本，用于完成对异构语言的支持。 目前先提供MySQL/PostgreSQL版本，它可以使用任何兼容MySQL/PostgreSQL协议的访问客户端(如：MySQL Command Client, MySQL Workbench, Navicat等)操作数据，对DBA更加友好。

- 向应用程序完全透明，可直接当做MySQL/PostgreSQL使用。
- 适用于任何兼容MySQL/PostgreSQL协议的的客户端。

[![Sharding-Proxy Architecture](Sharding-Proxy  ShardingSphere.assets/sharding-proxy-brief_v2.png)](https://shardingsphere.apache.org/document/legacy/4.x/document/img/sharding-proxy-brief_v2.png)

## 对比

|            | *Sharding-JDBC* | *Sharding-Proxy*   | *Sharding-Sidecar* |
| :--------- | :-------------- | :----------------- | :----------------- |
| 数据库     | 任意            | `MySQL/PostgreSQL` | MySQL/PostgreSQL   |
| 连接消耗数 | 高              | `低`               | 高                 |
| 异构语言   | 仅Java          | `任意`             | 任意               |
| 性能       | 损耗低          | `损耗略高`         | 损耗低             |
| 无中心化   | 是              | `否`               | 是                 |
| 静态入口   | 无              | `有`               | 无                 |

Sharding-Proxy的优势在于对异构语言的支持，以及为DBA提供可操作入口。