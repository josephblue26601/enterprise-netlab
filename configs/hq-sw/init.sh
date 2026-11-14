#!/bin/sh
# HQ access switch: VLAN-aware Linux bridge
# eth1 = trunk to hq-rtr (10,20,30,99)  eth2 = VLAN10  eth3 = VLAN20  eth4 = VLAN30
set -e
apk add --no-cache iproute2 >/dev/null
ip link add br0 type bridge vlan_filtering 1
ip link set br0 up
for p in eth1 eth2 eth3 eth4; do ip link set $p master br0; ip link set $p up; done

# Trunk
bridge vlan del dev eth1 vid 1
for v in 10 20 30 99; do bridge vlan add dev eth1 vid $v; done
# Access ports
access() { bridge vlan del dev $1 vid 1; bridge vlan add dev $1 vid $2 pvid untagged; }
access eth2 10
access eth3 20
access eth4 30
