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
import contextlib
import ipaddress
import json
import logging
import os
import sys
import time
from datetime import datetime, timezone
from typing import Any

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

try:
    import secretstorage
    from secretstorage.exceptions import (
        LockedException,
        SecretServiceNotAvailableException,
    )

    _HAS_SECRETSTORAGE = True
except ImportError:
    _HAS_SECRETSTORAGE = False

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


_KEYRING_SERVICE = "netcup-scp"
_KEYRING_USERNAME = "default"
_KEYRING_LABEL = "netcup-scp credentials"


class ScpAuth:
    """OIDC authentication for the netcup Server Control Panel."""

    def __init__(self, use_keyring: bool = False) -> None:
        """Initialize ScpAuth with file or keyring credential backend.

        Args:
            use_keyring: When True, use the Secret Service API (gnome-keyring)
                instead of a JSON file. Requires secretstorage library.

        Raises:
            RuntimeError: If use_keyring is True but secretstorage is not installed.
        """
        self._credentials_path = os.path.join(
            os.path.expanduser("~"), ".config", "netcup-scp", "credentials.json"
        )
        self._use_keyring = use_keyring
        if use_keyring and not _HAS_SECRETSTORAGE:
            raise RuntimeError(
                "--keyring requires the secretstorage library (not installed)"
            )

    @property
    def credentials_path(self) -> str:
        """Return the path to the stored credentials file.

        Returns:
            Absolute path to the credentials JSON file.
        """
        return self._credentials_path

    def _load_from_file(self) -> dict[str, Any] | None:
        """Load credentials from the JSON file.

        Returns:
            Parsed credentials dict, or None if the file is missing or invalid.
        """
        try:
            with open(self._credentials_path) as f:
                return json.load(f)  # type: ignore[no-any-return]
        except (FileNotFoundError, json.JSONDecodeError):
            return None

    def _save_to_file(self, tokens: dict[str, Any]) -> None:
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

    def _load_from_keyring(self) -> dict[str, Any] | None:
        """Load credentials from the Secret Service keyring.

        Returns:
            Parsed credentials dict, or None if no entry exists.

        Raises:
            RuntimeError: If the Secret Service is unavailable or the keyring is locked.
        """
        try:
            with contextlib.closing(secretstorage.dbus_init()) as conn:
                collection = secretstorage.get_default_collection(conn)
                items = list(
                    collection.search_items(
                        {"service": _KEYRING_SERVICE, "username": _KEYRING_USERNAME}
                    )
                )
                if not items:
                    return None
                secret_bytes = items[0].get_secret()
                return json.loads(secret_bytes.decode())  # type: ignore[no-any-return]
        except SecretServiceNotAvailableException as exc:
            raise RuntimeError(f"Secret Service unavailable: {exc}") from exc
        except LockedException as exc:
            raise RuntimeError(
                f"Secret Service unavailable: keyring is locked: {exc}"
            ) from exc

    def _save_to_keyring(self, tokens: dict[str, Any]) -> None:
        """Save tokens to the Secret Service keyring.

        Args:
            tokens: Token dict to persist (access_token, refresh_token, etc.).

        Raises:
            RuntimeError: If the Secret Service is unavailable or the keyring is locked.
        """
        try:
            with contextlib.closing(secretstorage.dbus_init()) as conn:
                collection = secretstorage.get_default_collection(conn)
                secret_bytes = json.dumps(tokens).encode()
                collection.create_item(
                    _KEYRING_LABEL,
                    {"service": _KEYRING_SERVICE, "username": _KEYRING_USERNAME},
                    secret_bytes,
                    replace=True,
                )
        except SecretServiceNotAvailableException as exc:
            raise RuntimeError(f"Secret Service unavailable: {exc}") from exc
        except LockedException as exc:
            raise RuntimeError(
                f"Secret Service unavailable: keyring is locked: {exc}"
            ) from exc

    def load_credentials(self) -> dict[str, Any] | None:
        """Load stored credentials from the configured backend.

        Returns:
            Parsed credentials dict, or None if no credentials are stored.
        """
        if self._use_keyring:
            return self._load_from_keyring()
        return self._load_from_file()

    def save_credentials(self, tokens: dict[str, Any]) -> None:
        """Save tokens to the configured backend.

        Args:
            tokens: Token dict to persist (access_token, refresh_token, etc.).
        """
        if self._use_keyring:
            self._save_to_keyring(tokens)
        else:
            self._save_to_file(tokens)

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


def _authenticate_and_setup(
    auth: ScpAuth | None,
    client: ScpApiClient | None,
    user_id: int | None,
    use_keyring: bool = False,
) -> tuple[ScpAuth, ScpApiClient, int]:
    """Authenticate with SCP and return a ready-to-use auth, client, and user ID.

    When all three arguments are already provided, they are returned unchanged.
    When any is missing, a fresh authentication flow is performed for all three.

    Args:
        auth: Existing ScpAuth instance, or None to create one.
        client: Existing ScpApiClient instance, or None to create one.
        user_id: Known SCP user ID, or None to fetch from the userinfo endpoint.
        use_keyring: Pass to ScpAuth when creating a new instance.

    Returns:
        Tuple of (auth, client, user_id) ready for API calls.
    """
    if auth is None or client is None or user_id is None:
        _auth = ScpAuth(use_keyring=use_keyring)
        access_token = _auth.get_access_token()
        _user_id = _auth.get_user_id(access_token)
        _client = ScpApiClient(access_token)
        return _auth, _client, _user_id
    return auth, client, user_id


def _gather_interface_firewall_state(
    client: ScpApiClient,
    server_id: int,
    interfaces: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    """Fetch and return the current firewall state for each server interface.

    Args:
        client: Authenticated ScpApiClient instance.
        server_id: The numeric server ID.
        interfaces: List of interface dicts as returned by get_interfaces.

    Returns:
        List of dicts with 'mac' and 'firewall' keys for each interface.
    """
    interface_data: list[dict[str, Any]] = []
    for iface in interfaces:
        mac = iface["mac"]
        firewall = client.get_firewall(server_id, mac)
        interface_data.append({"mac": mac, "firewall": firewall})
    return interface_data


def _assemble_backup(
    server_id: int,
    server_name: str,
    interface_data: list[dict[str, Any]],
    policies: list[dict[str, Any]],
    now: datetime,
) -> dict[str, Any]:
    """Assemble a versioned backup dict from current server state.

    Args:
        server_id: The numeric server ID.
        server_name: The server name as it appears in SCP.
        interface_data: Per-interface firewall state (from _gather_interface_firewall_state).
        policies: List of all user firewall policies.
        now: Timestamp for the backup metadata.

    Returns:
        Backup dict with version, timestamp, server, interfaces, and policies keys.
    """
    return {
        "version": 1,
        "timestamp": now.isoformat(),
        "server": {
            "id": server_id,
            "name": server_name,
        },
        "interfaces": interface_data,
        "policies": policies,
    }


def _write_backup_file(
    backup: dict[str, Any],
    backup_dir: str,
    server_name: str,
    now: datetime,
) -> str:
    """Write a backup dict to a timestamped JSON file with 0600 permissions.

    Args:
        backup: Backup data dict to serialize as JSON.
        backup_dir: Directory where the file will be written (created if absent).
        server_name: Server name used to form the filename prefix.
        now: Timestamp used to form the filename suffix.

    Returns:
        Absolute path to the written backup file.
    """
    os.makedirs(backup_dir, mode=0o700, exist_ok=True)
    timestamp_str = now.strftime("%Y%m%d-%H%M%S")
    filename = f"{server_name}-{timestamp_str}.json"
    filepath = os.path.join(backup_dir, filename)
    fd = os.open(filepath, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        json.dump(backup, f, indent=2)
    return filepath


def validate_source_ip(source: str) -> str:
    """Validate and normalize an IPv4 source address to CIDR notation.

    Args:
        source: A bare IPv4 address (e.g. ``"1.2.3.4"``) or IPv4 CIDR
            notation (e.g. ``"10.0.0.0/24"``).

    Returns:
        The source address in CIDR notation. Bare addresses are returned
        with ``/32`` appended.

    Raises:
        ValueError: If *source* is empty, is an IPv6 address, or is not
            a valid IP address or CIDR block.
    """
    if not source:
        raise ValueError("Source IP must not be empty")
    try:
        network = ipaddress.ip_network(source, strict=True)
    except ValueError as exc:
        raise ValueError(f"Invalid IP address: {source}") from exc
    if network.version == 6:
        raise ValueError(f"IPv6 not supported: {source}")
    if "/" not in source:
        return f"{source}/32"
    return str(network)


_REQUIRED_RULE_FIELDS = frozenset(
    {"direction", "protocol", "sourceIp", "destinationPort", "action"}
)


def load_policy_file(path: str) -> dict[str, Any]:
    """Load a firewall policy definition from a JSON file.

    Args:
        path: Path to the JSON policy file.

    Returns:
        Parsed policy dict with name, description, rules.

    Raises:
        FileNotFoundError: If the file does not exist.
        ValueError: If the file contains invalid JSON.
    """
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)  # type: ignore[no-any-return]
    except json.JSONDecodeError as exc:
        raise ValueError(f"Invalid JSON in {path}: {exc}") from exc


def validate_policy_schema(policy: dict[str, Any]) -> None:
    """Validate a firewall policy dict has required fields.

    Args:
        policy: Policy dict to validate.

    Raises:
        ValueError: If required fields are missing.
    """
    if "name" not in policy:
        raise ValueError("Policy missing required field: name")
    if "rules" not in policy:
        raise ValueError("Policy missing required field: rules")
    for i, rule in enumerate(policy["rules"]):
        for field in _REQUIRED_RULE_FIELDS:
            if field not in rule:
                raise ValueError(f"Rule {i} missing required field: {field}")


def _find_policy_by_name(
    client: ScpApiClient, user_id: int, name: str
) -> dict[str, Any] | None:
    """Find a firewall policy by name, returning the first match or None.

    Args:
        client: Authenticated SCP API client.
        user_id: Netcup user ID.
        name: Policy name to search for.

    Returns:
        First matching policy dict, or None if not found.
    """
    for policy in client.list_policies(user_id):
        if policy.get("name") == name:
            return policy
    return None


def _get_current_policy_ids(
    client: ScpApiClient, server_id: int, mac: str
) -> list[int]:
    """Read current userPolicies IDs assigned to a server interface.

    Args:
        client: Authenticated SCP API client.
        server_id: Netcup server ID.
        mac: Network interface MAC address.

    Returns:
        List of currently assigned user policy IDs, or empty list if none.
    """
    firewall_state = client.get_firewall(server_id, mac)
    return list(firewall_state.get("userPolicies", []))


def _find_or_create_lockdown_policy(
    client: ScpApiClient,
    user_id: int,
    server_name: str,
) -> dict[str, Any]:
    """Return the lockdown policy for a server, creating it when absent.

    The lockdown policy is named ``lockdown-<server_name>`` and contains no
    rules, which causes the SCP external firewall to DROP all inbound traffic.

    Args:
        client: Authenticated ScpApiClient instance.
        user_id: The numeric SCP user ID.
        server_name: Server name used to derive the policy name.

    Returns:
        Lockdown policy dict (either an existing one or newly created).
    """
    lockdown_name = f"lockdown-{server_name}"
    existing = _find_policy_by_name(client, user_id, lockdown_name)
    if existing is not None:
        logger.info(
            "Reusing existing lockdown policy '%s' (id: %s)",
            lockdown_name,
            existing["id"],
        )
        return existing
    logger.info(
        "Creating lockdown policy '%s' (empty rules = DROP ALL)...", lockdown_name
    )
    return client.create_policy(user_id, lockdown_name, [])


def _find_or_create_ssh_policy(
    client: ScpApiClient,
    user_id: int,
    server_name: str,
    source_cidr: str,
    port: int,
    server_id: int,
    interfaces: list[dict[str, Any]],
) -> dict[str, Any]:
    """Create a temporary SSH access policy, deleting any stale one first.

    Args:
        client: Authenticated SCP API client.
        user_id: Netcup user ID.
        server_name: Server name for policy naming.
        source_cidr: Source IP in CIDR notation.
        port: Destination SSH port.
        server_id: Netcup server ID (used to unassign stale policy from interfaces).
        interfaces: List of interface dicts (used to unassign stale policy).

    Returns:
        Created policy dict with id, name, rules.
    """
    policy_name = f"ssh-temp-{server_name}"
    existing = _find_policy_by_name(client, user_id, policy_name)
    if existing is not None:
        stale_id = existing["id"]
        logger.info("Deleting stale SSH policy: %s (id=%d)", policy_name, stale_id)
        for iface in interfaces:
            mac = iface["mac"]
            current_ids = _get_current_policy_ids(client, server_id, mac)
            if stale_id in current_ids:
                new_ids = [pid for pid in current_ids if pid != stale_id]
                task_uuid = client.set_firewall(
                    server_id, mac, {"userPolicies": new_ids}
                )
                client.wait_for_task(task_uuid)
        client.delete_policy(user_id, stale_id)
    rules = [
        {
            "direction": "INGRESS",
            "protocol": "TCP",
            "sourceIp": source_cidr,
            "destinationPort": str(port),
            "action": "ACCEPT",
        }
    ]
    return client.create_policy(user_id, policy_name, rules)


def _apply_lockdown_to_interfaces(
    client: ScpApiClient,
    server_id: int,
    interfaces: list[dict[str, Any]],
    lockdown_policy: dict[str, Any],
) -> None:
    """Assign the lockdown policy to every interface and log the resulting state.

    Args:
        client: Authenticated ScpApiClient instance.
        server_id: The numeric server ID.
        interfaces: List of interface dicts as returned by get_interfaces.
        lockdown_policy: Policy dict to assign to each interface.
    """
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


def _load_backup_file(filepath: str) -> dict[str, Any]:
    """Load and parse a backup JSON file, exiting on file or parse errors.

    Args:
        filepath: Path to the JSON backup file.

    Returns:
        Parsed backup dict.

    Raises:
        SystemExit: If the file is missing or contains invalid JSON.
    """
    try:
        with open(filepath) as f:
            return json.load(f)  # type: ignore[no-any-return]
    except FileNotFoundError:
        logger.error("Backup file not found: %s", filepath)
        sys.exit(1)
    except json.JSONDecodeError as e:
        logger.error("Invalid JSON in backup file: %s", e)
        sys.exit(1)


def _validate_backup_structure(backup: dict[str, Any], server_name: str) -> None:
    """Validate backup dict structure and server name match, exiting on violations.

    Checks that all required top-level keys are present, the version is
    supported, the server name matches, and all interface and policy entries
    contain the expected fields.

    Args:
        backup: Parsed backup dict to validate.
        server_name: Expected server name from CLI args.

    Raises:
        SystemExit: If any required key is missing, the version is unsupported,
            the server name mismatches, or interface/policy entries are malformed.
    """
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

    if backup.get("server", {}).get("name") != server_name:
        backup_server = backup.get("server", {}).get("name", "unknown")
        logger.error("Backup is for server '%s', not '%s'", backup_server, server_name)
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


def _restore_policies(
    client: ScpApiClient,
    user_id: int,
    policies: list[dict[str, Any]],
    existing_policies: list[dict[str, Any]],
) -> dict[int, int]:
    """Restore policies from backup, reusing existing ones where names match.

    Args:
        client: Authenticated ScpApiClient instance.
        user_id: The numeric SCP user ID.
        policies: Policy entries from the backup file.
        existing_policies: Currently existing policies on the account.

    Returns:
        Mapping from old policy IDs (as stored in backup) to new policy IDs
        (as assigned by the server after restore).
    """
    existing_by_name = {p["name"]: p for p in existing_policies}
    id_map: dict[int, int] = {}

    for policy in policies:
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

    return id_map


def _reassign_firewall_interfaces(
    client: ScpApiClient,
    server_id: int,
    interfaces_backup: list[dict[str, Any]],
    id_map: dict[int, int],
) -> None:
    """Reassign firewall policies to each interface using the restored ID mapping.

    Args:
        client: Authenticated ScpApiClient instance.
        server_id: The numeric server ID.
        interfaces_backup: Interface entries from the backup file.
        id_map: Mapping from old backup policy IDs to new server-assigned IDs.
    """
    for iface_backup in interfaces_backup:
        mac = iface_backup["mac"]
        old_policy_ids = iface_backup.get("firewall", {}).get("userPolicies", [])
        new_policy_ids = [id_map.get(old_id, old_id) for old_id in old_policy_ids]

        logger.info("Assigning policies %s to interface %s...", new_policy_ids, mac)
        task_uuid = client.set_firewall(
            server_id, mac, {"userPolicies": new_policy_ids}
        )
        client.wait_for_task(task_uuid)


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
    if backup_dir is None:
        backup_dir = os.path.join(
            os.path.expanduser("~"), ".local", "share", "netcup-scp", "backups"
        )

    now = datetime.now(timezone.utc)
    use_keyring = getattr(args, "keyring", False)
    auth, client, user_id = _authenticate_and_setup(
        auth, client, user_id, use_keyring=use_keyring
    )

    server_id = client.find_server(args.server)
    interfaces = client.get_interfaces(server_id)
    interface_data = _gather_interface_firewall_state(client, server_id, interfaces)
    policies = client.list_policies(user_id)

    backup = _assemble_backup(server_id, args.server, interface_data, policies, now)
    filepath = _write_backup_file(backup, backup_dir, args.server, now)

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

    use_keyring = getattr(args, "keyring", False)
    auth, client, user_id = _authenticate_and_setup(
        auth, client, user_id, use_keyring=use_keyring
    )

    logger.info("Creating automatic backup before lockdown...")
    backup_path = cmd_backup(args, auth=auth, client=client, user_id=user_id)

    server_id = client.find_server(args.server)
    interfaces = client.get_interfaces(server_id)
    lockdown_policy = _find_or_create_lockdown_policy(client, user_id, args.server)
    _apply_lockdown_to_interfaces(client, server_id, interfaces, lockdown_policy)

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
    backup = _load_backup_file(args.file)
    _validate_backup_structure(backup, args.server)

    use_keyring = getattr(args, "keyring", False)
    auth, client, user_id = _authenticate_and_setup(
        auth, client, user_id, use_keyring=use_keyring
    )

    server_id = client.find_server(args.server)
    existing_policies = client.list_policies(user_id)
    id_map = _restore_policies(
        client, user_id, backup.get("policies", []), existing_policies
    )
    _reassign_firewall_interfaces(
        client, server_id, backup.get("interfaces", []), id_map
    )

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


def cmd_ssh_open(
    args: argparse.Namespace,
    *,
    backup_dir: str | None = None,
    auth: ScpAuth | None = None,
    client: ScpApiClient | None = None,
    user_id: int | None = None,
) -> None:
    """Open temporary SSH access from a specific source IP.

    Args:
        args: Parsed CLI arguments (requires args.server, args.source,
            args.port, args.yes).
        backup_dir: Directory for the auto-backup file. Defaults to
            ~/.local/share/netcup-scp/backups.
        auth: ScpAuth instance. Created internally if not provided.
        client: ScpApiClient instance. Created internally if not provided.
        user_id: SCP user ID. Fetched internally if not provided.

    Raises:
        SystemExit: If the source IP is invalid.
    """
    try:
        source_cidr = validate_source_ip(args.source)
    except ValueError as exc:
        logger.error("%s", exc)
        sys.exit(1)

    server_name = args.server
    port = args.port

    if not args.yes:
        answer = input(
            f"Open SSH port {port} on {server_name} from {source_cidr}? [y/N] "
        )
        if answer.lower() != "y":
            logger.info("Aborted.")
            return

    use_keyring = getattr(args, "keyring", False)
    auth, client, user_id = _authenticate_and_setup(
        auth, client, user_id, use_keyring=use_keyring
    )

    server_id = client.find_server(server_name)
    interfaces = client.get_interfaces(server_id)

    # Auto-backup before any changes
    cmd_backup(
        args,
        backup_dir=backup_dir,
        auth=auth,
        client=client,
        user_id=user_id,
    )

    ssh_policy = _find_or_create_ssh_policy(
        client, user_id, server_name, source_cidr, port, server_id, interfaces
    )
    ssh_policy_id = ssh_policy["id"]

    for iface in interfaces:
        mac = iface["mac"]
        current_ids = _get_current_policy_ids(client, server_id, mac)
        if ssh_policy_id in current_ids:
            logger.info("SSH policy already assigned to %s — skipping", mac)
            continue
        new_ids = current_ids + [ssh_policy_id]
        task_uuid = client.set_firewall(server_id, mac, {"userPolicies": new_ids})
        client.wait_for_task(task_uuid)

    logger.info(
        "SSH ACCESS OPEN — %s:%d accessible from %s via SCP external firewall",
        server_name,
        port,
        source_cidr,
    )


def cmd_ssh_close(
    args: argparse.Namespace,
    *,
    backup_dir: str | None = None,
    auth: ScpAuth | None = None,
    client: ScpApiClient | None = None,
    user_id: int | None = None,
) -> None:
    """Close temporary SSH access and delete the policy.

    Args:
        args: Parsed CLI arguments (requires args.server).
        backup_dir: Directory for the auto-backup file. Defaults to
            ~/.local/share/netcup-scp/backups.
        auth: ScpAuth instance. Created internally if not provided.
        client: ScpApiClient instance. Created internally if not provided.
        user_id: SCP user ID. Fetched internally if not provided.
    """
    use_keyring = getattr(args, "keyring", False)
    auth, client, user_id = _authenticate_and_setup(
        auth, client, user_id, use_keyring=use_keyring
    )
    server_name = args.server

    server_id = client.find_server(server_name)
    interfaces = client.get_interfaces(server_id)

    policy_name = f"ssh-temp-{server_name}"
    ssh_policy = _find_policy_by_name(client, user_id, policy_name)

    if ssh_policy is None:
        logger.info("No SSH policy '%s' found — nothing to close", policy_name)
        return

    ssh_policy_id = ssh_policy["id"]

    # Auto-backup before changes
    cmd_backup(
        args,
        backup_dir=backup_dir,
        auth=auth,
        client=client,
        user_id=user_id,
    )

    # Unassign from all interfaces
    for iface in interfaces:
        mac = iface["mac"]
        current_ids = _get_current_policy_ids(client, server_id, mac)
        if ssh_policy_id not in current_ids:
            continue
        new_ids = [pid for pid in current_ids if pid != ssh_policy_id]
        task_uuid = client.set_firewall(server_id, mac, {"userPolicies": new_ids})
        client.wait_for_task(task_uuid)

    # Delete the temporary policy
    client.delete_policy(user_id, ssh_policy_id)

    logger.info("SSH ACCESS CLOSED — policy '%s' removed and deleted", policy_name)


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
    parser.add_argument(
        "--keyring",
        action="store_true",
        default=False,
        help=(
            "Store/retrieve credentials via gnome-keyring (Secret Service API) "
            "instead of file. Requires secretstorage library."
        ),
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

    # ssh-open subcommand
    ssh_open_parser = subparsers.add_parser(
        "ssh-open",
        help="Open temporary SSH access from a specific source IP",
    )
    ssh_open_parser.add_argument("--server", required=True, help="Server name")
    ssh_open_parser.add_argument(
        "--source", required=True, help="Source IP address (IPv4)"
    )
    ssh_open_parser.add_argument(
        "--port", type=int, default=22, help="SSH port (default: 22)"
    )
    ssh_open_parser.add_argument(
        "--yes", action="store_true", help="Skip confirmation prompt"
    )
    ssh_open_parser.set_defaults(command="ssh-open", func=cmd_ssh_open)

    # ssh-close subcommand
    ssh_close_parser = subparsers.add_parser(
        "ssh-close",
        help="Close temporary SSH access and remove the policy",
    )
    ssh_close_parser.add_argument("--server", required=True, help="Server name")
    ssh_close_parser.set_defaults(command="ssh-close", func=cmd_ssh_close)

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
