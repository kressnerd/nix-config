#!/usr/bin/env python3
"""netcup-firewall — CLI tool to manage netcup vServer firewall rules.

Subcommands:
  backup    Save current firewall rules to a JSON file.
  lockdown  Apply a deny-all inbound policy (kill-switch).
  restore   Restore firewall rules from a previously saved JSON file.
  apply     Apply a named policy template (bootstrap or production).
"""

import argparse
import json
import os
import sys
import time

import requests

# ---------------------------------------------------------------------------
# OIDC / SCP auth constants
# ---------------------------------------------------------------------------

BASE_URL = "https://www.servercontrolpanel.de/scp-core/api/v1"
TOKEN_URL = "https://www.servercontrolpanel.de/realms/scp/protocol/openid-connect/token"
DEVICE_AUTH_URL = "https://www.servercontrolpanel.de/realms/scp/protocol/openid-connect/auth/device"
USERINFO_URL = "https://www.servercontrolpanel.de/realms/scp/protocol/openid-connect/userinfo"
CLIENT_ID = "scp"
SCOPES = "offline_access openid"


# ---------------------------------------------------------------------------
# ScpAuth — OIDC device code flow + token management
# ---------------------------------------------------------------------------


class ScpAuth:
    """OIDC authentication for the netcup Server Control Panel."""

    def __init__(self):
        self._credentials_path = os.path.join(
            os.path.expanduser("~"), ".config", "netcup-scp", "credentials.json"
        )

    @property
    def credentials_path(self):
        return self._credentials_path

    def load_credentials(self):
        """Load stored credentials. Returns dict or None."""
        try:
            with open(self._credentials_path) as f:
                return json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            return None

    def save_credentials(self, tokens):
        """Save tokens to credentials file with 0600 permissions."""
        creds_dir = os.path.dirname(self._credentials_path)
        os.makedirs(creds_dir, mode=0o700, exist_ok=True)
        fd = os.open(self._credentials_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        with os.fdopen(fd, "w") as f:
            json.dump(tokens, f, indent=2)

    def device_code_flow(self):
        """Initiate OIDC device code flow. Returns device auth response."""
        resp = requests.post(DEVICE_AUTH_URL, data={
            "client_id": CLIENT_ID,
            "scope": SCOPES,
        })
        resp.raise_for_status()
        return resp.json()

    def poll_for_token(self, device_code, interval=5, expires_in=600):
        """Poll token endpoint until user completes auth."""
        elapsed = 0
        current_interval = interval
        while elapsed < expires_in:
            time.sleep(current_interval)
            elapsed += current_interval
            resp = requests.post(TOKEN_URL, data={
                "client_id": CLIENT_ID,
                "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
                "device_code": device_code,
            })
            if resp.status_code == 200:
                return resp.json()
            error = resp.json().get("error")
            if error == "authorization_pending":
                continue
            elif error == "slow_down":
                current_interval += 5
                continue
            else:
                raise RuntimeError(f"Device code auth failed: {error}")
        raise TimeoutError("Device code flow expired")

    def refresh_access_token(self, refresh_token):
        """Exchange refresh token for new access token."""
        resp = requests.post(TOKEN_URL, data={
            "client_id": CLIENT_ID,
            "grant_type": "refresh_token",
            "refresh_token": refresh_token,
        })
        resp.raise_for_status()
        return resp.json()

    def get_access_token(self):
        """Get valid access token. Uses stored refresh or initiates device flow."""
        creds = self.load_credentials()
        if creds and "refresh_token" in creds:
            try:
                tokens = self.refresh_access_token(creds["refresh_token"])
                self.save_credentials(tokens)
                return tokens["access_token"]
            except requests.HTTPError:
                print("Refresh token expired, starting device code flow...")
        # No stored credentials or refresh failed — initiate device code flow
        device_resp = self.device_code_flow()
        print(f"\nOpen this URL in your browser: {device_resp['verification_uri']}")
        print(f"Enter this code: {device_resp['user_code']}\n")
        tokens = self.poll_for_token(
            device_resp["device_code"],
            interval=device_resp.get("interval", 5),
            expires_in=device_resp.get("expires_in", 600),
        )
        self.save_credentials(tokens)
        return tokens["access_token"]

    def get_user_id(self, access_token):
        """Get SCP user ID from userinfo endpoint."""
        resp = requests.get(USERINFO_URL, headers={
            "Authorization": f"Bearer {access_token}",
        })
        resp.raise_for_status()
        return resp.json()["id"]


# ---------------------------------------------------------------------------
# ScpApiClient — SCP REST API client
# ---------------------------------------------------------------------------


class ScpApiClient:
    """REST API client for the netcup Server Control Panel."""

    def __init__(self, access_token: str):
        self._token = access_token

    def _headers(self):
        return {
            "Authorization": f"Bearer {self._token}",
            "Content-Type": "application/json",
        }

    def _get(self, path):
        resp = requests.get(BASE_URL + path, headers=self._headers())
        resp.raise_for_status()
        return resp

    def _post(self, path, json_data):
        resp = requests.post(BASE_URL + path, headers=self._headers(), json=json_data)
        resp.raise_for_status()
        return resp

    def _put(self, path, json_data):
        resp = requests.put(BASE_URL + path, headers=self._headers(), json=json_data)
        resp.raise_for_status()
        return resp

    def _delete(self, path):
        resp = requests.delete(BASE_URL + path, headers=self._headers())
        resp.raise_for_status()
        return resp

    def find_server(self, name):
        """Find a server by name and return its ID."""
        resp = self._get(f"/servers?name={name}")
        servers = resp.json()
        for server in servers:
            if server.get("name") == name:
                return server["id"]
        raise ValueError(f"Server '{name}' not found")

    def get_interfaces(self, server_id):
        """Return list of interface dicts for a server."""
        resp = self._get(f"/servers/{server_id}/interfaces")
        return resp.json()

    def get_firewall(self, server_id, mac):
        """Return firewall state dict for a server interface."""
        resp = self._get(f"/servers/{server_id}/interfaces/{mac}/firewall")
        return resp.json()

    def set_firewall(self, server_id, mac, payload):
        """Apply firewall payload via PUT; return task UUID from 202 response."""
        resp = self._put(f"/servers/{server_id}/interfaces/{mac}/firewall", payload)
        return resp.json()["uuid"]

    def list_policies(self, user_id):
        """Return list of firewall policy dicts for a user."""
        resp = self._get(f"/users/{user_id}/firewall-policies")
        return resp.json()

    def get_policy(self, user_id, policy_id):
        """Return a single firewall policy dict."""
        resp = self._get(f"/users/{user_id}/firewall-policies/{policy_id}")
        return resp.json()

    def create_policy(self, user_id, name, rules):
        """Create a new firewall policy; return the created policy dict."""
        resp = self._post(f"/users/{user_id}/firewall-policies", {"name": name, "rules": rules})
        return resp.json()

    def delete_policy(self, user_id, policy_id):
        """Delete a firewall policy."""
        self._delete(f"/users/{user_id}/firewall-policies/{policy_id}")

    def wait_for_task(self, task_uuid, max_polls=30, interval=2):
        """Poll task endpoint until COMPLETED, FAILED, or max_polls exceeded."""
        for _ in range(max_polls):
            resp = self._get(f"/tasks/{task_uuid}")
            status = resp.json()["status"]
            if status == "COMPLETED":
                return
            if status == "FAILED":
                raise RuntimeError(f"Task {task_uuid} failed")
            time.sleep(interval)
        raise TimeoutError(f"Task {task_uuid} did not complete after {max_polls} polls")


def parse_args(argv=None):
    """Parse command-line arguments.

    Args:
        argv: List of argument strings. When None, sys.argv[1:] is used.

    Returns:
        argparse.Namespace with parsed arguments.
    """
    parser = argparse.ArgumentParser(
        prog="netcup-firewall",
        description="Manage netcup vServer firewall rules declaratively.",
    )

    subparsers = parser.add_subparsers(dest="command")
    subparsers.required = True  # ensure missing subcommand raises SystemExit

    # --- backup ---
    backup_parser = subparsers.add_parser("backup", help="Save current firewall rules.")
    backup_parser.add_argument(
        "--server",
        required=True,
        help="Target server name.",
    )
    backup_parser.set_defaults(command="backup")

    # --- lockdown ---
    lockdown_parser = subparsers.add_parser(
        "lockdown", help="Apply deny-all inbound policy."
    )
    lockdown_parser.add_argument(
        "--server",
        required=True,
        help="Target server name.",
    )
    lockdown_parser.add_argument(
        "--yes",
        action="store_true",
        default=False,
        help="Skip confirmation prompt.",
    )
    lockdown_parser.set_defaults(command="lockdown")

    # --- restore ---
    restore_parser = subparsers.add_parser(
        "restore", help="Restore firewall rules from a backup file."
    )
    restore_parser.add_argument(
        "--server",
        required=True,
        help="Target server name.",
    )
    restore_parser.add_argument(
        "--file",
        required=True,
        help="Path to the JSON backup file.",
    )
    restore_parser.set_defaults(command="restore")

    # --- apply ---
    apply_parser = subparsers.add_parser(
        "apply", help="Apply a named policy template."
    )
    apply_parser.add_argument(
        "--server",
        required=True,
        help="Target server name.",
    )
    apply_parser.add_argument(
        "--policy",
        required=True,
        choices=["bootstrap", "production"],
        help="Policy template to apply.",
    )
    apply_parser.set_defaults(command="apply")

    return parser.parse_args(argv)


# ---------------------------------------------------------------------------
# Command handlers
# ---------------------------------------------------------------------------


def cmd_backup(args, backup_dir=None, auth=None, client=None, user_id=None):
    """Export current firewall state to JSON backup file."""
    from datetime import datetime, timezone

    # Default backup directory
    if backup_dir is None:
        backup_dir = os.path.join(
            os.path.expanduser("~"), ".local", "share", "netcup-scp", "backups"
        )

    # Authenticate (or reuse provided instances)
    if auth is None or client is None or user_id is None:
        auth = ScpAuth()
        access_token = auth.get_access_token()
        user_id = auth.get_user_id(access_token)
        client = ScpApiClient(access_token)

    # Gather data
    server_id = client.find_server(args.server)
    interfaces = client.get_interfaces(server_id)

    # Get firewall state for each interface
    interface_data = []
    for iface in interfaces:
        mac = iface["mac"]
        firewall = client.get_firewall(server_id, mac)
        interface_data.append({
            "mac": mac,
            "firewall": firewall,
        })

    # Get all user policies
    policies = client.list_policies(user_id)

    # Assemble backup
    now = datetime.now(timezone.utc)
    backup = {
        "version": 1,
        "timestamp": now.isoformat(),
        "server": {
            "id": server_id,
            "name": args.server,
        },
        "interfaces": interface_data,
        "policies": policies,
    }

    # Write backup file
    os.makedirs(backup_dir, mode=0o700, exist_ok=True)
    timestamp_str = now.strftime("%Y%m%d-%H%M%S")
    filename = f"{args.server}-{timestamp_str}.json"
    filepath = os.path.join(backup_dir, filename)
    fd = os.open(filepath, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        json.dump(backup, f, indent=2)

    print(f"Backup saved to: {filepath}")
    return filepath


def cmd_lockdown(args):
    """Kill switch: block ALL traffic via empty firewall policy."""
    # Confirmation prompt unless --yes
    if not args.yes:
        answer = input(
            f"WARNING: This will block ALL network traffic to {args.server}. "
            f"Continue? [y/N] "
        )
        if answer.lower() != "y":
            print("Aborted.")
            sys.exit(1)

    # Authenticate once
    auth = ScpAuth()
    access_token = auth.get_access_token()
    user_id = auth.get_user_id(access_token)
    client = ScpApiClient(access_token)

    # Auto-backup first (safety net) — share auth to avoid double login
    print("Creating automatic backup before lockdown...")
    backup_path = cmd_backup(args, auth=auth, client=client, user_id=user_id)
    print(f"Backup saved to: {backup_path}")

    # Find server and interfaces
    server_id = client.find_server(args.server)
    interfaces = client.get_interfaces(server_id)

    # Find or create lockdown policy
    lockdown_name = f"lockdown-{args.server}"
    policies = client.list_policies(user_id)
    lockdown_policy = None
    for p in policies:
        if p["name"] == lockdown_name:
            lockdown_policy = p
            break

    if lockdown_policy is None:
        print(f"Creating lockdown policy '{lockdown_name}' (empty rules = DROP ALL)...")
        lockdown_policy = client.create_policy(user_id, lockdown_name, [])
    else:
        print(f"Reusing existing lockdown policy '{lockdown_name}' (id: {lockdown_policy['id']})")

    # Assign lockdown policy to each interface
    for iface in interfaces:
        mac = iface["mac"]
        print(f"Assigning lockdown policy to interface {mac}...")
        task_uuid = client.set_firewall(server_id, mac, {"userPolicies": [lockdown_policy["id"]]})
        client.wait_for_task(task_uuid)

        # Verify
        state = client.get_firewall(server_id, mac)
        print(f"  Interface {mac}: active={state.get('active')}, "
              f"ingress={state.get('ingressImplicitRule')}, "
              f"egress={state.get('egressImplicitRule')}")

    print(f"\nLOCKDOWN ACTIVE — all traffic to {args.server} blocked via SCP external firewall")
    print(f"Backup saved to: {backup_path}")
    print(f"To restore: python3 scripts/netcup_firewall.py restore --server {args.server} --file {backup_path}")


def cmd_restore(args):
    """Restore firewall state from a backup JSON file."""
    # Load backup file
    try:
        with open(args.file) as f:
            backup = json.load(f)
    except FileNotFoundError:
        print(f"Error: Backup file not found: {args.file}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in backup file: {e}")
        sys.exit(1)

    # Validate backup
    if backup.get("version") != 1:
        print(f"Error: Unsupported backup version: {backup.get('version')} (expected 1)")
        sys.exit(1)
    if backup.get("server", {}).get("name") != args.server:
        backup_server = backup.get("server", {}).get("name", "unknown")
        print(f"Error: Backup is for server '{backup_server}', not '{args.server}'")
        sys.exit(1)

    # Authenticate
    auth = ScpAuth()
    access_token = auth.get_access_token()
    user_id = auth.get_user_id(access_token)
    client = ScpApiClient(access_token)

    # Find server
    server_id = client.find_server(args.server)

    # Restore policies: map old IDs to new IDs
    existing_policies = client.list_policies(user_id)
    existing_by_name = {p["name"]: p for p in existing_policies}
    id_map = {}  # old_id → new_id

    for policy in backup.get("policies", []):
        old_id = policy["id"]
        name = policy["name"]
        rules = policy.get("rules", [])

        if name in existing_by_name:
            # Reuse existing policy
            new_id = existing_by_name[name]["id"]
            print(f"Policy '{name}' already exists (id: {new_id}), reusing")
        else:
            # Create new policy
            created = client.create_policy(user_id, name, rules)
            new_id = created["id"]
            print(f"Created policy '{name}' (id: {new_id})")
        id_map[old_id] = new_id

    # Restore interface firewall assignments
    for iface_backup in backup.get("interfaces", []):
        mac = iface_backup["mac"]
        old_policy_ids = iface_backup.get("firewall", {}).get("userPolicies", [])
        new_policy_ids = [id_map.get(old_id, old_id) for old_id in old_policy_ids]

        print(f"Assigning policies {new_policy_ids} to interface {mac}...")
        task_uuid = client.set_firewall(server_id, mac, {"userPolicies": new_policy_ids})
        client.wait_for_task(task_uuid)

    print(f"\nRESTORE COMPLETE — firewall state restored from {args.file}")


def cmd_apply(args):
    """Handle the apply subcommand."""
    print("Not implemented — see Epic 15")
    sys.exit(1)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

_DISPATCH = {
    "backup": cmd_backup,
    "lockdown": cmd_lockdown,
    "restore": cmd_restore,
    "apply": cmd_apply,
}


def main():
    """Parse arguments and dispatch to the appropriate command handler."""
    args = parse_args()
    handler = _DISPATCH.get(args.command)
    if handler is None:
        # Should not happen because subparsers.required = True, but be safe.
        parse_args(["--help"])
        sys.exit(1)
    handler(args)


if __name__ == "__main__":
    main()
