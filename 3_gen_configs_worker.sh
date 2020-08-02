#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${DEBUG:-}" ]] || set -o xtrace

NODE_NO=0

WORKER_HOSTNAME=$(hostname)
DEVICE_IPV4=$(ip route get 1 | awk '{print $(NF-2);exit}')
POD_CIDR="10.222.${NODE_NO}.0/24"

export WORKER_HOSTNAME="${WORKER_HOSTNAME}"
export DEVICE_IPV4="${DEVICE_IPV4}"
export POD_CIDR="${POD_CIDR}"

KUBECONFIG_LOCATION="/opt/local_kube/kubernetes/etc"
KUBECONFIG_MANIFESTS_LOCATION="/opt/local_kube/kubernetes/manifests"

sudo mkdir -p "${KUBECONFIG_LOCATION}"
sudo mkdir -p "${KUBECONFIG_MANIFESTS_LOCATION}"

pushd etc/
for config in "containerd.toml" "kube-proxy-config.yaml" "kubelet-config.yaml"; do
  envsubst <"${config}" | sudo -E tee "${KUBECONFIG_LOCATION}"/"${config}"
done
popd

for service in 'kubelet' 'kube-proxy' 'containerd'; do
  envsubst <systemd/"${service}".service | sudo -E tee /etc/systemd/system/"${service}".service
done

# TODO: default /etc/containerd/config.toml used, not the one generated in /opt/local_kube/kubernetes/etc/
sudo mkdir -p /etc/containerd && /opt/local_kube/containerd/current/bin/containerd config default | sudo -E tee /etc/containerd/config.toml

# cp net.d/* /etc/cni/net.d/

sudo mkdir -p /etc/cni/net.d
for service in '10-bridge.conf' '99-loopback.conf'; do
  envsubst <net.d/"${service}" | sudo -E tee /etc/cni/net.d/"${service}"
done

# vim: ts=2 sw=2 et
