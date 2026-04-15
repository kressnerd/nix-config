from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, TYPE_CHECKING

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset


if TYPE_CHECKING:
    from ..models.cpu_topology import CpuTopology


T = TypeVar("T", bound="ServerCpuTopologyPatch")


@_attrs_define
class ServerCpuTopologyPatch:
    """
    Attributes:
        cpu_topology (CpuTopology | Unset):
    """

    cpu_topology: CpuTopology | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        cpu_topology: dict[str, Any] | Unset = UNSET
        if not isinstance(self.cpu_topology, Unset):
            cpu_topology = self.cpu_topology.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if cpu_topology is not UNSET:
            field_dict["cpuTopology"] = cpu_topology

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.cpu_topology import CpuTopology

        d = dict(src_dict)
        _cpu_topology = d.pop("cpuTopology", UNSET)
        cpu_topology: CpuTopology | Unset
        if isinstance(_cpu_topology, Unset):
            cpu_topology = UNSET
        else:
            cpu_topology = CpuTopology.from_dict(_cpu_topology)

        server_cpu_topology_patch = cls(
            cpu_topology=cpu_topology,
        )

        server_cpu_topology_patch.additional_properties = d
        return server_cpu_topology_patch

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
