#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${DEBUG:-}" ]] || set -o xtrace

source config.sh

./0_prerequirements.sh
./1_make_binaries.sh
./2_generate_local_ca.sh
./2_generate_main_certificates.sh
./2_generate_worker_certificates.sh
./2_verify_certificates.sh
./3_gen_configs_master.sh
./3_gen_configs_worker.sh
./4_start_services_master.sh
./4_start_services_worker.sh
./4_verify_kubeconfig_access.sh
./6_kube_components.sh
./7_smoke_tests.sh
./7_sonobuoy.sh
