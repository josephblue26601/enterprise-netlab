#!/usr/bin/env python3
"""Prometheus exporter for the lab. Grafana graphs these metrics.

Runs on the lab host (port 9105), polling routers over SSH every 15s.
"""
import re
import time

from prometheus_client import Gauge, start_http_server

from netlib import connect, load_inventory, vtysh_json

OSPF_NBRS = Gauge("netlab_ospf_neighbors_full", "OSPF neighbors in Full state", ["device"])
BGP_UP = Gauge("netlab_bgp_peers_established", "BGP peers Established", ["device"])
DEV_UP = Gauge("netlab_device_up", "Device reachable over SSH", ["device"])
RTT = Gauge("netlab_ping_rtt_ms", "Ping RTT in ms (-1 = unreachable)", ["device", "target"])
ROUTES = Gauge("netlab_route_count", "Routes in RIB", ["device"])
IFACE_UP = Gauge("netlab_wan_link_up", "WAN interface oper state", ["device", "interface"])

WAN = {"hq-rtr": ["eth1", "eth2", "eth4"], "br-rtr": ["eth1", "eth3"]}


def poll(inv):
    for dev in inv["devices"]:
        name = dev["name"]
        try:
            conn = connect(dev, inv["defaults"])
        except Exception:
            DEV_UP.labels(name).set(0)
            continue
        with conn:
            DEV_UP.labels(name).set(1)
            nbrs = vtysh_json(conn, "show ip ospf neighbor").get("neighbors", {})
            OSPF_NBRS.labels(name).set(sum(1 for n in nbrs.values() for s in n
                                           if "Full" in s.get("nbrState", s.get("state", ""))))
            peers = vtysh_json(conn, "show bgp summary").get("ipv4Unicast", {}).get("peers", {})
            BGP_UP.labels(name).set(sum(1 for p in peers.values() if p.get("state") == "Established"))
            ROUTES.labels(name).set(len(vtysh_json(conn, "show ip route")))
            for i in WAN.get(name, []):
                st = conn.send_command(f"cat /sys/class/net/{i}/operstate").strip()
                IFACE_UP.labels(name, i).set(1 if st == "up" else 0)
            for t in inv["ping_targets"]:
                out = conn.send_command(f"ping -c 1 -W 1 {t['ip']}")
                m = re.search(r"time=([\d.]+)", out)
                RTT.labels(name, t["name"]).set(float(m.group(1)) if m else -1)


if __name__ == "__main__":
    inv = load_inventory()
    start_http_server(9105)
    print("Exporter on :9105/metrics")
    while True:
        poll(inv)
        time.sleep(15)
