思路: 通过nginx直接将全部流量转发老的流量到新的nacos上



nginx配置文件

```
mkdir -p /data/tristan/nginx/config
tee /data/tristan/nginx/config/nginx.conf <<-'EOF'
user  nginx;
worker_processes  auto;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
    server {
        listen       8848;
		location / {
			proxy_pass http://nacos-config.dev.local.;
		}
    }
}
EOF
cat /data/tristan/nginx/config/nginx.conf
```



容器启动命令

```
docker stop nginx && docker rm nginx
docker run -d \
  --name=nginx \
  --net="host" --restart=always \
  -v /data/tristan/nginx/config/nginx.conf:/etc/nginx/nginx.conf \
  docker.io/library/nginx:1.21

docker logs -f --tail 100 nginx
```

