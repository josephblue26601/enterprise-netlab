# IP Addressing & VLAN Plan

## Sites
| Site | Router | Loopback | OSPF Area | BGP AS |
|---|---|---|---|---|
| HQ | hq-rtr | 10.0.0.1/32 | 0 | 65001 |
| Branch | br-rtr | 10.0.0.2/32 | 0 | — |
| ISP | isp | 8.8.8.8/32 | — | 65000 |

## VLANs
| VLAN | Name | HQ Subnet | Branch Subnet | Gateway | DHCP Pool |
|---|---|---|---|---|---|
| 10 | USERS | 10.10.10.0/24 | 10.20.10.0/24 | .1 | .100–.200 |
| 20 | SERVERS | 10.10.20.0/24 | — | .1 | static |
| 30 | GUEST | 10.10.30.0/24 | 10.20.30.0/24 | .1 | .100–.200 (2h lease) |
| 99 | MGMT | 10.10.99.0/24 | 10.20.99.0/24 | .1 | .100–.150 |

## Point-to-Point Links
| Link | Subnet | A side | B side | OSPF Cost |
|---|---|---|---|---|
| HQ ↔ ISP | 203.0.113.0/30 | hq-rtr eth1 .2 | isp eth1 .1 | eBGP |
| WAN primary | 10.255.0.0/30 | hq-rtr eth2 .1 | br-rtr eth1 .2 | 10 |
| WAN backup | 10.255.0.4/30 | hq-rtr eth4 .5 | br-rtr eth3 .6 | 100 |

## Key Hosts
| Host | IP | Role |
|---|---|---|
| hq-srv1 | 10.10.20.10 | Internal DNS (lab.internal) |
| 198.51.100.0/24, 8.8.8.8 | — | Simulated internet (ISP loopbacks) |

## Management (out-of-band, containerlab)
172.20.20.0/24 — isp .10, hq-rtr .11, br-rtr .12, switches .21–.22, hosts .31+
