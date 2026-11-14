#!/usr/bin/env bash
# Failure test: cut the primary HQ<->Branch WAN link and measure reroute.
# Output is saved to reports/failover-<timestamp>.log for the incident report.
set -u
LAB=clab-netlab
TS=$(date +%Y%m%d-%H%M%S)
LOG=reports/failover-$TS.log
mkdir -p reports
exec > >(tee "$LOG") 2>&1

x() { docker exec "$LAB-$1" sh -c "$2"; }
path() { x hq-rtr "vtysh -c 'show ip route 10.20.10.0/24'" | grep -E 'via|directly'; }

echo "=== $(date -Is) BASELINE ==="
path
x br-user1 "ip -4 addr show eth1 | grep inet"
BR_USER=$(x br-user1 "ip -4 -o addr show eth1" | awk '{print $4}' | cut -d/ -f1)

echo "=== Starting continuous ping hq-user1 -> br-user1 ($BR_USER) ==="
docker exec "$LAB-hq-user1" sh -c "ping -i 0.2 -c 150 $BR_USER > /tmp/ping.log 2>&1" &
PING_PID=$!
sleep 5

echo "=== $(date -Is) FAILURE INJECTED: hq-rtr eth2 (primary WAN) DOWN ==="
x hq-rtr "ip link set eth2 down"
sleep 3
echo "--- Path after failure ---"
path
x hq-rtr "vtysh -c 'show ip ospf neighbor'"

sleep 10
echo "=== $(date -Is) RESTORE: hq-rtr eth2 UP ==="
x hq-rtr "ip link set eth2 up"
wait $PING_PID
sleep 5
echo "--- Path after restore ---"
path

echo "=== PING RESULTS ==="
x hq-user1 "tail -3 /tmp/ping.log"
SENT=150
RECV=$(x hq-user1 "grep -c 'bytes from' /tmp/ping.log")
LOST=$((SENT - RECV))
echo "Lost $LOST of $SENT packets at 200ms interval => ~$((LOST * 200)) ms of outage"
echo "Log saved to $LOG"
