固定ip(注意不要ip冲突)

测试发现重启网络服务仍然无法修改ip, 只能通过重启实现
```
sed -i '/dhcp/d' /etc/network/interfaces
cat >> /etc/network/interfaces<<EOF
auto ens33
iface ens33 inet static
address 192.168.126.137
netmask 255.255.255.0
gateway 192.168.126.2
ns-nameservers 192.168.126.2 192.168.126.2
EOF
cat /etc/network/interfaces
/etc/init.d/networking restart
/etc/init.d/networking status

reboot
```
# route add default gw 192.168.126.1