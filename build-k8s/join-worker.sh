#!/bin/bash
# Worker 节点加入集群

echo "=== Worker 节点加入集群 ==="

 sudo -S kubeadm join master:6443 \
  --token emkmv9.tk6nigk5m1w0yfbg \
  --discovery-token-ca-cert-hash sha256:9127dc03974a0f3c636849dd7d7ccf8fb6983633d20a4a487044f2b92d905054

if [ $? -eq 0 ]; then
    echo -e "\n=== 节点加入成功 ==="
else
    echo -e "\n=== 节点加入失败 ==="
    exit 1
fi
