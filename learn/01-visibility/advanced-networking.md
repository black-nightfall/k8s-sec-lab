# 🔍 进阶：网络可视化 (Cilium & Hubble)

> **前置要求**: 完成阶段1的k8s基础学习

**目标**: 升级集群网络层，获得强大的可观测性能力。

> **概念站**:
> *   **CNI (Cilium)**: 基于 eBPF 的高性能容器网络接口，提供网络、安全和可观测性功能。
> *   **Hubble**: Cilium 的可观测性层，可视化服务间的网络流量和依赖关系。
> *   **eBPF**: Linux 内核技术，可以在不修改内核代码的情况下运行沙盒程序。

## 📝 学习任务

### 第一部分：理解 CNI

* [ ] **什么是 CNI**
  * 容器网络接口 (Container Network Interface)
  * 为什么需要 CNI（Pod 间通信、Service 网络、NetworkPolicy）
  * 常见 CNI 对比：Flannel, Calico, Cilium, Weave

* [ ] **Cilium 的优势**
  * 基于 eBPF，性能更高
  * 原生支持 L7 协议（HTTP, gRPC, Kafka）
  * 强大的网络策略和安全功能
  * 内置可观测性 (Hubble)

### 第二部分：从 Flannel/默认 CNI 迁移到 Cilium

> ⚠️ **警告**: 切换 CNI 会导致网络中断，请在测试环境操作

* [ ] **检查当前 CNI**
  ```bash
  # 查看当前网络插件
  kubectl get pods -n kube-system | grep -E 'flannel|calico|cilium'
  
  # 查看 Pod 网络配置
  kubectl get nodes -o jsonpath='{.items[*].spec.podCIDR}'
  ```

* [ ] **安装 Cilium CLI**
  ```bash
  # macOS
  brew install cilium-cli
  
  # 或者使用官方脚本
  curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-darwin-amd64.tar.gz
  sudo tar xzvfC cilium-darwin-amd64.tar.gz /usr/local/bin
  ```

* [ ] **部署 Cilium**
  ```bash
  # 删除旧的 CNI（如果是 Flannel）
  kubectl delete -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
  
  # 安装 Cilium
  cilium install --version 1.14.5
  
  # 等待 Cilium 就绪
  cilium status --wait
  
  # 验证安装
  kubectl get pods -n kube-system -l k8s-app=cilium
  ```

* [ ] **连通性测试**
  ```bash
  # 运行 Cilium 连通性测试
  cilium connectivity test
  ```

### 第三部分：启用 Hubble 可观测性

* [ ] **部署 Hubble UI**
  ```bash
  # 启用 Hubble
  cilium hubble enable --ui
  
  # 等待 Hubble 就绪
  cilium status
  
  # 端口转发访问 UI
  cilium hubble ui
  ```
  访问：http://localhost:12000

* [ ] **使用 Hubble CLI**
  ```bash
  # 安装 Hubble CLI
  brew install hubble
  
  # 端口转发 Hubble Relay
  cilium hubble port-forward &
  
  # 观察流量
  hubble observe
  hubble observe --namespace default
  hubble observe --pod nginx
  ```

### 第四部分：实战演练

* [ ] **基础流量观察**
  ```bash
  # 部署一个简单应用
  kubectl create deployment nginx --image=nginx --replicas=3
  kubectl expose deployment nginx --port=80
  
  # 创建测试 Pod
  kubectl run test --image=busybox --rm -it --restart=Never -- sh
  # 在 Pod 内执行: wget -O- http://nginx
  
  # 在 Hubble UI 中观察流量
  ```

## 🏆 里程碑练习：星战前传 (Star Wars Demo)

**任务**: 部署 Cilium 官方演示应用，观察微服务间的流量和网络策略。

### Step 1: 部署应用
```bash
kubectl create -f https://raw.githubusercontent.com/cilium/cilium/HEAD/examples/minikube/http-sw-app.yaml
```

这会创建以下资源：
- `deathstar` (后端服务)
- `tiefighter` (帝国飞船，可以访问 deathstar)
- `xwing` (反抗军飞船，可以访问 deathstar)

### Step 2: 观察流量
```bash
# 在 Hubble UI 中选择 default namespace

# 或使用 CLI 观察
hubble observe --namespace default
```

### Step 3: 模拟请求
```bash
# 从 tiefighter 访问 deathstar
kubectl exec tiefighter -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing

# 从 xwing 访问 deathstar
kubectl exec xwing -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing
```

### Step 4: 应用网络策略
```yaml
# save as deathstar-policy.yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "rule1"
spec:
  description: "L7 policy to restrict access to deathstar"
  endpointSelector:
    matchLabels:
      org: empire
      class: deathstar
  ingress:
  - fromEndpoints:
    - matchLabels:
        org: empire
    toPorts:
    - ports:
      - port: "80"
        protocol: TCP
      rules:
        http:
        - method: "POST"
          path: "/v1/request-landing"
```

```bash
kubectl apply -f deathstar-policy.yaml

# 再次测试，xwing 应该被拦截
kubectl exec xwing -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/exhaust-port
```

### Step 5: 在 Hubble 观察策略效果
- 绿色箭头：允许的流量
- 红色箭头：被策略拦截的流量

**✅ 通关标准**:
1. Hubble UI 清晰显示 `tiefighter` → `deathstar` 的流量（绿色）
2. Hubble UI 显示 `xwing` → `deathstar` 被策略拦截（红色）
3. 理解 L7 网络策略如何工作
4. 能够解释 Cilium 与传统防火墙的区别

## 📚 扩展学习

* [Cilium 官方文档](https://docs.cilium.io/)
* [Hubble 可观测性指南](https://docs.cilium.io/en/stable/gettingstarted/hubble/)
* [eBPF 入门](https://ebpf.io/what-is-ebpf/)

## 🔗 与安全学习路径的关系

完成此进阶内容后，将为以下阶段做好准备：
- **阶段6 - 网络微隔离**: 深入使用 Cilium NetworkPolicy 实现零信任网络
- **阶段7 - 运行时监控**: 结合 Hubble 和 Falco 构建完整的可观测性体系

---
*这是一个可选的进阶模块，建议在完成阶段1-3后再回来学习。*
