# 🎓 阶段十一：职业规划 (Career Path)
**目标**: 拿到入场券，证明你的实力。

## 📜 核心证书 (必考)

### 🥇 CKS (Certified Kubernetes Security Specialist)
*   **含金量**: ⭐⭐⭐⭐⭐ (云原生安全硬通货)
*   **前提**: 必须先过 CKA (Administrator)。
*   **考点**: 几乎涵盖了我们之前练习的所有内容（NetworkPolicy, Trivy, Falco, AppArmor, RBAC, 审计）。
*   **对于你**: 作为 SDL，这里主要是补齐 Infras 层的知识。

## 📜 加分证书 (公有云方向)

云安全不仅仅是 K8s，更多时候是 AWS/Azure/GCP。

*   **AWS Certified Security – Specialty**: 证明你懂 AWS 的 IAM, VPC, KMS。
*   **CCSP (Cloud Security Professional)**: 偏理论和管理，适合以后转架构或合规。

## 💼 SDL 转岗分析

你现在的 **SDL (Security Development Lifecycle)** 背景是巨大的优势！
*   **优势**: 你懂代码审阅 (Code Review)、威胁建模 (Threat Modeling)、漏洞原理。这些是运维出身的安全人员最缺的。
*   **劣势**: 可能对底层网络 (CNI, iptables)、Linux设置 (Capabilities, Syscall)、集群运维不够熟悉。

**面试策略**:
1.  **强调 DevSecOps**: 别只说你会修代码漏洞，要说你会把 Checkov/Trivy **集成** 到研发流程里，通过 Pipeline 自动化阻断风险。这是 SDL 的升维打击。
2.  **展示 Full-Stack 能力**: "我不仅能发现代码里的 SQL 注入，通过 Falco 监控，我还能发现已部署应用被 SQL 注入后的异常 Shell 连接。"
3.  **展示实战**: 我们做的这套学习环境（Cilium, Hubble, NetworkPolicy）就是最好的作品集。

---

## 📚 推荐阅读 (必读经典)

1.  **《Container Security》 (Liz Rice)**
    *   **理由**: 既然你想搞云安全，必须读 Liz Rice 的书。她是 Isovalent (Cilium 母公司) 的高管，这本书把 namespace, cgroups, linux capabilities 讲得非常透彻。你要补的 "Infra" 知识都在这里。
2.  **《Hacking Kubernetes》 (Andrew Martin & Michael Hausenblas)**
    *   **理由**: 攻防视角的必读书。详细讲解了如何攻击 K8s 集群，非常适合 Red Teaming 阶段学习。
3.  **《Kubernetes Security》 (O'Reilly)**
    *   **理由**: 系统性的安全加固指南，适合作为案头参考书。

## 🤝 开源项目与社区 (提升影响力)

作为 SDL，参与开源是你展示代码能力的最佳途径。

### 1. 参与现有项目 (Contributor)
不要一开始就想写大功能，从 **Good First Issue** 开始：
*   **Trivy (Aqua Security)**: Go 语言编写，逻辑清晰，适合看源码学习扫描原理。
*   **Kyverno (Nirmata)**: 策略引擎，你可以尝试提交一个新的 Policy 模板。
*   **CDK (Container Drill Kits)**: 渗透工具，你可以添加一个新的 Exploit 模块。

### 2. 造轮子 (Creator)
写一些“小而美”的安全工具，解决具体问题：
*   写一个 **Admission Controller Webhook**，自动拦截没有 `ResourceLimit` 的 Pod。
*   或者写一个 **Kubectl Plugin**，快速检查当前 namespace 下有哪些 Pod 是特权的 (`privileged: true`)。

## ❓ 常见问题 (FAQ)

### Q: 容器安全 (Container Security) 属于云安全 (Cloud Security) 吗？
**A: 绝对属于，而且是核心中的核心。**

*   **云安全 (Cloud Security)** 是一个大框，包含了：
    *   **基础设施安全**: AWS IAM, VPC, S3 权限 (CSPM)。
    *   **容器/云原生安全**: K8s, Docker, Runtime (CWPP)。
    *   **应用安全**: API Security, WAF (AppSec)。
*   随着 **Cloud Native** 的普及，**容器安全** 正在成为云安全最重要的一块拼图。掌握 K8s 安全，你通过 CKS 认证后，在云安全领域的竞争力会极大提升。

---
*在此目录下记录你的备考计划...*
