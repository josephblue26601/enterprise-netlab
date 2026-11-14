#!/usr/bin/env python3
"""Network health check: OSPF neighbors, BGP sessions, reachability.

Writes reports/health-<timestamp>.md and exits non-zero on any failure.
"""
import datetime as dt
import sys
from pathlib import Path

from netlib import ROOT, connect, load_inventory, vtysh, vtysh_json

REPORT_DIR = ROOT.parent / "reports"


def collect(inv):
    results = []  # (check, device, status, detail)
    exp = inv["expected"]
    for dev in inv["devices"]:
        name = dev["name"]
        try:
            conn = connect(dev, inv["defaults"])
        except Exception as exc:
            results.append(("ssh", name, "FAIL", str(exc)))
            continue
        with conn:
            results.append(("ssh", name, "PASS", "reachable"))

            nbrs = vtysh_json(conn, "show ip ospf neighbor").get("neighbors", {})
            full = sum(1 for n in nbrs.values() for s in n
                       if "Full" in s.get("nbrState", s.get("state", "")))
            want = exp["ospf_neighbors"].get(name, 0)
            results.append(("ospf", name, "PASS" if full >= want else "FAIL",
                            f"{full}/{want} neighbors Full"))

            if name in exp["bgp_established"]:
                peers = vtysh_json(conn, "show bgp summary").get("ipv4Unicast", {}).get("peers", {})
                up = sum(1 for p in peers.values() if p.get("state") == "Established")
                want = exp["bgp_established"][name]
                results.append(("bgp", name, "PASS" if up >= want else "FAIL",
                                f"{up}/{want} peers Established"))

            for t in inv["ping_targets"]:
                out = conn.send_command(f"ping -c 2 -W 1 {t['ip']}")
                ok = " 0% packet loss" in out
                results.append(("ping", f"{name}->{t['name']}", "PASS" if ok else "FAIL", t["ip"]))

            route = vtysh(conn, "show ip route 10.20.10.0/24" if name == "hq-rtr"
                          else "show ip route 10.10.10.0/24")
            via = next((l.strip() for l in route.splitlines() if "via" in l), "no route")
            results.append(("path", name, "INFO", via))
    return results


def write_report(results):
    REPORT_DIR.mkdir(exist_ok=True)
    stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    fails = [r for r in results if r[2] == "FAIL"]
    lines = [f"# Health Check — {stamp}", "",
             f"**Overall:** {'HEALTHY' if not fails else f'DEGRADED ({len(fails)} failures)'}", "",
             "| Check | Target | Status | Detail |", "|---|---|---|---|"]
    lines += [f"| {c} | {d} | {s} | {x} |" for c, d, s, x in results]
    path = REPORT_DIR / f"health-{stamp}.md"
    path.write_text("\n".join(lines) + "\n")
    return path, fails


def main():
    results = collect(load_inventory())
    for c, d, s, x in results:
        print(f"{s:5} {c:5} {d:25} {x}")
    path, fails = write_report(results)
    print(f"\nReport: {path}")
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
