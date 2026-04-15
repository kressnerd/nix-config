from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, TYPE_CHECKING

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset


if TYPE_CHECKING:
    from ..models.task_info import TaskInfo
    from ..models.firewall_policy import FirewallPolicy


T = TypeVar("T", bound="FirewallPolicyUpdateResult")


@_attrs_define
class FirewallPolicyUpdateResult:
    """
    Attributes:
        firewall_policy (FirewallPolicy | Unset):
        task_info (TaskInfo | Unset):
    """

    firewall_policy: FirewallPolicy | Unset = UNSET
    task_info: TaskInfo | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        firewall_policy: dict[str, Any] | Unset = UNSET
        if not isinstance(self.firewall_policy, Unset):
            firewall_policy = self.firewall_policy.to_dict()

        task_info: dict[str, Any] | Unset = UNSET
        if not isinstance(self.task_info, Unset):
            task_info = self.task_info.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if firewall_policy is not UNSET:
            field_dict["firewallPolicy"] = firewall_policy
        if task_info is not UNSET:
            field_dict["taskInfo"] = task_info

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.task_info import TaskInfo
        from ..models.firewall_policy import FirewallPolicy

        d = dict(src_dict)
        _firewall_policy = d.pop("firewallPolicy", UNSET)
        firewall_policy: FirewallPolicy | Unset
        if isinstance(_firewall_policy, Unset):
            firewall_policy = UNSET
        else:
            firewall_policy = FirewallPolicy.from_dict(_firewall_policy)

        _task_info = d.pop("taskInfo", UNSET)
        task_info: TaskInfo | Unset
        if isinstance(_task_info, Unset):
            task_info = UNSET
        else:
            task_info = TaskInfo.from_dict(_task_info)

        firewall_policy_update_result = cls(
            firewall_policy=firewall_policy,
            task_info=task_info,
        )

        firewall_policy_update_result.additional_properties = d
        return firewall_policy_update_result

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
