"""Tests for the generated SCP API client package (Phase 2 of CUP-018)."""

from __future__ import annotations

import enum
from typing import TYPE_CHECKING

import attrs

if TYPE_CHECKING:
    pass


class TestModelImports:
    """Verify all firewall-related model classes are importable."""

    def test_server_firewall_import(self) -> None:
        from scp_client.models import ServerFirewall

        assert attrs.has(ServerFirewall)

    def test_firewall_policy_import(self) -> None:
        from scp_client.models import FirewallPolicy

        assert attrs.has(FirewallPolicy)

    def test_server_firewall_save_import(self) -> None:
        from scp_client.models import ServerFirewallSave

        assert attrs.has(ServerFirewallSave)

    def test_firewall_policy_save_import(self) -> None:
        from scp_client.models import FirewallPolicySave

        assert attrs.has(FirewallPolicySave)

    def test_identifier_int_import(self) -> None:
        from scp_client.models import IdentifierInt

        assert attrs.has(IdentifierInt)

    def test_firewall_rule_import(self) -> None:
        from scp_client.models import FirewallRule

        assert attrs.has(FirewallRule)

    def test_firewall_policy_update_result_import(self) -> None:
        from scp_client.models import FirewallPolicyUpdateResult

        assert attrs.has(FirewallPolicyUpdateResult)

    def test_task_info_import(self) -> None:
        from scp_client.models import TaskInfo

        assert attrs.has(TaskInfo)


class TestEnumTypes:
    """Verify enum types have expected values from the OpenAPI spec."""

    def test_firewall_action_values(self) -> None:
        from scp_client.models import FirewallAction

        assert issubclass(FirewallAction, enum.Enum)
        assert FirewallAction.ACCEPT.value == "ACCEPT"
        assert FirewallAction.DROP.value == "DROP"

    def test_firewall_protocol_values(self) -> None:
        from scp_client.models import FirewallProtocol

        assert issubclass(FirewallProtocol, enum.Enum)
        assert FirewallProtocol.TCP.value == "TCP"
        assert FirewallProtocol.UDP.value == "UDP"
        assert FirewallProtocol.ICMP.value == "ICMP"

    def test_firewall_rule_direction_values(self) -> None:
        from scp_client.models import FirewallRuleDirection

        assert issubclass(FirewallRuleDirection, enum.Enum)
        assert FirewallRuleDirection.INGRESS.value == "INGRESS"
        assert FirewallRuleDirection.EGRESS.value == "EGRESS"

    def test_implicit_rule_values(self) -> None:
        from scp_client.models import ImplicitRule

        assert issubclass(ImplicitRule, enum.Enum)
        assert ImplicitRule.ACCEPT_ALL.value == "ACCEPT_ALL"
        assert ImplicitRule.DROP_ALL.value == "DROP_ALL"


class TestClientImports:
    """Verify HTTP client classes are importable."""

    def test_client_import(self) -> None:
        from scp_client import Client

        assert attrs.has(Client)

    def test_authenticated_client_import(self) -> None:
        from scp_client import AuthenticatedClient

        assert attrs.has(AuthenticatedClient)

    def test_authenticated_client_accepts_token(self) -> None:
        from scp_client import AuthenticatedClient

        ac = AuthenticatedClient(
            base_url="https://example.com",
            token="test-token",
        )
        assert ac.token == "test-token"
        assert ac._base_url == "https://example.com"


class TestApiEndpointImports:
    """Verify API endpoint modules are importable with expected function signatures."""

    def test_get_server_firewall_import(self) -> None:
        from scp_client.api.server_firewalls import (
            get_api_v_1_servers_server_id_interfaces_mac_firewall,
        )

        assert callable(get_api_v_1_servers_server_id_interfaces_mac_firewall.sync)
        assert callable(
            get_api_v_1_servers_server_id_interfaces_mac_firewall.sync_detailed
        )

    def test_put_server_firewall_import(self) -> None:
        from scp_client.api.server_firewalls import (
            put_api_v_1_servers_server_id_interfaces_mac_firewall,
        )

        assert callable(put_api_v_1_servers_server_id_interfaces_mac_firewall.sync)

    def test_list_user_firewall_policies_import(self) -> None:
        from scp_client.api.server_firewalls import (
            get_api_v_1_users_user_id_firewall_policies,
        )

        assert callable(get_api_v_1_users_user_id_firewall_policies.sync)

    def test_get_user_firewall_policy_import(self) -> None:
        from scp_client.api.server_firewalls import (
            get_api_v_1_users_user_id_firewall_policies_id,
        )

        assert callable(get_api_v_1_users_user_id_firewall_policies_id.sync)

    def test_create_user_firewall_policy_import(self) -> None:
        from scp_client.api.server_firewalls import (
            post_api_v_1_users_user_id_firewall_policies,
        )

        assert callable(post_api_v_1_users_user_id_firewall_policies.sync)

    def test_update_user_firewall_policy_import(self) -> None:
        from scp_client.api.server_firewalls import (
            put_api_v_1_users_user_id_firewall_policies_id,
        )

        assert callable(put_api_v_1_users_user_id_firewall_policies_id.sync)

    def test_delete_user_firewall_policy_import(self) -> None:
        from scp_client.api.server_firewalls import (
            delete_api_v_1_users_user_id_firewall_policies_id,
        )

        assert callable(delete_api_v_1_users_user_id_firewall_policies_id.sync)


class TestModelFieldContracts:
    """Verify key model fields match the OpenAPI schema expectations."""

    def test_identifier_int_has_id_field(self) -> None:
        from scp_client.models import IdentifierInt

        obj = IdentifierInt(id=42)
        assert obj.id == 42

    def test_server_firewall_save_requires_policies(self) -> None:
        from scp_client.models import IdentifierInt, ServerFirewallSave

        save = ServerFirewallSave(
            copied_policies=[],
            user_policies=[IdentifierInt(id=99)],
        )
        assert len(save.user_policies) == 1
        assert save.user_policies[0].id == 99
        assert save.copied_policies == []

    def test_firewall_policy_save_requires_name(self) -> None:
        from scp_client.models import FirewallPolicySave

        policy = FirewallPolicySave(name="test-policy")
        assert policy.name == "test-policy"

    def test_firewall_rule_requires_direction_protocol_action(self) -> None:
        from scp_client.models import (
            FirewallAction,
            FirewallProtocol,
            FirewallRule,
            FirewallRuleDirection,
        )

        rule = FirewallRule(
            direction=FirewallRuleDirection.INGRESS,
            protocol=FirewallProtocol.TCP,
            action=FirewallAction.ACCEPT,
        )
        assert rule.direction == FirewallRuleDirection.INGRESS
        assert rule.protocol == FirewallProtocol.TCP
        assert rule.action == FirewallAction.ACCEPT


class TestPyTypedMarker:
    """Verify PEP 561 py.typed marker exists."""

    def test_py_typed_exists(self) -> None:
        from pathlib import Path

        import scp_client

        package_dir = Path(scp_client.__file__).parent
        py_typed = package_dir / "py.typed"
        assert py_typed.exists(), (
            "py.typed marker missing — mypy won't treat package as typed"
        )
