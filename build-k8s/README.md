# Kubernetes 集群搭建完整流程（中文）

## 目录
- [环境概述](#环境概述)
- [前期准备](#前期准备)
- [集群搭建步骤](#集群搭建步骤)
- [问题记录与解决方案](#问题记录与解决方案)
- [验证测试](#验证测试)
- [常用运维命令](#常用运维命令)
- [集群访问信息](#集群访问信息)

---

## 环境概述

### 用途
本 Kubernetes 集群用于**本地云安全实验**和**开发实验**，提供以下功能：
- 容器安全、网络策略、RBAC 权限测试
- 漏洞复现和安全研究
- 应用部署、CI/CD 测试
- 微服务架构验证

### 集群架构

| 节点角色 | 主机名 | IP 地址 | 操作系统 | 配置 |
|----------|--------|---------|----------|------|
| Master | master | 192.168.0.200 | Ubuntu 24.04.3 LTS | 控制平面节点 |
| Worker | worker-1 | 192.168.0.201 | Ubuntu 24.04.3 LTS | 工作节点 |
| Worker | worker-2 | 192.168.0.202 | Ubuntu 24.04.3 LTS | 工作节点 |

### 软件版本

- **Kubernetes**: v1.30.14
- **containerd**: 1.7.28
- **网络插件**: Cilium v1.14.5 (替代 Flannel)
- **Pod 网络 CIDR**: 10.244.0.0/16

---

## 前期准备

### 1. 基础系统配置（所有节点已完成）

以下配置在搭建前已完成：

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装基础工具
sudo apt install -y curl wget vim net-tools iproute2 telnet traceroute \
  software-properties-common apt-transport-https ca-certificates bash-completion git

# 禁用 Swap
sudo swapoff -a
sudo sed -i '/swap/s/^/#/' /etc/fstab

# 配置内核参数
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
vm.swappiness = 0
EOF

# 加载内核模块
sudo modprobe br_netfilter
sudo modprobe overlay
sudo sysctl --system

# 禁用防火墙
sudo ufw disable

# 安装时间同步
sudo apt install -y chrony
sudo systemctl enable --now chronyd

# 安装 containerd
sudo apt install -y containerd runc

# 添加 Kubernetes 软件源
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/kubernetes.gpg
echo "deb https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

# 安装 Kubernetes 组件
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo systemctl enable kubelet
```

---

## 集群搭建步骤

### 步骤 1: 清理旧配置（所有节点）

如果之前有过失败的安装尝试，需要先清理：

```bash
# 重置 kubeadm
 sudo -S kubeadm reset -f

# 清理配置文件
sudo rm -rf /etc/kubernetes/
sudo rm -rf /var/lib/etcd/
sudo rm -rf /var/lib/kubelet/*
rm -rf ~/.kube/
```

### 步骤 2: 修复 containerd 配置（所有节点）

> [!IMPORTANT]
> 这是最关键的步骤，containerd 的 SystemdCgroup 配置必须正确

```bash
# 删除旧配置
sudo rm -f /etc/containerd/config.toml

# 生成新的默认配置
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

# 修改 SystemdCgroup 为 true
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# 验证配置
sudo grep "SystemdCgroup" /etc/containerd/config.toml
# 应该显示: SystemdCgroup = true

# 清理 CNI 配置冲突
sudo rm -rf /etc/cni/net.d/*

# 重启 containerd
sudo systemctl daemon-reload
sudo systemctl restart containerd
sudo systemctl status containerd

# 测试 containerd
sudo crictl info | head -20
```

### 步骤 3: 配置主机名和 Hosts（所有节点）

**Master 节点 (192.168.0.200):**
```bash
# 设置主机名
sudo hostnamectl set-hostname master

# 添加 hosts 映射
sudo tee -a /etc/hosts <<EOF

# Kubernetes Cluster
192.168.0.200 master
192.168.0.201 worker-1
192.168.0.202 worker-2
EOF
```

**Worker-1 节点 (192.168.0.201):**
```bash
# 设置主机名
sudo hostnamectl set-hostname worker-1

# 添加 hosts 映射
sudo tee -a /etc/hosts <<EOF

# Kubernetes Cluster
192.168.0.200 master
192.168.0.201 worker-1
192.168.0.202 worker-2
EOF
```

**Worker-2 节点 (192.168.0.202):**
```bash
# 设置主机名
sudo hostnamectl set-hostname worker-2

# 添加 hosts 映射
sudo tee -a /etc/hosts <<EOF

# Kubernetes Cluster
192.168.0.200 master
192.168.0.201 worker-1
192.168.0.202 worker-2
EOF
```

### 步骤 4: 初始化 Master 节点

**仅在 Master 节点上执行：**

```bash
# 初始化集群
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=192.168.0.200 \
  --control-plane-endpoint=master:6443 \
  --kubernetes-version=v1.30.14

# 配置 kubectl（普通用户）
mkdir -p $HOME/.kube
sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 验证节点状态（此时 master 是 NotReady，等待网络插件）
kubectl get nodes
```

> [!NOTE]
> 初始化成功后会显示 join 命令，**务必保存**此命令，用于后续 worker 节点加入

### 步骤 5: 安装网络插件 Cilium

我们使用 Helm 安装 Cilium，并启用 Hubble 进行网络可观测性。

**在 Master 节点上执行：**

```bash
# 1. 安装 Helm (如果尚未安装)
wget https://get.helm.sh/helm-v3.14.4-linux-arm64.tar.gz
tar -zxvf helm-v3.14.4-linux-arm64.tar.gz
sudo mv linux-arm64/helm /usr/local/bin/helm

# 2. 安装 Cilium
helm repo add cilium https://helm.cilium.io/
helm repo update
helm install cilium cilium/cilium --version 1.14.5 \
   --namespace kube-system \
   --set ipam.mode=kubernetes \
   --set hubble.enabled=true \
   --set hubble.relay.enabled=true \
   --set hubble.ui.enabled=true

# 3. 验证安装
kubectl get pods -n kube-system -l k8s-app=cilium --watch
```

### 步骤 6: 加入 Worker 节点

**在 Worker-1 和 Worker-2 节点上执行：**

使用 master 初始化时输出的 join 命令：

```bash
sudo kubeadm join master:6443 \
  --token <your-token> \
  --discovery-token-ca-cert-hash sha256:<your-hash>
```

> [!TIP]
> 如果 token 过期或丢失，可以在 master 节点上运行 `kubeadm token create --print-join-command` 生成新的

### 步骤 7: 验证集群

**在 Master 节点上检查：**

```bash
# 查看所有节点（应该都是 Ready）
kubectl get nodes -o wide

# 查看所有 Pods
kubectl get pods -A

# 查看系统组件状态
kubectl get componentstatuses
```

---

## 问题记录与解决方案

### 问题 1: containerd CRI 错误

**现象：**
```
ERROR CRI: container runtime is not running: rpc error: code = Unimplemented 
desc = unknown service runtime.v1.RuntimeService
```

**原因：**
- containerd 配置中 `SystemdCgroup = false`
- 需要改为 `SystemdCgroup = true` 以支持 systemd cgroup驱动

**解决方案：**
```bash
# 重新生成配置文件
sudo rm -f /etc/containerd/config.toml
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
```

### 问题 2: Worker 节点长时间 NotReady

**现象：**
- Worker 节点状态为 NotReady
- Flannel Pods 停留在 Init:0/2 或 Init:1/2 状态
- kubelet 日志显示 "Network plugin returns error: cni plugin not initialized"

**原因：**
- Flannel 镜像拉取缓慢
- 初始化容器正在下载镜像

**解决方案：**
```bash
# 等待镜像拉取完成（可能需要 5-10 分钟，取决于网络速度）
kubectl get pods -n kube-flannel --watch

# 检查镜像拉取进度
kubectl describe pod -n kube-flannel <pod-name>

# 在 worker 节点上检查镜像
sudo crictl images
```

### 问题 3: 主机名冲突

**现象：**
- 所有节点的主机名都相同
- 无法区分不同节点

**原因：**
- 虚拟机克隆后没有修改主机名

**解决方案：**
```bash
# 在各节点上设置不同的主机名
sudo hostnamectl set-hostname <master|worker-1|worker-2>

# 重新登录查看
hostname
```

### 问题 4: /etc/hosts IP 地址不匹配

**现象：**
- hosts 文件中配置的 IP 与实际不符

**原因：**
- 复制了其他环境的配置

**解决方案：**
```bash
# 确保 /etc/hosts 包含正确的 IP 映射
192.168.0.200 master
192.168.0.201 worker-1
192.168.0.202 worker-2
```

---

## 验证测试

### 基础集群测试

```bash
# 1. 查看集群信息
kubectl cluster-info

# 2. 查看所有节点
kubectl get nodes -o wide

# 预期输出：
# NAME       STATUS   ROLES           AGE   VERSION
# master     Ready    control-plane   25m   v1.30.14
# worker-1   Ready    <none>          15m   v1.30.14
# worker-2   Ready    <none>          13m   v1.30.14
```

### 部署测试应用

```bash
# 创建 nginx deployment
kubectl create deployment nginx --image=nginx --replicas=3

# 暴露服务
kubectl expose deployment nginx --port=80 --type=NodePort

# 查看部署状态
kubectl get deployment,svc,pods -o wide

# 获取 NodePort
kubectl get svc nginx

# 测试访问（使用上面获取的 NodePort）
curl http://192.168.0.200:<NodePort>
curl http://192.168.0.201:<NodePort>
curl http://192.168.0.202:<NodePort>
```

### Pod 网络连通性测试

```bash
# 查看 Pod IP
kubectl get pods -o wide

# 进入一个 Pod
kubectl exec -it <pod-name> -- /bin/bash

# 从 Pod 内部 ping 其他 Pod
ping <another-pod-ip>

# 测试 DNS 解析
nslookup kubernetes.default
```

---

---
## Cilium & Hubble 可观测性

### 验证 Cilium 状态

```bash
# 查看 Cilium Pods
kubectl get pods -n kube-system -l k8s-app=cilium

# (可选) 使用 Cilium CLI 检查
# cilium status
```

### 访问 Hubble UI (网络拓扑图)

Hubble UI 提供了实时的服务依赖图和流量监控。

```bash
# 设置端口转发
kubectl port-forward -n kube-system svc/hubble-ui --address 0.0.0.0 8888:80
```

访问地址：http://192.168.0.200:8888

---

## 常用运维命令

### 节点管理

```bash
# 查看节点详细信息
kubectl describe node master

# 标记节点不可调度
kubectl cordon worker-1

# 恢复节点调度
kubectl uncordon worker-1

# 驱逐节点上的 Pods
kubectl drain worker-1 --ignore-daemonsets

# 删除节点
kubectl delete node worker-1
```

### Pod 管理

```bash
# 查看所有命名空间的 Pods
kubectl get pods -A

# 查看 Pod 日志
kubectl logs <pod-name>
kubectl logs -f <pod-name>  # 实时查看

# 查看 Pod 详细信息
kubectl describe pod <pod-name>

# 进入 Pod
kubectl exec -it <pod-name> -- /bin/bash

# 删除 Pod
kubectl delete pod <pod-name>
```

### 命名空间管理

```bash
# 查看所有命名空间
kubectl get namespaces

# 创建命名空间
kubectl create namespace dev

# 删除命名空间
kubectl delete namespace dev

# 在指定命名空间操作
kubectl get pods -n kube-system
```

### 排错命令

```bash
# 查看集群事件
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# 查看节点资源使用（需要安装 metrics-server）
kubectl top nodes
kubectl top pods

# 检查集群组件状态
kubectl get cs

# 查看 API 资源
kubectl api-resources

# 检查 kubelet 日志
sudo journalctl -u kubelet -f

# 检查 containerd 日志
sudo journalctl -u containerd -f
```

### Token 管理

```bash
# 查看现有 token
kubeadm token list

# 创建新 token
kubeadm token create

# 生成完整的 join 命令
kubeadm token create --print-join-command

# Token 默认有效期为 24 小时
```

---

## 集群访问信息

### Master 节点

- **主机名**: master
- **IP**: 192.168.0.200
- **API Server**: https://192.168.0.200:6443
- **用户**: username
- **密码**: 

### Worker 节点

| 节点 | 主机名 | IP | 用户 | 密码 |
|------|--------|-----|------|------|
| Worker-1 | worker-1 | 192.168.0.201 | username |  |
| Worker-2 | worker-2 | 192.168.0.202 | username |  |

### kubectl 配置

**配置文件位置：**
```
~/.kube/config  # username 用户
/etc/kubernetes/admin.conf  # root 用户
```

**远程访问：**
```bash
# 从 master 节点复制 kubeconfig 到本地
scp username@192.168.0.200:~/.kube/config ~/.kube/config

# 修改 server 地址为 master IP
server: https://192.168.0.200:6443
```

### Join 命令（当前有效）

```bash
# Worker 节点加入命令
sudo kubeadm join master:6443 \
  --token emkmv9.tk6nigk5m1w0yfbg \
  --discovery-token-ca-cert-hash sha256:9127dc03974a0f3c636849dd7d7ccf8fb6983633d20a4a487044f2b92d905054
```

> [!WARNING]
> Token 有效期为 24 小时，过期后需要在 master 节点重新生成

### 网络配置

- **Pod Network CIDR**: 10.244.0.0/16
- **Service CIDR**: 10.96.0.0/12（默认）
- **DNS Service IP**: 10.96.0.10

---

## Kubernetes Dashboard 安装（可选）

### 安装步骤

#### 1. 部署 Dashboard

```bash
# 应用官方 Dashboard 配置
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# 等待 Pods 启动
kubectl get pods -n kubernetes-dashboard --watch
```

#### 9. 更换网络插件 (Flannel -> Cilium) 常见问题

**现象**:
- Kubernetes Dashboard 报错 `dial tcp 10.96.0.1:443: i/o timeout`
- Hubble Relay Pod 状态为 `ErrImagePull` 或 `CrashLoopBackOff`

**原因**:
- 网络插件切换后，旧的 iptables 规则或连接状态可能残留，导致 Pod 无法访问 Service (ClusterIP)。
- `quay.io` 镜像仓库在国内或特定网络环境下可能连接不稳定。

**全套修复方案**:

1. **手动拉取镜像 (针对 ErrImagePull)**:
   ```bash
   # 在所有 worker 节点执行
   crictl pull quay.io/cilium/hubble-relay:v1.14.5
   ```

2. **强制重启网络组件 (刷新规则)**:
   ```bash
   # 重启 kube-proxy 和 Cilium Agent
   kubectl -n kube-system rollout restart ds/kube-proxy
   kubectl -n kube-system rollout restart ds/cilium
   
   # 重启受影响的服务 (如 Dashboard, Hubble Relay)
   kubectl -n kube-system rollout restart deployment/hubble-relay
   kubectl -n kubernetes-dashboard rollout restart deployment/kubernetes-dashboard
   ```

3. **验证连通性**:
   ```bash
   # 测试 Pod 到 API Server 的连接
   kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never \
     -- curl -k -v https://10.96.0.1:443
   ```
   *如果返回 HTTP 403 Forbidden，说明 TCP 连接正常，网络已恢复。*

#### 2. 创建管理员用户

```bash
# 创建 ServiceAccount
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# 创建 ClusterRoleBinding
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
```

#### 3. 获取访问 Token

```bash
# 创建长期有效的 token（100 年）
kubectl -n kubernetes-dashboard create token admin-user --duration=876000h
```

> [!IMPORTANT]
> 请妥善保存生成的 Token，这是登录 Dashboard 的唯一凭证

### 访问 Dashboard

有三种方式可以访问 Dashboard：

#### 方式一：kubectl proxy（推荐本地测试）

1. 在 master 节点启动 proxy：
   ```bash
   kubectl proxy --port=8001
   ```

2. 如果从本地机器访问，使用 SSH 端口转发：
   ```bash
   ssh -L 8001:localhost:8001 username@192.168.0.200
   # 在 SSH 会话中执行: kubectl proxy --port=8001
   ```

3. 访问地址：
   ```
   http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
   ```

#### 方式二：NodePort（永久暴露 - 当前已配置）

1. 访问地址（端口 32237）：
   ```
   https://192.168.0.200:32237
   https://192.168.0.201:32237
   https://192.168.0.202:32237
   ```

#### 方式三：端口转发（最简单）

1. 设置端口转发（监听所有网卡接口）：
   ```bash
   kubectl -n kubernetes-dashboard port-forward --address 0.0.0.0 \
     svc/kubernetes-dashboard 8443:443
   ```

2. 访问地址：
   ```
   https://192.168.0.200:8443
   ```

### 登录步骤

1. 打开浏览器访问 Dashboard URL
2. 选择 **Token** 登录方式
3. 粘贴之前生成的访问 Token
4. 点击 **登录**

> [!TIP]
> 浏览器会提示证书不安全（自签名证书），点击"高级"→"继续访问"即可

### Dashboard 运维

#### 查看状态

```bash
# 查看 Dashboard Pods
kubectl get pods -n kubernetes-dashboard

# 查看 Dashboard Services
kubectl get svc -n kubernetes-dashboard

# 查看 Dashboard 详细信息
kubectl describe pod -n kubernetes-dashboard <pod-name>
```

#### 重启 Dashboard

```bash
# 重启 Dashboard Pod
kubectl -n kubernetes-dashboard rollout restart deployment kubernetes-dashboard

# 查看重启状态
kubectl -n kubernetes-dashboard rollout status deployment kubernetes-dashboard
```

#### 重新生成 Token

```bash
# 生成新的 token
kubectl -n kubernetes-dashboard create token admin-user --duration=876000h
```

#### 卸载 Dashboard

```bash
# 删除 Dashboard
kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# 删除管理员用户
kubectl delete sa admin-user -n kubernetes-dashboard
kubectl delete clusterrolebinding admin-user
```

### 安全建议

1. **Token 管理**: 不要将 Token 提交到代码库，建议使用密码管理器保存
2. **访问控制**: 生产环境中避免使用 cluster-admin 权限，应创建权限受限的用户
3. **HTTPS**: Dashboard 默认使用自签名证书，生产环境建议配置可信证书
4. **网络隔离**: 建议通过 VPN 或 SSH 隧道访问，避免直接暴露到公网

### Dashboard 功能

Dashboard 提供以下功能：
- 查看集群资源（Nodes, Namespaces, Pods, Deployments, Services 等）
- 查看 Pod 日志和进入容器终端
- 创建、编辑、删除资源
- 监控资源使用情况
- 查看集群事件
- 部署应用（通过 YAML 或表单）

---

## 后续步骤

### 推荐安装的其他组件

1. ✅ **Kubernetes Dashboard** - Web UI 管理界面（已安装）
2. **Metrics Server** - 资源监控
3. **Ingress Controller** - 流量管理
4. **Local Path Provisioner** - 本地持久化存储
5. **Helm** - 包管理工具

详细安装步骤请参考相关文档。

### 安全建议

对于安全实验环境：
1. 定期备份 etcd 数据
2. 启用 RBAC 权限控制
3. 配置 Network Policies
4. 使用 Pod Security Standards
5. 启用审计日志

---
