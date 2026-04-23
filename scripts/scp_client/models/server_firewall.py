from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, TYPE_CHECKING

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from ..models.implicit_rule import ImplicitRule

if TYPE_CHECKING:
    from ..models.firewall_policy import FirewallPolicy


T = TypeVar("T", bound="ServerFirewall")


@_attrs_define
class ServerFirewall:
    """
    Attributes:
        copied_policies (list[FirewallPolicy] | Unset):
        user_policies (list[FirewallPolicy] | Unset):
        ingress_implicit_rule (ImplicitRule | Unset):
        egress_implicit_rule (ImplicitRule | Unset):
        consistent (bool | Unset):
        active (bool | Unset):
    """

    copied_policies: list[FirewallPolicy] | Unset = UNSET
    user_policies: list[FirewallPolicy] | Unset = UNSET
    ingress_implicit_rule: ImplicitRule | Unset = UNSET
    egress_implicit_rule: ImplicitRule | Unset = UNSET
    consistent: bool | Unset = UNSET
    active: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        copied_policies: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.copied_policies, Unset):
            copied_policies = []
            for copied_policies_item_data in self.copied_policies:
                copied_policies_item = copied_policies_item_data.to_dict()
                copied_policies.append(copied_policies_item)

        user_policies: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.user_policies, Unset):
            user_policies = []
            for user_policies_item_data in self.user_policies:
                user_policies_item = user_policies_item_data.to_dict()
                user_policies.append(user_policies_item)

        ingress_implicit_rule: str | Unset = UNSET
        if not isinstance(self.ingress_implicit_rule, Unset):
            ingress_implicit_rule = self.ingress_implicit_rule.value

        egress_implicit_rule: str | Unset = UNSET
        if not isinstance(self.egress_implicit_rule, Unset):
            egress_implicit_rule = self.egress_implicit_rule.value

        consistent = self.consistent

        active = self.active

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if copied_policies is not UNSET:
            field_dict["copiedPolicies"] = copied_policies
        if user_policies is not UNSET:
            field_dict["userPolicies"] = user_policies
        if ingress_implicit_rule is not UNSET:
            field_dict["ingressImplicitRule"] = ingress_implicit_rule
        if egress_implicit_rule is not UNSET:
            field_dict["egressImplicitRule"] = egress_implicit_rule
        if consistent is not UNSET:
            field_dict["consistent"] = consistent
        if active is not UNSET:
            field_dict["active"] = active

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.firewall_policy import FirewallPolicy

        d = dict(src_dict)
        _copied_policies = d.pop("copiedPolicies", UNSET)
        copied_policies: list[FirewallPolicy] | Unset = UNSET
        if _copied_policies is not UNSET and _copied_policies is not None:
            copied_policies = []
            for copied_policies_item_data in _copied_policies:
                copied_policies_item = FirewallPolicy.from_dict(
                    copied_policies_item_data
                )

                copied_policies.append(copied_policies_item)
        elif _copied_policies is None:
            copied_policies = None  # type: ignore[assignment]

        _user_policies = d.pop("userPolicies", UNSET)
        user_policies: list[FirewallPolicy] | Unset = UNSET
        if _user_policies is not UNSET and _user_policies is not None:
            user_policies = []
            for user_policies_item_data in _user_policies:
                user_policies_item = FirewallPolicy.from_dict(user_policies_item_data)

                user_policies.append(user_policies_item)
        elif _user_policies is None:
            user_policies = None  # type: ignore[assignment]

        _ingress_implicit_rule = d.pop("ingressImplicitRule", UNSET)
        ingress_implicit_rule: ImplicitRule | Unset
        if isinstance(_ingress_implicit_rule, Unset):
            ingress_implicit_rule = UNSET
        else:
            ingress_implicit_rule = ImplicitRule(_ingress_implicit_rule)

        _egress_implicit_rule = d.pop("egressImplicitRule", UNSET)
        egress_implicit_rule: ImplicitRule | Unset
        if isinstance(_egress_implicit_rule, Unset):
            egress_implicit_rule = UNSET
        else:
            egress_implicit_rule = ImplicitRule(_egress_implicit_rule)

        consistent = d.pop("consistent", UNSET)

        active = d.pop("active", UNSET)

        server_firewall = cls(
            copied_policies=copied_policies,
            user_policies=user_policies,
            ingress_implicit_rule=ingress_implicit_rule,
            egress_implicit_rule=egress_implicit_rule,
            consistent=consistent,
            active=active,
        )

        server_firewall.additional_properties = d
        return server_firewall

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
