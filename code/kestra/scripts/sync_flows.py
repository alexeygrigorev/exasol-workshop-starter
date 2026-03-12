"""Sync flow YAML files to Kestra via the API.

On Windows + Docker, filesystem events don't propagate from the host
into the container through bind mounts, so Kestra's file watcher
cannot detect changes you make to flow files. Run this script after
editing any flow YAML to push the updates to Kestra.

Usage: cd code/kestra && uv run python scripts/sync_flows.py
"""

import re
import sys
from pathlib import Path

import requests

KESTRA_URL = "http://localhost:8080"
AUTH = ("admin@kestra.io", "Admin1234!")


def parse_flow(path):
    text = path.read_text(encoding="utf-8")
    ns = re.search(r"^namespace:\s*(\S+)", text, re.MULTILINE)
    fid = re.search(r"^id:\s*(\S+)", text, re.MULTILINE)
    if not ns or not fid:
        return None, None
    return ns.group(1), fid.group(1)


def sync():
    flows_dir = Path("flows")
    if not flows_dir.exists():
        print("No flows/ directory found. Run from code/kestra/.")
        sys.exit(1)

    local_flows = set()

    # Upload local flows
    for path in sorted(flows_dir.glob("*.yml")):
        namespace, flow_id = parse_flow(path)
        if not namespace or not flow_id:
            print(f"Skipping {path} (could not parse namespace/id)")
            continue

        local_flows.add(f"{namespace}/{flow_id}")
        body = path.read_bytes()
        headers = {"Content-Type": "application/x-yaml"}

        # Try update, fall back to create
        r = requests.put(f"{KESTRA_URL}/api/v1/flows/{namespace}/{flow_id}",
                         data=body, headers=headers, auth=AUTH)
        if r.status_code == 200:
            print(f"  {path} ({namespace}/{flow_id}): updated")
        elif r.status_code == 404:
            r = requests.post(f"{KESTRA_URL}/api/v1/flows",
                              data=body, headers=headers, auth=AUTH)
            print(f"  {path} ({namespace}/{flow_id}): created ({r.status_code})")
        else:
            print(f"  {path} ({namespace}/{flow_id}): error ({r.status_code})")

    # Delete remote flows that have no local file
    r = requests.get(f"{KESTRA_URL}/api/v1/flows/search?size=1000", auth=AUTH)
    if r.status_code == 200:
        for flow in r.json().get("results", []):
            key = f"{flow['namespace']}/{flow['id']}"
            if key not in local_flows:
                dr = requests.delete(
                    f"{KESTRA_URL}/api/v1/flows/{flow['namespace']}/{flow['id']}",
                    auth=AUTH)
                print(f"  Deleted {key} ({dr.status_code})")

    print("Done.")


if __name__ == "__main__":
    sync()
