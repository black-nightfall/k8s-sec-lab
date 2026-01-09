# ☁️ 阶段八：公有云模拟 (Public Cloud Security)
**目标**: 补齐你的“云”拼图。虽然我们在本地，但可以用 LocalStack 模拟 AWS 环境，学习 IAM 和 S3 安全。

> **👶 小白概念站**:
> *   **LocalStack**: 一个在本地运行的 AWS 模拟器，让你不花钱也能练 AWS 命令。
> *   **CSPM (云安全态势管理)**: 自动检查你的云配置对不对（比如 S3 桶是不是公开了）。
> *   **IAM (身份与访问管理)**: 云上的“账号”和“权限”系统，是云安全最核心的关卡。

## 📝 学习任务

* [ ] **部署 LocalStack**
  * **操作**: 使用 Helm 在 K8s 中部署 LocalStack。
  * **验证**: 使用 `awscli` 配置 endpoint pointing to localhost，成功执行 `aws s3 ls`。
* [ ] **IAM 权限过大演练**
  * **实验**: 创建一个 IAM Role，赋予 `AdministratorAccess` (最高权限)。
  * **攻击**: 模拟攻击者获取了该 Role 的凭证，删除了所有 S3 桶。
  * **修复**: 将权限缩减为 `AmazonS3ReadOnlyAccess`，验证攻击失效。
* [ ] **S3 数据泄露演练**
  * **实验**: 创建一个 S3 Bucket，并配置 ACL 为 `public-read`。
  * **扫描**: 使用 Trivy 或 Checkov 扫描 Terraform 代码（或使用 Prowler 扫描环境），发现这个高危配置。

## 🏆 里程碑练习：云攻防实验室

**任务**: 搭建一个“脆弱”的云环境并进行加固。

1. **部署**: 在 LocalStack 中创建一个模拟的 EC2 实例（容器）和一个 S3 桶。
2. **攻击验证**: 尝试不带密钥访问 S3 桶，成功读取数据（模拟数据泄露）。
3. **加固**:
    *   修改 Bucket Policy，禁止匿名访问。
    *   启用 KMS 加密。
4. **再次验证**: 匿名访问被拒绝 (`403 Access Denied`)。

**✅ 通关标准**: 成功生成一份 Prowler (或类似 CSPM 工具) 报告，显示通过了 CIS AWS Benchmark 检查。

---
*在此目录下创建你的练习笔记...*
