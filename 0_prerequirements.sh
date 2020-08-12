#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${DEBUG:-}" ]] || set -o xtrace

sudo swapoff -a

sudo apt update -y
sudo apt install -y socat conntrack ipset
sudo apt install -y gcc make libbtrfs-dev pkg-config libseccomp-dev

# vim: ts=2 sw=2 et
