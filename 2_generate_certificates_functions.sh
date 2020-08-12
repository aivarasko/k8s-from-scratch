#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${DEBUG:-}" ]] || set -o xtrace

DEVICE_IPV4=$(ip route get 1 | awk '{print $(NF-2);exit}')
export DEVICE_IPV4="${DEVICE_IPV4}"

function gen_certs() {
  [ -f "${K8SFS_CERT_LOCATION}"/"${1}".key ] && return 0

  declare -r NAME=$1
  declare -r CN=$2
  declare -r O=$3
  declare -r HOSTNAME="${4:-none}"

  pushd "${K8SFS_CERT_LOCATION}"

  cat <<EOF | sudo tee "${NAME}"-csr.json
{
  "CN": "${CN}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "O": "${O}"
    }
  ]
}
EOF

  if [ -z "$HOSTNAME" ]; then
    sudo env "PATH=$PATH" cfssl gencert -ca="${K8SFS_CERT_LOCATION}"/ca.crt -ca-key="${K8SFS_CERT_LOCATION}"/ca.key -config="${K8SFS_CERT_LOCATION}"/ca-config.json -profile=kubernetes "${NAME}"-csr.json | sudo env "PATH=$PATH" cfssljson -bare "${NAME}"
  else
    sudo env "PATH=$PATH" cfssl gencert -ca="${K8SFS_CERT_LOCATION}"/ca.crt -ca-key="${K8SFS_CERT_LOCATION}"/ca.key -config="${K8SFS_CERT_LOCATION}"/ca-config.json -profile=kubernetes -hostname="${HOSTNAME}" "${NAME}"-csr.json | sudo env "PATH=$PATH" cfssljson -bare "${NAME}"
  fi
  sudo mv "${NAME}"-key.pem "${NAME}".key
  sudo mv "${NAME}".pem "${NAME}".crt
  openssl x509 -in "${K8SFS_CERT_LOCATION}/${NAME}".crt -text -noout

  popd
}

function generate_kubeconfig() {
  [ -f "${K8SFS_KUBECONFIG_LOCATION}"/"${1}".kubeconfig ] && return 0

  declare -x CLUSTER='K8Learn'
  declare -r NAME=$1
  declare -r SERVER_ADDR=$2
  declare -r USER=$3

  pushd "${K8SFS_KUBECONFIG_LOCATION}"
  sudo env "PATH=$PATH" kubectl config --kubeconfig="${NAME}".kubeconfig set-cluster "${CLUSTER}" --server=https://"${SERVER_ADDR}":6443 --certificate-authority="${K8SFS_CERT_LOCATION}"/ca.crt --embed-certs
  sudo env "PATH=$PATH" kubectl config --kubeconfig="${NAME}".kubeconfig set-credentials "${USER}" --client-certificate="${K8SFS_CERT_LOCATION}"/"${NAME}".crt --client-key="${K8SFS_CERT_LOCATION}"/"${NAME}".key --embed-certs
  sudo env "PATH=$PATH" kubectl config --kubeconfig="${NAME}".kubeconfig set-context default --cluster="${CLUSTER}" --user="${USER}"
  sudo env "PATH=$PATH" kubectl config --kubeconfig="${NAME}".kubeconfig use-context default
  popd
}

# vim: ts=2 sw=2 et
