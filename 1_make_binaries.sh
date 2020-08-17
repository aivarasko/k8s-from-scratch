#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${DEBUG:-}" ]] || set -o xtrace

source config.sh

function install_go() {
  APP='go'

  tmp_dir=$(mktemp -d -t go-XXXXXXXXXX)
  wget https://dl.google.com/go/go"${GO_VERSION}".linux-amd64.tar.gz -O "${tmp_dir}/go${GO_VERSION}.linux-amd64.tar.gz"
  cp sha256sum "${tmp_dir}/"
  pushd "${tmp_dir}/"
  sha256sum -c sha256sum
  sudo mkdir -p "${K8SFS_CACHE_LOCATION}/${APP}/${GO_VERSION}"
  sudo tar xvfz go"${GO_VERSION}".linux-amd64.tar.gz -C "${K8SFS_CACHE_LOCATION}/${APP}/${GO_VERSION}"
  popd
  # [ -d "${K8SFS_CACHE_LOCATION}/go/current" ] && sudo rm "${K8SFS_CACHE_LOCATION}/go/current"
  # sudo ln -s "${K8SFS_CACHE_LOCATION}/go/go${GO_VERSION}/go" "${K8SFS_CACHE_LOCATION}/go/current"
}
[ ! -d "${K8SFS_CACHE_LOCATION}/go/${GO_VERSION}" ] && install_go

# Go does not exists yet in the target, use cached version
export PATH="${K8SFS_CACHE_LOCATION}/go/${GO_VERSION}/go/bin:$PATH"

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
  sudo mkdir -p "${K8SFS_CACHE_LOCATION}/${APP}/${GIT_VERSION}/bin"
  sudo cp bin/* "${K8SFS_CACHE_LOCATION}/${APP}/${GIT_VERSION}/bin/"
  popd

  # [ -d "${K8SFS_CACHE_LOCATION}/${APP}/current" ] && sudo rm "${K8SFS_CACHE_LOCATION}/${APP}/current"
  # sudo ln -s "${K8SFS_CACHE_LOCATION}/${APP}/${GIT_VERSION}" "${K8SFS_CACHE_LOCATION}/${APP}/current"
}
[ ! -d "${K8SFS_CACHE_LOCATION}/etcd/${ETCD_GIT_VERSION}" ] && install_etcd

function install_kubernetes() {
  APP='kubernetes'
  GIT_VERSION="${KUBERNETES_GIT_VERSION}"
  GIT_LOCATION="github.com/kubernetes/kubernetes"

  go get "${GIT_LOCATION}" || true
  pushd "${GOPATH}/src/${GIT_LOCATION}"
  git checkout "${GIT_VERSION}"
  make clean
  make
  sudo mkdir -p "${K8SFS_CACHE_LOCATION}/${APP}/${GIT_VERSION}/bin"
  sudo cp _output/bin/* "${K8SFS_CACHE_LOCATION}/${APP}/${GIT_VERSION}/bin/"
  popd

  # [ -d ${K8SFS_CACHE_LOCATION}/"${APP}"/current ] && sudo rm ${K8SFS_CACHE_LOCATION}/"${APP}"/current
  # sudo ln -s ${K8SFS_CACHE_LOCATION}/"${APP}"/"${GIT_VERSION}" ${K8SFS_CACHE_LOCATION}/"${APP}"/current
}
[ ! -d "${K8SFS_CACHE_LOCATION}/kubernetes/${KUBERNETES_GIT_VERSION}" ] && install_kubernetes

function install_cfssl() {
  APP='cfssl'
  GIT_VERSION="${CFSSL_GIT_VERSION}"
  GIT_LOCATION="github.com/cloudflare/cfssl"

  go get "${GIT_LOCATION}" || true
  pushd "${GOPATH}/src/${GIT_LOCATION}"
  git checkout "${GIT_VERSION}"
  make clean
  make
  sudo mkdir -p "${K8SFS_CACHE_LOCATION}/${APP}/${GIT_VERSION}/bin"
  sudo cp bin/* "${K8SFS_CACHE_LOCATION}/${APP}/${GIT_VERSION}/bin/"
  popd

  # [ -d ${K8SFS_CACHE_LOCATION}/"${APP}"/current ] && sudo rm ${K8SFS_CACHE_LOCATION}/"${APP}"/current
  # sudo ln -s ${K8SFS_CACHE_LOCATION}/"${APP}"/"${GIT_VERSION}" ${K8SFS_CACHE_LOCATION}/"${APP}"/current
}
[ ! -d "${K8SFS_CACHE_LOCATION}/cfssl/${CFSSL_GIT_VERSION}" ] && install_cfssl

function install_runc() {
  APP='runc'
  GIT_VERSION="${RUNC_GIT_VERSION}"
  GIT_LOCATION="github.com/opencontainers/runc"

  go get "${GIT_LOCATION}" || true
  pushd "${GOPATH}/src/${GIT_LOCATION}"
  git checkout "${GIT_VERSION}"
  make clean
  make BUILDTAGS='seccomp apparmor'
  sudo mkdir -p "${K8SFS_CACHE_LOCATION}/${APP}/${GIT_VERSION}/bin"
  sudo cp runc "${K8SFS_CACHE_LOCATION}/${APP}/${GIT_VERSION}/bin/"
  # sudo cp runc /usr/local/sbin/
  popd

  # TODO: do not overwrite runc, better update containerd config to use correct runc location
  sudo ln -fs /opt/k8sfs/runc/v1.0.0-rc92/bin/runc /usr/local/sbin/runc

  # [ -d ${K8SFS_CACHE_LOCATION}/"${APP}"/current ] && sudo rm ${K8SFS_CACHE_LOCATION}/"${APP}"/current
  # sudo ln -s ${K8SFS_CACHE_LOCATION}/"${APP}"/"${GIT_VERSION}" ${K8SFS_CACHE_LOCATION}/"${APP}"/current
}
[ ! -d "${K8SFS_CACHE_LOCATION}/runc/${RUNC_GIT_VERSION}" ] && install_runc

function install_containerd() {
  APP='containerd'
  GIT_VERSION="${CONTAINERD_GIT_VERSION}"
  GIT_LOCATION="github.com/containerd/containerd"

  go get "${GIT_LOCATION}" || true
  pushd "${GOPATH}/src/${GIT_LOCATION}"
  git checkout "${GIT_VERSION}"
  make clean
  make
  sudo mkdir -p "${K8SFS_CACHE_LOCATION}/${APP}/${GIT_VERSION}/bin"
  sudo cp bin/* "${K8SFS_CACHE_LOCATION}/${APP}/${GIT_VERSION}/bin/"
  popd

  # [ -d ${K8SFS_CACHE_LOCATION}/"${APP}"/current ] && sudo rm ${K8SFS_CACHE_LOCATION}/"${APP}"/current
  # sudo ln -s ${K8SFS_CACHE_LOCATION}/"${APP}"/"${GIT_VERSION}" ${K8SFS_CACHE_LOCATION}/"${APP}"/current
}
[ ! -d "${K8SFS_CACHE_LOCATION}/containerd/${CONTAINERD_GIT_VERSION}" ] && install_containerd

function install_cni() {
  APP='cni'
  GIT_VERSION="${CNI_GIT_VERSION}"
  GIT_LOCATION="github.com/containernetworking/plugins"

  go get "${GIT_LOCATION}" || true
  pushd "${GOPATH}/src/${GIT_LOCATION}"
  git checkout "${GIT_VERSION}"
  ./build_linux.sh
  sudo mkdir -p "${K8SFS_CACHE_LOCATION}/${APP}/${GIT_VERSION}/bin"
  sudo cp bin/* "${K8SFS_CACHE_LOCATION}/${APP}/${GIT_VERSION}/bin/"
  popd

  # [ -d ${K8SFS_CACHE_LOCATION}/"${APP}"/current ] && sudo rm ${K8SFS_CACHE_LOCATION}/"${APP}"/current
  # sudo ln -s ${K8SFS_CACHE_LOCATION}/"${APP}"/"${GIT_VERSION}" ${K8SFS_CACHE_LOCATION}/"${APP}"/current

  # Default /etc/containerd/config.toml path
  # sudo mkdir -p /opt/"${APP}"
  # [ ! -d /opt/"${APP}"/bin ] && sudo ln -s ${K8SFS_TARGET_LOCATION}/"${APP}"/"${GIT_LOCATION}"/bin /opt/"${APP}"/bin

  echo "cni done"
}
[ ! -d "${K8SFS_CACHE_LOCATION}/cni/${CNI_GIT_VERSION}" ] && install_cni

function install_sonobuoy() {
  APP='sonobuoy'
  VERSION="${SONOBUOY_VERSION}"
  LOCATION="https://github.com/vmware-tanzu/sonobuoy/releases/download/v${VERSION}/sonobuoy_${VERSION}_linux_amd64.tar.gz"

  sudo mkdir -p "${K8SFS_CACHE_LOCATION}/${APP}/${VERSION}/bin"
  pushd "${K8SFS_CACHE_LOCATION}/${APP}/${VERSION}/bin"
  sudo wget "${LOCATION}"
  sudo tar xvfz sonobuoy_"${VERSION}"_linux_amd64.tar.gz sonobuoy
  sudo rm sonobuoy_"${VERSION}"_linux_amd64.tar.gz
  sudo chmod +x sonobuoy
  popd

  # [ -d ${K8SFS_CACHE_LOCATION}/"${APP}"/current ] && sudo rm ${K8SFS_CACHE_LOCATION}/"${APP}"/current
  # sudo ln -s ${K8SFS_CACHE_LOCATION}/"${APP}"/"${VERSION}" ${K8SFS_CACHE_LOCATION}/"${APP}"/current
}
[ ! -d "${K8SFS_CACHE_LOCATION}/sonobuoy/${SONOBUOY_VERSION}" ] && install_sonobuoy

function install_crictl() {
  APP='crictl'
  VERSION="${CRICTL_VERSION}"
  LOCATION="https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-${VERSION}-linux-amd64.tar.gz"

  sudo mkdir -p "${K8SFS_CACHE_LOCATION}/${APP}/${VERSION}/bin"
  pushd "${K8SFS_CACHE_LOCATION}/${APP}/${VERSION}/bin"
  sudo wget "${LOCATION}"
  sudo tar xvfz crictl-"${VERSION}"-linux-amd64.tar.gz crictl
  sudo rm crictl-"${VERSION}"-linux-amd64.tar.gz
  sudo chmod +x crictl
  popd

  # [ -d ${K8SFS_CACHE_LOCATION}/"${APP}"/current ] && sudo rm ${K8SFS_CACHE_LOCATION}/"${APP}"/current
  # sudo ln -s ${K8SFS_CACHE_LOCATION}/"${APP}"/"${VERSION}" ${K8SFS_CACHE_LOCATION}/"${APP}"/current
}
[ ! -d "${K8SFS_CACHE_LOCATION}/crictl/${CRICTL_VERSION}" ] && install_crictl

sudo rsync -r "${K8SFS_CACHE_LOCATION}"/* "${K8SFS_TARGET_LOCATION}/"

exit 0
# vim: ts=2 sw=2 et
