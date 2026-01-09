#!/bin/bash
# 配置主机名和 hosts 文件

HOSTNAME=$1

if [ -z "$HOSTNAME" ]; then
    echo "使用方法: $0 <hostname>"
    exit 1
fi

echo "=== 配置主机名和 hosts 文件 ==="

# 1. 设置主机名
echo "1. 设置主机名为: $HOSTNAME"
 sudo -S hostnamectl set-hostname $HOSTNAME
hostname
echo "主机名设置完成"

# 2. 更新 /etc/hosts
echo -e "\n2. 更新 /etc/hosts..."
 sudo -S tee -a /etc/hosts > /dev/null <<EOF

# Kubernetes Cluster
192.168.0.200 master
192.168.0.201 worker-1
192.168.0.202 worker-2
EOF

echo "最新的 /etc/hosts:"
cat /etc/hosts | tail -5

echo -e "\n=== 配置完成 ==="
