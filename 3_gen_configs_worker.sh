#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${TRACE:-}" ]] || set -o xtrace

POD_CIDR="10.222.${WORKER_NO}.0/24"
export POD_CIDR="${POD_CIDR}"

pushd etc/
for config in "containerd.toml" "kube-proxy-config.yaml" "kubelet-config.yaml"; do
  envsubst <"${config}" | sudo -E tee "${K8SFS_KUBECONFIG_LOCATION}"/"${config}"
done
popd

for service in 'kubelet' 'kube-proxy' 'containerd'; do
  envsubst <systemd/"${service}".service | sudo -E tee /etc/systemd/system/"${service}".service
done

# TODO: default /etc/containerd/config.toml used, not the one generated in ${K8SFS_TARGET_LOCATION}/etc/
sudo mkdir -p /etc/containerd && containerd config default | sudo -E tee /etc/containerd/config.toml

# cp net.d/* /etc/cni/net.d/

sudo mkdir -p "${K8SFS_KUBECONFIG_LOCATION}/net.d"
for service in '10-bridge.conf' '99-loopback.conf'; do
  envsubst <net.d/"${service}" | sudo -E tee "${K8SFS_KUBECONFIG_LOCATION}/net.d/${service}"
done

# vim: ts=2 sw=2 et
