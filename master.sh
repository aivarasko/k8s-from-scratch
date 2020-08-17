#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${TRACE:-}" ]] || set -o xtrace

source config.sh

export MASTER_IP=${MASTER_IP:-$1}

./0_prerequirements.sh
./1_make_binaries.sh
./2_generate_local_ca.sh
./2_generate_master_certificates.sh
./2_verify_certificates.sh
./3_gen_configs_master.sh
./4_start_services_master.sh
