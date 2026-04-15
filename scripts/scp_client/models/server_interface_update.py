from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from ..models.network_driver import NetworkDriver


T = TypeVar("T", bound="ServerInterfaceUpdate")


@_attrs_define
class ServerInterfaceUpdate:
    """
    Attributes:
        driver (NetworkDriver | Unset):
    """

    driver: NetworkDriver | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        driver: str | Unset = UNSET
        if not isinstance(self.driver, Unset):
            driver = self.driver.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if driver is not UNSET:
            field_dict["driver"] = driver

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        _driver = d.pop("driver", UNSET)
        driver: NetworkDriver | Unset
        if isinstance(_driver, Unset):
            driver = UNSET
        else:
            driver = NetworkDriver(_driver)

        server_interface_update = cls(
            driver=driver,
        )

        server_interface_update.additional_properties = d
        return server_interface_update

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
