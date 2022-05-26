# Linux下文件实时自动同步备份

[![img](Linux下文件实时自动同步备份.assets/webp.webp)](https://www.jianshu.com/u/51edaa188222)

[程序员大佬超](https://www.jianshu.com/u/51edaa188222)关注

82020.03.13 11:33:22字数 2,109阅读 9,060

### 前言

我们都知道一旦 Linux 系统被入侵了，或者 Linux 系统由于硬件关系而死机，如何快速恢复系统呢？当然，如果有备份数据的话，那么恢复系统所花费的时间与成本将会很少。平时最好就养成备份的习惯，可以避免发生突发事件时束手无策。

本篇文章将对 Linux 主机之间**文件实时自动同步备份**进行讲解，使用 **rsync+inotify** 组合的方式来实现，避免由于硬件或者软件导致的 Linux 系统死机或损坏造成的损失。

### 文章重点

1、rsync+inotify 简介
2、整体架构
3、同步节点部署（rsync）
4、源服务器节点部署（rsync+inotify）
5、实时同步备份验证
6、遇到的问题及解决方法

------

### 一、rsync+inotify 简介

#### 1、rsync简介

rsync（remote synchronize）是 Liunx/Unix 下的一个远程数据同步工具，它可通过 LAN/WAN 快速同步多台主机间的文件和目录。

Linux 之间同步文件一般有两种方式，分别是 **rsync** 与 **scp** 。scp 相当于复制，粘贴，文件不存在则新建，若存在则覆盖，而 rsync 则是比较两边文件是否相同，不相同才进行更新。所以 rsync 和 scp 在文件夹存在的情况下差异很大，因为 scp 是复制和覆盖，从执行性能来说 rsync 更胜一筹。而且 rsync 能将文件夹、文件的权限等信息也保存下来。

但是 rsync 也有一定的缺点，在同步数据时，需要扫描所有文件后进行比对，如果文件数量相当大时，扫描文件就非常耗费时间和性能。其次，rsync 不能够实时监测、同步数据，这就可能导致一些时间段数据不一致。解决这个问题的方法就是实时同步，所以需要使用 rsync+inotify 组合。

#### 2、inotify简介

inotify 是一种强大的、细粒度的、异步的文件系统事件监控机制，Linux 内核从2.6.13版本起，加入了对 inotify 的支持。通过 inotify 可以监控文件系统中添加、删除、修改、移动等各种事件，利用这个内核接口，inotify-tools 便可以监控文件系统下文件的各种变化情况了。

首先检查系统内核是否支持 inotify



```undefined
uname -r  
ll /proc/sys/fs/inotify
```

出现以下三个文件表示系统默认支持 inotify，如下所示。



```shell
[root@localhost ~]# uname -r  #查询系统内核版本
3.10.0-327.el7.x86_64
[root@localhost ~]# ll /proc/sys/fs/inotify
total 0
-rw-r--r-- 1 root root 0 Mar 11 09:34 max_queued_events
-rw-r--r-- 1 root root 0 Mar 11 09:34 max_user_instances
-rw-r--r-- 1 root root 0 Mar 11 09:34 max_user_watches
```



### 二、整体架构

这里我使用两个 Linux 服务器节点来做演示，实现两个节点间文件的实时同步，node1 为源服务器节点，就是需要同步数据的节点，部署 rsync+inotify ，node2 为同步节点，也就是接收同步数据的节点，只需要部署 rsync，如下所示。

| 主机  | 节点名       | 系统         | ip              | 角色   | 软件           |
| ----- | ------------ | ------------ | --------------- | ------ | -------------- |
| node1 | 源服务器节点 | CentOS7 64位 | 192.168.157.129 | Server | rsync，inotify |
| node2 | 同步节点     | CentOS7 64位 | 192.168.157.130 | Client | rsync          |

node1 中的 inotify 用于监控文件或文件夹的各种变化情况，一旦变动则利用 rsync 来进行文件的同步，具体架构图如下所示。



![img](Linux下文件实时自动同步备份.assets/webp.webp)

部署架构图.png



### 三、同步节点部署（rsync）

同步节点，也就是node2 192.168.157.130，只需要安装配置 rsync 即可，具体步骤如下。

#### 1、安装rsync

（1）直接使用yum命令安装



```undefined
yum -y install rsync
```

（2）使用编译安装

官网：[https://rsync.samba.org/](https://links.jianshu.com/go?to=https%3A%2F%2Frsync.samba.org%2F)
下载地址：[https://rsync.samba.org/ftp/rsync/](https://links.jianshu.com/go?to=https%3A%2F%2Frsync.samba.org%2Fftp%2Frsync%2F) ，目前最新版本是3.1.3 。

![img](Linux下文件实时自动同步备份.assets/webp.webp)

下载.png



下载完成后解压安装，如下



```bash
# 解压
tar zxvf rsync-3.1.3.tar.gz
cd rsync-3.1.3/
# 配置
./configure
# 编译及安装
make && make install
```

安装完成后，使用`rsync –-help`命令可查看 rsync 相关信息

![img](Linux下文件实时自动同步备份.assets/webp.webp)

rsync-help.png



#### 2、配置rsync

rsync 安装好之后，在 etc 目录下有一个 rsyncd.conf 文件，修改rsync配置文件。



```undefined
vim /etc/rsyncd.conf
```

修改内容如下



```csharp
uid = nobody
gid = nobody
use chroot = yes
max connections = 10
strict mode=yes
pid file = /var/run/rsyncd.pid
lock file=/var/run/rsync.lock
log file=/var/log/rsyncd.log
[backup]
        path = /backup129/
        comment = backup file
        ignore errrors
        read only=no
        write only=no
        hosts allow=192.168.157.129
        hosts deny=*
        list=false
        uid=root
        gid=root
        auth users=yxc
        secrets file=/etc/rsync.password
```

![img](Linux下文件实时自动同步备份.assets/webp.webp)

rsync_conf.png

其中需要用到一个密码文件，也就是上面配置的 secrets file 的值 /etc/rsync.password，在 rsync3.1.3 版本中默认没有密码文件，需要手动创建，内容格式为：user:password，user 就是上面配置的 yxc，password 就是密码，如下所示。



```bash
echo "yxc:123456" > /etc/rsync.password
```

然后需要给密码文件600权限



```undefined
chmod 600 /etc/rsync.password
```

启动 rsync 守护进程



```bash
/usr/local/bin/rsync --daemon
```

启动之后可查看 rsync 进程，如下



```undefined
ps -ef | grep rsync
```

![img](Linux下文件实时自动同步备份.assets/webp.webp)

startRsync.png

如有需要可加入系统自启动文件



```bash
echo "/usr/local/bin/rsync --daemon" >> /etc/rc.local
```

rsync 默认端口为873，所以开放873端口



```csharp
firewall-cmd --add-port=873/tcp --permanent --zone=public
#重启防火墙(修改配置后要重启防火墙)
firewall-cmd --reload
```



### 四、源服务器节点部署（rsync+inotify）

源服务器节点，也就是 node1 192.168.157.129，需要部署 rsync 和 inotify。

#### 1、安装rsync

rsync 安装方式和上面相同，就不详细讲解了。



```bash
# 解压
tar zxvf rsync-3.1.3.tar.gz
cd rsync-3.1.3/
# 配置
./configure
# 编译及安装
make && make install
```



#### 2、配置rsync

源服务器节点中只需要配置认证密码文件，首先在 etc 文件夹下创建文件 rsync.password，只需要密码，不需要用户，密码需要和同步节点 node2 中的一致，我这里也就是123456。



```undefined
vim /etc/rsync.password
```

![img](Linux下文件实时自动同步备份.assets/webp.webp)

129rsyPwd.png

修改密码文件权限



```bash
#需要给密码文件600权限
chmod 600 /etc/rsync.password
```

启动 rsync 守护进程



```bash
/usr/local/bin/rsync --daemon
```

如有需要可加入系统自启动文件



```bash
echo "/usr/local/bin/rsync --daemon" >> /etc/rc.local
```

同样开放873端口，如下所示



```csharp
firewall-cmd --add-port=873/tcp --permanent --zone=public
#重启防火墙(修改配置后要重启防火墙)
firewall-cmd --reload
```



#### 3、手动同步测试

先在源服务器节点的 /root/data/backuptest/ 目录下新建一个 test 文件夹



```bash
mkdir data/backuptest/test
```

然后使用如下命令进行同步测试，其中一些参数要和同步节点配置文件中相对应，比如下面的认证模块名 backup、用户名 yxc 等。



```ruby
rsync -avH --port 873 --delete /root/data/backuptest/ yxc@192.168.157.130::backup --password-file=/etc/rsync.password
```

![img](Linux下文件实时自动同步备份.assets/webp.webp)

手动同步测试.png

可以看到 node1 中文件夹 test 已经发送，查看同步节点 node2 中，如下

![img](Linux下文件实时自动同步备份.assets/webp.webp)

手动同步后130.png

test 文件夹已经同步到 node2，所以我们的 rsync 配置成功，可以进行文件同步，接下来就是部署 inotify 实现实时同步，通过inotify监听文件或文件夹，如果有变动就进行同步。



#### 4、部署inotify

##### （1）下载安装

inofity-tools下载地址：[http://github.com/downloads/rvoicilas/inotify-tools/inotify-tools-3.14.tar.gz](https://links.jianshu.com/go?to=http%3A%2F%2Fgithub.com%2Fdownloads%2Frvoicilas%2Finotify-tools%2Finotify-tools-3.14.tar.gz)
inotify-tools 的详细介绍可以看：[https://github.com/rvoicilas/inotify-tools/wiki](https://links.jianshu.com/go?to=https%3A%2F%2Fgithub.com%2Frvoicilas%2Finotify-tools%2Fwiki)

下载完成后，进行解压安装，如下



```bash
# 解压
tar zxvf inotify-tools-3.14.tar.gz
cd inotify-tools-3.14/
# 配置
./configure
# 编译及安装
make && make install
```



##### （2）创建rsync同步的shell脚本

安装完成之后需要创建用于 rsync 同步的 shell 脚本，如果添加、修改、删除了文件或文件夹，inotify 可以监控到，然后通过 rsync 进行同步，这里我们就在需要进行监控的目录创建这个脚本



```kotlin
vim /root/data/backuptest/inotifyrsync.sh
```



```bash
#!/bin/bash
host1=192.168.157.130
src=/root/data/backuptest/
dst1=backup
user1=yxc
/usr/local/bin/inotifywait -mrq --timefmt '%d/%m/%y %H:%M' --format '%T %w%f%e' -e close_write,delete,create,attrib $src \
| while read files
do
        /usr/bin/rsync -vzrtopg --delete --progress --password-file=/etc/rsync.password $src $user1@$host1::$dst1 > /dev/null 2>&1
        echo "${files} was rsynced." >> /tmp/rsync.log 2>&1
done
```

其中 host 是 client 的 ip，src 是 server 端要实时监控的目录，des 是认证的模块名，需要与 client 一致，user 是建立密码文件里的认证用户。

然后给这个脚本赋予权限



```kotlin
chmod 755 /root/data/backuptest/inotifyrsync.sh
```

后台运行这个脚本



```kotlin
/root/data/backuptest/inotifyrsync.sh &
```

有需要可以将脚本加入系统自启动文件中



```bash
echo "/root/data/backuptest/inotifyrsync.sh &" >> /etc/rc.local
```



### 五、实时同步备份验证

在 node1 节点中添加删除修改文件或文件夹，看 node2 中是否会自动同步，首先在 node1 中创建一个文件夹 hello



![img](Linux下文件实时自动同步备份.assets/webp.webp)

自动同步-129.png

查看 node2 中 backup129 文件夹，hello 文件夹已经同步，如下



![img](Linux下文件实时自动同步备份.assets/webp.webp)

自动同步-130.png



再在 node1 中创建、删除或修改一些文件或文件夹



![img](Linux下文件实时自动同步备份.assets/webp.webp)

自动同步测试后129.png

在 node2 中都会进行实时的同步备份，如下所示



![img](Linux下文件实时自动同步备份.assets/webp.webp)

自动同步测试后130.png

所以经验证，实时自动同步备份功能成功实现。



### 六、遇到的问题及解决方法

**1、手动同步测试时出现如下错误。**



```csharp
[root@oraserver ~]# rsync -avH --port 873 --delete /root/data/backuptest/ yxc@192.168.157.130::backup --password-file=/etc/rsync.password
@ERROR: chroot failed
rsync error: error starting client-server protocol (code 5) at main.c(1657) [sender=3.1.3]
[root@oraserver ~]# 
```

出现这个错误的原因是服务器端的目录不存在或无权限。查看130节点日志，如下



```csharp
[root@localhost backup129]# cat /var/log/rsyncd.log 
2020/03/11 15:46:17 [90120] rsync: chroot /backup129 failed: No such file or directory (2)
```

果然backup129 这个目录不存在，创建这个目录即可解决问题。



**2、启动rsync失败，提示pid文件已经存在**



```kotlin
[root@localhost data]#  /usr/local/bin/rsync --daemon
[root@localhost data]# failed to create pid file /var/run/rsyncd.pid: File exists
```

删除pid文件即可



```csharp
rm -rf /var/run/rsyncd.pid
```



**3、启动inotifyrsync.sh这个shell脚本时，发生错误**



```ruby
[root@oraserver ~]# /root/data/backuptest/inotifyrsync.sh &
[1] 30084
[root@oraserver ~]# /root/data/backuptest/inotifyrsync.sh: line 6: /usr/local/inotify/bin/inotifywait: No such file or directory
/root/data/backuptest/inotifyrsync.sh: line 7: syntax error near unexpected token `|'
/root/data/backuptest/inotifyrsync.sh: line 7: `| while read files '
[1]+  Exit 2                  /root/data/backuptest/inotifyrsync.sh
```

原因：/usr/local/inotify/bin/inotifywait 路径不对，是 /usr/local/bin/inotifywait ，修改即可。