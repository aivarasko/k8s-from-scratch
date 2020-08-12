#!/bin/bash
set -euox pipefail
IFS=$'\n\t'

function create_ca() {
  pushd "${K8SFS_CERT_LOCATION}"

  cat <<EOF | sudo tee ca-config.json
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

  cat <<EOF | sudo tee ca-csr.json
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  }
}
EOF

  cfssl gencert -initca ca-csr.json | sudo env "PATH=$PATH" cfssljson -bare ca
  sudo mv ca-key.pem ca.key
  sudo mv ca.pem ca.crt

  popd
}

if [ ! -f "${K8SFS_CERT_LOCATION}/ca.crt" ]; then
  create_ca
fi

# vim: ts=2 sw=2 et
