#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# 0

# https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

# 6

BRIDGE=cnio0
IPTABLES_RULES=(
  "FORWARD -o ${BRIDGE} -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT"
  "FORWARD -i ${BRIDGE} ! -o ${BRIDGE} -j ACCEPT"
  "FORWARD -i ${BRIDGE} -o ${BRIDGE} -j ACCEPT"
)

for rule in "${IPTABLES_RULES[@]}"; do
  if ! eval "sudo iptables -C ${rule} > /dev/null"; then
    eval "sudo iptables -A ${rule}"
  fi
done

kubectl get pods --all-namespaces
kubectl get services --all-namespaces
kubectl get nodes
kubectl version
