创建docker host

tristan-docker-host	端口设置8091

创建docker group(需要付费)

tristan-docker			 端口设置8092

创建docker proxy(可选)

tristan-docker-proxy	端口设置8093

配置Realms

在已有列表中添加`Docker Bearer Token Realm`

创建角色

tristan-docker

将docker所有权限加进去

创建用户

tristan-docker/7#g6eftF_G



配置https

```
# 创建证书secret yaml文件并命名为ingress-default-cert 
kubectl -n registry create secret tls container --cert=6072839_ctr-nexus-registry.local..pem --key=6072839_ctr-nexus-registry.local..key
```



尝试使用

```
docker login ctr-nexus-registry.local.  --username="tristan-docker" --password="7#g6eftF_G"

docker pull nginx:1.21
docker tag nginx:1.21 ctr-nexus-registry.local./nginx/nginx:v1.21
docker push ctr-nexus-registry.local./nginx/nginx:v1.21
```

