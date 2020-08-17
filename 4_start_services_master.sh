#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${TRACE:-}" ]] || set -o xtrace

sudo systemctl daemon-reload
for service in 'etcd' 'kube-apiserver' 'kube-controller-manager' 'kube-scheduler' 'kube-proxy'; do
  sudo systemctl restart "${service}"
done

if timeout 20 sh -c "while sleep 3 ; do echo 'waiting for master'; curl --silent --show-error --fail -o /dev/null --cacert ${K8SFS_CERT_LOCATION}/ca.crt https://${MASTER_IP}:6443/version && break; done"; then
  echo "service is up"
else
  exit 1
fi

# vim: ts=2 sw=2 et
