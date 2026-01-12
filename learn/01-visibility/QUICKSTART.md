# 🚀 快速开始指南

本指南提供 Kubernetes 基础操作的快速入门路径。

## ✅ 前置检查

在开始之前，请确保：
- [ ] 已准备一个可用的 Kubernetes 集群（本地 minikube/kind 或远程集群）
- [ ] 已安装 `kubectl` 命令行工具
- [ ] 已安装 `k9s` (可选但强烈推荐)

### 验证环境
```bash
# 检查 kubectl 是否安装
kubectl version --client

# 检查集群连接
kubectl cluster-info

# 查看节点
kubectl get nodes

# 检查 k9s 是否安装
k9s version
```

如果环境有问题，请先参考项目根目录的 `build-k8s/` 文件夹搭建集群。

## 📖 建议学习路径

### 第1天：理解核心概念 (2-3小时)
1. 阅读 `README.md` 中的"核心概念理解"部分
2. 在 `notes.md` 中用自己的话解释 Pod、Deployment、Service、Namespace
3. 运行基本的查看命令，熟悉集群状态

### 第2天：kubectl 基础操作 (2-3小时)
1. 跟随 `README.md` 第二部分，逐个练习 kubectl 命令
2. 重点练习：
   - `kubectl get` (查看资源)
   - `kubectl describe` (查看详情)
   - `kubectl logs` (查看日志)
   - `kubectl exec` (进入容器)
3. 记录每个命令的输出到 `notes.md`

### 第3天：Service 和网络 (1-2小时)
1. 理解 ClusterIP、NodePort、LoadBalancer 的区别
2. 练习创建不同类型的 Service
3. 测试 Pod 间的网络连通性

### 第4天：K9s 可视化 (1小时)
1. 学习 K9s 的基本快捷键
2. 用 K9s 重复第2-3天的所有操作
3. 体会可视化工具的便利性

### 第5天：里程碑练习 (2-3小时)
1. 部署完整的前后端应用
2. 测试内外部访问
3. 调试问题并记录
4. 完成自查清单

## 🎯 每日学习检查点

### Day 1 完成标志
- [ ] 能解释 Pod 是什么
- [ ] 能解释 Deployment 的作用
- [ ] 能解释为什么需要 Service
- [ ] 成功运行 `kubectl get pods -A`

### Day 2 完成标志
- [ ] 能创建一个 Pod
- [ ] 能查看 Pod 的日志
- [ ] 能进入 Pod 的 Shell
- [ ] 能删除一个 Pod

### Day 3 完成标志
- [ ] 能创建一个 Service
- [ ] 理解 ClusterIP 和 NodePort 的区别
- [ ] 能从一个 Pod 访问 Service

### Day 4 完成标志
- [ ] 能熟练使用 K9s 查看资源
- [ ] 能用 K9s 查看日志
- [ ] 能用 K9s 进入容器

### Day 5 完成标志
- [ ] 成功部署 backend 和 frontend
- [ ] 能从外部访问前端服务
- [ ] 能从前端访问后端
- [ ] 完成所有自查清单问题

## 🆘 常见问题

### Q1: Pod 一直处于 Pending 状态？
```bash
# 查看详细原因
kubectl describe pod <pod-name>

# 常见原因：
# - 资源不足（CPU/内存）
# - 镜像拉取失败
# - 节点没有准备好
```

### Q2: 镜像拉取失败 (ImagePullBackOff)?
```bash
# 检查镜像名称是否正确
kubectl describe pod <pod-name> | grep Image

# 如果是国内网络问题，可以：
# 1. 使用国内镜像源
# 2. 提前在节点上拉取镜像
# 3. 配置镜像加速器
```

### Q3: Service 无法访问？
```bash
# 1. 检查 Service 是否创建成功
kubectl get svc

# 2. 检查 Endpoints 是否有 Pod
kubectl get endpoints <service-name>

# 3. 检查 selector 是否匹配
kubectl get svc <service-name> -o yaml | grep selector
kubectl get pods --show-labels

# 4. 使用 Pod 测试连通性
kubectl run test --image=busybox --rm -it -- wget -O- http://<service-name>
```

### Q4: 如何查看 Pod 启动失败的原因？
```bash
# 方法1: describe 查看事件
kubectl describe pod <pod-name>

# 方法2: 查看日志（如果容器启动过）
kubectl logs <pod-name>

# 方法3: 查看上一次容器的日志
kubectl logs <pod-name> --previous

# 方法4: 使用 K9s
# 进入 K9s，找到 Pod，按 'd' 查看描述，按 'l' 查看日志
```

## 💡 学习技巧

1. **多动手，少看教程**：Kubernetes 最好的学习方式就是实践
2. **记录和总结**：把每个命令的作用记录在 `notes.md` 中
3. **对比理解**：对比 kubectl 和 K9s 的操作，理解它们背后做了什么
4. **看官方文档**：遇到问题先看 `kubectl describe` 的输出，再查官方文档
5. **循序渐进**：不要着急，先把基础打牢，再学高级特性

## 📝 学习成果输出

完成本阶段后，建议在 `notes.md` 中整理：
1. **核心概念总结**：用自己的话解释 Pod、Deployment、Service 等
2. **常用命令清单**：整理常用的 kubectl 命令
3. **问题和解决方案**：记录遇到的问题和解决过程
4. **架构图**：尝试画出部署的应用架构（前端、后端、Service 的关系）

## ⏭️ 下一步

完成本阶段后，可以：
1. **继续安全学习路径**：进入阶段2 - 容器安全与硬化
2. **深化网络知识**：学习 `advanced-networking.md` 中的 Cilium 和 Hubble
3. **准备 CKAD 认证**：如果对 Kubernetes 感兴趣，可以考虑考取认证

---

💪 **记住**：学习 Kubernetes 就像学习一门新语言，开始可能会觉得困难，但坚持练习，很快就会熟练！

如果遇到问题，可以：
- 查看官方文档：https://kubernetes.io/zh-cn/docs/home/
- 在 `notes.md` 中记录问题
- 在社区寻求帮助

祝学习顺利！🎉
