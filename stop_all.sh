#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${DEBUG:-}" ]] || set -o xtrace

sudo systemctl daemon-reload

for service in 'containerd' 'kubelet' 'kube-proxy'; do
  sudo systemctl stop "${service}"
done

for service in 'kube-apiserver' 'kube-controller-manager' 'kube-scheduler'; do
  sudo systemctl stop "${service}"
done

sudo systemctl stop etcd

# vim: ts=2 sw=2 et
