#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${TRACE:-}" ]] || set -o xtrace

# Not very secure :(
sudo chown "$(id -un)" "${K8SFS_KUBECONFIG_LOCATION}"/*.kubeconfig
sudo chown "$(id -un)" "${K8SFS_CERT_LOCATION}"/*

CONFIG='admin'
KUBECONFIG="${K8SFS_KUBECONFIG_LOCATION}/${CONFIG}.kubeconfig"
export KUBECONFIG="${KUBECONFIG}"
kubectl get pods
kubectl get nodes

# CONFIG='kube-controller-manager'
# KUBECONFIG="${K8SFS_KUBECONFIG_LOCATION}/${CONFIG}.kubeconfig"
# export KUBECONFIG="${KUBECONFIG}"
# kubectl get pods
# kubectl get nodes

# CONFIG='kube-scheduler'
# KUBECONFIG="${K8SFS_KUBECONFIG_LOCATION}/${CONFIG}.kubeconfig"
# export KUBECONFIG="${KUBECONFIG}"
# kubectl get pods
# kubectl get nodes

# CONFIG='node0-kube-proxy'
# KUBECONFIG="${K8SFS_KUBECONFIG_LOCATION}/${CONFIG}.kubeconfig"
# export KUBECONFIG="${KUBECONFIG}"
# kubectl get endpoints
# kubectl get services

# Node must be discovered dynamically
CONFIG="${WORKER_HOSTNAME}"
KUBECONFIG="${K8SFS_KUBECONFIG_LOCATION}/${CONFIG}.kubeconfig"
export KUBECONFIG="${KUBECONFIG}"
kubectl get pods
kubectl get nodes

# vim: ts=2 sw=2 et
