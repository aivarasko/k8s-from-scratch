#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${TRACE:-}" ]] || set -o xtrace

source config.sh

export WORKER_NO=${WORKER_NO:-$1}
export MASTER_IP=${MASTER_IP:-$2}
export WORKER_IP=${WORKER_IP:-$3}
export WORKER_HOSTNAME="${WORKER_HOSTNAME:-node$WORKER_NO}"
export WORKER_ROOT="${K8SFS_RUNTIME_DIR}/${WORKER_HOSTNAME}"

sudo mkdir -p "${WORKER_ROOT}"/var/{run,lib,log}

./0_prerequirements.sh
./1_make_binaries.sh
./2_generate_worker_certificates.sh
./2_verify_certificates.sh
./3_gen_configs_worker.sh
./4_start_services_worker.sh
./4_verify_kubeconfig_access.sh
