#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${DEBUG:-}" ]] || set -o xtrace

# kubectl create secret generic secret1 -n default --from-literal=mykey=mydata || true
# ETCDCTL_API=3 etcdctl get /registry/secrets/default/secret1
# DEVICE='ens5'
# DEVICE_IPV4=$(ifconfig "${DEVICE}" | grep 'inet ' | awk '{print $2}')
# export KUBECONFIG="/opt/local_kube/kubernetes/etc/admin.kubeconfig"

DEVICE_IPV4=$(ip route get 1 | awk '{print $(NF-2);exit}')

kubectl delete namespace smoke || true

# Test etcd status
ETCDCTL_API=3 etcdctl member list --endpoints=https://"${DEVICE_IPV4}":2379 --cacert=/opt/local_kube/kubernetes/pki/ca.crt --cert=/opt/local_kube/kubernetes/pki/kubernetes.crt --key=/opt/local_kube/kubernetes/pki/kubernetes.key | grep "started"

# Test secrets encryption
kubectl create namespace smoke
kubectl -n smoke create secret generic smoke-secret --from-literal="mysecret=mydata"
ETCDCTL_API=3 etcdctl get --endpoints=https://"${DEVICE_IPV4}":2379 --cacert=/opt/local_kube/kubernetes/pki/ca.crt --cert=/opt/local_kube/kubernetes/pki/kubernetes.crt --key=/opt/local_kube/kubernetes/pki/kubernetes.key /registry/secrets/smoke/smoke-secret | grep "aescbc"

ETCDCTL_API=3 etcdctl get --endpoints=https://"${DEVICE_IPV4}":2379 --cacert=/opt/local_kube/kubernetes/pki/ca.crt --cert=/opt/local_kube/kubernetes/pki/kubernetes.crt --key=/opt/local_kube/kubernetes/pki/kubernetes.key /registry/secrets/smoke/smoke-secret

# Test Deployment, Expose
kubectl -n smoke create deployment nginx --image=nginx
kubectl -n smoke get pods -l app=nginx
kubectl -n smoke wait pods -l app=nginx --for=condition=Ready --timeout=100s
kubectl -n smoke logs -l app=nginx
kubectl -n smoke exec deployment/nginx -- nginx -v 2>&1 | grep "nginx version"
kubectl -n smoke expose deployment nginx --port 80

POD_IP=$(kubectl -n smoke get pods -l app=nginx -o wide --no-headers | awk '{print $6}')
curl -s "${POD_IP}" | grep "Thank you for using nginx"

SERVICE_IP=$(kubectl -n smoke get services nginx -o wide --no-headers | awk '{print $3}')
curl -s "${SERVICE_IP}" | grep "Thank you for using nginx"

kubectl delete namespace smoke

# vim: ts=2 sw=2 et
