#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${DEBUG:-}" ]] || set -o xtrace

for cert in "${K8SFS_CERT_LOCATION}"/*.crt; do
  openssl verify -verbose -CAfile "${K8SFS_CERT_LOCATION}/ca.crt" "${cert}"
done

# vim: ts=2 sw=2 et
