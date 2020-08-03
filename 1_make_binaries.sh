#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${DEBUG:-}" ]] || set -o xtrace

export PATH=/opt/local_kube/go/current/bin:$PATH
GOPATH=${GOPATH:-~/go}

go version

source versions.sh

function install_etcd() {
  APP='etcd'
  GIT_VERSION="${ETCD_GIT_VERSION}"
  GIT_LOCATION="github.com/etcd-io/etcd"

  go get "${GIT_LOCATION}" || true
  pushd "${GOPATH}/src/${GIT_LOCATION}"
  git checkout "${GIT_VERSION}"
  make clean
  go mod vendor
  make
  sudo mkdir -p /opt/local_kube/"${APP}"/"${GIT_VERSION}"/bin
  sudo cp bin/* /opt/local_kube/"${APP}"/"${GIT_VERSION}"/bin/
  popd

  [ -d /opt/local_kube/"${APP}"/current ] && sudo rm /opt/local_kube/"${APP}"/current
  sudo ln -s /opt/local_kube/"${APP}"/"${GIT_VERSION}" /opt/local_kube/"${APP}"/current
}
[ ! -d /opt/local_kube/etcd/"${ETCD_GIT_VERSION}" ] && install_etcd

function install_kubernetes() {
  APP='kubernetes'
  GIT_VERSION="${KUBERNETES_GIT_VERSION}"
  GIT_LOCATION="github.com/kubernetes/kubernetes"

  go get "${GIT_LOCATION}" || true
  pushd "${GOPATH}/src/${GIT_LOCATION}"
  git checkout "${GIT_VERSION}"
  make clean
  make
  sudo mkdir -p /opt/local_kube/"${APP}"/"${GIT_VERSION}"/bin
  sudo cp _output/bin/* /opt/local_kube/"${APP}"/"${GIT_VERSION}"/bin/
  popd

  [ -d /opt/local_kube/"${APP}"/current ] && sudo rm /opt/local_kube/"${APP}"/current
  sudo ln -s /opt/local_kube/"${APP}"/"${GIT_VERSION}" /opt/local_kube/"${APP}"/current
}
[ ! -d /opt/local_kube/kubernetes/"${KUBERNETES_GIT_VERSION}" ] && install_kubernetes

function install_cfssl() {
  APP='cfssl'
  GIT_VERSION="${CFSSL_GIT_VERSION}"
  GIT_LOCATION="github.com/cloudflare/cfssl"

  go get "${GIT_LOCATION}" || true
  pushd "${GOPATH}/src/${GIT_LOCATION}"
  git checkout "${GIT_VERSION}"
  make clean
  make
  sudo mkdir -p /opt/local_kube/"${APP}"/"${GIT_VERSION}"/bin
  sudo cp bin/* /opt/local_kube/"${APP}"/"${GIT_VERSION}"/bin/
  popd

  [ -d /opt/local_kube/"${APP}"/current ] && sudo rm /opt/local_kube/"${APP}"/current
  sudo ln -s /opt/local_kube/"${APP}"/"${GIT_VERSION}" /opt/local_kube/"${APP}"/current
}
[ ! -d /opt/local_kube/cfssl/"${CFSSL_GIT_VERSION}" ] && install_cfssl

function install_runc() {
  APP='runc'
  GIT_VERSION="${RUNC_GIT_VERSION}"
  GIT_LOCATION="github.com/opencontainers/runc"

  go get "${GIT_LOCATION}" || true
  pushd "${GOPATH}/src/${GIT_LOCATION}"
  git checkout "${GIT_VERSION}"
  make clean
  make BUILDTAGS='seccomp apparmor'
  sudo mkdir -p /opt/local_kube/"${APP}"/"${GIT_VERSION}"/bin
  sudo cp runc /opt/local_kube/"${APP}"/"${GIT_VERSION}"/bin/
  # sudo cp runc /usr/local/sbin/
  popd

  [ -d /opt/local_kube/"${APP}"/current ] && sudo rm /opt/local_kube/"${APP}"/current
  sudo ln -s /opt/local_kube/"${APP}"/"${GIT_VERSION}" /opt/local_kube/"${APP}"/current
}
[ ! -d /opt/local_kube/runc/"${RUNC_GIT_VERSION}" ] && install_runc

function install_containerd() {
  APP='containerd'
  GIT_VERSION="${CONTAINERD_GIT_VERSION}"
  GIT_LOCATION="github.com/containerd/containerd"

  go get "${GIT_LOCATION}" || true
  pushd "${GOPATH}/src/${GIT_LOCATION}"
  git checkout "${GIT_VERSION}"
  make clean
  make
  sudo mkdir -p /opt/local_kube/"${APP}"/"${GIT_VERSION}"/bin
  sudo cp bin/* /opt/local_kube/"${APP}"/"${GIT_VERSION}"/bin/
  popd

  [ -d /opt/local_kube/"${APP}"/current ] && sudo rm /opt/local_kube/"${APP}"/current
  sudo ln -s /opt/local_kube/"${APP}"/"${GIT_VERSION}" /opt/local_kube/"${APP}"/current
}
[ ! -d /opt/local_kube/containerd/"${CONTAINERD_GIT_VERSION}" ] && install_containerd

function install_cni() {
  APP='cni'
  GIT_VERSION="${CNI_GIT_VERSION}"
  GIT_LOCATION="github.com/containernetworking/plugins"

  go get "${GIT_LOCATION}" || true
  pushd "${GOPATH}/src/${GIT_LOCATION}"
  git checkout "${GIT_VERSION}"
  ./build_linux.sh
  sudo mkdir -p /opt/local_kube/"${APP}"/"${GIT_VERSION}"/bin
  sudo cp bin/* /opt/local_kube/"${APP}"/"${GIT_VERSION}"/bin/
  popd

  [ -d /opt/local_kube/"${APP}"/current ] && sudo rm /opt/local_kube/"${APP}"/current
  sudo ln -s /opt/local_kube/"${APP}"/"${GIT_VERSION}" /opt/local_kube/"${APP}"/current

  # Default /etc/containerd/config.toml path
  sudo mkdir -p /opt/"${APP}"
  [ ! -d /opt/"${APP}"/bin ] && sudo ln -s /opt/local_kube/"${APP}"/current/bin /opt/"${APP}"/bin

  echo "cni done"
}
[ ! -d /opt/local_kube/cni/"${CNI_GIT_VERSION}" ] && install_cni

function install_sonobuoy() {
  APP='sonobuoy'
  VERSION="${SONOBUOY_VERSION}"
  LOCATION="https://github.com/vmware-tanzu/sonobuoy/releases/download/v${VERSION}/sonobuoy_${VERSION}_linux_amd64.tar.gz"

  sudo mkdir -p /opt/local_kube/"${APP}"/"${VERSION}"/bin
  pushd /opt/local_kube/"${APP}"/"${VERSION}"/bin
  sudo wget "${LOCATION}"
  sudo tar xvfz sonobuoy_"${VERSION}"_linux_amd64.tar.gz sonobuoy
  sudo rm sonobuoy_"${VERSION}"_linux_amd64.tar.gz
  sudo chmod +x sonobuoy
  popd

  [ -d /opt/local_kube/"${APP}"/current ] && sudo rm /opt/local_kube/"${APP}"/current
  sudo ln -s /opt/local_kube/"${APP}"/"${VERSION}" /opt/local_kube/"${APP}"/current
}
[ ! -d /opt/local_kube/sonobuoy/"${SONOBUOY_VERSION}" ] && install_sonobuoy

function install_crictl() {
  APP='crictl'
  VERSION="${CRICTL_VERSION}"
  LOCATION="https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-${VERSION}-linux-amd64.tar.gz"

  sudo mkdir -p /opt/local_kube/"${APP}"/"${VERSION}"/bin
  pushd /opt/local_kube/"${APP}"/"${VERSION}"/bin
  sudo wget "${LOCATION}"
  sudo tar xvfz crictl-"${VERSION}"-linux-amd64.tar.gz crictl
  sudo rm crictl-"${VERSION}"-linux-amd64.tar.gz
  sudo chmod +x crictl
  popd

  [ -d /opt/local_kube/"${APP}"/current ] && sudo rm /opt/local_kube/"${APP}"/current
  sudo ln -s /opt/local_kube/"${APP}"/"${VERSION}" /opt/local_kube/"${APP}"/current
}
[ ! -d /opt/local_kube/crictl/"${CRICTL_VERSION}" ] && install_crictl

for binary in /opt/local_kube/*/current/bin/*; do
  BIN_NAME=$(basename "${binary}")
  sudo ln -f -s "${binary}" /usr/local/sbin/"${BIN_NAME}"
done

exit 0
# vim: ts=2 sw=2 et
