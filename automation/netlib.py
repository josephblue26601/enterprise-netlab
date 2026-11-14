"""Shared helpers: load inventory, open SSH sessions, run vtysh commands."""
import json
import os
from pathlib import Path

import yaml
from netmiko import ConnectHandler

ROOT = Path(__file__).resolve().parent
INVENTORY = ROOT / "inventory.yaml"


def load_inventory(path=INVENTORY):
    with open(path) as f:
        return yaml.safe_load(f)


def connect(device, defaults):
    password = os.environ.get(defaults["password_env"], "Lab@dmin123")
    return ConnectHandler(
        device_type=device.get("device_type", defaults["device_type"]),
        host=device["host"],
        username=device.get("username", defaults["username"]),
        password=password,
        fast_cli=False,
    )


def vtysh(conn, command):
    """Run an FRR command over SSH."""
    return conn.send_command(f'vtysh -c "{command}"', read_timeout=30)


def vtysh_json(conn, command):
    out = vtysh(conn, f"{command} json")
    try:
        return json.loads(out)
    except json.JSONDecodeError:
        return {}
