#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${DEBUG:-}" ]] || set -o xtrace

source 2_generate_certificates_functions.sh

SERVER_ADDR="${1:-$DEVICE_IPV4}"
WORKER_HOSTNAME=$(hostname)
gen_certs 'admin' 'admin' 'system:masters'
generate_kubeconfig admin "${SERVER_ADDR}" 'admin'

gen_certs 'kube-proxy' 'system:kube-proxy' 'system:node-proxier'
generate_kubeconfig kube-proxy "${SERVER_ADDR}" 'system:kube-proxy'

gen_certs "${WORKER_HOSTNAME}" "system:node:${WORKER_HOSTNAME}" 'system:nodes' "${WORKER_HOSTNAME},${DEVICE_IPV4}"
generate_kubeconfig "${WORKER_HOSTNAME}" "${SERVER_ADDR}" "system:node:${WORKER_HOSTNAME}"

# vim: ts=2 sw=2 et
