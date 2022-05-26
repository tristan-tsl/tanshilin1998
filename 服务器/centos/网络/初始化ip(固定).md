固定ip

```
# 删除动态ip
sed -i '/BOOTPROTO="dhcp"/d'  /etc/sysconfig/network-scripts/ifcfg-enp47s0f1

# 添加静态配置
cat >> /etc/sysconfig/network-scripts/ifcfg-enp47s0f1<<EOF
BOOTPROTO="static"
IPADDR=192.168.90.22
GATEWAY=192.168.90.1                                                                                             
NETMASK=255.255.255.0
DNS1=202.96.128.166
DNS2=202.96.128.86
EOF

# 重启网络服务
systemctl restart network
```

