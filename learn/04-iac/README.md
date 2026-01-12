# 🏗️ 阶段四：基础设施即代码（IaC）安全

**目标**: 在基础设施配置到达集群之前，通过静态分析和策略检查拦截安全风险。

> **🔄 技能迁移**: 代码审计 → IaC静态分析
> 
> SDL中的SAST工具扫描应用代码漏洞，IaC安全中的Checkov/KICS等工具扫描基础设施配置问题。两者思路相同：在部署前发现问题，成本更低。

> **💡 核心概念**:
> *   **IaC扫描**: 静态分析Terraform/CloudFormation/K8s YAML，检测安全配置错误
> *   **GitOps**: 以Git为单一信源，通过声明式配置管理基础设施
> *   **Policy as Code**: 将安全策略写成代码，自动化执行
> *   **Secrets Management**: 密钥不存储在代码中，使用专门的密钥管理系统
> *   **CI/CD安全**: 在流水线中集成安全检查，实现DevSecOps

---

## 📝 学习任务

### 第一部分：IaC扫描器深度使用（3小时）

#### Checkov - 跨平台IaC扫描器

Checkov支持Terraform、CloudFormation、Kubernetes、Dockerfile等多种IaC格式。

* [ ] **安装Checkov**
  
  ```bash
  # 使用pip安装
  pip3 install checkov
  
  # 或使用brew（macOS）
  brew install checkov
  
  # 验证
  checkov --version
  ```

* [ ] **扫描Kubernetes YAML**
  
  ```bash
  # 扫描单个文件
  checkov -f deployment.yaml
  
  # 扫描目录
  checkov -d ./kubernetes/
  
  # 只显示失败的检查
  checkov -d ./kubernetes/ --compact
  
  # 输出JSON格式
  checkov -d ./kubernetes/ -o json > results.json
  
  # 指定检查类型
  checkov -d ./kubernetes/ --framework kubernetes
  ```

* [ ] **理解检查规则**
  
  Checkov内置800+检查规则，例如：
  - `CKV_K8S_8`: 确保CPU requests已设置
  - `CKV_K8S_9`: 确保CPU limits已设置
  - `CKV_K8S_14`: 确保readOnlyRootFilesystem设置为true
  - `CKV_K8S_17`: 禁止特权容器
  - `CKV_K8S_22`: 确保runAsNonRoot设置为true
  
  **实验**：创建不安全的deployment
  ```yaml
  # insecure-deployment.yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: insecure-app
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: insecure
    template:
      metadata:
        labels:
          app: insecure
      spec:
        containers:
        - name: app
          image: nginx:latest  # ❌ 使用latest标签
          securityContext:
            privileged: true   # ❌ 特权容器
            runAsUser: 0       # ❌ root用户
          # ❌ 没有资源限制
  ```
  
  ```bash
  checkov -f insecure-deployment.yaml
  # 应该检测出多个问题
  ```

* [ ] **自定义检查规则**
  
  ```bash
  # 创建自定义检查（Python）
  mkdir custom_checks
  cat > custom_checks/RequireOwnerLabel.py <<'EOF'
  from checkov.kubernetes.checks.resource.base_resource_check import BaseResourceCheck
  
  class RequireOwnerLabel(BaseResourceCheck):
      def __init__(self):
          name = "Ensure Pod has owner label"
          id = "CKV_K8S_CUSTOM_1"
          supported_resources = ['Pod', 'Deployment', 'StatefulSet']
          categories = ['General']
          super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)
  
      def scan_resource_conf(self, conf):
          metadata = conf.get('metadata', {})
          labels = metadata.get('labels', {})
          return 'owner' in labels
  
  check = RequireOwnerLabel()
  EOF
  
  # 使用自定义检查
  checkov -d ./kubernetes/ --external-checks-dir ./custom_checks/
  ```

#### KICS - 开源IaC扫描器

* [ ] **安装KICS**
  
  ```bash
  # 使用Docker
  docker pull checkmarx/kics:latest
  
  # 使用brew（macOS）
  brew install kics
  
  # 验证
  kics version
  ```

* [ ] **扫描对比**
  
  ```bash
  # KICS扫描
  kics scan -p ./kubernetes/
  
  # 对比Checkov和KICS的结果差异
  checkov -d ./kubernetes/ > checkov-results.txt
  kics scan -p ./kubernetes/ -o kics-results.json
  ```

#### 误报处理

* [ ] **抑制特定检查**
  
  ```yaml
  # 使用注释抑制检查
  apiVersion: v1
  kind: Pod
  metadata:
    name: special-pod
    annotations:
      checkov.io/skip1: CKV_K8S_8=需要弹性资源调度
      checkov.io/skip2: CKV_K8S_14=应用需要写入临时文件
  spec:
    containers:
    - name: app
      image: myapp:1.0
  ```
  
  ```bash
  # 使用配置文件抑制
  cat > .checkov.yaml <<EOF
  skip-check:
    - CKV_K8S_8  # CPU requests检查
    - CKV_K8S_9  # CPU limits检查
  EOF
  ```

---

### 第二部分：GitOps安全（3小时）

#### ArgoCD深度实践

* [ ] **部署ArgoCD**
  
  ```bash
  # 创建namespace
  kubectl create namespace argocd
  
  # 安装ArgoCD
  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  
  # 等待就绪
  kubectl wait --for=condition=available --timeout=600s -n argocd deployment/argocd-server
  
  # 获取初始密码
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
  
  # 端口转发访问UI
  kubectl port-forward svc/argocd-server -n argocd 8080:443
  # 访问 https://localhost:8080
  ```

* [ ] **配置RBAC**
  
  ```yaml
  # argocd-rbac-cm.yaml
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: argocd-rbac-cm
    namespace: argocd
  data:
    policy.default: role:readonly
    policy.csv: |
      # 开发者只能读取应用
      p, role:developer, applications, get, */*, allow
      p, role:developer, applications, list, */*, allow
      g, dev-team, role:developer
      
      # SRE可以同步应用
      p, role:sre, applications, sync, */*, allow
      p, role:sre, applications, get, */*, allow
      g, sre-team, role:sre
      
      # 只有admin可以创建/删除
      p, role:admin, applications, *, */*, allow
      g, admin-team, role:admin
  ```

* [ ] **Git仓库安全配置**
  
  ```yaml
  # argocd-application.yaml
  apiVersion: argoproj.io/v1alpha1
  kind: Application
  metadata:
    name: myapp
    namespace: argocd
  spec:
    project: production
    source:
      repoURL: https://github.com/org/repo.git
      targetRevision: main
      path: k8s/production
    destination:
      server: https://kubernetes.default.svc
      namespace: production
    syncPolicy:
      automated:
        prune: true
        selfHeal: true
      syncOptions:
      - CreateNamespace=false  # 不自动创建namespace
      - PruneLast=true         # 最后执行删除
    # 安全验证
    ignoreDifferences:
    - group: "*"
      kind: Secret
      jsonPointers:
      - /data
  ```

* [ ] **Branch Protection Rules**
  
  在GitHub/GitLab中配置：
  - Require pull request reviews (至少2人)
  - Require status checks (CI必须通过)
  - Require signed commits
  - Include administrators (管理员也要遵守)

---

### 第三部分：密钥管理（2小时）

#### External Secrets Operator

* [ ] **安装ESO**
  
  ```bash
  # 添加Helm repo
  helm repo add external-secrets https://charts.external-secrets.io
  helm repo update
  
  # 安装
  helm install external-secrets \
    external-secrets/external-secrets \
    -n external-secrets-system \
    --create-namespace
  ```

* [ ] **配置AWS Secrets Manager后端（使用LocalStack模拟）**
  
  ```yaml
  # secret-store.yaml
  apiVersion: external-secrets.io/v1beta1
  kind: SecretStore
  metadata:
    name: aws-secret-store
    namespace: production
  spec:
    provider:
      aws:
        service: SecretsManager
        region: us-east-1
        auth:
          jwt:
            serviceAccountRef:
              name: external-secrets-sa
  ```

* [ ] **创建ExternalSecret**
  
  ```yaml
  # external-secret.yaml
  apiVersion: external-secrets.io/v1beta1
  kind: ExternalSecret
  metadata:
    name: db-credentials
    namespace: production
  spec:
    refreshInterval: 1h
    secretStoreRef:
      name: aws-secret-store
      kind: SecretStore
    target:
      name: db-secret
      creationPolicy: Owner
    data:
    - secretKey: username
      remoteRef:
        key: prod/database
        property: username
    - secretKey: password
      remoteRef:
        key: prod/database
        property: password
  ```

#### Sealed Secrets（备选方案）

* [ ] **安装Sealed Secrets**
  
  ```bash
  # 安装controller
  kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml
  
  # 安装kubeseal CLI
  brew install kubeseal
  ```

* [ ] **加密Secret**
  
  ```bash
  # 创建普通Secret
  kubectl create secret generic mysecret \
    --from-literal=username=admin \
    --from-literal=password=secret123 \
    --dry-run=client -o yaml > mysecret.yaml
  
  # 加密为SealedSecret
  kubeseal -f mysecret.yaml -w mysealedsecret.yaml
  
  # 现在可以安全地提交到Git
  kubectl apply -f mysealedsecret.yaml
  
  # Controller会自动解密为普通Secret
  kubectl get secret mysecret -o yaml
  ```

---

### 第四部分：CI/CD安全（2小时）

#### Pipeline安全最佳实践

* [ ] **GitHub Actions安全配置**
  
  ```yaml
  # .github/workflows/secure-pipeline.yml
  name: Secure CI/CD Pipeline
  
  on:
    pull_request:
      branches: [main]
  
  permissions:
    contents: read
    pull-requests: write
  
  jobs:
    security-scan:
      runs-on: ubuntu-latest
      steps:
      # IaC扫描
      - uses: actions/checkout@v4
      
      - name: Run Checkov
        uses: bridgecrewio/checkov-action@master
        with:
          directory: k8s/
          framework: kubernetes
          output_format: sarif
          output_file_path: checkov-results.sarif
          soft_fail: false  # 有问题就失败
      
      - name: Upload Checkov results
        uses: github/codeql-action/upload-sarif@v2
        if: always()
        with:
          sarif_file: checkov-results.sarif
      
      # 密钥扫描
      - name: Secret scan
        run: |
          pip install detect-secrets
          detect-secrets scan --baseline .secrets.baseline
      
      # 依赖检查
      - name: Dependency check
        run: |
          trivy fs --scanners vuln,secret,config .
  ```

* [ ] **构建环境隔离**
  
  ```yaml
  # 使用短生命周期的runner
  jobs:
    build:
      runs-on: ubuntu-latest
      container:
        image: alpine:3.19
        # 最小权限
        options: --read-only --tmpfs /tmp
  ```

---

## 🏆 里程碑项目：Pipeline卫士

**任务**: 构建一个完整的DevSecOps流水线，在CI阶段自动化所有安全检查。

### 要求

1. ✅ **代码提交触发**检查
2. ✅ **IaC扫描**（Checkov）
3. ✅ **密钥扫描**（Trivy/detect-secrets）
4. ✅ **镜像扫描**（Trivy）
5. ✅ **SBOM生成**（Syft）
6. ✅ **Critical漏洞阻断**（exit code 1）
7. ✅ **结果上传到GitHub Security**
8. ✅ **GitOps部署**（ArgoCD）

### 实施步骤

```yaml
# .github/workflows/devsecops-pipeline.yml
name: DevSecOps Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  security-checks:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    # Stage 1: IaC扫描
    - name: IaC Security Scan
      uses: bridgecrewio/checkov-action@master
      with:
        directory: k8s/
        soft_fail: false
    
    # Stage 2: 密钥扫描
    - name: Secret Scan
      run: |
        trivy fs --scanners secret --exit-code 1 .
    
    # Stage 3: 构建镜像
    - name: Build Image
      run: |
        docker build -t myapp:${{ github.sha }} .
    
    # Stage 4: 镜像扫描
    - name: Image Scan
      run: |
        trivy image --severity CRITICAL,HIGH --exit-code 1 myapp:${{ github.sha }}
    
    # Stage 5: SBOM生成
    - name: Generate SBOM
      run: |
        syft myapp:${{ github.sha }} -o spdx-json > sbom.json
    
    # Stage 6: 部署到ArgoCD
    - name: Update manifests
      if: github.ref == 'refs/heads/main'
      run: |
        # 更新镜像tag
        sed -i "s|image: .*|image: myapp:${{ github.sha }}|" k8s/deployment.yaml
        git config user.name "CI Bot"
        git config user.email "ci@example.com"
        git add k8s/deployment.yaml
        git commit -m "Update image to ${{ github.sha }}"
        git push
```

### ✅ 通关标准

1. ✅ 所有扫描步骤成功执行
2. ✅ 有Critical漏洞时构建失败
3. ✅ 扫描结果上传到GitHub Security tab
4. ✅ 只有通过所有检查的代码才能合并到main
5. ✅ ArgoCD自动同步新版本

---

## 📚 扩展学习

### IaC安全框架
- [Terraform Sentinel](https://www.terraform.io/docs/cloud/sentinel/index.html)
- [OPA for Terraform](https://www.openpolicyagent.org/docs/latest/terraform/)
- [Pulumi CrossGuard](https://www.pulumi.com/docs/guides/crossguard/)

### GitOps最佳实践
- [GitOps Principles](https://opengitops.dev/)
- [Flux vs ArgoCD对比](https://fluxcd.io/flux/faq/#what-is-the-difference-between-flux-and-argo-cd)

### 开源项目
- 贡献Checkov检测规则
- 开发ArgoCD插件
- 创建自定义Admission Webhook

---

## 🔗 与SDL的关联

| SDL实践 | IaC安全对应 | 说明 |
|---------|------------|------|
| 代码审查 | IaC Review | 审查Terraform/K8s YAML |
| SAST扫描 | Checkov/KICS | 静态分析配置 |
| 安全门禁 | CI/CD集成 | 未通过不能合并 |
| 密钥管理 | Secrets Management | 密钥不入代码库 |
| 变更审计 | Git History | 所有变更可追溯 |

---

*在此目录下创建 `notes.md` 记录学习笔记。*
