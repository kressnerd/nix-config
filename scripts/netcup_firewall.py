#!/usr/bin/env python3
"""netcup-firewall — CLI tool to manage netcup vServer firewall rules.

This module provides a command-line interface for declaratively managing
firewall rules on netcup vServer instances via the SCP REST API.
Authentication uses the OIDC device code flow with offline refresh tokens.

Subcommands:
    backup    Save current firewall rules to a JSON file.
    lockdown  Apply a deny-all inbound policy (kill-switch).
    restore   Restore firewall rules from a previously saved JSON file.
    apply     Apply a named policy template (bootstrap or production).
"""

from __future__ import annotations

import argparse
import json
import logging
import os
import sys
import time
from typing import Any

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logger = logging.getLogger(__name__)

BASE_URL = "https://www.servercontrolpanel.de/scp-core/api/v1"
TOKEN_URL = "https://www.servercontrolpanel.de/realms/scp/protocol/openid-connect/token"
DEVICE_AUTH_URL = (
    "https://www.servercontrolpanel.de/realms/scp/protocol/openid-connect/auth/device"
)
USERINFO_URL = (
    "https://www.servercontrolpanel.de/realms/scp/protocol/openid-connect/userinfo"
)
CLIENT_ID = "scp"
SCOPES = "offline_access openid"


class ScpAuth:
    """OIDC authentication for the netcup Server Control Panel."""

    def __init__(self) -> None:
        """Initialize ScpAuth with the default credentials file path."""
        self._credentials_path = os.path.join(
            os.path.expanduser("~"), ".config", "netcup-scp", "credentials.json"
        )

    @property
    def credentials_path(self) -> str:
        """Return the path to the stored credentials file.

        Returns:
            Absolute path to the credentials JSON file.
        """
        return self._credentials_path

    def load_credentials(self) -> dict[str, Any] | None:
        """Load stored credentials from disk.

        Returns:
            Parsed credentials dict, or None if the file is missing or invalid.
        """
        try:
            with open(self._credentials_path) as f:
                return json.load(f)  # type: ignore[no-any-return]
        except (FileNotFoundError, json.JSONDecodeError):
            return None

    def save_credentials(self, tokens: dict[str, Any]) -> None:
        """Save tokens to the credentials file with 0600 permissions.

        Args:
            tokens: Token dict to persist (access_token, refresh_token, etc.).
        """
        creds_dir = os.path.dirname(self._credentials_path)
        os.makedirs(creds_dir, mode=0o700, exist_ok=True)
        fd = os.open(
            self._credentials_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600
        )
        with os.fdopen(fd, "w") as f:
            json.dump(tokens, f, indent=2)

    def device_code_flow(self) -> dict[str, Any]:
        """Initiate OIDC device code flow.

        Returns:
            Device auth response dict containing device_code, user_code,
            verification_uri, interval, and expires_in.

        Raises:
            requests.HTTPError: If the device authorization request fails.
        """
        resp = requests.post(
            DEVICE_AUTH_URL,
            data={
                "client_id": CLIENT_ID,
                "scope": SCOPES,
            },
            timeout=(10, 30),
        )
        resp.raise_for_status()
        return resp.json()  # type: ignore[no-any-return]

    def poll_for_token(
        self,
        device_code: str,
        interval: int = 5,
        expires_in: int = 600,
    ) -> dict[str, Any]:
        """Poll the token endpoint until the user completes auth.

        Args:
            device_code: The device code from the device authorization response.
            interval: Initial polling interval in seconds.
            expires_in: Total seconds before the device code expires.

        Returns:
            Token dict containing access_token and refresh_token.

        Raises:
            RuntimeError: If the device code auth fails with an unexpected error.
            TimeoutError: If the device code expires before auth completes.
        """
        elapsed = 0
        current_interval = interval
        while elapsed < expires_in:
            time.sleep(current_interval)
            elapsed += current_interval
            resp = requests.post(
                TOKEN_URL,
                data={
                    "client_id": CLIENT_ID,
                    "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
                    "device_code": device_code,
                },
                timeout=(10, 30),
            )
            if resp.status_code == 200:
                return resp.json()  # type: ignore[no-any-return]
            error = resp.json().get("error")
            if error == "authorization_pending":
                continue
            elif error == "slow_down":
                current_interval += 5
                continue
            else:
                raise RuntimeError(f"Device code auth failed: {error}")
        raise TimeoutError("Device code flow expired")

    def refresh_access_token(self, refresh_token: str) -> dict[str, Any]:
        """Exchange a refresh token for a new access token.

        Args:
            refresh_token: The refresh token to exchange.

        Returns:
            New token dict containing access_token and refresh_token.

        Raises:
            requests.HTTPError: If the token refresh request fails.
        """
        resp = requests.post(
            TOKEN_URL,
            data={
                "client_id": CLIENT_ID,
                "grant_type": "refresh_token",
                "refresh_token": refresh_token,
            },
            timeout=(10, 30),
        )
        resp.raise_for_status()
        return resp.json()  # type: ignore[no-any-return]

    def get_access_token(self) -> str:
        """Get a valid access token, using stored refresh or starting device flow.

        Returns:
            A valid access token string.

        Raises:
            TimeoutError: If the device code flow expires.
            RuntimeError: If device code auth fails with an unexpected error.
        """
        creds = self.load_credentials()
        if creds and "refresh_token" in creds:
            try:
                tokens = self.refresh_access_token(creds["refresh_token"])
                self.save_credentials(tokens)
                return tokens["access_token"]  # type: ignore[no-any-return]
            except requests.HTTPError:
                logger.info("Refresh token expired, starting device code flow...")
        device_resp = self.device_code_flow()
        print(
            f"\nOpen this URL in your browser: {device_resp['verification_uri']}",
            file=sys.stderr,
        )
        print(f"Enter this code: {device_resp['user_code']}\n", file=sys.stderr)
        tokens = self.poll_for_token(
            device_resp["device_code"],
            interval=device_resp.get("interval", 5),
            expires_in=device_resp.get("expires_in", 600),
        )
        self.save_credentials(tokens)
        return tokens["access_token"]  # type: ignore[no-any-return]

    def get_user_id(self, access_token: str) -> int:
        """Get the SCP user ID from the userinfo endpoint.

        Args:
            access_token: A valid access token.

        Returns:
            The integer user ID from the SCP userinfo response.

        Raises:
            requests.HTTPError: If the userinfo request fails.
        """
        resp = requests.get(
            USERINFO_URL,
            headers={
                "Authorization": f"Bearer {access_token}",
            },
            timeout=(10, 30),
        )
        resp.raise_for_status()
        return resp.json()["id"]  # type: ignore[no-any-return]


class ScpApiClient:
    """REST API client for the netcup Server Control Panel."""

    def __init__(self, access_token: str) -> None:
        """Initialize the API client with a valid access token.

        Args:
            access_token: A valid SCP OAuth2 access token.
        """
        self._token = access_token
        retry = Retry(
            total=3,
            backoff_factor=1,
            status_forcelist=[500, 502, 503, 504],
        )
        adapter = HTTPAdapter(max_retries=retry)
        self._session = requests.Session()
        self._session.mount("https://", adapter)
        self._session.mount("http://", adapter)

    def _headers(self) -> dict[str, str]:
        """Return HTTP headers for authenticated API requests."""
        return {
            "Authorization": f"Bearer {self._token}",
            "Content-Type": "application/json",
        }

    def _get(self, path: str) -> requests.Response:
        """Send an authenticated GET request to the SCP API."""
        resp = self._session.get(
            BASE_URL + path, headers=self._headers(), timeout=(10, 30)
        )
        resp.raise_for_status()
        return resp

    def _post(self, path: str, json_data: dict[str, Any]) -> requests.Response:
        """Send an authenticated POST request to the SCP API."""
        resp = self._session.post(
            BASE_URL + path, headers=self._headers(), json=json_data, timeout=(10, 30)
        )
        resp.raise_for_status()
        return resp

    def _put(self, path: str, json_data: dict[str, Any]) -> requests.Response:
        """Send an authenticated PUT request to the SCP API."""
        resp = self._session.put(
            BASE_URL + path, headers=self._headers(), json=json_data, timeout=(10, 30)
        )
        resp.raise_for_status()
        return resp

    def _delete(self, path: str) -> requests.Response:
        """Send an authenticated DELETE request to the SCP API."""
        resp = self._session.delete(
            BASE_URL + path, headers=self._headers(), timeout=(10, 30)
        )
        resp.raise_for_status()
        return resp

    def find_server(self, name: str) -> int:
        """Find a server by name and return its numeric ID.

        Args:
            name: The server name to search for.

        Returns:
            The integer server ID.

        Raises:
            ValueError: If no server with the given name is found.
        """
        resp = self._get(f"/servers?name={name}")
        servers = resp.json()
        if not isinstance(servers, list):
            raise ValueError(
                f"Unexpected response format when searching for server '{name}'"
            )
        for server in servers:
            if server.get("name") == name:
                server_id = server.get("id")
                if server_id is None:
                    raise ValueError(f"Server '{name}' response missing 'id' field")
                return server_id  # type: ignore[no-any-return]
        raise ValueError(f"Server '{name}' not found")

    def get_interfaces(self, server_id: int) -> list[dict[str, Any]]:
        """Return list of interface dicts for a server.

        Args:
            server_id: The numeric server ID.

        Returns:
            List of interface dicts, each containing mac and type fields.
        """
        resp = self._get(f"/servers/{server_id}/interfaces")
        return resp.json()  # type: ignore[no-any-return]

    def get_firewall(self, server_id: int, mac: str) -> dict[str, Any]:
        """Return the firewall state dict for a server interface.

        Args:
            server_id: The numeric server ID.
            mac: The MAC address of the interface.

        Returns:
            Firewall state dict including userPolicies and implicit rules.
        """
        resp = self._get(f"/servers/{server_id}/interfaces/{mac}/firewall")
        return resp.json()  # type: ignore[no-any-return]

    def set_firewall(self, server_id: int, mac: str, payload: dict[str, Any]) -> str:
        """Apply a firewall payload via PUT and return the task UUID.

        Args:
            server_id: The numeric server ID.
            mac: The MAC address of the interface.
            payload: Firewall payload dict (e.g., {"userPolicies": [...]}).

        Returns:
            Task UUID string for polling the async task status.
        """
        resp = self._put(f"/servers/{server_id}/interfaces/{mac}/firewall", payload)
        return resp.json()["uuid"]  # type: ignore[no-any-return]

    def list_policies(self, user_id: int) -> list[dict[str, Any]]:
        """Return list of firewall policy dicts for a user.

        Args:
            user_id: The numeric SCP user ID.

        Returns:
            List of firewall policy dicts.
        """
        resp = self._get(f"/users/{user_id}/firewall-policies")
        return resp.json()  # type: ignore[no-any-return]

    def get_policy(self, user_id: int, policy_id: int) -> dict[str, Any]:
        """Return a single firewall policy dict.

        Args:
            user_id: The numeric SCP user ID.
            policy_id: The numeric policy ID.

        Returns:
            Firewall policy dict including name and rules.
        """
        resp = self._get(f"/users/{user_id}/firewall-policies/{policy_id}")
        return resp.json()  # type: ignore[no-any-return]

    def create_policy(
        self,
        user_id: int,
        name: str,
        rules: list[dict[str, Any]],
    ) -> dict[str, Any]:
        """Create a new firewall policy and return the created policy dict.

        Args:
            user_id: The numeric SCP user ID.
            name: Name for the new policy.
            rules: List of firewall rule dicts.

        Returns:
            Created policy dict including the server-assigned id.
        """
        resp = self._post(
            f"/users/{user_id}/firewall-policies",
            {"name": name, "rules": rules},
        )
        return resp.json()  # type: ignore[no-any-return]

    def delete_policy(self, user_id: int, policy_id: int) -> None:
        """Delete a firewall policy.

        Args:
            user_id: The numeric SCP user ID.
            policy_id: The numeric policy ID to delete.
        """
        self._delete(f"/users/{user_id}/firewall-policies/{policy_id}")

    def wait_for_task(
        self,
        task_uuid: str,
        max_polls: int = 30,
        interval: int = 2,
    ) -> None:
        """Poll the task endpoint until COMPLETED, FAILED, or timeout.

        Args:
            task_uuid: The task UUID to poll.
            max_polls: Maximum number of polling attempts.
            interval: Seconds to wait between polls.

        Raises:
            RuntimeError: If the task status is FAILED.
            TimeoutError: If max_polls is exceeded without completion.
        """
        for _ in range(max_polls):
            resp = self._get(f"/tasks/{task_uuid}")
            data = resp.json()
            status = data.get("status")
            if status == "COMPLETED":
                return
            if status == "FAILED":
                raise RuntimeError(f"Task {task_uuid} failed")
            time.sleep(interval)
        raise TimeoutError(f"Task {task_uuid} did not complete after {max_polls} polls")


def cmd_backup(
    args: argparse.Namespace,
    backup_dir: str | None = None,
    auth: ScpAuth | None = None,
    client: ScpApiClient | None = None,
    user_id: int | None = None,
) -> str:
    """Export current firewall state to a JSON backup file.

    Args:
        args: Parsed CLI arguments (requires args.server).
        backup_dir: Directory for backup files. Defaults to
            ~/.local/share/netcup-scp/backups.
        auth: ScpAuth instance. Created internally if not provided.
        client: ScpApiClient instance. Created internally if not provided.
        user_id: SCP user ID. Fetched internally if not provided.

    Returns:
        Absolute path to the written backup file.
    """
    from datetime import datetime, timezone

    if backup_dir is None:
        backup_dir = os.path.join(
            os.path.expanduser("~"), ".local", "share", "netcup-scp", "backups"
        )

    if auth is None or client is None or user_id is None:
        auth = ScpAuth()
        access_token = auth.get_access_token()
        user_id = auth.get_user_id(access_token)
        client = ScpApiClient(access_token)

    server_id = client.find_server(args.server)
    interfaces = client.get_interfaces(server_id)

    interface_data: list[dict[str, Any]] = []
    for iface in interfaces:
        mac = iface["mac"]
        firewall = client.get_firewall(server_id, mac)
        interface_data.append(
            {
                "mac": mac,
                "firewall": firewall,
            }
        )

    policies = client.list_policies(user_id)

    now = datetime.now(timezone.utc)
    backup: dict[str, Any] = {
        "version": 1,
        "timestamp": now.isoformat(),
        "server": {
            "id": server_id,
            "name": args.server,
        },
        "interfaces": interface_data,
        "policies": policies,
    }

    os.makedirs(backup_dir, mode=0o700, exist_ok=True)
    timestamp_str = now.strftime("%Y%m%d-%H%M%S")
    filename = f"{args.server}-{timestamp_str}.json"
    filepath = os.path.join(backup_dir, filename)
    fd = os.open(filepath, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        json.dump(backup, f, indent=2)

    logger.info("Backup saved to: %s", filepath)
    return filepath


def cmd_lockdown(
    args: argparse.Namespace,
    auth: ScpAuth | None = None,
    client: ScpApiClient | None = None,
    user_id: int | None = None,
) -> None:
    """Kill switch: block ALL traffic via an empty firewall policy.

    Args:
        args: Parsed CLI arguments (requires args.server, args.yes).
        auth: ScpAuth instance. Created internally if not provided.
        client: ScpApiClient instance. Created internally if not provided.
        user_id: SCP user ID. Fetched internally if not provided.
    """
    if not args.yes:
        answer = input(
            f"WARNING: This will block ALL network traffic to {args.server}. "
            f"Continue? [y/N] "
        )
        if answer.lower() != "y":
            logger.error("Aborted.")
            sys.exit(1)

    if auth is None or client is None or user_id is None:
        auth = ScpAuth()
        access_token = auth.get_access_token()
        user_id = auth.get_user_id(access_token)
        client = ScpApiClient(access_token)

    logger.info("Creating automatic backup before lockdown...")
    backup_path = cmd_backup(args, auth=auth, client=client, user_id=user_id)

    server_id = client.find_server(args.server)
    interfaces = client.get_interfaces(server_id)

    lockdown_name = f"lockdown-{args.server}"
    policies = client.list_policies(user_id)
    lockdown_policy: dict[str, Any] | None = None
    for p in policies:
        if p["name"] == lockdown_name:
            lockdown_policy = p
            break

    if lockdown_policy is None:
        logger.info(
            "Creating lockdown policy '%s' (empty rules = DROP ALL)...", lockdown_name
        )
        lockdown_policy = client.create_policy(user_id, lockdown_name, [])
    else:
        logger.info(
            "Reusing existing lockdown policy '%s' (id: %s)",
            lockdown_name,
            lockdown_policy["id"],
        )

    for iface in interfaces:
        mac = iface["mac"]
        logger.info("Assigning lockdown policy to interface %s...", mac)
        task_uuid = client.set_firewall(
            server_id, mac, {"userPolicies": [lockdown_policy["id"]]}
        )
        client.wait_for_task(task_uuid)

        state = client.get_firewall(server_id, mac)
        logger.info(
            "  Interface %s: active=%s, ingress=%s, egress=%s",
            mac,
            state.get("active"),
            state.get("ingressImplicitRule"),
            state.get("egressImplicitRule"),
        )

    logger.info(
        "\nLOCKDOWN ACTIVE — all traffic to %s blocked via SCP external firewall",
        args.server,
    )
    logger.info("Backup saved to: %s", backup_path)
    logger.info(
        "To restore: python3 scripts/netcup_firewall.py restore --server %s --file %s",
        args.server,
        backup_path,
    )


def cmd_restore(
    args: argparse.Namespace,
    auth: ScpAuth | None = None,
    client: ScpApiClient | None = None,
    user_id: int | None = None,
) -> None:
    """Restore firewall state from a backup JSON file.

    Args:
        args: Parsed CLI arguments (requires args.server, args.file).
        auth: ScpAuth instance. Created internally if not provided.
        client: ScpApiClient instance. Created internally if not provided.
        user_id: SCP user ID. Fetched internally if not provided.

    Raises:
        SystemExit: If the backup file is missing, contains invalid JSON,
            has an unsupported version, or targets a different server.
    """
    backup: dict[str, Any]
    try:
        with open(args.file) as f:
            backup = json.load(f)
    except FileNotFoundError:
        logger.error("Backup file not found: %s", args.file)
        sys.exit(1)
    except json.JSONDecodeError as e:
        logger.error("Invalid JSON in backup file: %s", e)
        sys.exit(1)

    required_keys = {"version", "server", "interfaces", "policies"}
    missing = required_keys - set(backup.keys())
    if missing:
        logger.error(
            "Backup file missing required keys: %s", ", ".join(sorted(missing))
        )
        sys.exit(1)

    if backup.get("version") != 1:
        logger.error(
            "Unsupported backup version: %s (expected 1)", backup.get("version")
        )
        sys.exit(1)
    if backup.get("server", {}).get("name") != args.server:
        backup_server = backup.get("server", {}).get("name", "unknown")
        logger.error("Backup is for server '%s', not '%s'", backup_server, args.server)
        sys.exit(1)

    for iface in backup.get("interfaces", []):
        if "mac" not in iface:
            logger.error("Backup interface entry missing required key: mac")
            sys.exit(1)

    for policy in backup.get("policies", []):
        missing_policy_keys = {"name", "rules"} - set(policy.keys())
        if missing_policy_keys:
            logger.error(
                "Backup policy entry missing required keys: %s",
                ", ".join(sorted(missing_policy_keys)),
            )
            sys.exit(1)

    if auth is None or client is None or user_id is None:
        auth = ScpAuth()
        access_token = auth.get_access_token()
        user_id = auth.get_user_id(access_token)
        client = ScpApiClient(access_token)

    server_id = client.find_server(args.server)

    existing_policies = client.list_policies(user_id)
    existing_by_name = {p["name"]: p for p in existing_policies}
    id_map: dict[int, int] = {}

    for policy in backup.get("policies", []):
        old_id = policy["id"]
        name = policy["name"]
        rules = policy.get("rules", [])

        if name in existing_by_name:
            # TODO Epic 15: PUT the backed-up rules to the existing policy so that
            # restore is fully correct even when the policy already exists but has
            # diverged from the backup (requires PATCH/PUT policy-rules endpoint).
            new_id = existing_by_name[name]["id"]
            logger.info("Policy '%s' already exists (id: %s), reusing", name, new_id)
        else:
            created = client.create_policy(user_id, name, rules)
            new_id = created["id"]
            logger.info("Created policy '%s' (id: %s)", name, new_id)
        id_map[old_id] = new_id

    for iface_backup in backup.get("interfaces", []):
        mac = iface_backup["mac"]
        old_policy_ids = iface_backup.get("firewall", {}).get("userPolicies", [])
        new_policy_ids = [id_map.get(old_id, old_id) for old_id in old_policy_ids]

        logger.info("Assigning policies %s to interface %s...", new_policy_ids, mac)
        task_uuid = client.set_firewall(
            server_id, mac, {"userPolicies": new_policy_ids}
        )
        client.wait_for_task(task_uuid)

    logger.info("\nRESTORE COMPLETE — firewall state restored from %s", args.file)


def cmd_apply(args: argparse.Namespace) -> None:
    """Handle the apply subcommand (not yet implemented).

    Args:
        args: Parsed CLI arguments.

    Raises:
        SystemExit: Always, with code 1.
    """
    logger.error("Not implemented — see Epic 15")
    sys.exit(1)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    """Parse command-line arguments.

    Args:
        argv: List of argument strings. When None, sys.argv[1:] is used.

    Returns:
        argparse.Namespace with parsed arguments, including a ``func``
        attribute pointing to the appropriate command handler.
    """
    parser = argparse.ArgumentParser(
        prog="netcup-firewall",
        description="Manage netcup SCP firewall policies via REST API.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""\
examples:
  netcup-firewall backup --server cupix001
  netcup-firewall lockdown --server cupix001 --yes
  netcup-firewall restore --server cupix001 --file backup.json
""",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        default=False,
        help="Enable verbose output (INFO level logging).",
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        default=False,
        help="Suppress all output except errors (ERROR level logging).",
    )

    subparsers = parser.add_subparsers(dest="command")
    subparsers.required = True

    backup_parser = subparsers.add_parser("backup", help="Save current firewall rules.")
    backup_parser.add_argument(
        "--server",
        required=True,
        help="Target server name.",
    )
    backup_parser.set_defaults(command="backup", func=cmd_backup)

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
    lockdown_parser.set_defaults(command="lockdown", func=cmd_lockdown)

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
    restore_parser.set_defaults(command="restore", func=cmd_restore)

    apply_parser = subparsers.add_parser("apply", help="Apply a named policy template.")
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
    apply_parser.set_defaults(command="apply", func=cmd_apply)

    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> None:
    """Parse arguments, configure logging, and dispatch to the command handler."""
    args = parse_args(argv)

    if args.verbose:
        log_level = logging.INFO
    elif args.quiet:
        log_level = logging.ERROR
    else:
        log_level = logging.WARNING

    logging.basicConfig(level=log_level, format="%(message)s")

    try:
        args.func(args)
    except KeyboardInterrupt:
        print("\nInterrupted.", file=sys.stderr)
        sys.exit(130)
    except Exception as exc:  # noqa: BLE001
        if args.verbose:
            raise
        logger.error("%s", exc)
        sys.exit(1)


if __name__ == "__main__":
    main()
