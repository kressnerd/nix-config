from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, TYPE_CHECKING

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset


if TYPE_CHECKING:
    from ..models.identifier_int import IdentifierInt


T = TypeVar("T", bound="ServerFirewallSave")


@_attrs_define
class ServerFirewallSave:
    """
    Attributes:
        copied_policies (list[IdentifierInt]):
        user_policies (list[IdentifierInt]):
        active (bool | Unset): If not set, by default the firewall will be active.
    """

    copied_policies: list[IdentifierInt]
    user_policies: list[IdentifierInt]
    active: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        copied_policies = []
        for copied_policies_item_data in self.copied_policies:
            copied_policies_item = copied_policies_item_data.to_dict()
            copied_policies.append(copied_policies_item)

        user_policies = []
        for user_policies_item_data in self.user_policies:
            user_policies_item = user_policies_item_data.to_dict()
            user_policies.append(user_policies_item)

        active = self.active

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "copiedPolicies": copied_policies,
                "userPolicies": user_policies,
            }
        )
        if active is not UNSET:
            field_dict["active"] = active

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.identifier_int import IdentifierInt

        d = dict(src_dict)
        copied_policies = []
        _copied_policies = d.pop("copiedPolicies")
        for copied_policies_item_data in _copied_policies:
            copied_policies_item = IdentifierInt.from_dict(copied_policies_item_data)

            copied_policies.append(copied_policies_item)

        user_policies = []
        _user_policies = d.pop("userPolicies")
        for user_policies_item_data in _user_policies:
            user_policies_item = IdentifierInt.from_dict(user_policies_item_data)

            user_policies.append(user_policies_item)

        active = d.pop("active", UNSET)

        server_firewall_save = cls(
            copied_policies=copied_policies,
            user_policies=user_policies,
            active=active,
        )

        server_firewall_save.additional_properties = d
        return server_firewall_save

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
