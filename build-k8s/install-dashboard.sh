#!/bin/bash
# 安装 Kubernetes Dashboard

echo "=== 安装 Kubernetes Dashboard ==="

# 1. 部署 Dashboard
echo "1. 部署 Kubernetes Dashboard..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# 等待部署完成
echo -e "\n2. 等待 Dashboard 启动..."
sleep 10

# 检查 Dashboard Pods
echo -e "\n3. 检查 Dashboard 状态:"
kubectl get pods -n kubernetes-dashboard

# 检查 Service
echo -e "\n4. 检查 Dashboard Service:"
kubectl get svc -n kubernetes-dashboard

echo -e "\n=== Dashboard 部署完成 ==="
echo "接下来需要创建管理员用户和获取访问 token"
