#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${TRACE:-}" ]] || set -o xtrace

source 2_generate_certificates_functions.sh

gen_certs 'admin' 'admin' 'system:masters'
generate_kubeconfig admin "${MASTER_IP}" 'admin'

gen_certs "kube-proxy" 'system:kube-proxy' 'system:node-proxier'
generate_kubeconfig "kube-proxy" "${MASTER_IP}" 'system:kube-proxy'

gen_certs "${WORKER_HOSTNAME}" "system:node:${WORKER_HOSTNAME}" 'system:nodes' "${WORKER_HOSTNAME},${WORKER_IP}"
generate_kubeconfig "${WORKER_HOSTNAME}" "${MASTER_IP}" "system:node:${WORKER_HOSTNAME}"

sudo chown "$(id -un)" "${K8SFS_KUBECONFIG_LOCATION}/admin.kubeconfig"

# vim: ts=2 sw=2 et
