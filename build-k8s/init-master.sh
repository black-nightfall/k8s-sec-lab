#!/bin/bash
# 初始化 Master 节点

echo "=== 开始初始化 Kubernetes Master 节点 ==="

# 初始化集群
 sudo -S kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=192.168.0.200 \
  --control-plane-endpoint=master:6443 \
  --kubernetes-version=v1.30.14

# 检查初始化结果
if [ $? -eq 0 ]; then
    echo -e "\n=== Master 节点初始化成功 ==="
    
    # 配置 kubectl
    echo -e "\n配置 kubectl..."
    mkdir -p $HOME/.kube
     sudo -S cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
     sudo -S chown $(id -u):$(id -g) $HOME/.kube/config
    
    echo -e "\n检查节点状态:"
    kubectl get nodes
    
    echo -e "\n=== 初始化完成 ==="
else
    echo -e "\n=== Master 节点初始化失败 ==="
    exit 1
fi
