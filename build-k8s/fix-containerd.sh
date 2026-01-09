#!/bin/bash
# 修复 containerd 配置

echo "=== 修复 containerd 配置 ==="

# 1. 删除旧配置
echo "1. 删除旧配置..."
 sudo -S rm -f /etc/containerd/config.toml

# 2. 生成新的默认配置
echo "2. 生成新的默认配置..."
 sudo -S mkdir -p /etc/containerd
 sudo -S containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

# 3. 修改 SystemdCgroup 配置
echo "3. 修改 SystemdCgroup = true..."
 sudo -S sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# 4. 检查配置
echo "4. 检查 SystemdCgroup 配置:"
 sudo -S grep "SystemdCgroup" /etc/containerd/config.toml

# 5. 删除可能的 CNI 配置冲突
echo -e "\n5. 清理 CNI 配置..."
 sudo -S rm -rf /etc/cni/net.d/* 2>/dev/null || true

# 6. 重启 containerd
echo -e "\n6. 重启 containerd..."
 sudo -S systemctl daemon-reload
 sudo -S systemctl restart containerd
sleep 3

# 7. 检查服务状态
echo "7. 检查 containerd 状态:"
 sudo -S systemctl status containerd --no-pager | head -10

# 8. 测试 crictl
echo -e "\n8. 测试 crictl 连接:"
 sudo -S crictl info 2>&1 | head -20

echo -e "\n=== containerd 配置完成 ==="
