# 创建统一免密登录文件

```
# 备份本机文件
mv -f /root/.ssh/id_rsa /root/.ssh/id_rsa_bak
mv -f /root/.ssh/id_rsa.pub /root/.ssh/id_rsa.pub_bak

# 创建登录证书文件
ssh-keygen -t rsa -P ''
```

# 调整每台服务器

```
# 修改root账号密码
passwd

# 备份本机文件
mv -f /root/.ssh/id_rsa /root/.ssh/id_rsa_bak
mv -f /root/.ssh/id_rsa.pub /root/.ssh/id_rsa.pub_bak

# 下载登录认证文件
yum install -y sshpass
scp root@192.168.5.65:/root/.ssh/id_rsa /root/.ssh/id_rsa
scp root@192.168.5.65:/root/.ssh/id_rsa.pub /root/.ssh/id_rsa.pub

ll /root/.ssh/

echo "备份"
mv -f /root/.ssh/authorized_keys /root/.ssh/authorized_keys_bak
echo "加载证书文件内容"
cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
chmod 700 /root/.ssh/authorized_keys

vi /etc/ssh/sshd_config

RSAAuthentication yes
PubkeyAuthentication yes
PasswordAuthentication no
PermitRootLogin yes

systemctl restart sshd
systemctl status  sshd
```

jumpserver需要使用 id_rsa 文件, 上传 id_rsa 文件到 jumpserver

securecrt 需要使用 id_rsa.pub 文件