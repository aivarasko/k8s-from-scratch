#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${TRACE:-}" ]] || set -o xtrace

sudo swapoff -a

sudo apt update -y
sudo apt install -y socat conntrack ipset
sudo apt install -y gcc make libbtrfs-dev pkg-config libseccomp-dev
sudo apt install -y golang-cfssl

sudo mkdir -p "${K8SFS_CERT_LOCATION}" "${K8SFS_TARGET_LOCATION}" "${K8SFS_KUBECONFIG_LOCATION}" "${K8SFS_MANIFESTS_LOCATION}"

# vim: ts=2 sw=2 et
