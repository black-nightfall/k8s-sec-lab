# 🎓 阶段十一：职业规划 (Career Path)
**目标**: 技能全栈化，实现从应用安全到云原生的职场升维。

## 📜 核心证书 (必考)

### 🥇 CKS (Certified Kubernetes Security Specialist)
*   **含金量**: ⭐⭐⭐⭐⭐ (云原生安全硬通货)
*   **前提**: 必须先过 CKA (Administrator)。
*   **考点**: 几乎涵盖了我们之前练习的所有内容（NetworkPolicy, Trivy, Falco, AppArmor, RBAC, 审计）。
*   **核心价值**: 补齐基础设施层安全能力，实现真正的 DevSecOps 闭环。

## 📜 加分证书 (公有云方向)

云安全不仅仅是 K8s，更多时候是 AWS/Azure/GCP。

*   **AWS Certified Security – Specialty**: 证明你懂 AWS 的 IAM, VPC, KMS。
*   **CCSP (Cloud Security Professional)**: 偏理论和管理，适合未来向安全架构或合规领域深造。

## 💼 云原生安全职业演化

从传统安全（应用安全/网络运营）向云原生安全演进具有天然的复合优势：
*   **跨域能力**: 理解应用逻辑与底层基础设施的关联。
*   **技能扩展领域**: 深入探索底层网络 (CNI, iptables)、Linux 系统安全 (Capabilities, Syscall) 及集群自动化运维。

**职场竞争力 (Pro Tactics)**:
1.  **践行 DevSecOps**: 熟悉如何将安全检查工具深度**集成**到 CI/CD 流水线，实现风险的自动化治理。
2.  **构建纵深防御视野**: 从代码审计延伸至运行时监控（如 Falco），感知业务在完整生命周期内的异常行为。
3.  **实战项目积累**: 具备构建和优化云原生安全实验环境（如 Cilium, Hubble, NetworkPolicy 等）的实战经验。

---

## 📚 推荐阅读 (必读经典)

1.  **《Container Security》 (Liz Rice)**
    *   **理由**: 深入理解容器底层的必读书。Liz Rice (Cilium 母公司 Isovalent 核心成员) 将 namespace, cgroups, capabilities 讲得极为透彻，是补齐“云原生基础设施”底层逻辑的最佳途径。
2.  **《Hacking Kubernetes》 (Andrew Martin & Michael Hausenblas)**
    *   **理由**: 攻防视角的必读书。详细讲解了如何攻击 K8s 集群，非常适合 Red Teaming 阶段学习。
3.  **《Kubernetes Security》 (O'Reilly)**
    *   **理由**: 系统性的安全加固指南，适合作为案头参考书。

## 🤝 开源项目与社区 (提升影响力)

参与开源项目是展示技术能力和社区贡献的最佳途径。

### 1. 参与现有项目 (Contributor)
可以从 **Good First Issue** 开始：
*   **Trivy (Aqua Security)**: 学习扫描原理与容器漏洞分析。
*   **Kyverno (Nirmata)**: 尝试构建并贡献新的安全策略模板。
*   **CDK (Container Drill Kits)**: 研究并贡献新的 Exploit/防御模块。

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
*在此记录你的学习与备考计划...*
