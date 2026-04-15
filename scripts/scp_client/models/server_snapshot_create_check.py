from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset


T = TypeVar("T", bound="ServerSnapshotCreateCheck")


@_attrs_define
class ServerSnapshotCreateCheck:
    """
    Attributes:
        disk_name (str | Unset): Must be set if attribute onlineSnapshot is false.
        online_snapshot (bool | Unset):
    """

    disk_name: str | Unset = UNSET
    online_snapshot: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        disk_name = self.disk_name

        online_snapshot = self.online_snapshot

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if disk_name is not UNSET:
            field_dict["diskName"] = disk_name
        if online_snapshot is not UNSET:
            field_dict["onlineSnapshot"] = online_snapshot

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        disk_name = d.pop("diskName", UNSET)

        online_snapshot = d.pop("onlineSnapshot", UNSET)

        server_snapshot_create_check = cls(
            disk_name=disk_name,
            online_snapshot=online_snapshot,
        )

        server_snapshot_create_check.additional_properties = d
        return server_snapshot_create_check

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
