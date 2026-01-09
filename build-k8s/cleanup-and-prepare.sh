#!/bin/bash
# 清理和准备脚本 - 在所有节点上运行

echo "=== 开始清理和准备节点 ==="

# 1. 清理旧的 Kubernetes 配置
echo "1. 清理旧配置..."
 sudo -S kubeadm reset -f 2>/dev/null || echo "没有需要重置的配置"
 sudo -S rm -rf /etc/kubernetes/ 2>/dev/null
 sudo -S rm -rf /var/lib/etcd/ 2>/dev/null
 sudo -S rm -rf /var/lib/kubelet/* 2>/dev/null
rm -rf ~/.kube/ 2>/dev/null
echo "清理完成"

# 2. 修复 containerd 配置
echo -e "\n2. 修复 containerd 配置..."
 sudo -S sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
 sudo -S systemctl restart containerd
sleep 2
 sudo -S systemctl status containerd --no-pager | head -3
echo "containerd 配置完成"

# 3. 加载内核模块
echo -e "\n3. 加载内核模块..."
 sudo -S modprobe br_netfilter
 sudo -S modprobe overlay
lsmod | grep -E "br_netfilter|overlay"
echo "内核模块加载完成"

# 4. 确保内核参数生效
echo -e "\n4. 应用内核参数..."
 sudo -S sysctl --system 2>/dev/null | tail -5
echo "内核参数应用完成"

echo -e "\n=== 清理和准备完成 ==="
