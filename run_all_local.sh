#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${TRACE:-}" ]] || set -o xtrace

source config.sh

MASTER_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export MASTER_IP=${MASTER_IP}
export WORKER_IP=${MASTER_IP}
export WORKER_NO=1

export WORKER_IP=192.168.11.90
export WORKER_NO=0

./2_generate_local_ca.sh
./master.sh
./worker.sh
./6_kube_components.sh
./7_smoke_tests.sh
./7_one_by_one.sh PreStop should call prestop when killing a pod
./7_one_by_one.sh DNS should provide DNS
./7_one_by_one.sh should mutate configmap
./7_one_by_one.sh Aggregator Should be able to support
./7_sonobuoy.sh
