#!/usr/bin/env python3
"""Back up running configs from every device and commit any changes to Git.

Usage: python automation/backup_configs.py [--push]
"""
import argparse
import datetime as dt
import subprocess
import sys
from pathlib import Path

from netlib import ROOT, connect, load_inventory, vtysh

BACKUP_DIR = ROOT.parent / "backups"


def git(*args):
    return subprocess.run(["git", "-C", str(ROOT.parent), *args],
                          capture_output=True, text=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--push", action="store_true", help="git push after commit")
    args = ap.parse_args()

    inv = load_inventory()
    BACKUP_DIR.mkdir(exist_ok=True)
    failed = []

    for dev in inv["devices"]:
        try:
            with connect(dev, inv["defaults"]) as conn:
                running = vtysh(conn, "show running-config")
                firewall = conn.send_command("sudo iptables-save 2>/dev/null || iptables-save")
            (BACKUP_DIR / f"{dev['name']}.frr.conf").write_text(running + "\n")
            (BACKUP_DIR / f"{dev['name']}.iptables").write_text(firewall + "\n")
            print(f"[OK]   {dev['name']}")
        except Exception as exc:  # keep going if one device is down
            print(f"[FAIL] {dev['name']}: {exc}")
            failed.append(dev["name"])

    git("add", "backups")
    if git("diff", "--cached", "--quiet").returncode != 0:
        stamp = dt.datetime.now().strftime("%Y-%m-%d %H:%M")
        git("commit", "-m", f"Config backup {stamp}")
        print("Changes committed.")
        if args.push:
            print(git("push").stderr.strip() or "Pushed.")
    else:
        print("No config changes since last backup.")

    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
