# 🟢 阶段一：Kubernetes 基础操作入门

**目标**: 掌握 Kubernetes 的核心概念和基本操作,为后续的安全学习打下坚实基础。

> **👶 核心概念**:
> *   **Pod**: Kubernetes 中最小的部署单元，可以包含一个或多个容器，是应用运行的"房间"。
> *   **Deployment**: 管理 Pod 的"管家"，负责创建、更新和保持指定数量的 Pod 运行。
> *   **Service**: 为 Pod 提供稳定访问入口的"门牌号"，即使 Pod 重启 IP 变化也能找到它。
> *   **Namespace**: 集群内的"隔离区"，用于划分资源和权限边界。

## 📝 学习任务

### 第一部分：核心概念理解 (30分钟)

* [ ] **理解 Kubernetes 架构**
  * 学习 Master 节点（控制平面）和 Worker 节点的职责
  * 理解 kubectl、API Server、etcd、Scheduler、Controller Manager 的作用
  * **练习**: 运行 `kubectl cluster-info` 和 `kubectl get nodes` 查看集群信息

* [ ] **掌握核心资源对象**
  * Pod、ReplicaSet、Deployment、Service、ConfigMap、Secret
  * **练习**: 用自己的话在笔记中解释每个资源的用途

### 第二部分：kubectl 基础操作 (1小时)

* [ ] **查看资源 (Read)**
  ```bash
  # 查看所有命名空间
  kubectl get namespaces
  
  # 查看 Pod（多种方式）
  kubectl get pods                    # 当前命名空间
  kubectl get pods -A                 # 所有命名空间
  kubectl get pods -o wide            # 显示更多信息（IP、节点等）
  kubectl get pods -o yaml            # YAML 格式
  
  # 查看详细信息
  kubectl describe pod <pod-name>
  
  # 查看日志
  kubectl logs <pod-name>
  kubectl logs <pod-name> -f          # 实时跟踪
  kubectl logs <pod-name> --tail=50   # 最后50行
  ```
  * **练习**: 查看 kube-system 命名空间中的所有 Pod，找出 CoreDNS 的日志

* [ ] **创建资源 (Create)**
  ```bash
  # 方式1: 命令式创建
  kubectl run nginx-test --image=nginx:latest
  
  # 方式2: 从 YAML 文件创建
  kubectl apply -f nginx-deployment.yaml
  
  # 方式3: 快速生成 YAML（不直接创建）
  kubectl run nginx-test --image=nginx --dry-run=client -o yaml > my-pod.yaml
  ```
  * **练习**: 创建一个名为 `hello-app` 的 Deployment，使用 `gcr.io/google-samples/hello-app:1.0` 镜像，副本数为 3

* [ ] **更新资源 (Update)**
  ```bash
  # 修改副本数
  kubectl scale deployment/nginx-deployment --replicas=5
  
  # 更新镜像
  kubectl set image deployment/nginx-deployment nginx=nginx:1.20
  
  # 直接编辑
  kubectl edit deployment/nginx-deployment
  
  # 查看更新状态
  kubectl rollout status deployment/nginx-deployment
  kubectl rollout history deployment/nginx-deployment
  ```
  * **练习**: 将 `hello-app` 的副本数扩展到 5，然后缩减到 2

* [ ] **删除资源 (Delete)**
  ```bash
  # 删除 Pod
  kubectl delete pod <pod-name>
  
  # 删除 Deployment（会删除关联的所有 Pod）
  kubectl delete deployment <deployment-name>
  
  # 从文件删除
  kubectl delete -f nginx-deployment.yaml
  
  # 强制删除（慎用）
  kubectl delete pod <pod-name> --force --grace-period=0
  ```

* [ ] **进入容器调试**
  ```bash
  # 执行命令
  kubectl exec <pod-name> -- ls /
  
  # 进入交互式 Shell
  kubectl exec -it <pod-name> -- /bin/bash
  kubectl exec -it <pod-name> -- /bin/sh
  
  # 多容器 Pod 中指定容器
  kubectl exec -it <pod-name> -c <container-name> -- /bin/bash
  ```
  * **练习**: 进入 nginx Pod，查看 `/etc/nginx/nginx.conf` 文件内容

### 第三部分：Service 网络基础 (45分钟)

* [ ] **理解 Service 类型**
  * **ClusterIP** (默认): 仅集群内部访问
  * **NodePort**: 通过节点 IP:端口暴露服务
  * **LoadBalancer**: 云厂商负载均衡器（本地环境可能不可用）
  
* [ ] **创建 Service**
  ```bash
  # 为 Deployment 创建 Service
  kubectl expose deployment nginx-deployment --port=80 --type=ClusterIP
  
  # 查看 Service
  kubectl get svc
  kubectl describe svc nginx-deployment
  ```
  * **练习**: 为 `hello-app` 创建一个 NodePort 类型的 Service，通过浏览器访问

* [ ] **测试服务连通性**
  ```bash
  # 临时创建一个测试 Pod
  kubectl run test-pod --image=busybox --rm -it --restart=Never -- sh
  
  # 在 Pod 内测试（使用 Service 名称）
  wget -O- http://nginx-deployment
  nslookup nginx-deployment
  ```

### 第四部分：可视化工具入门 (30分钟)

* [ ] **K9s - 终端 UI 管理工具**
  * 安装 K9s（如果还没安装）
  * **基础操作**:
    - `:pod` 查看 Pod
    - `:deploy` 查看 Deployment
    - `:svc` 查看 Service
    - `l` 查看日志
    - `d` 查看详细描述
    - `s` 进入 Shell
    - `ctrl-d` 删除资源
  * **练习**: 使用 K9s 完成上述所有 kubectl 操作

* [ ] **Kubernetes Dashboard (可选)**
  * 部署官方 Dashboard
  * 通过 `kubectl proxy` 访问
  * **练习**: 在 Dashboard 中查看资源使用情况

## 🏆 里程碑练习：部署一个完整的 Web 应用

**任务**: 从零开始部署一个包含前端和后端的简单应用，并能够从集群外部访问。

### Step 1: 创建后端服务
```yaml
# backend.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: gcr.io/google-samples/hello-app:2.0
        ports:
        - containerPort: 8080
        env:
        - name: PORT
          value: "8080"
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
```

### Step 2: 创建前端服务
```yaml
# frontend.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: nginx:alpine
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
  type: NodePort
```

### Step 3: 部署和测试
```bash
# 部署
kubectl apply -f backend.yaml
kubectl apply -f frontend.yaml

# 检查状态
kubectl get deployments
kubectl get pods
kubectl get services

# 测试内部连通性
kubectl run test --image=busybox --rm -it --restart=Never -- wget -O- http://backend-service:8080

# 测试外部访问（通过 NodePort）
curl http://<node-ip>:30080
```

### Step 4: 观察和调试
* 使用 `kubectl describe` 查看资源详情
* 使用 `kubectl logs` 查看应用日志
* 使用 `kubectl exec` 进入容器内部调试
* 使用 K9s 可视化监控所有资源状态

**✅ 通关标准**:
1. 所有 Pod 都处于 Running 状态
2. 前端服务可以通过 NodePort 从集群外访问
3. 前端 Pod 可以成功访问后端 Service
4. 能够使用 kubectl 和 K9s 熟练查看日志、描述资源、进入容器
5. 理解 Pod、Deployment、Service 之间的关系，并能用自己的话解释

## 📚 扩展学习资源

* [Kubernetes 官方文档 - 基础教程](https://kubernetes.io/zh-cn/docs/tutorials/kubernetes-basics/)
* [kubectl 速查表](https://kubernetes.io/zh-cn/docs/reference/kubectl/cheatsheet/)
* [K9s 官方文档](https://k9scli.io/)

## 🤔 学习验证清单

完成本阶段后，应该能够回答：
- [ ] Pod 和容器有什么区别？
- [ ] Deployment 和 Pod 是什么关系？
- [ ] Service 为什么需要，它解决了什么问题？
- [ ] ClusterIP、NodePort、LoadBalancer 的使用场景有什么不同？
- [ ] 如何查看一个 Pod 无法启动的原因？
- [ ] 如何进入运行中的容器进行调试？
- [ ] Namespace 有什么用？

---
*在此目录下创建 `solutions.md` 保存练习代码和截图，创建 `notes.md` 记录学习笔记和问题。*
