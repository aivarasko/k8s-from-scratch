#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${TRACE:-}" ]] || set -o xtrace

kubectl delete namespace smoke || true

echo 'Checking if nodes can be pinged'
kubectl get nodes --no-headers=true | awk '{print $1}' | xargs -L 1 ping -c 1

# Test etcd status
ETCDCTL_API=3 etcdctl member list --endpoints=https://"${MASTER_IP}":2379 --cacert="${K8SFS_CERT_LOCATION}/ca.crt" --cert="${K8SFS_CERT_LOCATION}/kubernetes.crt" --key="${K8SFS_CERT_LOCATION}/kubernetes.key" | grep "started"

# Test secrets encryption
kubectl create namespace smoke

kubectl -n smoke create secret generic smoke-secret --from-literal="mysecret=mydata"
ETCDCTL_API=3 etcdctl get --endpoints="https://${MASTER_IP}:2379" --cacert="${K8SFS_CERT_LOCATION}/ca.crt" --cert="${K8SFS_CERT_LOCATION}/kubernetes.crt" --key="${K8SFS_CERT_LOCATION}/kubernetes.key" /registry/secrets/smoke/smoke-secret | grep "k8s:enc:aescbc:v1:key1" >>/dev/null

# Test Deployment, Expose
kubectl -n smoke create deployment nginx --image=nginx
kubectl -n smoke expose deployment nginx --port 80
kubectl -n smoke get pods -l app=nginx
kubectl -n smoke wait pods -l app=nginx --for=condition=Ready --timeout=100s
kubectl -n smoke logs -l app=nginx
kubectl -n smoke exec deployment/nginx -- nginx -v 2>&1 | grep "nginx version"

POD_IP=$(kubectl -n smoke get pods -l app=nginx -o wide --no-headers | awk '{print $6}')
echo "POD_IP, ${POD_IP}"
curl -s "${POD_IP}" | grep "Thank you for using nginx"

SERVICE_IP=$(kubectl -n smoke get services nginx -o wide --no-headers | awk '{print $3}')
echo "SERVICE_IP, ${SERVICE_IP}"
curl -s "${SERVICE_IP}" | grep "Thank you for using nginx"

if timeout 20 sh -c "while sleep 3 ; do curl --max-time 1 --silent --show-error --fail ${SERVICE_IP} | grep 'Thank you for using nginx' && break; done"; then
  echo "service is up"
else
  echo "service is down"
  exit 1
fi

kubectl -n smoke run -it --rm --wait=true --restart=Never ubuntu --image=ubuntu -- bash -c " \
  apt update -y && \
  ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata && \
  dpkg-reconfigure --frontend noninteractive tzdata && \
  apt install -y dnsutils iputils-ping curl && \
  dig kubernetes.default.svc.cluster.local | grep 10.32.0.1 && \
  curl http://nginx.smoke
"

kubectl delete namespace smoke
kubectl get namespace

# vim: ts=2 sw=2 et
