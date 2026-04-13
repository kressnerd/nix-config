"""Tests for the netcup-firewall CLI tool.

Covers argument parsing, OIDC authentication (ScpAuth), REST API client
(ScpApiClient), all command handlers (backup, lockdown, restore, apply),
and keyring credential storage via the Secret Service API.
External HTTP calls are fully mocked — no real network access is made.
"""

from __future__ import annotations

import argparse
import json
import logging
import os
from pathlib import Path
from typing import Any
from unittest.mock import MagicMock, mock_open, patch

import pytest

from netcup_firewall import (
    ScpApiClient,
    ScpAuth,
    _find_or_create_ssh_policy,
    _get_current_policy_ids,
    cmd_apply,
    cmd_backup,
    cmd_lockdown,
    cmd_restore,
    cmd_ssh_close,
    cmd_ssh_open,
    load_policy_file,
    main,
    parse_args,
    validate_policy_schema,
    validate_source_ip,
)


class TestArgParsing:
    """Test CLI argument parsing."""

    def test_backup_subcommand(self) -> None:
        """backup subcommand requires --server."""
        args = parse_args(["backup", "--server", "cupix001"])
        assert args.command == "backup"
        assert args.server == "cupix001"

    def test_lockdown_subcommand(self) -> None:
        """lockdown subcommand requires --server."""
        args = parse_args(["lockdown", "--server", "cupix001"])
        assert args.command == "lockdown"
        assert args.server == "cupix001"

    def test_lockdown_yes_flag(self) -> None:
        """lockdown accepts optional --yes flag."""
        args = parse_args(["lockdown", "--server", "cupix001", "--yes"])
        assert args.command == "lockdown"
        assert args.yes is True

    def test_lockdown_no_yes_default(self) -> None:
        """lockdown --yes defaults to False."""
        args = parse_args(["lockdown", "--server", "cupix001"])
        assert args.yes is False

    def test_restore_subcommand(self) -> None:
        """restore subcommand requires --server and --file."""
        args = parse_args(
            ["restore", "--server", "cupix001", "--file", "/tmp/backup.json"]
        )
        assert args.command == "restore"
        assert args.server == "cupix001"
        assert args.file == "/tmp/backup.json"

    def test_apply_subcommand(self) -> None:
        """apply subcommand requires --server and --policy."""
        args = parse_args(["apply", "--server", "cupix001", "--policy", "bootstrap"])
        assert args.command == "apply"
        assert args.server == "cupix001"
        assert args.policy == "bootstrap"

    def test_apply_policy_choices(self) -> None:
        """apply --policy only accepts bootstrap or production."""
        with pytest.raises(SystemExit):
            parse_args(["apply", "--server", "cupix001", "--policy", "invalid"])

    @pytest.mark.parametrize(
        "argv",
        [
            [],
            ["backup"],
            ["restore", "--server", "cupix001"],
        ],
    )
    def test_invalid_args_raise_system_exit(self, argv: list[str]) -> None:
        """Missing required arguments raise SystemExit."""
        with pytest.raises(SystemExit):
            parse_args(argv)

    def test_help_raises_systemexit_0(self) -> None:
        """--help raises SystemExit with code 0."""
        with pytest.raises(SystemExit) as exc_info:
            parse_args(["--help"])
        assert exc_info.value.code == 0

    def test_backup_subcommand_help_raises_systemexit_0(self) -> None:
        """backup --help raises SystemExit with code 0."""
        with pytest.raises(SystemExit) as exc_info:
            parse_args(["backup", "--help"])
        assert exc_info.value.code == 0

    def test_verbose_flag(self) -> None:
        """--verbose flag is accepted at top level."""
        args = parse_args(["--verbose", "backup", "--server", "cupix001"])
        assert args.verbose is True

    def test_quiet_flag(self) -> None:
        """--quiet flag is accepted at top level."""
        args = parse_args(["--quiet", "backup", "--server", "cupix001"])
        assert args.quiet is True

    def test_func_attribute_set(self) -> None:
        """parse_args sets args.func to the appropriate command handler."""
        args = parse_args(["backup", "--server", "cupix001"])
        assert args.func is cmd_backup

    def test_lockdown_func_attribute(self) -> None:
        """parse_args sets args.func to cmd_lockdown for lockdown subcommand."""
        args = parse_args(["lockdown", "--server", "cupix001"])
        assert args.func is cmd_lockdown

    def test_restore_func_attribute(self) -> None:
        """parse_args sets args.func to cmd_restore for restore subcommand."""
        args = parse_args(["restore", "--server", "s", "--file", "f.json"])
        assert args.func is cmd_restore

    def test_ssh_open_requires_server_and_source(self) -> None:
        """ssh-open requires --server and --source arguments."""
        args = parse_args(["ssh-open", "--server", "cupix001", "--source", "1.2.3.4"])
        assert args.command == "ssh-open"
        assert args.server == "cupix001"
        assert args.source == "1.2.3.4"

    def test_ssh_open_default_port(self) -> None:
        """ssh-open defaults to port 22."""
        args = parse_args(["ssh-open", "--server", "cupix001", "--source", "1.2.3.4"])
        assert args.port == 22

    def test_ssh_open_custom_port(self) -> None:
        """ssh-open accepts custom port."""
        args = parse_args(
            [
                "ssh-open",
                "--server",
                "cupix001",
                "--source",
                "1.2.3.4",
                "--port",
                "55809",
            ]
        )
        assert args.port == 55809

    def test_ssh_open_yes_flag(self) -> None:
        """ssh-open accepts --yes flag."""
        args = parse_args(
            ["ssh-open", "--server", "cupix001", "--source", "1.2.3.4", "--yes"]
        )
        assert args.yes is True

    def test_ssh_open_missing_source_exits(self) -> None:
        """ssh-open without --source exits with error."""
        with pytest.raises(SystemExit):
            parse_args(["ssh-open", "--server", "cupix001"])

    def test_ssh_open_missing_server_exits(self) -> None:
        """ssh-open without --server exits with error."""
        with pytest.raises(SystemExit):
            parse_args(["ssh-open", "--source", "1.2.3.4"])

    def test_ssh_close_requires_server(self) -> None:
        """ssh-close requires --server argument."""
        args = parse_args(["ssh-close", "--server", "cupix001"])
        assert args.command == "ssh-close"
        assert args.server == "cupix001"

    def test_ssh_close_missing_server_exits(self) -> None:
        """ssh-close without --server exits with error."""
        with pytest.raises(SystemExit):
            parse_args(["ssh-close"])

    def test_ssh_open_dispatches_to_handler(self) -> None:
        """ssh-open args.func points to cmd_ssh_open."""
        args = parse_args(["ssh-open", "--server", "cupix001", "--source", "1.2.3.4"])
        assert args.func == cmd_ssh_open

    def test_ssh_close_dispatches_to_handler(self) -> None:
        """ssh-close args.func points to cmd_ssh_close."""
        args = parse_args(["ssh-close", "--server", "cupix001"])
        assert args.func == cmd_ssh_close


class TestScpAuth:
    """Test OIDC authentication module."""

    def test_credentials_path(self) -> None:
        """credentials_path returns ~/.config/netcup-scp/credentials.json."""
        auth = ScpAuth()
        assert auth.credentials_path.endswith("netcup-scp/credentials.json")
        assert ".config" in auth.credentials_path

    def test_load_credentials_missing_file(self) -> None:
        """load_credentials returns None when file doesn't exist."""
        auth = ScpAuth()
        with patch("builtins.open", side_effect=FileNotFoundError):
            result = auth.load_credentials()
        assert result is None

    def test_load_credentials_valid_file(self) -> None:
        """load_credentials returns parsed JSON dict."""
        auth = ScpAuth()
        creds: dict[str, str] = {"refresh_token": "rt-123", "access_token": "at-456"}
        with patch("builtins.open", mock_open(read_data=json.dumps(creds))):
            result = auth.load_credentials()
        assert result == creds

    def test_save_credentials(self, tmp_path: Path) -> None:
        """save_credentials writes JSON file with 0600 permissions."""
        auth = ScpAuth()
        creds_file = tmp_path / "netcup-scp" / "credentials.json"
        auth._credentials_path = str(creds_file)
        tokens: dict[str, str] = {"refresh_token": "rt-new", "access_token": "at-new"}
        auth.save_credentials(tokens)
        assert creds_file.exists()
        loaded = json.loads(creds_file.read_text())
        assert loaded == tokens
        mode = creds_file.stat().st_mode & 0o777
        assert mode == 0o600

    @patch("requests.post")
    def test_device_code_flow(self, mock_post: MagicMock) -> None:
        """device_code_flow sends correct POST and returns response."""
        auth = ScpAuth()
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "device_code": "dc-123",
            "user_code": "ABCD-EFGH",
            "verification_uri": "https://example.com/device",
            "interval": 5,
            "expires_in": 600,
        }
        mock_post.return_value = mock_response
        result = auth.device_code_flow()
        assert result["device_code"] == "dc-123"
        assert result["user_code"] == "ABCD-EFGH"
        call_args = mock_post.call_args
        assert "auth/device" in call_args[0][0]
        assert call_args[1]["data"]["client_id"] == "scp"

    @patch("time.sleep")
    @patch("requests.post")
    def test_poll_for_token_success(
        self, mock_post: MagicMock, mock_sleep: MagicMock
    ) -> None:
        """poll_for_token returns tokens on successful auth."""
        auth = ScpAuth()
        pending_resp = MagicMock()
        pending_resp.status_code = 400
        pending_resp.json.return_value = {"error": "authorization_pending"}
        success_resp = MagicMock()
        success_resp.status_code = 200
        success_resp.json.return_value = {
            "access_token": "at-789",
            "refresh_token": "rt-789",
            "token_type": "Bearer",
        }
        mock_post.side_effect = [pending_resp, success_resp]
        result = auth.poll_for_token("dc-123", interval=5, expires_in=600)
        assert result["access_token"] == "at-789"
        assert result["refresh_token"] == "rt-789"

    @patch("time.sleep")
    @patch("requests.post")
    def test_poll_for_token_slow_down(
        self, mock_post: MagicMock, mock_sleep: MagicMock
    ) -> None:
        """poll_for_token handles slow_down by increasing interval."""
        auth = ScpAuth()
        slow_resp = MagicMock()
        slow_resp.status_code = 400
        slow_resp.json.return_value = {"error": "slow_down"}
        success_resp = MagicMock()
        success_resp.status_code = 200
        success_resp.json.return_value = {
            "access_token": "at-slow",
            "refresh_token": "rt-slow",
        }
        mock_post.side_effect = [slow_resp, success_resp]
        result = auth.poll_for_token("dc-123", interval=5, expires_in=600)
        assert result["access_token"] == "at-slow"
        mock_sleep.assert_any_call(10)

    @patch("requests.post")
    def test_refresh_access_token(self, mock_post: MagicMock) -> None:
        """refresh_access_token sends refresh_token grant."""
        auth = ScpAuth()
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "access_token": "at-refreshed",
            "refresh_token": "rt-refreshed",
        }
        mock_post.return_value = mock_response
        result = auth.refresh_access_token("rt-old")
        assert result["access_token"] == "at-refreshed"
        call_args = mock_post.call_args
        assert call_args[1]["data"]["grant_type"] == "refresh_token"
        assert call_args[1]["data"]["refresh_token"] == "rt-old"

    @patch("requests.get")
    def test_get_user_id(self, mock_get: MagicMock) -> None:
        """get_user_id calls userinfo endpoint and returns integer id."""
        auth = ScpAuth()
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"id": 42, "sub": "user-uuid"}
        mock_get.return_value = mock_response
        result = auth.get_user_id("at-valid")
        assert result == 42
        call_args = mock_get.call_args
        assert "userinfo" in call_args[0][0]

    def test_get_access_token_with_stored_refresh(self) -> None:
        """get_access_token uses stored refresh token when available."""
        auth = ScpAuth()
        auth.load_credentials = MagicMock(return_value={"refresh_token": "rt-stored"})  # type: ignore[method-assign]
        auth.refresh_access_token = MagicMock(  # type: ignore[method-assign]
            return_value={
                "access_token": "at-new",
                "refresh_token": "rt-new",
            }
        )
        auth.save_credentials = MagicMock()  # type: ignore[method-assign]
        result = auth.get_access_token()
        assert result == "at-new"
        auth.refresh_access_token.assert_called_once_with("rt-stored")
        auth.save_credentials.assert_called_once()


class TestScpApiClient:
    """Test SCP REST API client."""

    def test_find_server(self) -> None:
        """find_server returns server ID by name."""
        client = ScpApiClient("fake-token")
        with patch.object(client._session, "get") as mock_get:
            mock_resp = MagicMock()
            mock_resp.status_code = 200
            mock_resp.json.return_value = [{"id": 12345, "name": "cupix001"}]
            mock_get.return_value = mock_resp
            result = client.find_server("cupix001")
        assert result == 12345

    def test_find_server_not_found(self) -> None:
        """find_server raises ValueError when server not found."""
        client = ScpApiClient("fake-token")
        with patch.object(client._session, "get") as mock_get:
            mock_resp = MagicMock()
            mock_resp.status_code = 200
            mock_resp.json.return_value = []
            mock_get.return_value = mock_resp
            with pytest.raises(ValueError, match="not found"):
                client.find_server("nonexistent")

    def test_get_interfaces(self) -> None:
        """get_interfaces returns list of interface dicts."""
        client = ScpApiClient("fake-token")
        with patch.object(client._session, "get") as mock_get:
            mock_resp = MagicMock()
            mock_resp.status_code = 200
            mock_resp.json.return_value = [
                {"mac": "aa:bb:cc:dd:ee:ff", "type": "public"}
            ]
            mock_get.return_value = mock_resp
            result = client.get_interfaces(12345)
        assert len(result) == 1
        assert result[0]["mac"] == "aa:bb:cc:dd:ee:ff"

    def test_get_firewall(self) -> None:
        """get_firewall returns firewall state dict."""
        client = ScpApiClient("fake-token")
        with patch.object(client._session, "get") as mock_get:
            mock_resp = MagicMock()
            mock_resp.status_code = 200
            mock_resp.json.return_value = {
                "userPolicies": [1],
                "copiedPolicies": [],
                "ingressImplicitRule": "DROP",
                "egressImplicitRule": "DROP",
                "consistent": True,
                "active": True,
            }
            mock_get.return_value = mock_resp
            result = client.get_firewall(12345, "aa:bb:cc:dd:ee:ff")
        assert result["active"] is True
        assert result["ingressImplicitRule"] == "DROP"

    def test_set_firewall(self) -> None:
        """set_firewall PUTs ServerFirewallSave payload and returns task UUID."""
        client = ScpApiClient("fake-token")
        with patch.object(client, "_put") as mock_put:
            mock_resp = MagicMock()
            mock_resp.json.return_value = {"uuid": "task-uuid-123"}
            mock_put.return_value = mock_resp
            result = client.set_firewall(12345, "aa:bb:cc:dd:ee:ff", [99])
        assert result == "task-uuid-123"
        mock_put.assert_called_once_with(
            "/servers/12345/interfaces/aa:bb:cc:dd:ee:ff/firewall",
            {"userPolicies": [{"id": 99}], "copiedPolicies": []},
        )

    def test_set_firewall_sends_server_firewall_save_format(self) -> None:
        """set_firewall builds ServerFirewallSave payload with IdentifierInt wrapping."""
        client = ScpApiClient("fake-token")
        with patch.object(client, "_put") as mock_put:
            mock_resp = MagicMock()
            mock_resp.json.return_value = {"uuid": "task-uuid-123"}
            mock_put.return_value = mock_resp
            client.set_firewall(
                server_id=123, mac="aa:bb:cc:dd:ee:ff", policy_ids=[42, 99]
            )
        mock_put.assert_called_once_with(
            "/servers/123/interfaces/aa:bb:cc:dd:ee:ff/firewall",
            {
                "userPolicies": [{"id": 42}, {"id": 99}],
                "copiedPolicies": [],
            },
        )

    def test_list_policies(self) -> None:
        """list_policies returns list of policy dicts."""
        client = ScpApiClient("fake-token")
        with patch.object(client._session, "get") as mock_get:
            mock_resp = MagicMock()
            mock_resp.status_code = 200
            mock_resp.json.return_value = [
                {"id": 1, "name": "my-policy", "rules": []},
                {"id": 2, "name": "other-policy", "rules": []},
            ]
            mock_get.return_value = mock_resp
            result = client.list_policies(42)
        assert len(result) == 2

    def test_get_policy(self) -> None:
        """get_policy returns single policy dict."""
        client = ScpApiClient("fake-token")
        with patch.object(client._session, "get") as mock_get:
            mock_resp = MagicMock()
            mock_resp.status_code = 200
            mock_resp.json.return_value = {"id": 1, "name": "my-policy", "rules": []}
            mock_get.return_value = mock_resp
            result = client.get_policy(42, 1)
        assert result["name"] == "my-policy"

    def test_create_policy(self) -> None:
        """create_policy POSTs and returns created policy."""
        client = ScpApiClient("fake-token")
        with patch.object(client._session, "post") as mock_post:
            mock_resp = MagicMock()
            mock_resp.status_code = 201
            mock_resp.json.return_value = {"id": 99, "name": "lockdown", "rules": []}
            mock_post.return_value = mock_resp
            result = client.create_policy(42, "lockdown", [])
        assert result["id"] == 99
        assert result["name"] == "lockdown"

    def test_delete_policy(self) -> None:
        """delete_policy sends DELETE request."""
        client = ScpApiClient("fake-token")
        with patch.object(client._session, "delete") as mock_delete:
            mock_resp = MagicMock()
            mock_resp.status_code = 200
            mock_delete.return_value = mock_resp
            client.delete_policy(42, 99)
        mock_delete.assert_called_once()

    @patch("time.sleep")
    def test_wait_for_task_success(self, mock_sleep: MagicMock) -> None:
        """wait_for_task polls until COMPLETED."""
        client = ScpApiClient("fake-token")
        with patch.object(client._session, "get") as mock_get:
            running_resp = MagicMock()
            running_resp.status_code = 200
            running_resp.json.return_value = {"status": "RUNNING"}
            completed_resp = MagicMock()
            completed_resp.status_code = 200
            completed_resp.json.return_value = {"status": "COMPLETED"}
            mock_get.side_effect = [running_resp, completed_resp]
            client.wait_for_task("task-uuid-123")

    @patch("time.sleep")
    def test_wait_for_task_timeout(self, mock_sleep: MagicMock) -> None:
        """wait_for_task raises TimeoutError after max polls."""
        client = ScpApiClient("fake-token")
        with patch.object(client._session, "get") as mock_get:
            running_resp = MagicMock()
            running_resp.status_code = 200
            running_resp.json.return_value = {"status": "RUNNING"}
            mock_get.return_value = running_resp
            with pytest.raises(TimeoutError):
                client.wait_for_task("task-uuid-123", max_polls=3, interval=0)


class TestBackupCommand:
    """Test backup subcommand."""

    def _mock_setup(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
    ) -> tuple[MagicMock, MagicMock]:
        """Set up standard auth/client mocks for backup tests."""
        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "at-test"
        mock_auth.get_user_id.return_value = 42
        mock_client = MockClient.return_value
        mock_client.find_server.return_value = 12345
        mock_client.get_interfaces.return_value = [
            {"mac": "aa:bb:cc:dd:ee:ff", "type": "public"}
        ]
        mock_client.get_firewall.return_value = {
            "userPolicies": [
                {"id": 1, "name": "default-policy", "description": None, "rules": []}
            ],
            "copiedPolicies": [],
            "ingressImplicitRule": "DROP",
            "egressImplicitRule": "DROP",
            "consistent": True,
            "active": True,
        }
        mock_client.list_policies.return_value = []
        return mock_auth, mock_client

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_backup_calls_api_methods(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        tmp_path: Path,
    ) -> None:
        """backup calls find_server, get_interfaces, get_firewall, list_policies."""
        mock_auth, mock_client = self._mock_setup(MockAuth, MockClient)
        mock_client.list_policies.return_value = [{"id": 1, "name": "my-policy"}]
        mock_client.get_policy.return_value = {
            "id": 1,
            "name": "my-policy",
            "rules": [
                {
                    "direction": "INGRESS",
                    "protocol": "TCP",
                    "destinationPort": "22",
                    "action": "ACCEPT",
                }
            ],
        }

        args = argparse.Namespace(server="cupix001", command="backup")
        cmd_backup(args, backup_dir=str(tmp_path))

        mock_client.find_server.assert_called_once_with("cupix001")
        mock_client.get_interfaces.assert_called_once_with(12345)
        mock_client.get_firewall.assert_called_once()
        mock_client.list_policies.assert_called_once_with(42)
        mock_client.get_policy.assert_called_once_with(42, 1)

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_backup_writes_valid_json(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        tmp_path: Path,
    ) -> None:
        """backup writes a valid JSON file."""
        self._mock_setup(MockAuth, MockClient)

        args = argparse.Namespace(server="cupix001", command="backup")
        backup_path = cmd_backup(args, backup_dir=str(tmp_path))

        assert os.path.exists(backup_path)
        with open(backup_path) as f:
            data = json.load(f)
        assert data["version"] == 1
        assert "timestamp" in data
        assert data["server"]["id"] == 12345
        assert data["server"]["name"] == "cupix001"

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_backup_includes_interfaces_and_firewall(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        tmp_path: Path,
    ) -> None:
        """backup JSON includes interface firewall state."""
        _, mock_client = self._mock_setup(MockAuth, MockClient)
        firewall_state: dict[str, Any] = {
            "userPolicies": [
                {"id": 1, "name": "policy-a", "description": None, "rules": []},
                {"id": 2, "name": "policy-b", "description": None, "rules": []},
            ],
            "copiedPolicies": [],
            "ingressImplicitRule": "DROP",
            "egressImplicitRule": "DROP",
            "consistent": True,
            "active": True,
        }
        mock_client.get_firewall.return_value = firewall_state
        mock_client.list_policies.return_value = [
            {"id": 1, "name": "policy-a"},
            {"id": 2, "name": "policy-b"},
        ]
        mock_client.get_policy.side_effect = [
            {"id": 1, "name": "policy-a", "rules": []},
            {"id": 2, "name": "policy-b", "rules": []},
        ]

        args = argparse.Namespace(server="cupix001", command="backup")
        backup_path = cmd_backup(args, backup_dir=str(tmp_path))

        with open(backup_path) as f:
            data = json.load(f)
        assert len(data["interfaces"]) == 1
        assert data["interfaces"][0]["mac"] == "aa:bb:cc:dd:ee:ff"
        assert data["interfaces"][0]["firewall"] == firewall_state
        assert len(data["policies"]) == 2

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_backup_creates_directory(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        tmp_path: Path,
    ) -> None:
        """backup creates backup directory if it doesn't exist."""
        _, mock_client = self._mock_setup(MockAuth, MockClient)
        mock_client.get_interfaces.return_value = []

        nested_dir = str(tmp_path / "sub" / "dir")
        args = argparse.Namespace(server="cupix001", command="backup")
        backup_path = cmd_backup(args, backup_dir=nested_dir)

        assert os.path.exists(backup_path)
        assert os.path.isdir(nested_dir)

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_backup_filename_format(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        tmp_path: Path,
    ) -> None:
        """backup filename contains server name and timestamp."""
        _, mock_client = self._mock_setup(MockAuth, MockClient)
        mock_client.get_interfaces.return_value = []

        args = argparse.Namespace(server="cupix001", command="backup")
        backup_path = cmd_backup(args, backup_dir=str(tmp_path))

        filename = os.path.basename(backup_path)
        assert filename.startswith("cupix001-")
        assert filename.endswith(".json")

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_backup_uses_di_auth_client(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        tmp_path: Path,
    ) -> None:
        """backup uses injected auth/client without creating new ones."""
        injected_auth = MagicMock(spec=ScpAuth)
        injected_client = MagicMock(spec=ScpApiClient)
        injected_client.find_server.return_value = 99999
        injected_client.get_interfaces.return_value = []
        injected_client.list_policies.return_value = []

        args = argparse.Namespace(server="myserver", command="backup")
        cmd_backup(
            args,
            backup_dir=str(tmp_path),
            auth=injected_auth,
            client=injected_client,
            user_id=7,
        )

        MockAuth.assert_not_called()
        MockClient.assert_not_called()
        injected_client.find_server.assert_called_once_with("myserver")
        injected_client.list_policies.assert_called_once_with(7)

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_backup_fetches_full_policy_details(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        tmp_path: Path,
    ) -> None:
        """backup stores full policy details including rules.

        list_policies() returns only summary data (id, name) without rules.
        cmd_backup must call get_policy() for each policy to fetch full details.
        """
        _, mock_client = self._mock_setup(MockAuth, MockClient)
        mock_client.list_policies.return_value = [{"id": 1, "name": "my-policy"}]
        mock_client.get_policy.return_value = {
            "id": 1,
            "name": "my-policy",
            "rules": [
                {
                    "direction": "INGRESS",
                    "protocol": "TCP",
                    "sourceIp": "0.0.0.0/0",
                    "destinationPort": "443",
                    "action": "ACCEPT",
                }
            ],
        }

        args = argparse.Namespace(server="cupix001", command="backup")
        backup_path = cmd_backup(args, backup_dir=str(tmp_path))

        with open(backup_path) as f:
            data = json.load(f)

        assert len(data["policies"]) == 1
        policy = data["policies"][0]
        assert "rules" in policy, (
            "backup must include full policy rules, not just summary"
        )
        assert len(policy["rules"]) == 1
        assert policy["rules"][0]["direction"] == "INGRESS"


class TestLockdownCommand:
    """Test lockdown (kill switch) subcommand."""

    def _make_mock_setup(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
    ) -> tuple[MagicMock, MagicMock]:
        """Set up common mocks for lockdown tests."""
        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "at-test"
        mock_auth.get_user_id.return_value = 42
        mock_client = MockClient.return_value
        mock_client.find_server.return_value = 12345
        mock_client.get_interfaces.return_value = [
            {"mac": "aa:bb:cc:dd:ee:ff", "type": "public"}
        ]
        mock_client.list_policies.return_value = []
        mock_client.create_policy.return_value = {
            "id": 99,
            "name": "lockdown-cupix001",
            "rules": [],
        }
        mock_client.set_firewall.return_value = "task-uuid-123"
        mock_client.get_firewall.return_value = {
            "userPolicies": [
                {
                    "id": 99,
                    "name": "lockdown-cupix001",
                    "description": None,
                    "rules": [],
                }
            ],
            "copiedPolicies": [],
            "ingressImplicitRule": "DROP",
            "egressImplicitRule": "DROP",
            "consistent": True,
            "active": True,
        }
        return mock_auth, mock_client

    @patch("netcup_firewall.cmd_backup")
    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_lockdown_creates_auto_backup(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        mock_backup: MagicMock,
        tmp_path: Path,
    ) -> None:
        """lockdown creates automatic backup before lockdown."""
        self._make_mock_setup(MockAuth, MockClient)
        mock_backup.return_value = str(tmp_path / "backup.json")

        args = argparse.Namespace(server="cupix001", command="lockdown", yes=True)
        cmd_lockdown(args)

        mock_backup.assert_called_once()

    @patch("netcup_firewall.cmd_backup")
    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_lockdown_creates_empty_policy(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        mock_backup: MagicMock,
        tmp_path: Path,
    ) -> None:
        """lockdown creates policy with empty rules (DROP ALL)."""
        _, mock_client = self._make_mock_setup(MockAuth, MockClient)
        mock_backup.return_value = str(tmp_path / "backup.json")

        args = argparse.Namespace(server="cupix001", command="lockdown", yes=True)
        cmd_lockdown(args)

        mock_client.create_policy.assert_called_once_with(42, "lockdown-cupix001", [])

    @patch("netcup_firewall.cmd_backup")
    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_lockdown_reuses_existing_policy(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        mock_backup: MagicMock,
        tmp_path: Path,
    ) -> None:
        """lockdown reuses existing lockdown policy instead of creating new one."""
        _, mock_client = self._make_mock_setup(MockAuth, MockClient)
        mock_client.list_policies.return_value = [
            {"id": 77, "name": "lockdown-cupix001", "rules": []},
            {"id": 1, "name": "other-policy", "rules": [{"direction": "INGRESS"}]},
        ]
        mock_backup.return_value = str(tmp_path / "backup.json")

        args = argparse.Namespace(server="cupix001", command="lockdown", yes=True)
        cmd_lockdown(args)

        mock_client.create_policy.assert_not_called()
        mock_client.set_firewall.assert_called_once()
        call_args = mock_client.set_firewall.call_args
        assert 77 in call_args[0][2]

    @patch("netcup_firewall.cmd_backup")
    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_lockdown_assigns_policy_to_interface(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        mock_backup: MagicMock,
        tmp_path: Path,
    ) -> None:
        """lockdown assigns lockdown policy to server interface."""
        _, mock_client = self._make_mock_setup(MockAuth, MockClient)
        mock_backup.return_value = str(tmp_path / "backup.json")

        args = argparse.Namespace(server="cupix001", command="lockdown", yes=True)
        cmd_lockdown(args)

        mock_client.set_firewall.assert_called_once_with(
            12345, "aa:bb:cc:dd:ee:ff", [99]
        )

    @patch("netcup_firewall.cmd_backup")
    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_lockdown_waits_for_task(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        mock_backup: MagicMock,
        tmp_path: Path,
    ) -> None:
        """lockdown waits for firewall assignment task to complete."""
        _, mock_client = self._make_mock_setup(MockAuth, MockClient)
        mock_backup.return_value = str(tmp_path / "backup.json")

        args = argparse.Namespace(server="cupix001", command="lockdown", yes=True)
        cmd_lockdown(args)

        mock_client.wait_for_task.assert_called_once_with("task-uuid-123")

    @patch("netcup_firewall.cmd_backup")
    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_lockdown_verifies_state(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        mock_backup: MagicMock,
        tmp_path: Path,
    ) -> None:
        """lockdown verifies firewall state after assignment."""
        _, mock_client = self._make_mock_setup(MockAuth, MockClient)
        mock_backup.return_value = str(tmp_path / "backup.json")

        args = argparse.Namespace(server="cupix001", command="lockdown", yes=True)
        cmd_lockdown(args)

        mock_client.get_firewall.assert_called_with(12345, "aa:bb:cc:dd:ee:ff")

    @patch("builtins.input", return_value="n")
    @patch("netcup_firewall.cmd_backup")
    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_lockdown_aborts_without_yes(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        mock_backup: MagicMock,
        mock_input: MagicMock,
        caplog: pytest.LogCaptureFixture,
    ) -> None:
        """lockdown aborts when user says no to confirmation."""
        self._make_mock_setup(MockAuth, MockClient)

        args = argparse.Namespace(server="cupix001", command="lockdown", yes=False)
        with caplog.at_level(logging.ERROR), pytest.raises(SystemExit) as exc_info:
            cmd_lockdown(args)
        assert exc_info.value.code == 1
        assert "aborted" in caplog.text.lower()

    @patch("builtins.input", return_value="y")
    @patch("netcup_firewall.cmd_backup")
    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_lockdown_proceeds_with_yes_input(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        mock_backup: MagicMock,
        mock_input: MagicMock,
        tmp_path: Path,
    ) -> None:
        """lockdown proceeds when user confirms with 'y'."""
        _, mock_client = self._make_mock_setup(MockAuth, MockClient)
        mock_backup.return_value = str(tmp_path / "backup.json")

        args = argparse.Namespace(server="cupix001", command="lockdown", yes=False)
        cmd_lockdown(args)

        mock_client.set_firewall.assert_called_once()

    @patch("netcup_firewall.cmd_backup")
    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_lockdown_uses_di_params(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        mock_backup: MagicMock,
        tmp_path: Path,
    ) -> None:
        """lockdown uses injected auth/client/user_id without re-authenticating."""
        injected_auth = MagicMock(spec=ScpAuth)
        injected_client = MagicMock(spec=ScpApiClient)
        injected_client.find_server.return_value = 555
        injected_client.get_interfaces.return_value = [{"mac": "00:11:22:33:44:55"}]
        injected_client.list_policies.return_value = []
        injected_client.create_policy.return_value = {
            "id": 10,
            "name": "lockdown-s",
            "rules": [],
        }
        injected_client.set_firewall.return_value = "uuid-x"
        injected_client.get_firewall.return_value = {"active": True}
        mock_backup.return_value = str(tmp_path / "backup.json")

        args = argparse.Namespace(server="s", command="lockdown", yes=True)
        cmd_lockdown(args, auth=injected_auth, client=injected_client, user_id=5)

        MockAuth.assert_not_called()
        MockClient.assert_not_called()
        injected_client.find_server.assert_called_once_with("s")


class TestRestoreCommand:
    """Test restore subcommand."""

    def _make_backup_file(
        self,
        tmp_path: Path,
        server_name: str = "cupix001",
        version: int = 1,
    ) -> str:
        """Create a valid backup JSON file and return its path."""
        backup: dict[str, Any] = {
            "version": version,
            "timestamp": "2026-04-11T15:00:00+00:00",
            "server": {"id": 12345, "name": server_name},
            "interfaces": [
                {
                    "mac": "aa:bb:cc:dd:ee:ff",
                    "firewall": {
                        "userPolicies": [1],
                        "copiedPolicies": [],
                        "ingressImplicitRule": "DROP",
                        "egressImplicitRule": "DROP",
                        "consistent": True,
                        "active": True,
                    },
                }
            ],
            "policies": [
                {
                    "id": 1,
                    "name": "my-policy",
                    "rules": [
                        {
                            "direction": "INGRESS",
                            "protocol": "TCP",
                            "sourceIp": "0.0.0.0/0",
                            "destinationPort": "22",
                            "action": "ACCEPT",
                        }
                    ],
                }
            ],
        }
        backup_file = tmp_path / "backup.json"
        backup_file.write_text(json.dumps(backup))
        return str(backup_file)

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_restore_loads_backup(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        tmp_path: Path,
    ) -> None:
        """restore loads and parses backup JSON file."""
        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "at-test"
        mock_auth.get_user_id.return_value = 42
        mock_client = MockClient.return_value
        mock_client.find_server.return_value = 12345
        mock_client.list_policies.return_value = []
        mock_client.create_policy.return_value = {
            "id": 50,
            "name": "my-policy",
            "rules": [],
        }
        mock_client.set_firewall.return_value = "task-uuid"

        backup_file = self._make_backup_file(tmp_path)
        args = argparse.Namespace(
            server="cupix001", command="restore", file=backup_file
        )
        cmd_restore(args)

        mock_client.find_server.assert_called_once_with("cupix001")

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_restore_validates_version(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        tmp_path: Path,
        caplog: pytest.LogCaptureFixture,
    ) -> None:
        """restore rejects backup with wrong version."""
        backup_file = self._make_backup_file(tmp_path, version=99)
        args = argparse.Namespace(
            server="cupix001", command="restore", file=backup_file
        )
        with caplog.at_level(logging.ERROR), pytest.raises(SystemExit) as exc_info:
            cmd_restore(args)
        assert exc_info.value.code == 1
        assert "version" in caplog.text.lower()

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_restore_validates_server_name(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        tmp_path: Path,
        caplog: pytest.LogCaptureFixture,
    ) -> None:
        """restore rejects backup for wrong server."""
        backup_file = self._make_backup_file(tmp_path, server_name="other-server")
        args = argparse.Namespace(
            server="cupix001", command="restore", file=backup_file
        )
        with caplog.at_level(logging.ERROR), pytest.raises(SystemExit) as exc_info:
            cmd_restore(args)
        assert exc_info.value.code == 1
        assert "server" in caplog.text.lower()

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_restore_creates_missing_policies(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        tmp_path: Path,
    ) -> None:
        """restore creates policies that don't exist yet."""
        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "at-test"
        mock_auth.get_user_id.return_value = 42
        mock_client = MockClient.return_value
        mock_client.find_server.return_value = 12345
        mock_client.list_policies.return_value = []
        mock_client.create_policy.return_value = {
            "id": 50,
            "name": "my-policy",
            "rules": [],
        }
        mock_client.set_firewall.return_value = "task-uuid"

        backup_file = self._make_backup_file(tmp_path)
        args = argparse.Namespace(
            server="cupix001", command="restore", file=backup_file
        )
        cmd_restore(args)

        mock_client.create_policy.assert_called_once()
        call_args = mock_client.create_policy.call_args
        assert call_args[0][1] == "my-policy"
        assert len(call_args[0][2]) == 1

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_restore_reuses_existing_policies(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        tmp_path: Path,
    ) -> None:
        """restore reuses policies that already exist by name."""
        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "at-test"
        mock_auth.get_user_id.return_value = 42
        mock_client = MockClient.return_value
        mock_client.find_server.return_value = 12345
        mock_client.list_policies.return_value = [
            {"id": 77, "name": "my-policy", "rules": []}
        ]
        mock_client.set_firewall.return_value = "task-uuid"

        backup_file = self._make_backup_file(tmp_path)
        args = argparse.Namespace(
            server="cupix001", command="restore", file=backup_file
        )
        cmd_restore(args)

        mock_client.create_policy.assert_not_called()

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_restore_assigns_policies_to_interfaces(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        tmp_path: Path,
    ) -> None:
        """restore assigns mapped policies to interfaces."""
        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "at-test"
        mock_auth.get_user_id.return_value = 42
        mock_client = MockClient.return_value
        mock_client.find_server.return_value = 12345
        mock_client.list_policies.return_value = [
            {"id": 77, "name": "my-policy", "rules": []}
        ]
        mock_client.set_firewall.return_value = "task-uuid"

        backup_file = self._make_backup_file(tmp_path)
        args = argparse.Namespace(
            server="cupix001", command="restore", file=backup_file
        )
        cmd_restore(args)

        mock_client.set_firewall.assert_called_once()
        call_args = mock_client.set_firewall.call_args
        assert call_args[0][0] == 12345
        assert call_args[0][1] == "aa:bb:cc:dd:ee:ff"
        assert 77 in call_args[0][2]

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_restore_waits_for_task(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        tmp_path: Path,
    ) -> None:
        """restore waits for firewall assignment task."""
        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "at-test"
        mock_auth.get_user_id.return_value = 42
        mock_client = MockClient.return_value
        mock_client.find_server.return_value = 12345
        mock_client.list_policies.return_value = []
        mock_client.create_policy.return_value = {
            "id": 50,
            "name": "my-policy",
            "rules": [],
        }
        mock_client.set_firewall.return_value = "task-uuid-456"

        backup_file = self._make_backup_file(tmp_path)
        args = argparse.Namespace(
            server="cupix001", command="restore", file=backup_file
        )
        cmd_restore(args)

        mock_client.wait_for_task.assert_called_once_with("task-uuid-456")

    def test_restore_invalid_json(
        self, tmp_path: Path, caplog: pytest.LogCaptureFixture
    ) -> None:
        """restore fails gracefully on invalid JSON."""
        bad_file = tmp_path / "bad.json"
        bad_file.write_text("not valid json {{{")
        args = argparse.Namespace(
            server="cupix001", command="restore", file=str(bad_file)
        )
        with caplog.at_level(logging.ERROR), pytest.raises(SystemExit) as exc_info:
            cmd_restore(args)
        assert exc_info.value.code == 1
        assert "json" in caplog.text.lower()

    def test_restore_missing_file(self, caplog: pytest.LogCaptureFixture) -> None:
        """restore fails gracefully on missing file."""
        args = argparse.Namespace(
            server="cupix001", command="restore", file="/nonexistent/file.json"
        )
        with caplog.at_level(logging.ERROR), pytest.raises(SystemExit) as exc_info:
            cmd_restore(args)
        assert exc_info.value.code == 1
        assert "not found" in caplog.text.lower()

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_restore_uses_di_params(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        tmp_path: Path,
    ) -> None:
        """restore uses injected auth/client/user_id without re-authenticating."""
        injected_auth = MagicMock(spec=ScpAuth)
        injected_client = MagicMock(spec=ScpApiClient)
        injected_client.find_server.return_value = 12345
        injected_client.list_policies.return_value = []
        injected_client.create_policy.return_value = {
            "id": 50,
            "name": "my-policy",
            "rules": [],
        }
        injected_client.set_firewall.return_value = "uuid-y"

        backup_file = self._make_backup_file(tmp_path)
        args = argparse.Namespace(
            server="cupix001", command="restore", file=backup_file
        )
        cmd_restore(args, auth=injected_auth, client=injected_client, user_id=9)

        MockAuth.assert_not_called()
        MockClient.assert_not_called()
        injected_client.find_server.assert_called_once_with("cupix001")


class TestApplyCommand:
    """Test apply subcommand."""

    def test_apply_exits_not_implemented(self) -> None:
        """apply command exits with code 1 (not yet implemented)."""
        args = argparse.Namespace(
            server="cupix001", policy="bootstrap", command="apply"
        )
        with pytest.raises(SystemExit) as exc_info:
            cmd_apply(args)
        assert exc_info.value.code == 1


class TestMain:
    """Test main() entry point dispatch."""

    @patch("netcup_firewall.cmd_backup")
    def test_main_dispatches_via_args_func(self, mock_backup: MagicMock) -> None:
        """main() calls args.func(args) to dispatch the subcommand."""
        mock_backup.return_value = "/tmp/fake-backup.json"
        with patch(
            "sys.argv",
            ["netcup-firewall", "backup", "--server", "cupix001"],
        ):
            try:
                main()
            except Exception:
                pass
        mock_backup.assert_called_once()


class TestErrorPaths:
    """Test error handling and edge cases."""

    @patch("time.sleep")
    @patch("requests.post")
    def test_poll_for_token_timeout(
        self, mock_post: MagicMock, mock_sleep: MagicMock
    ) -> None:
        """poll_for_token raises TimeoutError when device code expires."""
        auth = ScpAuth()
        pending_resp = MagicMock()
        pending_resp.status_code = 400
        pending_resp.json.return_value = {"error": "authorization_pending"}
        mock_post.return_value = pending_resp
        with pytest.raises(TimeoutError):
            auth.poll_for_token("dc-123", interval=1, expires_in=2)

    @patch("time.sleep")
    @patch("requests.post")
    def test_poll_for_token_unknown_error(
        self, mock_post: MagicMock, mock_sleep: MagicMock
    ) -> None:
        """poll_for_token raises RuntimeError on unknown OIDC error."""
        auth = ScpAuth()
        error_resp = MagicMock()
        error_resp.status_code = 400
        error_resp.json.return_value = {"error": "access_denied"}
        mock_post.return_value = error_resp
        with pytest.raises(RuntimeError, match="access_denied"):
            auth.poll_for_token("dc-123", interval=1, expires_in=600)

    @patch("time.sleep")
    def test_wait_for_task_failed(self, mock_sleep: MagicMock) -> None:
        """wait_for_task raises RuntimeError when task fails."""
        client = ScpApiClient("fake-token")
        with patch.object(client._session, "get") as mock_get:
            failed_resp = MagicMock()
            failed_resp.status_code = 200
            failed_resp.json.return_value = {"status": "FAILED"}
            mock_get.return_value = failed_resp
            with pytest.raises(RuntimeError, match="failed"):
                client.wait_for_task("task-uuid")

    @patch("requests.post")
    def test_get_access_token_expired_refresh_falls_back(
        self, mock_post: MagicMock
    ) -> None:
        """get_access_token falls back to device flow when refresh token is expired."""
        import requests as req

        auth = ScpAuth()
        auth.load_credentials = MagicMock(return_value={"refresh_token": "rt-expired"})  # type: ignore[method-assign]
        auth.save_credentials = MagicMock()  # type: ignore[method-assign]

        refresh_resp = MagicMock()
        refresh_resp.status_code = 400
        refresh_resp.raise_for_status.side_effect = req.HTTPError("400 Client Error")

        device_resp = MagicMock()
        device_resp.status_code = 200
        device_resp.json.return_value = {
            "device_code": "dc-new",
            "user_code": "NEW-CODE",
            "verification_uri": "https://example.com/device",
            "interval": 1,
            "expires_in": 10,
        }

        token_resp = MagicMock()
        token_resp.status_code = 200
        token_resp.json.return_value = {
            "access_token": "at-fresh",
            "refresh_token": "rt-fresh",
        }

        mock_post.side_effect = [refresh_resp, device_resp, token_resp]

        result = auth.get_access_token()
        assert result == "at-fresh"
        auth.save_credentials.assert_called()


class TestWorkflow:
    """Test full backup → lockdown → restore workflow."""

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_full_backup_lockdown_restore_cycle(
        self,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        tmp_path: Path,
    ) -> None:
        """Full cycle: backup saves state, lockdown blocks traffic, restore recovers."""
        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "at-test"
        mock_auth.get_user_id.return_value = 42

        mock_client = MockClient.return_value
        mock_client.find_server.return_value = 12345
        mock_client.get_interfaces.return_value = [
            {"mac": "aa:bb:cc:dd:ee:ff", "type": "public"}
        ]

        initial_firewall: dict[str, Any] = {
            "userPolicies": [
                {"id": 1, "name": "production", "description": None, "rules": []}
            ],
            "copiedPolicies": [],
            "ingressImplicitRule": "DROP",
            "egressImplicitRule": "DROP",
            "consistent": True,
            "active": True,
        }
        mock_client.get_firewall.return_value = initial_firewall
        mock_client.list_policies.return_value = [{"id": 1, "name": "production"}]
        mock_client.get_policy.return_value = {
            "id": 1,
            "name": "production",
            "rules": [
                {
                    "direction": "INGRESS",
                    "protocol": "TCP",
                    "destinationPort": "443",
                    "action": "ACCEPT",
                }
            ],
        }
        mock_client.set_firewall.return_value = "task-uuid"

        backup_dir = str(tmp_path / "backups")
        args_backup = argparse.Namespace(server="cupix001", command="backup")
        backup_path = cmd_backup(args_backup, backup_dir=backup_dir)
        assert os.path.exists(backup_path)

        with open(backup_path) as f:
            backup_data = json.load(f)
        assert backup_data["version"] == 1
        assert backup_data["server"]["name"] == "cupix001"
        assert len(backup_data["policies"]) == 1
        assert backup_data["policies"][0]["name"] == "production"

        mock_client.create_policy.return_value = {
            "id": 99,
            "name": "lockdown-cupix001",
            "rules": [],
        }
        mock_client.list_policies.return_value = [
            {"id": 1, "name": "production", "rules": []}
        ]

        with patch(
            "netcup_firewall.cmd_backup",
            return_value=str(tmp_path / "auto-backup.json"),
        ):
            args_lockdown = argparse.Namespace(
                server="cupix001", command="lockdown", yes=True
            )
            cmd_lockdown(args_lockdown)

        mock_client.create_policy.assert_called_with(42, "lockdown-cupix001", [])
        mock_client.set_firewall.assert_called()

        mock_client.list_policies.return_value = [
            {"id": 99, "name": "lockdown-cupix001", "rules": []}
        ]
        mock_client.create_policy.return_value = {
            "id": 50,
            "name": "production",
            "rules": [],
        }

        args_restore = argparse.Namespace(
            server="cupix001", command="restore", file=backup_path
        )
        cmd_restore(args_restore)

        last_set_call = mock_client.set_firewall.call_args
        assert last_set_call[0][1] == "aa:bb:cc:dd:ee:ff"


class TestKeyringCredentials:
    """Test gnome-keyring (Secret Service) credential backend."""

    def test_keyring_flag_parsed(self) -> None:
        """--keyring flag is parsed and set on the namespace."""
        args = parse_args(["--keyring", "backup", "--server", "cupix001"])
        assert args.keyring is True

    def test_keyring_flag_defaults_false(self) -> None:
        """--keyring defaults to False when not supplied."""
        args = parse_args(["backup", "--server", "cupix001"])
        assert args.keyring is False

    def test_keyring_missing_library_raises_error(self) -> None:
        """ScpAuth raises RuntimeError when use_keyring=True but library is missing."""
        import netcup_firewall as nf

        original = nf._HAS_SECRETSTORAGE
        try:
            nf._HAS_SECRETSTORAGE = False
            with pytest.raises(RuntimeError, match="secretstorage"):
                ScpAuth(use_keyring=True)
        finally:
            nf._HAS_SECRETSTORAGE = original

    def test_auth_uses_file_by_default(self, tmp_path: Path) -> None:
        """Without --keyring, load_credentials delegates to _load_from_file."""
        auth = ScpAuth(use_keyring=False)
        auth._load_from_file = MagicMock(return_value={"refresh_token": "rt-file"})  # type: ignore[method-assign]
        auth._load_from_keyring = MagicMock()  # type: ignore[method-assign]
        result = auth.load_credentials()
        auth._load_from_file.assert_called_once()
        auth._load_from_keyring.assert_not_called()
        assert result == {"refresh_token": "rt-file"}

    def test_auth_uses_keyring_when_flag_set(self) -> None:
        """With use_keyring=True, load_credentials delegates to _load_from_keyring."""
        with patch("netcup_firewall._HAS_SECRETSTORAGE", True):
            auth = ScpAuth(use_keyring=True)
        auth._load_from_file = MagicMock()  # type: ignore[method-assign]
        auth._load_from_keyring = MagicMock(return_value={"refresh_token": "rt-kr"})  # type: ignore[method-assign]
        result = auth.load_credentials()
        auth._load_from_keyring.assert_called_once()
        auth._load_from_file.assert_not_called()
        assert result == {"refresh_token": "rt-kr"}

    def test_save_uses_file_by_default(self, tmp_path: Path) -> None:
        """Without --keyring, save_credentials delegates to _save_to_file."""
        auth = ScpAuth(use_keyring=False)
        auth._save_to_file = MagicMock()  # type: ignore[method-assign]
        auth._save_to_keyring = MagicMock()  # type: ignore[method-assign]
        tokens: dict[str, str] = {"access_token": "at", "refresh_token": "rt"}
        auth.save_credentials(tokens)
        auth._save_to_file.assert_called_once_with(tokens)
        auth._save_to_keyring.assert_not_called()

    def test_save_uses_keyring_when_flag_set(self) -> None:
        """With use_keyring=True, save_credentials delegates to _save_to_keyring."""
        with patch("netcup_firewall._HAS_SECRETSTORAGE", True):
            auth = ScpAuth(use_keyring=True)
        auth._save_to_file = MagicMock()  # type: ignore[method-assign]
        auth._save_to_keyring = MagicMock()  # type: ignore[method-assign]
        tokens: dict[str, str] = {"access_token": "at", "refresh_token": "rt"}
        auth.save_credentials(tokens)
        auth._save_to_keyring.assert_called_once_with(tokens)
        auth._save_to_file.assert_not_called()

    def test_keyring_load_returns_tokens(self) -> None:
        """_load_from_keyring returns token dict from Secret Service item."""
        tokens: dict[str, str] = {"access_token": "at-kr", "refresh_token": "rt-kr"}
        secret_bytes = json.dumps(tokens).encode()

        mock_item = MagicMock()
        mock_item.get_secret.return_value = secret_bytes

        mock_collection = MagicMock()
        mock_collection.search_items.return_value = iter([mock_item])

        mock_conn = MagicMock()

        with patch("netcup_firewall._HAS_SECRETSTORAGE", True):
            auth = ScpAuth(use_keyring=True)

        with (
            patch("secretstorage.dbus_init", return_value=mock_conn),
            patch("secretstorage.get_default_collection", return_value=mock_collection),
        ):
            result = auth._load_from_keyring()

        assert result == tokens
        mock_collection.search_items.assert_called_once_with(
            {"service": "netcup-scp", "username": "default"}
        )

    def test_keyring_load_returns_none_when_no_item(self) -> None:
        """_load_from_keyring returns None when no item exists in keyring."""
        mock_collection = MagicMock()
        mock_collection.search_items.return_value = iter([])
        mock_conn = MagicMock()

        with patch("netcup_firewall._HAS_SECRETSTORAGE", True):
            auth = ScpAuth(use_keyring=True)

        with (
            patch("secretstorage.dbus_init", return_value=mock_conn),
            patch("secretstorage.get_default_collection", return_value=mock_collection),
        ):
            result = auth._load_from_keyring()

        assert result is None

    def test_keyring_save_stores_secret(self) -> None:
        """_save_to_keyring calls create_item with correct label and attributes."""
        tokens: dict[str, str] = {"access_token": "at-kr", "refresh_token": "rt-kr"}

        mock_collection = MagicMock()
        mock_conn = MagicMock()

        with patch("netcup_firewall._HAS_SECRETSTORAGE", True):
            auth = ScpAuth(use_keyring=True)

        with (
            patch("secretstorage.dbus_init", return_value=mock_conn),
            patch("secretstorage.get_default_collection", return_value=mock_collection),
        ):
            auth._save_to_keyring(tokens)

        mock_collection.create_item.assert_called_once_with(
            "netcup-scp credentials",
            {"service": "netcup-scp", "username": "default"},
            json.dumps(tokens).encode(),
            replace=True,
        )

    def test_keyring_unavailable_raises_runtime_error(self) -> None:
        """_load_from_keyring raises RuntimeError when SecretServiceNotAvailableException is raised."""
        from secretstorage.exceptions import SecretServiceNotAvailableException

        mock_conn = MagicMock()

        with patch("netcup_firewall._HAS_SECRETSTORAGE", True):
            auth = ScpAuth(use_keyring=True)

        with (
            patch("secretstorage.dbus_init", return_value=mock_conn),
            patch(
                "secretstorage.get_default_collection",
                side_effect=SecretServiceNotAvailableException("no dbus"),
            ),
        ):
            with pytest.raises(RuntimeError, match="Secret Service unavailable"):
                auth._load_from_keyring()


class TestValidateSourceIp:
    """Tests for validate_source_ip() — IPv4 CIDR normalization."""

    def test_bare_ipv4_gets_slash32(self) -> None:
        """Bare IPv4 address gets /32 appended."""
        assert validate_source_ip("1.2.3.4") == "1.2.3.4/32"

    def test_cidr_notation_preserved(self) -> None:
        """IPv4 with CIDR notation is preserved as-is."""
        assert validate_source_ip("10.0.0.0/24") == "10.0.0.0/24"

    def test_slash32_preserved(self) -> None:
        """IPv4 with /32 is preserved."""
        assert validate_source_ip("192.168.1.1/32") == "192.168.1.1/32"

    def test_ipv6_rejected(self) -> None:
        """IPv6 addresses are rejected."""
        with pytest.raises(ValueError, match="IPv6"):
            validate_source_ip("::1")

    def test_ipv6_cidr_rejected(self) -> None:
        """IPv6 CIDR is rejected."""
        with pytest.raises(ValueError, match="IPv6"):
            validate_source_ip("2001:db8::/32")

    def test_invalid_address_rejected(self) -> None:
        """Invalid IP addresses are rejected."""
        with pytest.raises(ValueError):
            validate_source_ip("not-an-ip")

    def test_empty_string_rejected(self) -> None:
        """Empty string is rejected."""
        with pytest.raises(ValueError):
            validate_source_ip("")

    def test_invalid_cidr_prefix_rejected(self) -> None:
        """Invalid CIDR prefix length is rejected."""
        with pytest.raises(ValueError):
            validate_source_ip("1.2.3.4/33")

    def test_mismatched_host_bits_rejected(self) -> None:
        """CIDR with host bits set is rejected (e.g., 10.0.0.5/24)."""
        with pytest.raises(ValueError):
            validate_source_ip("10.0.0.5/24")

    def test_keyring_locked_raises_runtime_error(self) -> None:
        """_load_from_keyring raises RuntimeError when the keyring is locked."""
        from secretstorage.exceptions import LockedException

        mock_collection = MagicMock()
        mock_collection.search_items.side_effect = LockedException("locked")
        mock_conn = MagicMock()

        with patch("netcup_firewall._HAS_SECRETSTORAGE", True):
            auth = ScpAuth(use_keyring=True)

        with (
            patch("secretstorage.dbus_init", return_value=mock_conn),
            patch("secretstorage.get_default_collection", return_value=mock_collection),
        ):
            with pytest.raises(RuntimeError, match="Secret Service unavailable"):
                auth._load_from_keyring()


class TestGetCurrentPolicyIds:
    """Tests for _get_current_policy_ids() — read current userPolicies from interface."""

    def test_returns_policy_ids_from_firewall(self) -> None:
        """Extracts userPolicies IDs from get_firewall response."""
        client = MagicMock(spec=ScpApiClient)
        client.get_interfaces.return_value = [{"mac": "aa:bb:cc:dd:ee:ff"}]
        client.get_firewall.return_value = {
            "userPolicies": [
                {"id": 42, "name": "prod-policy", "description": None, "rules": []},
                {"id": 99, "name": "ssh-policy", "description": None, "rules": []},
            ],
            "copiedPolicies": [],
            "ingressImplicitRule": "DROP",
            "egressImplicitRule": "DROP",
        }
        result = _get_current_policy_ids(client, 123, "aa:bb:cc:dd:ee:ff")
        assert result == [42, 99]
        client.get_firewall.assert_called_once_with(123, "aa:bb:cc:dd:ee:ff")

    def test_returns_empty_list_when_no_policies(self) -> None:
        """Returns empty list when no userPolicies are assigned."""
        client = MagicMock(spec=ScpApiClient)
        client.get_firewall.return_value = {
            "userPolicies": [],
            "copiedPolicies": [],
            "ingressImplicitRule": "DROP",
            "egressImplicitRule": "DROP",
        }
        result = _get_current_policy_ids(client, 123, "aa:bb:cc:dd:ee:ff")
        assert result == []

    def test_handles_missing_user_policies_key(self) -> None:
        """Returns empty list when userPolicies key is missing from response."""
        client = MagicMock(spec=ScpApiClient)
        client.get_firewall.return_value = {
            "copiedPolicies": [],
            "ingressImplicitRule": "DROP",
        }
        result = _get_current_policy_ids(client, 123, "aa:bb:cc:dd:ee:ff")
        assert result == []

    def test_get_current_policy_ids_extracts_ids_from_objects(self) -> None:
        """Extracts integer IDs from full FirewallPolicy objects in userPolicies."""
        client = MagicMock(spec=ScpApiClient)
        client.get_firewall.return_value = {
            "userPolicies": [
                {
                    "id": 42,
                    "name": "prod-policy",
                    "description": None,
                    "rules": [
                        {
                            "id": 1,
                            "action": "ACCEPT",
                            "protocol": "TCP",
                            "srcIp": "0.0.0.0/0",
                            "srcPort": None,
                            "dstIp": None,
                            "dstPort": "443",
                            "direction": "INGRESS",
                            "comment": None,
                        }
                    ],
                },
                {"id": 99, "name": "ssh-policy", "description": None, "rules": []},
            ],
            "copiedPolicies": [],
            "ingressImplicitRule": "DROP_ALL",
            "egressImplicitRule": "ACCEPT_ALL",
            "consistent": True,
            "active": True,
        }
        result = _get_current_policy_ids(client, server_id=123, mac="aa:bb:cc:dd:ee:ff")
        assert result == [42, 99]


class TestFindOrCreateSshPolicy:
    """Tests for _find_or_create_ssh_policy() — create-use-delete temporary SSH policy."""

    def test_creates_new_policy_when_none_exists(self) -> None:
        """Creates ssh-temp-{server} policy when no existing one found."""
        client = MagicMock(spec=ScpApiClient)
        client.list_policies.return_value = []
        client.create_policy.return_value = {
            "id": 777,
            "name": "ssh-temp-cupix001",
            "rules": [
                {
                    "direction": "INGRESS",
                    "protocol": "TCP",
                    "sourceIp": "1.2.3.4/32",
                    "destinationPort": "22",
                    "action": "ACCEPT",
                }
            ],
        }
        result = _find_or_create_ssh_policy(
            client, 42, "cupix001", "1.2.3.4/32", 22, server_id=123, interfaces=[]
        )
        assert result["id"] == 777
        client.create_policy.assert_called_once()
        call_args = client.create_policy.call_args
        assert call_args[0][1] == "ssh-temp-cupix001"
        rules = call_args[0][2]
        assert len(rules) == 1
        assert rules[0]["sourceIp"] == "1.2.3.4/32"
        assert rules[0]["destinationPort"] == "22"

    def test_deletes_stale_policy_and_recreates(self) -> None:
        """If ssh-temp-{server} already exists (stale from crash), deletes and recreates."""
        client = MagicMock(spec=ScpApiClient)
        client.list_policies.return_value = [
            {"id": 555, "name": "ssh-temp-cupix001", "rules": []}
        ]
        client.create_policy.return_value = {
            "id": 888,
            "name": "ssh-temp-cupix001",
            "rules": [
                {
                    "direction": "INGRESS",
                    "protocol": "TCP",
                    "sourceIp": "5.6.7.8/32",
                    "destinationPort": "55809",
                    "action": "ACCEPT",
                }
            ],
        }
        result = _find_or_create_ssh_policy(
            client, 42, "cupix001", "5.6.7.8/32", 55809, server_id=123, interfaces=[]
        )
        assert result["id"] == 888
        client.delete_policy.assert_called_once_with(42, 555)
        client.create_policy.assert_called_once()

    def test_uses_correct_port_in_rule(self) -> None:
        """Destination port in rule matches the port argument."""
        client = MagicMock(spec=ScpApiClient)
        client.list_policies.return_value = []
        client.create_policy.return_value = {
            "id": 999,
            "name": "ssh-temp-cupix001",
            "rules": [],
        }
        _find_or_create_ssh_policy(
            client, 42, "cupix001", "10.0.0.1/32", 55809, server_id=123, interfaces=[]
        )
        call_args = client.create_policy.call_args
        rules = call_args[0][2]
        assert rules[0]["destinationPort"] == "55809"

    def test_unassigns_stale_policy_before_deleting(self) -> None:
        """Stale policy is unassigned from interfaces before deletion."""
        client = MagicMock(spec=ScpApiClient)
        client.list_policies.return_value = [
            {"id": 555, "name": "ssh-temp-cupix001", "rules": []}
        ]
        client.get_firewall.return_value = {
            "userPolicies": [
                {
                    "id": 555,
                    "name": "ssh-temp-cupix001",
                    "description": None,
                    "rules": [],
                },
                {"id": 50, "name": "prod-policy", "description": None, "rules": []},
            ],
            "copiedPolicies": [],
        }
        client.set_firewall.return_value = "task-uuid"
        client.create_policy.return_value = {
            "id": 888,
            "name": "ssh-temp-cupix001",
            "rules": [],
        }

        interfaces = [{"mac": "aa:bb:cc:dd:ee:ff"}]
        _find_or_create_ssh_policy(
            client,
            42,
            "cupix001",
            "5.6.7.8/32",
            55809,
            server_id=123,
            interfaces=interfaces,
        )

        # Should unassign stale policy from interface first
        client.set_firewall.assert_any_call(123, "aa:bb:cc:dd:ee:ff", [50])
        # Then delete
        client.delete_policy.assert_called_once_with(42, 555)


class TestSshOpenCommand:
    """Tests for cmd_ssh_open() — open temporary SSH access."""

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_ssh_open_creates_policy_and_assigns(
        self, MockAuth: MagicMock, MockClient: MagicMock, tmp_path: Any
    ) -> None:
        """ssh-open creates SSH policy and additively assigns to all interfaces."""
        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "token"
        mock_auth.get_user_id.return_value = 42
        mock_client = MockClient.return_value
        mock_client.find_server.return_value = 123
        mock_client.get_interfaces.return_value = [{"mac": "aa:bb:cc:dd:ee:ff"}]
        mock_client.get_firewall.return_value = {
            "userPolicies": [
                {"id": 50, "name": "prod-policy", "description": None, "rules": []}
            ],
            "copiedPolicies": [],
        }
        mock_client.list_policies.return_value = []
        mock_client.create_policy.return_value = {
            "id": 777,
            "name": "ssh-temp-cupix001",
            "rules": [],
        }
        mock_client.set_firewall.return_value = "task-uuid-1"

        args = parse_args(
            [
                "ssh-open",
                "--server",
                "cupix001",
                "--source",
                "1.2.3.4",
                "--port",
                "22",
                "--yes",
            ]
        )
        cmd_ssh_open(
            args,
            backup_dir=str(tmp_path),
            auth=mock_auth,
            client=mock_client,
            user_id=42,
        )

        mock_client.set_firewall.assert_called_once()
        set_fw_call = mock_client.set_firewall.call_args
        policy_ids = set_fw_call[0][2]
        assert 50 in policy_ids
        assert 777 in policy_ids

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_ssh_open_skips_assignment_if_already_assigned(
        self, MockAuth: MagicMock, MockClient: MagicMock, tmp_path: Any
    ) -> None:
        """ssh-open does not duplicate policy ID if already in userPolicies."""
        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "token"
        mock_auth.get_user_id.return_value = 42
        mock_client = MockClient.return_value
        mock_client.find_server.return_value = 123
        mock_client.get_interfaces.return_value = [{"mac": "aa:bb:cc:dd:ee:ff"}]
        mock_client.get_firewall.return_value = {
            "userPolicies": [
                {
                    "id": 777,
                    "name": "ssh-temp-cupix001",
                    "description": None,
                    "rules": [],
                }
            ],
            "copiedPolicies": [],
        }
        mock_client.list_policies.return_value = []
        mock_client.create_policy.return_value = {
            "id": 777,
            "name": "ssh-temp-cupix001",
            "rules": [],
        }
        mock_client.set_firewall.return_value = "task-uuid-1"

        args = parse_args(
            ["ssh-open", "--server", "cupix001", "--source", "1.2.3.4", "--yes"]
        )
        cmd_ssh_open(
            args,
            backup_dir=str(tmp_path),
            auth=mock_auth,
            client=mock_client,
            user_id=42,
        )

        mock_client.set_firewall.assert_not_called()

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_ssh_open_creates_backup_first(
        self, MockAuth: MagicMock, MockClient: MagicMock, tmp_path: Any
    ) -> None:
        """ssh-open creates auto-backup before making changes."""
        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "token"
        mock_auth.get_user_id.return_value = 42
        mock_client = MockClient.return_value
        mock_client.find_server.return_value = 123
        mock_client.get_interfaces.return_value = [{"mac": "aa:bb:cc:dd:ee:ff"}]
        mock_client.get_firewall.return_value = {
            "userPolicies": [],
            "copiedPolicies": [],
        }
        mock_client.list_policies.return_value = []
        mock_client.create_policy.return_value = {
            "id": 777,
            "name": "ssh-temp-cupix001",
            "rules": [],
        }
        mock_client.set_firewall.return_value = "task-uuid-1"

        args = parse_args(
            ["ssh-open", "--server", "cupix001", "--source", "1.2.3.4", "--yes"]
        )
        cmd_ssh_open(
            args,
            backup_dir=str(tmp_path),
            auth=mock_auth,
            client=mock_client,
            user_id=42,
        )

        backup_files = list(tmp_path.glob("*.json"))
        assert len(backup_files) >= 1

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_ssh_open_validates_source_ip(
        self, MockAuth: MagicMock, MockClient: MagicMock, tmp_path: Any
    ) -> None:
        """ssh-open validates the source IP and rejects invalid ones."""
        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "token"
        mock_auth.get_user_id.return_value = 42

        args = parse_args(
            ["ssh-open", "--server", "cupix001", "--source", "not-an-ip", "--yes"]
        )
        with pytest.raises(SystemExit):
            cmd_ssh_open(
                args,
                auth=mock_auth,
                client=MockClient.return_value,
                user_id=42,
            )

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_ssh_open_with_di_skips_auth_setup(
        self, MockAuth: MagicMock, MockClient: MagicMock, tmp_path: Any
    ) -> None:
        """When DI params are passed, ssh-open does not instantiate auth/client."""
        injected_auth = MagicMock(spec=ScpAuth)
        injected_client = MagicMock(spec=ScpApiClient)
        injected_client.find_server.return_value = 123
        injected_client.get_interfaces.return_value = [{"mac": "aa:bb:cc:dd:ee:ff"}]
        injected_client.get_firewall.return_value = {
            "userPolicies": [],
            "copiedPolicies": [],
        }
        injected_client.list_policies.return_value = []
        injected_client.create_policy.return_value = {
            "id": 777,
            "name": "ssh-temp-cupix001",
            "rules": [],
        }
        injected_client.set_firewall.return_value = "task-uuid-1"

        args = parse_args(
            ["ssh-open", "--server", "cupix001", "--source", "1.2.3.4", "--yes"]
        )
        cmd_ssh_open(
            args,
            backup_dir=str(tmp_path),
            auth=injected_auth,
            client=injected_client,
            user_id=7,
        )

        MockAuth.assert_not_called()
        MockClient.assert_not_called()

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    @patch("builtins.input", return_value="n")
    def test_ssh_open_aborts_without_yes(
        self,
        mock_input: MagicMock,
        MockAuth: MagicMock,
        MockClient: MagicMock,
        tmp_path: Any,
    ) -> None:
        """ssh-open aborts when user declines confirmation."""
        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "token"
        mock_auth.get_user_id.return_value = 42

        args = parse_args(["ssh-open", "--server", "cupix001", "--source", "1.2.3.4"])
        cmd_ssh_open(
            args,
            backup_dir=str(tmp_path),
            auth=mock_auth,
            client=MockClient.return_value,
            user_id=42,
        )

        # Should NOT proceed to find_server etc.
        MockClient.return_value.find_server.assert_not_called()


class TestSshCloseCommand:
    """Tests for cmd_ssh_close() — close temporary SSH access."""

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_ssh_close_removes_policy_and_deletes(
        self, MockAuth: MagicMock, MockClient: MagicMock, tmp_path: Any
    ) -> None:
        """ssh-close removes SSH policy from interfaces and deletes it."""
        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "token"
        mock_auth.get_user_id.return_value = 42
        mock_client = MockClient.return_value
        mock_client.find_server.return_value = 123
        mock_client.get_interfaces.return_value = [{"mac": "aa:bb:cc:dd:ee:ff"}]
        mock_client.get_firewall.return_value = {
            "userPolicies": [
                {"id": 50, "name": "prod-policy", "description": None, "rules": []},
                {
                    "id": 777,
                    "name": "ssh-temp-cupix001",
                    "description": None,
                    "rules": [],
                },
            ],  # 777 is the SSH policy
            "copiedPolicies": [],
        }
        mock_client.list_policies.return_value = [
            {"id": 777, "name": "ssh-temp-cupix001"}
        ]
        mock_client.get_policy.return_value = {
            "id": 777,
            "name": "ssh-temp-cupix001",
            "rules": [],
        }
        mock_client.set_firewall.return_value = "task-uuid-1"

        args = parse_args(["ssh-close", "--server", "cupix001"])
        cmd_ssh_close(
            args,
            backup_dir=str(tmp_path),
            auth=mock_auth,
            client=mock_client,
            user_id=42,
        )

        # Should set firewall WITHOUT the SSH policy (keep policy 50)
        mock_client.set_firewall.assert_called_once()
        set_fw_call = mock_client.set_firewall.call_args
        policy_ids = set_fw_call[0][2]
        assert 777 not in policy_ids
        assert 50 in policy_ids

        # Should delete the SSH policy
        mock_client.delete_policy.assert_called_once_with(42, 777)

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_ssh_close_no_policy_found(
        self, MockAuth: MagicMock, MockClient: MagicMock, tmp_path: Any
    ) -> None:
        """ssh-close when no ssh-temp-{server} policy exists logs info and exits cleanly."""
        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "token"
        mock_auth.get_user_id.return_value = 42
        mock_client = MockClient.return_value
        mock_client.find_server.return_value = 123
        mock_client.get_interfaces.return_value = [{"mac": "aa:bb:cc:dd:ee:ff"}]
        mock_client.list_policies.return_value = []  # no SSH policy

        args = parse_args(["ssh-close", "--server", "cupix001"])
        # Should not raise, just log and return
        cmd_ssh_close(
            args,
            backup_dir=str(tmp_path),
            auth=mock_auth,
            client=mock_client,
            user_id=42,
        )

        mock_client.set_firewall.assert_not_called()
        mock_client.delete_policy.assert_not_called()

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_ssh_close_policy_exists_but_not_assigned(
        self, MockAuth: MagicMock, MockClient: MagicMock, tmp_path: Any
    ) -> None:
        """ssh-close when policy exists but is not assigned to any interface still deletes it."""
        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "token"
        mock_auth.get_user_id.return_value = 42
        mock_client = MockClient.return_value
        mock_client.find_server.return_value = 123
        mock_client.get_interfaces.return_value = [{"mac": "aa:bb:cc:dd:ee:ff"}]
        mock_client.get_firewall.return_value = {
            "userPolicies": [
                {"id": 50, "name": "prod-policy", "description": None, "rules": []}
            ],  # SSH policy NOT in list
            "copiedPolicies": [],
        }
        mock_client.list_policies.return_value = [
            {"id": 777, "name": "ssh-temp-cupix001"}
        ]
        mock_client.get_policy.return_value = {
            "id": 777,
            "name": "ssh-temp-cupix001",
            "rules": [],
        }

        args = parse_args(["ssh-close", "--server", "cupix001"])
        cmd_ssh_close(
            args,
            backup_dir=str(tmp_path),
            auth=mock_auth,
            client=mock_client,
            user_id=42,
        )

        # Should NOT call set_firewall (nothing to unassign)
        mock_client.set_firewall.assert_not_called()
        # Should still delete the orphaned policy
        mock_client.delete_policy.assert_called_once_with(42, 777)

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_ssh_close_creates_backup_first(
        self, MockAuth: MagicMock, MockClient: MagicMock, tmp_path: Any
    ) -> None:
        """ssh-close creates auto-backup before making changes."""
        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "token"
        mock_auth.get_user_id.return_value = 42
        mock_client = MockClient.return_value
        mock_client.find_server.return_value = 123
        mock_client.get_interfaces.return_value = [{"mac": "aa:bb:cc:dd:ee:ff"}]
        mock_client.get_firewall.return_value = {
            "userPolicies": [
                {
                    "id": 777,
                    "name": "ssh-temp-cupix001",
                    "description": None,
                    "rules": [],
                }
            ],
            "copiedPolicies": [],
        }
        mock_client.list_policies.return_value = [
            {"id": 777, "name": "ssh-temp-cupix001"}
        ]
        mock_client.get_policy.return_value = {
            "id": 777,
            "name": "ssh-temp-cupix001",
            "rules": [],
        }
        mock_client.set_firewall.return_value = "task-uuid-1"

        args = parse_args(["ssh-close", "--server", "cupix001"])
        cmd_ssh_close(
            args,
            backup_dir=str(tmp_path),
            auth=mock_auth,
            client=mock_client,
            user_id=42,
        )

        # Verify backup was created
        backup_files = list(tmp_path.glob("*.json"))
        assert len(backup_files) >= 1

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_ssh_close_with_di_skips_auth_setup(
        self, MockAuth: MagicMock, MockClient: MagicMock, tmp_path: Any
    ) -> None:
        """When DI params are passed, ssh-close does not instantiate auth/client."""
        injected_auth = MagicMock(spec=ScpAuth)
        injected_client = MagicMock(spec=ScpApiClient)
        injected_client.find_server.return_value = 123
        injected_client.get_interfaces.return_value = [{"mac": "aa:bb:cc:dd:ee:ff"}]
        injected_client.list_policies.return_value = []

        args = parse_args(["ssh-close", "--server", "cupix001"])
        cmd_ssh_close(
            args,
            backup_dir=str(tmp_path),
            auth=injected_auth,
            client=injected_client,
            user_id=7,
        )

        MockAuth.assert_not_called()
        MockClient.assert_not_called()


class TestPolicyLoading:
    """Tests for load_policy_file() and validate_policy_schema()."""

    def test_load_valid_policy_file(self, tmp_path: Any) -> None:
        """Loads and parses a valid policy JSON file."""
        policy_file = tmp_path / "test-policy.json"
        policy_file.write_text(
            json.dumps(
                {
                    "name": "test-policy",
                    "description": "Test policy",
                    "rules": [
                        {
                            "direction": "INGRESS",
                            "protocol": "TCP",
                            "sourceIp": "0.0.0.0/0",
                            "destinationPort": "443",
                            "action": "ACCEPT",
                        }
                    ],
                }
            )
        )
        result = load_policy_file(str(policy_file))
        assert result["name"] == "test-policy"
        assert len(result["rules"]) == 1

    def test_load_nonexistent_file_raises(self) -> None:
        """Raises FileNotFoundError for missing policy file."""
        with pytest.raises(FileNotFoundError):
            load_policy_file("/nonexistent/path.json")

    def test_load_invalid_json_raises(self, tmp_path: Any) -> None:
        """Raises ValueError for invalid JSON."""
        bad_file = tmp_path / "bad.json"
        bad_file.write_text("not valid json {{{")
        with pytest.raises(ValueError, match="Invalid JSON"):
            load_policy_file(str(bad_file))

    def test_validate_valid_policy(self) -> None:
        """Valid policy passes validation."""
        policy = {
            "name": "test",
            "description": "desc",
            "rules": [
                {
                    "direction": "INGRESS",
                    "protocol": "TCP",
                    "sourceIp": "0.0.0.0/0",
                    "destinationPort": "443",
                    "action": "ACCEPT",
                }
            ],
        }
        validate_policy_schema(policy)  # Should not raise

    def test_validate_empty_rules_valid(self) -> None:
        """Policy with empty rules (lockdown) passes validation."""
        policy = {"name": "lockdown", "description": "drop all", "rules": []}
        validate_policy_schema(policy)  # Should not raise

    def test_validate_missing_name_raises(self) -> None:
        """Policy without name fails validation."""
        policy = {"description": "desc", "rules": []}
        with pytest.raises(ValueError, match="name"):
            validate_policy_schema(policy)

    def test_validate_missing_rules_raises(self) -> None:
        """Policy without rules key fails validation."""
        policy = {"name": "test", "description": "desc"}
        with pytest.raises(ValueError, match="rules"):
            validate_policy_schema(policy)

    def test_validate_rule_missing_direction_raises(self) -> None:
        """Rule without direction fails validation."""
        policy = {
            "name": "test",
            "description": "desc",
            "rules": [
                {
                    "protocol": "TCP",
                    "sourceIp": "0.0.0.0/0",
                    "destinationPort": "443",
                    "action": "ACCEPT",
                }
            ],
        }
        with pytest.raises(ValueError, match="direction"):
            validate_policy_schema(policy)

    def test_validate_rule_missing_protocol_raises(self) -> None:
        """Rule without protocol fails validation."""
        policy = {
            "name": "test",
            "description": "desc",
            "rules": [
                {
                    "direction": "INGRESS",
                    "sourceIp": "0.0.0.0/0",
                    "destinationPort": "443",
                    "action": "ACCEPT",
                }
            ],
        }
        with pytest.raises(ValueError, match="protocol"):
            validate_policy_schema(policy)

    def test_load_lockdown_json_from_infra(self) -> None:
        """Loads the actual lockdown.json from infra/firewall/."""
        repo_root = os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        )
        lockdown_path = os.path.join(repo_root, "infra", "firewall", "lockdown.json")
        result = load_policy_file(lockdown_path)
        validate_policy_schema(result)
        assert result["name"] == "lockdown"
        assert result["rules"] == []
