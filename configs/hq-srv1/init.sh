#!/bin/sh
# hq-srv1: static server in VLAN 20, runs the internal DNS (lab.internal)
ip addr add 10.10.20.10/24 dev eth1
ip link set eth1 up
ip route replace 10.0.0.0/8 via 10.10.20.1 dev eth1
ip route replace 8.8.8.8/32 via 10.10.20.1 dev eth1
ip route replace 198.51.100.0/24 via 10.10.20.1 dev eth1
apk add --no-cache dnsmasq bind-tools
dnsmasq --conf-file=/etc/dnsmasq.conf
