#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${DEBUG:-}" ]] || set -o xtrace

tmp_dir=$(mktemp -d -t sonobouy-XXXXXXXXXX)

time sonobuoy run -m quick --wait
sonobuoy status
results=$(sonobuoy retrieve -d "${tmp_dir}")
echo "$results"
sonobuoy results "$results" >"${tmp_dir}/results-quick.logs"
cat "${tmp_dir}"/results-quick.logs
sonobuoy delete --all --wait
grep "Status: failed" "${tmp_dir}/results-quick.logs" && exit 1

time sonobuoy run -m certified-conformance --wait
sonobuoy status
results=$(sonobuoy retrieve -d "${tmp_dir}")
sonobuoy results "$results" >"${tmp_dir}/results-certified-conformance.logs"
cat "${tmp_dir}/results-certified-conformance.logs"
sonobuoy delete --all --wait
grep "Status: failed" "${tmp_dir}/results-certified-conformance.logs" && exit 1

echo "Results in dir ${tmp_dir}/"

# time sonobuoy run \
#   --plugin https://raw.githubusercontent.com/vmware-tanzsonobuoy-plugins/cis-benchmarks/cis-benchmarks/kube-bench-plugin.yaml \
#   --plugin https://raw.githubusercontent.com/vmware-tanzsonobuoy-plugins/cis-benchmarks/cis-benchmarks/kube-bench-master-plugin.yaml \
#   --wait
# results=$(sonobuoy retrieve)
# sonobuoy results $results > results-cis.logs
# cat results-cis.logs
# sonobuoy delete --all --wait

# vim: ts=2 sw=2 et
