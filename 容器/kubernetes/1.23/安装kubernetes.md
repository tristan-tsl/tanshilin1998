# master

## kube-apiserver

```
mkdir -p /data/tristan/kubernetes-bin/server/bin \
&& cd /data/tristan/kubernetes-bin/server/bin \
&& curl -L http://192.168.0.178/kubernetes-1.23/1.23.1/kubernetes/server/bin/kube-apiserver -o kube-apiserver \
&& chmod +x kube-apiserver \
&& rm -rf /usr/bin/kube-apiserver \
&& ln -s /data/tristan/kubernetes-bin/server/bin/kube-apiserver /usr/bin/kube-apiserver \
&& kube-apiserver --version
```

### 节点-135

```
tee /usr/lib/systemd/system/kube-apiserver.service <<-'EOF'
[Unit]
Description=kube-apiserver
After=containerd.service

[Service]
ExecStart=/usr/bin/kube-apiserver \
--advertise-address=192.168.126.135 \
--etcd-servers=https://192.168.126.135:2379,https://192.168.126.136:2379,https://192.168.126.137:2379 \
--etcd-cafile=/data/tristan/kube-auth/ca.pem --etcd-certfile=/data/tristan/kube-auth/server.pem --etcd-keyfile=/data/tristan/kube-auth/server-key.pem \
--allow-privileged=true \
--service-cluster-ip-range=10.0.0.0/16 \
--enable-bootstrap-token-auth --token-auth-file=/data/tristan/kubernetes/token.csv \
--tls-cert-file=/data/tristan/kube-auth/server.pem --tls-private-key-file=/data/tristan/kube-auth/server-key.pem \
--service-account-issuer=kubernetes.default.svc --service-account-key-file=/data/tristan/kube-auth/ca-key.pem --service-account-signing-key-file=/data/tristan/kube-auth/ca-key.pem \
--client-ca-file=/data/tristan/kube-auth/ca.pem \
--kubelet-client-certificate=/data/tristan/kube-auth/server.pem --kubelet-client-key=/data/tristan/kube-auth/server-key.pem \
--requestheader-client-ca-file=/data/tristan/kube-auth/server.pem \
--requestheader-allowed-names=aggregator \
--requestheader-extra-headers-prefix=X-Remote-Extra- \
--requestheader-group-headers=X-Remote-Group \
--requestheader-username-headers=X-Remote-User \
--proxy-client-cert-file=/data/tristan/kube-auth/ca.pem \
--proxy-client-key-file=/data/tristan/kube-auth/ca-key.pem \
--runtime-config=api/all=true \
--enable-aggregator-routing=true

KillMode=process
Restart=always
RestartSec=5
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload \
&& systemctl enable kube-apiserver \
&& systemctl restart kube-apiserver

journalctl -xefu kube-apiserver
```

### 节点-136

```
tee /usr/lib/systemd/system/kube-apiserver.service <<-'EOF'
[Unit]
Description=kube-apiserver
After=containerd.service

[Service]
ExecStart=/usr/bin/kube-apiserver \
--advertise-address=192.168.126.136 \
--etcd-servers=https://192.168.126.135:2379,https://192.168.126.136:2379,https://192.168.126.137:2379 \
--etcd-cafile=/data/tristan/kube-auth/ca.pem --etcd-certfile=/data/tristan/kube-auth/server.pem --etcd-keyfile=/data/tristan/kube-auth/server-key.pem \
--allow-privileged=true \
--service-cluster-ip-range=10.0.0.0/16 \
--enable-bootstrap-token-auth --token-auth-file=/data/tristan/kubernetes/token.csv \
--tls-cert-file=/data/tristan/kube-auth/server.pem --tls-private-key-file=/data/tristan/kube-auth/server-key.pem \
--service-account-issuer=kubernetes.default.svc --service-account-key-file=/data/tristan/kube-auth/ca-key.pem --service-account-signing-key-file=/data/tristan/kube-auth/ca-key.pem \
--client-ca-file=/data/tristan/kube-auth/ca.pem \
--kubelet-client-certificate=/data/tristan/kube-auth/server.pem --kubelet-client-key=/data/tristan/kube-auth/server-key.pem \
--requestheader-client-ca-file=/data/tristan/kube-auth/server.pem \
--requestheader-allowed-names=aggregator \
--requestheader-extra-headers-prefix=X-Remote-Extra- \
--requestheader-group-headers=X-Remote-Group \
--requestheader-username-headers=X-Remote-User \
--proxy-client-cert-file=/data/tristan/kube-auth/ca.pem \
--proxy-client-key-file=/data/tristan/kube-auth/ca-key.pem \
--runtime-config=api/all=true \
--enable-aggregator-routing=true

KillMode=process
Restart=always
RestartSec=5
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload \
&& systemctl enable kube-apiserver \
&& systemctl restart kube-apiserver

journalctl -xefu kube-apiserver
```

### 节点-137

```
tee /usr/lib/systemd/system/kube-apiserver.service <<-'EOF'
[Unit]
Description=kube-apiserver
After=containerd.service

[Service]
ExecStart=/usr/bin/kube-apiserver \
--advertise-address=192.168.126.137 \
--etcd-servers=https://192.168.126.135:2379,https://192.168.126.136:2379,https://192.168.126.137:2379 \
--etcd-cafile=/data/tristan/kube-auth/ca.pem --etcd-certfile=/data/tristan/kube-auth/server.pem --etcd-keyfile=/data/tristan/kube-auth/server-key.pem \
--allow-privileged=true \
--service-cluster-ip-range=10.0.0.0/16 \
--enable-bootstrap-token-auth --token-auth-file=/data/tristan/kubernetes/token.csv \
--tls-cert-file=/data/tristan/kube-auth/server.pem --tls-private-key-file=/data/tristan/kube-auth/server-key.pem \
--service-account-issuer=kubernetes.default.svc --service-account-key-file=/data/tristan/kube-auth/ca-key.pem --service-account-signing-key-file=/data/tristan/kube-auth/ca-key.pem \
--client-ca-file=/data/tristan/kube-auth/ca.pem \
--kubelet-client-certificate=/data/tristan/kube-auth/server.pem --kubelet-client-key=/data/tristan/kube-auth/server-key.pem \
--requestheader-client-ca-file=/data/tristan/kube-auth/server.pem \
--requestheader-allowed-names=aggregator \
--requestheader-extra-headers-prefix=X-Remote-Extra- \
--requestheader-group-headers=X-Remote-Group \
--requestheader-username-headers=X-Remote-User \
--proxy-client-cert-file=/data/tristan/kube-auth/ca.pem \
--proxy-client-key-file=/data/tristan/kube-auth/ca-key.pem \
--runtime-config=api/all=true \
--enable-aggregator-routing=true

KillMode=process
Restart=always
RestartSec=5
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload \
&& systemctl enable kube-apiserver \
&& systemctl restart kube-apiserver

journalctl -xefu kube-apiserver
```







## kube-controller-manager

```
mkdir -p /data/tristan/kubernetes-bin/server/bin \
&& cd /data/tristan/kubernetes-bin/server/bin \
&& curl -L http://192.168.0.178/kubernetes-1.23/1.23.1/kubernetes/server/bin/kube-controller-manager -o kube-controller-manager \
&& chmod +x kube-controller-manager \
&& rm -rf /usr/bin/kube-controller-manager \
&& ln -s /data/tristan/kubernetes-bin/server/bin/kube-controller-manager /usr/bin/kube-controller-manager \
&& kube-controller-manager --version
```

### 每个节点

```
tee /usr/lib/systemd/system/kube-controller-manager.service <<-'EOF'
[Unit]
Description=kube-controller-manager
After=containerd.service

[Service]
ExecStart=/usr/bin/kube-controller-manager \
--master=https://192.168.126.135:6443 \
--kubeconfig=/data/tristan/kubernetes/bootstrap.kubeconfig \
--cluster-signing-cert-file=/data/tristan/kube-auth/ca.pem --cluster-signing-key-file=/data/tristan/kube-auth/ca-key.pem --cluster-signing-duration=87600h0m0s \
--pod-eviction-timeout=1m0s \
--service-account-private-key-file=/data/tristan/kube-auth/ca-key.pem \
--root-ca-file=/data/tristan/kube-auth/ca.pem --client-ca-file=/data/tristan/kube-auth/ca.pem

KillMode=process
Restart=always
RestartSec=5
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload \
&& systemctl enable kube-controller-manager \
&& systemctl restart kube-controller-manager

journalctl -xefu kube-controller-manager
```



## kube-scheduler

```
mkdir -p /data/tristan/kubernetes-bin/server/bin \
&& cd /data/tristan/kubernetes-bin/server/bin \
&& curl -L http://192.168.0.178/kubernetes-1.23/1.23.1/kubernetes/server/bin/kube-scheduler -o kube-scheduler \
&& chmod +x kube-scheduler \
&& rm -rf /usr/bin/kube-scheduler \
&& ln -s /data/tristan/kubernetes-bin/server/bin/kube-scheduler /usr/bin/kube-scheduler \
&& kube-scheduler --version
```

### 每个节点

```
tee /usr/lib/systemd/system/kube-scheduler.service <<-'EOF'
[Unit]
Description=kube-scheduler
After=containerd.service

[Service]
ExecStart=/usr/bin/kube-scheduler --master=https://192.168.126.135:6443 --client-ca-file=/data/tristan/kube-auth/ca.pem --kubeconfig=/data/tristan/kubernetes/bootstrap.kubeconfig --tls-cert-file=/data/tristan/kube-auth/ca.pem --tls-private-key-file=/data/tristan/kube-auth/ca-key.pem

KillMode=process
Restart=always
RestartSec=5
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload \
&& systemctl enable kube-scheduler \
&& systemctl restart kube-scheduler

journalctl -xefu kube-scheduler
```



# worker(每个节点)

## kubelet

```
mkdir -p /data/tristan/kubernetes-bin/server/bin \
&& cd /data/tristan/kubernetes-bin/server/bin \
&& curl -L http://192.168.0.178/kubernetes-1.23/1.23.1/kubernetes/server/bin/kubelet -o kubelet \
&& chmod +x kubelet \
&& rm -rf /usr/bin/kubelet \
&& ln -s /data/tristan/kubernetes-bin/server/bin/kubelet /usr/bin/kubelet \
&& kubelet --version

apt install iptables -y
```



```
tee /data/tristan/kubernetes/kubelet-config.yaml <<-'EOF'
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: "systemd"
maxPods: 1000
clusterDNS: ["10.0.0.2"]
clusterDomain: "cluster.local."
authentication:
  anonymous:
    enabled: false
  x509:
    clientCAFile: /data/tristan/kube-auth/ca.pem
kubeReserved:
    cpu: "0.1"
    memory: "0.1Gi"
    ephemeral-storage: "0.1Gi"
systemReserved:
    cpu: "20m"
    memory: "0.5Gi"
    ephemeral-storage: "1Gi"
evictionHard:
    memory.available:  "1Gi"
EOF
```



```
tee /usr/lib/systemd/system/kubelet.service <<-'EOF'
[Unit]
Description=kubelet
After=containerd.service

[Service]
ExecStart=/usr/bin/kubelet --config=/data/tristan/kubernetes/kubelet-config.yaml --container-runtime=remote --container-runtime-endpoint=unix:///run/containerd/containerd.sock --bootstrap-kubeconfig=/data/tristan/kubernetes/bootstrap.kubeconfig --kubeconfig=/data/tristan/kubernetes/bootstrap-kubelet.kubeconfig

KillMode=process
Restart=always
RestartSec=5
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload \
&& systemctl enable kubelet \
&& systemctl restart kubelet

journalctl -xefu kubelet
```



## kube-proxy

```
mkdir -p /data/tristan/kubernetes-bin/server/bin \
&& cd /data/tristan/kubernetes-bin/server/bin \
&& curl -L http://192.168.0.178/kubernetes-1.23/1.23.1/kubernetes/server/bin/kube-proxy -o kube-proxy \
&& chmod +x kube-proxy \
&& rm -rf /usr/bin/kube-proxy \
&& ln -s /data/tristan/kubernetes-bin/server/bin/kube-proxy /usr/bin/kube-proxy \
&& kube-proxy --version
```



```
tee /usr/lib/systemd/system/kube-proxy.service <<-'EOF'
[Unit]
Description=kube-proxy
After=containerd.service
Wants=containerd.service

[Service]
ExecStart=/usr/bin/kube-proxy --kubeconfig=/data/tristan/kubernetes/bootstrap.kubeconfig --cluster-cidr=10.0.0.0/16

Type=simple
Delegate=yes
Restart=always
RestartSec=5
OOMScoreAdjust=-999
KillMode=process

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload \
&& systemctl enable kube-proxy \
&& systemctl restart kube-proxy

journalctl -xefu kube-proxy
```



## kubectl

```
mkdir -p /data/tristan/kubernetes-bin/server/bin \
&& cd /data/tristan/kubernetes-bin/server/bin \
&& curl -L http://192.168.0.178/kubernetes-1.23/1.23.1/kubernetes/server/bin/kubectl -o kubectl \
&& chmod +x kubectl \
&& rm -rf /usr/bin/kubectl \
&& ln -s /data/tristan/kubernetes-bin/server/bin/kubectl /usr/bin/kubectl \
&& kubectl version
```

