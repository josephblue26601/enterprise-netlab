#!/bin/sh
# Branch access switch. eth1 = trunk (10,30,99)  eth2 = VLAN10  eth3 = VLAN30
set -e
apk add --no-cache iproute2 >/dev/null
ip link add br0 type bridge vlan_filtering 1
ip link set br0 up
for p in eth1 eth2 eth3; do ip link set $p master br0; ip link set $p up; done

bridge vlan del dev eth1 vid 1
for v in 10 30 99; do bridge vlan add dev eth1 vid $v; done
access() { bridge vlan del dev $1 vid 1; bridge vlan add dev $1 vid $2 pvid untagged; }
access eth2 10
access eth3 30
