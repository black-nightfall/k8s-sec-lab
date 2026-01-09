# 🧬 阶段二：容器安全与硬化 (Container Hardening)
**目标**: 深入原子层面。防止单个容器被攻破后，攻击者能“逃”到宿主机。

> **👶 小白概念站**:
> *   **Capabilities**: Linux 权限的细分。`root` 权限太大了，我们把它切碎，只给容器最少的几片。
> *   **Seccomp**: 限制程序能调用哪些系统函数（System Calls）。
> *   **AppArmor/SELinux**: 限制程序能读写哪些文件。

## 📝 学习任务

* [ ] **权限修剪 (Capabilities)**
  * **实验**: 启动一个容器，使用 `capsh --print` 查看默认拥有的权限。
  * **加固**: 使用 `securityContext.capabilities.drop: ["ALL"]` 启动容器，观察区别。
* [ ] **系统调用过滤 (Seccomp)**
  * **概念**: 绝大多数 Web 应用只需要 `read`, `write`, `socket` 等几十个系统调用，不需要 `reboot` 或 `swapon`。
  * **练习**: 为容器配置 `RuntimeDefault` seccomp profile。
* [ ] **非 Root 运行 (RunAsNonRoot)**
  * **原则**: **永远不要以 Root 身份运行业务容器**。
  * **练习**: 修改 Dockerfile，添加 `USER 1000`，并在 K8s 中强制 `runAsNonRoot: true`。

## 🏆 里程碑练习：铁桶阵

**任务**: 部署一个极致硬化的 Nginx 容器。
1.  **Drop ALL Capabilities**: 移除所有默认权限，只显式添加 `NET_BIND_SERVICE` (如果需要绑定 <1024 端口)。
2.  **Read-Only Root Filesystem**: 根文件系统设为只读。
3.  **RunAsUser**: 使用 UID 101 (Nginx)。
4.  **Seccomp**: 启用 RuntimeDefault。

**✅ 通关标准**:
1. 容器能正常响应 HTTP 请求。
2. 进入容器 (`kubectl exec`) 尝试安装软件 (`apt update`) 或修改文件 (`touch /tmp/test`) 必须**全部失败**。

---
*在此目录下创建你的练习笔记...*
