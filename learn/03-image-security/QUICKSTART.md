# 🚀 阶段三快速开始指南

本指南提供镜像安全与供应链的4天学习计划。

## ✅ 前置检查

- [ ] 已完成阶段1-2
- [ ] 安装Docker
- [ ] 熟悉Dockerfile编写
- [ ] 有GitHub账号（用于CI/CD实践）

## 📖 4天学习计划

### Day 1: 镜像扫描基础（2-3小时）

**目标**: 掌握Trivy使用

- [ ] 安装Trivy
- [ ] 扫描公开镜像（nginx:1.14 vs nginx:alpine）
- [ ] 理解CVE和CVSS评分
- [ ] 学习漏洞结果解读

**关键命令**:
```bash
trivy image nginx:1.14
trivy image --severity CRITICAL,HIGH nginx:alpine
trivy fs .
```

### Day 2: SBOM与供应链（2小时）

**目标**: 生成和分析软件物料清单

- [ ] 安装Syft
- [ ] 生成SBOM（SPDX和CycloneDX格式）
- [ ] 分析SBOM内容
- [ ] 学习Log4Shell案例

**关键命令**:
```bash
syft nginx:alpine -o spdx-json > sbom.json
cat sbom.json | jq '.packages | length'
```

### Day 3: 镜像签名与验证（2小时）

**目标**: 使用Cosign签名镜像

- [ ] 安装Cosign
- [ ] 生成密钥对
- [ ] 签名本地镜像
- [ ] 验证签名

**关键命令**:
```bash
cosign generate-key-pair
cosign sign --key cosign.key myapp:1.0
cosign verify --key cosign.pub myapp:1.0
```

### Day 4: Dockerfile最佳实践 + 里程碑（3-4小时）

**目标**: 安全的Dockerfile编写和完整流水线

- [ ] 学习Distroless/Alpine选择
- [ ] 多阶段构建实践
- [ ] 创建脆弱Dockerfile并扫描
- [ ] 构建GitHub Actions安全流水线

## 🆘 常见问题

### Q1: Trivy扫描很慢？

```bash
# 问题：首次扫描需要下载漏洞数据库

# 解决：预先下载数据库
trivy image --download-db-only

# 使用缓存
trivy image --cache-dir ~/.trivy/cache nginx:alpine
```

### Q2: 有很多unfixed CVE，怎么办？

**策略**:
1. 评估影响：unfixed不代表可利用
2. 检查是否有workaround
3. 考虑更换基础镜像
4. 使用WAF等其他防护

### Q3: Cosign keyless模式认证失败？

```bash
# 确保网络可以访问Sigstore服务
# 或使用密钥对模式

cosign generate-key-pair
cosign sign --key cosign.key image:tag
```

### Q4: 多阶段构建后Trivy还是扫描出很多漏洞？

**检查**:
- 最终stage的基础镜像是否最小化？
- 是否使用了Distroless？
- 是否只复制了必要文件？

```dockerfile
# ✅ 确保最终stage最小化
FROM gcr.io/distroless/static-debian11
COPY --from=builder /app/binary /app
```

## 💡 学习技巧

### 1. 对比不同基础镜像

```bash
# 扫描并对比
trivy image ubuntu:22.04 > ubuntu.txt
trivy image alpine:3.19 > alpine.txt
trivy image gcr.io/distroless/static-debian11 > distroless.txt

# 比较CVE数量
wc -l *.txt
```

### 2. 使用jq分析SBOM

```bash
# 查找特定包
cat sbom.json | jq '.packages[] | select(.name=="openssl")'

# 统计包类型
cat sbom.json | jq '.packages[].type' | sort | uniq -c
```

### 3. 集成到pre-commit hook

```bash
# .git/hooks/pre-commit
#!/bin/bash
trivy config . --exit-code 1
# 提交前自动扫描
```

## 📝 学习成果输出

### 1. 镜像扫描报告模板

创建扫描报告格式：
```markdown
## 镜像扫描报告
- **镜像**: myapp:1.0
- **扫描时间**: 2024-01-01
- **Total CVE**: 50
  - Critical: 2
  - High: 8
  - Medium: 25
  - Low: 15
- **修复建议**: ...
```

### 2. Dockerfile安全清单

```markdown
- [ ] 使用固定版本标签
- [ ] 使用最小基础镜像
- [ ] 多阶段构建
- [ ] 非root用户运行
- [ ] 无密钥泄露
- [ ] 清理缓存文件
```

### 3. CI/CD集成checklist

```xml
- [ ] Trivy扫描
- [ ] SBOM生成
- [ ] 镜像签名
- [ ] Critical漏洞阻断
- [ ] 扫描结果上传
```

## ⏭️ 下一步

完成后可以:
1. 进入阶段4 - IaC安全（Checkov）
2. 深化供应链安全（SLSA/in-toto）
3. 准备CKS认证（镜像安全是考点）
