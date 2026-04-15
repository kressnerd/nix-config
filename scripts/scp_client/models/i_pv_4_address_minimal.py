from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from typing import cast


T = TypeVar("T", bound="IPv4AddressMinimal")


@_attrs_define
class IPv4AddressMinimal:
    """
    Attributes:
        id (int | Unset):
        ip (str | Unset):
        netmask (str | Unset):
        gateway (None | str | Unset):
        broadcast (None | str | Unset):
    """

    id: int | Unset = UNSET
    ip: str | Unset = UNSET
    netmask: str | Unset = UNSET
    gateway: None | str | Unset = UNSET
    broadcast: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ip = self.ip

        netmask = self.netmask

        gateway: None | str | Unset
        if isinstance(self.gateway, Unset):
            gateway = UNSET
        else:
            gateway = self.gateway

        broadcast: None | str | Unset
        if isinstance(self.broadcast, Unset):
            broadcast = UNSET
        else:
            broadcast = self.broadcast

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if id is not UNSET:
            field_dict["id"] = id
        if ip is not UNSET:
            field_dict["ip"] = ip
        if netmask is not UNSET:
            field_dict["netmask"] = netmask
        if gateway is not UNSET:
            field_dict["gateway"] = gateway
        if broadcast is not UNSET:
            field_dict["broadcast"] = broadcast

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id", UNSET)

        ip = d.pop("ip", UNSET)

        netmask = d.pop("netmask", UNSET)

        def _parse_gateway(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        gateway = _parse_gateway(d.pop("gateway", UNSET))

        def _parse_broadcast(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        broadcast = _parse_broadcast(d.pop("broadcast", UNSET))

        i_pv_4_address_minimal = cls(
            id=id,
            ip=ip,
            netmask=netmask,
            gateway=gateway,
            broadcast=broadcast,
        )

        i_pv_4_address_minimal.additional_properties = d
        return i_pv_4_address_minimal

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
