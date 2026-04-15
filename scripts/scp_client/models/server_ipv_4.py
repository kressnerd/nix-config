from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from ..models.server_ip_type import ServerIpType
from typing import cast


T = TypeVar("T", bound="ServerIpv4")


@_attrs_define
class ServerIpv4:
    """
    Attributes:
        id (int | Unset):
        interface_mac (str | Unset):
        type_ (ServerIpType | Unset):
        ip (str | Unset):
        cidr (str | Unset):
        gateway (None | str | Unset):
        rdns (None | str | Unset):
        destination_ip (None | str | Unset):
        editable (bool | Unset):
    """

    id: int | Unset = UNSET
    interface_mac: str | Unset = UNSET
    type_: ServerIpType | Unset = UNSET
    ip: str | Unset = UNSET
    cidr: str | Unset = UNSET
    gateway: None | str | Unset = UNSET
    rdns: None | str | Unset = UNSET
    destination_ip: None | str | Unset = UNSET
    editable: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        interface_mac = self.interface_mac

        type_: str | Unset = UNSET
        if not isinstance(self.type_, Unset):
            type_ = self.type_.value

        ip = self.ip

        cidr = self.cidr

        gateway: None | str | Unset
        if isinstance(self.gateway, Unset):
            gateway = UNSET
        else:
            gateway = self.gateway

        rdns: None | str | Unset
        if isinstance(self.rdns, Unset):
            rdns = UNSET
        else:
            rdns = self.rdns

        destination_ip: None | str | Unset
        if isinstance(self.destination_ip, Unset):
            destination_ip = UNSET
        else:
            destination_ip = self.destination_ip

        editable = self.editable

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if id is not UNSET:
            field_dict["id"] = id
        if interface_mac is not UNSET:
            field_dict["interfaceMac"] = interface_mac
        if type_ is not UNSET:
            field_dict["type"] = type_
        if ip is not UNSET:
            field_dict["ip"] = ip
        if cidr is not UNSET:
            field_dict["cidr"] = cidr
        if gateway is not UNSET:
            field_dict["gateway"] = gateway
        if rdns is not UNSET:
            field_dict["rdns"] = rdns
        if destination_ip is not UNSET:
            field_dict["destinationIp"] = destination_ip
        if editable is not UNSET:
            field_dict["editable"] = editable

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id", UNSET)

        interface_mac = d.pop("interfaceMac", UNSET)

        _type_ = d.pop("type", UNSET)
        type_: ServerIpType | Unset
        if isinstance(_type_, Unset):
            type_ = UNSET
        else:
            type_ = ServerIpType(_type_)

        ip = d.pop("ip", UNSET)

        cidr = d.pop("cidr", UNSET)

        def _parse_gateway(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        gateway = _parse_gateway(d.pop("gateway", UNSET))

        def _parse_rdns(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        rdns = _parse_rdns(d.pop("rdns", UNSET))

        def _parse_destination_ip(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        destination_ip = _parse_destination_ip(d.pop("destinationIp", UNSET))

        editable = d.pop("editable", UNSET)

        server_ipv_4 = cls(
            id=id,
            interface_mac=interface_mac,
            type_=type_,
            ip=ip,
            cidr=cidr,
            gateway=gateway,
            rdns=rdns,
            destination_ip=destination_ip,
            editable=editable,
        )

        server_ipv_4.additional_properties = d
        return server_ipv_4

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
