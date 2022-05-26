# [Jira & Confluence部署](https://segmentfault.com/a/1190000039264694)

[![img](Jira & Confluence部署 - SegmentFault 思否.assets/3179314346-5f61e47221e07.png)**已注销**](https://segmentfault.com/u/jjlaaa)发布于 2 月 23 日

![img](Jira & Confluence部署 - SegmentFault 思否.assets/lg.phpbannerid=0&campaignid=0&zoneid=25&loc=https%3A%2F%2Fsegmentfault.com%2Fa%2F1190000039264694&referer=https%3A%2F%2Fsegmentfault.com%2Fa%2F1190000039264694&cb=e049a19797)

# Jira & Confluence 服务部署

# 1. Jira安装配置

## 1.1 Jira简介

JIRA是Atlassian公司出品的项目与事务跟踪工具，被广泛应用于缺陷跟踪、客户服务、需求收集、流程审批、任务跟踪、项目跟踪和敏捷管理等工作领域，其配置灵活、功能全面、部署简单、扩展丰富

## 1.2 Jira破解镜像制作

- 破解crack来源：[Gitee atlassian-agent](https://link.segmentfault.com/?url=https%3A%2F%2Fgitee.com%2Fpengzhile%2Fatlassian-agent)，理论上可用于破解所有版本的Atlassian家几乎所有产品，但是只验证了特定的版本（Jira Docker Image 7.12.0）

编写Dockerfile

```bash
mkdir -p /opt/jira
echo '
FROM cptactionhank/atlassian-jira-software:7.12.0
USER root 
COPY "atlassian-agent.jar" /opt/atlassian/jira/ 
RUN echo 'export CATALINA_OPTS="-javaagent:/opt/atlassian/jira/atlassian-agent.jar ${CATALINA_OPTS}"' >> /opt/atlassian/jira/bin/setenv.sh ' > /opt/jira/Dockerfile
```

下载[atlassian-agent.jar](https://link.segmentfault.com/?url=https%3A%2F%2Fgitee.com%2Fpengzhile%2Fatlassian-agent%2Freleases)文件到Dockerfile同目录

构建镜像

```apache
docker build -t jira/jira:v7.12.0 .
```

## 1.3 配置MySQL数据库

准备MySQL配置文件

```bash
echo '
[client]
default-character-set = utf8
[mysql]
default-character-set = utf8
[mysqld]
character-set-server=utf8
innodb_log_file_size=3G
character_set_server = utf8mb4
innodb_default_row_format=DYNAMIC
innodb_large_prefix=ON
#innodb_file_format=Barracud
default-storage-engine=INNODB ' > /opt/jira/my.cnf 
```

启动MySQL容器

```bash
docker run \ 
--name mysqlForJira \ 
--restart always \ 
-p ${port}:3306 \ 
-v /opt/jira/mysql/:/var/lib/mysql \ 
-v /opt/jira/my.cnf:/etc/mysql/my.cnf \ 
-e MYSQL_ROOT_PASSWORD=${password} \
-d mysql:5.7
```

创建表和用户

```sql
create database jira character set 'UTF8';
create user jira identified by 'jira';
grant all privileges on `jira`.* to 'jira'@'172.%' identified by 'jira' with grant option;
grant all privileges on `jira`.* to 'jira'@'localhost' identified by 'jira' with grant option;
flush privileges;
```

## 1.4 Jira容器生成

```bash
docker run --name jira \
--restart always \
--link mysqlForJira:mysql \
--link confluence:confluence \
-p ${port}:8080 \
-v /opt/jira/var/:/var/atlassian/jira \
-v /opt/jira/opt:/opt/atlassian/jira \
-d jira/jira:v7.12.0
```

## 1.5 Jira破解配置

访问http://127.0.0.1:${port}，进入Jira setup wizard ,进行初始化配置

- 手动设置项目
- 选择配置独立数据库

制定许可证关键字：

- 复制**服务器ID**
- 在本地存放atlassian-agent.jar目录下执行

```bash
java -jar atlassian-agent.jar -d -m ${email} -n ${company_name} -p jira -o ${jira_url} -s ${服务器ID}
```

将生成的许可证复制到页面，完成破解

# 2 Confluence安装配置

## 2.1 Confluence简介

Confluence是一个专业的企业知识管理与协同软件，也可以用于构建企业wiki。使用简单，但它强大的编辑和站点管理特征能够帮助团队成员之间共享信息、文档协作、集体讨论，信息推送。

## 2.2 Confluence破解镜像制作

- 破解crack来源：[Gitee atlassian-agent](https://link.segmentfault.com/?url=https%3A%2F%2Fgitee.com%2Fpengzhile%2Fatlassian-agent)，理论上可用于破解所有版本的Atlassian家几乎所有产品，但是只验证了特定的版（Confluence Docker Image 6.13.0）

编写Dockerfile

```bash
mkdir -p /opt/confluence
echo 'FROM cptactionhank/atlassian-confluence:6.13.0
USER root
COPY "atlassian-agent.jar" /opt/atlassian/confluence/
RUN echo 'export CATALINA_OPTS="-javaagent:/opt/atlassian/confluence/atlassian-agent.jar ${CATALINA_OPTS}"' >> /opt/atlassian/confluence/bin/setenv.sh' >> /opt/confluence/Dockerfile
```

下载[atlassian-agent.jar](https://link.segmentfault.com/?url=https%3A%2F%2Fgitee.com%2Fpengzhile%2Fatlassian-agent%2Freleases)文件到Dockerfile同目录

构建镜像

```bash
docker build -f Dockerfile -t confluence/confluence:6.13.0 .
```

## 2.3 配置MySQL数据库

准备MySQL配置文件

```bash
mkdir -p /opt/confluence/mysql
echo '[client]
default-character-set =utf8
[mysql]
default-character-set =utf8
[mysqld]
character_set_server =utf8
collation-server=utf8_bin
max_allowed_packet=256M
innodb_log_file_size=256M
default-storage-engine=INNODB
transaction-isolation=READ-COMMITTED
binlog_format=row ' > /opt/confluence/my.cnf 
```

启动MySQL容器

```bash
docker run \
--name mysqlForConfluence \
--restart always \
-p ${port}:3306 \
-v /opt/confluence/mysql/:/var/lib/mysql \
-v /opt/confluence/my.cnf:/etc/mysql/my.cnf \
-e MYSQL_ROOT_PASSWORD=${password} \
-d mysql:5.7
```

创建表和用户

```sql
create database confluence character set 'UTF8';
create user confluence identified by 'confluence';
grant all privileges on `confluence`.* to 'confluence'@'%' identified by 'confluence' with grant option;
grant all privileges on `confluence`.* to 'confluence'@'localhost' identified by 'confluence' with grant option;
flush privileges;
alter database confluence character set utf8 collate utf8_bin;
set global tx_isolation='READ-COMMITTED';
```

## 2.4 Confluence容器生成

```bash
docker run --name confluence \
--restart always \
--link mysqlForConfluence:mysql \
--link jira:jira \
-p ${port}:8090 \
-v /opt/confluence/data/:/home/confluence_data \
-v /opt/confluence/opt/:/opt/atlassian/confluence \
-v /opt/confluence/var/:/var/atlassian/confluence \
-d confluence/confluence:6.13.0
```

## 2.5 Confluence破解配置

访问http://127.0.0.1:${port}，进入Jira setup wizard ,进行初始化配置

- 手动设置项目
- 选择配置独立数据库

制定许可证关键字：

- 复制服务器ID
- 在本地存放atlassian-agent.jar目录下执行

```bash
java -jar atlassian-agent.jar -d -m ${email} -n ${company_name} -p conf -o ${jira_url} -s ${服务器ID}
```

将生成的许可证复制到页面，完成破解

# 3 参考

- [What is Jira used for?](https://link.segmentfault.com/?url=https%3A%2F%2Fwww.atlassian.com%2Fsoftware%2Fjira%2Fguides%2Fuse-cases%2Fwhat-is-jira-used-for)
- [通过Docker安装破解版Jira与Confluence](https://link.segmentfault.com/?url=https%3A%2F%2Fmy.oschina.net%2Fwuweixiang%2Fblog%2F3014644)
- [Docker安装破解版Jira与Confluence](https://link.segmentfault.com/?url=https%3A%2F%2Fwww.jianshu.com%2Fp%2Fb95ceabd3e9d)