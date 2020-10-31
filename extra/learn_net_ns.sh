#!/bin/bash
set -euxo pipefail

IFACE=enp3s0
PREFIX="learn"
NS="${PREFIX}"_ns
VETH="${PREFIX}"_veth
VPEER="${PREFIX}"_peer
NET_ADDR=192.168.21
VETH_ADDR="${NET_ADDR}".1
VPEER_ADDR="${NET_ADDR}".2
BRIDGE="${PREFIX}"_bridge

sysctl net.ipv4.ip_forward=1
sysctl net.bridge.bridge-nf-call-arptables=1
sysctl net.bridge.bridge-nf-call-ip6tables=1
sysctl net.bridge.bridge-nf-call-iptables=1

function clean() {
  ip link del "${BRIDGE}" || true
  for i in {1..2}; do

    ip netns del "${NS}${i}" &>/dev/null || true
    ip link del "${VETH}${i}" &>/dev/null || true
    ip link del "${VPEER}${i}" &>/dev/null || true
    iptables -t nat -D POSTROUTING -s "${VPEER_ADDR}${i}"/24 -o "${IFACE}" -j MASQUERADE || true
    iptables -t nat -D POSTROUTING -s "${NET_ADDR}${i}"/24 ! -o "${BRIDGE}" -j MASQUERADE || true
    iptables -D FORWARD -i "${IFACE}" -o "${VETH}${i}" -j ACCEPT || true
    iptables -D FORWARD -o "${IFACE}" -i "${VETH}${i}" -j ACCEPT || true
    iptables -D FORWARD -i "${IFACE}" -o "${BRIDGE}" -j ACCEPT || true
    iptables -D FORWARD -o "${IFACE}" -i "${BRIDGE}" -j ACCEPT || true

    iptables -D FORWARD -o "${BRIDGE}" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT || true
    iptables -D FORWARD -o "${BRIDGE}" -j DOCKER || true
    iptables -D FORWARD -i "${BRIDGE}" ! -o "${BRIDGE}" -j ACCEPT || true
    iptables -D FORWARD -i "${BRIDGE}" -o "${BRIDGE}" -j ACCEPT || true
    iptables -t nat -D POSTROUTING -s "${NET_ADDR}".0/24 ! -o "${BRIDGE}" -j MASQUERADE || true

  done
}

clean

ip link add name "${BRIDGE}" type bridge
ip addr add "${VETH_ADDR}"0/24 brd + dev "${BRIDGE}"
ip link set "${BRIDGE}" up

iptables -A FORWARD -o "${BRIDGE}" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i "${BRIDGE}" ! -o "${BRIDGE}" -j ACCEPT
iptables -A FORWARD -i "${BRIDGE}" -o "${BRIDGE}" -j ACCEPT
# iptables -t nat -A POSTROUTING -s "${NET_ADDR}".0/24 ! -o "${BRIDGE}" -j MASQUERADE

for i in {1..2}; do

  ip netns add "${NS}${i}"
  ip link add "${VETH}${i}" type veth peer name "${VPEER}${i}"
  ip link set "${VETH}${i}" netns "${NS}${i}"
  ip netns exec "${NS}${i}" ip addr add "${VETH_ADDR}${i}"/24 dev "${VETH}${i}"
  ip link set "${VPEER}${i}" up
  ip netns exec "${NS}${i}" ip link set lo up
  ip netns exec "${NS}${i}" ip link set "${VETH}${i}" up
  ip link set "${VPEER}${i}" master "${BRIDGE}"
  ip netns exec "${NS}${i}" ip route add default via "${VETH_ADDR}"0 dev "${VETH}${i}"

done

for i in {1..2}; do
  for i2 in {1..2}; do
    ip netns exec "${NS}${i}" ping -c 1 "${VETH_ADDR}${i2}"
  done
  ip netns exec "${NS}${i}" ping -c 1 8.8.8.8
  ip netns exec "${NS}${i}" dig @8.8.8.8 google.lt
done

clean
