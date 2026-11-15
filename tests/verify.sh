#!/usr/bin/env bash
# Functional checks for every requirement. Run after deploy.
LAB=clab-netlab
pass=0; fail=0
x() { docker exec "$LAB-$1" sh -c "$2" >/dev/null 2>&1; }
check() { if x "$2" "$3"; then echo "PASS  $1"; pass=$((pass+1)); else echo "FAIL  $1"; fail=$((fail+1)); fi; }
deny()  { if x "$2" "$3"; then echo "FAIL  $1 (should be blocked)"; fail=$((fail+1)); else echo "PASS  $1"; pass=$((pass+1)); fi; }

check "DHCP: hq-user1 got 10.10.10.x"        hq-user1  "ip addr show eth1 | grep -q 'inet 10.10.10.'"
check "DHCP: br-user1 got 10.20.10.x"        br-user1  "ip addr show eth1 | grep -q 'inet 10.20.10.'"
check "Inter-VLAN: user -> server"           hq-user1  "ping -c2 -W1 10.10.20.10"
check "OSPF: HQ user -> branch gateway"      hq-user1  "ping -c2 -W1 10.20.10.1"
check "DNS: resolve intranet.lab.internal"   hq-user1  "nslookup intranet.lab.internal 10.10.20.10"
check "NAT: hq-rtr translating to 203.0.113.2" hq-rtr "iptables -t nat -L POSTROUTING -v -n | grep -q MASQUERADE"
check "NAT/BGP: HQ user -> internet"         hq-user1  "ping -c2 -W1 198.51.100.1"
check "NAT/BGP: branch user -> internet"     br-user1  "ping -c2 -W1 198.51.100.1"
check "Guest -> internet allowed"            hq-guest1 "ping -c2 -W1 198.51.100.1"
check "Guest -> DNS allowed"                 hq-guest1 "nslookup intranet.lab.internal 10.10.20.10"
deny  "ACL: guest -> server (ICMP)"          hq-guest1 "ping -c2 -W1 10.10.20.10"
deny  "ACL: branch guest -> HQ users"        br-guest1 "ping -c2 -W1 10.10.10.1"
deny  "ACL: user VLAN SSH to router"         hq-user1  "nc -z -w2 10.10.10.1 22"
check "BGP session Established"              hq-rtr    "vtysh -c 'show bgp summary json' | grep -Eq '\"state\": ?\"Established\"'"

echo; echo "$pass passed, $fail failed"
[ $fail -eq 0 ]
