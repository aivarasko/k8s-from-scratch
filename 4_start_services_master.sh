#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${DEBUG:-}" ]] || set -o xtrace

DEVICE_IPV4=$(ip route get 1 | awk '{print $(NF-2);exit}')

sudo swapoff -a

sudo systemctl daemon-reload
for service in 'etcd' 'kube-apiserver' 'kube-controller-manager' 'kube-scheduler'; do
  sudo systemctl restart "${service}"
done
# for service in 'etcd' 'kube-apiserver' 'kube-controller-manager' 'kube-scheduler'
# do
#   systemctl status "${service}"
# done

if timeout 20 sh -c "while sleep 3 ; do echo 'waiting for master'; curl --silent --show-error --fail -o /dev/null --cacert /opt/local_kube/kubernetes/pki/ca.crt https://${DEVICE_IPV4}:6443/version && break; done"; then
  echo "service is up"
else
  exit 1
fi

# vim: ts=2 sw=2 et
