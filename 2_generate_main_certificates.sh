#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${DEBUG:-}" ]] || set -o xtrace

source 2_generate_certificates_functions.sh

gen_certs 'admin' 'admin' 'system:masters'
generate_kubeconfig admin "${DEVICE_IPV4}" 'admin'

gen_certs 'kube-controller-manager' 'system:kube-controller-manager' 'system:kube-controller-manager'
generate_kubeconfig kube-controller-manager "${DEVICE_IPV4}" 'system:kube-controller-manager'

gen_certs 'kube-scheduler' 'system:kube-scheduler' 'system:kube-scheduler'
generate_kubeconfig kube-scheduler "${DEVICE_IPV4}" 'system:kube-scheduler'

gen_certs 'kubernetes' 'kubernetes' 'Kubernetes' "$(hostname),${DEVICE_IPV4},10.32.0.1,127.0.0.1,127.0.1.1"
gen_certs 'service-account' 'service-accounts' 'Kubernetes'

# vim: ts=2 sw=2 et
