# 容器安全速查表

## SecurityContext完整配置模板

```yaml
securityContext:
  # Pod级别
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 3000
  fsGroup: 2000
  seccompProfile:
    type: RuntimeDefault
  
  # Container级别
  containers:
  - securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      capabilities:
        drop:
        - ALL
```

## Capabilities速查

### 危险的Capabilities（绝不添加）
- `CAP_SYS_ADMIN` - 几乎等于root
- `CAP_SYS_PTRACE` - 可以追踪其他进程
- `CAP_SYS_MODULE` - 可以加载内核模块
- `CAP_DAC_READ_SEARCH` - 绕过文件读权限检查

### 常用的Capabilities
- `CAP_NET_BIND_SERVICE` - 绑定<1024端口
- `CAP_CHOWN` - 修改文件所有者
- `CAP_SETUID/SETGID` - 切换用户/组

## Seccomp Profile类型

| Type | 说明 | 使用场景 |
|------|------|---------|
| Unconfined | 无限制 | 不推荐 |
| RuntimeDefault | 运行时默认 | 推荐，阻止危险系统调用 |
| Localhost | 自定义profile | 高级场景 |

## Pod Security Standards

### Restricted（最严格）
```yaml
metadata:
  namespace: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
```

Required:
- runAsNonRoot: true
- allowPrivilegeEscalation: false
- capabilities: drop ALL
- seccompProfile: RuntimeDefault or Localhost

### Baseline（基础）
Disallows:
- privileged: true
- hostNetwork, hostPID, hostIPC
- hostPath volumes

## 常见问题快速排查

### Pod无法启动
```bash
kubectl describe pod <pod-name>
# 查找Events部分的错误信息
```

### 权限不足
```bash
kubectl exec -it <pod> -- id
kubectl exec -it <pod> -- capsh --print
```

### 文件系统只读
```yaml
volumeMounts:
- name: tmp
  mountPath: /tmp
volumes:
- name: tmp
  emptyDir: {}
```

## kubectl快速命令

```bash
# 查看SecurityContext
kubectl get pod <pod> -o jsonpath='{.spec.securityContext}'

# 查看所有特权Pod
kubectl get pods -A -o json | \
  jq '.items[] | select(.spec.containers[].securityContext.privileged==true) | .metadata.name'

# 查看以root运行的Pod
kubectl get pods -A -o json | \
  jq '.items[] | select(.spec.securityContext.runAsUser==0 or .spec.containers[].securityContext.runAsUser==0) | .metadata.name'
```

## 安全检查清单

```markdown
- [ ] runAsNonRoot: true
- [ ] runAsUser: non-zero
- [ ] readOnlyRootFilesystem: true
- [ ] allowPrivilegeEscalation: false
- [ ] privileged: false
- [ ] capabilities: drop ALL
- [ ] seccompProfile: RuntimeDefault
- [ ] resources.limits配置
- [ ] No hostNetwork/hostPID/hostIPC
- [ ] No hostPath volumes
```

## 相关文档链接

- [Kubernetes Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Linux Capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)
- [Seccomp](https://kubernetes.io/docs/tutorials/security/seccomp/)
