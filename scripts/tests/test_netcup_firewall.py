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
