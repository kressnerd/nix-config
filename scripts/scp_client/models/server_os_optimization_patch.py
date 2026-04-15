from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from ..models.os_optimization import OsOptimization


T = TypeVar("T", bound="ServerOsOptimizationPatch")


@_attrs_define
class ServerOsOptimizationPatch:
    """
    Attributes:
        os_optimization (OsOptimization | Unset):
    """

    os_optimization: OsOptimization | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        os_optimization: str | Unset = UNSET
        if not isinstance(self.os_optimization, Unset):
            os_optimization = self.os_optimization.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if os_optimization is not UNSET:
            field_dict["os_optimization"] = os_optimization

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        _os_optimization = d.pop("os_optimization", UNSET)
        os_optimization: OsOptimization | Unset
        if isinstance(_os_optimization, Unset):
            os_optimization = UNSET
        else:
            os_optimization = OsOptimization(_os_optimization)

        server_os_optimization_patch = cls(
            os_optimization=os_optimization,
        )

        server_os_optimization_patch.additional_properties = d
        return server_os_optimization_patch

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
