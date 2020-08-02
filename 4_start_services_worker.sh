#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

[[ -z "${DEBUG:-}" ]] || set -o xtrace

sudo systemctl daemon-reload
for service in 'containerd' 'kubelet' 'kube-proxy'; do
  sudo systemctl restart "${service}"
done

# vim: ts=2 sw=2 et
