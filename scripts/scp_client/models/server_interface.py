from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from typing import cast


T = TypeVar("T", bound="ServerInterface")


@_attrs_define
class ServerInterface:
    """
    Attributes:
        mac (str | Unset):
        driver (str | Unset):
        mtu (int | Unset):
        speed_in_m_bits (int | Unset):
        rx_monthly_in_mi_b (int | Unset):
        tx_monthly_in_mi_b (int | Unset):
        ipv_4_addresses (list[str] | Unset):
        ipv_6_link_local_addresses (list[str] | Unset):
        ipv_6_network_prefixes (list[str] | Unset):
        traffic_throttled (bool | Unset):
        vlan_interface (bool | Unset):
        vlan_id (int | Unset):
    """

    mac: str | Unset = UNSET
    driver: str | Unset = UNSET
    mtu: int | Unset = UNSET
    speed_in_m_bits: int | Unset = UNSET
    rx_monthly_in_mi_b: int | Unset = UNSET
    tx_monthly_in_mi_b: int | Unset = UNSET
    ipv_4_addresses: list[str] | Unset = UNSET
    ipv_6_link_local_addresses: list[str] | Unset = UNSET
    ipv_6_network_prefixes: list[str] | Unset = UNSET
    traffic_throttled: bool | Unset = UNSET
    vlan_interface: bool | Unset = UNSET
    vlan_id: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        mac = self.mac

        driver = self.driver

        mtu = self.mtu

        speed_in_m_bits = self.speed_in_m_bits

        rx_monthly_in_mi_b = self.rx_monthly_in_mi_b

        tx_monthly_in_mi_b = self.tx_monthly_in_mi_b

        ipv_4_addresses: list[str] | Unset = UNSET
        if not isinstance(self.ipv_4_addresses, Unset):
            ipv_4_addresses = self.ipv_4_addresses

        ipv_6_link_local_addresses: list[str] | Unset = UNSET
        if not isinstance(self.ipv_6_link_local_addresses, Unset):
            ipv_6_link_local_addresses = self.ipv_6_link_local_addresses

        ipv_6_network_prefixes: list[str] | Unset = UNSET
        if not isinstance(self.ipv_6_network_prefixes, Unset):
            ipv_6_network_prefixes = self.ipv_6_network_prefixes

        traffic_throttled = self.traffic_throttled

        vlan_interface = self.vlan_interface

        vlan_id = self.vlan_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if mac is not UNSET:
            field_dict["mac"] = mac
        if driver is not UNSET:
            field_dict["driver"] = driver
        if mtu is not UNSET:
            field_dict["mtu"] = mtu
        if speed_in_m_bits is not UNSET:
            field_dict["speedInMBits"] = speed_in_m_bits
        if rx_monthly_in_mi_b is not UNSET:
            field_dict["rxMonthlyInMiB"] = rx_monthly_in_mi_b
        if tx_monthly_in_mi_b is not UNSET:
            field_dict["txMonthlyInMiB"] = tx_monthly_in_mi_b
        if ipv_4_addresses is not UNSET:
            field_dict["ipv4Addresses"] = ipv_4_addresses
        if ipv_6_link_local_addresses is not UNSET:
            field_dict["ipv6LinkLocalAddresses"] = ipv_6_link_local_addresses
        if ipv_6_network_prefixes is not UNSET:
            field_dict["ipv6NetworkPrefixes"] = ipv_6_network_prefixes
        if traffic_throttled is not UNSET:
            field_dict["trafficThrottled"] = traffic_throttled
        if vlan_interface is not UNSET:
            field_dict["vlanInterface"] = vlan_interface
        if vlan_id is not UNSET:
            field_dict["vlanId"] = vlan_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        mac = d.pop("mac", UNSET)

        driver = d.pop("driver", UNSET)

        mtu = d.pop("mtu", UNSET)

        speed_in_m_bits = d.pop("speedInMBits", UNSET)

        rx_monthly_in_mi_b = d.pop("rxMonthlyInMiB", UNSET)

        tx_monthly_in_mi_b = d.pop("txMonthlyInMiB", UNSET)

        ipv_4_addresses = cast(list[str], d.pop("ipv4Addresses", UNSET))

        ipv_6_link_local_addresses = cast(
            list[str], d.pop("ipv6LinkLocalAddresses", UNSET)
        )

        ipv_6_network_prefixes = cast(list[str], d.pop("ipv6NetworkPrefixes", UNSET))

        traffic_throttled = d.pop("trafficThrottled", UNSET)

        vlan_interface = d.pop("vlanInterface", UNSET)

        vlan_id = d.pop("vlanId", UNSET)

        server_interface = cls(
            mac=mac,
            driver=driver,
            mtu=mtu,
            speed_in_m_bits=speed_in_m_bits,
            rx_monthly_in_mi_b=rx_monthly_in_mi_b,
            tx_monthly_in_mi_b=tx_monthly_in_mi_b,
            ipv_4_addresses=ipv_4_addresses,
            ipv_6_link_local_addresses=ipv_6_link_local_addresses,
            ipv_6_network_prefixes=ipv_6_network_prefixes,
            traffic_throttled=traffic_throttled,
            vlan_interface=vlan_interface,
            vlan_id=vlan_id,
        )

        server_interface.additional_properties = d
        return server_interface

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
