# ☁️ 阶段八：公有云安全

**目标**: 掌握AWS等公有云平台的安全配置，理解云原生与云基础设施安全的结合。

> **🔄 技能迁移**: 应用安全 → 云基础设施安全
> 
> 从应用代码层扩展到云基础设施层（IAM、VPC、S3等），安全边界从应用扩展到整个云环境。

> **💡 核心概念**:
> *   **IAM**: 身份与访问管理，最小权限原则
> *   **CSPM**: Cloud Security Posture Management，云安全态势管理
> *   **IRSA**: IAM Roles for Service Accounts，K8s Pod的云权限
> *   **LocalStack**: 本地模拟AWS服务，用于学习和测试

---

## 📝 学习任务

### 第一部分：LocalStack环境搭建（1小时）

#### 安装LocalStack

```bash
# 使用Docker Compose
cat > docker-compose.yml <<EOF
version: '3.8'
services:
  localstack:
    image: localstack/localstack:latest
    ports:
      - "4566:4566"
    environment:
      - SERVICES=s3,iam,sts,secretsmanager,kms
      - DEBUG=1
      - DATA_DIR=/tmp/localstack/data
    volumes:
      - "./localstack:/tmp/localstack"
      - "/var/run/docker.sock:/var/run/docker.sock"
EOF

docker-compose up -d

# 配置AWS CLI
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
aws --endpoint-url=http://localhost:4566 s3 ls
```

### 第二部分：AWS安全基础（4小时）

#### IAM最佳实践

```json
// 最小权限策略示例
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-app-bucket",
        "arn:aws:s3:::my-app-bucket/*"
      ],
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": "10.0.0.0/8"
        }
      }
    }
  ]
}
```

#### S3安全配置

```bash
# 阻止公共访问
aws s3api put-public-access-block \
  --bucket my-bucket \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
  --endpoint-url=http://localhost:4566

# 启用加密
aws s3api put-bucket-encryption \
  --bucket my-bucket \
  --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' \
  --endpoint-url=http://localhost:4566

# 启用版本控制
aws s3api put-bucket-versioning \
  --bucket my-bucket \
  --versioning-configuration Status=Enabled \
  --endpoint-url=http://localhost:4566
```

### 第三部分：CSPM实践（2小时）

#### Prowler扫描

```bash
# 安装Prowler
pip3 install prowler

# 扫描LocalStack
prowler aws --profile localstack \
  --services s3 iam \
  --output-formats html json

# 查看报告
open output/prowler-output-*.html
```

#### 常见配置错误

| 问题 | 风险 | 修复 |
|------|------|------|
| S3 bucket公开 | 数据泄露 | 启用BlockPublicAccess |
| IAM用户有管理员权限 | 权限过大 | 应用最小权限 |
| 未启用CloudTrail | 无审计日志 | 启用CloudTrail |
| 未加密EBS卷 | 数据泄露 | 启用默认加密 |
| SecurityGroup开放0.0.0.0/0的22端口 | SSH暴露 | 限制源IP |

### 第四部分：EKS安全（3小时）

#### IRSA配置

```yaml
# service-account.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app-sa
  namespace: production
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/my-app-role
---
# pod使用SA
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  namespace: production
spec:
  serviceAccountName: my-app-sa
  containers:
  - name: app
    image: myapp:1.0
    env:
    - name: AWS_ROLE_ARN
      value: "arn:aws:iam::123456789:role/my-app-role"
    - name: AWS_WEB_IDENTITY_TOKEN_FILE
      value: "/var/run/secrets/eks.amazonaws.com/serviceaccount/token"
```

#### Pod Security Group

```bash
# 为特定Pod应用安全组
kubectl annotate pod my-app \
  vpc.amazonaws.com/pod-eni='[{"securityGroups":["sg-12345678"]}]'
```

---

## 🏆 里程碑项目：云安全态势评估

**任务**: 使用LocalStack模拟AWS环境，植入10+安全配置错误，使用Prowler扫描并修复。

### 故意的错误配置

1. S3 bucket公开且无加密
2. IAM用户有AdministratorAccess
3. 未启用MFA
4. SecurityGroup开放所有端口
5. 未启用CloudTrail
6. S3未启用版本控制
7. KMS密钥未轮换
8. IAM密钥超过90天未轮换
9. 未启用GuardDuty
10. Lambda函数有过大权限

### 验证

```bash
# 运行Prowler
prowler aws --checks s3_bucket_public_access,iam_user_hw_mfa_enabled

# 应该检测出所有问题
# 修复后重新扫描，通过率应达到90%+
```

---

## 🔗 与SDL的关联

| SDL实践 | 云安全对应 |
|---------|-----------|
| 最小权限 | IAM策略最小化 |
| 数据加密 | S3/EBS加密 |
| 审计日志 | CloudTrail |
| 安全基线 | CIS AWS Foundations |
| 配置审查 | CSPM工具 |

*在此目录下创建Terraform配置和Prowler检查脚本。*
