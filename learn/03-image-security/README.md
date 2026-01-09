# ⛓️ 阶段三：镜像安全 (Image Security)
**目标**: 确保你运行的软件是“干净”的，没有自带病毒或漏洞。

> **👶 小白概念站**:
> *   **镜像漏洞**: 比如你用的 `nginx:1.14` 包含一个已知的 OpenSSL 漏洞，黑客可以利用它。
> *   **左移 (Shift Left)**: 在黑客攻击之前（开发阶段）就发现问题。

## 📝 学习任务

* [ ] **安装扫描器 (Trivy)**
  * 操作: `apt install trivy` (或下载二进制)。
* [ ] **初次体验漏洞扫描**
  * **练习**: 扫描一个老旧镜像 `trivy image nginx:1.14`，看看有多少红色的 "Critical" 漏洞。
  * **练习**: 扫描一个新镜像 `trivy image nginx:alpine`，对比漏洞数量。
* [ ] **文件系统扫描**
  * **练习**: 写一个包含密码的文本文件，用 `trivy fs .` 扫描，看它能否发现“泄露的秘密”。

## 🏆 里程碑练习：捉虫行动

**任务**: 编写一个故意包含漏洞（如硬编码 AWS Key）的 Dockerfile，并使用 Trivy 扫描出所有问题。

1. 创建 `Dockerfile`，故意写入 `ENV AWS_SECRET_KEY=AKIA...`
2. 运行 `trivy fs .` 或构建后运行 `trivy image <image-name>`。

**✅ 通关标准**: Trivy 报告中至少发现 1 个 Secret 泄露和 5 个 Critical 级别漏洞。

---
*在此目录下创建你的练习笔记或截图...*
