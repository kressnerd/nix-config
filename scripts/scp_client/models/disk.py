from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from ..models.storage_driver import StorageDriver


T = TypeVar("T", bound="Disk")


@_attrs_define
class Disk:
    """
    Attributes:
        name (str | Unset):
        allocation_in_mi_b (int | Unset):
        capacity_in_mi_b (int | Unset):
        storage_driver (StorageDriver | Unset):
    """

    name: str | Unset = UNSET
    allocation_in_mi_b: int | Unset = UNSET
    capacity_in_mi_b: int | Unset = UNSET
    storage_driver: StorageDriver | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        allocation_in_mi_b = self.allocation_in_mi_b

        capacity_in_mi_b = self.capacity_in_mi_b

        storage_driver: str | Unset = UNSET
        if not isinstance(self.storage_driver, Unset):
            storage_driver = self.storage_driver.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if name is not UNSET:
            field_dict["name"] = name
        if allocation_in_mi_b is not UNSET:
            field_dict["allocationInMiB"] = allocation_in_mi_b
        if capacity_in_mi_b is not UNSET:
            field_dict["capacityInMiB"] = capacity_in_mi_b
        if storage_driver is not UNSET:
            field_dict["storageDriver"] = storage_driver

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name", UNSET)

        allocation_in_mi_b = d.pop("allocationInMiB", UNSET)

        capacity_in_mi_b = d.pop("capacityInMiB", UNSET)

        _storage_driver = d.pop("storageDriver", UNSET)
        storage_driver: StorageDriver | Unset
        if isinstance(_storage_driver, Unset):
            storage_driver = UNSET
        else:
            storage_driver = StorageDriver(_storage_driver)

        disk = cls(
            name=name,
            allocation_in_mi_b=allocation_in_mi_b,
            capacity_in_mi_b=capacity_in_mi_b,
            storage_driver=storage_driver,
        )

        disk.additional_properties = d
        return disk

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
