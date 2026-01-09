# Kubernetes 集群环境检查报告

## 检查时间
2026-01-09 15:33 (JST)

## 节点概览

| 节点 | IP地址 | 主机名 | 状态 |
|------|--------|--------|------|
| Master | 192.168.0.200 | bacon | ✅ 可连接 |
| Worker-1 | 192.168.0.201 | bacon | ✅ 可连接 |
| Worker-2 | 192.168.0.202 | bacon | ✅ 可连接 |

## 详细检查结果

### ✅ 已正确配置的项目

1. **Kubernetes 组件** - 所有节点
   - kubeadm: v1.30.14 ✅
   - kubelet: v1.30.14 ✅
   - kubectl: v1.30.14 ✅

2. **containerd** - 所有节点
   - 状态: active ✅
   - 开机启动: enabled ✅

3. **Swap 分区** - 所有节点
   - 状态: 已禁用 ✅

4. **/etc/hosts 配置** - 所有节点
   - 包含主机映射（但IP地址需要更新）:
     ```
     192.168.0.100 k8s-master-01
     192.168.0.101 k8s-worker-01
     192.168.0.102 k8s-worker-02
     ```

### ⚠️ 需要修复的问题

1. **主机名不一致** - 所有节点
   - 当前: 所有节点主机名都是 "bacon"
   - 问题: 无法区分不同节点
   - 建议修改为:
     - 192.168.0.200 → master
     - 192.168.0.201 → worker-1
     - 192.168.0.202 → worker-2

2. **containerd SystemdCgroup 配置** - 所有节点
   - 当前: `SystemdCgroup = false` ⚠️
   - 需要: `SystemdCgroup = true`
   - 影响: 这会导致 kubeadm init 失败

3. **br_netfilter 内核模块** - 所有节点
   - 状态: 未加载 ⚠️
   - 需要: 加载该模块以支持网络桥接

4. **/etc/hosts IP 地址不匹配** - 所有节点
   - 配置的IP: 192.168.0.100-102
   - 实际IP: 192.168.0.200-202
   - 需要更新映射

5. **可能存在旧的初始化残留**
   - 所有节点都有 `/etc/kubernetes/manifests` 目录
   - 但没有 Kubernetes 进程运行
   - 建议: 清理后重新初始化

## 修复计划

### 阶段 1: 清理和准备（所有节点）

1. 清理可能的旧配置
   ```bash
   sudo kubeadm reset -f
   sudo rm -rf /etc/kubernetes/
   sudo rm -rf /var/lib/etcd/
   sudo rm -rf /var/lib/kubelet/*
   sudo rm -rf ~/.kube/
   ```

2. 修改主机名
   ```bash
   # master 节点
   sudo hostnamectl set-hostname master
   
   # worker-1 节点
   sudo hostnamectl set-hostname worker-1
   
   # worker-2 节点
   sudo hostnamectl set-hostname worker-2
   ```

3. 更新 /etc/hosts
   ```bash
   sudo tee -a /etc/hosts <<EOF
   192.168.0.200 master
   192.168.0.201 worker-1
   192.168.0.202 worker-2
   EOF
   ```

4. 修复 containerd 配置
   ```bash
   # 修改 SystemdCgroup 为 true
   sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
   sudo systemctl restart containerd
   ```

5. 加载内核模块
   ```bash
   sudo modprobe br_netfilter
   sudo modprobe overlay
   ```

### 阶段 2: 初始化 Master 节点

```bash
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=192.168.0.200 \
  --control-plane-endpoint=master:6443 \
  --kubernetes-version=v1.30.14
```

### 阶段 3: 加入 Worker 节点

使用 master 初始化后生成的 join 命令

## 风险评估

- **低风险**: 基础环境配置良好，只需要少量调整
- **可控**: 问题都可以通过配置文件修改解决
- **建议**: 先清理旧配置，避免冲突

## 下一步操作

建议按照修复计划逐步执行，每个阶段完成后验证状态。
