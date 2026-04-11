"""Tests for netcup-firewall.py CLI tool."""
import pytest
import sys
import os
from unittest.mock import patch, mock_open, MagicMock
import json

# Add scripts directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))


class TestArgParsing:
    """Test CLI argument parsing."""

    def test_backup_subcommand(self):
        """backup subcommand requires --server."""
        from netcup_firewall import parse_args
        args = parse_args(["backup", "--server", "cupix001"])
        assert args.command == "backup"
        assert args.server == "cupix001"

    def test_lockdown_subcommand(self):
        """lockdown subcommand requires --server."""
        from netcup_firewall import parse_args
        args = parse_args(["lockdown", "--server", "cupix001"])
        assert args.command == "lockdown"
        assert args.server == "cupix001"

    def test_lockdown_yes_flag(self):
        """lockdown accepts optional --yes flag."""
        from netcup_firewall import parse_args
        args = parse_args(["lockdown", "--server", "cupix001", "--yes"])
        assert args.command == "lockdown"
        assert args.yes is True

    def test_lockdown_no_yes_default(self):
        """lockdown --yes defaults to False."""
        from netcup_firewall import parse_args
        args = parse_args(["lockdown", "--server", "cupix001"])
        assert args.yes is False

    def test_restore_subcommand(self):
        """restore subcommand requires --server and --file."""
        from netcup_firewall import parse_args
        args = parse_args(["restore", "--server", "cupix001", "--file", "/tmp/backup.json"])
        assert args.command == "restore"
        assert args.server == "cupix001"
        assert args.file == "/tmp/backup.json"

    def test_apply_subcommand(self):
        """apply subcommand requires --server and --policy."""
        from netcup_firewall import parse_args
        args = parse_args(["apply", "--server", "cupix001", "--policy", "bootstrap"])
        assert args.command == "apply"
        assert args.server == "cupix001"
        assert args.policy == "bootstrap"

    def test_apply_policy_choices(self):
        """apply --policy only accepts bootstrap or production."""
        from netcup_firewall import parse_args
        with pytest.raises(SystemExit):
            parse_args(["apply", "--server", "cupix001", "--policy", "invalid"])

    def test_missing_server_raises(self):
        """Missing --server raises SystemExit."""
        from netcup_firewall import parse_args
        with pytest.raises(SystemExit):
            parse_args(["backup"])

    def test_restore_missing_file_raises(self):
        """restore without --file raises SystemExit."""
        from netcup_firewall import parse_args
        with pytest.raises(SystemExit):
            parse_args(["restore", "--server", "cupix001"])

    def test_no_subcommand_raises(self):
        """No subcommand raises SystemExit."""
        from netcup_firewall import parse_args
        with pytest.raises(SystemExit):
            parse_args([])


class TestScpAuth:
    """Test OIDC authentication module."""

    def test_credentials_path(self):
        """credentials_path returns ~/.config/netcup-scp/credentials.json."""
        from netcup_firewall import ScpAuth
        auth = ScpAuth()
        assert auth.credentials_path.endswith("netcup-scp/credentials.json")
        assert ".config" in auth.credentials_path

    def test_load_credentials_missing_file(self):
        """load_credentials returns None when file doesn't exist."""
        from netcup_firewall import ScpAuth
        auth = ScpAuth()
        with patch("builtins.open", side_effect=FileNotFoundError):
            result = auth.load_credentials()
        assert result is None

    def test_load_credentials_valid_file(self):
        """load_credentials returns parsed JSON dict."""
        from netcup_firewall import ScpAuth
        auth = ScpAuth()
        creds = {"refresh_token": "rt-123", "access_token": "at-456"}
        with patch("builtins.open", mock_open(read_data=json.dumps(creds))):
            result = auth.load_credentials()
        assert result == creds

    def test_save_credentials(self, tmp_path):
        """save_credentials writes JSON file with 0600 permissions."""
        from netcup_firewall import ScpAuth
        auth = ScpAuth()
        creds_file = tmp_path / "netcup-scp" / "credentials.json"
        auth._credentials_path = str(creds_file)
        tokens = {"refresh_token": "rt-new", "access_token": "at-new"}
        auth.save_credentials(tokens)
        assert creds_file.exists()
        loaded = json.loads(creds_file.read_text())
        assert loaded == tokens
        # Check file permissions (0600 = owner read/write only)
        import stat
        mode = creds_file.stat().st_mode & 0o777
        assert mode == 0o600

    @patch("requests.post")
    def test_device_code_flow(self, mock_post):
        """device_code_flow sends correct POST and returns response."""
        from netcup_firewall import ScpAuth
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
        # Verify correct endpoint called
        call_args = mock_post.call_args
        assert "auth/device" in call_args[0][0]
        assert call_args[1]["data"]["client_id"] == "scp"

    @patch("time.sleep")  # Don't actually sleep in tests
    @patch("requests.post")
    def test_poll_for_token_success(self, mock_post, mock_sleep):
        """poll_for_token returns tokens on successful auth."""
        from netcup_firewall import ScpAuth
        auth = ScpAuth()
        # First call: authorization_pending, second call: success
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
    def test_poll_for_token_slow_down(self, mock_post, mock_sleep):
        """poll_for_token handles slow_down by increasing interval."""
        from netcup_firewall import ScpAuth
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
        # After slow_down, sleep should be called with increased interval
        mock_sleep.assert_any_call(10)  # 5 + 5

    @patch("requests.post")
    def test_refresh_access_token(self, mock_post):
        """refresh_access_token sends refresh_token grant."""
        from netcup_firewall import ScpAuth
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
    def test_get_user_id(self, mock_get):
        """get_user_id calls userinfo endpoint and returns integer id."""
        from netcup_firewall import ScpAuth
        auth = ScpAuth()
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"id": 42, "sub": "user-uuid"}
        mock_get.return_value = mock_response
        result = auth.get_user_id("at-valid")
        assert result == 42
        call_args = mock_get.call_args
        assert "userinfo" in call_args[0][0]

    def test_get_access_token_with_stored_refresh(self):
        """get_access_token uses stored refresh token when available."""
        from netcup_firewall import ScpAuth
        auth = ScpAuth()
        auth.load_credentials = MagicMock(return_value={"refresh_token": "rt-stored"})
        auth.refresh_access_token = MagicMock(return_value={
            "access_token": "at-new",
            "refresh_token": "rt-new",
        })
        auth.save_credentials = MagicMock()
        result = auth.get_access_token()
        assert result == "at-new"
        auth.refresh_access_token.assert_called_once_with("rt-stored")
        auth.save_credentials.assert_called_once()


class TestScpApiClient:
    """Test SCP REST API client."""

    def test_find_server(self):
        """find_server returns server ID by name."""
        from netcup_firewall import ScpApiClient
        client = ScpApiClient("fake-token")
        with patch("requests.get") as mock_get:
            mock_resp = MagicMock()
            mock_resp.status_code = 200
            mock_resp.json.return_value = [{"id": 12345, "name": "cupix001"}]
            mock_get.return_value = mock_resp
            result = client.find_server("cupix001")
        assert result == 12345

    def test_find_server_not_found(self):
        """find_server raises ValueError when server not found."""
        from netcup_firewall import ScpApiClient
        client = ScpApiClient("fake-token")
        with patch("requests.get") as mock_get:
            mock_resp = MagicMock()
            mock_resp.status_code = 200
            mock_resp.json.return_value = []
            mock_get.return_value = mock_resp
            with pytest.raises(ValueError, match="not found"):
                client.find_server("nonexistent")

    def test_get_interfaces(self):
        """get_interfaces returns list of interface dicts."""
        from netcup_firewall import ScpApiClient
        client = ScpApiClient("fake-token")
        with patch("requests.get") as mock_get:
            mock_resp = MagicMock()
            mock_resp.status_code = 200
            mock_resp.json.return_value = [{"mac": "aa:bb:cc:dd:ee:ff", "type": "public"}]
            mock_get.return_value = mock_resp
            result = client.get_interfaces(12345)
        assert len(result) == 1
        assert result[0]["mac"] == "aa:bb:cc:dd:ee:ff"

    def test_get_firewall(self):
        """get_firewall returns firewall state dict."""
        from netcup_firewall import ScpApiClient
        client = ScpApiClient("fake-token")
        with patch("requests.get") as mock_get:
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

    def test_set_firewall(self):
        """set_firewall PUTs payload and returns task UUID."""
        from netcup_firewall import ScpApiClient
        client = ScpApiClient("fake-token")
        with patch("requests.put") as mock_put:
            mock_resp = MagicMock()
            mock_resp.status_code = 202
            mock_resp.json.return_value = {"uuid": "task-uuid-123"}
            mock_put.return_value = mock_resp
            result = client.set_firewall(12345, "aa:bb:cc:dd:ee:ff", {"userPolicies": [99]})
        assert result == "task-uuid-123"

    def test_list_policies(self):
        """list_policies returns list of policy dicts."""
        from netcup_firewall import ScpApiClient
        client = ScpApiClient("fake-token")
        with patch("requests.get") as mock_get:
            mock_resp = MagicMock()
            mock_resp.status_code = 200
            mock_resp.json.return_value = [
                {"id": 1, "name": "my-policy", "rules": []},
                {"id": 2, "name": "other-policy", "rules": []},
            ]
            mock_get.return_value = mock_resp
            result = client.list_policies(42)
        assert len(result) == 2

    def test_get_policy(self):
        """get_policy returns single policy dict."""
        from netcup_firewall import ScpApiClient
        client = ScpApiClient("fake-token")
        with patch("requests.get") as mock_get:
            mock_resp = MagicMock()
            mock_resp.status_code = 200
            mock_resp.json.return_value = {"id": 1, "name": "my-policy", "rules": []}
            mock_get.return_value = mock_resp
            result = client.get_policy(42, 1)
        assert result["name"] == "my-policy"

    def test_create_policy(self):
        """create_policy POSTs and returns created policy."""
        from netcup_firewall import ScpApiClient
        client = ScpApiClient("fake-token")
        with patch("requests.post") as mock_post:
            mock_resp = MagicMock()
            mock_resp.status_code = 201
            mock_resp.json.return_value = {"id": 99, "name": "lockdown", "rules": []}
            mock_post.return_value = mock_resp
            result = client.create_policy(42, "lockdown", [])
        assert result["id"] == 99
        assert result["name"] == "lockdown"

    def test_delete_policy(self):
        """delete_policy sends DELETE request."""
        from netcup_firewall import ScpApiClient
        client = ScpApiClient("fake-token")
        with patch("requests.delete") as mock_delete:
            mock_resp = MagicMock()
            mock_resp.status_code = 200
            mock_delete.return_value = mock_resp
            client.delete_policy(42, 99)  # Should not raise
        mock_delete.assert_called_once()

    @patch("time.sleep")
    def test_wait_for_task_success(self, mock_sleep):
        """wait_for_task polls until COMPLETED."""
        from netcup_firewall import ScpApiClient
        client = ScpApiClient("fake-token")
        with patch("requests.get") as mock_get:
            running_resp = MagicMock()
            running_resp.status_code = 200
            running_resp.json.return_value = {"status": "RUNNING"}
            completed_resp = MagicMock()
            completed_resp.status_code = 200
            completed_resp.json.return_value = {"status": "COMPLETED"}
            mock_get.side_effect = [running_resp, completed_resp]
            client.wait_for_task("task-uuid-123")  # Should not raise

    @patch("time.sleep")
    def test_wait_for_task_timeout(self, mock_sleep):
        """wait_for_task raises TimeoutError after max polls."""
        from netcup_firewall import ScpApiClient
        client = ScpApiClient("fake-token")
        with patch("requests.get") as mock_get:
            running_resp = MagicMock()
            running_resp.status_code = 200
            running_resp.json.return_value = {"status": "RUNNING"}
            mock_get.return_value = running_resp
            with pytest.raises(TimeoutError):
                client.wait_for_task("task-uuid-123", max_polls=3, interval=0)


class TestBackupCommand:
    """Test backup subcommand."""

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_backup_calls_api_methods(self, MockAuth, MockClient, tmp_path):
        """backup calls find_server, get_interfaces, get_firewall, list_policies."""
        from netcup_firewall import cmd_backup
        import argparse

        # Setup mocks
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
        mock_client.list_policies.return_value = [
            {"id": 1, "name": "my-policy", "rules": [{"direction": "INGRESS", "protocol": "TCP", "destinationPort": "22", "action": "ACCEPT"}]}
        ]

        args = argparse.Namespace(server="cupix001", command="backup")
        backup_path = cmd_backup(args, backup_dir=str(tmp_path))

        mock_client.find_server.assert_called_once_with("cupix001")
        mock_client.get_interfaces.assert_called_once_with(12345)
        mock_client.get_firewall.assert_called_once()
        mock_client.list_policies.assert_called_once_with(42)

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_backup_writes_valid_json(self, MockAuth, MockClient, tmp_path):
        """backup writes a valid JSON file."""
        from netcup_firewall import cmd_backup
        import argparse

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
    def test_backup_includes_interfaces_and_firewall(self, MockAuth, MockClient, tmp_path):
        """backup JSON includes interface firewall state."""
        from netcup_firewall import cmd_backup
        import argparse

        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "at-test"
        mock_auth.get_user_id.return_value = 42
        mock_client = MockClient.return_value
        mock_client.find_server.return_value = 12345
        mock_client.get_interfaces.return_value = [
            {"mac": "aa:bb:cc:dd:ee:ff", "type": "public"}
        ]
        firewall_state = {
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
    def test_backup_creates_directory(self, MockAuth, MockClient, tmp_path):
        """backup creates backup directory if it doesn't exist."""
        from netcup_firewall import cmd_backup
        import argparse

        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "at-test"
        mock_auth.get_user_id.return_value = 42
        mock_client = MockClient.return_value
        mock_client.find_server.return_value = 12345
        mock_client.get_interfaces.return_value = []
        mock_client.list_policies.return_value = []

        nested_dir = str(tmp_path / "sub" / "dir")
        args = argparse.Namespace(server="cupix001", command="backup")
        backup_path = cmd_backup(args, backup_dir=nested_dir)

        assert os.path.exists(backup_path)
        assert os.path.isdir(nested_dir)

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_backup_filename_format(self, MockAuth, MockClient, tmp_path):
        """backup filename contains server name and timestamp."""
        from netcup_firewall import cmd_backup
        import argparse

        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "at-test"
        mock_auth.get_user_id.return_value = 42
        mock_client = MockClient.return_value
        mock_client.find_server.return_value = 12345
        mock_client.get_interfaces.return_value = []
        mock_client.list_policies.return_value = []

        args = argparse.Namespace(server="cupix001", command="backup")
        backup_path = cmd_backup(args, backup_dir=str(tmp_path))

        filename = os.path.basename(backup_path)
        assert filename.startswith("cupix001-")
        assert filename.endswith(".json")


class TestLockdownCommand:
    """Test lockdown (kill switch) subcommand."""

    def _make_mock_setup(self, MockAuth, MockClient):
        """Helper to set up common mocks for lockdown tests."""
        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "at-test"
        mock_auth.get_user_id.return_value = 42
        mock_client = MockClient.return_value
        mock_client.find_server.return_value = 12345
        mock_client.get_interfaces.return_value = [
            {"mac": "aa:bb:cc:dd:ee:ff", "type": "public"}
        ]
        mock_client.list_policies.return_value = []  # No existing lockdown policy
        mock_client.create_policy.return_value = {"id": 99, "name": "lockdown-cupix001", "rules": []}
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
    def test_lockdown_creates_auto_backup(self, MockAuth, MockClient, mock_backup, tmp_path):
        """lockdown creates automatic backup before lockdown."""
        from netcup_firewall import cmd_lockdown
        import argparse

        self._make_mock_setup(MockAuth, MockClient)
        mock_backup.return_value = str(tmp_path / "backup.json")

        args = argparse.Namespace(server="cupix001", command="lockdown", yes=True)
        cmd_lockdown(args)

        mock_backup.assert_called_once()

    @patch("netcup_firewall.cmd_backup")
    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_lockdown_creates_empty_policy(self, MockAuth, MockClient, mock_backup, tmp_path):
        """lockdown creates policy with empty rules (DROP ALL)."""
        from netcup_firewall import cmd_lockdown
        import argparse

        _, mock_client = self._make_mock_setup(MockAuth, MockClient)
        mock_backup.return_value = str(tmp_path / "backup.json")

        args = argparse.Namespace(server="cupix001", command="lockdown", yes=True)
        cmd_lockdown(args)

        mock_client.create_policy.assert_called_once_with(42, "lockdown-cupix001", [])

    @patch("netcup_firewall.cmd_backup")
    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_lockdown_reuses_existing_policy(self, MockAuth, MockClient, mock_backup, tmp_path):
        """lockdown reuses existing lockdown policy instead of creating new one."""
        from netcup_firewall import cmd_lockdown
        import argparse

        _, mock_client = self._make_mock_setup(MockAuth, MockClient)
        # Existing lockdown policy
        mock_client.list_policies.return_value = [
            {"id": 77, "name": "lockdown-cupix001", "rules": []},
            {"id": 1, "name": "other-policy", "rules": [{"direction": "INGRESS"}]},
        ]
        mock_backup.return_value = str(tmp_path / "backup.json")

        args = argparse.Namespace(server="cupix001", command="lockdown", yes=True)
        cmd_lockdown(args)

        # Should NOT create a new policy
        mock_client.create_policy.assert_not_called()
        # Should assign existing policy ID 77
        mock_client.set_firewall.assert_called_once()
        call_args = mock_client.set_firewall.call_args
        assert 77 in call_args[0][2]["userPolicies"]  # payload contains policy 77

    @patch("netcup_firewall.cmd_backup")
    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_lockdown_assigns_policy_to_interface(self, MockAuth, MockClient, mock_backup, tmp_path):
        """lockdown assigns lockdown policy to server interface."""
        from netcup_firewall import cmd_lockdown
        import argparse

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
    def test_lockdown_waits_for_task(self, MockAuth, MockClient, mock_backup, tmp_path):
        """lockdown waits for firewall assignment task to complete."""
        from netcup_firewall import cmd_lockdown
        import argparse

        _, mock_client = self._make_mock_setup(MockAuth, MockClient)
        mock_backup.return_value = str(tmp_path / "backup.json")

        args = argparse.Namespace(server="cupix001", command="lockdown", yes=True)
        cmd_lockdown(args)

        mock_client.wait_for_task.assert_called_once_with("task-uuid-123")

    @patch("netcup_firewall.cmd_backup")
    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_lockdown_verifies_state(self, MockAuth, MockClient, mock_backup, tmp_path):
        """lockdown verifies firewall state after assignment."""
        from netcup_firewall import cmd_lockdown
        import argparse

        _, mock_client = self._make_mock_setup(MockAuth, MockClient)
        mock_backup.return_value = str(tmp_path / "backup.json")

        args = argparse.Namespace(server="cupix001", command="lockdown", yes=True)
        cmd_lockdown(args)

        # get_firewall called to verify
        mock_client.get_firewall.assert_called_with(12345, "aa:bb:cc:dd:ee:ff")

    @patch("builtins.input", return_value="n")
    @patch("netcup_firewall.cmd_backup")
    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_lockdown_aborts_without_yes(self, MockAuth, MockClient, mock_backup, mock_input):
        """lockdown aborts when user says no to confirmation."""
        from netcup_firewall import cmd_lockdown
        import argparse

        self._make_mock_setup(MockAuth, MockClient)

        args = argparse.Namespace(server="cupix001", command="lockdown", yes=False)
        with pytest.raises(SystemExit):
            cmd_lockdown(args)

    @patch("builtins.input", return_value="y")
    @patch("netcup_firewall.cmd_backup")
    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_lockdown_proceeds_with_yes_input(self, MockAuth, MockClient, mock_backup, mock_input, tmp_path):
        """lockdown proceeds when user confirms with 'y'."""
        from netcup_firewall import cmd_lockdown
        import argparse

        _, mock_client = self._make_mock_setup(MockAuth, MockClient)
        mock_backup.return_value = str(tmp_path / "backup.json")

        args = argparse.Namespace(server="cupix001", command="lockdown", yes=False)
        cmd_lockdown(args)

        # Should have proceeded with lockdown
        mock_client.set_firewall.assert_called_once()


class TestRestoreCommand:
    """Test restore subcommand."""

    def _make_backup_file(self, tmp_path, server_name="cupix001", version=1):
        """Helper: create a valid backup JSON file."""
        backup = {
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
    def test_restore_loads_backup(self, MockAuth, MockClient, tmp_path):
        """restore loads and parses backup JSON file."""
        from netcup_firewall import cmd_restore
        import argparse

        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "at-test"
        mock_auth.get_user_id.return_value = 42
        mock_client = MockClient.return_value
        mock_client.find_server.return_value = 12345
        mock_client.list_policies.return_value = []
        mock_client.create_policy.return_value = {"id": 50, "name": "my-policy", "rules": []}
        mock_client.set_firewall.return_value = "task-uuid"

        backup_file = self._make_backup_file(tmp_path)
        args = argparse.Namespace(server="cupix001", command="restore", file=backup_file)
        cmd_restore(args)

        mock_client.find_server.assert_called_once_with("cupix001")

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_restore_validates_version(self, MockAuth, MockClient, tmp_path):
        """restore rejects backup with wrong version."""
        from netcup_firewall import cmd_restore
        import argparse

        backup_file = self._make_backup_file(tmp_path, version=99)
        args = argparse.Namespace(server="cupix001", command="restore", file=backup_file)
        with pytest.raises(SystemExit):
            cmd_restore(args)

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_restore_validates_server_name(self, MockAuth, MockClient, tmp_path):
        """restore rejects backup for wrong server."""
        from netcup_firewall import cmd_restore
        import argparse

        backup_file = self._make_backup_file(tmp_path, server_name="other-server")
        args = argparse.Namespace(server="cupix001", command="restore", file=backup_file)
        with pytest.raises(SystemExit):
            cmd_restore(args)

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_restore_creates_missing_policies(self, MockAuth, MockClient, tmp_path):
        """restore creates policies that don't exist yet."""
        from netcup_firewall import cmd_restore
        import argparse

        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "at-test"
        mock_auth.get_user_id.return_value = 42
        mock_client = MockClient.return_value
        mock_client.find_server.return_value = 12345
        mock_client.list_policies.return_value = []  # No existing policies
        mock_client.create_policy.return_value = {"id": 50, "name": "my-policy", "rules": []}
        mock_client.set_firewall.return_value = "task-uuid"

        backup_file = self._make_backup_file(tmp_path)
        args = argparse.Namespace(server="cupix001", command="restore", file=backup_file)
        cmd_restore(args)

        mock_client.create_policy.assert_called_once()
        call_args = mock_client.create_policy.call_args
        assert call_args[0][1] == "my-policy"  # name
        assert len(call_args[0][2]) == 1  # rules list has 1 rule

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_restore_reuses_existing_policies(self, MockAuth, MockClient, tmp_path):
        """restore reuses policies that already exist by name."""
        from netcup_firewall import cmd_restore
        import argparse

        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "at-test"
        mock_auth.get_user_id.return_value = 42
        mock_client = MockClient.return_value
        mock_client.find_server.return_value = 12345
        mock_client.list_policies.return_value = [
            {"id": 77, "name": "my-policy", "rules": []}  # Already exists
        ]
        mock_client.set_firewall.return_value = "task-uuid"

        backup_file = self._make_backup_file(tmp_path)
        args = argparse.Namespace(server="cupix001", command="restore", file=backup_file)
        cmd_restore(args)

        # Should NOT create a new policy
        mock_client.create_policy.assert_not_called()

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_restore_assigns_policies_to_interfaces(self, MockAuth, MockClient, tmp_path):
        """restore assigns mapped policies to interfaces."""
        from netcup_firewall import cmd_restore
        import argparse

        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "at-test"
        mock_auth.get_user_id.return_value = 42
        mock_client = MockClient.return_value
        mock_client.find_server.return_value = 12345
        mock_client.list_policies.return_value = [
            {"id": 77, "name": "my-policy", "rules": []}  # Existing, maps old id 1 → 77
        ]
        mock_client.set_firewall.return_value = "task-uuid"

        backup_file = self._make_backup_file(tmp_path)
        args = argparse.Namespace(server="cupix001", command="restore", file=backup_file)
        cmd_restore(args)

        mock_client.set_firewall.assert_called_once()
        call_args = mock_client.set_firewall.call_args
        assert call_args[0][0] == 12345  # server_id
        assert call_args[0][1] == "aa:bb:cc:dd:ee:ff"  # mac
        # The mapped policy ID should be 77 (not the old backup ID 1)
        assert 77 in call_args[0][2]["userPolicies"]

    @patch("netcup_firewall.ScpApiClient")
    @patch("netcup_firewall.ScpAuth")
    def test_restore_waits_for_task(self, MockAuth, MockClient, tmp_path):
        """restore waits for firewall assignment task."""
        from netcup_firewall import cmd_restore
        import argparse

        mock_auth = MockAuth.return_value
        mock_auth.get_access_token.return_value = "at-test"
        mock_auth.get_user_id.return_value = 42
        mock_client = MockClient.return_value
        mock_client.find_server.return_value = 12345
        mock_client.list_policies.return_value = []
        mock_client.create_policy.return_value = {"id": 50, "name": "my-policy", "rules": []}
        mock_client.set_firewall.return_value = "task-uuid-456"

        backup_file = self._make_backup_file(tmp_path)
        args = argparse.Namespace(server="cupix001", command="restore", file=backup_file)
        cmd_restore(args)

        mock_client.wait_for_task.assert_called_once_with("task-uuid-456")

    def test_restore_invalid_json(self, tmp_path):
        """restore fails gracefully on invalid JSON."""
        from netcup_firewall import cmd_restore
        import argparse

        bad_file = tmp_path / "bad.json"
        bad_file.write_text("not valid json {{{")
        args = argparse.Namespace(server="cupix001", command="restore", file=str(bad_file))
        with pytest.raises(SystemExit):
            cmd_restore(args)

    def test_restore_missing_file(self):
        """restore fails gracefully on missing file."""
        from netcup_firewall import cmd_restore
        import argparse

        args = argparse.Namespace(server="cupix001", command="restore", file="/nonexistent/file.json")
        with pytest.raises(SystemExit):
            cmd_restore(args)
