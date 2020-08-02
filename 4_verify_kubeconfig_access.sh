#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${DEBUG:-}" ]] || set -o xtrace

# Not very secure :(
sudo chown "$(id -un)" /opt/local_kube/kubernetes/etc/*.kubeconfig
sudo chown "$(id -un)" /opt/local_kube/kubernetes/pki/*

CONFIG='admin'
KUBECONFIG=/opt/local_kube/kubernetes/etc/"${CONFIG}".kubeconfig
export KUBECONFIG="${KUBECONFIG}"
kubectl get pods
kubectl get nodes

CONFIG='kube-controller-manager'
KUBECONFIG=/opt/local_kube/kubernetes/etc/"${CONFIG}".kubeconfig
export KUBECONFIG="${KUBECONFIG}"
kubectl get pods
kubectl get nodes

CONFIG='kube-proxy'
KUBECONFIG=/opt/local_kube/kubernetes/etc/"${CONFIG}".kubeconfig
export KUBECONFIG="${KUBECONFIG}"
kubectl get endpoints
kubectl get services

CONFIG='kube-scheduler'
KUBECONFIG=/opt/local_kube/kubernetes/etc/"${CONFIG}".kubeconfig
export KUBECONFIG="${KUBECONFIG}"
kubectl get pods
kubectl get nodes

# Node must be discovered dynamically
CONFIG=$(hostname)
KUBECONFIG=/opt/local_kube/kubernetes/etc/"${CONFIG}".kubeconfig
export KUBECONFIG="${KUBECONFIG}"
kubectl get pods
kubectl get nodes

# vim: ts=2 sw=2 et
