#!/bin/sh
# ISP: just routing. Simulated "internet" lives on loopback (8.8.8.8, 198.51.100.0/24).
sysctl -w net.ipv4.ip_forward=1
ip route del default via 172.20.20.1 dev eth0 2>/dev/null || true
