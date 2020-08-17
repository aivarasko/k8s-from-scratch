#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${TRACE:-}" ]] || set -o xtrace

source config.sh

./2_generate_local_ca.sh
./master.sh 192.168.11.80
./worker.sh 0 192.168.11.80 192.168.11.90
./worker.sh 1 192.168.11.80 192.168.11.91
./6_kube_components.sh
./7_smoke_tests.sh
# ./7_sonobuoy.sh
