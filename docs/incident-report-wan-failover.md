# Incident Report: Primary WAN Link Failure (HQ ↔ Branch)

> Template: fill the `[ ]` fields from `reports/failover-*.log` after running `make failover`.

| Field | Value |
|---|---|
| Incident ID | NETLAB-001 |
| Date / time | [ ] |
| Severity | SEV-3 (degraded, redundancy lost, no user-facing outage expected) |
| Duration | [ ] (failure injected → link restored) |
| Detected by | Grafana "WAN Link State" panel + OSPF neighbor count drop |
| Author | Joseph |

## Summary
The primary WAN link between hq-rtr (eth2) and br-rtr (eth1) went down. OSPF and BFD detected the failure, and traffic moved to the backup link (10.255.0.4/30). Measured user impact was **[ ] ms** of packet loss on a continuous ping from hq-user1 to br-user1.

## Timeline
| Time | Event |
|---|---|
| [ ] | Baseline: 10.20.10.0/24 reached via 10.255.0.2 (eth2), cost 10 |
| [ ] | Failure injected: `ip link set eth2 down` on hq-rtr |
| [ ] | BFD/OSPF neighbor 10.0.0.2 on eth2 drops |
| [ ] | Route reconverges via 10.255.0.6 (eth4), cost 100 |
| [ ] | Link restored, traffic returns to primary |

## Impact
- Packets lost: [ ] of 150 (200 ms interval) → ~[ ] ms outage
- Services affected: [none / list]
- Internet access from the branch: [ ] (it goes through HQ, so it follows the same reroute)

## Root cause
Simulated: an administrator shut the interface down. In production this would be a carrier circuit outage.

## What went well
- The backup path was already in the RIB as an OSPF alternate, so no manual action was needed
- BFD shortened detection compared with the default OSPF timers (dead interval 40 s)

## What could be improved
- [ ] e.g. add alerting so a NETLAB_WAN_LINK_UP == 0 event pages someone
- [ ] e.g. compare the outage with and without BFD (remove `ip ospf bfd` and rerun)

## Evidence
- Log: `reports/failover-[ ].log`
- Grafana screenshot: `docs/img/failover-grafana.png`
