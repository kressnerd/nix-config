from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset


T = TypeVar("T", bound="ServerAttachIso")


@_attrs_define
class ServerAttachIso:
    """
    Attributes:
        iso_id (int | Unset):
        user_iso_name (str | Unset):
        change_boot_device_to_cdrom (bool | Unset):
    """

    iso_id: int | Unset = UNSET
    user_iso_name: str | Unset = UNSET
    change_boot_device_to_cdrom: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        iso_id = self.iso_id

        user_iso_name = self.user_iso_name

        change_boot_device_to_cdrom = self.change_boot_device_to_cdrom

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if iso_id is not UNSET:
            field_dict["isoId"] = iso_id
        if user_iso_name is not UNSET:
            field_dict["userIsoName"] = user_iso_name
        if change_boot_device_to_cdrom is not UNSET:
            field_dict["changeBootDeviceToCdrom"] = change_boot_device_to_cdrom

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        iso_id = d.pop("isoId", UNSET)

        user_iso_name = d.pop("userIsoName", UNSET)

        change_boot_device_to_cdrom = d.pop("changeBootDeviceToCdrom", UNSET)

        server_attach_iso = cls(
            iso_id=iso_id,
            user_iso_name=user_iso_name,
            change_boot_device_to_cdrom=change_boot_device_to_cdrom,
        )

        server_attach_iso.additional_properties = d
        return server_attach_iso

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
