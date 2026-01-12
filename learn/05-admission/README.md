# 🚪 阶段五：准入控制与策略即代码

**目标**: 使用Policy as Code在集群入口拦截不合规的配置，实现自动化的安全策略执行。

> **🔄 技能迁移**: 代码Review → 配置Review (Policy as Code)
> 
> SDL中通过Code Review发现问题，准入控制中通过策略自动审查配置。区别是后者自动化、实时、强制执行。

> **💡 核心概念**:
> *   **Admission Controller**: K8s API Server的插件，在对象持久化前拦截请求
> *   **ValidatingAdmissionWebhook**: 验证请求是否符合策略
> *   **MutatingAdmissionWebhook**: 自动修改请求（如注入sidecar）
> *   **Kyverno**: 云原生的策略引擎，无需学习新语言
> *   **OPA/Gatekeeper**: 使用Rego语言的通用策略引擎

---

## 📝 学习任务

### 第一部分：Kubernetes准入控制架构（1.5小时）

* [ ] **理解准入控制链**
  
  ```
  kubectl apply → API Server → Authentication → Authorization 
    → Mutating Admission → Validating Admission → Persistence (etcd)
  ```

* [ ] **查看内置的Admission Controllers**
  
  ```bash
  kubectl -n kube-system describe pod kube-apiserver-* | grep enable-admission-plugins
  
  # 常见内置controllers:
  # - NamespaceLifecycle
  # - LimitRanger
  # - ServiceAccount
  # - ResourceQuota
  # - PodSecurityPolicy (已废弃)
  # - PodSecurity (新)  
  ```

### 第二部分：Kyverno深度实践（3小时）

#### 安装Kyverno

```bash
# 使用Helm安装
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install kyverno kyverno/kyverno -n kyverno --create-namespace

# 验证
kubectl get pods -n kyverno
```

#### 策略模式

**1. Validate - 验证模式**

```yaml
# require-labels.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-labels
spec:
  validationFailureAction: enforce  # enforce=拒绝, audit=仅审计
  rules:
  - name: check-for-labels
    match:
      any:
      - resources:
          kinds:
          - Pod
          - Deployment
    validate:
      message: "Label 'owner' is required"
      pattern:
        metadata:
          labels:
            owner: "?*"
```

**2. Mutate - 修改模式**

```yaml
# add-default-resources.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-default-resources
spec:
  rules:
  - name: add-resources
    match:
      any:
      - resources:
          kinds:
          - Pod
    mutate:
      patchStrategicMerge:
        spec:
          containers:
          - (name): "*"
            resources:
              requests:
                +(memory): "128Mi"
                +(cpu): "100m"
              limits:
                +(memory): "256Mi"
                +(cpu): "200m"
```

**3. Generate - 生成模式**

```yaml
# generate-network-policy.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: generate-network-policy
spec:
  rules:
  - name: default-deny-ingress
    match:
      any:
      - resources:
          kinds:
          - Namespace
    generate:
      kind: NetworkPolicy
      name: default-deny-ingress
      namespace: "{{request.object.metadata.name}}"
      data:
        spec:
          podSelector: {}
          policyTypes:
          - Ingress
```

#### 企业级策略库

```yaml
# enterprise-baseline.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: security-baseline
spec:
  validationFailureAction: enforce
  background: true
  rules:
  # 规则1: 禁止特权容器
  - name: deny-privileged
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Privileged containers are not allowed"
      pattern:
        spec:
          containers:
          - =(securityContext):
              =(privileged): false
  
  # 规则2: 必须设置资源限制
  - name: require-limits
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Resource limits are required"
      pattern:
        spec:
          containers:
          - resources:
              limits:
                memory: "?*"
                cpu: "?*"
  
  # 规则3: 禁止latest标签
  - name: deny-latest-tag
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Using 'latest' tag is not allowed"
      pattern:
        spec:
          containers:
          - image: "!*:latest"
  
  # 规则4: 必须非root运行
  - name: require-non-root
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Running as root is not allowed"
      pattern:
        spec:
          securityContext:
            runAsNonRoot: true
          containers:
          - securityContext:
              runAsNonRoot: true
```

### 第三部分：OPA/Gatekeeper（2小时）

#### 安装Gatekeeper

```bash
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml
```

#### Rego策略示例

```yaml
# constraint-template.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        openAPIV3Schema:
          properties:
            labels:
              type: array
              items: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels
        
        violation[{"msg": msg, "details": {"missing_labels": missing}}] {
          provided := {label | input.review.object.metadata.labels[label]}
          required := {label | label := input.parameters.labels[_]}
          missing := required - provided
          count(missing) > 0
          msg := sprintf("Missing required labels: %v", [missing])
        }
---
# constraint.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: must-have-owner
spec:
  match:
    kinds:
      - apiGroups: ["apps"]
        kinds: ["Deployment"]
  parameters:
    labels: ["owner", "env"]
```

---

## 🏆 里程碑项目：企业策略库

**任务**: 构建覆盖CIS Benchmark 80%要求的Kyverno策略库。

### 策略清单

1. ✅ 禁止特权容器
2. ✅ 禁止hostNetwork/hostPID/hostIPC
3. ✅ 禁止hostPath volumes
4. ✅ 要求runAsNonRoot
5. ✅ 要求readOnlyRootFilesystem
6. ✅ Drop ALL capabilities
7. ✅ 禁止latest标签
8. ✅ 要求资源limits
9. ✅ 要求liveness/readiness probes
10. ✅ 要求metadata labels (owner, env)

### 灰度发布策略

```yaml
# staged-rollout.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: security-baseline
  annotations:
    policies.kyverno.io/category: Security
spec:
  validationFailureAction: audit  # 第1周: audit模式
  background: true
  rules:
  - name: require-owner-label
    match:
      any:
      - resources:
          kinds:
          - Deployment
          namespaces:
          - production  # 第2周: 只在production强制
    validate:
      message: "Label 'owner' is required"
      pattern:
        metadata:
          labels:
            owner: "?*"
```

**部署计划**：
- Week 1: audit模式，收集违规数据
- Week 2: 在dev环境enforce
- Week 3: 在staging环境enforce
- Week 4: 在production环境enforce

---

## 🔗 与SDL的关联

| SDL实践 | 准入控制对应 |
|---------|------------|
| Code Review | 策略自动审查 |
| 安全门禁 | ValidationFailureAction: enforce |
| 静态分析规则 | Kyverno Policies |
| 自动修复 | Mutate模式 |

*在此目录下创建策略库和测试用例。*
