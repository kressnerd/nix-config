from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset


T = TypeVar("T", bound="BandwidthClass")


@_attrs_define
class BandwidthClass:
    """
    Attributes:
        name (str):
        speed_in_m_bit (int):
        id (int | Unset):
    """

    name: str
    speed_in_m_bit: int
    id: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        speed_in_m_bit = self.speed_in_m_bit

        id = self.id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "name": name,
                "speedInMBit": speed_in_m_bit,
            }
        )
        if id is not UNSET:
            field_dict["id"] = id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name")

        speed_in_m_bit = d.pop("speedInMBit")

        id = d.pop("id", UNSET)

        bandwidth_class = cls(
            name=name,
            speed_in_m_bit=speed_in_m_bit,
            id=id,
        )

        bandwidth_class.additional_properties = d
        return bandwidth_class

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
