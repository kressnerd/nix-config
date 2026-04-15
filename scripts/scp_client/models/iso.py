from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from typing import cast


T = TypeVar("T", bound="Iso")


@_attrs_define
class Iso:
    """
    Attributes:
        iso_attached (bool | Unset):
        iso (None | str | Unset):
    """

    iso_attached: bool | Unset = UNSET
    iso: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        iso_attached = self.iso_attached

        iso: None | str | Unset
        if isinstance(self.iso, Unset):
            iso = UNSET
        else:
            iso = self.iso

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if iso_attached is not UNSET:
            field_dict["isoAttached"] = iso_attached
        if iso is not UNSET:
            field_dict["iso"] = iso

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        iso_attached = d.pop("isoAttached", UNSET)

        def _parse_iso(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        iso = _parse_iso(d.pop("iso", UNSET))

        iso = cls(
            iso_attached=iso_attached,
            iso=iso,
        )

        iso.additional_properties = d
        return iso

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
