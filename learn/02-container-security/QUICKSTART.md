# 🚀 阶段二快速开始指南

本指南提供容器安全与硬化的5天学习计划。

## ✅ 前置检查

- [ ] 已完成阶段1（Kubernetes基础操作）
- [ ] 能够熟练使用kubectl和K9s
- [ ] 有一个可用的Kubernetes集群
- [ ] 了解基本的Linux命令

## 📖 5天学习计划

### Day 1: Linux安全基础（2-3小时）

**学习目标**：理解容器隔离原理

- [ ] 理解Namespace和Cgroups的作用
- [ ] 实验：查看容器的namespace
- [ ] 实验：观察cgroup资源限制
- [ ] 学习Linux Capabilities概念
- [ ] 实验：查看容器的默认capabilities

**关键命令**：
```bash
ls -la /proc/$$/ns/
capsh --print
ps aux | grep <container-name>
```

**完成标志**：
- 能解释Namespace和Cgroups的区别
- 能列出Docker默认给容器的capabilities
- 理解容器不是虚拟机，而是受限的进程

---

### Day 2: Capabilities深度实践（2-3小时）

**学习目标**：掌握最小权限原则

- [ ] 实验：Drop ALL capabilities并观察影响
- [ ] 实验：只添加必要的capabilities
- [ ] 练习：为不同类型应用设计capabilities方案
- [ ] 理解常见capabilities的作用

**关键实验**：
```yaml
# 尝试部署drop all的Pod
securityContext:
  capabilities:
    drop:
    - ALL
```

**完成标志**：
- 能够为Nginx设计最小capabilities集
- 理解哪些capabilities是危险的
- 能解释CAP_SYS_ADMIN的风险

---

### Day 3: Seccomp和AppArmor（3小时）

**学习目标**：系统调用和文件访问控制

- [ ] 理解Seccomp的工作原理
- [ ] 使用RuntimeDefault seccomp profile
- [ ] 实验：追踪系统调用（使用strace）
- [ ] 了解AppArmor/SELinux（如果节点支持）

**关键实验**：
```bash
# 追踪系统调用
strace ls /

# 应用RuntimeDefault
securityContext:
  seccompProfile:
    type: RuntimeDefault
```

**完成标志**：
- 能列出常见的系统调用类型
- 理解RuntimeDefault profile的作用
- 知道如何debug seccomp拦截问题

---

### Day 4: SecurityContext完整配置（2-3小时）

**学习目标**：综合应用安全配置

- [ ] 学习RunAsNonRoot的重要性
- [ ] 配置ReadOnlyRootFilesystem
- [ ] 理解Pod Security Standards
- [ ] 创建企业级安全基线模板

**关键配置**：
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
```

**完成标志**：
- 能编写符合Restricted标准的Pod
- 理解root用户在容器中的风险
- 知道如何处理只读文件系统的应用需求

---

### Day 5: 里程碑项目 - 铁桶阵（3-4小时）

**学习目标**：部署极致硬化的Nginx

- [ ] 构建非root Nginx镜像
- [ ] 配置所有安全选项
- [ ] 验证服务正常运行
- [ ] 进行安全验证测试

**任务清单**：
1. 编写Dockerfile（使用非root用户）
2. 配置SecurityContext（drop all + readonly）
3. 部署并测试访问
4. 尝试渗透测试（验证防护有效）

**完成标志**：
- ✅ Nginx正常响应HTTP请求
- ✅ 无法在容器内创建文件
- ✅ 无法安装软件
- ✅ 无法修改配置文件
- ✅ 运行用户为非root

---

## 🆘 常见问题

### Q1: Pod启动失败，提示权限不足？

**可能原因**：
1. RunAsNonRoot但镜像以root启动
2. 需要的capabilities被drop了
3. ReadOnlyRootFilesystem但应用需要写入

**排查方法**：
```bash
# 查看详细错误
kubectl describe pod <pod-name>

# 查看容器日志
kubectl logs <pod-name>

# 临时去掉安全限制测试
# 逐个添加限制，定位问题
```

### Q2: Nginx提示"bind() to 0.0.0.0:80 failed"？

**原因**：非root用户无法绑定<1024的端口

**解决方法**：
1. 改用8080等非特权端口
2. 或添加NET_BIND_SERVICE capability

```yaml
capabilities:
  drop:
  - ALL
  add:
  - NET_BIND_SERVICE
```

### Q3: ReadOnlyRootFilesystem导致应用无法写临时文件？

**解决方法**：为需要写入的目录挂载emptyDir

```yaml
volumeMounts:
- name: tmp
  mountPath: /tmp
- name: cache
  mountPath: /app/cache

volumes:
- name: tmp
  emptyDir: {}
- name: cache
  emptyDir: {}
```

### Q4: 如何debug Seccomp拦截？

```bash
# 1. 查看审计日志（如果有）
sudo ausearch -m seccomp

# 2. 临时使用audit模式（记录但不拦截）
# 创建audit profile并查看日志

# 3. 使用strace追踪系统调用
kubectl debug -it <pod-name> --image=alpine
apk add strace
strace -f <command>
```

---

## 💡 学习技巧

### 1. 渐进式加固

不要一次配置所有安全选项，而是：
```
1. 先让应用正常运行
2. 添加RunAsNonRoot，修复问题
3. 添加ReadOnlyRootFilesystem，挂载必要目录
4. Drop ALL capabilities，按需添加
5. 添加Seccomp profile
```

### 2. 使用K9s快速查看

```bash
k9s
# 按 ':pod' 进入Pod视图
# 选中Pod，按 'd' 查看描述
# 查找SecurityContext配置
```

### 3. 对比不同配置的差异

创建两个Pod，一个有安全限制，一个没有：
```bash
kubectl exec -it secure-pod -- sh
kubectl exec -it insecure-pod -- sh

# 对比：
id
capsh --print
touch /etc/test
```

### 4. 阅读源码理解原理

- Docker seccomp default profile: `moby/moby/profiles/seccomp/default.json`
- runc capabilities配置: `opencontainers/runc/libcontainer/specconv`

---

## 📝 学习成果输出

完成本阶段后，建议整理：

### 1. 企业安全基线模板
创建不同场景的SecurityContext模板：
- `web-application.yaml` - Web应用基线
- `database.yaml` - 数据库基线
- `batch-job.yaml` - 批处理任务基线

### 2. Capabilities决策表
| 应用类型 | 需要的Capabilities | 原因 |
|---------|------------------|------|
| Nginx/HTTP Server | NET_BIND_SERVICE（使用80端口时） | 绑定特权端口 |
| Database | CHOWN, SETUID, SETGID | 管理文件权限 |
| 普通应用 | 无（drop all） | 最小权限 |

### 3. 问题排查手册
记录遇到的问题和解决方案

### 4. 安全检查清单
```markdown
- [ ] runAsNonRoot: true
- [ ] readOnlyRootFilesystem: true
- [ ] allowPrivilegeEscalation: false
- [ ] privileged: false
- [ ] capabilities: drop ALL
- [ ] seccompProfile: RuntimeDefault
- [ ] resources limits配置
```

---

## ⏭️ 下一步

完成本阶段后，可以：

1. **进入阶段3 - 镜像安全**
   - 学习Trivy扫描漏洞
   - SBOM软件物料清单
   - 镜像签名与验证

2. **深化容器运行时知识**
   - 学习gVisor/Kata Containers沙箱
   - 研究容器逃逸技术（阶段9）
   - 学习RuntimeClass

3. **准备CKS认证**
   - 本阶段内容是CKS考试重点
   - 练习在时间压力下快速配置SecurityContext

---

💪 **记住**：容器安全的核心是**最小权限原则**。默认拒绝一切，只给必需的权限！

如果遇到问题：
- 查看 `README.md` 的详细说明
- 在 `notes.md` 中记录问题
- 参考 `examples/` 目录的示例配置

祝学习顺利！🎉
