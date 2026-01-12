# 🛡️ 阶段七：运行时威胁检测

**目标**: 使用Falco检测容器运行时的异常行为，构建实时威胁检测体系。

> **🔄 技能迁移**: RASP/IAST → Runtime Container Security
> 
> SDL中的RASP在应用层检测攻击，Falco在系统调用层检测异常，范围更广，能检测容器逃逸等基础设施层攻击。

> **💡 核心概念**:
> *   **Falco**: 云原生运行时安全工具，基于eBPF监控系统调用
> *   **规则引擎**: 使用声明式规则定义异常行为
> *   **MITRE ATT&CK**: 容器攻击战术和技术框架
> *   **事件响应**: 检测到威胁后的自动化响应

---

## 📝 学习任务

### 第一部分：Falco部署与基础（2小时）

#### 安装Falco

```bash
# 使用Helm安装
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

helm install falco falcosecurity/falco \
  --namespace falco --create-namespace \
  --set ebpf.enabled=true

# 查看日志
kubectl logs -n falco -l app.kubernetes.io/name=falco -f
```

#### 触发基础告警

```bash
# 场景1: 在容器内读取敏感文件
kubectl exec -it test-pod -- cat /etc/shadow
# Falco告警: Sensitive file opened for reading

# 场景2: 在容器内执行shell
kubectl exec -it test-pod -- /bin/bash
# Falco告警: Terminal shell spawned in container

# 场景3: 写入二进制目录
kubectl exec -it test-pod -- touch /bin/malware
# Falco告警: Write below binary dir
```

### 第二部分：自定义规则（3小时）

#### Falco规则语法

```yaml
# custom-rules.yaml
- rule: Suspicious Network Activity
  desc: Detect outbound connections to unusual ports
  condition: >
    outbound and 
    fd.sport != 443 and fd.sport != 80 and 
    fd.sport != 53 and
    container.id != host
  output: >
    Outbound connection to unusual port 
    (user=%user.name container=%container.name 
    port=%fd.sport ip=%fd.rip)
  priority: WARNING
  tags: [network, container]

- rule: Package Management in Container
  desc: Detect package installation in running container
  condition: >
    spawned_process and container and
    (proc.name in (apt, apt-get, yum, dnf, apk, pip, npm))
  output: >
    Package manager executed in container
    (user=%user.name container=%container.name 
    command=%proc.cmdline)
  priority: ERROR
  tags: [process, container]

- rule: Cryptocurrency Mining
  desc: Detect cryptocurrency mining activity
  condition: >
    spawned_process and
    (proc.name in (xmrig, minerd, cpuminer) or
     proc.cmdline contains "stratum+tcp")
  output: >
    Cryptocurrency mining detected
    (user=%user.name command=%proc.cmdline)
  priority: CRITICAL
  tags: [malware]
```

### 第三部分：MITRE ATT&CK映射（2小时）

#### 容器攻击链

| 阶段 | 技术 | Falco规则 |
|------|------|-----------|
| Initial Access | 暴露的容器API | Detect exposed Docker socket |
| Execution | 容器内执行shell | Terminal shell in container |
| Persistence | 修改启动脚本 | Modify shell configuration |
| Privilege Escalation | 容器逃逸 | Privileged container spawned |
| Defense Evasion | 删除日志 | Log files were tampered |
| Discovery | 网络扫描 | Network tool launched in container |
| Lateral Movement | kubectl exec | Kubectl executed in container |
| Exfiltration | 异常网络传输 | Outbound connection to suspicious IP |

### 第四部分：自动化响应（2小时）

#### Falcosidekick集成

```yaml
# falcosidekick-config.yaml
customoutputs:
  slack:
    webhookurl: "https://hooks.slack.com/services/XXX"
    minimumpriority: "warning"
  
  elasticsearch:
    hostport: "http://elasticsearch:9200"
    index: "falco"
  
  webhook:
    address: "http://response-handler:8080/alert"
```

#### 自动化响应示例

```python
# response-handler.py
from flask import Flask, request
import kubernetes

app = Flask(__name__)

@app.route('/alert', methods=['POST'])
def handle_alert():
    alert = request.json
    
    if alert['priority'] == 'CRITICAL':
        # 隔离Pod
        isolate_pod(alert['output_fields']['container.name'])
        
        # 通知团队
        notify_security_team(alert)
    
    return 'OK'

def isolate_pod(container_name):
    # 应用拒绝所有流量的NetworkPolicy
    policy = {
        "apiVersion": "networking.k8s.io/v1",
        "kind": "NetworkPolicy",
        "spec": {
            "podSelector": {"matchLabels": {"container": container_name}},
            "policyTypes": ["Ingress", "Egress"]
        }
    }
    # Apply policy...
```

---

## 🏆 里程碑项目：完整威胁检测与响应

**任务**: 检测恶意文件写入并自动隔离容器。

### 场景

1. 攻击者通过漏洞在容器内写入恶意脚本
2. Falco检测到异常文件操作
3. 自动触发响应：隔离Pod + 告警

### 实施

```yaml
# malware-detection.yaml
- rule: Malicious File Written
  desc: Detect malicious file creation
  condition: >
    open_write and container and
    (fd.name glob "/tmp/*.sh" or
     fd.name glob "/tmp/*.py") and
    proc.name != "dpkg"
  output: >
    Malicious file written
    (user=%user.name file=%fd.name container=%container.name)
  priority: CRITICAL
  tags: [filesystem, malware]
```

### 验证

```bash
# 模拟攻击
kubectl exec -it victim-pod -- sh -c 'echo "evil" > /tmp/malware.sh'

# 检查Falco告警
kubectl logs -n falco -l app.kubernetes.io/name=falco | grep "Malicious file"

# 验证Pod被隔离
kubectl get networkpolicy
kubectl describe pod victim-pod
```

---

## 🔗 与SDL的关联

| SDL实践 | 运行时安全对应 |
|---------|--------------|
| RASP | Falco运行时检测 |
| SIEM集成 | Falcosidekick输出 |
| 事件响应 | 自动化隔离 |
| 威胁建模 | MITRE ATT&CK映射 |
| 安全监控 | 持续行为分析 |

*在此目录下创建自定义规则库和响应脚本。*
