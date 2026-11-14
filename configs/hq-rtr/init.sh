#!/bin/sh
set -e
sysctl -w net.ipv4.ip_forward=1
apk add --no-cache iptables dnsmasq openssh >/dev/null

# Router-on-a-stick sub-interfaces (802.1Q)
for v in 10 20 30 99; do
  ip link add link eth3 name eth3.$v type vlan id $v 2>/dev/null || true
  ip link set eth3.$v up
done

# NAT: everything internal leaves as 203.0.113.2
iptables -t nat -A POSTROUTING -o eth1 -s 10.0.0.0/8 -j MASQUERADE

# DHCP for HQ VLANs (DNS points at hq-srv1)
dnsmasq --conf-file=/etc/dnsmasq.conf

SITE_GUEST=10.10.30.0/24 sh /security.sh
