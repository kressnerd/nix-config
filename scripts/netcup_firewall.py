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
        with open(self._credentials_path, "w") as f:
            json.dump(tokens, f, indent=2)
        os.chmod(self._credentials_path, 0o600)

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
            tokens = self.refresh_access_token(creds["refresh_token"])
            self.save_credentials(tokens)
            return tokens["access_token"]
        # No stored credentials — initiate device code flow
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
        return requests.get(BASE_URL + path, headers=self._headers())

    def _post(self, path, json_data):
        return requests.post(BASE_URL + path, headers=self._headers(), json=json_data)

    def _put(self, path, json_data):
        return requests.put(BASE_URL + path, headers=self._headers(), json=json_data)

    def _delete(self, path):
        return requests.delete(BASE_URL + path, headers=self._headers())

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


def cmd_backup(args):
    """Handle the backup subcommand."""
    print("Not implemented")
    sys.exit(1)


def cmd_lockdown(args):
    """Handle the lockdown subcommand."""
    print("Not implemented")
    sys.exit(1)


def cmd_restore(args):
    """Handle the restore subcommand."""
    print("Not implemented")
    sys.exit(1)


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
