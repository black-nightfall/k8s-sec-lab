#!/bin/bash
# Kubernetes 环境检查脚本

HOST=$1
if [ -z "$HOST" ]; then
    echo "使用方法: $0 <hostname|ip>"
    exit 1
fi

echo "========================================"
echo "检查节点: $HOST"
echo "========================================"

# 执行检查命令
ssh username@$HOST << 'ENDSSH'
echo "1. 主机名和IP地址:"
hostname
ip addr show | grep "inet " | grep -v "127.0.0.1"

echo -e "\n2. Kubernetes 组件版本:"
kubeadm version 2>/dev/null || echo "kubeadm 未安装"
kubelet --version 2>/dev/null || echo "kubelet 未安装"
kubectl version --client 2>/dev/null || echo "kubectl 未安装"

echo -e "\n3. containerd 状态:"
sudo systemctl is-active containerd
sudo systemctl is-enabled containerd

echo -e "\n4. 检查 Kubernetes 是否已初始化:"
if sudo test -d /etc/kubernetes/manifests; then
    echo "已初始化 - 发现 /etc/kubernetes/ 目录"
    sudo ls -la /etc/kubernetes/ 2>&1 | head -10
else
    echo "未初始化 - /etc/kubernetes/ 不存在"
fi

echo -e "\n5. Swap 状态:"
free -h | grep Swap
swapon --show

echo -e "\n6. /etc/hosts 配置:"
cat /etc/hosts | grep -E "192.168.0|k8s|master|worker"

echo -e "\n7. containerd 配置检查:"
if sudo test -f /etc/containerd/config.toml; then
    echo "containerd config.toml 存在"
    echo "SystemdCgroup 设置:"
    sudo grep "SystemdCgroup" /etc/containerd/config.toml || echo "未找到 SystemdCgroup 配置"
else
    echo "containerd config.toml 不存在"
fi

echo -e "\n8. 内核模块:"
lsmod | grep br_netfilter

echo -e "\n9. 已运行的 Kubernetes 进程:"
ps aux | grep -E "kube|etcd" | grep -v grep | head -5 || echo "无 Kubernetes 进程"

ENDSSH

echo -e "\n检查完成: $HOST"
echo "========================================"
