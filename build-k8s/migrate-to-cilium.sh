#!/bin/bash
set -e

# Master Node Script (Part 2: Helm & Cilium)
PASSWORD=""

# 1. INSTALL Helm (Manual method to handle sudo)
echo "=== Installing Helm ==="
if ! command -v helm &> /dev/null; then
    echo "Downloading Helm..."
    wget -q https://get.helm.sh/helm-v3.14.4-linux-arm64.tar.gz
    tar -zxvf helm-v3.14.4-linux-arm64.tar.gz > /dev/null
    echo "Installing binary..."
    echo "$PASSWORD" | sudo -S mv linux-arm64/helm /usr/local/bin/helm
    rm -rf linux-arm64 helm-v3.14.4-linux-arm64.tar.gz
    echo "Helm installed successfully."
else
    echo "Helm already installed."
fi

# 2. INSTALL Cilium
echo "=== Installing Cilium ==="
helm repo add cilium https://helm.cilium.io/
helm repo update
# Check if already installed
if helm list -n kube-system | grep -q cilium; then
    echo "Cilium already installed, upgrading..."
    helm upgrade cilium cilium/cilium --version 1.14.5 \
       --namespace kube-system \
       --set ipam.mode=kubernetes \
       --set hubble.enabled=true \
       --set hubble.relay.enabled=true \
       --set hubble.ui.enabled=true
else
    echo "Installing Cilium chart..."
    helm install cilium cilium/cilium --version 1.14.5 \
       --namespace kube-system \
       --set ipam.mode=kubernetes \
       --set hubble.enabled=true \
       --set hubble.relay.enabled=true \
       --set hubble.ui.enabled=true
fi

# 3. RESTART Pods to pick up Cilium CNI
echo "=== Restarting Pods ==="
kubectl -n kube-system rollout restart deployment/coredns
kubectl -n kubernetes-dashboard rollout restart deployment/kubernetes-dashboard || true

# 4. WAIT for Cilium
echo "=== Waiting for API Server to stabilize ==="
# Cilium installation might briefly disrupt network
sleep 10
kubectl get pods -n kube-system -l k8s-app=cilium

echo "=== Migration Complete! ==="
