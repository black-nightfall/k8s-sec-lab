#!/bin/bash
# 直接在远程节点执行的检查脚本

echo "1. 主机名和IP地址:"
hostname
ip addr show | grep "inet " | grep -v "127.0.0.1"

echo -e "\n2. Kubernetes 组件版本:"
kubeadm version 2>/dev/null || echo "kubeadm 未安装"
kubelet --version 2>/dev/null || echo "kubelet 未安装"
kubectl version --client 2>/dev/null || echo "kubectl 未安装"

echo -e "\n3. containerd 状态:"
 sudo -S systemctl is-active containerd 2>/dev/null
 sudo -S systemctl is-enabled containerd 2>/dev/null

echo -e "\n4. 检查 Kubernetes 是否已初始化:"
if  sudo -S test -d /etc/kubernetes/manifests 2>/dev/null; then
    echo "已初始化 - 发现 /etc/kubernetes/ 目录"
     sudo -S ls -la /etc/kubernetes/ 2>/dev/null | head -10
else
    echo "未初始化 - /etc/kubernetes/ 不存在或无访问权限"
fi

echo -e "\n5. Swap 状态:"
free -h | grep Swap
swapon --show 2>/dev/null || echo "无 swap 分区"

echo -e "\n6. /etc/hosts 配置:"
cat /etc/hosts | tail -10

echo -e "\n7. containerd 配置检查:"
if  sudo -S test -f /etc/containerd/config.toml 2>/dev/null; then
    echo "containerd config.toml 存在"
    echo "SystemdCgroup 设置:"
     sudo -S grep "SystemdCgroup" /etc/containerd/config.toml 2>/dev/null || echo "未找到 SystemdCgroup 配置"
else
    echo "containerd config.toml 不存在"
fi

echo -e "\n8. 内核模块:"
lsmod | grep br_netfilter || echo "br_netfilter 未加载"

echo -e "\n9. 已运行的 Kubernetes 进程:"
ps aux | grep -E "kube|etcd" | grep -v grep | head -5 || echo "无 Kubernetes 进程运行"

echo -e "\n10. 核心镜像列表:"
 sudo -S crictl images 2>/dev/null | head -10 || echo "无镜像或crictl未配置"
