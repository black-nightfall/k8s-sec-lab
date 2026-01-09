# Kubernetes Dashboard 访问信息

## 访问 Token

```
eyJhbGciOiJSUzI1NiIsImtpZCI6IkNIMDlva0dGV00tUkFPcnpPWTZJRWVEbmtBU2hQZ1gxYmNpUXBSZWJVbFkifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjo0OTIxNTQzNjE3LCJpYXQiOjE3Njc5NDM2MTcsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwianRpIjoiZTcyYWMxNjUtNGZkMi00OTc0LWFlNTMtYjY5NDQzZmMwZDA3Iiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsInNlcnZpY2VhY2NvdW50Ijp7Im5hbWUiOiJhZG1pbi11c2VyIiwidWlkIjoiODg2MjRhY2QtOTgyNi00ZDNjLWIxNzUtMWE4OTQ0NzNhYmI4In19LCJuYmYiOjE3Njc5NDM2MTcsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlcm5ldGVzLWRhc2hib2FyZDphZG1pbi11c2VyIn0.mVHVO9JbwMhm7yyOHAd6U7TXSZOxsMl50FHJ1PEcyYyBtUQMbJzYACBwxvwJB9XqKUGKxQpuQmpIWBPzpvs1AUiJ7Uza4wrCtqDZdNG0KBcOUjYQsDH17vjHVkLYwLyrXS3FUIMcgHy6evbugjThVmtB-4cMGC-Ft3Su31K3nES2Su0qOUG8Q_cJ1YHgv0UTh77GKi9_yOto9PoRj84Ly2aN319SbJN5mRjc3_y9Gk_CbWlFrSBnV1p0Hk9qsMxI33ZcTKUuh2F9ozyqFmRQnAu8djGklnIz8uEijwZDzgOckMJTbMqZ1ecqviCBaZb4uUwCg2jeci62i1cmEgvvtw
```

**Token 有效期**: 100 年（直到 2126 年）

## 访问方式

### 方式一：kubectl proxy（推荐本地访问）

1. 在 master 节点上启动 proxy：
   ```bash
   kubectl proxy
   ```

2. 从本地机器使用 SSH 端口转发：
   ```bash
   ssh -L 8001:localhost:8001 username@192.168.0.200
   # 在远程执行: kubectl proxy --port=8001
   ```

3. 访问地址：
   ```
   http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
   ```

### 方式二：NodePort（永久暴露 - 当前已配置）

1. 访问地址（端口 32237）：
   ```
   https://192.168.0.200:32237
   https://192.168.0.201:32237
   https://192.168.0.202:32237
   ```

2. 恢复为默认 ClusterIP（如需关闭）：
   ```bash
   kubectl -n kubernetes-dashboard patch svc kubernetes-dashboard -p '{"spec":{"type":"ClusterIP"}}'
   ```

### 方式三：端口转发（最简单）

1. 设置端口转发：
   ```bash
   kubectl -n kubernetes-dashboard port-forward --address 0.0.0.0 svc/kubernetes-dashboard 8443:443
   ```

2. 访问地址：
   ```
   https://192.168.0.200:8443
   ```

## 登录流程

1. 打开 Dashboard URL
2. 选择 "Token" 登录方式
3. 粘贴上面的访问 Token
4. 点击 "登录"

## 管理员用户信息

- **ServiceAccount**: admin-user
- **Namespace**: kubernetes-dashboard
- **权限**: cluster-admin（完全管理权限）

## 重新生成 Token

如果需要重新生成 Token：

```bash
kubectl -n kubernetes-dashboard create token admin-user --duration=876000h
```

## Dashboard 状态

查看 Dashboard 运行状态：

```bash
kubectl get pods -n kubernetes-dashboard
kubectl get svc -n kubernetes-dashboard
```

## 卸载 Dashboard

如果需要卸载：

```bash
kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
kubectl delete sa admin-user -n kubernetes-dashboard
kubectl delete clusterrolebinding admin-user
```

---

**安装日期**: 2026-01-09
**Dashboard 版本**: v2.7.0
