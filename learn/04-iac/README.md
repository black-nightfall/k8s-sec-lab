# 🏗️ 阶段四：基础设施即代码 (IaC) 与各种“左移”
**目标**: 将你的 SDL 经验发挥到极致。在代码合并之前，就在 Git 仓库里消灭安全隐患。

> **SDL 转岗优势**: 你非常熟悉 SAST/DAST。在云原生里，Trivy/Checkov 就是基础设施的 SAST。

## 📝 学习任务

* [ ] **IaC 扫描 (Terraform/Kubernetes)**
  * **工具**: Checkov 或 KICS。
  * **练习**: 编写一个故意开放 `0.0.0.0/0` SSH 端口的 Terraform 文件，或者 `readOnlyRootFilesystem: false` 的 K8s YAML，用工具扫描并阻断。
* [ ] **GitOps 安全 (ArgoCD)**
  * **概念**: 了解为什么“不要手动 kubectl apply”，而是由 Git 仓库单一信源控制。
  * **练习**: 部署 ArgoCD，并配置 RBAC，只允许特定仓库同步。
* [ ] **密钥管理 (Secrets Management)**
  * **痛点**: 代码里不能有密码。
  * **练习**: 使用 **External Secrets Operator** (ESO) 集成 AWS Secrets Manager 或 HashiCorp Vault (可以使用模拟环境)。

## 🏆 里程碑练习：Pipeline 卫士

**任务**: 配置一个 GitHub Actions (或 GitLab CI) 流水线。
1. 代码提交触发扫描 (Trivy + Checkov)。
2. 构建 Docker 镜像。
3. 如果有 Critical 漏洞，直接 Fail 掉 Build，不生成镜像。
4. 生成 SBOM (软件物料清单)。

**✅ 通关标准**: 必须修复所有 Critical 问题才能看到绿色的 Build Success。

---
*在此目录下创建你的练习笔记或截图...*
