#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${TRACE:-}" ]] || set -o xtrace

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

time sonobuoy run -m certified-conformance --wait --timeout 108000
output="${tmp_dir}/results-certified-conformance.logs"

sonobuoy status
results=$(sonobuoy retrieve -d "${tmp_dir}")
echo "$results"
sonobuoy results "$results" >"${output}"
cat "${output}"
sonobuoy delete --all --wait
grep "Status: failed" "${output}" && exit 1

#   sonobuoy results --mode detailed --plugin e2e $outfile |  jq '.  | select(.status == "failed") | .details'
#   sonobuoy run --e2e-focus "should update pod when spec was updated and update strategy is RollingUpdate"

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
