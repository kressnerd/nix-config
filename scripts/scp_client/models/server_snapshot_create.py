from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from typing import cast


T = TypeVar("T", bound="ServerSnapshotCreate")


@_attrs_define
class ServerSnapshotCreate:
    """
    Attributes:
        name (str):
        description (None | str | Unset):
        disk_name (None | str | Unset):
        online_snapshot (bool | Unset):
    """

    name: str
    description: None | str | Unset = UNSET
    disk_name: None | str | Unset = UNSET
    online_snapshot: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        description: None | str | Unset
        if isinstance(self.description, Unset):
            description = UNSET
        else:
            description = self.description

        disk_name: None | str | Unset
        if isinstance(self.disk_name, Unset):
            disk_name = UNSET
        else:
            disk_name = self.disk_name

        online_snapshot = self.online_snapshot

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "name": name,
            }
        )
        if description is not UNSET:
            field_dict["description"] = description
        if disk_name is not UNSET:
            field_dict["diskName"] = disk_name
        if online_snapshot is not UNSET:
            field_dict["onlineSnapshot"] = online_snapshot

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name")

        def _parse_description(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        description = _parse_description(d.pop("description", UNSET))

        def _parse_disk_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        disk_name = _parse_disk_name(d.pop("diskName", UNSET))

        online_snapshot = d.pop("onlineSnapshot", UNSET)

        server_snapshot_create = cls(
            name=name,
            description=description,
            disk_name=disk_name,
            online_snapshot=online_snapshot,
        )

        server_snapshot_create.additional_properties = d
        return server_snapshot_create

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
