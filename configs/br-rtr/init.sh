#!/bin/sh
set -e
sysctl -w net.ipv4.ip_forward=1
apk add --no-cache iptables dnsmasq openssh >/dev/null

for v in 10 30 99; do
  ip link add link eth2 name eth2.$v type vlan id $v 2>/dev/null || true
  ip link set eth2.$v up
done

dnsmasq --conf-file=/etc/dnsmasq.conf

SITE_GUEST=10.20.30.0/24 sh /security.sh
