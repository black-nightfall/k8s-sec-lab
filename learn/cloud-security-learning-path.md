# 🛡️ 云原生安全实战学习导航 (From SDL to Cloud Security)

> **👤 职业规划分析 (Target: Cloud Security Engineer)**
>
> 你当前作为 **SDL** 工程师转岗云安全具有**天然优势 (Left 侧)**，但急需补充 **Infrastructure (Right 侧)** 能力。
>
> *   **你的强项**: 代码审计、漏洞原理、SAST/DAST、威胁建模。
> *   **需要补齐**: K8s 运维、容器网络 (Cilium)、云平台配置 (IAM/VPC)、合规标准 (CIS)。
>
> 👇 **这份路线图已升级，完美覆盖了从代码侧 (你的舒适区) 到 运维侧 (你的挑战区) 的全链路。**

这份路线图已经拆分为不同的模块。请进入对应的目录查看任务详情，并在该目录下保存你的练习文件（如 YAML, 脚本, 截图等）。

> **🤝 协作方式**: 当你完成一个阶段的里程碑后，请在该目录下创建一个 `solutions.md` 或直接存放代码文件，然后告诉我“帮我检查阶段 X 的作业”。

## 📚 学习模块 (按生命周期排序)

### 🕵️‍♂️ 阶段一：感知与透视 (Visibility)
> *先看清战场，再谈战略。*
### [1️⃣ 基础与可视化 (Visibility)](./01-visibility/)
*   **重点**: Cilium, Hubble, K9s
*   **里程碑**: 星战前传

### 🧬 阶段二：原子安全 (The Unit)
> *容器本身不牢固，集群再强也没用。*
### [2️⃣ 容器安全与硬化 (Container Security)](./02-container-security/)
*   **重点**: Capabilities, Seccomp, ReadOnlyRootFS, Non-Root
*   **里程碑**: 铁桶阵 (极致硬化 Nginx)

### ⛓️ 阶段三：供应链 (Supply Chain)
> *确保源头是干净的。*
### [3️⃣ 镜像安全 (Image Security)](./03-image-security/)
*   **重点**: Trivy, 漏洞扫描, 镜像签名
*   **里程碑**: 捉虫行动 (Dockerfile 漏洞挖掘)

### 🏗️ 阶段四：构建与部署 (Build/Deploy)
> *在代码和配置及集群之前拦截风险。*
### [4️⃣ 基础设施即代码 (IaC)](./04-iac/)
*   **重点**: Checkov, Pipeline 集成, GitOps (这是 SDL 最能发光的地方)
*   **里程碑**: Pipeline 卫士 (CI 自动阻断)
### [5️⃣ 准入控制 (Admission)](./05-admission/)
*   **重点**: Kyverno, 策略即代码 (相当于 WAF 但针对配置)
*   **里程碑**: 门禁升级 (强制标签策略)

### 🛡️ 阶段五：运行与防御 (Runtime Defense)
> *构建纵深防御体系。*
### [6️⃣ 网络微隔离 (Zero Trust)](./06-zero-trust/)
*   **重点**: NetworkPolicy, L7 过滤 (不仅是防火墙，更是应用安全)
*   **里程碑**: 死星防御 (API 访问控制)
### [7️⃣ 运行时监控 (Runtime Detect)](./07-runtime-defense/)
*   **重点**: Falco, 异常行为行为分析
*   **里程碑**: 现行犯抓捕 (恶意文件监控)

### ☁️ 阶段六：基础设施 (Infrastructure)
> *云平台底座的安全。*
### [8️⃣ 公有云模拟 (Public Cloud)](./08-public-cloud/)
*   **重点**: LocalStack, IAM, S3 安全, CSPM
*   **里程碑**: 云攻防实验室 (IAM 提权与 S3 泄露)

### ⚔️ 阶段七：验证与合规 (Verify)
> *以攻促防，通过审计。*
### [9️⃣ 红队演练 (Red Teaming)](./09-red-teaming/)
*   **重点**: 容器逃逸, 渗透测试
*   **里程碑**: 越狱 (特权容器逃逸)
### [🔟 审计与合规 (Compliance)](./10-compliance/)
*   **重点**: CIS Benchmarks, kube-bench, 审计日志
*   **里程碑**: 合规体检报告

### 🎓 终章：职业认证 (Certificate)
### [11 职业规划 (Career)](./11-career/)
*   **重点**: **CKS (必考)**, AWS Security, 面试策略
*   **分析**: 详细的 SDL -> Cloud Security 转岗指南

---

**建议**: 按顺序学习，每完成一个阶段并在目录下归档你的成果后，再进行下一阶段。