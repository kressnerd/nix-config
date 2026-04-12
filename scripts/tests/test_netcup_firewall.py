"""Tests for the netcup-firewall CLI tool.

Covers argument parsing, OIDC authentication (ScpAuth), REST API client
(ScpApiClient), and all command handlers (backup, lockdown, restore, apply).
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
    cmd_apply,
    cmd_backup,
    cmd_lockdown,
    cmd_restore,
    main,
    parse_args,
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
        """set_firewall PUTs payload and returns task UUID."""
        client = ScpApiClient("fake-token")
        with patch.object(client._session, "put") as mock_put:
            mock_resp = MagicMock()
            mock_resp.status_code = 202
            mock_resp.json.return_value = {"uuid": "task-uuid-123"}
            mock_put.return_value = mock_resp
            result = client.set_firewall(
                12345, "aa:bb:cc:dd:ee:ff", {"userPolicies": [99]}
            )
        assert result == "task-uuid-123"

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
            "userPolicies": [1],
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
        mock_client.list_policies.return_value = [
            {
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
        ]

        args = argparse.Namespace(server="cupix001", command="backup")
        cmd_backup(args, backup_dir=str(tmp_path))

        mock_client.find_server.assert_called_once_with("cupix001")
        mock_client.get_interfaces.assert_called_once_with(12345)
        mock_client.get_firewall.assert_called_once()
        mock_client.list_policies.assert_called_once_with(42)

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
            "userPolicies": [1, 2],
            "copiedPolicies": [],
            "ingressImplicitRule": "DROP",
            "egressImplicitRule": "DROP",
            "consistent": True,
            "active": True,
        }
        mock_client.get_firewall.return_value = firewall_state
        mock_client.list_policies.return_value = [
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
            "userPolicies": [99],
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
        assert 77 in call_args[0][2]["userPolicies"]

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
            12345, "aa:bb:cc:dd:ee:ff", {"userPolicies": [99]}
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
        assert 77 in call_args[0][2]["userPolicies"]

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
            "userPolicies": [1],
            "copiedPolicies": [],
            "ingressImplicitRule": "DROP",
            "egressImplicitRule": "DROP",
            "consistent": True,
            "active": True,
        }
        mock_client.get_firewall.return_value = initial_firewall
        mock_client.list_policies.return_value = [
            {
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
        ]
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
