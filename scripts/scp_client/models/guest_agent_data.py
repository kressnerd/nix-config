from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, TYPE_CHECKING

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset


if TYPE_CHECKING:
    from ..models.guest_agent_data_guest_agent_data import GuestAgentDataGuestAgentData


T = TypeVar("T", bound="GuestAgentData")


@_attrs_define
class GuestAgentData:
    """
    Attributes:
        guest_agent_available (bool | Unset):
        guest_agent_data (GuestAgentDataGuestAgentData | Unset): Information in json format about the qemu guest agent,
            which may change depending on the version. We do not guarantee backwards compatibility for this data.
    """

    guest_agent_available: bool | Unset = UNSET
    guest_agent_data: GuestAgentDataGuestAgentData | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        guest_agent_available = self.guest_agent_available

        guest_agent_data: dict[str, Any] | Unset = UNSET
        if not isinstance(self.guest_agent_data, Unset):
            guest_agent_data = self.guest_agent_data.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if guest_agent_available is not UNSET:
            field_dict["guestAgentAvailable"] = guest_agent_available
        if guest_agent_data is not UNSET:
            field_dict["guestAgentData"] = guest_agent_data

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.guest_agent_data_guest_agent_data import (
            GuestAgentDataGuestAgentData,
        )

        d = dict(src_dict)
        guest_agent_available = d.pop("guestAgentAvailable", UNSET)

        _guest_agent_data = d.pop("guestAgentData", UNSET)
        guest_agent_data: GuestAgentDataGuestAgentData | Unset
        if isinstance(_guest_agent_data, Unset):
            guest_agent_data = UNSET
        else:
            guest_agent_data = GuestAgentDataGuestAgentData.from_dict(_guest_agent_data)

        guest_agent_data = cls(
            guest_agent_available=guest_agent_available,
            guest_agent_data=guest_agent_data,
        )

        guest_agent_data.additional_properties = d
        return guest_agent_data

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
