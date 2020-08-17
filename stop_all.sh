#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${TRACE:-}" ]] || set -o xtrace

sudo systemctl daemon-reload

for service in 'containerd' 'kubelet' 'kube-proxy' 'node0-containerd' 'node0-kubelet' 'node0-kube-proxy'; do
  sudo systemctl stop "${service}" || true
  sudo systemctl disable "${service}" || true
done

for service in 'kube-apiserver' 'kube-controller-manager' 'kube-scheduler' 'etcd'; do
  sudo systemctl stop "${service}"
  sudo systemctl disable "${service}"
done

sudo systemctl daemon-reload

# vim: ts=2 sw=2 et
