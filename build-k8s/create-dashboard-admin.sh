#!/bin/bash
# 创建 Dashboard 管理员用户

echo "=== 创建 Dashboard 管理员用户 ==="

# 1. 创建 ServiceAccount
echo "1. 创建 admin-user ServiceAccount..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# 2. 创建 ClusterRoleBinding
echo -e "\n2. 创建 ClusterRoleBinding..."
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# 3. 等待一下
sleep 2

# 4. 创建 token
echo -e "\n3. 创建访问 token..."
kubectl -n kubernetes-dashboard create token admin-user --duration=876000h > /tmp/dashboard-token.txt

echo -e "\n=== 管理员用户创建完成 ==="
echo -e "\n访问 Token 已保存到 /tmp/dashboard-token.txt"
echo -e "\n显示 Token:"
cat /tmp/dashboard-token.txt

echo -e "\n\n=== 检查 Dashboard 状态 ==="
kubectl get pods -n kubernetes-dashboard
kubectl get svc -n kubernetes-dashboard
