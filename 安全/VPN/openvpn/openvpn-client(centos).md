# 安装

```
yum update -y
yum install -y unbound
yum install -y epel-release
yum install -y openvpn iptables openssl wget ca-certificates curl tar 'policycoreutils-python*'
```

# 客户端连接认证文件

将`*.ovpn` 改为 `*.conf`, 例如`wjh-robot-k8s.opvn`改为`wjh-robot-k8s.conf`

```
mv wjh-server.ovpn /etc/openvpn/client/wjh-server.conf
```



```
mv wjh-local.ovpn /etc/openvpn/client/wjh-local.conf
```

修改配置文件

```
vi /usr/lib/systemd/system/openvpn-client@.service
```



# 启动

```
systemctl daemon-reload
```

线上

```
systemctl start openvpn-client@wjh-local
systemctl enable openvpn-client@wjh-local
systemctl status openvpn-client@wjh-local

journalctl -xe openvpn-client@wjh-local
```

线下

```
systemctl start openvpn-client@wjh-1-server
systemctl enable openvpn-client@wjh-1-server
systemctl status openvpn-client@wjh-1-server

journalctl -xe openvpn-client@wjh-1-server
```

# systemd方式

```
# 上传文件
mv -f /root/wjh-1-local.ovpn /etc/openvpn/client/wjh-1-local.conf

systemctl restart openvpn-client@wjh-1-local
systemctl enable openvpn-client@wjh-1-local
systemctl status openvpn-client@wjh-1-local
systemctl stop openvpn-client@wjh-1-local
```

测试

```
ping 192.168.1.9
```



# systemd不可用时的方式

```
# 上传文件
mv /root/wjh-1-server.ovpn /etc/openvpn/client/wjh-1-server.conf
tee /etc/rc.d/init.d/openvpn-client-wjh-1-server.sh <<-'EOF'
#!/bin/sh
#chkconfig: - 85 15
#description: nginx is a World Wide Web server. It is used to serve
sleep 15
nohup /usr/sbin/openvpn --suppress-timestamps --nobind --config /etc/openvpn/client/wjh-1-server.conf > /root/openvpn-client-wjh-1-server.log 2>&1 &
EOF
chmod 755 /etc/rc.d/init.d/openvpn-client-wjh-1-server.sh
```

```
chkconfig --add openvpn-client-wjh-1-server.sh
chkconfig openvpn-client-wjh-1-server.sh on
```

测试

```
ps aux|grep wjh-1-server.conf
ping 192.168.2.21
```





## 测试发现有问题

```
tee /usr/lib/systemd/system/openvpn-client-wjh-1-server.service <<-'EOF'
[Unit]
Description=openvpn-client-2-server
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/bin/bash /root/openvpn-client-wjh-1-server.sh

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload

systemctl start openvpn-client-wjh-1-server
systemctl status openvpn-client-wjh-1-server

/bin/kill $(ps aux | grep 'wjh-1-server.conf' | awk '{print $2}')
```



```
chmod +x /etc/rc.d/rc.local
echo "" >> /etc/rc.d/rc.local
echo "/bin/bash /root/openvpn-client-wjh-1-server.sh" >> /etc/rc.d/rc.local


/bin/kill $(ps aux | grep 'wjh-1-server.conf' | awk '{print $2}')
```

