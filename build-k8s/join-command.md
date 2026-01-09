# Kubernetes 集群 Join 命令

## Worker 节点加入命令

```bash
sudo kubeadm join master:6443 --token emkmv9.tk6nigk5m1w0yfbg \
  --discovery-token-ca-cert-hash sha256:9127dc03974a0f3c636849dd7d7ccf8fb6983633d20a4a487044f2b92d905054
```

## Control Plane 节点加入命令（如需添加更多 master 节点）

```bash
sudo kubeadm join master:6443 --token emkmv9.tk6nigk5m1w0yfbg \
  --discovery-token-ca-cert-hash sha256:9127dc03974a0f3c636849dd7d7ccf8fb6983633d20a4a487044f2b92d905054 \
  --control-plane
```

## Token 信息
- Token: emkmv9.tk6nigk5m1w0yfbg
- CA Cert Hash: sha256:9127dc03974a0f3c636849dd7d7ccf8fb6983633d20a4a487044f2b92d905054
- 控制平面地址: master:6443 (192.168.0.200:6443)

## 注意事项
- Token 默认有效期为 24 小时
- 如果 token 过期，可以在 master 节点上运行 `kubeadm token create --print-join-command` 生成新的 join 命令
