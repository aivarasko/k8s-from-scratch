#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${DEBUG:-}" ]] || set -o xtrace

for cert in /opt/local_kube/kubernetes/pki/*.crt; do
  openssl verify -verbose -CAfile /opt/local_kube/kubernetes/pki/ca.crt "${cert}"
done

# vim: ts=2 sw=2 et
