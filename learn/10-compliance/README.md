# 📋 阶段十：审计与合规

**目标**: 建立持续合规体系，通过CIS Benchmark等标准验证集群安全性。

> **🔄 技能迁移**: SDL审计 → 云原生合规审计
> 
> SDL中的安全审计关注代码和应用，云原生审计扩展到基础设施配置、K8s集群安全、云资源合规等。

> **💡 核心概念**:
> *   **CIS Benchmark**: Center for Internet Security发布的安全配置基准
> *   **kube-bench**: 自动化CIS Kubernetes Benchmark检查
> *   **审计日志**: K8s API Server审计日志，记录所有API操作
> *   **合规框架**: SOC2、ISO27001、PCI-DSS等

---

## 📝 学习任务

### 第一部分：CIS Kubernetes Benchmark（3小时）

#### kube-bench安装与使用

```bash
# 在K8s集群中运行
kubectl apply -f https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job.yaml

# 查看结果
kubectl logs job/kube-bench

# 本地运行
docker run --rm -v `pwd`:/host aquasec/kube-bench:latest \
  --config-dir /host/cfg \
  --config /host/cfg/config.yaml
```

#### CIS检查项解读

**Control Plane Components**:
- [PASS] 1.2.1 Ensure that the --anonymous-auth argument is set to false  
- [FAIL] 1.2.6 Ensure that the --kubelet-certificate-authority argument is set
- [WARN] 1.2.12 Ensure that the admission control plugin AlwaysPullImages is set

**Worker Nodes**:
- [PASS] 4.2.1 Ensure that the kubelet service file permissions are set to 644
- [FAIL] 4.2.6 Ensure that the --protect-kernel-defaults argument is set to true

#### 修复FAIL项

```bash
# 示例：修复API Server配置
# 编辑 /etc/kubernetes/manifests/kube-apiserver.yaml
--kubelet-certificate-authority=/etc/kubernetes/pki/ca.crt

# 修复kubelet配置
# 编辑 /var/lib/kubelet/config.yaml
protectKernelDefaults: true

# 重启kubelet
systemctl restart kubelet
```

### 第二部分：审计日志分析（2小时）

#### 启用审计日志

```yaml
# audit-policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
# 记录Secret的创建/删除
- level: RequestResponse
  resources:
  - group: ""
    resources: ["secrets"]
  verbs: ["create", "delete", "patch"]

# 记录所有创建/删除Pod的操作
- level: Metadata
  resources:
  - group: ""
    resources: ["pods"]
  verbs: ["create", "delete"]

# 记录exec/attach操作
- level: Request
  verbs: ["create"]
  resources:
  - group: ""
    resources: ["pods/exec", "pods/attach"]
```

#### 分析审计日志

```bash
# 查找创建特权Pod的操作
cat /var/log/kubernetes/audit.log | \
  jq 'select(.objectRef.resource=="pods" and .requestObject.spec.containers[].securityContext.privileged==true)'

# 查找Secret访问
cat /var/log/kubernetes/audit.log | \
  jq 'select(.objectRef.resource=="secrets")'

# 查找异常API调用
cat /var/log/kubernetes/audit.log | \
  jq 'select(.responseStatus.code>=400)'
```

### 第三部分：合规框架映射（2小时)

#### SOC2合规示例

| SOC2控制 | K8s实施 | 验证方法 |
|----------|---------|---------|
| CC6.1 逻辑与物理访问控制 | RBAC + NetworkPolicy | kube-bench + 审计日志 |
| CC6.6 加密数据 | etcd encryption + TLS | 配置检查 |
| CC6.7 系统监控 | Falco + Prometheus | 告警覆盖率 |
| CC7.2 系统组件监控 | kube-state-metrics | 指标收集 |

#### PCI-DSS合规示例

**要求3.4**: 加密传输中的持卡人数据
- **实施**: Ingress TLS + Service Mesh mTLS
- **验证**: 网络抓包验证加密

**要求8.7**: 限制对数据库的访问
- **实施**: NetworkPolicy + RBAC
- **验证**: 渗透测试验证隔离

### 第四部分：持续合规（2小时）

#### 自动化合规检查

```yaml
# .github/workflows/compliance-check.yml
name: Compliance Check

on:
  schedule:
    - cron: '0 0 * * 0'  # 每周日运行

jobs:
  cis-benchmark:
    runs-on: ubuntu-latest
    steps:
    - name: Run kube-bench
      run: |
        kubectl apply -f kube-bench-job.yaml
        kubectl wait --for=condition=complete job/kube-bench
        kubectl logs job/kube-bench > cis-report.txt
    
    - name: Parse results
      run: |
        FAIL_COUNT=$(grep -c "\[FAIL\]" cis-report.txt)
        if [ $FAIL_COUNT -gt 5 ]; then
          echo "Too many failures: $FAIL_COUNT"
          exit 1
        fi
    
    - name: Upload report
      uses: actions/upload-artifact@v3
      with:
        name: cis-report
        path: cis-report.txt
```

---

## 🏆 里程碑项目：完整合规报告

**任务**: 生成通过率90%+的CIS Kubernetes Benchmark合规报告。

### 实施步骤

1. **基线评估**: 运行kube-bench记录当前状态
2. **修复计划**: 对所有FAIL项制定修复计划
3. **分批修复**: 按优先级修复（先修复容易且影响大的）
4. **重新评估**: 验证修复效果
5. **文档化**: 记录所有修复操作和例外情况

### 报告模板

```markdown
# CIS Kubernetes Benchmark合规报告

## 执行摘要
- 评估日期: 2024-01-15
- 集群版本: v1.28.0
- 总检查项: 124
- 通过: 112 (90.3%)
- 失败: 8 (6.5%)
- 警告: 4 (3.2%)

## Control Plane评估结果
### 1.1 Master Node Configuration Files
- 1.1.1 [PASS] API server pod specification file permissions
- 1.1.2 [PASS] API server pod specification file ownership
...

### 1.2 API Server
- 1.2.1 [PASS] --anonymous-auth 已禁用
- 1.2.6 [FAIL] --kubelet-certificate-authority未设置
  - **修复计划**: Q1 2024实施
  - **风险评估**: Medium
  - **临时缓解**: 使用NetworkPolicy限制kubelet访问

## 合规路线图
- Q1 2024: 修复所有HIGH风险项
- Q2 2024: 修复MEDIUM风险项
- Q3 2024: 达成95%通过率目标
```

---

## 🔗 与SDL的关联

| SDL实践 | 合规审计对应 |
|---------|------------|
| 安全基线 | CIS Benchmark |
| 审计日志 | K8s Audit Log |
| 合规评估 | kube-bench自动化 |
| 证据收集 | 审计报告 |
| 持续改进 | 定期合规检查 |

*在此目录下创建审计日志分析脚本和合规报告模板。*
