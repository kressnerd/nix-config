from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset


T = TypeVar("T", bound="CpuTopology")


@_attrs_define
class CpuTopology:
    """
    Attributes:
        socket_count (int | Unset):
        cores_per_socket_count (int | Unset):
    """

    socket_count: int | Unset = UNSET
    cores_per_socket_count: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        socket_count = self.socket_count

        cores_per_socket_count = self.cores_per_socket_count

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if socket_count is not UNSET:
            field_dict["socketCount"] = socket_count
        if cores_per_socket_count is not UNSET:
            field_dict["coresPerSocketCount"] = cores_per_socket_count

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        socket_count = d.pop("socketCount", UNSET)

        cores_per_socket_count = d.pop("coresPerSocketCount", UNSET)

        cpu_topology = cls(
            socket_count=socket_count,
            cores_per_socket_count=cores_per_socket_count,
        )

        cpu_topology.additional_properties = d
        return cpu_topology

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
