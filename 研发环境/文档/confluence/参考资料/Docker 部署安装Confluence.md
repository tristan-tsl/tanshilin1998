# Docker 部署安装Confluence

 发表于 2020-01-17 | 更新于 2020-01-19 | 分类于 [confluence](https://howard1994.github.io/categories/confluence/)

# docker下部署confluence



## docker镜像获取及容器创建

- 1. confluence镜像下载

     ```
     docker pull cptactionhank/atlassian-confluence
     ```

     ![img](https://howard1994.github.io/2020/01/17/Docker-%E9%83%A8%E7%BD%B2%E5%AE%89%E8%A3%85Confluence/1.jpg)

- 1. 创建confluence容器

     ```
     docker run -d \
     --restart=always \
     --name "confluence"  \
     -p 7788:8090 \
     -e CATALINA_OPTS="-Xms512m -Xmx4g" \
     -v confluence:/var/atlassian/confluence \
     cptactionhank/atlassian-confluence:latest
     ```

     命令详解:

     - -d 即 –detach **设置容器后台运行**
     - –restart=always **Docker重启时自动启动容器**
     - –name **容器别名**
     - -p 即 –publish **宿主机端口:容器内部端口 容器内部端口映射到宿主机**
     - -e 即 –env **创建容器时传入环境变量**
     - -v 即 –volume **宿主机路径(或者匿名的volume 使用命令: \*docker volume ls\* 可查看所有volume,使用命令: \*docker inspect [volume]\* 查看文件内容):容器路径 将容器内部文件映射到宿主机目录下**

- 1. 查看容器运行状态&进入容器内部

     > 查看容器运行状态

     ![img](https://howard1994.github.io/2020/01/17/Docker-%E9%83%A8%E7%BD%B2%E5%AE%89%E8%A3%85Confluence/2.jpg)

     ```
     docker ps -a
     ```

     > 进入容器内部,退出: **exit**

     ![img](https://howard1994.github.io/2020/01/17/Docker-%E9%83%A8%E7%BD%B2%E5%AE%89%E8%A3%85Confluence/4.jpg)

     ```
     docker exec -it [容器名或者ID] /bin/sh
     ```

- 1. 配置confluence

     - 访问[http://ip:7788](http://ip:7788/) 就可以看到Confluence的初始化和配置页面。右上角语言栏选择中文

     ![img](https://howard1994.github.io/2020/01/17/Docker-%E9%83%A8%E7%BD%B2%E5%AE%89%E8%A3%85Confluence/5.jpg)
     ![img](https://howard1994.github.io/2020/01/17/Docker-%E9%83%A8%E7%BD%B2%E5%AE%89%E8%A3%85Confluence/3.jpg)

     - 一路next

     ![img](https://howard1994.github.io/2020/01/17/Docker-%E9%83%A8%E7%BD%B2%E5%AE%89%E8%A3%85Confluence/6.jpg)

     - 记住这个服务ID,进入破解流程:
       [confluence破解](https://howard1994.github.io/2020/01/17/Docker-部署安装Confluence/#confluence破解)
     - 输入上一步破解教程得到的Key

     ![img](https://howard1994.github.io/2020/01/17/Docker-%E9%83%A8%E7%BD%B2%E5%AE%89%E8%A3%85Confluence/11.jpg)

     - 开始配置数据库

     ![img](https://howard1994.github.io/2020/01/17/Docker-%E9%83%A8%E7%BD%B2%E5%AE%89%E8%A3%85Confluence/12.jpg)

     ![img](https://howard1994.github.io/2020/01/17/Docker-%E9%83%A8%E7%BD%B2%E5%AE%89%E8%A3%85Confluence/10.jpg)

     ```
     jdbc:mysql://192.168.1.202:3308/test_confluence?useUnicode=true&amp;characterEncoding=utf8&amp;useSSL=false&amp;sessionVariables=tx_isolation='READ-COMMITTED'
     ```

     如果出现隔离级别错误,设置数据库默认隔离级别为

     ```
     SET GLOBAL TRANSACTION ISOLATION LEVEL READ COMMITTED;
     ```

     - confluence开始创建表
       ![img](https://howard1994.github.io/2020/01/17/Docker-%E9%83%A8%E7%BD%B2%E5%AE%89%E8%A3%85Confluence/13.jpg)
     - 完成安装
       ![img](https://howard1994.github.io/2020/01/17/Docker-%E9%83%A8%E7%BD%B2%E5%AE%89%E8%A3%85Confluence/14.jpg)
       **个人推荐选择空白站点**

## confluence破解

- 1. 破解文件下载:
     [confluence破解.rar](https://github.com/howard1994/MyFile/raw/master/confluence破解.rar)

- 1. 破解文件的使用:

  - (1). 解压文件
    ![img](https://howard1994.github.io/2020/01/17/Docker-%E9%83%A8%E7%BD%B2%E5%AE%89%E8%A3%85Confluence/7.jpg)
    如上图所示图片,邮件打开方式选择java
    ![img](https://howard1994.github.io/2020/01/17/Docker-%E9%83%A8%E7%BD%B2%E5%AE%89%E8%A3%85Confluence/8.jpg)

  - (2). 破解文件下载到windows机器
    将atlassian-extras-decoder-v2-3.4.1.jar复制到宿主机并重命名为atlassian-extras-2.4.jar(破解文件只识别此名字)
    sz 命令将atlassian-extras-2.4.jar 下载到本地进行破解

    ```
    docker cp  confluence:/opt/atlassian/confluence/confluence/WEB-INF/lib/atlassian-extras-decoder-v2-3.4.1.jar ./atlassian-extras-2.4.jar
     
    sz atlassian-extras-2.4.jar
    ```

  - (3).破解
    ![img](https://howard1994.github.io/2020/01/17/Docker-%E9%83%A8%E7%BD%B2%E5%AE%89%E8%A3%85Confluence/9.jpg)

    - 将生成的atlassian-extras-2.4.jar上传到服务器(如linux路径下有同名文件需要先重命名)

      ```
      rz
      ```

    选择atlassian-extras-2.4.jar进行上传

    - 用上传的文件替换confluence中的atlassian-extras-decoder-v2-3.4.1.jar

      ```
      docker cp ./atlassian-extras-2.4.jar confluence:/opt/atlassian/confluence/confluence/WEB-INF/lib/atlassian-extras-decoder-v2-3.4.1.jar
      ```

    - 重启容器

      ```
      docker restart confluence
      ```

    - 复制破解脚本中Key值,重新进入[confluence安装教程](https://howard1994.github.io/2020/01/17/Docker-部署安装Confluence/#继续安装)

      ### 常见错误处理

- 1. Mysql Session isolation level 错误

     > 数据库链接中加入参数:
     > useSSL=false

- 1. mysql重启导致隔离级别需要重新设置

     > 数据库链接中加入参数:
     > sessionVariables=tx_isolation=’READ-COMMITTED’