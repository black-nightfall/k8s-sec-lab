# ⛓️ 阶段三：镜像安全与供应链

**目标**: 构建从源码到运行时的供应链安全体系，确保容器镜像干净、可信、可追溯。

> **🔄 技能迁移**: SAST/SCA → Container Image Scanning & SBOM
> 
> 对于具有SDL背景的学习者：传统开发中使用SAST扫描代码漏洞、SCA扫描依赖漏洞，容器安全中则使用镜像扫描器检测OS包和应用依赖的CVE。SBOM（软件物料清单）类似于传统软件的依赖清单，但范围更广，涵盖整个容器镜像。

> **💡 核心概念**:
> *   **CVE (Common Vulnerabilities and Exposures)**: 公开的安全漏洞数据库
> *   **CVSS (Common Vulnerability Scoring System)**: 漏洞严重程度评分标准（0-10分）
> *   **镜像扫描**: 分析容器镜像中的OS包、应用依赖，查找已知漏洞
> *   **SBOM**: Software Bill of Materials，软件物料清单，记录镜像中的所有组件
> *   **镜像签名**: 使用密码学签名验证镜像完整性和来源
> *   **Supply Chain Attack**: 供应链攻击，通过污染依赖或构建过程植入恶意代码

---

## 📝 学习任务

### 第一部分：镜像扫描原理与实践（3小时）

#### 理解CVE与漏洞管理

* [ ] **CVE数据库**
  
  CVE由MITRE维护，记录公开的安全漏洞。每个CVE有唯一ID，如CVE-2024-1234。
  
  ```bash
  # 查看CVE详情（示例）
  curl https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-44228
  # Log4Shell漏洞
  ```
  
  **CVSS评分标准**：
  - **Critical (9.0-10.0)**: 严重，立即修复
  - **High (7.0-8.9)**: 高危，优先修复
  - **Medium (4.0-6.9)**: 中危，计划修复
  - **Low (0.1-3.9)**: 低危，可选修复

* [ ] **漏洞数据源**
  
  镜像扫描器从多个数据库获取漏洞信息：
  - NVD (National Vulnerability Database) - NIST维护
  - Debian/Ubuntu/Alpine Security Tracker
  - GitHub Advisory Database
  - Red Hat Security Data

#### Trivy深度使用

Trivy是Aqua Security开源的镜像扫描器，支持多种扫描目标。

* [ ] **安装Trivy**
  
  ```bash
  # macOS
  brew install trivy
  
  # Linux
  wget https://github.com/aquasecurity/trivy/releases/download/v0.48.0/trivy_0.48.0_Linux-64bit.tar.gz
  tar zxvf trivy_0.48.0_Linux-64bit.tar.gz
  sudo mv trivy /usr/local/bin/
  
  # 验证安装
  trivy --version
  ```

* [ ] **扫描容器镜像**
  
  ```bash
  # 扫描公开镜像
  trivy image nginx:1.14
  # 注意漏洞数量，特别是Critical和High
  
  # 扫描新版本对比
  trivy image nginx:alpine
  # Alpine镜像通常漏洞更少
  
  # 只显示Critical和High
  trivy image --severity CRITICAL,HIGH nginx:1.14
  
  # 输出JSON格式
  trivy image -f json -o results.json nginx:1.14
  
  # 扫描本地构建的镜像
  docker build -t myapp:1.0 .
  trivy image myapp:1.0
  ```

* [ ] **理解扫描结果**
  
  Trivy扫描结果包含：
  ```
  Library: 受影响的包名
  Vulnerability ID: CVE编号
  Severity: 严重程度
  Installed Version: 当前安装版本
  Fixed Version: 修复版本（如果有）
  Title: 漏洞描述
  ```
  
  **实战练习**：
  ```bash
  # 扫描一个老旧镜像
  trivy image python:3.7
  
  # 问题思考：
  # 1. Total CVE数量是多少？
  # 2. Critical有多少？
  # 3. 有多少可以通过升级修复？
  # 4. 有多少是无修复版本的（unfixed）？
  ```

* [ ] **镜像扫描器对比**
  
  | 工具 | 开源 | 速度 | 准确度 | 特点 |
  |------|------|------|--------|------|
  | Trivy | ✅ | 快 | 高 | 易用，支持多种目标 |
  | Grype | ✅ | 快 | 高 | Anchore出品 |
  | Clair | ✅ | 中 | 高 | 需要部署服务 |
  | Snyk | ❌ | 快 | 高 | 商业，有免费额度 |
  
  **实验**：用Grype扫描同一镜像，对比结果
  ```bash
  # 安装Grype
  brew install grype
  
  # 扫描
  grype nginx:1.14
  
  # 对比Trivy和Grype的结果差异
  ```

#### 文件系统和配置扫描

* [ ] **扫描文件系统**
  
  Trivy不仅扫描镜像，还能扫描本地目录
  
  ```bash
  # 扫描当前目录
  trivy fs .
  
  # 扫描特定目录
  trivy fs /path/to/project
  
  # 检测密钥泄露
  trivy fs --scanners secret .
  ```

* [ ] **密钥泄露检测**
  
  **常见泄露模式**：
  - AWS Access Key: `AKIA...`
  - GitHub Token: `ghp_...`
  - Private Key: `-----BEGIN RSA PRIVATE KEY-----`
  - API Keys, Passwords in code
  
  **实战练习**：创建包含泄露的Dockerfile
  ```dockerfile
  # Dockerfile.with-secrets
  FROM alpine
  
  # ❌ 硬编码密钥（故意的，用于演示）
  ENV AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
  ENV AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
  ENV DB_PASSWORD=super_secret_password_123
  
  COPY . /app
  ```
  
  ```bash
  # 创建测试文件
  echo "github_token=ghp_1234567890abcdef" > .env
  
  # 扫描密钥
  trivy fs --scanners secret .
  
  # 应该检测到AWS keys和GitHub token
  ```

* [ ] **IaC配置扫描**
  
  ```bash
  # 扫描Kubernetes YAML
  trivy config deployment.yaml
  
  # 扫描Terraform
  trivy config ./terraform/
  
  # 检测的问题类型：
  # - 特权容器
  # - 缺少资源限制
  # - root用户运行
  # - 不安全的配置
  ```

---

### 第二部分：SBOM软件物料清单（2小时）

#### 理解SBOM

SBOM记录软件中的所有组件，类似于食品配料表。

**为什么需要SBOM？**
- 快速响应漏洞（如Log4Shell爆发时，快速定位影响范围）
- 合规要求（美国政府要求）
- 供应链透明度

* [ ] **SBOM标准**
  
  两大主流标准：
  
  **1. SPDX (Software Package Data Exchange)**
  - Linux Foundation维护
  - ISO/IEC 5962国际标准
  
  **2. CycloneDX**
  - OWASP维护
  - 专注于安全用例
  - 更轻量级

#### 使用Syft生成SBOM

Syft是Anchore开源的SBOM生成工具。

* [ ] **安装Syft**
  
  ```bash
  # macOS
  brew install syft
  
  # Linux
  curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh
  
  # 验证
  syft --version
  ```

* [ ] **生成镜像SBOM**
  
  ```bash
  # 生成SPDX格式
  syft nginx:alpine -o spdx-json > nginx-sbom-spdx.json
  
  # 生成CycloneDX格式
  syft nginx:alpine -o cyclonedx-json > nginx-sbom-cdx.json
  
  # 人类可读格式
  syft nginx:alpine -o table
  
  # 查看SBOM包含哪些包
  cat nginx-sbom-spdx.json | jq '.packages[].name' | head -20
  ```

* [ ] **分析SBOM**
  
  ```bash
  # 查看包数量
  cat nginx-sbom-spdx.json | jq '.packages | length'
  
  # 查找特定包
  cat nginx-sbom-spdx.json | jq '.packages[] | select(.name=="openssl")'
  
  # 查看所有版本信息
  cat nginx-sbom-spdx.json | jq '.packages[] | {name, version}'
  ```

#### 供应链攻击案例分析

* [ ] **Log4Shell (CVE-2021-44228)**
  
  2021年12月，Apache Log4j 2的远程代码执行漏洞。
  
  **影响范围**：几乎所有使用Java的应用
  
  **SBOM的价值**：
  ```bash
  # 快速查找受影响的镜像
  syft myapp:1.0 -o json | jq '.artifacts[] | select(.name=="log4j-core")'
  
  # 检查版本是否在受影响范围
  # 受影响版本: 2.0-beta9 to 2.14.1
  ```

* [ ] **SolarWinds供应链攻击**
  
  2020年，攻击者在SolarWinds Orion构建过程中植入后门。
  
  **防御措施**：
  - SBOM记录所有依赖
  - 镜像签名验证完整性
  - 可重现构建（Reproducible Builds）

---

### 第三部分：镜像签名与验证（2小时）

#### Sigstore生态系统

Sigstore提供免费的镜像签名服务，无需管理私钥。

**组件**：
- **Cosign**: 签名和验证工具
- **Rekor**: 透明日志（签名记录）
- **Fulcio**: 证书颁发机构

* [ ] **安装Cosign**
  
  ```bash
  # macOS
  brew install cosign
  
  # Linux
  wget https://github.com/sigstore/cosign/releases/download/v2.2.0/cosign-linux-amd64
  chmod +x cosign-linux-amd64
  sudo mv cosign-linux-amd64 /usr/local/bin/cosign
  
  # 验证
  cosign version
  ```

* [ ] **密钥对生成**
  
  ```bash
  # 生成密钥对
  cosign generate-key-pair
  # 会生成 cosign.key（私钥）和 cosign.pub（公钥）
  # 输入密码保护私钥
  
  # ⚠️ 私钥务必妥善保管！
  chmod 600 cosign.key
  ```

* [ ] **签名镜像**
  
  ```bash
  # 构建测试镜像
  docker build -t localhost:5000/myapp:signed .
  docker push localhost:5000/myapp:signed
  
  # 签名（使用密钥对）
  cosign sign --key cosign.key localhost:5000/myapp:signed
  
  # 签名（使用keyless，无需管理密钥）
  cosign sign localhost:5000/myapp:signed
  # 会打开浏览器进行OIDC认证（Google/GitHub等）
  ```

* [ ] **验证签名**
  
  ```bash
  # 使用公钥验证
  cosign verify --key cosign.pub localhost:5000/myapp:signed
  
  # 验证成功会显示签名信息
  # 验证失败会报错
  
  # 尝试验证未签名的镜像
  cosign verify --key cosign.pub nginx:alpine
  # Error: no signatures found
  ```

* [ ] **结合Kubernetes准入控制**
  
  可以使用Kyverno或OPA Gatekeeper强制镜像签名验证
  
  ```yaml
  # kyverno-verify-image.yaml
  apiVersion: kyverno.io/v1
  kind: ClusterPolicy
  metadata:
    name: verify-image-signature
  spec:
    validationFailureAction: enforce
    rules:
    - name: verify-signature
      match:
        any:
        - resources:
            kinds:
            - Pod
      verifyImages:
      - imageReferences:
        - "myregistry.io/*"
        attestors:
        - count: 1
          entries:
          - keys:
              publicKeys: |-
                -----BEGIN PUBLIC KEY-----
                <your-public-key>
                -----END PUBLIC KEY-----
  ```

---

### 第四部分：镜像构建最佳实践（2小时）

#### Dockerfile安全编写

* [ ] **使用Distroless/Alpine基础镜像**
  
  ```dockerfile
  # ❌ 不推荐：完整OS，攻击面大
  FROM ubuntu:22.04
  
  # ✅ 推荐：Alpine，最小化
  FROM alpine:3.19
  
  # ✅ 更好：Distroless，只有应用运行时
  FROM gcr.io/distroless/static-debian11
  ```
  
  **Distroless优势**：
  - 无shell（防止反弹shell）
  - 无包管理器（防止安装恶意软件）
  - 镜像更小（100MB+ → 10MB）
  - 漏洞更少

* [ ] **多阶段构建**
  
  ```dockerfile
  # 多阶段构建示例：Go应用
  
  # Stage 1: 构建阶段
  FROM golang:1.21 AS builder
  
  WORKDIR /app
  COPY go.mod go.sum ./
  RUN go mod download
  
  COPY . .
  RUN CGO_ENABLED=0 GOOS=linux go build -o myapp
  
  # Stage 2: 运行阶段（Distroless）
  FROM gcr.io/distroless/static-debian11
  
  COPY --from=builder /app/myapp /myapp
  
  USER nonroot:nonroot
  
  ENTRYPOINT ["/myapp"]
  ```
  
  **对比**：
  ```bash
  # 单阶段构建
  docker images | grep single-stage
  # myapp  single  800MB
  
  # 多阶段构建
  docker images | grep multi-stage
  # myapp  multi   15MB
  
  # 扫描漏洞对比
  trivy image myapp:single
  trivy image myapp:multi
  ```

* [ ] **不要在镜像中存储密钥**
  
  ```dockerfile
  # ❌ 错误做法
  FROM alpine
  COPY .env /app/.env
  # 即使后面删除，密钥仍在镜像层中！
  
  # ✅ 正确做法：使用构建参数（谨慎）
  ARG NPM_TOKEN
  RUN npm config set //registry.npmjs.org/:_authToken=${NPM_TOKEN}
  # 构建完成后token不在最终镜像中
  
  # ✅ 更好：使用BuildKit secret挂载
  # 需要Docker BuildKit
  RUN --mount=type=secret,id=npmtoken \
      npm config set //registry.npmjs.org/:_authToken=$(cat /run/secrets/npmtoken) && \
      npm install && \
      npm config delete //registry.npmjs.org/:_authToken
  ```

* [ ] **固定版本，避免latest**
  
  ```dockerfile
  # ❌ 不确定性，可重现性差
  FROM nginx:latest
  
  # ✅ 固定具体版本
  FROM nginx:1.25.3-alpine
  
  # ✅ 锁定摘要（最安全）
  FROM nginx:1.25.3-alpine@sha256:abc123...
  ```

* [ ] **最小化镜像层**
  
  ```dockerfile
  # ❌ 多个RUN，层数多
  RUN apt-get update
  RUN apt-get install -y curl
  RUN apt-get install -y vim
  
  # ✅ 合并RUN，减少层数
  RUN apt-get update && \
      apt-get install -y curl vim && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/*
  ```

---

## 🏆 里程碑项目：捉虫行动 + 安全流水线

### 项目一：Dockerfile漏洞挖掘

**任务**: 编写一个故意包含多种安全问题的Dockerfile，使用Trivy扫描出所有问题。

#### Step 1: 创建"脆弱"的Dockerfile

```dockerfile
# Dockerfile.vulnerable
# ⚠️ 此Dockerfile故意包含安全问题，仅用于学习！

FROM ubuntu:18.04

# 问题1: 以root运行
# 问题2: 旧版本OS（CVE多）

# 问题3: 硬编码密钥
ENV AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
ENV AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
ENV DATABASE_PASSWORD=admin123

# 问题4: 安装不必要的包
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    vim \
    netcat \
    nmap \
    telnet

# 问题5: 不清理APT缓存
# apt缓存未删除

# 问题6: 使用latest标签的依赖
RUN wget https://example.com/app-latest.tar.gz

# 问题7: 可写的文件系统
# 没有设置readOnlyRootFilesystem

# 问题8: 暴露不必要的端口
EXPOSE 22 23 3306 6379

# 问题9: 以特权模式运行
# （需要在运行时配置，但Dockerfile未限制）

CMD ["/bin/bash"]
```

#### Step 2: 扫描并记录所有问题

```bash
# 构建镜像
docker build -f Dockerfile.vulnerable -t vulnerable-app:bad .

# 全面扫描
trivy image vulnerable-app:bad

# 只看Critical和High
trivy image --severity CRITICAL,HIGH vulnerable-app:bad

# 扫描密钥泄露
trivy image --scanners secret vulnerable-app:bad

# 扫描配置问题
trivy config Dockerfile.vulnerable
```

#### Step 3: 创建修复版本

```dockerfile
# Dockerfile.secure
FROM alpine:3.19

# ✅ 使用非root用户
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser

# ✅ 只安装必要的包
RUN apk add --no-cache ca-certificates

WORKDIR /app

# ✅ 复制应用文件
COPY --chown=appuser:appuser ./app /app

# ✅ 切换到非root用户
USER appuser

# ✅ 只暴露必要端口
EXPOSE 8080

# ✅ 使用非root端口
CMD ["./app"]
```

```bash
# 构建安全镜像
docker build -f Dockerfile.secure -t vulnerable-app:good .

# 对比扫描结果
trivy image vulnerable-app:bad > scan-bad.txt
trivy image vulnerable-app:good > scan-good.txt

diff scan-bad.txt scan-good.txt
```

### 项目二：构建镜像安全流水线

**任务**: 创建GitHub Actions工作流，实现：扫描 → 签名 → 验证的完整流程

#### Step 1: 创建工作流文件

```yaml
# .github/workflows/image-security.yml
name: Image Security Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  scan-build-sign:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    # Step 1: 构建镜像
    - name: Build Docker image
      run: |
        docker build -t myapp:${{ github.sha }} .
        docker save myapp:${{ github.sha }} -o image.tar
    
    # Step 2: 扫描漏洞
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: 'myapp:${{ github.sha }}'
        format: 'sarif'
        output: 'trivy-results.sarif'
        severity: 'CRITICAL,HIGH'
        exit-code: '1'  # 有Critical/High漏洞就失败
    
    # Step 3: 上传扫描结果到GitHub Security
    - name: Upload Trivy scan results
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: 'trivy-results.sarif'
    
    # Step 4: 生成SBOM
    - name: Generate SBOM
      run: |
        docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
          anchore/syft:latest myapp:${{ github.sha }} -o spdx-json > sbom.json
    
    - name: Upload SBOM artifact
      uses: actions/upload-artifact@v3
      with:
        name: sbom
        path: sbom.json
    
    # Step 5: 签名镜像（仅在main分支）
    - name: Install Cosign
      if: github.ref == 'refs/heads/main'
      uses: sigstore/cosign-installer@v3
    
    - name: Sign image
      if: github.ref == 'refs/heads/main'
      env:
        COSIGN_EXPERIMENTAL: 1
      run: |
        cosign sign myapp:${{ github.sha }}
    
    # Step 6: 推送到Registry
    - name: Push to Registry
      if: github.ref == 'refs/heads/main'
      run: |
        docker tag myapp:${{ github.sha }} myregistry.io/myapp:${{ github.sha }}
        docker push myregistry.io/myapp:${{ github.sha }}
```

#### Step 2: 本地验证流程

```bash
# 模拟CI流程

# 1. 构建
docker build -t myapp:test .

# 2. 扫描
trivy image --severity CRITICAL,HIGH --exit-code 1 myapp:test
# 如果有Critical/High漏洞，exit code 为 1

# 3. 生成SBOM
syft myapp:test -o spdx-json > sbom.json

# 4. 签名
cosign sign --key cosign.key myapp:test

# 5. 验证
cosign verify --key cosign.pub myapp:test
```

### ✅ 通关标准

**项目一**：
1. ✅ 在Dockerfile.vulnerable中至少包含8种安全问题
2. ✅ Trivy扫描出至少5个Critical级别漏洞
3. ✅ Trivy检测到至少2个密钥泄露
4. ✅ 修复后的镜像漏洞减少80%+

**项目二**：
1. ✅ CI流水线成功运行所有步骤
2. ✅ 有Critical漏洞时构建失败
3. ✅ 成功生成SBOM
4. ✅ 成功签名并验证镜像

---

## 📚 扩展学习

### 深入理解供应链安全

1. **SLSA (Supply-chain Levels for Software Artifacts)**
   - [SLSA.dev](https://slsa.dev)
   - Google发起的供应链安全框架
   - 4个等级的安全保证

2. **in-toto**
   - 记录软件供应链每个步骤
   - 验证构建到部署的完整性

3. **GUAC (Graph for Understanding Artifact Composition)**
   - Google开源的SBOM聚合和分析工具

### 开源项目实践

1. **贡献Trivy检测规则**
   - `github.com/aquasecurity/trivy-db`
   - 添加新的CVE数据源或检测逻辑

2. **开发Kubectl插件**
   - 创建kubectl插件扫描集群中所有镜像
   - 生成漏洞报告

3. **集成到CI/CD**
   - 为常用CI系统贡献Trivy插件
   - 优化扫描性能

---

## 🤔 学习验证清单

完成本阶段后，应该能够回答：

- [ ] CVE和CVSS是什么？如何评估漏洞严重性？
- [ ] 镜像扫描器的工作原理是什么？
- [ ] Trivy、Grype、Clair的区别？
- [ ] SBOM有什么用？两大标准是什么？
- [ ] 供应链攻击的常见手法有哪些？
- [ ] 如何使用Cosign签名和验证镜像？
- [ ] Distroless镜像的优势是什么？
- [ ] 多阶段构建如何减少镜像大小和漏洞？
- [ ] 如何在CI/CD中集成镜像扫描？
- [ ] 如何处理无修复版本的漏洞（unfixed CVE）？

---

## 🔗 与SDL的关联

| SDL实践 | 镜像安全对应 | 说明 |
|---------|------------|------|
| SAST代码扫描 | 镜像配置扫描 | Trivy扫描Dockerfile |
| SCA依赖扫描 | 镜像漏洞扫描 | 检测OS包和应用依赖CVE |
| BOM管理 | SBOM生成 | 软件物料清单 |
| 制品签名 | 镜像签名 | Cosign/Notary |
| 左移安全 | CI/CD集成 | 构建时就发现问题 |
| 漏洞管理 | CVE跟踪修复 | 持续监控和修复 |

---

*在此目录下创建 `solutions.md` 保存练习代码和截图，创建 `notes.md` 记录学习笔记和问题。*
