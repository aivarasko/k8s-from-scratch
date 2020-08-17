#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${TRACE:-}" ]] || set -o xtrace

sudo chown "$(id -un)" "${K8SFS_KUBECONFIG_LOCATION}/admin.kubeconfig"

# Delete if service account certs has been changed
kubectl delete -f manifests/ || true

kubectl apply -f manifests/kubelet-rbac.yaml
# kubectl apply -f https://docs.projectcalico.org/v3.10/manifests/calico.yaml
sed 's/CLUSTER_DNS_IP/10.32.0.10/g' manifests/coredns.yaml | kubectl apply -n kube-system -f -
kubectl -n kube-system wait --for condition=available deployment -l k8s-app=kube-dns --timeout=100s

# Comment for now, blocks namespace remove
# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.7/components.yaml
# kubectl -n kube-system wait --for condition=available deployment -l k8s-app=metrics-server --timeout=100s

# 2020-07-19 06:19:39.767 [FATAL][1144] int_dataplane.go 1032: Kernel's RPF check is set to 'loose'.  This would allow endpoints to spoof their IP address.  Calico requires net.ipv4.conf.all.rp_filter to be set to 0 or 1. If you require loose RPF and you are not concerned about spoofing, this check can be disabled by setting the IgnoreLooseRPF configuration parameter to 'true'.
# kubectl apply -f https://docs.projectcalico.org/v3.10/manifests/calico.yaml
# kubectl -n kube-system set env daemonset/calico-node FELIX_IGNORELOOSERPF=true

# vim: ts=2 sw=2 et
