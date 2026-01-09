# Kubernetes 集群基本操作说明

## 快速开始

### 访问集群

1. **SSH 登录到 Master 节点**
   ```bash
   ssh username@192.168.0.200
   # 密码: 
   ```

2. **验证集群状态**
   ```bash
   kubectl get nodes
   kubectl get pods -A
   ```

---

## 一、应用部署

### 1.1 部署应用

#### 方式一：使用 kubectl create（简单快速）

```bash
# 部署一个 nginx 应用
kubectl create deployment nginx --image=nginx --replicas=3

# 部署其他应用示例
kubectl create deployment redis --image=redis --replicas=1
kubectl create deployment mysql --image=mysql --replicas=1 --env="MYSQL_ROOT_PASSWORD=password123"
```

#### 方式二：使用 YAML 文件（推荐生产环境）

创建文件 `app-deployment.yaml`：
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  labels:
    app: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: nginx:latest
        ports:
        - containerPort: 80
```

应用配置：
```bash
kubectl apply -f app-deployment.yaml
```

### 1.2 暴露服务

#### ClusterIP（集群内部访问）
```bash
kubectl expose deployment nginx --port=80 --target-port=80 --type=ClusterIP
```

#### NodePort（外部通过节点端口访问）
```bash
kubectl expose deployment nginx --port=80 --target-port=80 --type=NodePort

# 查看分配的端口
kubectl get svc nginx
# 访问: http://192.168.0.200:<NodePort>
```

#### 使用 YAML 创建服务

创建文件 `app-service.yaml`：
```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp
  type: NodePort
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30080
```

应用：
```bash
kubectl apply -f app-service.yaml
```

---

## 二、查看和监控

### 2.1 查看资源

```bash
# 查看所有节点
kubectl get nodes
kubectl get nodes -o wide  # 显示更多信息

# 查看所有 Pods
kubectl get pods
kubectl get pods -A  # 所有命名空间
kubectl get pods -o wide  # 显示节点信息

# 查看 Deployments
kubectl get deployments
kubectl get deploy  # 简写

# 查看 Services
kubectl get services
kubectl get svc  # 简写

# 查看所有资源
kubectl get all
kubectl get all -n kube-system  # 指定命名空间
```

### 2.2 查看详细信息

```bash
# 查看 Pod 详细信息
kubectl describe pod <pod-name>

# 查看 Deployment 详细信息
kubectl describe deployment <deployment-name>

# 查看 Service 详细信息
kubectl describe service <service-name>

# 查看节点详细信息
kubectl describe node master
```

### 2.3 查看日志

```bash
# 查看 Pod 日志
kubectl logs <pod-name>

# 实时查看日志
kubectl logs -f <pod-name>

# 查看之前的日志（容器重启后）
kubectl logs <pod-name> --previous

# 查看多容器 Pod 中特定容器的日志
kubectl logs <pod-name> -c <container-name>
```

### 2.4 监控资源使用（需要安装 metrics-server）

```bash
# 查看节点资源使用
kubectl top nodes

# 查看 Pod 资源使用
kubectl top pods
kubectl top pods -A  # 所有命名空间
```

---

## 三、应用管理

### 3.1 扩缩容

```bash
# 扩展副本数
kubectl scale deployment nginx --replicas=5

# 缩减副本数
kubectl scale deployment nginx --replicas=2

# 自动扩缩容（基于 CPU 使用率）
kubectl autoscale deployment nginx --min=2 --max=10 --cpu-percent=80
```

### 3.2 更新应用

```bash
# 更新镜像
kubectl set image deployment/nginx nginx=nginx:1.29.5

# 查看更新状态
kubectl rollout status deployment/nginx

# 查看更新历史
kubectl rollout history deployment/nginx

# 回滚到上一个版本
kubectl rollout undo deployment/nginx

# 回滚到指定版本
kubectl rollout undo deployment/nginx --to-revision=2
```

### 3.3 删除资源

```bash
# 删除 Pod（会自动重建）
kubectl delete pod <pod-name>

# 删除 Deployment（会删除所有相关 Pod）
kubectl delete deployment nginx

# 删除 Service
kubectl delete service nginx

# 使用 YAML 文件删除
kubectl delete -f app-deployment.yaml

# 删除所有资源
kubectl delete deployment,service nginx
```

---

## 四、交互操作

### 4.1 进入容器

```bash
# 进入 Pod 执行命令
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec -it <pod-name> -- /bin/sh  # 如果没有 bash

# 在 Pod 中执行单个命令
kubectl exec <pod-name> -- ls -la
kubectl exec <pod-name> -- cat /etc/nginx/nginx.conf

# 多容器 Pod 指定容器
kubectl exec -it <pod-name> -c <container-name> -- /bin/bash
```

### 4.2 文件传输

```bash
# 从 Pod 复制文件到本地
kubectl cp <pod-name>:/path/to/file ./local-file

# 从本地复制文件到 Pod
kubectl cp ./local-file <pod-name>:/path/to/file

# 指定命名空间
kubectl cp <namespace>/<pod-name>:/path/to/file ./local-file
```

### 4.3 端口转发

```bash
# 将 Pod 端口转发到本地
kubectl port-forward <pod-name> 8080:80
# 访问: http://localhost:8080

# 转发 Service
kubectl port-forward service/nginx 8080:80

# 监听所有网络接口
kubectl port-forward --address 0.0.0.0 <pod-name> 8080:80
```

---

## 五、命名空间管理

### 5.1 命名空间操作

```bash
# 查看所有命名空间
kubectl get namespaces
kubectl get ns  # 简写

# 创建命名空间
kubectl create namespace dev
kubectl create namespace test
kubectl create namespace prod

# 查看指定命名空间的资源
kubectl get pods -n dev
kubectl get all -n dev

# 删除命名空间（会删除其中所有资源）
kubectl delete namespace dev
```

### 5.2 在命名空间中部署

```bash
# 在指定命名空间创建资源
kubectl create deployment nginx --image=nginx -n dev

# 使用 YAML 指定命名空间
kubectl apply -f app.yaml -n dev

# 设置默认命名空间
kubectl config set-context --current --namespace=dev

# 查看当前默认命名空间
kubectl config view --minify | grep namespace:
```

---

## 六、配置管理

### 6.1 ConfigMap（配置文件）

```bash
# 从文件创建 ConfigMap
kubectl create configmap app-config --from-file=config.txt

# 从键值对创建
kubectl create configmap app-config \
  --from-literal=database.host=mysql \
  --from-literal=database.port=3306

# 查看 ConfigMap
kubectl get configmap
kubectl describe configmap app-config

# 使用 YAML 创建
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database.host: "mysql"
  database.port: "3306"
  app.mode: "production"
EOF
```

### 6.2 Secret（敏感信息）

```bash
# 从文件创建 Secret
kubectl create secret generic db-secret --from-file=password.txt

# 从键值对创建
kubectl create secret generic db-secret \
  --from-literal=username=admin \
  --from-literal=password=secret123

# 查看 Secret
kubectl get secrets
kubectl describe secret db-secret

# 查看 Secret 内容（base64 编码）
kubectl get secret db-secret -o jsonpath='{.data.password}' | base64 --decode
```

---

## 七、故障排查

### 7.1 常见问题诊断

```bash
# 查看 Pod 事件
kubectl describe pod <pod-name>
# 重点查看 Events 部分

# 查看 Pod 状态
kubectl get pods -o wide
# 可能的状态: Running, Pending, CrashLoopBackOff, Error, ImagePullBackOff

# 查看集群事件
kubectl get events --sort-by='.lastTimestamp'
kubectl get events -n kube-system --sort-by='.lastTimestamp'

# 查看节点状态
kubectl describe node <node-name>
```

### 7.2 常见问题解决

**Pod 处于 Pending 状态：**
```bash
# 检查资源是否充足
kubectl describe pod <pod-name>
# 查看: Insufficient cpu, Insufficient memory

# 检查节点状态
kubectl get nodes
```

**Pod 处于 ImagePullBackOff：**
```bash
# 检查镜像名称是否正确
kubectl describe pod <pod-name>
# 查看: Failed to pull image

# 测试从节点拉取镜像
ssh worker-1
sudo crictl pull nginx:latest
```

**Pod 处于 CrashLoopBackOff：**
```bash
# 查看日志
kubectl logs <pod-name>
kubectl logs <pod-name> --previous

# 检查应用配置
kubectl describe pod <pod-name>
```

### 7.3 调试工具

```bash
# 创建临时调试 Pod
kubectl run debug-pod --image=busybox --restart=Never -it -- /bin/sh

# 测试网络连通性
kubectl run test-pod --image=busybox --restart=Never -it -- /bin/sh
# 在 Pod 内执行:
# ping <pod-ip>
# nslookup kubernetes.default
# wget -O- http://<service-name>

# 删除调试 Pod
kubectl delete pod debug-pod test-pod
```

---

## 八、常用操作示例

### 8.1 部署完整应用（Web + 数据库）

```bash
# 1. 部署 MySQL
kubectl create deployment mysql --image=mysql:5.7 \
  --env="MYSQL_ROOT_PASSWORD=password123" \
  --env="MYSQL_DATABASE=myapp"

# 2. 创建 MySQL Service
kubectl expose deployment mysql --port=3306 --type=ClusterIP

# 3. 部署 Web 应用
kubectl create deployment webapp --image=nginx --replicas=3

# 4. 暴露 Web 应用
kubectl expose deployment webapp --port=80 --type=NodePort

# 5. 查看服务
kubectl get svc
```

### 8.2 查看完整应用状态

```bash
# 一键查看所有相关资源
kubectl get deployment,pod,service,configmap,secret

# 查看特定应用的所有资源
kubectl get all -l app=webapp
```

### 8.3 清理资源

```bash
# 删除特定应用的所有资源
kubectl delete deployment webapp
kubectl delete service webapp

# 或使用标签删除
kubectl delete all -l app=webapp

# 清理整个命名空间
kubectl delete namespace dev
```

---

## 九、快速参考

### 9.1 常用命令速查

| 操作 | 命令 |
|------|------|
| 查看资源 | `kubectl get <resource>` |
| 创建资源 | `kubectl create <resource>` |
| 应用配置 | `kubectl apply -f <file>` |
| 删除资源 | `kubectl delete <resource> <name>` |
| 查看详情 | `kubectl describe <resource> <name>` |
| 查看日志 | `kubectl logs <pod-name>` |
| 进入容器 | `kubectl exec -it <pod-name> -- /bin/bash` |
| 扩缩容 | `kubectl scale deployment <name> --replicas=N` |

### 9.2 资源简写

| 资源 | 简写 |
|------|------|
| pods | po |
| services | svc |
| deployments | deploy |
| replicasets | rs |
| namespaces | ns |
| nodes | no |
| configmaps | cm |
| persistentvolumes | pv |
| persistentvolumeclaims | pvc |

### 9.3 输出格式

```bash
# 宽格式显示更多信息
kubectl get pods -o wide

# JSON 格式
kubectl get pod <pod-name> -o json

# YAML 格式
kubectl get pod <pod-name> -o yaml

# 自定义列
kubectl get pods -o custom-columns=NAME:.metadata.name,IP:.status.podIP,NODE:.spec.nodeName

# JSONPath 查询
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
```

---

## 十、集群访问信息

### 10.1 节点信息

| 节点 | IP 地址 | 用户 | 密码 |
|------|---------|------|------|
| master | 192.168.0.200 | username |  |
| worker-1 | 192.168.0.201 | username |  |
| worker-2 | 192.168.0.202 | username |  |

### 10.2 访问方式

**SSH 访问：**
```bash
ssh username@192.168.0.200  # Master
ssh username@192.168.0.201  # Worker-1
ssh username@192.168.0.202  # Worker-2
```

**kubectl 配置：**
- 配置文件：`~/.kube/config`
- API Server：`https://192.168.0.200:6443`

### 10.3 重要提示

1. **所有 kubectl 命令只能在 master 节点上执行**（worker 节点没有配置 kubectl）
2. **NodePort 服务可以通过任意节点 IP + NodePort 访问**
3. **默认命名空间是 default**，系统组件在 kube-system
4. **Pod 网络范围**：10.244.0.0/16
5. **Service 网络范围**：10.96.0.0/12

---

## 十一、实用技巧

### 11.1 命令别名

在 `~/.bashrc` 中添加：
```bash
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployments'
alias kdesc='kubectl describe'
alias klogs='kubectl logs'
alias kexec='kubectl exec -it'
```

生效：
```bash
source ~/.bashrc
```

### 11.2 bash 命令补全

```bash
# 启用 kubectl 自动补全
source <(kubectl completion bash)

# 永久启用（已配置）
echo "source <(kubectl completion bash)" >> ~/.bashrc
```

### 11.3 快速清理测试资源

```bash
# 删除所有处于 Evicted 状态的 Pods
kubectl get pods -A | grep Evicted | awk '{print $1, $2}' | xargs -n2 kubectl delete pod -n

# 删除所有完成的 Jobs
kubectl delete jobs --field-selector status.successful=1

# 强制删除卡住的 Pod
kubectl delete pod <pod-name> --grace-period=0 --force
```

---

---

## 十二、Cilium & Hubble 操作指南

### 12.1 状态检查

```bash
# 查看 Cilium Agent 状态
kubectl get pods -n kube-system -l k8s-app=cilium

# 查看 Hubble Relay 状态
kubectl get pods -n kube-system -l k8s-app=hubble-relay

# (高级) 进入 Cilium Pod 查看详细状态
kubectl -n kube-system exec -it <cilium-pod-name> -- cilium status
```

### 12.2 访问 Hubble UI

Hubble UI 提供可视化的服务依赖图和流量监控。

```bash
# 1. 启动端口转发 (在 Master 执行)
kubectl port-forward -n kube-system svc/hubble-ui --address 0.0.0.0 8888:80

# 2. 浏览器访问
http://192.168.0.200:8888
```

### 12.3 NetworkPolicy 示例

Cilium 完全支持 Kubernetes NetworkPolicy。以下示例限制 Pod 只能被特定来源访问。

**deny-all.yaml (默认拒绝所有流量):**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

**allow-web.yaml (允许访问 Web 服务):**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-access
spec:
  podSelector:
    matchLabels:
      app: webapp
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: client
    ports:
    - protocol: TCP
      port: 80
```

---

### 11.4 终端管理工具 (k9s)

已在 Master 节点预装 k9s (v0.32.7)。

**启动:**
```bash
k9s
```

**常用快捷键:**
- `:ns` - 切换命名空间 (如 `:ns default`)
- `:pod` - 查看 Pod 列表
- `:svc` - 查看 Service 列表
- `/` - 过滤/搜索列表
- `l` - 查看选中 Pod 的日志 (Logs)
- `s` - 进入选中 Pod 的 Shell
- `d` - 查看选中资源的 Describe 信息
- `ctrl-c` - 退出 k9s

---

## 帮助和文档

```bash
# 获取命令帮助
kubectl --help
kubectl get --help
kubectl create --help

# 查看资源定义
kubectl explain pod
kubectl explain deployment
kubectl explain service

# 查看资源的详细字段
kubectl explain pod.spec
kubectl explain deployment.spec.template
```

---

**祝你使用愉快！** 🚀

如有问题请参考完整文档：`k8s-setup-guide.md`
