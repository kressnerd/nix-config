from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from typing import cast


T = TypeVar("T", bound="IPv6AddressMinimal")


@_attrs_define
class IPv6AddressMinimal:
    """
    Attributes:
        id (int | Unset):
        network_prefix (str | Unset):
        network_prefix_length (int | Unset):
        gateway (None | str | Unset):
    """

    id: int | Unset = UNSET
    network_prefix: str | Unset = UNSET
    network_prefix_length: int | Unset = UNSET
    gateway: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        network_prefix = self.network_prefix

        network_prefix_length = self.network_prefix_length

        gateway: None | str | Unset
        if isinstance(self.gateway, Unset):
            gateway = UNSET
        else:
            gateway = self.gateway

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if id is not UNSET:
            field_dict["id"] = id
        if network_prefix is not UNSET:
            field_dict["networkPrefix"] = network_prefix
        if network_prefix_length is not UNSET:
            field_dict["networkPrefixLength"] = network_prefix_length
        if gateway is not UNSET:
            field_dict["gateway"] = gateway

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id", UNSET)

        network_prefix = d.pop("networkPrefix", UNSET)

        network_prefix_length = d.pop("networkPrefixLength", UNSET)

        def _parse_gateway(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        gateway = _parse_gateway(d.pop("gateway", UNSET))

        i_pv_6_address_minimal = cls(
            id=id,
            network_prefix=network_prefix,
            network_prefix_length=network_prefix_length,
            gateway=gateway,
        )

        i_pv_6_address_minimal.additional_properties = d
        return i_pv_6_address_minimal

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
