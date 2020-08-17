#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${TRACE:-}" ]] || set -o xtrace

source 2_generate_certificates_functions.sh

gen_certs 'admin' 'admin' 'system:masters'
generate_kubeconfig admin "${MASTER_IP}" 'admin'

gen_certs 'kube-controller-manager' 'system:kube-controller-manager' 'system:kube-controller-manager'
generate_kubeconfig kube-controller-manager "${MASTER_IP}" 'system:kube-controller-manager'

gen_certs 'kube-scheduler' 'system:kube-scheduler' 'system:kube-scheduler'
generate_kubeconfig kube-scheduler "${MASTER_IP}" 'system:kube-scheduler'

gen_certs "kube-proxy" 'system:kube-proxy' 'system:node-proxier'
generate_kubeconfig "kube-proxy" "${MASTER_IP}" 'system:kube-proxy'

gen_certs 'kubernetes' 'kubernetes' 'Kubernetes' "$(hostname),${MASTER_IP},10.32.0.1,127.0.0.1,127.0.1.1"
gen_certs 'service-account' 'service-accounts' 'Kubernetes'

gen_certs "proxy-client" 'aggregator' 'system:masters'  # TODO: ca for this cert only
# generate_kubeconfig "kube-proxy" "${MASTER_IP}" 'system:kube-proxy'

sudo chown "$(id -un)" "${K8SFS_KUBECONFIG_LOCATION}/admin.kubeconfig"

# vim: ts=2 sw=2 et
