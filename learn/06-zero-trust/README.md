# 🔒 阶段六：网络微隔离与零信任

**目标**: 实现Pod级别的网络访问控制，构建零信任网络架构。

> **🔄 技能迁移**: 网络防火墙 → 微服务零信任网络
> 
> 传统网络使用防火墙控制南北向流量，K8s中使用NetworkPolicy控制东西向流量（Pod间通信）。

> **💡 核心概念**:
> *   **NetworkPolicy**: K8s原生的网络策略，L3/L4层控制
> *   **零信任**: 默认拒绝所有流量，显式允许必要连接
> *   **Cilium L7 Policy**: 基于eBPF的L7协议过滤（HTTP/gRPC/Kafka）
> *   **Service Mesh**: Istio/Linkerd提供的mTLS和授权策略

---

## 📝 学习任务

### 第一部分：NetworkPolicy基础（2小时）

#### 默认拒绝策略

```yaml
# default-deny-all.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

#### 允许特定流量

```yaml
# allow-frontend-to-backend.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

#### DNS访问（必需）

```yaml
# allow-dns.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
```

### 第二部分：Cilium L7策略（3小时）

#### HTTP路径过滤

```yaml
# cilium-http-policy.yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-api-get-only
spec:
  endpointSelector:
    matchLabels:
      app: api-server
  ingress:
  - fromEndpoints:
    - matchLabels:
        app: frontend
    toPorts:
    - ports:
      - port: "80"
        protocol: TCP
      rules:
        http:
        - method: "GET"
          path: "/api/v1/.*"
```

#### DNS域名过滤

```yaml
# allow-specific-domains.yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-external-apis
spec:
  endpointSelector:
    matchLabels:
      app: backend
  egress:
  - toFQDNs:
    - matchName: "api.github.com"
    - matchPattern: "*.googleapis.com"
  - toEndpoints:
    - matchLabels:
        "k8s:io.kubernetes.pod.namespace": kube-system
        "k8s:k8s-app": kube-dns
    toPorts:
    - ports:
      - port: "53"
        protocol: ANY
```

### 第三部分：Service Mesh安全（可选，2小时）

#### Istio授权策略

```yaml
# istio-authz-policy.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: frontend-authz
  namespace: production
spec:
  selector:
    matchLabels:
      app: backend
  action: ALLOW
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/production/sa/frontend"]
    to:
    - operation:
        methods: ["GET", "POST"]
        paths: ["/api/*"]
```

---

## 🏆 里程碑项目：微服务零信任网络

**任务**: 为3层微服务应用（前端→API→数据库）实现完整的零信任网络策略。

### 架构

```
Frontend (port 80) → API (port 8080) → Database (port 5432)
                      ↓
                  External API (https://api.external.com)
```

### 策略实施

1. ✅ 默认拒绝所有流量
2. ✅ Frontend只能访问API的GET/POST
3. ✅ API只能访问数据库5432端口
4. ✅ API只能访问指定外部域名
5. ✅ 所有Pod都能访问DNS
6. ✅ 在Hubble中验证策略有效性

### 验证方法

```bash
# 部署应用
kubectl apply -f microservices-app.yaml

# 应用NetworkPolicies
kubectl apply -f network-policies/

# 测试合法访问（应该成功）
kubectl exec -it frontend-pod -- curl http://api-service:8080/api/users

# 测试非法访问（应该失败）
kubectl exec -it frontend-pod -- curl http://database:5432

# 在Hubble UI查看
cilium hubble ui
# 应该看到：绿色箭头（允许）和红色箭头（拒绝）
```

---

## 🔗 与SDL的关联

| SDL实践 | 网络安全对应 |
|---------|------------|
| 最小权限 | 默认拒绝策略 |
| 白名单机制 | 显式allow规则 |
| 分层防御 | L3/L4/L7多层控制 |
| 访问控制矩阵 | NetworkPolicy矩阵 |

*在此目录下创建NetworkPolicy库和测试脚本。*
