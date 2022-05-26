

```
mkdir -p /data/tristan/etcd \
&& curl -L http://192.168.0.178/etcd/etcd-v3.5.1-linux-amd64.tar.gz -o /data/tristan/etcd/etcd-v3.5.1-linux-amd64.tar.gz \
&& tar xvf /data/tristan/etcd/etcd-v3.5.1-linux-amd64.tar.gz -C /data/tristan/etcd \
&& rm -rf /usr/bin/etcd /usr/bin/etcdctl \
&& ln -s /data/tristan/etcd/etcd-v3.5.1-linux-amd64/etcd /usr/bin/etcd \
&& ln -s /data/tristan/etcd/etcd-v3.5.1-linux-amd64/etcdctl /usr/bin/etcdctl \
&& etcd --version \
&& rm -rf /data/tristan/etcd/data && mkdir -p /data/tristan/etcd/data && chmod 0700 /data/tristan/etcd/data \
&& echo "export ETCDCTL_API=3" >> /etc/profile && source /etc/profile
```

注意如果是新的集群则设置`--initial-cluster-state new` 反之如果是往集群中加入一个节点则设置`--initial-cluster-state existing`

在原有etcd集群中添加当前节点

```
# 查看已有etcd集群情况
ETCDCTL_API=3 etcdctl --endpoints=https://[192.168.126.135]:2379 \
--cacert=/data/tristan/kube-auth/ca.pem \
--cert=/data/tristan/kube-auth/server.pem \
--key=/data/tristan/kube-auth/server-key.pem \
member list -w table

# etcd添加节点
ETCDCTL_API=3 etcdctl --endpoints=https://[192.168.126.135]:2379 \
--cacert=/data/tristan/kube-auth/ca.pem \
--cert=/data/tristan/kube-auth/server.pem \
--key=/data/tristan/kube-auth/server-key.pem \
member add etcd-22 --peer-urls=https://192.168.90.136:2380

# etcd删除节点
ETCDCTL_API=3 etcdctl --endpoints=https://[192.168.126.135]:2379 \
--cacert=/data/tristan/kube-auth/ca.pem \
--cert=/data/tristan/kube-auth/server.pem \
--key=/data/tristan/kube-auth/server-key.pem \
member remove 36d3cc5381f372bd
```

### 节点(192.168.126.135)

```
tee /usr/lib/systemd/system/etcd.service <<-'EOF'
[Unit]
Description=etcd
After=network.target local-fs.target

[Service]
ExecStart=/usr/bin/etcd \
  --data-dir=/data/tristan/etcd/data --name etcd-135 \
  --client-cert-auth --trusted-ca-file=/data/tristan/kube-auth/ca.pem --cert-file=/data/tristan/kube-auth/server.pem --key-file=/data/tristan/kube-auth/server-key.pem \
  --peer-client-cert-auth --peer-trusted-ca-file=/data/tristan/kube-auth/ca.pem --peer-cert-file=/data/tristan/kube-auth/server.pem --peer-key-file=/data/tristan/kube-auth/server-key.pem \
  --initial-advertise-peer-urls https://192.168.126.135:2380 --listen-peer-urls https://0.0.0.0:2380 \
  --advertise-client-urls https://192.168.126.135:2379 --listen-client-urls https://0.0.0.0:2379 \
  --initial-cluster etcd-135=https://192.168.126.135:2380,etcd-136=https://192.168.126.136:2380,etcd-137=https://192.168.126.137:2380 \
  --initial-cluster-state new --initial-cluster-token 858y64fKjj1DKqhhyk9D
KillMode=process
Restart=always
RestartSec=5
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload \
&& systemctl enable etcd \
&& systemctl restart etcd

journalctl -xefu etcd
```



### 节点(192.168.126.136)

```
tee /usr/lib/systemd/system/etcd.service <<-'EOF'
[Unit]
Description=etcd
After=network.target local-fs.target

[Service]
ExecStart=/usr/bin/etcd \
  --data-dir=/data/tristan/etcd/data --name etcd-136 \
  --client-cert-auth --trusted-ca-file=/data/tristan/kube-auth/ca.pem --cert-file=/data/tristan/kube-auth/server.pem --key-file=/data/tristan/kube-auth/server-key.pem \
  --peer-client-cert-auth --peer-trusted-ca-file=/data/tristan/kube-auth/ca.pem --peer-cert-file=/data/tristan/kube-auth/server.pem --peer-key-file=/data/tristan/kube-auth/server-key.pem \
  --initial-advertise-peer-urls https://192.168.126.136:2380 --listen-peer-urls https://0.0.0.0:2380 \
  --advertise-client-urls https://192.168.126.136:2379 --listen-client-urls https://0.0.0.0:2379 \
  --initial-cluster etcd-135=https://192.168.126.135:2380,etcd-136=https://192.168.126.136:2380,etcd-137=https://192.168.126.137:2380 \
  --initial-cluster-state new --initial-cluster-token 858y64fKjj1DKqhhyk9D
KillMode=process
Restart=always
RestartSec=5
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload \
&& systemctl enable etcd \
&& systemctl restart etcd

journalctl -xefu etcd
```



### 节点(192.168.126.137)

```
tee /usr/lib/systemd/system/etcd.service <<-'EOF'
[Unit]
Description=etcd
After=network.target local-fs.target

[Service]
ExecStart=/usr/bin/etcd \
  --data-dir=/data/tristan/etcd/data --name etcd-137 \
  --client-cert-auth --trusted-ca-file=/data/tristan/kube-auth/ca.pem --cert-file=/data/tristan/kube-auth/server.pem --key-file=/data/tristan/kube-auth/server-key.pem \
  --peer-client-cert-auth --peer-trusted-ca-file=/data/tristan/kube-auth/ca.pem --peer-cert-file=/data/tristan/kube-auth/server.pem --peer-key-file=/data/tristan/kube-auth/server-key.pem \
  --initial-advertise-peer-urls https://192.168.126.137:2380 --listen-peer-urls https://0.0.0.0:2380 \
  --advertise-client-urls https://192.168.126.137:2379 --listen-client-urls https://0.0.0.0:2379 \
  --initial-cluster etcd-135=https://192.168.126.135:2380,etcd-136=https://192.168.126.136:2380,etcd-137=https://192.168.126.137:2380 \
  --initial-cluster-state new --initial-cluster-token 858y64fKjj1DKqhhyk9D
KillMode=process
Restart=always
RestartSec=5
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload \
&& systemctl enable etcd \
&& systemctl restart etcd

journalctl -xefu etcd
```
