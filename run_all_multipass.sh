#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${TRACE:-}" ]] || set -o xtrace

source config.sh

NODES_NO=2

make multipass_clean

function launch_multipass() {
  VM=$1
  multipass launch -c 2 -m 4G -d 20G -n "${VM}" 20.04
  multipass mount . "${VM}":/k8s-from-scratch
  mkdir -p ~/.k8sfs
  multipass mount ~/.k8sfs "${VM}":/home/ubuntu/.k8sfs
  mkdir -p ~/.cache/multipass/opt/k8sfs/kubernetes/pki
  multipass mount ~/.cache/multipass/opt/k8sfs/kubernetes/pki/ "${VM}":/opt/k8sfs/kubernetes/pki/
}

VM=master
launch_multipass "${VM}" || true
MASTER_IP=$(multipass info "${VM}" | grep IPv4 | awk '{print $2}')

multipass exec "${VM}" -- bash -c "cd /k8s-from-scratch && source config.sh && TRACE=1 ./0_prerequirements.sh"
multipass exec "${VM}" -- bash -c "cd /k8s-from-scratch && source config.sh && TRACE=1 ./2_generate_local_ca.sh"
multipass exec "${VM}" -- bash -c "cd /k8s-from-scratch && TRACE=1 ./master.sh ${MASTER_IP}"
multipass exec "${VM}" -- bash -c "cd /k8s-from-scratch && source config.sh && TRACE=1 kubectl apply -f manifests/kubelet-rbac.yaml"

for i in $(seq 1 $NODES_NO); do
  VM=node${i}
  launch_multipass "${VM}" || true
  WORKER_IP=$(multipass info "${VM}" | grep IPv4 | awk '{print $2}')
  multipass exec "${VM}" -- bash -c "cd /k8s-from-scratch && TRACE=1 ./worker.sh ${i} ${MASTER_IP} ${WORKER_IP}"
done

DEV=$(multipass exec master -- bash -c "ip route | grep ^default | cut -d' ' -f5")
for i in $(seq 1 $NODES_NO); do
  WORKER_IP=$(multipass info "node${i}" | grep IPv4 | awk '{print $2}')
  multipass exec master -- sudo ip route add 10.222."${i}".0/24 via "${WORKER_IP}" dev "${DEV}"
  multipass exec master -- bash -c "echo '${WORKER_IP} node${i}' | sudo tee -a /etc/hosts"

  for i2 in $(seq 1 $NODES_NO); do
    if [ "${i}" != "${i2}" ]; then
      echo "${i}, ${i2}"
      multipass exec "node${i2}" -- sudo ip route add 10.222."${i}".0/24 via "${WORKER_IP}" dev "${DEV}"
      multipass exec "node${i2}" -- bash -c "echo '${WORKER_IP} node${i}' | sudo tee -a /etc/hosts"
    fi
  done
done

multipass exec master -- bash -c "cd /k8s-from-scratch && source config.sh && TRACE=1 ./6_kube_components.sh"
for i in $(seq 1 $NODES_NO); do
  multipass exec "node${i}" -- bash -c "cd /k8s-from-scratch && source config.sh && TRACE=1 MASTER_IP=${MASTER_IP} ./7_smoke_tests.sh"
done

multipass exec master -- bash -c "cd /k8s-from-scratch && source config.sh && TRACE=1 ./7_one_by_one.sh PreStop should call prestop when killing a pod"
multipass exec master -- bash -c "cd /k8s-from-scratch && source config.sh && TRACE=1 ./7_one_by_one.sh DNS should provide DNS"
multipass exec master -- bash -c "cd /k8s-from-scratch && source config.sh && TRACE=1 ./7_one_by_one.sh should mutate configmap"
multipass exec master -- bash -c "cd /k8s-from-scratch && source config.sh && TRACE=1 ./7_one_by_one.sh Aggregator Should be able to support"
multipass exec master -- bash -c "cd /k8s-from-scratch && source config.sh && TRACE=1 ./7_sonobuoy.sh" || true
