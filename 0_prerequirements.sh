#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${DEBUG:-}" ]] || set -o xtrace

source versions.sh
sudo apt-get update -y
dpkg -s libbtrfs-dev >/dev/null || sudo apt install libbtrfs-dev # for containerd

function install_go() {
  wget https://dl.google.com/go/go"${GO_VERSION}".linux-amd64.tar.gz
  sha256sum -c sha256sum
  sudo mkdir -p /opt/local_kube/go/go"${GO_VERSION}"
  sudo tar xvfz go"${GO_VERSION}".linux-amd64.tar.gz -C /opt/local_kube/go/go"${GO_VERSION}"
  [ -d /opt/local_kube/go/current ] && sudo rm /opt/local_kube/go/current
  sudo ln -s /opt/local_kube/go/go"${GO_VERSION}"/go /opt/local_kube/go/current
}

[ ! -d /opt/local_kube/go/go"${GO_VERSION}"/go ] && install_go

# sudo apt-get install -y gcc make pkg-config libseccomp-dev python3-pip
# sudo apt-get install -y socat conntrack ipset && break

# export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=/opt/local_kube/go/current/bin:$PATH

go version

exit 0

# sudo pip3 install --system awscli==1.16.266

# https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

sudo mkdir -p /opt/local_kube/kubernetes/ /opt/local_kube/kubernetes/manifest
sudo mv ~/pki /opt/local_kube/kubernetes/pki
