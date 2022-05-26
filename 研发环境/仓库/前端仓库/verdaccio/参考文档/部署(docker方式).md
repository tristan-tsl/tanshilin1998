# 设计思路

![静态导入方式设计思路](.\静态导入方式设计思路.png)

# verdaccio

```
docker volume rm verdaccio_conf verdaccio_storage
docker volume create verdaccio_conf
docker volume create verdaccio_storage

docker volume inspect verdaccio_storage
cd /var/lib/docker/volumes/verdaccio_storage/_data
```

运行

```
docker stop verdaccio && docker rm verdaccio
docker run -d \
  --name=verdaccio \
  --net="host" -u root --restart=always \
  --mount source=verdaccio_conf,target=/verdaccio/conf \
  --mount source=verdaccio_storage,target=/verdaccio/storage \
  verdaccio/verdaccio:5.1

docker exec -it verdaccio sh
docker ps -a
docker logs -f -n 100 verdaccio
```

生成认证信息

```
npm adduser --registry  http://192.168.5.8:4873
或者
npm adduser --registry  http://verdaccio-nodejs-registry.local.
```

注意: 实际存储目录为`/verdaccio/conf` `/verdaccio/storage`

实际端口为4873

调整配置

```
cat >> /data/tristan/registry/nodejs/verdaccio/conf/config.yaml<<EOF
i18n:
    web: zh-CN
EOF
```

初始化完成之后禁用添加用户功能

```
vi /data/tristan/registry/nodejs/verdaccio/conf/config.yaml

auth:
  htpasswd:
    file: /verdaccio/storage/htpasswd
    # Maximum amount of users allowed to register, defaults to "+infinity".
    # You can set this to -1 to disable registration.
    max_users: 1
```



访问:

http://192.168.5.8:4873

http://verdaccio-nodejs-registry.local.

登录: tristan/tristan

使用:



```
npm config set registry http://172.30.1.32:9527
```



```
npm config get registry
npm config set registry http://verdaccio-nodejs-registry.local.


npm login --registry http://verdaccio-nodejs-registry.local.
npm publish --registry http://verdaccio-nodejs-registry.local.
```



# unpkg

```
docker stop unpkg && docker rm unpkg
docker run -d \
  --name=unpkg \
  --restart=always \
  -p 8080:8080 \
  -e NPM_REGISTRY_URL="http://192.168.5.8:4873" \
  -e ORIGIN="http://localhost:8080" \
  -e NODE_ENV="production" \
  -e DEBUG="true" \
  -e TZ=Asia/Shanghai \
  -v /etc/localtime:/etc/localtime:ro \
  dalongrong/unpkg:http-env

docker ps -a
docker logs -f -n 100 unpkg
docker exec -it unpkg sh
```

双节点

```
docker stop unpkg8081 && docker rm unpkg8081
docker run -d \
  --name=unpkg8081 \
  --restart=always \
  -p 8081:8080 \
  -e NPM_REGISTRY_URL="http://192.168.5.8:4873" \
  -e ORIGIN="http://localhost:8080" \
  -e NODE_ENV="production" \
  -e DEBUG="true" \
  -e TZ=Asia/Shanghai \
  -v /etc/localtime:/etc/localtime:ro \
  dalongrong/unpkg:http-env

docker ps -a
docker logs -f -n 100 unpkg8081
```

访问: http://192.168.5.8:8080

网关

参考unpkg.conf

访问: https://unpkg-nodejs-registry.

# 参考资料

https://github.com/verdaccio/charts

https://verdaccio.org/zh-CN/docs/uplinks

http://www.htaccesstools.com/htpasswd-generator/
