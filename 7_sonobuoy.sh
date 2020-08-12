#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${DEBUG:-}" ]] || set -o xtrace

tmp_dir=$(mktemp -d -t sonobouy-XXXXXXXXXX)

time sonobuoy run -m quick --wait
output="${tmp_dir}/results-quick.logs"

sonobuoy status
results=$(sonobuoy retrieve -d "${tmp_dir}")
echo "$results"
sonobuoy results "$results" >"${output}"
cat "${output}"
sonobuoy delete --all --wait
grep "Status: failed" "${output}" && exit 1

time sonobuoy run -m certified-conformance --wait
output="${tmp_dir}/results-certified-conformance.logs"

sonobuoy status
results=$(sonobuoy retrieve -d "${tmp_dir}")
echo "$results"
sonobuoy results "$results" >"${output}"
cat "${output}"
sonobuoy delete --all --wait
grep "Status: failed" "${output}" && exit 1

time sonobuoy run \
  --plugin https://raw.githubusercontent.com/vmware-tanzu/sonobuoy-plugins/master/cis-benchmarks/kube-bench-plugin.yaml \
  --plugin https://raw.githubusercontent.com/vmware-tanzu/sonobuoy-plugins/master/cis-benchmarks/kube-bench-master-plugin.yaml \
  --wait
output="${tmp_dir}/results-cis.logs"

sonobuoy status
results=$(sonobuoy retrieve -d "${tmp_dir}")
echo "$results"
sonobuoy results "$results" >"${output}"
cat "${output}"
sonobuoy delete --all --wait
grep "Status: failed" "${output}" && exit 1

echo "PASSED"

# vim: ts=2 sw=2 et
