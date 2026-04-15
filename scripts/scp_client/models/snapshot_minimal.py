from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from ..models.server_state import ServerState
from dateutil.parser import isoparse
from typing import cast
import datetime


T = TypeVar("T", bound="SnapshotMinimal")


@_attrs_define
class SnapshotMinimal:
    """
    Attributes:
        uuid (str | Unset):
        name (str | Unset):
        description (None | str | Unset):
        disks (list[str] | Unset):
        creation_time (datetime.datetime | Unset):  Example: 2022-03-10T16:15:50Z.
        state (ServerState | Unset):
        online (bool | Unset):
        exported (bool | Unset):
        exported_size_in_ki_b (int | None | Unset):
    """

    uuid: str | Unset = UNSET
    name: str | Unset = UNSET
    description: None | str | Unset = UNSET
    disks: list[str] | Unset = UNSET
    creation_time: datetime.datetime | Unset = UNSET
    state: ServerState | Unset = UNSET
    online: bool | Unset = UNSET
    exported: bool | Unset = UNSET
    exported_size_in_ki_b: int | None | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        uuid = self.uuid

        name = self.name

        description: None | str | Unset
        if isinstance(self.description, Unset):
            description = UNSET
        else:
            description = self.description

        disks: list[str] | Unset = UNSET
        if not isinstance(self.disks, Unset):
            disks = self.disks

        creation_time: str | Unset = UNSET
        if not isinstance(self.creation_time, Unset):
            creation_time = self.creation_time.isoformat()

        state: str | Unset = UNSET
        if not isinstance(self.state, Unset):
            state = self.state.value

        online = self.online

        exported = self.exported

        exported_size_in_ki_b: int | None | Unset
        if isinstance(self.exported_size_in_ki_b, Unset):
            exported_size_in_ki_b = UNSET
        else:
            exported_size_in_ki_b = self.exported_size_in_ki_b

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if uuid is not UNSET:
            field_dict["uuid"] = uuid
        if name is not UNSET:
            field_dict["name"] = name
        if description is not UNSET:
            field_dict["description"] = description
        if disks is not UNSET:
            field_dict["disks"] = disks
        if creation_time is not UNSET:
            field_dict["creationTime"] = creation_time
        if state is not UNSET:
            field_dict["state"] = state
        if online is not UNSET:
            field_dict["online"] = online
        if exported is not UNSET:
            field_dict["exported"] = exported
        if exported_size_in_ki_b is not UNSET:
            field_dict["exportedSizeInKiB"] = exported_size_in_ki_b

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        uuid = d.pop("uuid", UNSET)

        name = d.pop("name", UNSET)

        def _parse_description(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        description = _parse_description(d.pop("description", UNSET))

        disks = cast(list[str], d.pop("disks", UNSET))

        _creation_time = d.pop("creationTime", UNSET)
        creation_time: datetime.datetime | Unset
        if isinstance(_creation_time, Unset):
            creation_time = UNSET
        else:
            creation_time = isoparse(_creation_time)

        _state = d.pop("state", UNSET)
        state: ServerState | Unset
        if isinstance(_state, Unset):
            state = UNSET
        else:
            state = ServerState(_state)

        online = d.pop("online", UNSET)

        exported = d.pop("exported", UNSET)

        def _parse_exported_size_in_ki_b(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        exported_size_in_ki_b = _parse_exported_size_in_ki_b(
            d.pop("exportedSizeInKiB", UNSET)
        )

        snapshot_minimal = cls(
            uuid=uuid,
            name=name,
            description=description,
            disks=disks,
            creation_time=creation_time,
            state=state,
            online=online,
            exported=exported,
            exported_size_in_ki_b=exported_size_in_ki_b,
        )

        snapshot_minimal.additional_properties = d
        return snapshot_minimal

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
