from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, TYPE_CHECKING

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset


if TYPE_CHECKING:
    from ..models.server_ipv_4 import ServerIpv4
    from ..models.server_ipv_6 import ServerIpv6


T = TypeVar("T", bound="Interface")


@_attrs_define
class Interface:
    """
    Attributes:
        mac (str | Unset):
        driver (str | Unset):
        speed_in_m_bits (int | Unset):
        ipv_4_addresses (list[ServerIpv4] | Unset):
        ipv_6_addresses (list[ServerIpv6] | Unset):
    """

    mac: str | Unset = UNSET
    driver: str | Unset = UNSET
    speed_in_m_bits: int | Unset = UNSET
    ipv_4_addresses: list[ServerIpv4] | Unset = UNSET
    ipv_6_addresses: list[ServerIpv6] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        mac = self.mac

        driver = self.driver

        speed_in_m_bits = self.speed_in_m_bits

        ipv_4_addresses: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.ipv_4_addresses, Unset):
            ipv_4_addresses = []
            for ipv_4_addresses_item_data in self.ipv_4_addresses:
                ipv_4_addresses_item = ipv_4_addresses_item_data.to_dict()
                ipv_4_addresses.append(ipv_4_addresses_item)

        ipv_6_addresses: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.ipv_6_addresses, Unset):
            ipv_6_addresses = []
            for ipv_6_addresses_item_data in self.ipv_6_addresses:
                ipv_6_addresses_item = ipv_6_addresses_item_data.to_dict()
                ipv_6_addresses.append(ipv_6_addresses_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if mac is not UNSET:
            field_dict["mac"] = mac
        if driver is not UNSET:
            field_dict["driver"] = driver
        if speed_in_m_bits is not UNSET:
            field_dict["speedInMBits"] = speed_in_m_bits
        if ipv_4_addresses is not UNSET:
            field_dict["ipv4Addresses"] = ipv_4_addresses
        if ipv_6_addresses is not UNSET:
            field_dict["ipv6Addresses"] = ipv_6_addresses

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.server_ipv_4 import ServerIpv4
        from ..models.server_ipv_6 import ServerIpv6

        d = dict(src_dict)
        mac = d.pop("mac", UNSET)

        driver = d.pop("driver", UNSET)

        speed_in_m_bits = d.pop("speedInMBits", UNSET)

        _ipv_4_addresses = d.pop("ipv4Addresses", UNSET)
        ipv_4_addresses: list[ServerIpv4] | Unset = UNSET
        if _ipv_4_addresses is not UNSET and _ipv_4_addresses is not None:
            ipv_4_addresses = []
            for ipv_4_addresses_item_data in _ipv_4_addresses:
                ipv_4_addresses_item = ServerIpv4.from_dict(ipv_4_addresses_item_data)

                ipv_4_addresses.append(ipv_4_addresses_item)
        elif _ipv_4_addresses is None:
            ipv_4_addresses = None  # type: ignore[assignment]

        _ipv_6_addresses = d.pop("ipv6Addresses", UNSET)
        ipv_6_addresses: list[ServerIpv6] | Unset = UNSET
        if _ipv_6_addresses is not UNSET and _ipv_6_addresses is not None:
            ipv_6_addresses = []
            for ipv_6_addresses_item_data in _ipv_6_addresses:
                ipv_6_addresses_item = ServerIpv6.from_dict(ipv_6_addresses_item_data)

                ipv_6_addresses.append(ipv_6_addresses_item)
        elif _ipv_6_addresses is None:
            ipv_6_addresses = None  # type: ignore[assignment]

        interface = cls(
            mac=mac,
            driver=driver,
            speed_in_m_bits=speed_in_m_bits,
            ipv_4_addresses=ipv_4_addresses,
            ipv_6_addresses=ipv_6_addresses,
        )

        interface.additional_properties = d
        return interface

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
