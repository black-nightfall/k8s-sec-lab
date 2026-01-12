# 🛡️ 云原生安全实战学习路线

> **🎯 目标**: 构建从基础设施、容器到云平台的纵深防御体系

本路线图旨在通过实战练习，帮助具有开发或应用安全背景的工程师系统性掌握云原生安全技术。从代码审查到运行时监控，覆盖完整的安全生命周期。

路线图已拆分为不同的模块。请进入对应的目录查看任务详情，并在该目录下保存练习文件（如 YAML、脚本、截图等）。

> **🤝 学习方式**: 建议在每个阶段目录下创建 `solutions.md` 或存放相应的练习代码。可对照"通关标准"验证学习成果。

## 📊 SDL/应用安全 → 云安全技能迁移路径

对于具有SDL或应用安全背景的学习者，以下为技能迁移对照表：

| SDL/应用安全技能 | 云安全应用场景 | 对应阶段 | 关键工具 |
|----------------|--------------|---------|---------|
| SAST代码扫描 | IaC静态分析 | 阶段4 | Checkov/KICS |
| SCA依赖扫描 | 镜像扫描与SBOM | 阶段3 | Trivy/Syft |
| 代码Review | 配置审查(Policy as Code) | 阶段5 | Kyverno/OPA |
| 威胁建模 | 容器威胁建模 | 阶段7 | MITRE ATT&CK |
| 渗透测试 | K8s渗透测试 | 阶段9 | CDK/kube-hunter |
| RASP/IAST | 运行时监控 | 阶段7 | Falco/Tetragon |
| 合规审计 | CIS Benchmark | 阶段10 | kube-bench |
| 密钥管理 | Secrets Management | 阶段4 | External Secrets |

---

## 📚 学习模块（按生命周期排序）

### 🎯 阶段一：Kubernetes 基础入门
> *万丈高楼平地起，先打好 k8s 基础。*

### [1️⃣ Kubernetes 基础操作](./01-visibility/)
*   **重点**: Pod, Deployment, Service, kubectl 命令, K9s
*   **学习时长**: 约5天（每天2-3小时）
*   **里程碑**: 部署完整的 Web 应用（前后端分离）
*   **前置要求**: 无，适合零基础入门

---

### 🧬 阶段二：容器安全与硬化
> *容器本身不牢固，集群再强也没用。*

### [2️⃣ 容器安全与硬化 (Container Security)](./02-container-security/)
*   **重点**: Capabilities, Seccomp, AppArmor, SecurityContext, Pod Security Standards
*   **学习时长**: 约5天（每天2-3小时）
*   **技能迁移**: RASP → Container Runtime Security
*   **里程碑**: 铁桶阵（极致硬化 Nginx）
*   **前置要求**: 完成阶段1

---

### ⛓️ 阶段三：供应链安全
> *确保源头是干净的。*

### [3️⃣ 镜像安全 (Image Security)](./03-image-security/)
*   **重点**: Trivy扫描, SBOM, 镜像签名(Cosign), 漏洞管理
*   **学习时长**: 约4天（每天2-3小时）
*   **技能迁移**: SAST/SCA → Image Scanning
*   **里程碑**: 捉虫行动（Dockerfile 漏洞挖掘）+ 构建签名流水线
*   **前置要求**: 完成阶段1-2

---

### 🏗️ 阶段四：构建与部署安全
> *在代码和配置到达集群之前拦截风险。*

### [4️⃣ 基础设施即代码 (IaC)](./04-iac/)
*   **重点**: Checkov/KICS, GitOps(ArgoCD), Secrets Management, CI/CD安全
*   **学习时长**: 约6天（每天2-3小时）
*   **技能迁移**: 代码审计 → IaC静态分析
*   **里程碑**: Pipeline 卫士（CI 自动阻断）
*   **前置要求**: 完成阶段1-3

---

### 🚪 阶段五：准入控制
> *不合规的配置根本不允许进入集群。*

### [5️⃣ 准入控制 (Admission)](./05-admission/)
*   **重点**: Kyverno策略引擎, OPA/Gatekeeper, Policy as Code
*   **学习时长**: 约5天（每天2-3小时）
*   **技能迁移**: 代码Review → 配置Review
*   **里程碑**: 门禁升级（强制标签策略 + 企业级策略库）
*   **前置要求**: 完成阶段1-4

---

### 🛡️ 阶段六：运行时防御
> *构建纵深防御体系。*

### [6️⃣ 网络微隔离 (Zero Trust)](./06-zero-trust/)
*   **重点**: NetworkPolicy, Cilium L7过滤, Service Mesh(Istio)
*   **学习时长**: 约6天（每天2-3小时）
*   **技能迁移**: 网络防火墙 → 微服务零信任网络
*   **里程碑**: 死星防御（API 访问控制）
*   **前置要求**: 完成阶段1-5

### [7️⃣ 运行时监控 (Runtime Detection)](./07-runtime-defense/)
*   **重点**: Falco规则引擎, eBPF, 异常行为检测, MITRE ATT&CK
*   **学习时长**: 约5天（每天2-3小时）
*   **技能迁移**: RASP/IAST → Runtime Security
*   **里程碑**: 现行犯抓捕（恶意文件监控 + 自动化响应）
*   **前置要求**: 完成阶段1-6

---

### ☁️ 阶段七：云基础设施安全
> *云平台底座的安全。*

### [8️⃣ 公有云安全 (Public Cloud)](./08-public-cloud/)
*   **重点**: AWS IAM/S3/EKS安全, CSPM(Prowler), LocalStack实验
*   **学习时长**: 约7天（每天2-3小时）
*   **技能迁移**: 应用安全 → 云基础设施安全
*   **里程碑**: 云攻防实验室（IAM 提权与 S3 泄露）
*   **前置要求**: 完成阶段1-7

---

### ⚔️ 阶段八：攻防验证
> *以攻促防，验证防御。*

### [9️⃣ 红队演练 (Red Teaming)](./09-red-teaming/)
*   **重点**: 容器逃逸, K8s渗透测试, CDK工具链, OWASP K8s Top 10
*   **学习时长**: 约7天（每天2-3小时）
*   **技能迁移**: 渗透测试 → 云原生渗透
*   **里程碑**: 越狱（特权容器逃逸）+ Purple Team验证
*   **前置要求**: 完成阶段1-8

---

### 📋 阶段九：审计与合规
> *持续合规，证据留存。*

### [🔟 审计与合规 (Compliance)](./10-compliance/)
*   **重点**: CIS Benchmarks, kube-bench, 审计日志, 安全基线
*   **学习时长**: 约5天（每天2-3小时）
*   **技能迁移**: 安全审计 → 云原生合规
*   **里程碑**: 合规体检报告（CIS 90%+通过率）
*   **前置要求**: 完成阶段1-9

---

### 🎓 阶段十：职业发展
> *技术栈成型，认证加持，开源贡献。*

### [1️⃣1️⃣ 职业规划 (Career)](./11-career/)
*   **重点**: CKS认证(必考), AWS Security, 开源项目贡献, 技术写作
*   **学习时长**: 持续进行
*   **价值**: SDL → Cloud Security 职业转型完整指南
*   **里程碑**: 通过CKS认证 + 开源PR + 技术博客
*   **前置要求**: 完成阶段1-10

---

## 🎯 学习路径建议

### 入门路径（适合零基础）
```
阶段1 → 阶段2 → 阶段3 → 阶段4 → 阶段5
（约25天，掌握容器安全和DevSecOps基础）
```

### 进阶路径（适合有K8s基础）
```
阶段1(复习) → 阶段6 → 阶段7 → 阶段8
（约18天，掌握运行时安全和云平台安全）
```

### 完整路径（云安全专家）
```
阶段1-11全部完成
（约60-70天，每天2-3小时，达到CKS认证水平）
```

---

## 📚 推荐阅读

### 必读书籍
1. **《Container Security》** - Liz Rice
   - 深入理解容器底层（namespace, cgroups, capabilities）
   
2. **《Hacking Kubernetes》** - Andrew Martin & Michael Hausenblas
   - 攻防视角理解K8s安全
   
3. **《Kubernetes Security》** - O'Reilly
   - 系统性的安全加固指南

### 在线资源
- [CNCF Cloud Native Security Whitepaper](https://www.cncf.io/blog/2020/11/18/announcing-the-cloud-native-security-white-paper/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [OWASP Kubernetes Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Kubernetes_Security_Cheat_Sheet.html)

---

## 🤝 开源项目贡献路径

### 初级贡献（Good First Issue）
- **Trivy**: 为扫描器贡献检测规则
- **Kyverno**: 贡献策略模板
- **Falco**: 贡献检测规则

### 中级贡献（Feature Development）
- 开发kubectl插件（安全扫描/审计）
- 为Checkov添加新的IaC检测器
- 为CDK贡献exploit模块

### 高级贡献（Project Creation）
- 创建admission controller
- 开发安全态势可视化工具
- 构建自动化合规报告工具

---

## 🏆 学习成果验证

完成所有阶段后，应具备以下能力：

### 技术能力
- ✅ 深入理解容器和Kubernetes安全机制
- ✅ 能够设计和实施企业级云安全架构
- ✅ 掌握主流云安全工具的原理和使用
- ✅ 具备云原生渗透测试能力
- ✅ 能够进行安全合规审计

### 认证与产出
- ✅ 通过CKS认证
- ✅ 至少3个开源项目PR
- ✅ 撰写技术博客或演讲分享
- ✅ 建立个人云安全知识库

### 职业竞争力
- ✅ 具备Cloud Security Engineer岗位能力
- ✅ 理解DevSecOps完整流程
- ✅ SDL技能成功迁移到云安全领域
- ✅ 建立云原生安全思维体系

---

## ❓ 常见问题

### Q: 容器安全属于云安全吗？
**A: 绝对属于，而且是核心。**

云安全包含：
- **基础设施安全**: AWS IAM, VPC, S3权限 (CSPM)
- **容器/云原生安全**: K8s, Docker, Runtime (CWPP) ← 本路线重点
- **应用安全**: API Security, WAF (AppSec)

随着Cloud Native的普及，容器安全正成为云安全最重要的拼图。

### Q: SDL经验如何迁移到云安全？
**A: 大量技能可直接复用。**

参见上方"技能迁移对照表"，SDL的核心思维（安全左移、威胁建模、漏洞管理）完全适用于云原生场景，只是工具和对象不同。

### Q: 需要多长时间完成？
**A: 因人而异。**

- **全职学习**: 2-3个月
- **业余学习**: 4-6个月（每天2-3小时）
- **重点突击**: 选择关键阶段，1-2个月速成

### Q: 必须按顺序学习吗？
**A: 建议按顺序，但可灵活调整。**

阶段1是必须的基础，后续可根据兴趣和工作需求调整顺序。例如：
- 专注DevSecOps → 优先学习阶段3、4、5
- 专注运行时安全 → 优先学习阶段6、7
- 准备CKS认证 → 全部完成

---

**建议**: 按顺序学习，每完成一个阶段并在目录下归档成果后，再进行下一阶段。

**License**: 本项目采用 MIT 协议，欢迎fork、star和贡献。
