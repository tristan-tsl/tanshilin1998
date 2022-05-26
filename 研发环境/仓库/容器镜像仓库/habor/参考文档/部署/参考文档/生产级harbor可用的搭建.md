## **生产级harbor可用的搭建**

## **Harbor简介**

**[Harbor](https://link.zhihu.com/?target=https%3A//goharbor.io/)**是一个用于存储和分发`Docker镜像`的企业级`Registry`服务器，通过添加一些企业必需的功能特性，例如安全、标识和管理等，扩展了开源Docker Distribution。

![img](生产级harbor可用的搭建.assets/v2-1a089b10378dbef172c88bb402d725b0_720w.jpg)

作为一个企业级私有Registry服务器，Harbor提供了更好的性能和安全。

提升用户使用Registry构建和运行环境传输镜像的效率。

Harbor支持安装在多个Registry节点的镜像资源复制，镜像全部保存在私有Registry中， 确保数据和知识产权在公司内部网络中管控。

另外，Harbor也提供了高级的安全特性，诸如用户管理，访问控制和活动审计等。

## **高可用架构：双主复制**

### **主从同步**

harbor官方默认提供主从复制的方案来解决镜像同步问题，通过复制的方式，我们可以实时将测试环境harbor仓库的镜像同步到生产环境harbor，类似于如下流程：

![img](生产级harbor可用的搭建.assets/v2-8f65be6065773702c1b052947ec1e8f5_720w.jpg)

在实际生产运维的中，往往需要把镜像发布到几十或上百台集群节点上。这时，单个Registry已经无法满足大量节点的下载需求，因此要配置多个Registry实例做负载均衡。手工维护多个Registry实例上的镜像，将是十分繁琐的事情。Harbor可以支持一主多从的镜像发布模式，可以解决大规模镜像发布的难题：

![img](生产级harbor可用的搭建.assets/v2-1326470a10c56916dc0768bf9c56d2c4_720w.jpg)

只要往一台Harbor上发布，镜像就会像"仙女散花"般地同步到多个Registry中，高效可靠。

如果是地域分布较广的集群，还可以采用层次型发布方式，比如从集团总部机房同步到分公司1机房，再从分公司1机房同步到分公司2机房：

![img](生产级harbor可用的搭建.assets/v2-555dba23e57930a637a8b2832d3e4314_720w.jpg)

然而单靠主从同步，仍然解决不了harbor主节点的单点问题。

### **双主复制说明**

所谓的双主复制其实就是复用主从同步实现两个harbor节点之间的双向同步，来保证数据的一致性，然后在两台harbor前端顶一个负载均衡器将进来的请求分流到不同的实例中去，只要有一个实例中有了新的镜像，就是自动的同步复制到另外的的实例中去，这样实现了负载均衡，也避免了单点故障，在一定程度上实现了Harbor的高可用性：

![img](生产级harbor可用的搭建.assets/v2-dcac7fed1193e1335a630a243b1abbf8_720w.jpg)

这个方案有一个问题就是有可能两个Harbor实例中的数据不一致。假设如果一个实例A挂掉了，这个时候有新的镜像进来，那么新的镜像就会在另外一个实例B中，后面即使恢复了挂掉的A实例，Harbor实例B也不会自动去同步镜像，这样只能手动的先关掉Harbor实例B的复制策略，然后再开启复制策略，才能让实例B数据同步，让两个实例的数据一致。

另外，这里还需要多吐槽一句：**在实际生产使用中，主从复制十分的不靠谱！！所以这里推荐使用下面要说的这种方案**。

## **高可用架构：多实例共享后端存储**

### **方案说明**

共享后端存储算是一种比较标准的方案，就是多个Harbor实例共享同一个后端存储，任何一个实例持久化到存储的镜像，都可被其他实例中读取。通过前置LB进来的请求，可以分流到不同的实例中去处理，这样就实现了负载均衡，也避免了单点故障。

本次搭建以NFS作为共享存储存放Harbor相关data，并分离PostgreSQL与Redis为多个Harbor共同连接使用，使用Nginx做负载均衡。

![img](生产级harbor可用的搭建.assets/v2-101e317527c6efa64d150f2e1c631ece_720w.jpg)

如果最终生产环境集群中服务器较多，依赖做完LB的Harbor也无法完全达到需求时，可以使用如下架构，部署下级Harbor节点从主节点同步镜像，然后再分发给生产服务器。

![img](生产级harbor可用的搭建.assets/v2-af6fe945b1386aafeb23d78f6a20e23b_720w.jpg)

这个方案在实际生产环境中部署需要考虑三个问题：

**1.** 共享存储的选取，Harbor的后端存储目前支持AWS S3、Openstack Swift, Ceph等，在下面的实验环境里，暂且直接使用nfs。

**2.** Session在不同的实例上共享，这个现在其实已经不是问题了，在最新的harbor中，默认session会存放在redis中，只需要将redis独立出来即可。可以通过redis sentinel或者redis cluster等方式来保证redis的可用性。在下面的实验环境里，暂且使用单台redis。

**3.** Harbor多实例数据库问题，这个也只需要将harbor中的数据库拆出来独立部署即可。让多实例共用一个外部数据库，数据库的高可用也可以通过数据库的高可用方案保证。

### **环境说明**

- 操作系统：`CentOS 7.6`
- 演示环境软件版本

| 软件 | 版本 |
| ---- | ---- |
|      |      |

- 演示环境网络

这里主要做Harbor高可用演示，真实生产环境请按需分离NFS与DB单独部署。

| IP   | 主机名 |
| ---- | ------ |
|      |        |

## **多实例共享后端存储部署**

### **Docker**

1）安装依赖包：

```text
yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2
```

2）官方一键脚本安装

```text
curl -fsSL get.docker.com -o get-docker.sh
sh get-docker.sh --mirror Aliyun
```

3）添加内核参数

```text
tee -a /etc/sysctl.conf <<-EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
```

将`net.ipv4.ip_forward`赋值为`1`

然后刷新内核参数

```text
sysctl -p
```

4）修改Docker仓库为国内镜像站

```text
curl -sSL https://get.daocloud.io/daotools/set_mirror.sh | sh -s https://pclhthp0.mirror.aliyuncs.com
```

5）启动Docker

```text
systemctl enable docker && systemctl start docker
```

### **Compose**

**[compose](https://link.zhihu.com/?target=https%3A//github.com/docker/compose/releases)**是Docker提供的一个命令行工具，用来定义和运行由多个容器组成的应用。使用compose，我们可以通过YAML文件声明式的定义应用程序的各个服务，并由单个命令完成应用的创建和启动。

由于国内政策原因，可能在海外网站上下载文件速度较慢，建议下载本地后上传至服务器

1）下载`docker-compose`并赋予可执行权限

```text
# curl -L https://github.com/docker/compose/releases/download/1.24.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
# chmod +x /usr/local/bin/docker-compose

cd /usr/local/bin
scp 192.168.166.96:/usr/local/bin/docker-compose .
```

> “ 注意：由于我其他服务器已经存在，所以我直接拷贝了

2）安装bash补全命令

```text
# curl -L https://raw.githubusercontent.com/docker/compose/1.24.1/contrib/completion/bash/docker-compose > /etc/bash_completion.d/docker-compose

scp 192.168.166.96:/etc/bash_completion.d/docker-compose /etc/bash_completion.d/
```

重新连接终端即生效

> “ 注意：由于我其他服务器已经存在，所以我直接拷贝了

### **NFS**

### **服务端**

1）安装必需的RPM包

```text
yum -y install nfs-utils rpcbind   
```

2）创建NFS共享目录

```text
mkdir -p /data/harbor_data
chown nobody:nobody /data/harbor_data/ 
```

3）修改NFS服务配置文件

```text
echo "/data/harbor_data 192.168.166.0/24(rw,sync,no_root_squash)"  >> /etc/exports
```

4）启动NFS服务器

```text
systemctl enable rpcbind && systemctl restart rpcbind
systemctl enable nfs && systemctl restart nfs
```

### **客户端**

1）安装nfs-utils

```text
yum -y install nfs-utils
```

2）在NFS客户端上查看NFS的连通性

```text
# showmount -e 192.168.166.122
Export list for 192.168.166.122:
/data/harbor_data 192.168.166.0/24
```

3）挂载NFS共享存储

创建挂载目录

```text
mkdir /data
```

修改/etc/fstab配置文件加入以下内容

```text
192.168.166.122:/data/harbor_data  /data  nfs defaults 0 0
```

mount挂载

```text
mount -a
```

### **PostgreSQL**

1）下载PostgreSQL官方YUM源配置文件包并安装

```text
wget https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
rpm -ivh pgdg-redhat-repo-latest.noarch.rpm 
```

2）安装PostgreSQL

```text
yum  -y install postgresql96-server postgresql96-contrib 
```

3）初始化数据库

```text
/usr/pgsql-9.6/bin/postgresql96-setup initdb  
```

4）启动数据库

```text
systemctl enable postgresql-9.6 && systemctl restart postgresql-9.6
```

5）PostgreSQL数据库配置

1. 修改密码

```text
# su - postgres
-bash-4.2$ psql
psql (9.6.17)
Type "help" for help.
postgres=# ALTER USER postgres WITH PASSWORD 'postgres';
ALTER ROLE
```

1. 开启远程访问

```text
vi /var/lib/pgsql/9.6/data/postgresql.conf

# listen_addresses = 'localhost' 改为 listen_addresses='*'
```

1. 信任远程连接

```
vim /var/lib/pgsql/9.6/data/pg_hba.conf
```

加入:

```text
host    all  all  192.168.166.203/32 trust
host    all  all  192.168.166.81/32 trust
host    all  all  192.168.166.212/32 trust
```

6）重启PostgreSQL服务

```text
systemctl restart postgresql-9.6
```

7）验证服务

```text
psql -h 192.168.166.203 -p 5432 -U postgres
```

8）迁移数据库

1. 在postgresql所在服务器，先启动一套harbor环境

简要步骤如下：

```text
# yum install -y yum-utils   device-mapper-persistent-data   lvm2
# curl -fsSL get.docker.com -o get-docker.sh
# sh get-docker.sh --mirror Aliyun
#curl -sSL https://get.daocloud.io/daotools/set_mirror.sh | sh -s https://pclhthp0.mirror.aliyuncs.com
# systemctl enable docker && systemctl start docker
# cd /usr/local/bin
# scp 192.168.166.96:/usr/local/bin/docker-compose .
# scp 192.168.166.96:/etc/bash_completion.d/docker-compose /etc/bash_completion.d/
# cd ~
# scp 192.168.166.96:/root/harbor-offline-installer-v1.10.2.tgz .
# tar -xvf harbor-offline-installer-v1.10.2.tgz -C /usr/local/
# cd /usr/local/harbor/
# vim harbor.yml ###修改hostname: 192.168.166.203  ####注释掉https段即可
# ./prepare 
# ./install.sh 
# docker-compose up -d
```

1. 进入harbor-db容器导出相关表及数据

```text
# docker container exec -it harbor-db /bin/bash
pg_dump -U postgres registry > /tmp/registry.sql 
pg_dump -U postgres notarysigner > /tmp/notarysigner.sql  
pg_dump -U postgres notaryserver > /tmp/notaryserver.sql
```

1. 导出数据库

```text
docker container cp harbor-db:/tmp/registry.sql /tmp
docker container cp harbor-db:/tmp/notarysigner.sql /tmp
docker container cp harbor-db:/tmp/notaryserver.sql /tmp
```

1. 将数据导入至外部PostgreSQL数据库

```text
# psql -h 192.168.166.203 -U postgres
postgres=# create database registry;
CREATE DATABASE
postgres=# create database notarysigner;
CREATE DATABASE
postgres=# create database notaryserver;
CREATE DATABASE

psql -h 192.168.166.203 -U postgres registry < /tmp/registry.sql
psql -h 192.168.166.203 -U postgres notarysigner  < /tmp/notarysigner.sql
psql -h 192.168.166.203 -U postgres notaryserver < /tmp/notaryserver.sql
```

### **Redis**

1）安装redis

```text
yum -y install redis
```

2） 修改配置参数

```text
sed -i 's/bind 127.0.0.1/bind 0.0.0.0/g' /etc/redis.conf   
sed -i 's/daemonize no/daemonize yes/g' /etc/redis.conf   
```

3）启动并测试redis连接

```text
systemctl enable redis && systemctl restart redis
redis-cli 
```

### **Harbor**

下载**[Harbor](https://link.zhihu.com/?target=https%3A//github.com/goharbor/harbor/releases)**离线安装包，离线安装包文件较大（约为：590M），建议在本地使用多线程工具下载后上传服务器使用。

1）下载

```text
cd ~
scp 192.168.166.96:/root/harbor-offline-installer-v1.10.2.tgz .
```

2）解压

```text
tar -xvf harbor-offline-installer-v1.10.2.tgz -C /usr/local/
```

3）修改配置文件

```text
# cd /usr/local/harbor/
# vim harbor.yml 
```

修改的内容有

- `hostname`修改为本机ip
- 注释掉https
- 修改harbor默认的admin账号密码
- 数据存储位置，改为nfs挂载目录，因为我们本来就挂载到了`/data`目录下，所以不用动
- 注释掉`database`
- 注释掉`clair`
- 打开`external_database`和`external_redis`块的注释，并改为刚刚部署的地址

修改完的样例文件，如下

```text
hostname: 192.168.166.81
http:
  port: 80
harbor_admin_password: Harbor12345
data_volume: /data
jobservice:
  max_job_workers: 10
notification:
  webhook_job_max_retry: 10
chart:
  absolute_url: disabled
log:
  level: info
  local:
    rotate_count: 50
    rotate_size: 200M
    location: /var/log/harbor
_version: 1.10.0
external_database:
  harbor:
    host: 192.168.166.203
    port: 5432
    db_name: registry
    username: postgres
    password: postgres
    ssl_mode: disable
    max_idle_conns: 2
    max_open_conns: 0
  clair:
    host: 192.168.166.203
    port: 5432
    db_name: clair
    username: postgres
    password: postgres
    ssl_mode: disable
  notary_signer:
    host: 192.168.166.203
    port: 5432
    db_name: notarysigner
    username: postgres
    password: postgres
    ssl_mode: disable
  notary_server:
    host: 192.168.166.203
    port: 5432
    db_name: notaryserver
    username: postgres
    password: postgres
    ssl_mode: disable
external_redis:
  host: 192.168.166.245
  port: 6379
  password:
  registry_db_index: 1
  jobservice_db_index: 2
  chartmuseum_db_index: 3
  clair_db_index: 4
proxy:
  http_proxy:
  https_proxy:
  no_proxy:
  components:
    - core
    - jobservice
    - clair
```

4）生成harbor运行的必要文件（环境）以及`docker-compose.yml`文件；执行后会通过网络获取Docker Image，建议提前修改好国内镜像站加速。

```text
./prepare 
```

5）安装Harbor

```text
./install.sh 
```

### **Nginx**

1）安装nginx

安装可以参考[https://wiki.clay-wangzhi.com/7-nginx/1.-chu-shi-nginx#4-bian-yi-an-zhuang-nginx](https://link.zhihu.com/?target=https%3A//wiki.clay-wangzhi.com/7-nginx/1.-chu-shi-nginx%234-bian-yi-an-zhuang-nginx)

这里我就不再详细讲了

2）编写配置文件

```text
# cat harbor.schengle.com.conf 
upstream harbor {
    ip_hash;
    server 192.168.166.81:80;
    server 192.168.166.212:80;
}
server {
    listen       80;
    server_name  harbor.***.com;
    rewrite ^(.*) https://$server_name$1 permanent;
}
server {
    listen  443 ssl;
    server_name harbor.schengle.com;
    
    ssl_certificate ***.crt;
    ssl_certificate_key ***.key;
    client_max_body_size 0;
    chunked_transfer_encoding on;

    location / {
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        #proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto https;
        proxy_redirect off;
        proxy_ssl_verify off;
        proxy_ssl_session_reuse on;
        proxy_pass http://harbor;
		proxy_redirect default;
        proxy_http_version 1.1;
}
    location /v2/ {
        proxy_pass http://harbor/v2/;
		proxy_redirect default;
        #proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_ssl_verify off;
        proxy_ssl_session_reuse on;
        proxy_buffering off;
        proxy_request_buffering off;
    }
}
```

3）平滑重启nginx

```text
nginx -s reload
```

## **参考文章**

> “ [https://www.cnblogs.com/kevingrace/p/11422710.html](https://link.zhihu.com/?target=https%3A//www.cnblogs.com/kevingrace/p/11422710.html)
> [https://juejin.im/post/5d973e246fb9a04dfa0963fb#heading-18](https://link.zhihu.com/?target=https%3A//juejin.im/post/5d973e246fb9a04dfa0963fb%23heading-18)
> [http://dwz-9.cn/_L4me](https://link.zhihu.com/?target=http%3A//dwz-9.cn/_L4me)

发布于 01-24

[Harbor](https://www.zhihu.com/topic/20229690)

[服务器](https://www.zhihu.com/topic/19554575)

[Docker](https://www.zhihu.com/topic/19950993)