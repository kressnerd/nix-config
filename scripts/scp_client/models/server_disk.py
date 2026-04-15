from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset


T = TypeVar("T", bound="ServerDisk")


@_attrs_define
class ServerDisk:
    """
    Attributes:
        dev (str | Unset):
        driver (str | Unset):
        capacity_in_mi_b (int | Unset):
        allocation_in_mi_b (int | Unset):
    """

    dev: str | Unset = UNSET
    driver: str | Unset = UNSET
    capacity_in_mi_b: int | Unset = UNSET
    allocation_in_mi_b: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        dev = self.dev

        driver = self.driver

        capacity_in_mi_b = self.capacity_in_mi_b

        allocation_in_mi_b = self.allocation_in_mi_b

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if dev is not UNSET:
            field_dict["dev"] = dev
        if driver is not UNSET:
            field_dict["driver"] = driver
        if capacity_in_mi_b is not UNSET:
            field_dict["capacityInMiB"] = capacity_in_mi_b
        if allocation_in_mi_b is not UNSET:
            field_dict["allocationInMiB"] = allocation_in_mi_b

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        dev = d.pop("dev", UNSET)

        driver = d.pop("driver", UNSET)

        capacity_in_mi_b = d.pop("capacityInMiB", UNSET)

        allocation_in_mi_b = d.pop("allocationInMiB", UNSET)

        server_disk = cls(
            dev=dev,
            driver=driver,
            capacity_in_mi_b=capacity_in_mi_b,
            allocation_in_mi_b=allocation_in_mi_b,
        )

        server_disk.additional_properties = d
        return server_disk

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
