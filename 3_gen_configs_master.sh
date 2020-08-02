#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${DEBUG:-}" ]] || set -o xtrace

DEVICE_IPV4=$(ip route get 1 | awk '{print $(NF-2);exit}')
export DEVICE_IPV4="${DEVICE_IPV4}"
KUBECONFIG_LOCATION="/opt/local_kube/kubernetes/etc"
mkdir -p "${KUBECONFIG_LOCATION}"

KEYS="${KUBECONFIG_LOCATION}/encryption.keys"
mkdir -p "${KUBECONFIG_LOCATION}"

if [ ! -f "${KEYS}" ] || [[ -n "${ROTATE_KEYS:-}" ]]; then
  head -c 32 /dev/urandom | base64 | sudo tee -a "${KEYS}"
fi

i=0
ENCRYPTION_KEYS_BLOCK=""
while read -r line; do
  i=$((i + 1))
  ENCRYPTION_KEYS_BLOCK="
            - name: key${i}
              secret: ${line}${ENCRYPTION_KEYS_BLOCK}"
done <"${KEYS}"

ETCD_NAME=$(hostname)
export ETCD_NAME="${ETCD_NAME}"
ENCRYPTION_KEYS_BLOCK="${ENCRYPTION_KEYS_BLOCK}"
export ENCRYPTION_KEYS_BLOCK="${ENCRYPTION_KEYS_BLOCK}"

pushd etc/
for config in "encryption-config.yaml" "kube-scheduler.yaml"; do
  envsubst <"${config}" | sudo -E tee "${KUBECONFIG_LOCATION}"/"${config}"
done
popd

for service in 'etcd' 'kube-apiserver' 'kube-controller-manager' 'kube-scheduler'; do
  envsubst <systemd/"${service}".service | sudo -E tee /etc/systemd/system/"${service}".service
done

# vim: ts=2 sw=2 et
