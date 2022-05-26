# 部署

线上配置

```
rm -rf /data/tristan/nginx
mkdir -p /data/tristan/nginx/config /data/tristan/nginx/logs

tee /data/tristan/nginx/config/nginx.conf <<-'EOF'
user  nginx;
worker_processes  auto;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;
events {
    worker_connections  1024;
}
stream {
    upstream multi.target {
        server 192.168.1.9:80;
    }
    server {
        listen 80;
        proxy_connect_timeout 100s;
        proxy_timeout 300s;
        proxy_pass multi.target;
    }
}
EOF
```

线下配置

```
rm -rf /data/tristan/nginx
mkdir -p /data/tristan/nginx/config /data/tristan/nginx/logs

tee /data/tristan/nginx/config/nginx.conf <<-'EOF'
user  nginx;
worker_processes  auto;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;
events {
    worker_connections  1024;
}
stream {
    upstream multi.target {
        server 192.168.2.11:80;
        server 192.168.2.4:80;
    }
    upstream grafana.target {
        server 192.168.2.21:80;
    }
    upstream skywalking.target {
        server 192.168.2.20:80;
    }
    server {
        listen 80;
        allow 172.30.1.35;
        allow 192.168.1.9;
        deny all;
        proxy_connect_timeout 100s;
        proxy_timeout 300s;
        proxy_pass multi.target;
    }
    server {
        listen 81;
        proxy_connect_timeout 10s;
        proxy_timeout 300s;
        proxy_pass grafana.target;
    }
    server {
        listen 82;
        proxy_connect_timeout 10s;
        proxy_timeout 300s;
        proxy_pass skywalking.target;
    }
}
EOF
```



```
ctr images pull docker.io/library/nginx:1.21-alpine

# 查看运行效果
ctr t rm -f nginx
ctr c rm  nginx

ctr run -d \
--net-host \
--log-uri file:///data/tristan/nginx/logs/nginx.log \
--mount type=bind,src=/data/tristan/nginx/config/nginx.conf,dst=/etc/nginx/nginx.conf,options=rbind:ro \
docker.io/library/nginx:1.21-alpine nginx
```



```
ctr t exec --exec-id nginx nginx sh

nginx -t
nginx -s reload


# 查看运行日志
cat /data/tristan/nginx/logs/nginx.log
tail -f -n 100 /data/tristan/nginx/logs/nginx.log
```





访问线上: server.proxy.	172.30.1.35

访问线下: local.proxy.	   192.168.5.10



调整线上nginx-out

```
# oa 内网穿透代理
server {
    listen  80;
    server_name server.proxy.;
    access_log  logs/server_proxy_prod.log  main;
    access_log  logs/server_proxy_prod_json.json main_json;
    allow 192.168.5.10;
    deny all;
    location / {
       proxy_buffer_size 102400k;
       proxy_buffers   4 102400k;
       proxy_busy_buffers_size 102400k;
       proxy_http_version 1.1;
       #####################自定义请求头####################
       proxy_set_header Branch  wjh-prod;
       proxy_set_header Ser-host "oa-intermediate-server.";
       proxy_set_header wjh-auth-token $http_wjh_auth_token ;
       proxy_set_header X-Real-IP $remote_addr;
       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       #####################自定义请求头####################
       proxy_pass http://prod_wjh_application;
    }
}
```

```
/usr/local/openresty/nginx/sbin/nginx -t
/usr/local/openresty/nginx/sbin/nginx -s reload
```



# 自启

```
mkdir -p /data/tristan/nginx
tee /data/tristan/nginx/boot_auto_start_container.sh <<-'EOF'
#!/bin/bash
echo "auto startting"
ctr t start nginx -d
echo "auto start"

EOF
chmod +x /data/tristan/nginx/boot_auto_start_container.sh


tee /usr/lib/systemd/system/containerd_auto.service <<-'EOF'
[Unit]
Description=containerd_auto
After=containerd.service

[Service]
ExecStart=/data/tristan/nginx/boot_auto_start_container.sh
ExecReload=/data/tristan/nginx/boot_auto_start_container.sh

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload \
&& systemctl enable containerd_auto \
&& systemctl status containerd_auto
```

测试

```
systemctl start  containerd_auto
systemctl status containerd_auto
journalctl -xefu containerd_auto
ctr t ls
```

