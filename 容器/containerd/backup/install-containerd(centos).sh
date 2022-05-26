echo "配置"
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter


echo "设置必需的 sysctl 参数，这些参数在重新启动后仍然存在。"
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

echo "应用 sysctl 参数而无需重新启动"
sysctl --system

echo "以下指令是直接安装containerd"
yum install -y yum-utils
yum-config-manager \
    --add-repo \
    https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# yum update -y
yum install -y containerd.io
# 后续升级
#yum update -y containerd.io

containerd -v

echo "配置"
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

tee /etc/containerd/config.toml <<-'EOF'
version = 2
root = "/var/lib/containerd"
state = "/run/containerd"
plugin_dir = ""
disabled_plugins = []
required_plugins = []
oom_score = 0

[grpc]
  address = "/run/containerd/containerd.sock"
  tcp_address = ""
  tcp_tls_cert = ""
  tcp_tls_key = ""
  uid = 0
  gid = 0
  max_recv_message_size = 16777216
  max_send_message_size = 16777216

[ttrpc]
  address = ""
  uid = 0
  gid = 0

[debug]
  address = ""
  uid = 0
  gid = 0
  level = ""

[metrics]
  address = ""
  grpc_histogram = false

[cgroup]
  path = ""

[timeouts]
  "io.containerd.timeout.shim.cleanup" = "5s"
  "io.containerd.timeout.shim.load" = "5s"
  "io.containerd.timeout.shim.shutdown" = "3s"
  "io.containerd.timeout.task.state" = "2s"

[plugins]
  [plugins."io.containerd.gc.v1.scheduler"]
    pause_threshold = 0.02
    deletion_threshold = 0
    mutation_threshold = 100
    schedule_delay = "0s"
    startup_delay = "100ms"
  [plugins."io.containerd.grpc.v1.cri"]
    disable_tcp_service = true
    stream_server_address = "127.0.0.1"
    stream_server_port = "0"
    stream_idle_timeout = "4h0m0s"
    enable_selinux = false
    selinux_category_range = 1024
    sandbox_image = "docker.io/mirrorgcrio/pause:3.2"
    stats_collect_period = 10
    systemd_cgroup = false
    enable_tls_streaming = false
    max_container_log_line_size = 16384
    disable_cgroup = false
    disable_apparmor = false
    restrict_oom_score_adj = false
    max_concurrent_downloads = 3
    disable_proc_mount = false
    unset_seccomp_profile = ""
    tolerate_missing_hugetlb_controller = true
    disable_hugetlb_controller = true
    ignore_image_defined_volumes = false
    [plugins."io.containerd.grpc.v1.cri".containerd]
      snapshotter = "overlayfs"
      default_runtime_name = "runc"
      no_pivot = false
      disable_snapshot_annotations = true
      discard_unpacked_layers = false
      [plugins."io.containerd.grpc.v1.cri".containerd.default_runtime]
        runtime_type = ""
        runtime_engine = ""
        runtime_root = ""
        privileged_without_host_devices = false
        base_runtime_spec = ""
      [plugins."io.containerd.grpc.v1.cri".containerd.untrusted_workload_runtime]
        runtime_type = ""
        runtime_engine = ""
        runtime_root = ""
        privileged_without_host_devices = false
        base_runtime_spec = ""
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runc.v2"
          runtime_engine = ""
          runtime_root = ""
          privileged_without_host_devices = false
          base_runtime_spec = ""
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            SystemdCgroup = true
    [plugins."io.containerd.grpc.v1.cri".cni]
      bin_dir = "/opt/cni/bin"
      conf_dir = "/etc/cni/net.d"
      max_conf_num = 1
      conf_template = ""
    [plugins."io.containerd.grpc.v1.cri".registry]
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.wjh.com"]
          endpoint = ["http://192.168.90.242"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."ctr-registry.local."]
          endpoint = ["https://ctr-registry.local."]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."*"]
          endpoint = ["https://mirror.ccs.tencentyun.com"]
    [plugins."io.containerd.grpc.v1.cri".image_decryption]
      key_model = ""
    [plugins."io.containerd.grpc.v1.cri".x509_key_pair_streaming]
      tls_cert_file = ""
      tls_key_file = ""
  [plugins."io.containerd.internal.v1.opt"]
    path = "/opt/containerd"
  [plugins."io.containerd.internal.v1.restart"]
    interval = "10s"
  [plugins."io.containerd.metadata.v1.bolt"]
    content_sharing_policy = "shared"
  [plugins."io.containerd.monitor.v1.cgroups"]
    no_prometheus = false
  [plugins."io.containerd.runtime.v1.linux"]
    shim = "containerd-shim"
    runtime = "runc"
    runtime_root = ""
    no_shim = false
    shim_debug = false
  [plugins."io.containerd.runtime.v2.task"]
    platforms = ["linux/amd64"]
  [plugins."io.containerd.service.v1.diff-service"]
    default = ["walking"]
  [plugins."io.containerd.snapshotter.v1.devmapper"]
    root_path = ""
    pool_name = ""
    base_image_size = ""
    async_remove = false
EOF

echo "启动"
systemctl start containerd
systemctl enable containerd
systemctl status containerd

echo "修改宿主机的一些配置"
echo "docker调优"
echo "关闭selinux"
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

echo "修改时区为上海"
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

echo "修改系统语言环境"
echo 'LANG="en_US.UTF-8"' >> /etc/profile;source /etc/profile

echo "同步时间"
yum install -y ntp
ntpdate pool.ntp.org
systemctl start ntpd
systemctl enable ntpd
systemctl status ntpd
ntpdate -u  pool.ntp.org
echo '*/5 * * * * /usr/sbin/ntpdate -u  pool.ntp.org >/dev/null 2>&1' >/var/spool/cron/root

echo "kernel性能调优:"
echo "1、修复可能出现的网络问题"
echo "2、修改最大进程数"
tee /etc/sysctl.conf <<-'EOF'
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-iptables=1
net.ipv4.neigh.default.gc_thresh1=4096
net.ipv4.neigh.default.gc_thresh2=6144
net.ipv4.neigh.default.gc_thresh3=8192
net.core.netdev_max_backlog = 2500
net.core.somaxconn = 80000
net.ipv4.tcp_rmem = 4096 87380   16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.rmem_default = 1048576
net.core.wmem_default = 524288
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_max_syn_backlog = 102400

fs.aio-max-nr = 3145728
kernel.pid_max=4194303
vm.max_map_count=128048575
EOF
echo 'ulimit -n 1000000' >> /etc/profile
ulimit -l unlimited
ulimit -a


sysctl -p
systemctl restart network

sudo cat >> /root/.profile<<EOF
echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled
echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag
EOF

# 开启cpu性能模式
for CPUFREQ in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do [ -f $CPUFREQ ] || continue; echo -n performance > $CPUFREQ; done

# 合理磁盘预读
echo "8192" > /sys/block/sda/queue/read_ahead_kb
# 禁止cpu卡死
echo 0 > /proc/sys/kernel/hung_task_timeout_secs
echo "关闭防火墙"
firewall-cmd --state
systemctl stop firewalld.service
systemctl disable firewalld.service

# 修改主机名
yum install -y  net-tools
hostnamectl set-hostname `ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`